from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_chat_streams_with_mocked_ollama(client: AsyncClient, mock_ollama: list[str]) -> None:
    response = await client.post("/api/chat", json={"message": "Hello model"})
    assert response.status_code == 200
    assert "text/event-stream" in response.headers["content-type"]
    assert "Hello" in response.text
    assert '"done": true' in response.text or '"done":true' in response.text
