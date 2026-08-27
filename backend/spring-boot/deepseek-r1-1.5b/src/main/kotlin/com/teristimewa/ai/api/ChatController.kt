package com.teristimewa.ai.api

import com.fasterxml.jackson.databind.ObjectMapper
import com.teristimewa.ai.application.IdentityService
import com.teristimewa.ai.infrastructure.ChatRepository
import com.teristimewa.ai.infrastructure.OllamaClient
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import jakarta.validation.Valid
import org.springframework.http.MediaType
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody
import java.util.UUID

@RestController
class ChatController(
    private val identities: IdentityService,
    private val repository: ChatRepository,
    private val ollama: OllamaClient,
    private val mapper: ObjectMapper,
) {
    @GetMapping("/api/messages")
    fun messages(
        request: HttpServletRequest,
        response: HttpServletResponse,
        @RequestParam(defaultValue = "10") limit: Int,
        @RequestParam(required = false) before: UUID?,
    ): MessagesOut {
        val (items, hasMore) = repository.listPage(identities.resolve(request, response), limit, before)
        return MessagesOut(
            items =
                items.map { row ->
                    MessageOut(row.id, row.role, row.content, row.createdAt)
                },
            hasMore = hasMore,
        )
    }

    @PostMapping("/api/chat", produces = [MediaType.TEXT_EVENT_STREAM_VALUE])
    fun chat(
        request: HttpServletRequest,
        response: HttpServletResponse,
        @Valid @RequestBody body: ChatRequest,
    ): StreamingResponseBody {
        val identity = identities.resolve(request, response)
        repository.add(identity, "user", body.message.trim())
        val history =
            repository.listAllForContext(identity).map { row ->
                mapOf("role" to row.role, "content" to row.content)
            }
        return StreamingResponseBody { output ->
            fun emit(payload: Map<String, Any>) {
                output.write("data: ${mapper.writeValueAsString(payload)}\n\n".toByteArray())
                output.flush()
            }
            try {
                val answer =
                    ollama.stream(history) { token ->
                        emit(mapOf("content" to token))
                    }
                if (answer.isNotBlank()) {
                    repository.add(identity, "assistant", answer)
                }
                emit(mapOf("done" to true))
            } catch (exc: Exception) {
                emit(mapOf("error" to "chat_failed", "message" to (exc.message ?: "chat_failed")))
            }
        }
    }
}
