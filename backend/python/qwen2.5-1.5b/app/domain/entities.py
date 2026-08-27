from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass(slots=True)
class User:
    id: UUID
    email: str
    password_hash: str
    created_at: datetime


@dataclass(slots=True)
class Guest:
    id: UUID
    created_at: datetime


@dataclass(slots=True)
class Conversation:
    id: UUID
    user_id: UUID | None
    guest_id: UUID | None
    created_at: datetime


@dataclass(slots=True)
class Message:
    id: UUID
    conversation_id: UUID
    role: str
    content: str
    created_at: datetime
