from __future__ import annotations

import asyncio
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.errors import register_exception_handlers
from app.api.routers import auth, chat, health, messages
from app.application.cleanup import GuestCleanupService, run_guest_cleanup_loop
from app.application.rate_limit import InMemoryRateLimiter
from app.config import get_settings
from app.infrastructure.database import create_engine, create_session_factory, init_db
from app.infrastructure.repositories import SqlAlchemyUnitOfWork


def create_app() -> FastAPI:
    settings = get_settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        engine = create_engine(settings.database_url)
        session_factory = create_session_factory(engine)
        await init_db(engine)
        app.state.engine = engine
        app.state.session_factory = session_factory
        app.state.rate_limiter = InMemoryRateLimiter()

        async def purge_expired_guests() -> int:
            async with session_factory() as session:
                return await GuestCleanupService(SqlAlchemyUnitOfWork(session)).cleanup_expired()

        cleanup_task = asyncio.create_task(run_guest_cleanup_loop(purge_expired_guests))
        yield
        cleanup_task.cancel()
        await asyncio.gather(cleanup_task, return_exceptions=True)
        await engine.dispose()

    app = FastAPI(
        title="AI Chat API",
        lifespan=lifespan,
        docs_url="/docs" if settings.app_env in {"local", "dev"} else None,
        redoc_url=None,
        openapi_url="/openapi.json" if settings.app_env in {"local", "dev"} else None,
    )
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
    return app


app = create_app()


def run() -> None:
    settings = get_settings()
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=False,
    )


if __name__ == "__main__":
    run()
