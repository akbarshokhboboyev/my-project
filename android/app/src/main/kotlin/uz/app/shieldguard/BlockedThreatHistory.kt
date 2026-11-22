package uz.app.shieldguard

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest
import java.util.UUID

internal object BlockedThreatHistory {
    private val lock = Any()
    private fun store(context: Context) = context.getSharedPreferences("apk-guard", Context.MODE_PRIVATE)
    fun entries(context: Context): List<Map<String, Any>> = synchronized(lock) {
        val array = runCatching { JSONArray(store(context).getString("entries", "[]")) }.getOrDefault(JSONArray())
        (0 until minOf(array.length(), 50)).mapNotNull { index -> runCatching {
            val row = array.getJSONObject(index)
            buildMap<String, Any> {
                for (key in listOf("id", "risk", "confidence", "severity", "method", "outcome", "advice")) put(key, row.getString(key))
                put("score", row.getInt("score")); put("complete", row.getBoolean("complete")); put("time", row.getLong("time"))
                val codes = row.getJSONArray("evidence")
                put("evidence", (0 until minOf(codes.length(), 64)).map { codes.getString(it) })
            }
        }.getOrNull() }
    }
    fun record(context: Context, report: Map<String, Any>, outcome: String): String? = synchronized(lock) {
        if (!InstallProtectionCoordinator.enabled(context)) return null
        require(outcome in setOf("blockedByShieldGuard", "blockedByAndroid", "warningOnly", "scanIncomplete", "notIntercepted"))
        val now = System.currentTimeMillis()
        val key = MessageDigest.getInstance("SHA-256").digest(((report["hash"] as? String).orEmpty() + outcome).toByteArray())
            .joinToString("") { "%02x".format(it) }
        val known = runCatching { JSONObject(store(context).getString("dedup", "{}")) }.getOrDefault(JSONObject())
        val age = now - known.optLong(key, 0)
        if (known.has(key) && age in 0 until 10 * 60 * 1000L) return null
        val id = UUID.randomUUID().toString()
        val row = ApkRiskPolicy.assess(report).asMap() + mapOf("id" to id, "time" to now,
            "outcome" to outcome, "advice" to "apkAdvice")
        val next = (listOf(row) + entries(context)).take(50)
        val dedup = JSONObject()
        known.keys().asSequence().filter { now - known.optLong(it) in 0 until 10 * 60 * 1000L }
            .take(49).forEach { dedup.put(it, known.getLong(it)) }
        dedup.put(key, now)
        store(context).edit().putString("entries", JSONArray(next).toString()).putString("dedup", dedup.toString()).commit()
        id
    }
    fun report(context: Context, id: String): Map<String, Any>? {
        val row = entries(context).firstOrNull { it["id"] == id } ?: return null
        return mapOf("kind" to "file", "format" to "APK", "complete" to row.getValue("complete"),
            "time" to row.getValue("time"), "findings" to (row["evidence"] as List<*>).associate { it.toString() to 0 },
            "details" to mapOf("apkAssessment" to row, "apkGate" to mapOf("blocked" to (row["outcome"] == "blockedByShieldGuard"),
                "outcome" to row.getValue("outcome"))))
    }
    fun clear(context: Context) = synchronized(lock) {
        store(context).edit().clear().commit()
        context.getSystemService(android.app.NotificationManager::class.java).cancel("apk-guard", 4)
    }
}
