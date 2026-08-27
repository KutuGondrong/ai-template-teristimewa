from __future__ import annotations

import asyncio
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from app.application.cleanup import GuestCleanupService, run_guest_cleanup_loop
from app.infrastructure.orm import ConversationRow, GuestRow, MessageRow
from app.infrastructure.repositories import SqlAlchemyUnitOfWork
from sqlalchemy import select


@pytest.mark.asyncio
async def test_cleanup_deletes_guests_older_than_one_day(session_factory) -> None:
    guest_old = uuid4()
    guest_new = uuid4()
    async with session_factory() as session:
        old = GuestRow(id=guest_old, created_at=datetime.now(tz=UTC) - timedelta(hours=25))
        new = GuestRow(id=guest_new, created_at=datetime.now(tz=UTC) - timedelta(hours=1))
        session.add_all([old, new])
        await session.flush()
        old_convo = ConversationRow(guest_id=guest_old)
        new_convo = ConversationRow(guest_id=guest_new)
        session.add_all([old_convo, new_convo])
        await session.flush()
        session.add(MessageRow(conversation_id=old_convo.id, role="user", content="old"))
        await session.commit()

    async with session_factory() as session:
        uow = SqlAlchemyUnitOfWork(session)
        deleted = await GuestCleanupService(uow).cleanup_expired()
        assert deleted == 1

    async with session_factory() as session:
        remaining = (await session.execute(select(GuestRow))).scalars().all()
        assert len(remaining) == 1
        assert remaining[0].id == guest_new
        leftover_messages = (await session.execute(select(MessageRow))).scalars().all()
        assert leftover_messages == []


@pytest.mark.asyncio
async def test_cleanup_loop_runs_once_then_stops(session_factory) -> None:
    guest_old = uuid4()
    async with session_factory() as session:
        session.add(GuestRow(id=guest_old, created_at=datetime.now(tz=UTC) - timedelta(hours=25)))
        await session.commit()

    stop = asyncio.Event()

    async def cleanup() -> int:
        async with session_factory() as session:
            deleted = await GuestCleanupService(SqlAlchemyUnitOfWork(session)).cleanup_expired()
        stop.set()
        return deleted

    await run_guest_cleanup_loop(cleanup, interval_seconds=30, stop=stop)

    async with session_factory() as session:
        remaining = (await session.execute(select(GuestRow))).scalars().all()
        assert remaining == []
