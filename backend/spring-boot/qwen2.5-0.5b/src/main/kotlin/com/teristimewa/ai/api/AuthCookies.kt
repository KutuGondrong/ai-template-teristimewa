package com.teristimewa.ai.api

import jakarta.servlet.http.HttpServletResponse
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.HttpHeaders
import org.springframework.http.ResponseCookie
import org.springframework.stereotype.Component
import java.time.Duration
import java.util.UUID

@Component
class AuthCookies(
    @Value("\${app.cookie-secure:false}") private val secure: Boolean,
) {
    fun setSession(
        response: HttpServletResponse,
        token: String,
    ) {
        write(
            response,
            ResponseCookie
                .from("session", token)
                .httpOnly(true)
                .path("/")
                .maxAge(Duration.ofSeconds(2_592_000))
                .sameSite("Lax")
                .secure(secure)
                .build(),
        )
    }

    fun clearSession(response: HttpServletResponse) {
        write(
            response,
            ResponseCookie
                .from("session", "")
                .httpOnly(true)
                .path("/")
                .maxAge(Duration.ZERO)
                .sameSite("Lax")
                .secure(secure)
                .build(),
        )
    }

    fun setGuest(
        response: HttpServletResponse,
        guestId: UUID,
    ) {
        write(
            response,
            ResponseCookie
                .from("guest_id", guestId.toString())
                .httpOnly(true)
                .path("/")
                .maxAge(Duration.ofSeconds(86_400))
                .sameSite("Lax")
                .secure(secure)
                .build(),
        )
    }

    private fun write(
        response: HttpServletResponse,
        cookie: ResponseCookie,
    ) {
        response.addHeader(HttpHeaders.SET_COOKIE, cookie.toString())
    }
}
