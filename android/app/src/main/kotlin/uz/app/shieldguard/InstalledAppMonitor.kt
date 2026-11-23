package uz.app.shieldguard

import android.app.Application
import android.app.NotificationManager
import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.content.*
import android.os.Build
import android.os.PersistableBundle

class ShieldGuardApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // The isolated PDF process must never access the main UID's preferences or jobs.
        val processName = if (Build.VERSION.SDK_INT >= 28) getProcessName()
            else getSystemService(android.app.ActivityManager::class.java).runningAppProcesses
                ?.firstOrNull { it.pid == android.os.Process.myPid() }?.processName
        if (processName == packageName) {
            InstalledAppMonitor.sync(this)
            AuthorizedFolderMonitor.recover(this)
        }
    }
}

internal object InstalledAppMonitor {
    val lock = Any()
    var changed: (() -> Unit)? = null
    fun notifyChanged() { android.os.Handler(android.os.Looper.getMainLooper()).post { changed?.invoke() } }
    private var receiver: BroadcastReceiver? = null
    fun enabled(context: Context) = context.options().getBoolean("appMonitoring", false)
    fun generation(context: Context) = context.options().getLong("appGeneration", 0)
    fun store(context: Context) = context.getSharedPreferences("installed-monitor", Context.MODE_PRIVATE)

    fun setEnabled(context: Context, value: Boolean) = synchronized(lock) {
        context.options().edit().putBoolean("appMonitoring", value)
            .putLong("appGeneration", generation(context) + 1).commit()
        if (!value) {
            ScanScheduler.cancel(context)
            store(context).edit().clear().commit()
            context.getSystemService(NotificationManager::class.java).cancel("installed", 1)
        }
        sync(context)
    }

    fun sync(context: Context) = synchronized(lock) {
        val app = context.applicationContext
        if (enabled(app)) {
            val prefs = store(app)
            if (prefs.getInt("rulesVersion", 0) != ThreatFamilyAnalyzer.rulesVersion) {
                context.options().edit().putLong("appGeneration", generation(context) + 1).commit()
                ScanScheduler.cancel(app)
                prefs.edit().remove("known").remove("report").remove("alertReport")
                    .putInt("rulesVersion", ThreatFamilyAnalyzer.rulesVersion).commit()
                app.getSystemService(NotificationManager::class.java).cancel("installed", 1)
            }
            if (receiver == null) {
                val listener = object : BroadcastReceiver() {
                    override fun onReceive(context: Context, intent: Intent) {
                        if (!enabled(context) || intent.data?.scheme != "package") return
                        val name = PackageUpdateMonitor.packageFor(intent.action,
                            intent.data?.schemeSpecificPart, intent.getBooleanExtra(Intent.EXTRA_REPLACING, false))
                            ?: return
                        if (name != context.packageName) synchronized(lock) {
                            if (enabled(context)) {
                                store(context).edit().putString("lastEvent", name)
                                    .putString("lastEventType", intent.action).apply()
                                ScanScheduler.enqueue(context, name)
                            }
                        }
                    }
                }
                val filter = IntentFilter().apply {
                    addAction(Intent.ACTION_PACKAGE_ADDED)
                    addAction(Intent.ACTION_PACKAGE_REPLACED)
                    addDataScheme("package")
                }
                if (Build.VERSION.SDK_INT >= 33) app.registerReceiver(listener, filter, Context.RECEIVER_NOT_EXPORTED)
                else @Suppress("DEPRECATION") app.registerReceiver(listener, filter)
                receiver = listener
            }
            ScanScheduler.ensurePeriodic(app)
        } else {
            receiver?.let { runCatching { app.unregisterReceiver(it) } }
            receiver = null
            ScanScheduler.cancel(app)
        }
    }
}

internal object ScanScheduler {
    const val periodicId = 7101
    const val eventId = 7102
    private fun scheduler(context: Context) = context.getSystemService(JobScheduler::class.java)
    fun ensurePeriodic(context: Context) {
        val jobs = scheduler(context)
        if (jobs.getPendingJob(periodicId) != null) return
        val result = jobs.schedule(JobInfo.Builder(periodicId, ComponentName(context, InstalledAppJobService::class.java))
            .setPeriodic(15 * 60 * 1000L).setPersisted(true).setRequiresBatteryNotLow(true).build())
        if (result != JobScheduler.RESULT_SUCCESS)
            InstalledAppMonitor.store(context).edit().putString("state", "scheduleFailed").apply()
    }
    fun enqueue(context: Context, name: String? = null) = synchronized(InstalledAppMonitor.lock) {
        if (!InstalledAppMonitor.enabled(context)) return@synchronized
        val store = InstalledAppMonitor.store(context)
        val pending = store.getStringSet("pending", emptySet()).orEmpty().toMutableSet()
        if (name != null && pending.size < InstalledAppPolicy.queueLimit) pending.add(name)
        store.edit().putStringSet("pending", pending).commit()
        val jobs = scheduler(context)
        if (jobs.getPendingJob(eventId) == null) {
            val generation = PersistableBundle().apply { putLong("generation", InstalledAppMonitor.generation(context)) }
            val result = jobs.schedule(JobInfo.Builder(eventId, ComponentName(context, InstalledAppJobService::class.java))
                .setExtras(generation).setMinimumLatency(1000).setRequiresBatteryNotLow(true).build())
            if (result != JobScheduler.RESULT_SUCCESS) store.edit().putString("state", "scheduleFailed").apply()
        }
    }
    fun cancel(context: Context) {
        scheduler(context).cancel(periodicId)
        scheduler(context).cancel(eventId)
    }
    fun scheduled(context: Context) = scheduler(context).getPendingJob(periodicId) != null
}
