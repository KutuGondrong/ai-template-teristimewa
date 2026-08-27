from __future__ import annotations

from dataclasses import dataclass
from uuid import UUID

from app.application.cleanup import guest_expiry_cutoff
from app.application.ports import PasswordHasher, SessionStore, UnitOfWork
from app.application.validation import normalize_email, validate_password
from app.domain.entities import Guest, User
from app.domain.errors import EmailTakenError, InvalidCredentialsError


@dataclass(slots=True)
class AuthResult:
    user: User
    session_token: str


@dataclass(slots=True)
class Identity:
    kind: str
    user: User | None = None
    guest: Guest | None = None

    @property
    def user_id(self) -> UUID | None:
        return self.user.id if self.user else None

    @property
    def guest_id(self) -> UUID | None:
        return self.guest.id if self.guest else None


class AuthService:
    def __init__(
        self,
        uow: UnitOfWork,
        hasher: PasswordHasher,
        sessions: SessionStore,
    ) -> None:
        self._uow = uow
        self._hasher = hasher
        self._sessions = sessions

    async def signup(self, email: str, password: str) -> AuthResult:
        email = normalize_email(email)
        password = validate_password(password)
        if await self._uow.users.get_by_email(email) is not None:
            raise EmailTakenError("Email already registered")
        user = await self._uow.users.create(email, self._hasher.hash(password))
        await self._uow.conversations.create_for_user(user.id)
        await self._uow.commit()
        return AuthResult(user=user, session_token=self._sessions.issue(user.id))

    async def login(self, email: str, password: str) -> AuthResult:
        email = normalize_email(email)
        user = await self._uow.users.get_by_email(email)
        if user is None or not self._hasher.verify(password, user.password_hash):
            raise InvalidCredentialsError("Invalid email or password")
        if await self._uow.conversations.get_for_user(user.id) is None:
            await self._uow.conversations.create_for_user(user.id)
            await self._uow.commit()
        return AuthResult(user=user, session_token=self._sessions.issue(user.id))

    async def resolve_user(self, session_token: str | None) -> User | None:
        if not session_token:
            return None
        user_id = self._sessions.resolve(session_token)
        if user_id is None:
            return None
        return await self._uow.users.get_by_id(user_id)

    async def ensure_guest(self, guest_cookie: str | None) -> Guest:
        await self._uow.guests.delete_older_than(guest_expiry_cutoff())
        guest: Guest | None = None
        if guest_cookie:
            try:
                guest = await self._uow.guests.get_by_id(UUID(guest_cookie))
            except ValueError:
                guest = None
        if guest is None:
            guest = await self._uow.guests.create()
            await self._uow.conversations.create_for_guest(guest.id)
            await self._uow.commit()
        elif await self._uow.conversations.get_for_guest(guest.id) is None:
            await self._uow.conversations.create_for_guest(guest.id)
            await self._uow.commit()
        else:
            await self._uow.commit()
        return guest

    async def resolve_identity(
        self,
        session_token: str | None,
        guest_cookie: str | None,
    ) -> Identity:
        user = await self.resolve_user(session_token)
        if user is not None:
            if await self._uow.conversations.get_for_user(user.id) is None:
                await self._uow.conversations.create_for_user(user.id)
                await self._uow.commit()
            return Identity(kind="user", user=user)
        guest = await self.ensure_guest(guest_cookie)
        return Identity(kind="guest", guest=guest)
