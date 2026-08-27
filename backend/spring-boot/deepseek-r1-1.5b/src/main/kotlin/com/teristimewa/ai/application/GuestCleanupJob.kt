package com.teristimewa.ai.application

import com.teristimewa.ai.infrastructure.ChatRepository
import org.slf4j.LoggerFactory
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component

@Component
class GuestCleanupJob(
    private val repository: ChatRepository,
) {
    private val log = LoggerFactory.getLogger(javaClass)

    @Scheduled(initialDelay = 0, fixedRate = 3_600_000)
    fun cleanupExpiredGuests() {
        val deleted = repository.deleteOldGuests()
        if (deleted > 0) {
            log.info("Deleted {} guests older than 1 day", deleted)
        }
    }
}
