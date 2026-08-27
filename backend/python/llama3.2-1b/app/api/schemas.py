from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class AuthRequest(BaseModel):
    email: str
    password: str = Field(min_length=1)


class UserOut(BaseModel):
    type: str = "user"
    id: UUID
    email: str


class GuestOut(BaseModel):
    type: str = "guest"
    id: UUID


class MessageOut(BaseModel):
    id: UUID
    role: str
    content: str
    created_at: datetime


class MessagesOut(BaseModel):
    items: list[MessageOut]
    has_more: bool


class ChatRequest(BaseModel):
    message: str = Field(min_length=1)


class ErrorOut(BaseModel):
    code: str
    message: str


class HealthOut(BaseModel):
    status: str


class ReadyOut(BaseModel):
    status: str
    database: bool
    ollama: bool
