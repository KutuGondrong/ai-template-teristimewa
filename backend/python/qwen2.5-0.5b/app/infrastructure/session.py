from __future__ import annotations

from uuid import UUID

from itsdangerous import BadSignature, SignatureExpired, URLSafeTimedSerializer


class SignedSessionStore:
    def __init__(self, secret_key: str, *, max_age_seconds: int) -> None:
        self._serializer = URLSafeTimedSerializer(secret_key, salt="session")
        self._max_age = max_age_seconds

    def issue(self, user_id: UUID) -> str:
        return self._serializer.dumps({"uid": str(user_id)})

    def resolve(self, token: str) -> UUID | None:
        try:
            data = self._serializer.loads(token, max_age=self._max_age)
        except (BadSignature, SignatureExpired):
            return None
        try:
            return UUID(str(data["uid"]))
        except (KeyError, ValueError, TypeError):
            return None
