from __future__ import annotations

import pytest
from app.application.validation import normalize_email, validate_password
from app.domain.errors import InvalidEmailError, WeakPasswordError


def test_normalize_email() -> None:
    assert normalize_email("  Foo@Bar.COM ") == "foo@bar.com"


def test_invalid_email() -> None:
    with pytest.raises(InvalidEmailError):
        normalize_email("not-an-email")


def test_password_rules() -> None:
    assert validate_password("abcdefg1") == "abcdefg1"
    with pytest.raises(WeakPasswordError):
        validate_password("abcdefgh")
    with pytest.raises(WeakPasswordError):
        validate_password("12345678")
