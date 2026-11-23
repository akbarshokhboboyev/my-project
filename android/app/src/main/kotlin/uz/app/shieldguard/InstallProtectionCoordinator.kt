package uz.app.shieldguard

import android.content.Context
import java.io.File
import java.security.MessageDigest
import java.util.UUID

// Only the explicit, foreground file-open/share scanner stages snapshots. Folder scans never do.
internal object InstallProtectionCoordinator {
    private data class Snapshot(val file: File, var report: Map<String, Any>, val hash: String,
        val expires: Long, val generation: Long, var validated: Boolean = false)
    private val lock = Any()
    private val pending = linkedMapOf<String, Snapshot>()
    private val staging = java.util.concurrent.Semaphore(1)
    private var generation = 0L
    private const val ttl = 10 * 60 * 1000L
    fun epoch() = synchronized(lock) { generation }
    fun withCurrent(epoch: Long, action: () -> Unit) = synchronized(lock) { if (generation == epoch) action() }
    private fun directory(context: Context) = File(context.cacheDir, "apk-forward").apply { mkdirs() }
    fun enabled(context: Context) = context.options().getBoolean("apkAutoBlock", true)
    fun strict(context: Context) = context.options().getBoolean("apkStrict", false)
    fun discard(context: Context, token: String) = synchronized(lock) {
        pending.remove(token)?.file?.let { file ->
            runCatching { context.revokeUriPermission(androidx.core.content.FileProvider.getUriForFile(context,
                "${context.packageName}.apkforward", file), android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION) }
            file.delete()
        }
    }
    fun setEnabled(context: Context, value: Boolean) = synchronized(lock) {
        val edit = context.options().edit().putBoolean("apkAutoBlock", value)
        if (!value) edit.putBoolean("apkStrict", false).putBoolean("apkAlerts", false)
        edit.commit()
        if (!value) { clear(context); BlockedThreatHistory.clear(context) }
    }
    fun decision(context: Context, report: Map<String, Any>) = AutomaticBlockEngine.decide(
        ApkRiskPolicy.assess(report), (report["format"] as? String).orEmpty().substringBefore(" · ") == "APK",
        enabled(context), strict(context))

    fun stage(context: Context, source: File, report: Map<String, Any>, cancelled: () -> Boolean,
        expectedEpoch: Long = epoch()): Map<String, Any> {
        if (!(report["format"] as? String).orEmpty().startsWith("APK") || cancelled()) return report
        val epoch = expectedEpoch
        synchronized(lock) { if (generation != epoch) return report }
        if (source.length() > 32L * 1024 * 1024) return report
        val token = UUID.randomUUID().toString()
        val file = File(directory(context), "$token.apk")
        if (!staging.tryAcquire()) return report
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
                // Bound disk snapshots too, including already handed-off files and process orphans.
                val existing = directory(context).listFiles().orEmpty().filter { it != file &&
                    Regex("[a-f0-9-]{36}\\.apk").matches(it.name) }.sortedBy { it.lastModified() }.toMutableList()
                while (existing.size >= 8) {
                    val oldest = existing.removeAt(0)
                    check(oldest.delete())
                    pending.entries.removeAll { it.value.file == oldest }
                }
                while (pending.size >= 8) { val first = pending.keys.first(); pending.remove(first)?.file?.delete() }
                check(file.setReadOnly())
                pending[token] = Snapshot(file, report, hash, android.os.SystemClock.elapsedRealtime() + ttl, epoch)
                return report + mapOf("details" to ((report["details"] as? Map<*, *>).orEmpty() +
                    mapOf("apkToken" to token, "apkGate" to decision(context, report).asMap())))
            }
        } finally {
            synchronized(lock) { if (pending[token]?.file != file) file.delete() }
            staging.release()
        }
    }

    // SharedFileScanner may downgrade completeness after its cooperative batch deadline.
    // The native gate must use that final verdict, not the earlier single-file verdict.
    fun finalizeBatch(context: Context, batch: Map<String, Any>, apkHint: Boolean = false): Map<String, Any> = synchronized(lock) {
        val rows = (batch["batch"] as? List<*>).orEmpty().map { value ->
            @Suppress("UNCHECKED_CAST")
            val row = value as? Map<String, Any> ?: return@map value
            val details = (row["details"] as? Map<*, *>).orEmpty()
            val token = details["apkToken"] as? String
            if (token == null) {
                if (!apkHint && details["apkAssessment"] !is Map<*, *>) return@map row
                val unavailable = ApkDiscoveryCoordinator.decorate(row + mapOf("complete" to false,
                    "findings" to ((row["findings"] as? Map<*, *>).orEmpty() + mapOf("apkUnavailableSnapshot" to 0))), "candidate.apk")
                val policy = decision(context, unavailable)
                val gate = if (policy.blocked) policy else GateDecision(true, "scanIncomplete")
                BlockedThreatHistory.record(context, unavailable, gate.outcome)
                return@map unavailable + mapOf("details" to ((unavailable["details"] as? Map<*, *>).orEmpty() + mapOf("apkGate" to gate.asMap())))
            }
            val qualified = ApkDiscoveryCoordinator.decorate(row, "")
            val snapshot = pending[token]
            val findings = (row["findings"] as? Map<*, *>).orEmpty()
            if (snapshot == null || "scanCancelled" in findings) {
                pending.remove(token)?.file?.delete()
                return@map qualified + mapOf("details" to ((qualified["details"] as? Map<*, *>).orEmpty() - "apkToken"))
            }
            snapshot.report = qualified
            snapshot.validated = false
            val result = decision(context, qualified)
            val id = BlockedThreatHistory.record(context, qualified, result.outcome).orEmpty()
            qualified + mapOf("details" to ((qualified["details"] as? Map<*, *>).orEmpty() +
                mapOf("apkGate" to result.asMap(), "apkHistoryId" to id)))
        }
        batch + mapOf("batch" to rows)
    }

    // Rehash the immutable private snapshot, never re-open the sender's potentially changed URI.
    fun validate(context: Context, token: String): Map<String, Any> = synchronized(lock) {
        prune(context)
        val snapshot = pending[token] ?: throw IllegalStateException("apkExpired")
        check(snapshot.generation == generation)
        snapshot.validated = false
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
        check(snapshot.expires > android.os.SystemClock.elapsedRealtime() && snapshot.generation == generation)
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
        pending.filterValues { it.expires <= android.os.SystemClock.elapsedRealtime() }.keys.toList().forEach { pending.remove(it)?.file?.delete() }
        directory(context).listFiles()?.filter { Regex("[a-f0-9-]{36}\\.apk").matches(it.name) &&
            now - it.lastModified() > ttl }?.forEach { it.delete() }
    }
}
