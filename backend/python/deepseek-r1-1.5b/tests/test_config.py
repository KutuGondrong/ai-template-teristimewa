from __future__ import annotations

from app.config import get_settings, parse_cors_value


def test_parse_cors_json() -> None:
    assert parse_cors_value('["http://localhost:3000","http://127.0.0.1:3000"]') == [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ]


def test_parse_cors_bash_stripped_json() -> None:
    assert parse_cors_value("[http://localhost:3000,http://127.0.0.1:3000]") == [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ]


def test_parse_cors_comma_list() -> None:
    assert parse_cors_value("http://localhost:3000, http://127.0.0.1:3000") == [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ]


def test_settings_accepts_bash_stripped_cors(monkeypatch) -> None:
    monkeypatch.setenv("CORS_ORIGINS", "[http://localhost:3000,http://127.0.0.1:3000]")
    get_settings.cache_clear()
    try:
        settings = get_settings()
        assert settings.cors_origins == ["http://localhost:3000", "http://127.0.0.1:3000"]
    finally:
        get_settings.cache_clear()
