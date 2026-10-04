import json
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import httpx

from .cache import get_cache
from .config import settings
from .database import Base, engine
from .routers import auth_router, market_router, misc_router, wallet_router

FORBIDDEN_FIELDS = {
    "private_key",
    "privatekey",
    "seed",
    "seed_phrase",
    "mnemonic",
    "pin",
}


def _contains_secret(value) -> bool:
    if isinstance(value, dict):
        for key, nested in value.items():
            if str(key).lower() in FORBIDDEN_FIELDS:
                return True
            if _contains_secret(nested):
                return True
        return False
    if isinstance(value, list):
        return any(_contains_secret(item) for item in value)
    return False


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http_client = httpx.Client(timeout=10)
    yield
    client = app.state.http_client
    if client is not None:
        client.close()


def create_app() -> FastAPI:
    app = FastAPI(title="Crypto Wallet Backend", lifespan=lifespan)
    app.state.http_client = None

    @app.middleware("http")
    async def rate_limit(request: Request, call_next):
        cache_factory = app.dependency_overrides.get(get_cache, get_cache)
        client = request.client.host if request.client else "unknown"
        if settings.trusted_proxy:
            forwarded = request.headers.get("x-forwarded-for", "").split(",")[0].strip()
            client = forwarded or client
        limit = (
            settings.auth_rate_limit_per_minute
            if request.url.path.startswith("/auth/")
            else settings.rate_limit_per_minute
        )
        count = cache_factory().incr_with_ttl(f"rl:{request.url.path}:{client}", 60)
        if count > limit:
            return JSONResponse({"detail": "Too many requests"}, status_code=429)
        return await call_next(request)

    @app.middleware("http")
    async def reject_secrets(request: Request, call_next):
        if request.method in {"POST", "PUT", "PATCH"}:
            body = await request.body()
            if body:
                try:
                    payload = json.loads(body)
                except json.JSONDecodeError:
                    payload = None
                if payload is not None and _contains_secret(payload):
                    return JSONResponse(
                        {"detail": "Secrets must never be sent to the server"},
                        status_code=400,
                    )
        return await call_next(request)

    @app.get("/health")
    def health():
        return {"status": "ok"}

    app.include_router(auth_router)
    app.include_router(market_router)
    app.include_router(wallet_router)
    app.include_router(misc_router)
    return app


Base.metadata.create_all(bind=engine)
app = create_app()
