from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_identity, get_message_service
from app.api.schemas import MessageOut, MessagesOut
from app.application.auth import Identity
from app.application.messages import MessageService
from app.config import Settings, get_settings

router = APIRouter(tags=["messages"])


@router.get("/api/messages", response_model=MessagesOut)
async def list_messages(
    identity: Annotated[Identity, Depends(get_identity)],
    service: Annotated[MessageService, Depends(get_message_service)],
    settings: Annotated[Settings, Depends(get_settings)],
    limit: Annotated[int, Query(ge=1, le=100)] = 10,
    before: Annotated[UUID | None, Query()] = None,
) -> MessagesOut:
    effective_limit = limit or settings.messages_default_limit
    items, has_more = await service.list_messages(identity, limit=effective_limit, before=before)
    return MessagesOut(
        items=[
            MessageOut(
                id=item.id,
                role=item.role,
                content=item.content,
                created_at=item.created_at,
            )
            for item in items
        ],
        has_more=has_more,
    )
