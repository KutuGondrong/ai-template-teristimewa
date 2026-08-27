package com.teristimewa.ai.infrastructure

import org.springframework.security.crypto.argon2.Argon2PasswordEncoder
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.stereotype.Component

@Component
class PasswordHashes {
    private val argon2 = Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8()
    private val bcrypt = BCryptPasswordEncoder()

    fun hash(raw: String): String = argon2.encode(raw)

    fun matches(
        raw: String,
        encoded: String,
    ): Boolean {
        if (encoded.startsWith("\$argon2")) {
            return runCatching { argon2.matches(raw, encoded) }.getOrDefault(false)
        }
        if (encoded.startsWith("\$2")) {
            return runCatching { bcrypt.matches(raw, encoded) }.getOrDefault(false)
        }
        return false
    }
}
