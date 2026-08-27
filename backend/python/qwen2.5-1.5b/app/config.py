from __future__ import annotations

import json
import os
from functools import lru_cache
from pathlib import Path
from typing import Any

import yaml
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

ROOT = Path(__file__).resolve().parents[1]

DEFAULT_CORS_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "http://localhost:5174",
    "http://127.0.0.1:5174",
]

_ENV_OVERRIDES = {
    "DATABASE_URL": "database_url",
    "OLLAMA_BASE_URL": "ollama_base_url",
    "OLLAMA_MODEL": "ollama_model",
    "SECRET_KEY": "secret_key",
    "COOKIE_SECURE": "cookie_secure",
    "COOKIE_SAMESITE": "cookie_samesite",
    "CORS_ORIGINS": "cors_origins",
}


def parse_cors_value(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(part).strip() for part in value if str(part).strip()]
    if not isinstance(value, str):
        return [str(value)]
    raw = value.strip()
    if not raw:
        return []
    if raw.startswith("["):
        try:
            parsed = json.loads(raw)
            if isinstance(parsed, list):
                return [str(part).strip() for part in parsed if str(part).strip()]
        except json.JSONDecodeError:
            inner = raw[1:-1] if raw.endswith("]") else raw[1:]
            return [
                part.strip().strip("'\"")
                for part in inner.split(",")
                if part.strip().strip("'\"")
            ]
    return [part.strip() for part in raw.split(",") if part.strip()]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file_encoding="utf-8",
        extra="ignore",
        populate_by_name=True,
    )

    app_env: str = Field(default="local", validation_alias="APP_ENV")
    host: str = "127.0.0.1"
    port: int = 8000
    database_url: str = Field(validation_alias="DATABASE_URL")
    ollama_base_url: str = Field(validation_alias="OLLAMA_BASE_URL")
    ollama_model: str = Field(validation_alias="OLLAMA_MODEL")
    cors_origins: list[str] = Field(default_factory=lambda: list(DEFAULT_CORS_ORIGINS))
    cookie_secure: bool = False
    cookie_samesite: str = "lax"
    secret_key: str = Field(validation_alias="SECRET_KEY")
    session_cookie_name: str = "session"
    guest_cookie_name: str = "guest_id"
    session_max_age_seconds: int = 2592000
    guest_max_age_seconds: int = 86400
    messages_default_limit: int = 10

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors(cls, value: Any) -> list[str]:
        return parse_cors_value(value)


def _load_yaml(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    if not isinstance(data, dict):
        raise ValueError(f"Invalid settings file: {path}")
    return data


@lru_cache
def get_settings() -> Settings:
    env = os.getenv("APP_ENV", "local").strip().lower() or "local"
    shared = _load_yaml(ROOT / "settings.yaml")
    profile = _load_yaml(ROOT / f"settings.{env}.yaml")
    merged: dict[str, Any] = {**shared, **profile, "app_env": env}
    for env_name, field_name in _ENV_OVERRIDES.items():
        if env_name in os.environ:
            merged[field_name] = os.environ[env_name]
    if "cors_origins" in merged:
        origins = parse_cors_value(merged["cors_origins"])
        merged["cors_origins"] = origins
        os.environ["CORS_ORIGINS"] = json.dumps(origins)
    env_file = ROOT / f".env.{env}"
    return Settings(_env_file=env_file if env_file.exists() else None, **merged)
