import json
import time
from typing import Any, Protocol

import redis

from .config import settings


class Cache(Protocol):
    def get_json(self, key: str) -> Any | None: ...

    def set_json(self, key: str, value: Any, ttl: int) -> None: ...

    def incr_with_ttl(self, key: str, ttl: int) -> int: ...


class RedisCache:
    def __init__(self, url: str):
        self._client = redis.Redis.from_url(url, decode_responses=True)
        self._fallback = MemoryCache()

    def get_json(self, key: str) -> Any | None:
        try:
            raw = self._client.get(key)
        except redis.RedisError:
            return self._fallback.get_json(key)
        return json.loads(raw) if raw else None

    def set_json(self, key: str, value: Any, ttl: int) -> None:
        try:
            self._client.set(key, json.dumps(value), ex=ttl)
        except redis.RedisError:
            self._fallback.set_json(key, value, ttl)

    def incr_with_ttl(self, key: str, ttl: int) -> int:
        try:
            pipe = self._client.pipeline()
            pipe.incr(key)
            pipe.expire(key, ttl, nx=True)
            return int(pipe.execute()[0])
        except redis.RedisError:
            return self._fallback.incr_with_ttl(key, ttl)


class MemoryCache:
    def __init__(self):
        self._data: dict[str, tuple[float, Any]] = {}

    def get_json(self, key: str) -> Any | None:
        item = self._data.get(key)
        if not item or item[0] < time.time():
            return None
        return item[1]

    def set_json(self, key: str, value: Any, ttl: int) -> None:
        self._data[key] = (time.time() + ttl, value)

    def incr_with_ttl(self, key: str, ttl: int) -> int:
        current = (self.get_json(key) or 0) + 1
        item = self._data.get(key)
        expires = item[0] if item and item[0] >= time.time() else time.time() + ttl
        self._data[key] = (expires, current)
        return current


_cache: Cache | None = None


def get_cache() -> Cache:
    global _cache
    if _cache is None:
        _cache = RedisCache(settings.redis_url)
    return _cache
