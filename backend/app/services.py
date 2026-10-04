import httpx
from fastapi import HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from .cache import Cache
from .config import NETWORKS, SYMBOL_TO_COINGECKO, settings
from .database import TransactionCache


def get_http(request: Request):
    client = getattr(request.app.state, "http_client", None)
    if client is None:
        client = httpx.Client(timeout=10)
        request.app.state.http_client = client
    yield client


class MarketService:
    def __init__(self, http: httpx.Client, cache: Cache):
        self._http = http
        self._cache = cache

    def prices(self, symbols: list[str], currency: str = "usd") -> dict:
        currency = currency.lower()
        wanted = [s.upper() for s in symbols if s.upper() in SYMBOL_TO_COINGECKO]
        result: dict[str, dict] = {}
        missing: list[str] = []
        for symbol in wanted:
            cached = self._cache.get_json(f"price:{symbol}:{currency}")
            if cached is not None:
                result[symbol] = cached
            else:
                missing.append(symbol)
        if missing:
            ids = ",".join(SYMBOL_TO_COINGECKO[s] for s in missing)
            try:
                response = self._http.get(
                    f"{settings.coingecko_base_url}/simple/price",
                    params={
                        "ids": ids,
                        "vs_currencies": currency,
                        "include_24hr_change": "true",
                    },
                )
                response.raise_for_status()
                data = response.json()
            except (httpx.HTTPError, ValueError):
                if not result:
                    raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Market data unavailable")
                return result
            for symbol in missing:
                entry = data.get(SYMBOL_TO_COINGECKO[symbol])
                if entry is None:
                    continue
                value = {
                    "price": entry.get(currency),
                    "change24h": entry.get(f"{currency}_24h_change"),
                }
                result[symbol] = value
                self._cache.set_json(
                    f"price:{symbol}:{currency}", value, settings.market_ttl_seconds
                )
        return result


class TransactionService:
    def __init__(self, http: httpx.Client, cache: Cache, db: Session):
        self._http = http
        self._cache = cache
        self._db = db

    def history(self, address: str, chain_id: int) -> list[dict]:
        if chain_id not in {n["chain_id"] for n in NETWORKS}:
            raise HTTPException(422, "Unsupported chain")
        key = f"txs:{chain_id}:{address}"
        cached = self._cache.get_json(key)
        if cached is not None:
            return cached
        try:
            rows = self._fetch(address, chain_id)
        except (httpx.HTTPError, ValueError):
            raise HTTPException(
                status.HTTP_502_BAD_GATEWAY, "Transaction history unavailable"
            )
        self._store(address, chain_id, rows)
        self._cache.set_json(key, rows, settings.transactions_ttl_seconds)
        return rows

    def _fetch(self, address: str, chain_id: int) -> list[dict]:
        response = self._http.get(
            "https://api.etherscan.io/v2/api",
            params={
                "chainid": chain_id,
                "module": "account",
                "action": "txlist",
                "address": address,
                "startblock": 0,
                "endblock": 99999999,
                "page": 1,
                "offset": 50,
                "sort": "desc",
                "apikey": settings.etherscan_api_key,
            },
        )
        response.raise_for_status()
        body = response.json()
        result = body.get("result")
        if isinstance(result, list):
            return result
        if body.get("message") == "No transactions found":
            return []
        raise ValueError("unexpected response")

    def _store(self, address: str, chain_id: int, rows: list[dict]) -> None:
        existing = {
            row.tx_hash: row
            for row in self._db.scalars(
                select(TransactionCache).where(
                    TransactionCache.address == address,
                    TransactionCache.chain_id == chain_id,
                )
            )
        }
        for row in rows:
            tx_hash = row.get("hash")
            if not tx_hash:
                continue
            current = existing.get(tx_hash)
            if current is None:
                self._db.add(
                    TransactionCache(
                        chain_id=chain_id,
                        address=address,
                        tx_hash=tx_hash,
                        payload=row,
                    )
                )
            else:
                current.payload = row
        self._db.commit()
