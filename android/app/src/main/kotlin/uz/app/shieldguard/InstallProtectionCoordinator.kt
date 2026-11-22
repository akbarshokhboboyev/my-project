package uz.app.shieldguard

import android.content.Context
import java.io.File
import java.security.MessageDigest
import java.util.UUID

// Only the explicit, foreground file-open/share scanner stages snapshots. Folder scans never do.
internal object InstallProtectionCoordinator {
    private data class Snapshot(val file: File, val report: Map<String, Any>, val hash: String,
        val expires: Long, val generation: Long, var validated: Boolean = false)
    private val lock = Any()
    private val pending = linkedMapOf<String, Snapshot>()
    private var generation = 0L
    private const val ttl = 10 * 60 * 1000L
    private fun directory(context: Context) = File(context.cacheDir, "apk-forward").apply { mkdirs() }
    fun enabled(context: Context) = context.options().getBoolean("apkAutoBlock", true)
    fun strict(context: Context) = context.options().getBoolean("apkStrict", false)
    fun decision(context: Context, report: Map<String, Any>) = AutomaticBlockEngine.decide(
        ApkRiskPolicy.assess(report), (report["format"] as? String).orEmpty().substringBefore(" · ") == "APK",
        enabled(context), strict(context))

    fun stage(context: Context, source: File, report: Map<String, Any>, cancelled: () -> Boolean): Map<String, Any> {
        if (!(report["format"] as? String).orEmpty().startsWith("APK") || cancelled()) return report
        val epoch = synchronized(lock) { generation }
        if (source.length() > 32L * 1024 * 1024) return report
        val token = UUID.randomUUID().toString()
        val file = File(directory(context), "$token.apk")
        try {
            source.inputStream().use { input -> file.outputStream().use { output ->
                val buffer = ByteArray(64 * 1024)
                var total = 0L
                while (true) {
                    if (cancelled()) return report
                    val count = input.read(buffer)
                    if (count < 0) break
                    total += count
                    check(total <= 32L * 1024 * 1024)
                    output.write(buffer, 0, count)
                }
            } }
            val hash = report["hash"] as? String ?: return report
            synchronized(lock) {
                if (epoch != generation || cancelled()) return report
                prune(context)
                while (pending.size >= 8) { val first = pending.keys.first(); pending.remove(first)?.file?.delete() }
                check(file.setReadOnly())
                pending[token] = Snapshot(file, report, hash, System.currentTimeMillis() + ttl, epoch)
                return report + mapOf("details" to ((report["details"] as? Map<*, *>).orEmpty() +
                    mapOf("apkToken" to token, "apkGate" to decision(context, report).asMap())))
            }
        } finally {
            synchronized(lock) { if (pending[token]?.file != file) file.delete() }
        }
    }

    // Rehash the immutable private snapshot, never re-open the sender's potentially changed URI.
    fun validate(context: Context, token: String): Map<String, Any> = synchronized(lock) {
        prune(context)
        val snapshot = pending[token] ?: throw IllegalStateException("apkExpired")
        check(snapshot.generation == generation)
        val hash = MessageDigest.getInstance("SHA-256")
        snapshot.file.inputStream().use { input ->
            val bytes = ByteArray(64 * 1024)
            var total = 0L
            while (true) {
                val count = input.read(bytes)
                if (count < 0) break
                total += count; check(total <= 32L * 1024 * 1024)
                hash.update(bytes, 0, count)
            }
        }
        check(hash.digest().joinToString("") { "%02x".format(it) } == snapshot.hash) { "apkChanged" }
        snapshot.validated = true
        snapshot.report
    }
    // Called immediately before launch, on the UI thread, with current preferences.
    fun forward(context: Context, token: String, approved: Boolean, launch: (File) -> Unit): GateDecision = synchronized(lock) {
        val snapshot = pending[token] ?: throw IllegalStateException("apkExpired")
        check(snapshot.expires > System.currentTimeMillis() && snapshot.generation == generation)
        val result = decision(context, snapshot.report)
        check(result.blocked || snapshot.validated) { "apkChanged" }
        if (AutomaticBlockEngine.forward(result, approved) { launch(snapshot.file) }) pending.remove(token)
        result
    }
    fun clear(context: Context) = synchronized(lock) {
        generation++
        pending.values.forEach { it.file.delete() }; pending.clear()
        directory(context).listFiles()?.filter { Regex("[a-f0-9-]{36}\\.apk").matches(it.name) }?.forEach { it.delete() }
    }
    private fun prune(context: Context) {
        val now = System.currentTimeMillis()
        pending.filterValues { it.expires <= now }.keys.toList().forEach { pending.remove(it)?.file?.delete() }
        directory(context).listFiles()?.filter { Regex("[a-f0-9-]{36}\\.apk").matches(it.name) &&
            now - it.lastModified() > ttl }?.forEach { it.delete() }
    }
}
