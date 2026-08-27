from __future__ import annotations

from collections.abc import AsyncIterator
from typing import Annotated

from fastapi import Depends, Request, Response
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.application.auth import AuthService, Identity
from app.application.chat import ChatService
from app.application.messages import MessageService
from app.application.rate_limit import InMemoryRateLimiter
from app.config import Settings, get_settings
from app.infrastructure.ollama import HttpOllamaClient
from app.infrastructure.password import Argon2PasswordHasher
from app.infrastructure.repositories import SqlAlchemyUnitOfWork
from app.infrastructure.session import SignedSessionStore


def get_session_factory(request: Request) -> async_sessionmaker[AsyncSession]:
    return request.app.state.session_factory


async def get_uow(
    factory: Annotated[async_sessionmaker[AsyncSession], Depends(get_session_factory)],
) -> AsyncIterator[SqlAlchemyUnitOfWork]:
    async with factory() as session:
        uow = SqlAlchemyUnitOfWork(session)
        try:
            yield uow
        except Exception:
            await uow.rollback()
            raise


def get_hasher() -> Argon2PasswordHasher:
    return Argon2PasswordHasher()


def get_sessions(settings: Annotated[Settings, Depends(get_settings)]) -> SignedSessionStore:
    return SignedSessionStore(
        settings.secret_key,
        max_age_seconds=settings.session_max_age_seconds,
    )


def get_ollama(settings: Annotated[Settings, Depends(get_settings)]) -> HttpOllamaClient:
    return HttpOllamaClient(settings.ollama_base_url, settings.ollama_model)


def get_auth_service(
    uow: Annotated[SqlAlchemyUnitOfWork, Depends(get_uow)],
    hasher: Annotated[Argon2PasswordHasher, Depends(get_hasher)],
    sessions: Annotated[SignedSessionStore, Depends(get_sessions)],
) -> AuthService:
    return AuthService(uow, hasher, sessions)


def get_message_service(
    uow: Annotated[SqlAlchemyUnitOfWork, Depends(get_uow)],
) -> MessageService:
    return MessageService(uow)


def get_chat_service(
    uow: Annotated[SqlAlchemyUnitOfWork, Depends(get_uow)],
    messages: Annotated[MessageService, Depends(get_message_service)],
    ollama: Annotated[HttpOllamaClient, Depends(get_ollama)],
) -> ChatService:
    return ChatService(uow, messages, ollama)


def get_rate_limiter(request: Request) -> InMemoryRateLimiter:
    return request.app.state.rate_limiter


def attach_guest_cookie(response: Response, settings: Settings, identity: Identity) -> None:
    if identity.kind != "guest" or identity.guest is None:
        return
    response.set_cookie(
        key=settings.guest_cookie_name,
        value=str(identity.guest.id),
        httponly=True,
        samesite=settings.cookie_samesite,  # type: ignore[arg-type]
        secure=settings.cookie_secure,
        max_age=settings.guest_max_age_seconds,
        path="/",
    )


async def get_identity(
    request: Request,
    response: Response,
    auth: Annotated[AuthService, Depends(get_auth_service)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> Identity:
    session_token = request.cookies.get(settings.session_cookie_name)
    guest_cookie = request.cookies.get(settings.guest_cookie_name)
    identity = await auth.resolve_identity(session_token, guest_cookie)
    attach_guest_cookie(response, settings, identity)
    return identity
