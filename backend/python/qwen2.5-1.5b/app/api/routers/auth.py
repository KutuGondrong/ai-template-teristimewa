from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Request, Response

from app.api.deps import get_auth_service, get_identity, get_rate_limiter
from app.api.schemas import AuthRequest, GuestOut, UserOut
from app.application.auth import AuthService, Identity
from app.application.rate_limit import InMemoryRateLimiter
from app.config import Settings, get_settings

router = APIRouter(prefix="/api/auth", tags=["auth"])


def _set_session_cookie(response: Response, settings: Settings, token: str) -> None:
    response.set_cookie(
        key=settings.session_cookie_name,
        value=token,
        httponly=True,
        samesite=settings.cookie_samesite,  # type: ignore[arg-type]
        secure=settings.cookie_secure,
        max_age=settings.session_max_age_seconds,
        path="/",
    )


@router.post("/signup", response_model=UserOut)
async def signup(
    body: AuthRequest,
    request: Request,
    auth: Annotated[AuthService, Depends(get_auth_service)],
    limiter: Annotated[InMemoryRateLimiter, Depends(get_rate_limiter)],
) -> UserOut:
    limiter.check(f"signup:{request.client.host if request.client else 'unknown'}")
    result = await auth.signup(body.email, body.password)
    return UserOut(id=result.user.id, email=result.user.email)


@router.post("/login", response_model=UserOut)
async def login(
    body: AuthRequest,
    request: Request,
    response: Response,
    auth: Annotated[AuthService, Depends(get_auth_service)],
    settings: Annotated[Settings, Depends(get_settings)],
    limiter: Annotated[InMemoryRateLimiter, Depends(get_rate_limiter)],
) -> UserOut:
    limiter.check(f"login:{request.client.host if request.client else 'unknown'}")
    result = await auth.login(body.email, body.password)
    _set_session_cookie(response, settings, result.session_token)
    return UserOut(id=result.user.id, email=result.user.email)


@router.post("/logout")
async def logout(
    response: Response,
    settings: Annotated[Settings, Depends(get_settings)],
) -> dict[str, str]:
    response.delete_cookie(settings.session_cookie_name, path="/")
    return {"status": "ok"}


@router.get("/me")
async def me(
    identity: Annotated[Identity, Depends(get_identity)],
) -> UserOut | GuestOut:
    if identity.user is not None:
        return UserOut(id=identity.user.id, email=identity.user.email)
    assert identity.guest is not None
    return GuestOut(id=identity.guest.id)
