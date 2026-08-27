package com.teristimewa.ai.api

import com.teristimewa.ai.infrastructure.OllamaClient
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import javax.sql.DataSource

@RestController
class HealthController(
    private val dataSource: DataSource,
    private val ollama: OllamaClient,
) {
    @GetMapping("/api/health")
    fun health() = mapOf("status" to "ok")

    @GetMapping("/api/ready")
    fun ready(): ResponseEntity<Map<String, String>> {
        val dbReady = runCatching { dataSource.connection.use { it.isValid(2) } }.getOrDefault(false)
        val status = if (dbReady && ollama.ready()) "ready" else "not_ready"
        return if (status == "ready") {
            ResponseEntity.ok(mapOf("status" to status))
        } else {
            ResponseEntity.status(503).body(mapOf("status" to status))
        }
    }
}
