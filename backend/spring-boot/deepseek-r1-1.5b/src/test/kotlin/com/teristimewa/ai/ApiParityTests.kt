package com.teristimewa.ai

import com.teristimewa.ai.domain.Identity
import com.teristimewa.ai.infrastructure.ChatRepository
import com.teristimewa.ai.infrastructure.PasswordHashes
import jakarta.servlet.http.Cookie
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.HttpHeaders
import org.springframework.http.MediaType
import org.springframework.mock.web.MockHttpServletResponse
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import java.util.UUID

@SpringBootTest(
    properties = [
        "spring.datasource.url=jdbc:h2:mem:parity;MODE=PostgreSQL;DB_CLOSE_DELAY=-1",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.sql.init.mode=always",
        "app.ollama-base-url=http://127.0.0.1:9",
        "app.ollama-model=test",
    ],
)
@AutoConfigureMockMvc
class ApiParityTests {
    @Autowired lateinit var mockMvc: MockMvc

    @Autowired lateinit var repository: ChatRepository

    @Autowired lateinit var passwords: PasswordHashes

    @Test
    fun signupDoesNotSetSessionAndMeStaysGuest() {
        val signup =
            mockMvc
                .post("/api/auth/signup") {
                    contentType = MediaType.APPLICATION_JSON
                    content = """{"email":"User@Example.com","password":"secret123"}"""
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.email") { value("user@example.com") }
                    jsonPath("$.type") { value("user") }
                }.andReturn()
                .response
        assertNull(signup.namedCookie("session"))

        mockMvc.get("/api/auth/me").andExpect {
            status { isOk() }
            jsonPath("$.type") { value("guest") }
        }
    }

    @Test
    fun loginThenMeIsUserThenLogoutIsGuest() {
        mockMvc.post("/api/auth/signup") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"email":"in@e.com","password":"secret123"}"""
        }

        val session = login("in@e.com")
        mockMvc
            .get("/api/auth/me") { cookie(session) }
            .andExpect {
                status { isOk() }
                jsonPath("$.type") { value("user") }
                jsonPath("$.email") { value("in@e.com") }
            }

        mockMvc.post("/api/auth/logout") { cookie(session) }.andExpect { status { isOk() } }

        mockMvc.get("/api/auth/me").andExpect {
            status { isOk() }
            jsonPath("$.type") { value("guest") }
        }
    }

    @Test
    fun pythonStyleArgon2HashCanLogIn() {
        val email = "argon@e.com"
        val hash = passwords.hash("Password1")
        assertTrue(hash.startsWith("\$argon2"))
        val id = repository.createUser(email, hash)
        val session = login(email, "Password1")
        mockMvc.get("/api/auth/me") { cookie(session) }.andExpect {
            jsonPath("$.id") { value(id.toString()) }
        }
    }

    @Test
    fun messagesAreLastTenWithHasMoreAndLoadOlder() {
        mockMvc.post("/api/auth/signup") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"email":"hist@e.com","password":"secret123"}"""
        }
        val session = login("hist@e.com")
        val userId = userIdFromMe(session)
        repeat(7) { i ->
            repository.add(Identity(userId = userId), "user", "msg-$i")
            repository.add(Identity(userId = userId), "assistant", "ans-$i")
        }

        val page =
            mockMvc
                .get("/api/messages") { cookie(session) }
                .andExpect {
                    status { isOk() }
                    jsonPath("$.items.length()") { value(10) }
                    jsonPath("$.has_more") { value(true) }
                    jsonPath("$.items[8].content") { value("msg-6") }
                    jsonPath("$.items[9].role") { value("assistant") }
                }.andReturn()
                .response
                .contentAsString
        val firstId = page.substringAfter("\"id\":\"").substringBefore("\"")

        mockMvc
            .get("/api/messages") {
                cookie(session)
                param("before", firstId)
            }.andExpect {
                status { isOk() }
                jsonPath("$.items.length()") { value(4) }
                jsonPath("$.has_more") { value(false) }
                jsonPath("$.items[0].content") { value("msg-0") }
            }
    }

    @Test
    fun loginUsesUserThreadNotGuest() {
        val guestPage =
            mockMvc
                .get("/api/messages")
                .andExpect { status { isOk() } }
                .andReturn()
                .response
        val guestCookie = checkNotNull(guestPage.namedCookie("guest_id"))
        assertTrue(guestPage.contentAsString.contains("\"items\":[]"))

        mockMvc.post("/api/auth/signup") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"email":"u@e.com","password":"secret123"}"""
        }
        val session = login("u@e.com")
        mockMvc.get("/api/messages") { cookie(session) }.andExpect {
            jsonPath("$.items.length()") { value(0) }
        }
        val userId = userIdFromMe(session)
        repository.add(Identity(userId = userId), "user", "user-only")
        repository.add(Identity(userId = userId), "assistant", "ok")

        mockMvc.post("/api/auth/logout") { cookie(session) }
        mockMvc.get("/api/messages") { cookie(guestCookie) }.andExpect {
            jsonPath("$.items.length()") { value(0) }
        }

        val again = login("u@e.com")
        mockMvc.get("/api/messages") { cookie(again) }.andExpect {
            jsonPath("$.items.length()") { value(2) }
            jsonPath("$.items[0].content") { value("user-only") }
            jsonPath("$.items[1].role") { value("assistant") }
        }
    }

    private fun login(
        email: String,
        password: String = "secret123",
    ): Cookie {
        val response =
            mockMvc
                .post("/api/auth/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = """{"email":"$email","password":"$password"}"""
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.type") { value("user") }
                }.andReturn()
                .response
        val session = checkNotNull(response.namedCookie("session"))
        return session
    }

    private fun userIdFromMe(session: Cookie): UUID {
        val body =
            mockMvc
                .get("/api/auth/me") { cookie(session) }
                .andReturn()
                .response
                .contentAsString
        return UUID.fromString(body.substringAfter("\"id\":\"").substringBefore("\""))
    }
}

private fun MockHttpServletResponse.namedCookie(name: String): Cookie? {
    val header =
        getHeaders(HttpHeaders.SET_COOKIE)
            .map { it.split(";")[0] }
            .firstOrNull { it.startsWith("$name=") }
            ?: return cookies.firstOrNull { it.name == name && it.value.isNotEmpty() && it.maxAge != 0 }
    val value = header.substringAfter("=")
    if (value.isEmpty() || value.equals("null", ignoreCase = true)) return null
    return Cookie(name, value)
}
