package com.teristimewa.ai.infrastructure

import com.fasterxml.jackson.databind.ObjectMapper
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Component
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration

@Component
class OllamaClient(
    private val mapper: ObjectMapper,
    @Value("\${app.ollama-base-url}") private val baseUrl: String,
    @Value("\${app.ollama-model}") private val model: String,
) {
    private val http =
        HttpClient
            .newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build()

    fun ready(): Boolean =
        runCatching {
            val request =
                HttpRequest
                    .newBuilder(URI.create("$baseUrl/api/tags"))
                    .timeout(Duration.ofSeconds(5))
                    .GET()
                    .build()
            http.send(request, HttpResponse.BodyHandlers.discarding()).statusCode() == 200
        }.getOrDefault(false)

    fun stream(
        messages: List<Map<String, String>>,
        onToken: (String) -> Unit,
    ): String {
        val payload =
            mapper.writeValueAsString(
                mapOf(
                    "model" to model,
                    "messages" to messages,
                    "stream" to true,
                ),
            )
        val request =
            HttpRequest
                .newBuilder(URI.create("$baseUrl/api/chat"))
                .timeout(Duration.ofSeconds(120))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(payload))
                .build()
        val response = http.send(request, HttpResponse.BodyHandlers.ofLines())
        require(response.statusCode() in 200..299) { "Ollama returned ${response.statusCode()}" }
        val answer = StringBuilder()
        response.body().use { lines ->
            lines.forEach { line ->
                if (line.isBlank()) return@forEach
                val node = mapper.readTree(line)
                if (node.path("done").asBoolean(false)) return@forEach
                val token = node.path("message").path("content").asText()
                if (token.isNotEmpty()) {
                    answer.append(token)
                    onToken(token)
                }
            }
        }
        return answer.toString().trim()
    }
}
