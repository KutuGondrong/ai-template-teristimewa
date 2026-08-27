from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Request
from sqlalchemy import text

from app.api.schemas import HealthOut, ReadyOut
from app.config import Settings, get_settings
from app.infrastructure.ollama import HttpOllamaClient

router = APIRouter(tags=["health"])


@router.get("/api/health", response_model=HealthOut)
async def health() -> HealthOut:
    return HealthOut(status="ok")


@router.get("/api/ready", response_model=ReadyOut)
async def ready(
    request: Request,
    settings: Annotated[Settings, Depends(get_settings)],
) -> ReadyOut:
    db_ok = False
    try:
        async with request.app.state.session_factory() as session:
            await session.execute(text("SELECT 1"))
            db_ok = True
    except Exception:
        db_ok = False
    ollama = HttpOllamaClient(settings.ollama_base_url, settings.ollama_model)
    ollama_ok = await ollama.health()
    status = "ok" if db_ok and ollama_ok else "degraded"
    return ReadyOut(status=status, database=db_ok, ollama=ollama_ok)
