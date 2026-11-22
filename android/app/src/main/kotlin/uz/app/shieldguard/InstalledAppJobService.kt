package uz.app.shieldguard

import android.app.job.JobParameters
import android.app.job.JobService
import android.content.pm.PackageManager
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class InstalledAppJobService : JobService() {
    private val stops = ConcurrentHashMap<Int, AtomicBoolean>()
    override fun onStartJob(params: JobParameters): Boolean {
        if (!InstalledAppMonitor.enabled(this)) return false
        val stop = AtomicBoolean(false)
        stops[params.jobId] = stop
        val generation = InstalledAppMonitor.generation(this)
        executor.execute {
            val cancelled = { stop.get() || !InstalledAppMonitor.enabled(this) ||
                InstalledAppMonitor.generation(this) != generation }
            try {
                if (!cancelled()) scanBatch(generation, cancelled)
            } catch (_: Exception) {
                synchronized(InstalledAppMonitor.lock) {
                    if (!cancelled()) {
                        InstalledAppMonitor.store(this).edit().putString("state", "unavailable").apply()
                        InstalledAppMonitor.notifyChanged()
                    }
                }
            } finally {
                stops.remove(params.jobId, stop)
                if (!stop.get()) jobFinished(params, false)
            }
        }
        return true
    }
    override fun onStopJob(params: JobParameters): Boolean {
        stops.remove(params.jobId)?.set(true)
        return InstalledAppMonitor.enabled(this)
    }
    override fun onDestroy() {
        stops.values.forEach { it.set(true) }
        super.onDestroy()
    }

    @Suppress("DEPRECATION")
    private fun scanBatch(generation: Long, cancelled: () -> Boolean) {
        val store = InstalledAppMonitor.store(this)
        val knownJson = JSONObject(store.getString("known", "{}") ?: "{}")
        val known = knownJson.keys().asSequence().associateWith { knownJson.getLong(it) }.toMutableMap()
        val visible = packageManager.getInstalledPackages(0).filter { it.packageName != packageName }
            .sortedByDescending { it.lastUpdateTime }.take(InstalledAppPolicy.inventoryLimit)
            .associate { it.packageName to it.lastUpdateTime }
        val pending = synchronized(InstalledAppMonitor.lock) {
            if (cancelled()) return
            InstalledAppPolicy.pendingChanges(store.getStringSet("pending", emptySet()).orEmpty(), visible, known)
                .also { store.edit().putStringSet("pending", it).commit() }
        }
        val names = (pending + InstalledAppPolicy.changed(true, visible, known)).take(InstalledAppPolicy.batchSize)
        val start = android.os.SystemClock.elapsedRealtime()
        for (name in names) {
            if (cancelled() || android.os.SystemClock.elapsedRealtime() - start > 60_000) break
            val report = InstalledAppScanner(this).inspect(name, cancelled)
            if (cancelled()) break
            val details = report["details"] as? Map<*, *>
            val stamp = details?.get("installedUpdated") as? Long
            // If an update races the scan, do not cache the mixed-version result.
            val current = runCatching { packageManager.getPackageInfo(name, 0).lastUpdateTime }.getOrNull()
            if (stamp != null && current != stamp) continue
            synchronized(InstalledAppMonitor.lock) {
                if (cancelled() || generation != InstalledAppMonitor.generation(this)) return
                if (stamp != null) known[name] = stamp
                known.keys.retainAll(visible.keys + pending)
                val remaining = store.getStringSet("pending", emptySet()).orEmpty().toMutableSet().apply { remove(name) }
                store.edit().putString("known", JSONObject(known.toMap()).toString())
                    .putStringSet("pending", remaining)
                    .putString("report", JSONObject(report).toString())
                    .putString("state", if (stamp == null) "unavailable" else
                        if (report["complete"] == true) "content" else "metadata")
                    .putLong("lastScan", System.currentTimeMillis()).commit()
                // The same lock protects opt-out and notification publication.
                if (InstalledAppAlert.show(this, report)) {
                    store.edit().putString("alertReport", JSONObject(report).toString()).commit()
                }
                InstalledAppMonitor.notifyChanged()
            }
        }
    }

    companion object { private val executor = Executors.newSingleThreadExecutor() }
}

internal fun installedReport(context: android.content.Context, alert: Boolean = false): Map<String, Any>? {
    val raw = InstalledAppMonitor.store(context).getString(if (alert) "alertReport" else "report", null) ?: return null
    fun convert(value: Any): Any = when (value) {
        is JSONObject -> value.keys().asSequence().associateWith { convert(value.get(it)) }
        is org.json.JSONArray -> (0 until value.length()).map { convert(value.get(it)) }
        JSONObject.NULL -> ""
        else -> value
    }
    @Suppress("UNCHECKED_CAST")
    return runCatching { convert(JSONObject(raw)) as Map<String, Any> }.getOrNull()
}
