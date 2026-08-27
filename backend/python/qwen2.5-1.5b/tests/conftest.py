from __future__ import annotations

import os
from collections.abc import AsyncIterator, Iterator
from contextlib import asynccontextmanager
from pathlib import Path

import pytest
import pytest_asyncio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "test.db"

os.environ["APP_ENV"] = "local"
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{DB_PATH}"
os.environ["SECRET_KEY"] = "test-secret"
os.environ["OLLAMA_BASE_URL"] = "http://127.0.0.1:11434"
os.environ["OLLAMA_MODEL"] = "test-model"

from app.api.errors import register_exception_handlers  # noqa: E402
from app.api.routers import auth, chat, health, messages  # noqa: E402
from app.application.rate_limit import InMemoryRateLimiter  # noqa: E402
from app.config import get_settings  # noqa: E402
from app.infrastructure.database import create_engine, create_session_factory  # noqa: E402
from app.infrastructure.orm import Base  # noqa: E402

get_settings.cache_clear()


def build_test_app(session_factory: async_sessionmaker[AsyncSession]) -> FastAPI:
    settings = get_settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        app.state.session_factory = session_factory
        app.state.rate_limiter = InMemoryRateLimiter()
        yield

    app = FastAPI(lifespan=lifespan)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    register_exception_handlers(app)
    app.include_router(health.router)
    app.include_router(auth.router)
    app.include_router(messages.router)
    app.include_router(chat.router)
    app.state.session_factory = session_factory
    app.state.rate_limiter = InMemoryRateLimiter()
    return app


@pytest_asyncio.fixture()
async def session_factory() -> AsyncIterator[async_sessionmaker[AsyncSession]]:
    get_settings.cache_clear()
    if DB_PATH.exists():
        DB_PATH.unlink()
    engine = create_engine(get_settings().database_url)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    factory = create_session_factory(engine)
    yield factory
    await engine.dispose()
    if DB_PATH.exists():
        DB_PATH.unlink()


@pytest_asyncio.fixture()
async def client(session_factory) -> AsyncIterator[AsyncClient]:
    app = build_test_app(session_factory)
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.fixture()
def mock_ollama(monkeypatch: pytest.MonkeyPatch) -> Iterator[list[str]]:
    tokens = ["Hello", " ", "world"]

    class FakeOllama:
        async def health(self) -> bool:
            return True

        async def stream_chat(self, messages: list[dict[str, str]]):
            for token in tokens:
                yield token

    monkeypatch.setattr("app.api.deps.HttpOllamaClient", lambda *a, **k: FakeOllama())
    monkeypatch.setattr("app.api.routers.health.HttpOllamaClient", lambda *a, **k: FakeOllama())
    monkeypatch.setattr("app.api.routers.chat.HttpOllamaClient", lambda *a, **k: FakeOllama())
    yield tokens
