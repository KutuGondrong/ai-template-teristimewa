from __future__ import annotations

import time
from collections import defaultdict, deque

from app.domain.errors import RateLimitError


class InMemoryRateLimiter:
    def __init__(self, *, limit: int = 20, window_seconds: float = 60.0) -> None:
        self._limit = limit
        self._window = window_seconds
        self._hits: dict[str, deque[float]] = defaultdict(deque)

    def check(self, key: str) -> None:
        now = time.monotonic()
        bucket = self._hits[key]
        while bucket and now - bucket[0] > self._window:
            bucket.popleft()
        if len(bucket) >= self._limit:
            raise RateLimitError("Too many requests")
        bucket.append(now)
