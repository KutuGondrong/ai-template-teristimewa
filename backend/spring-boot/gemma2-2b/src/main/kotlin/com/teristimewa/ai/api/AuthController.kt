package com.teristimewa.ai.api

import com.teristimewa.ai.application.IdentityService
import com.teristimewa.ai.infrastructure.ChatRepository
import com.teristimewa.ai.infrastructure.PasswordHashes
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import jakarta.validation.Valid
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.server.ResponseStatusException

@RestController
@RequestMapping("/api/auth")
class AuthController(
    private val repository: ChatRepository,
    private val identities: IdentityService,
    private val passwords: PasswordHashes,
    private val cookies: AuthCookies,
) {
    @PostMapping("/signup")
    fun signup(
        @Valid @RequestBody body: AuthRequest,
    ): UserOut {
        val email = body.email.trim().lowercase()
        val id =
            try {
                repository.createUser(email, passwords.hash(body.password))
            } catch (_: DataIntegrityViolationException) {
                throw ResponseStatusException(HttpStatus.CONFLICT, "Email already exists")
            }
        return UserOut(id = id, email = email)
    }

    @PostMapping("/login")
    fun login(
        @Valid @RequestBody body: AuthRequest,
        response: HttpServletResponse,
    ): UserOut {
        val email = body.email.trim().lowercase()
        val row =
            repository.authenticate(email)
                ?: throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials")
        if (!passwords.matches(body.password, row.second)) {
            throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials")
        }
        cookies.setSession(response, repository.refreshSession(row.first))
        return UserOut(id = row.first, email = email)
    }

    @PostMapping("/logout")
    fun logout(
        request: HttpServletRequest,
        response: HttpServletResponse,
    ): Map<String, String> {
        request.cookies
            .orEmpty()
            .firstOrNull { it.name == "session" }
            ?.value
            ?.let(repository::clearSession)
        cookies.clearSession(response)
        return mapOf("status" to "ok")
    }

    @GetMapping("/me")
    fun me(
        request: HttpServletRequest,
        response: HttpServletResponse,
    ): Any {
        val identity = identities.resolve(request, response)
        if (identity.userId != null) {
            val email =
                repository.emailFor(identity.userId)
                    ?: throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "Not authenticated")
            return UserOut(id = identity.userId, email = email)
        }
        return GuestOut(id = identity.guestId!!)
    }
}
