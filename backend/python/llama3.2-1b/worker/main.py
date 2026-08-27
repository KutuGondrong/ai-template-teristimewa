from __future__ import annotations

import asyncio
import logging

from app.application.cleanup import GuestCleanupService
from app.config import get_settings
from app.infrastructure.database import create_engine, create_session_factory, init_db
from app.infrastructure.repositories import SqlAlchemyUnitOfWork

logger = logging.getLogger("worker")


async def run_once() -> int:
    settings = get_settings()
    engine = create_engine(settings.database_url)
    factory = create_session_factory(engine)
    await init_db(engine)
    try:
        async with factory() as session:
            uow = SqlAlchemyUnitOfWork(session)
            deleted = await GuestCleanupService(uow).cleanup_expired()
            logger.info("Deleted %s guests older than 1 day", deleted)
            return deleted
    finally:
        await engine.dispose()


def run() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    asyncio.run(run_once())


if __name__ == "__main__":
    run()
