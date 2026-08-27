from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_guest_gets_empty_thread_then_one_thread(
    client: AsyncClient, mock_ollama: list[str]
) -> None:
    me = await client.get("/api/auth/me")
    assert me.json()["type"] == "guest"

    empty = await client.get("/api/messages?limit=10")
    assert empty.status_code == 200
    assert empty.json()["items"] == []
    assert empty.json()["has_more"] is False

    stream = await client.post("/api/chat", json={"message": "hi there"})
    assert stream.status_code == 200
    body = stream.text
    assert "Hello" in body

    page = await client.get("/api/messages?limit=10")
    items = page.json()["items"]
    assert len(items) == 2
    assert items[0]["role"] == "user"
    assert items[1]["role"] == "assistant"


@pytest.mark.asyncio
async def test_messages_pagination(client: AsyncClient, mock_ollama: list[str]) -> None:
    await client.post("/api/auth/signup", json={"email": "p@e.com", "password": "secret123"})
    await client.post("/api/auth/login", json={"email": "p@e.com", "password": "secret123"})
    for i in range(5):
        await client.post("/api/chat", json={"message": f"msg-{i}"})

    first = await client.get("/api/messages?limit=2")
    data = first.json()
    assert len(data["items"]) == 2
    assert data["has_more"] is True
    before = data["items"][0]["id"]
    older = await client.get(f"/api/messages?limit=2&before={before}")
    assert older.status_code == 200
    assert len(older.json()["items"]) == 2


@pytest.mark.asyncio
async def test_login_uses_user_thread_not_guest(
    client: AsyncClient, mock_ollama: list[str]
) -> None:
    await client.post("/api/chat", json={"message": "guest-only"})
    guest_page = await client.get("/api/messages")
    assert any(item["content"] == "guest-only" for item in guest_page.json()["items"])

    signup = await client.post(
        "/api/auth/signup", json={"email": "u@e.com", "password": "secret123"}
    )
    assert signup.status_code == 200
    after_signup = await client.get("/api/auth/me")
    assert after_signup.json()["type"] == "guest"
    guest_still = [item["content"] for item in (await client.get("/api/messages")).json()["items"]]
    assert "guest-only" in guest_still

    login = await client.post(
        "/api/auth/login", json={"email": "u@e.com", "password": "secret123"}
    )
    assert login.status_code == 200
    after_login = await client.get("/api/messages")
    assert after_login.json()["items"] == []

    await client.post("/api/chat", json={"message": "user-only"})
    await client.post("/api/auth/logout")
    guest_again = [item["content"] for item in (await client.get("/api/messages")).json()["items"]]
    assert "guest-only" in guest_again
    assert "user-only" not in guest_again

    again = await client.post(
        "/api/auth/login", json={"email": "u@e.com", "password": "secret123"}
    )
    assert again.status_code == 200
    user_items = (await client.get("/api/messages")).json()["items"]
    contents = [item["content"] for item in user_items]
    roles = [item["role"] for item in user_items]
    assert "user-only" in contents
    assert "guest-only" not in contents
    assert "user" in roles
    assert "assistant" in roles


@pytest.mark.asyncio
async def test_messages_default_last_ten(client: AsyncClient, mock_ollama: list[str]) -> None:
    await client.post("/api/auth/signup", json={"email": "p10@e.com", "password": "secret123"})
    await client.post("/api/auth/login", json={"email": "p10@e.com", "password": "secret123"})
    for i in range(7):
        await client.post("/api/chat", json={"message": f"msg-{i}"})

    page = await client.get("/api/messages")
    data = page.json()
    assert len(data["items"]) == 10
    assert data["has_more"] is True
    assert data["items"][-1]["role"] == "assistant"
    assert data["items"][-2]["content"] == "msg-6"

    older = await client.get(f"/api/messages?before={data['items'][0]['id']}")
    older_data = older.json()
    assert len(older_data["items"]) == 4
    assert older_data["has_more"] is False
    assert older_data["items"][0]["content"] == "msg-0"
