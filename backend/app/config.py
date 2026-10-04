import os
import sys


class Settings:
    database_url: str = os.getenv("DATABASE_URL", "sqlite:///./wallet.db")
    redis_url: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    jwt_secret: str = os.getenv("JWT_SECRET", "change-me")
    jwt_ttl_minutes: int = int(os.getenv("JWT_TTL_MINUTES", "60"))
    etherscan_api_key: str = os.getenv("ETHERSCAN_API_KEY", "")
    coingecko_base_url: str = os.getenv(
        "COINGECKO_BASE_URL", "https://api.coingecko.com/api/v3"
    )
    rate_limit_per_minute: int = int(os.getenv("RATE_LIMIT_PER_MINUTE", "120"))
    auth_rate_limit_per_minute: int = int(os.getenv("AUTH_RATE_LIMIT_PER_MINUTE", "20"))
    market_ttl_seconds: int = 60
    transactions_ttl_seconds: int = 30
    trusted_proxy: bool = os.getenv("TRUSTED_PROXY", "false").lower() in {
        "1",
        "true",
        "yes",
    }
    testing: bool = os.getenv("TESTING", "").lower() in {"1", "true", "yes"}


settings = Settings()

if not settings.testing and (
    not settings.jwt_secret or settings.jwt_secret == "change-me"
):
    sys.exit("JWT_SECRET must be set to a non-default value")

NETWORKS = [
    {
        "id": "sepolia",
        "name": "Sepolia Testnet",
        "chain_id": 11155111,
        "symbol": "SepoliaETH",
        "testnet": True,
    },
    {"id": "ethereum", "name": "Ethereum", "chain_id": 1, "symbol": "ETH", "testnet": False},
    {"id": "polygon", "name": "Polygon", "chain_id": 137, "symbol": "POL", "testnet": False},
    {"id": "bnb", "name": "BNB Chain", "chain_id": 56, "symbol": "BNB", "testnet": False},
]

SUPPORTED_CURRENCIES = {"USD", "EUR", "RUB"}

SYMBOL_TO_COINGECKO = {
    "ETH": "ethereum",
    "POL": "polygon-ecosystem-token",
    "BNB": "binancecoin",
    "BTC": "bitcoin",
    "USDT": "tether",
    "USDC": "usd-coin",
}
