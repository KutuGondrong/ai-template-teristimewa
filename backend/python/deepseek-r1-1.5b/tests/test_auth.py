from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_signup_login_me_logout(client: AsyncClient) -> None:
    signup = await client.post(
        "/api/auth/signup",
        json={"email": "User@Example.com", "password": "secret123"},
    )
    assert signup.status_code == 200
    assert signup.json()["email"] == "user@example.com"
    assert "session" not in signup.cookies

    after_signup = await client.get("/api/auth/me")
    assert after_signup.status_code == 200
    assert after_signup.json()["type"] == "guest"

    login = await client.post(
        "/api/auth/login",
        json={"email": "user@example.com", "password": "secret123"},
    )
    assert login.status_code == 200
    assert login.json()["type"] == "user"
    assert "session" in login.cookies

    me = await client.get("/api/auth/me")
    assert me.status_code == 200
    assert me.json()["type"] == "user"

    await client.post("/api/auth/logout")
    guest_me = await client.get("/api/auth/me")
    assert guest_me.status_code == 200
    assert guest_me.json()["type"] == "guest"
    assert "guest_id" in guest_me.cookies


@pytest.mark.asyncio
async def test_weak_password_rejected(client: AsyncClient) -> None:
    response = await client.post(
        "/api/auth/signup",
        json={"email": "a@b.com", "password": "short"},
    )
    assert response.status_code == 400
    assert response.json()["code"] == "weak_password"


@pytest.mark.asyncio
async def test_email_taken(client: AsyncClient) -> None:
    payload = {"email": "dup@example.com", "password": "secret123"}
    assert (await client.post("/api/auth/signup", json=payload)).status_code == 200
    again = await client.post("/api/auth/signup", json=payload)
    assert again.status_code == 409
    assert again.json()["code"] == "email_taken"


@pytest.mark.asyncio
async def test_wrong_credentials(client: AsyncClient) -> None:
    await client.post(
        "/api/auth/signup",
        json={"email": "x@y.com", "password": "secret123"},
    )
    bad = await client.post(
        "/api/auth/login",
        json={"email": "x@y.com", "password": "wrong9999"},
    )
    assert bad.status_code == 401
