from __future__ import annotations

from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities import Conversation, Guest, Message, User
from app.infrastructure.orm import ConversationRow, GuestRow, MessageRow, UserRow


def _user(row: UserRow) -> User:
    return User(
        id=row.id,  # type: ignore[arg-type]
        email=row.email,
        password_hash=row.password_hash,
        created_at=row.created_at,
    )


def _guest(row: GuestRow) -> Guest:
    return Guest(id=row.id, created_at=row.created_at)  # type: ignore[arg-type]


def _convo(row: ConversationRow) -> Conversation:
    return Conversation(
        id=row.id,  # type: ignore[arg-type]
        user_id=row.user_id,  # type: ignore[arg-type]
        guest_id=row.guest_id,  # type: ignore[arg-type]
        created_at=row.created_at,
    )


def _message(row: MessageRow) -> Message:
    return Message(
        id=row.id,  # type: ignore[arg-type]
        conversation_id=row.conversation_id,  # type: ignore[arg-type]
        role=row.role,
        content=row.content,
        created_at=row.created_at,
    )


class SqlAlchemyUnitOfWork:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.users = UserRepo(session)
        self.guests = GuestRepo(session)
        self.conversations = ConversationRepo(session)
        self.messages = MessageRepo(session)

    async def commit(self) -> None:
        await self.session.commit()

    async def rollback(self) -> None:
        await self.session.rollback()


class UserRepo:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_email(self, email: str) -> User | None:
        result = await self._session.execute(select(UserRow).where(UserRow.email == email))
        row = result.scalar_one_or_none()
        return _user(row) if row else None

    async def get_by_id(self, user_id: UUID) -> User | None:
        row = await self._session.get(UserRow, user_id)
        return _user(row) if row else None

    async def create(self, email: str, password_hash: str) -> User:
        row = UserRow(email=email, password_hash=password_hash)
        self._session.add(row)
        await self._session.flush()
        return _user(row)


class GuestRepo:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, guest_id: UUID) -> Guest | None:
        row = await self._session.get(GuestRow, guest_id)
        return _guest(row) if row else None

    async def create(self, guest_id: UUID | None = None) -> Guest:
        row = GuestRow(id=guest_id or uuid4())
        self._session.add(row)
        await self._session.flush()
        return _guest(row)

    async def delete_older_than(self, cutoff: datetime) -> int:
        result = await self._session.execute(delete(GuestRow).where(GuestRow.created_at < cutoff))
        return int(result.rowcount or 0)


class ConversationRepo:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_for_user(self, user_id: UUID) -> Conversation | None:
        result = await self._session.execute(
            select(ConversationRow).where(ConversationRow.user_id == user_id)
        )
        row = result.scalar_one_or_none()
        return _convo(row) if row else None

    async def get_for_guest(self, guest_id: UUID) -> Conversation | None:
        result = await self._session.execute(
            select(ConversationRow).where(ConversationRow.guest_id == guest_id)
        )
        row = result.scalar_one_or_none()
        return _convo(row) if row else None

    async def create_for_user(self, user_id: UUID) -> Conversation:
        row = ConversationRow(user_id=user_id)
        self._session.add(row)
        await self._session.flush()
        return _convo(row)

    async def create_for_guest(self, guest_id: UUID) -> Conversation:
        row = ConversationRow(guest_id=guest_id)
        self._session.add(row)
        await self._session.flush()
        return _convo(row)


class MessageRepo:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def list_before(
        self,
        conversation_id: UUID,
        *,
        limit: int,
        before_id: UUID | None,
    ) -> tuple[list[Message], bool]:
        stmt = select(MessageRow).where(MessageRow.conversation_id == conversation_id)
        if before_id is not None:
            pivot = (
                await self._session.execute(select(MessageRow).where(MessageRow.id == before_id))
            ).scalar_one_or_none()
            if pivot is None or pivot.conversation_id != conversation_id:
                return [], False
            stmt = stmt.where(MessageRow.seq < pivot.seq)
        stmt = stmt.order_by(MessageRow.seq.desc()).limit(limit + 1)
        rows = list((await self._session.execute(stmt)).scalars().all())
        has_more = len(rows) > limit
        rows = rows[:limit]
        rows.reverse()
        return [_message(row) for row in rows], has_more

    async def add(self, conversation_id: UUID, role: str, content: str) -> Message:
        row = MessageRow(conversation_id=conversation_id, role=role, content=content)
        self._session.add(row)
        await self._session.flush()
        return _message(row)

    async def list_all_for_context(self, conversation_id: UUID) -> list[Message]:
        stmt = (
            select(MessageRow)
            .where(MessageRow.conversation_id == conversation_id)
            .order_by(MessageRow.seq.asc())
        )
        rows = (await self._session.execute(stmt)).scalars().all()
        return [_message(row) for row in rows]
