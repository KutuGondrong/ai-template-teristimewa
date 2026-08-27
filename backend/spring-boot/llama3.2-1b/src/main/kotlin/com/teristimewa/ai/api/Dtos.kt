package com.teristimewa.ai.api

import com.fasterxml.jackson.annotation.JsonProperty
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import java.time.Instant
import java.util.UUID

data class AuthRequest(
    @field:Email val email: String,
    @field:Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d).{8,}$") val password: String,
)

data class UserOut(
    val type: String = "user",
    val id: UUID,
    val email: String,
)

data class GuestOut(
    val type: String = "guest",
    val id: UUID,
)

data class ChatRequest(
    @field:NotBlank val message: String,
)

data class MessageOut(
    val id: UUID,
    val role: String,
    val content: String,
    @param:JsonProperty("created_at")
    @get:JsonProperty("created_at")
    val createdAt: Instant,
)

data class MessagesOut(
    val items: List<MessageOut>,
    @param:JsonProperty("has_more")
    @get:JsonProperty("has_more")
    val hasMore: Boolean,
)
