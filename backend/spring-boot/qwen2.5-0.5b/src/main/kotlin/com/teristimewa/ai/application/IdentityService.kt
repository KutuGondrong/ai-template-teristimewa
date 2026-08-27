package com.teristimewa.ai.application

import com.teristimewa.ai.api.AuthCookies
import com.teristimewa.ai.domain.Identity
import com.teristimewa.ai.infrastructure.ChatRepository
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.stereotype.Service

@Service
class IdentityService(
    private val repository: ChatRepository,
    private val cookies: AuthCookies,
) {
    fun resolve(
        request: HttpServletRequest,
        response: HttpServletResponse,
    ): Identity {
        val jar = request.cookies.orEmpty().associate { it.name to it.value }
        val session = jar["session"]?.let(repository::identityFromSession)
        if (session != null) return session
        val guest = repository.ensureGuest(jar["guest_id"])
        cookies.setGuest(response, guest.guestId!!)
        return guest
    }
}
