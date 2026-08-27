from __future__ import annotations

from collections.abc import AsyncIterator

from app.application.auth import Identity
from app.application.messages import MessageService
from app.application.ports import OllamaClient, UnitOfWork


class ChatService:
    def __init__(
        self,
        uow: UnitOfWork,
        messages: MessageService,
        ollama: OllamaClient,
    ) -> None:
        self._uow = uow
        self._messages = messages
        self._ollama = ollama

    async def stream(self, identity: Identity, content: str) -> AsyncIterator[str]:
        text = content.strip()
        if not text:
            raise ValueError("Message is empty")
        convo = await self._messages.thread_for(identity)
        await self._uow.messages.add(convo.id, "user", text)
        await self._uow.commit()
        history = await self._uow.messages.list_all_for_context(convo.id)
        payload = [{"role": m.role, "content": m.content} for m in history]
        chunks: list[str] = []
        async for token in self._ollama.stream_chat(payload):
            chunks.append(token)
            yield token
        assistant = "".join(chunks).strip()
        if assistant:
            await self._uow.messages.add(convo.id, "assistant", assistant)
            await self._uow.commit()
