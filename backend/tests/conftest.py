import os

os.environ["TESTING"] = "true"
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["JWT_SECRET"] = "test-secret-test-secret-test-secret-123"
os.environ["RATE_LIMIT_PER_MINUTE"] = "1000"
os.environ["AUTH_RATE_LIMIT_PER_MINUTE"] = "1000"

import httpx
import pytest
from fastapi.testclient import TestClient

from app.cache import MemoryCache, get_cache
from app.main import app
from app.services import get_http
from tests.state import calls


def handler(request: httpx.Request) -> httpx.Response:
    calls.append(str(request.url))
    if "simple/price" in request.url.path:
        return httpx.Response(
            200, json={"ethereum": {"usd": 3500.0, "usd_24h_change": 1.5}}
        )
    if "etherscan" in request.url.host:
        return httpx.Response(
            200,
            json={
                "status": "1",
                "message": "OK",
                "result": [{"hash": "0xabc", "from": "0x1", "to": "0x2", "value": "1"}],
            },
        )
    return httpx.Response(404)


@pytest.fixture()
def client():
    calls.clear()
    cache = MemoryCache()
    app.dependency_overrides[get_cache] = lambda: cache
    app.dependency_overrides[get_http] = lambda: httpx.Client(
        transport=httpx.MockTransport(handler)
    )
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
