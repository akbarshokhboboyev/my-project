package uz.app.shieldguard

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

internal object AuthorizedFolderMonitor {
    val lock = Any()
    fun store(context: Context) = context.getSharedPreferences("folder-monitor", Context.MODE_PRIVATE)
    fun epoch(context: Context) = store(context).getLong("epoch", 0)
    fun enabled(context: Context) = store(context).getBoolean("enabled", false)
    fun rows(context: Context): List<JSONObject> = runCatching {
        val array = JSONArray(store(context).getString("roots", "[]"))
        (0 until minOf(array.length(), 4)).map { array.getJSONObject(it) }
    }.getOrDefault(emptyList())
    private fun saveRows(context: Context, rows: List<JSONObject>) {
        check(store(context).edit().putString("roots", JSONArray(rows).toString()).commit())
    }
    fun hasGrant(context: Context, raw: String): Boolean = runCatching {
        context.contentResolver.persistedUriPermissions.any { it.uri.toString() == raw && it.isReadPermission }
    }.getOrDefault(false)
    fun validate(context: Context): Boolean = rows(context).all { hasGrant(context, it.getString("uri")) }
    fun allowedTree(uri: Uri): Boolean = runCatching {
        if (uri.scheme != "content" || !DocumentsContract.isTreeUri(uri)) return false
        val id = DocumentsContract.getTreeDocumentId(uri)
        if (id.length !in 1..2048) return false
        if (uri.authority == "com.android.externalstorage.documents") {
            val path = id.substringAfter(':', "").trim('/').lowercase()
            if (path.isEmpty() || path == "download" || path == "downloads" ||
                path == "android/data" || path.startsWith("android/data/") ||
                path == "android/obb" || path.startsWith("android/obb/")) return false
        }
        true
    }.getOrDefault(false)
    fun add(context: Context, uri: Uri, flags: Int, expectedEpoch: Long): Long = synchronized(lock) {
        if (expectedEpoch != epoch(context)) throw IllegalStateException("cancelled")
        releaseAll(context, emptyList())
        if (store(context).getStringSet("releasePending", emptySet()).orEmpty().isNotEmpty())
            throw IllegalStateException("folderCleanupPending")
        if (!allowedTree(uri) || flags and Intent.FLAG_GRANT_READ_URI_PERMISSION == 0 ||
            flags and Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION == 0) throw SecurityException("folderPermission")
        val current = rows(context)
        if (current.none { it.getString("uri") == uri.toString() } && current.size >= 4)
            throw IllegalStateException("folderLimit")
        context.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val row = current.firstOrNull { it.getString("uri") == uri.toString() }
            ?: JSONObject().put("id", UUID.randomUUID().toString()).put("uri", uri.toString()).put("label", "")
        val next = current.filterNot { it.getString("id") == row.getString("id") } + row
        try { saveRows(context, next) } catch (error: Exception) {
            release(context, uri.toString()); throw error
        }
        val nextEpoch = expectedEpoch + 1
        store(context).edit().putLong("epoch", nextEpoch).remove("cache").remove("summary")
            .putString("state", "idle").commit()
        FolderScanScheduler.cancel(context)
        if (enabled(context)) FolderScanScheduler.ensure(context)
        InstalledAppMonitor.notifyChanged()
        nextEpoch
    }
    fun updateLabel(context: Context, raw: String, label: String, expectedEpoch: Long) = synchronized(lock) {
        if (expectedEpoch != epoch(context)) return@synchronized
        val current = rows(context)
        current.firstOrNull { it.getString("uri") == raw }?.put("label",
            label.filterNot { it.isISOControl() || it in '\u202a'..'\u202e' || it in '\u2066'..'\u2069' }.take(64))
        saveRows(context, current)
    }
    private fun release(context: Context, raw: String): Boolean = try {
        context.contentResolver.releasePersistableUriPermission(Uri.parse(raw), Intent.FLAG_GRANT_READ_URI_PERMISSION)
        true
    } catch (_: Exception) { !hasGrant(context, raw) }
    private fun releaseAll(context: Context, uris: List<String>) {
        val pending = store(context).getStringSet("releasePending", emptySet()).orEmpty() + uris
        val failed = pending.filterNot { release(context, it) }.toSet()
        store(context).edit().putStringSet("releasePending", failed).apply()
    }
    fun setEnabled(context: Context, value: Boolean) = synchronized(lock) {
        if (value && (rows(context).isEmpty() || !validate(context))) throw SecurityException("folderPermission")
        val oldEpoch = epoch(context)
        val roots = rows(context)
        FolderScanScheduler.cancel(context)
        if (!value) {
            val pending = store(context).getStringSet("releasePending", emptySet()).orEmpty()
            store(context).edit().clear().putLong("epoch", oldEpoch + 1)
                .putStringSet("releasePending", pending).commit()
            releaseAll(context, roots.map { it.getString("uri") })
        } else {
            store(context).edit().putLong("epoch", oldEpoch + 1).putBoolean("enabled", true).commit()
            FolderScanScheduler.ensure(context)
        }
        InstalledAppMonitor.notifyChanged()
    }
    fun remove(context: Context, id: String) = synchronized(lock) {
        val removed = rows(context).firstOrNull { it.getString("id") == id } ?: return@synchronized
        cancel(context)
        saveRows(context, rows(context).filterNot { it.getString("id") == id })
        store(context).edit().remove("cache").remove("summary").commit()
        releaseAll(context, listOf(removed.getString("uri")))
        if (rows(context).isEmpty()) {
            store(context).edit().putBoolean("enabled", false).apply()
            FolderScanScheduler.cancel(context)
        }
        InstalledAppMonitor.notifyChanged()
    }
    fun cancel(context: Context) = synchronized(lock) {
        store(context).edit().putLong("epoch", epoch(context) + 1).putString("state", "cancelled").commit()
        FolderScanScheduler.cancel(context)
        if (enabled(context) && validate(context)) FolderScanScheduler.ensure(context)
        InstalledAppMonitor.notifyChanged()
    }
    fun permissionLost(context: Context) = synchronized(lock) {
        val roots = rows(context)
        val epoch = epoch(context)
        FolderScanScheduler.cancel(context)
        store(context).edit().remove("cache").remove("summary").putLong("epoch", epoch + 1)
            .putBoolean("enabled", false).putString("state", "permissionLost").commit()
        releaseAll(context, roots.map { it.getString("uri") })
        InstalledAppMonitor.notifyChanged()
    }
    fun recover(context: Context) = synchronized(lock) {
        releaseAll(context, emptyList())
        if (!validate(context)) { permissionLost(context); return@synchronized }
        if (enabled(context) && rows(context).isNotEmpty()) FolderScanScheduler.ensure(context)
        else FolderScanScheduler.cancel(context)
        if (store(context).getString("state", "") in setOf("running", "queued", "deferred"))
            store(context).edit().putString("state", "interrupted").apply()
    }
    fun status(context: Context): Map<String, Any> {
        val current = rows(context)
        val valid = current.all { hasGrant(context, it.getString("uri")) }
        if (!valid && enabled(context)) permissionLost(context)
        val summary = runCatching { JSONObject(store(context).getString("summary", "{}")) }.getOrDefault(JSONObject())
        return mapOf("enabled" to enabled(context), "scheduled" to FolderScanScheduler.scheduled(context),
            "state" to (store(context).getString("state", "idle") ?: "idle"),
            "cleanupPending" to store(context).getStringSet("releasePending", emptySet()).orEmpty().isNotEmpty(),
            "roots" to current.map { mapOf("id" to it.getString("id"), "label" to it.optString("label"),
                "granted" to hasGrant(context, it.getString("uri"))) },
            "lastScan" to summary.optLong("time"), "visited" to summary.optInt("visited"),
            "scanned" to summary.optInt("scanned"), "cached" to summary.optInt("cached"),
            "unverified" to summary.optInt("unverified"), "partial" to (summary.optBoolean("partial", true) || store(context).getString("state", "idle") != "done"),
            "indicators" to (summary.optJSONArray("indicators") ?: JSONArray()).let { array ->
                (0 until array.length()).map { array.getString(it) } })
    }
}
