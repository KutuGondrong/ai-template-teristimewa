from __future__ import annotations

import re

from pydantic import EmailStr, TypeAdapter, ValidationError

from app.domain.errors import InvalidEmailError, WeakPasswordError

_EMAIL = TypeAdapter(EmailStr)
_PASSWORD_RE = re.compile(r"^(?=.*[A-Za-z])(?=.*\d).{8,}$")


def normalize_email(email: str) -> str:
    value = email.strip().lower()
    try:
        return str(_EMAIL.validate_python(value))
    except ValidationError as exc:
        raise InvalidEmailError("Invalid email") from exc


def validate_password(password: str) -> str:
    if not _PASSWORD_RE.match(password):
        raise WeakPasswordError("Password must be at least 8 characters with letters and numbers")
    return password
