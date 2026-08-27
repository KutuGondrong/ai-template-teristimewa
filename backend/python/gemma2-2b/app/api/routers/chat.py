from __future__ import annotations

import json
from typing import Annotated

from fastapi import APIRouter, Depends, Request
from fastapi.responses import StreamingResponse

from app.api.deps import attach_guest_cookie, get_identity
from app.api.schemas import ChatRequest
from app.application.auth import Identity
from app.application.chat import ChatService
from app.application.messages import MessageService
from app.config import Settings, get_settings
from app.domain.errors import AppError
from app.infrastructure.ollama import HttpOllamaClient
from app.infrastructure.repositories import SqlAlchemyUnitOfWork

router = APIRouter(tags=["chat"])


@router.post("/api/chat")
async def chat(
    body: ChatRequest,
    request: Request,
    identity: Annotated[Identity, Depends(get_identity)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> StreamingResponse:
    factory = request.app.state.session_factory

    async def event_stream():
        try:
            async with factory() as session:
                uow = SqlAlchemyUnitOfWork(session)
                ollama = HttpOllamaClient(settings.ollama_base_url, settings.ollama_model)
                service = ChatService(uow, MessageService(uow), ollama)
                async for token in service.stream(identity, body.message):
                    yield "data: " + json.dumps({"content": token}) + "\n\n"
                yield "data: " + json.dumps({"done": True}) + "\n\n"
        except AppError as exc:
            yield "data: " + json.dumps({"error": exc.code, "message": exc.message}) + "\n\n"
        except Exception as exc:  # noqa: BLE001
            yield "data: " + json.dumps({"error": "chat_failed", "message": str(exc)}) + "\n\n"

    stream = StreamingResponse(event_stream(), media_type="text/event-stream")
    attach_guest_cookie(stream, settings, identity)
    return stream
