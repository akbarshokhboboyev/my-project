package uz.app.shieldguard

import java.net.URI
import java.io.FileNotFoundException

internal data class SharedFileRequest(
    val uris: List<String>,
    val readGranted: Boolean,
    val truncated: Boolean = false,
    val apkHint: Boolean = false
)

internal class SharedFileScanner(
    private val readable: (String) -> Boolean,
    private val inspect: (String, () -> Boolean) -> Map<String, Any>,
    private val clock: () -> Long = { System.nanoTime() / 1_000_000 },
    private val maxMillis: Long = 60_000
) {
    fun scan(request: SharedFileRequest, cancelled: () -> Boolean): Map<String, Any> {
        val deadline = clock() + maxMillis
        val seen = linkedSetOf<String>()
        var overflow = request.truncated || request.uris.size > 64
        for (raw in request.uris.take(64)) {
            val separator = raw.indexOf(':')
            val key = if (separator > 0) raw.substring(0, separator).lowercase() + raw.substring(separator) else raw
            if (seen.size < 8 || key in seen) seen.add(key) else overflow = true
        }
        val reports = mutableListOf<Map<String, Any>>()
        if (seen.isEmpty()) reports.add(error("sharedInvalid"))
        for ((index, raw) in seen.withIndex()) {
            val result = when {
                cancelled() -> error("scanCancelled")
                clock() >= deadline -> error("scanTimeout")
                !validUri(raw) -> error("sharedInvalid")
                !request.readGranted -> error("filePermission")
                else -> try {
                    if (!readable(raw)) error("filePermission")
                    else inspect(raw) { cancelled() || clock() >= deadline }
                } catch (_: SecurityException) { error("filePermission") }
                  catch (_: FileNotFoundException) { error("fileMissing") }
                  catch (_: Exception) { error("failed") }
            }
            val stopped = cancelled() || clock() >= deadline
            val qualified = if (stopped) {
                val findings = ((result["findings"] as? Map<*, *>) ?: emptyMap<Any, Any>())
                    .filterKeys { it != "scanCancelled" }.toMutableMap()
                findings[if (cancelled()) "scanCancelled" else "scanTimeout"] = 0
                result + mapOf("complete" to false, "findings" to findings)
            } else result
            val details = (qualified["details"] as? Map<*, *>).orEmpty() + mapOf("batchItem" to index + 1)
            reports.add(qualified + mapOf("details" to details))
            if (stopped) break
        }
        if (overflow) reports.add(error("contentLimit"))
        return mapOf("batch" to reports)
    }

    companion object {
        fun validUri(raw: String): Boolean {
            if (raw.length !in 1..4096) return false
            val uri = runCatching { URI(raw) }.getOrNull() ?: return false
            return uri.scheme.equals("content", ignoreCase = true) && !uri.rawAuthority.isNullOrEmpty() &&
                uri.rawUserInfo == null && uri.rawFragment == null
        }
        fun error(code: String): Map<String, Any> =
            mapOf("kind" to "file", "complete" to false, "findings" to mapOf(code to 0))
    }
}
