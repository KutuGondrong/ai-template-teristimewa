from __future__ import annotations

from uuid import UUID

from app.application.auth import Identity
from app.application.ports import UnitOfWork
from app.domain.entities import Conversation, Message
from app.domain.errors import NotFoundError


class MessageService:
    def __init__(self, uow: UnitOfWork) -> None:
        self._uow = uow

    async def thread_for(self, identity: Identity) -> Conversation:
        if identity.user is not None:
            convo = await self._uow.conversations.get_for_user(identity.user.id)
        else:
            assert identity.guest is not None
            convo = await self._uow.conversations.get_for_guest(identity.guest.id)
        if convo is None:
            raise NotFoundError("Conversation not found")
        return convo

    async def list_messages(
        self,
        identity: Identity,
        *,
        limit: int,
        before: UUID | None,
    ) -> tuple[list[Message], bool]:
        convo = await self.thread_for(identity)
        return await self._uow.messages.list_before(convo.id, limit=limit, before_id=before)
