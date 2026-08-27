from __future__ import annotations

from app.config import get_settings
from app.main import create_app


def test_swagger_enabled_for_local() -> None:
    assert get_settings().app_env == "local"
    app = create_app()
    assert app.docs_url == "/docs"
    assert app.openapi_url == "/openapi.json"


def test_swagger_disabled_for_prod(monkeypatch) -> None:
    monkeypatch.setenv("APP_ENV", "prod")
    get_settings.cache_clear()
    try:
        app = create_app()
        assert app.docs_url is None
        assert app.openapi_url is None
    finally:
        monkeypatch.setenv("APP_ENV", "local")
        get_settings.cache_clear()
