from tests.state import calls

ADDRESS = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"


def register(client, email="user@example.com"):
    response = client.post("/auth/register", json={"email": email, "password": "password123"})
    assert response.status_code == 201
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def test_health(client):
    assert client.get("/health").json() == {"status": "ok"}


def test_register_login_and_duplicate(client):
    register(client)
    assert client.post("/auth/register", json={"email": "user@example.com", "password": "password123"}).status_code == 409
    ok = client.post("/auth/login", json={"email": "user@example.com", "password": "password123"})
    assert ok.status_code == 200
    bad = client.post("/auth/login", json={"email": "user@example.com", "password": "wrong-password"})
    assert bad.status_code == 401


def test_market_prices_are_cached(client):
    first = client.get("/market/prices", params={"symbols": "ETH"})
    assert first.status_code == 200
    assert first.json()["prices"]["ETH"] == {"price": 3500.0, "change24h": 1.5}
    client.get("/market/prices", params={"symbols": "ETH"})
    assert len([c for c in calls if "simple/price" in c]) == 1


def test_market_symbol(client):
    assert client.get("/market/ETH").json()["price"] == 3500.0
    assert client.get("/market/UNKNOWN").status_code == 404


def test_transactions_proxy(client):
    response = client.get(f"/wallet/{ADDRESS}/transactions", params={"chain_id": 11155111})
    assert response.status_code == 200
    assert response.json()["result"][0]["hash"] == "0xabc"


def test_transactions_validation(client):
    assert client.get("/wallet/0x123/transactions").status_code == 422
    assert client.get(f"/wallet/{ADDRESS}/transactions", params={"chain_id": 999}).status_code == 422


def test_networks(client):
    ids = [n["id"] for n in client.get("/networks").json()["networks"]]
    assert "sepolia" in ids


def test_notifications_require_auth(client):
    assert client.get("/notifications").status_code == 401
    headers = register(client, "a@example.com")
    assert client.get("/notifications", headers=headers).json() == {"notifications": []}
    response = client.post(
        "/notifications/register-device",
        headers=headers,
        json={"token": "x" * 20, "platform": "android"},
    )
    assert response.status_code == 201


def test_wallet_metadata_and_settings(client):
    headers = register(client, "b@example.com")
    assert client.post("/wallet/metadata", headers=headers, json={"address": ADDRESS, "network": "sepolia"}).status_code == 201
    assert client.put("/settings", headers=headers, json={"currency": "EUR", "theme": "dark"}).status_code == 200
    assert client.get("/settings", headers=headers).json() == {"currency": "EUR", "theme": "dark"}


def test_server_rejects_secrets(client):
    headers = register(client, "c@example.com")
    response = client.post(
        "/wallet/metadata",
        headers=headers,
        json={"address": ADDRESS, "network": "sepolia", "private_key": "0x01"},
    )
    assert response.status_code == 400
    response = client.post(
        "/auth/login",
        json={"email": "c@example.com", "password": "x" * 8, "mnemonic": "a b"},
    )
    assert response.status_code == 400
    nested = client.post(
        "/wallet/metadata",
        headers=headers,
        json={"address": ADDRESS, "network": "sepolia", "extra": {"seed_phrase": "a"}},
    )
    assert nested.status_code == 400


def test_rate_limit(client):
    from app.cache import MemoryCache, get_cache
    from app.config import settings
    from app.main import app

    cache = MemoryCache()
    app.dependency_overrides[get_cache] = lambda: cache
    settings.rate_limit_per_minute = 2
    assert client.get("/health").status_code == 200
    assert client.get("/health").status_code == 200
    assert client.get("/health").status_code == 429
    settings.rate_limit_per_minute = 1000


def test_invalid_settings_currency(client):
    headers = register(client, "currency@example.com")
    response = client.put(
        "/settings", headers=headers, json={"currency": "BTC", "theme": "dark"}
    )
    assert response.status_code == 422


def test_jwt_secret_required():
    import os
    import subprocess
    import sys
    from pathlib import Path

    env = os.environ.copy()
    env["JWT_SECRET"] = "change-me"
    env.pop("TESTING", None)
    env["DATABASE_URL"] = "sqlite:///:memory:"
    result = subprocess.run(
        [
            sys.executable,
            "-c",
            "import app.config",
        ],
        cwd=str(Path(__file__).resolve().parents[1]),
        env=env,
        capture_output=True,
        text=True,
    )
    assert result.returncode != 0
