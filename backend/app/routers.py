from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .cache import Cache, get_cache
from .config import NETWORKS, SUPPORTED_CURRENCIES, SYMBOL_TO_COINGECKO
from .database import DeviceToken, Notification, User, UserSettings, WalletMetadata, get_db
from .security import (
    create_token,
    current_user,
    dummy_password_hash,
    hash_password,
    validate_address,
    verify_password,
)
from .services import MarketService, TransactionService, get_http

auth_router = APIRouter(prefix="/auth", tags=["auth"])
market_router = APIRouter(prefix="/market", tags=["market"])
wallet_router = APIRouter(prefix="/wallet", tags=["wallet"])
misc_router = APIRouter(tags=["misc"])


class Credentials(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class DeviceRegistration(BaseModel):
    token: str = Field(min_length=10, max_length=512)
    platform: str = Field(pattern="^(android|ios)$")


class WalletRegistration(BaseModel):
    address: str
    network: str = Field(min_length=2, max_length=32)


class SettingsPayload(BaseModel):
    currency: str = Field(default="USD", max_length=8)
    theme: str = Field(default="system", pattern="^(system|light|dark)$")


@auth_router.post("/register", response_model=TokenResponse, status_code=201)
def register(payload: Credentials, db: Session = Depends(get_db)):
    email = payload.email.lower()
    user = User(email=email, password_hash=hash_password(payload.password))
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "Email already registered")
    return TokenResponse(access_token=create_token(user.id))


@auth_router.post("/login", response_model=TokenResponse)
def login(payload: Credentials, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.email == payload.email.lower()))
    password_hash = user.password_hash if user is not None else dummy_password_hash()
    if user is None or not verify_password(payload.password, password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid credentials")
    return TokenResponse(access_token=create_token(user.id))


@market_router.get("/prices")
def prices(
    symbols: str = Query(..., min_length=1, max_length=200),
    currency: str = Query("usd", max_length=8),
    http=Depends(get_http),
    cache: Cache = Depends(get_cache),
):
    names = [s for s in symbols.split(",") if s]
    return {"prices": MarketService(http, cache).prices(names, currency)}


@market_router.get("/{symbol}")
def price(
    symbol: str,
    currency: str = Query("usd", max_length=8),
    http=Depends(get_http),
    cache: Cache = Depends(get_cache),
):
    if symbol.upper() not in SYMBOL_TO_COINGECKO:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Unknown symbol")
    data = MarketService(http, cache).prices([symbol], currency)
    if symbol.upper() not in data:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Price unavailable")
    return {"symbol": symbol.upper(), **data[symbol.upper()]}


@wallet_router.get("/{address}/transactions")
def transactions(
    address: str,
    chain_id: int = Query(11155111),
    http=Depends(get_http),
    cache: Cache = Depends(get_cache),
    db: Session = Depends(get_db),
):
    # Public blockchain history proxy (no private keys). Protected by rate limiting.
    rows = TransactionService(http, cache, db).history(
        validate_address(address), chain_id
    )
    return {"status": "1", "message": "OK", "result": rows}


@wallet_router.post("/metadata", status_code=201)
def register_wallet(
    payload: WalletRegistration,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    if payload.network not in {n["id"] for n in NETWORKS}:
        raise HTTPException(422, "Unsupported network")
    address = validate_address(payload.address)
    exists = db.scalar(
        select(WalletMetadata).where(
            WalletMetadata.user_id == user.id, WalletMetadata.wallet_address == address
        )
    )
    if not exists:
        db.add(
            WalletMetadata(
                user_id=user.id, wallet_address=address, network=payload.network
            )
        )
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
    return {"address": address, "network": payload.network}


@misc_router.get("/networks")
def networks():
    return {"networks": NETWORKS}


@misc_router.get("/notifications")
def notifications(user: User = Depends(current_user), db: Session = Depends(get_db)):
    rows = db.scalars(
        select(Notification)
        .where(Notification.user_id == user.id)
        .order_by(Notification.id.desc())
        .limit(100)
    )
    return {
        "notifications": [
            {
                "id": n.id,
                "title": n.title,
                "body": n.body,
                "created_at": n.created_at.isoformat(),
            }
            for n in rows
        ]
    }


@misc_router.post("/notifications/register-device", status_code=201)
def register_device(
    payload: DeviceRegistration,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    existing = db.scalar(select(DeviceToken).where(DeviceToken.token == payload.token))
    if existing is None:
        db.add(
            DeviceToken(
                user_id=user.id, token=payload.token, platform=payload.platform
            )
        )
    else:
        existing.user_id = user.id
        existing.platform = payload.platform
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "Device token conflict")
    return {"status": "registered"}


@misc_router.get("/settings")
def get_settings(user: User = Depends(current_user), db: Session = Depends(get_db)):
    row = db.scalar(select(UserSettings).where(UserSettings.user_id == user.id))
    return SettingsPayload(currency=row.currency, theme=row.theme) if row else SettingsPayload()


@misc_router.put("/settings")
def put_settings(
    payload: SettingsPayload,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    if payload.currency.upper() not in SUPPORTED_CURRENCIES:
        raise HTTPException(422, "Unsupported currency")
    row = db.scalar(select(UserSettings).where(UserSettings.user_id == user.id))
    if row is None:
        row = UserSettings(user_id=user.id)
        db.add(row)
    row.currency = payload.currency.upper()
    row.theme = payload.theme
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "Settings conflict")
    return SettingsPayload(currency=row.currency, theme=row.theme)
