from __future__ import annotations

import asyncio
import logging
from collections.abc import Awaitable, Callable
from datetime import UTC, datetime, timedelta

from app.application.ports import UnitOfWork

GUEST_TTL = timedelta(days=1)
GUEST_CLEANUP_INTERVAL_SECONDS = 3600.0
logger = logging.getLogger("guest_cleanup")


def guest_expiry_cutoff() -> datetime:
    return datetime.now(tz=UTC) - GUEST_TTL


class GuestCleanupService:
    def __init__(self, uow: UnitOfWork) -> None:
        self._uow = uow

    async def cleanup_expired(self) -> int:
        deleted = await self._uow.guests.delete_older_than(guest_expiry_cutoff())
        await self._uow.commit()
        return deleted


async def run_guest_cleanup_loop(
    cleanup: Callable[[], Awaitable[int]],
    *,
    interval_seconds: float = GUEST_CLEANUP_INTERVAL_SECONDS,
    stop: asyncio.Event | None = None,
) -> None:
    while True:
        try:
            deleted = await cleanup()
            if deleted:
                logger.info("Deleted %s guests older than 1 day", deleted)
        except asyncio.CancelledError:
            raise
        except Exception:
            logger.exception("Guest cleanup failed")
        if stop is None:
            await asyncio.sleep(interval_seconds)
            continue
        try:
            await asyncio.wait_for(stop.wait(), timeout=interval_seconds)
            return
        except TimeoutError:
            continue
