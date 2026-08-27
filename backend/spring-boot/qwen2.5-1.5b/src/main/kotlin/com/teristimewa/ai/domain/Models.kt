package com.teristimewa.ai.domain

import java.time.Instant
import java.util.UUID

data class ChatMessage(
    val id: UUID,
    val role: String,
    val content: String,
    val createdAt: Instant,
)

data class Identity(
    val userId: UUID? = null,
    val guestId: UUID? = null,
) {
    init {
        require((userId == null) xor (guestId == null))
    }
}
