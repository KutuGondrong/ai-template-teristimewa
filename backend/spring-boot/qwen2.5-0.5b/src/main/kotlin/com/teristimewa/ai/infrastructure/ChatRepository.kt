package com.teristimewa.ai.infrastructure

import com.teristimewa.ai.domain.ChatMessage
import com.teristimewa.ai.domain.Identity
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.stereotype.Repository
import java.sql.ResultSet
import java.time.Duration
import java.time.Instant
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

@Repository
class ChatRepository(
    private val jdbc: JdbcTemplate,
) {
    private val sessions = ConcurrentHashMap<String, UUID>()

    fun createUser(
        email: String,
        passwordHash: String,
    ): UUID {
        val id = UUID.randomUUID()
        jdbc.update(
            "insert into users(id,email,password_hash) values (?,?,?)",
            id,
            email,
            passwordHash,
        )
        return id
    }

    fun authenticate(email: String): Pair<UUID, String>? =
        jdbc
            .query(
                "select id,password_hash from users where email=?",
                { rs, _ -> rs.getObject("id", UUID::class.java) to rs.getString("password_hash") },
                email,
            ).firstOrNull()

    fun emailFor(userId: UUID): String? =
        jdbc
            .query(
                "select email from users where id=?",
                { rs, _ -> rs.getString("email") },
                userId,
            ).firstOrNull()

    fun refreshSession(userId: UUID): String {
        sessions.entries.removeIf { it.value == userId }
        return issueSession(userId)
    }

    fun clearSession(token: String) {
        sessions.remove(token)
    }

    fun identityFromSession(token: String): Identity? = sessions[token]?.let { Identity(userId = it) }

    fun ensureGuest(raw: String?): Identity {
        deleteOldGuests()
        val parsed = runCatching { raw?.let(UUID::fromString) }.getOrNull()
        if (parsed != null) {
            val exists = jdbc.queryForObject("select count(*) from guests where id=?", Long::class.java, parsed) ?: 0
            if (exists > 0) return Identity(guestId = parsed)
        }
        val id = UUID.randomUUID()
        jdbc.update("insert into guests(id) values (?)", id)
        return Identity(guestId = id)
    }

    fun add(
        identity: Identity,
        role: String,
        content: String,
    ): ChatMessage {
        val conversationId = conversationId(identity)
        val message = ChatMessage(UUID.randomUUID(), role, content, Instant.now())
        jdbc.update(
            "insert into messages(id,conversation_id,role,content,created_at) values (?,?,?,?,?)",
            message.id,
            conversationId,
            role,
            content,
            java.sql.Timestamp.from(message.createdAt),
        )
        return message
    }

    fun listPage(
        identity: Identity,
        limit: Int,
        beforeId: UUID?,
    ): Pair<List<ChatMessage>, Boolean> {
        val conversationId = conversationId(identity)
        val cap = limit.coerceIn(1, 100)
        var sql = "select id,role,content,created_at from messages where conversation_id=?"
        val args = mutableListOf<Any?>(conversationId)
        if (beforeId != null) {
            val pivot =
                jdbc
                    .query(
                        "select seq, conversation_id from messages where id=?",
                        { rs, _ -> rs.getInt("seq") to rs.getObject("conversation_id", UUID::class.java) },
                        beforeId,
                    ).firstOrNull()
            if (pivot == null || pivot.second != conversationId) {
                return emptyList<ChatMessage>() to false
            }
            sql += " and seq < ?"
            args += pivot.first
        }
        sql += " order by seq desc limit ?"
        args += cap + 1
        val rows =
            jdbc.query(
                sql,
                { rs, _ -> mapMessage(rs) },
                *args.toTypedArray(),
            )
        val hasMore = rows.size > cap
        return rows.take(cap).reversed() to hasMore
    }

    fun listAllForContext(identity: Identity): List<ChatMessage> {
        val conversationId = conversationId(identity)
        return jdbc.query(
            "select id,role,content,created_at from messages where conversation_id=? order by seq asc",
            { rs, _ -> mapMessage(rs) },
            conversationId,
        )
    }

    fun deleteOldGuests(): Int =
        jdbc.update(
            "delete from guests where created_at < ?",
            java.sql.Timestamp.from(Instant.now().minus(Duration.ofDays(1))),
        )

    private fun issueSession(userId: UUID): String {
        val token = UUID.randomUUID().toString() + UUID.randomUUID()
        sessions[token] = userId
        return token
    }

    private fun conversationId(identity: Identity): UUID {
        val column = if (identity.userId != null) "user_id" else "guest_id"
        val ownerId = identity.userId ?: identity.guestId
        val existing =
            jdbc
                .query(
                    "select id from conversations where $column=?",
                    { rs, _ -> rs.getObject("id", UUID::class.java) },
                    ownerId,
                ).firstOrNull()
        if (existing != null) return existing
        val id = UUID.randomUUID()
        jdbc.update("insert into conversations(id, $column) values (?,?)", id, ownerId)
        return id
    }

    private fun mapMessage(rs: ResultSet) =
        ChatMessage(
            rs.getObject("id", UUID::class.java),
            rs.getString("role"),
            rs.getString("content"),
            rs.getTimestamp("created_at").toInstant(),
        )
}
