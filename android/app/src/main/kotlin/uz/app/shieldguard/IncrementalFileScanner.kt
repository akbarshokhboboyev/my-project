package uz.app.shieldguard

internal data class FolderDocument(val key: String, val uri: String, val directory: Boolean,
    val modified: Long? = null, val size: Long? = null)
internal data class FolderRecord(val modified: Long?, val size: Long?, val checked: Long,
    val hash: String?, val complete: Boolean, val findings: Map<String, Int>)
internal data class FolderRun(val visited: Int, val scanned: Int, val cached: Int,
    val unverified: Int, val partial: Boolean, val denied: Boolean,
    val indicators: Set<String>, val records: Map<String, FolderRecord>)

internal class IncrementalFileScanner(
    private val list: (FolderDocument, Int, (FolderDocument) -> Unit) -> Boolean,
    private val inspect: (FolderDocument, () -> Boolean) -> Map<String, Any>,
    private val clock: () -> Long = { System.nanoTime() / 1_000_000 },
    private val now: () -> Long = { System.currentTimeMillis() },
    private val maxEntries: Int = 256,
    private val maxFiles: Int = 8,
    private val maxDepth: Int = 2,
    private val maxMillis: Long = 60_000
) {
    fun scan(roots: List<FolderDocument>, previous: Map<String, FolderRecord>,
        authorized: Boolean = true, cancelled: () -> Boolean): FolderRun {
        if (!authorized) return FolderRun(0, 0, 0, 1, true, true, emptySet(), emptyMap())
        val deadline = clock() + maxMillis
        fun stopped() = cancelled() || clock() >= deadline
        var visited = 0
        var partial = false
        var denied = false
        var unknown = 0
        val folders = ArrayDeque<Pair<FolderDocument, Int>>()
        roots.take(4).forEach { folders.addLast(it to 0) }
        if (roots.size > 4) { partial = true; unknown++ }
        val seen = mutableSetOf<String>()
        val files = linkedMapOf<String, FolderDocument>()
        while (folders.isNotEmpty() && !stopped()) {
            val (folder, depth) = folders.removeFirst()
            if (!seen.add(folder.key)) continue
            if (visited >= maxEntries) { partial = true; unknown++; break }
            try {
                val cut = list(folder, maxEntries - visited) { child ->
                    if (visited < maxEntries && !stopped()) {
                        visited++
                        if (child.directory) {
                            if (depth < maxDepth && folders.size < maxEntries) folders.addLast(child to depth + 1)
                            else { partial = true; unknown++ }
                        } else files.putIfAbsent(child.key, child)
                    } else { partial = true }
                }
                if (cut) { partial = true; unknown++ }
            } catch (_: SecurityException) { denied = true; partial = true; unknown++; break }
              catch (_: Exception) { partial = true; unknown++ }
        }
        if (stopped()) { partial = true; unknown++ }
        val records = previous.toMutableMap()
        var scanned = 0
        var cached = 0
        val observed = linkedMapOf<String, FolderRecord>()
        fun fresh(doc: FolderDocument): Boolean {
            val old = previous[doc.key] ?: return false
            val age = now() - old.checked
            return doc.modified != null && doc.modified > 0 && doc.size != null && doc.size >= 0 &&
                old.modified == doc.modified && old.size == doc.size && age in 0 until 3_600_000
        }
        files.values.filter(::fresh).forEach {
            cached++; observed[it.key] = previous.getValue(it.key)
        }
        val pending = files.values.filterNot(::fresh).sortedBy { previous[it.key]?.checked ?: 0 }
        if (!denied) for (doc in pending.take(maxFiles)) {
            if (stopped()) { partial = true; break }
            val report = try { inspect(doc, ::stopped) }
                catch (_: SecurityException) { SharedFileScanner.error("filePermission") }
                catch (_: Exception) { SharedFileScanner.error("failed") }
            scanned++
            val findings = (report["findings"] as? Map<*, *>).orEmpty().entries.mapNotNull {
                if (it.key is String && it.value is Int) (it.key as String) to (it.value as Int) else null
            }.take(64).toMap().toMutableMap()
            val complete = report["complete"] == true && !stopped()
            if (stopped()) findings[if (cancelled()) "scanCancelled" else "scanTimeout"] = 0
            val record = FolderRecord(doc.modified, doc.size, now(),
                (report["hash"] as? String)?.takeIf { it.matches(Regex("[a-f0-9]{64}")) }, complete, findings)
            records[doc.key] = record
            observed[doc.key] = record
        }
        if (!partial && !denied) records.keys.retainAll(files.keys)
        val bounded = records.entries.sortedByDescending { it.value.checked }.take(maxEntries).associate { it.toPair() }
        val unchecked = files.size - observed.size + observed.values.count { !it.complete }
        unknown += unchecked.coerceAtLeast(0)
        if (files.size > observed.size || denied) partial = true
        val indicators = observed.values.flatMap { it.findings.filterValues { weight -> weight > 0 }.keys }.toSet()
        return FolderRun(visited, scanned, cached, unknown, partial || unknown > 0, denied, indicators, bounded)
    }
}
