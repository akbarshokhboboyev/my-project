package uz.app.shieldguard

import java.security.MessageDigest
import java.util.UUID

internal class AlertGate {
    private val salt = UUID.randomUUID().toString()
    private val recent = LinkedHashMap<String, Long>()
    private var lastAlert = -30_000L
    fun allow(body: String, now: Long): Boolean {
        val key = MessageDigest.getInstance("SHA-256").digest((salt + body).toByteArray())
            .joinToString("") { "%02x".format(it) }
        if (now - lastAlert < 30_000 || recent[key]?.let { now - it < 300_000 } == true) return false
        if (recent.size >= 128) recent.remove(recent.keys.first())
        recent[key] = now
        lastAlert = now
        return true
    }
}
