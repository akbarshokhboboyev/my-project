package uz.app.shieldguard

import android.app.job.JobParameters
import android.app.job.JobService
import android.net.Uri
import android.provider.DocumentsContract
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest
import java.util.concurrent.*
import java.util.concurrent.atomic.AtomicBoolean

class FolderScanJobService : JobService() {
    private val stops = ConcurrentHashMap<Int, AtomicBoolean>()
    private val epochs = ConcurrentHashMap<Int, Long>()
    override fun onStartJob(params: JobParameters): Boolean {
        val roots: List<JSONObject>
        val generation: Long
        synchronized(AuthorizedFolderMonitor.lock) {
            if (params.jobId == FolderScanScheduler.periodicId && !AuthorizedFolderMonitor.enabled(this)) return false
            if (!AuthorizedFolderMonitor.validate(this)) { AuthorizedFolderMonitor.permissionLost(this); return false }
            roots = AuthorizedFolderMonitor.rows(this)
            if (roots.isEmpty()) return false
            generation = AuthorizedFolderMonitor.epoch(this)
            AuthorizedFolderMonitor.store(this).edit().putString("state", "running").apply()
        }
        val stop = AtomicBoolean(false)
        val apkEpoch = InstallProtectionCoordinator.epoch()
        stops[params.jobId] = stop
        epochs[params.jobId] = generation
        val cancelled = { stop.get() || generation != AuthorizedFolderMonitor.epoch(this) }
        InstalledAppMonitor.notifyChanged()
        try {
            executor.execute {
                try {
                    val store = AuthorizedFolderMonitor.store(this)
                    val old = decodeRecords(store.getString("cache", "{}") ?: "{}")
                    val offset = store.getInt("rotation", 0).mod(roots.size)
                    val ordered = roots.drop(offset) + roots.take(offset)
                    val documents = ordered.map {
                        val tree = Uri.parse(it.getString("uri"))
                        val id = DocumentsContract.getTreeDocumentId(tree)
                        FolderDocument(key(tree.authority.orEmpty(), id),
                            DocumentsContract.buildDocumentUriUsingTree(tree, id).toString(), true)
                    }
                    val scanner = IncrementalFileScanner(
                        list = { parent, budget, emit -> listChildren(parent, budget, cancelled, emit) },
                        inspect = { document, stopped ->
                            if (!AuthorizedFolderMonitor.validate(this)) throw SecurityException()
                            val batch = FileOpenScanHandler.scanner(this).scan(
                                SharedFileRequest(listOf(document.uri), true), stopped)["batch"] as List<*>
                            @Suppress("UNCHECKED_CAST")
                            (batch.first() as Map<String, Any>).also { report ->
                                if (!stopped()) TelegramApkGuard.observe(this, report, apkEpoch)
                            }
                        })
                    val result = scanner.scan(documents, old, cancelled = cancelled)
                    synchronized(AuthorizedFolderMonitor.lock) {
                        if (cancelled()) return@synchronized
                        if (result.denied || !AuthorizedFolderMonitor.validate(this)) {
                            AuthorizedFolderMonitor.permissionLost(this)
                        } else {
                            val summary = JSONObject().put("time", System.currentTimeMillis())
                                .put("visited", result.visited).put("scanned", result.scanned)
                                .put("cached", result.cached).put("unverified", result.unverified)
                                .put("partial", result.partial).put("indicators", JSONArray(result.indicators.toList()))
                            store.edit().putString("cache", encodeRecords(result.records).toString())
                                .putString("summary", summary.toString()).putInt("rotation", offset + 1)
                                .putString("state", if (result.partial) "partial" else "done").commit()
                        }
                        InstalledAppMonitor.notifyChanged()
                    }
                } catch (_: Exception) {
                    synchronized(AuthorizedFolderMonitor.lock) {
                        if (!cancelled()) {
                            AuthorizedFolderMonitor.store(this).edit().putString("state", "providerError").apply()
                            InstalledAppMonitor.notifyChanged()
                        }
                    }
                } finally {
                    stops.remove(params.jobId, stop)
                    epochs.remove(params.jobId, generation)
                    if (!stop.get()) jobFinished(params, false)
                }
            }
        } catch (_: RejectedExecutionException) {
            stops.remove(params.jobId, stop)
            epochs.remove(params.jobId, generation)
            synchronized(AuthorizedFolderMonitor.lock) {
                if (!cancelled()) {
                    AuthorizedFolderMonitor.store(this).edit().putString("state", "deferred").apply()
                    InstalledAppMonitor.notifyChanged()
                }
            }
            return false
        }
        return true
    }
    override fun onStopJob(params: JobParameters): Boolean {
        stops.remove(params.jobId)?.set(true)
        val generation = epochs.remove(params.jobId)
        synchronized(AuthorizedFolderMonitor.lock) {
            if (generation != AuthorizedFolderMonitor.epoch(this)) return false
            AuthorizedFolderMonitor.store(this).edit().putString("state", "deferred").apply()
            InstalledAppMonitor.notifyChanged()
            return AuthorizedFolderMonitor.rows(this).isNotEmpty() && AuthorizedFolderMonitor.validate(this)
        }
    }
    override fun onDestroy() { stops.values.forEach { it.set(true) }; super.onDestroy() }

    private fun listChildren(parent: FolderDocument, budget: Int, cancelled: () -> Boolean,
        emit: (FolderDocument) -> Unit): Boolean {
        val uri = Uri.parse(parent.uri)
        val childUri = DocumentsContract.buildChildDocumentsUriUsingTree(uri, DocumentsContract.getDocumentId(uri))
        val columns = arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_MIME_TYPE, DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            DocumentsContract.Document.COLUMN_SIZE)
        val cursor = contentResolver.query(childUri, columns, null, null, null)
            ?: throw IllegalStateException()
        return cursor.use {
            var read = 0
            while (read < budget && !cancelled() && it.moveToNext()) {
                val id = it.getString(0).orEmpty()
                val raw = if (id.length in 1..2048) DocumentsContract.buildDocumentUriUsingTree(uri, id).toString() else ""
                emit(FolderDocument(key(uri.authority.orEmpty(), id), raw,
                    it.getString(1) == DocumentsContract.Document.MIME_TYPE_DIR,
                    if (it.isNull(2)) null else it.getLong(2), if (it.isNull(3)) null else it.getLong(3)))
                read++
            }
            cancelled() || it.moveToNext()
        }
    }
    companion object {
        private val executor = ThreadPoolExecutor(1, 1, 0, TimeUnit.SECONDS, ArrayBlockingQueue(1))
        private fun key(authority: String, id: String) = MessageDigest.getInstance("SHA-256")
            .digest((authority + "\n" + id).toByteArray()).joinToString("") { "%02x".format(it) }
        internal fun decodeRecords(raw: String): Map<String, FolderRecord> = runCatching {
            val json = JSONObject(raw)
            json.keys().asSequence().take(256).associateWith { name ->
                val row = json.getJSONObject(name)
                val findings = row.optJSONObject("findings") ?: JSONObject()
                FolderRecord(if (row.isNull("modified")) null else row.getLong("modified"),
                    if (row.isNull("size")) null else row.getLong("size"), row.getLong("checked"),
                    row.optString("hash").takeIf { it.length == 64 }, row.optBoolean("complete"),
                    findings.keys().asSequence().take(64).associateWith { findings.getInt(it) })
            }
        }.getOrDefault(emptyMap())
        internal fun encodeRecords(records: Map<String, FolderRecord>): JSONObject = JSONObject().apply {
            records.forEach { (name, value) -> put(name, JSONObject()
                .put("modified", value.modified ?: JSONObject.NULL).put("size", value.size ?: JSONObject.NULL)
                .put("checked", value.checked).put("hash", value.hash ?: "")
                .put("complete", value.complete).put("findings", JSONObject(value.findings))) }
        }
    }
}
