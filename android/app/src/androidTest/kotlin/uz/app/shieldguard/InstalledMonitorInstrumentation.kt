package uz.app.shieldguard

import android.app.Instrumentation
import android.app.job.JobScheduler
import android.os.Bundle

// Runs against the real PackageManager/JobScheduler. No third-party APK is installed or executed.
class InstalledMonitorInstrumentation : Instrumentation() {
    private var testEvents = false
    override fun onCreate(arguments: Bundle?) {
        super.onCreate(arguments)
        testEvents = arguments?.getString("events") == "true"
        start()
    }
    override fun onStart() {
        Thread {
            var checks = 0
            fun verify(value: Boolean) { check(value); checks++ }
            val context = targetContext
            try {
                val scanner = InstalledAppScanner(context)
                val own = scanner.inspect(context.packageName) { false }
                verify((own["details"] as Map<*, *>)["installedPackage"] == context.packageName)
                verify((own["signers"] as List<*>).isNotEmpty())
                @Suppress("DEPRECATION")
                val source = context.packageManager.getApplicationInfo(context.packageName, 0).sourceDir
                if (java.io.File(source).length() > 32L * 1024 * 1024) {
                    verify(own["complete"] == false)
                    verify("installedMetadataOnly" in (own["findings"] as Map<*, *>))
                    verify((own["details"] as Map<*, *>)["signatureStatus"] != "signatureVerified")
                }
                val missing = scanner.inspect("uz.app.shieldguard.synthetic.absent") { false }
                verify(missing["complete"] == false)
                verify("installedUnavailable" in (missing["findings"] as Map<*, *>))
                val cancelled = scanner.inspect(context.packageName) { true }
                verify("scanCancelled" in (cancelled["findings"] as Map<*, *>))
                val originallyEnabled = InstalledAppMonitor.enabled(context)
                if (!originallyEnabled) {
                    try {
                        @Suppress("DEPRECATION")
                        val baseline = context.packageManager.getInstalledPackages(0)
                            .associate { it.packageName to it.lastUpdateTime }
                        InstalledAppMonitor.store(context).edit()
                            .putString("known", org.json.JSONObject(baseline).toString()).commit()
                        val epoch = InstalledAppMonitor.generation(context)
                        InstalledAppMonitor.setEnabled(context, true)
                        val scheduler = context.getSystemService(JobScheduler::class.java)
                        verify(scheduler.getPendingJob(ScanScheduler.periodicId) != null)
                        ScanScheduler.enqueue(context, "uz.app.synthetic")
                        ScanScheduler.enqueue(context, "uz.app.synthetic")
                        verify(InstalledAppMonitor.store(context).getStringSet("pending", emptySet()) == setOf("uz.app.synthetic"))
                        verify(scheduler.getPendingJob(ScanScheduler.eventId) != null)
                        InstalledAppMonitor.setEnabled(context, false)
                        verify(InstalledAppMonitor.generation(context) > epoch)
                        verify(scheduler.getPendingJob(ScanScheduler.periodicId) == null)
                        verify(scheduler.getPendingJob(ScanScheduler.eventId) == null)
                        verify(InstalledAppMonitor.store(context).all.isEmpty())
                        ScanScheduler.enqueue(context, "uz.app.synthetic")
                        verify(scheduler.getPendingJob(ScanScheduler.eventId) == null)
                    } finally { InstalledAppMonitor.setEnabled(context, false) }
                    selfJobCheck { verify(it) }
                }
                if (testEvents) eventChecks { verify(it) }
                finish(0, Bundle().apply {
                    putString("stream", "$checks installed monitor Android checks passed; enable/disable checks run only when initially disabled.\n")
                })
            } catch (error: Throwable) {
                finish(1, Bundle().apply { putString("stream", "$checks installed monitor Android checks completed before failure: " + error.javaClass.simpleName + "\n") })
            }
        }.start()
    }

    @Suppress("DEPRECATION")
    private fun selfJobCheck(verify: (Boolean) -> Unit) {
        val context = targetContext
        val store = InstalledAppMonitor.store(context)
        // Seed timestamps to avoid scheduling unchanged third-party apps.
        val known = context.packageManager.getInstalledPackages(0).associate { it.packageName to it.lastUpdateTime }
        store.edit().putString("known", org.json.JSONObject(known).toString()).commit()
        try {
            InstalledAppMonitor.setEnabled(context, true)
            ScanScheduler.enqueue(context, context.packageName)
            val deadline = android.os.SystemClock.elapsedRealtime() + 45_000
            while (installedReport(context) == null && android.os.SystemClock.elapsedRealtime() < deadline) Thread.sleep(200)
            val report = installedReport(context)
            verify(report != null)
            verify((report?.get("details") as? Map<*, *>)?.get("installedPackage") == context.packageName)
            verify((report?.get("signers") as? List<*>)?.isNotEmpty() == true)
            verify(report?.get("complete") == false) // This universal debug APK exceeds the content budget.
        } finally { InstalledAppMonitor.setEnabled(context, false) }
        verify(store.all.isEmpty())
    }

    @Suppress("DEPRECATION")
    private fun eventChecks(verify: (Boolean) -> Unit) {
        val context = targetContext
        val fixture = "uz.app.shieldguard.synthetic.monitor"
        check(!InstalledAppMonitor.enabled(context))
        val store = InstalledAppMonitor.store(context)
        val known = context.packageManager.getInstalledPackages(0)
            .filter { it.packageName != fixture }.associate { it.packageName to it.lastUpdateTime }
        store.edit().putString("known", org.json.JSONObject(known).toString()).commit()
        fun waitUntil(condition: () -> Boolean) {
            val until = android.os.SystemClock.elapsedRealtime() + 90_000
            while (!condition()) {
                check(android.os.SystemClock.elapsedRealtime() < until) { "Event/job timeout" }
                Thread.sleep(200)
            }
        }
        fun version() = runCatching { context.packageManager.getPackageInfo(fixture, 0).versionCode }.getOrDefault(0)
        fun scanned(): Boolean {
            val stamp = runCatching { context.packageManager.getPackageInfo(fixture, 0).lastUpdateTime }.getOrDefault(-1)
            return org.json.JSONObject(store.getString("known", "{}") ?: "{}").optLong(fixture, -2) == stamp
        }
        val jobs = context.getSystemService(JobScheduler::class.java)
        try {
            InstalledAppMonitor.setEnabled(context, true)
            sendStatus(0, Bundle().apply { putString("stream", "PHASE2_READY_FOR_INSTALL\n") })
            waitUntil { version() == 1 && store.getString("lastEvent", "") == fixture && scanned() }
            verify(store.getString("lastEventType", "") == android.content.Intent.ACTION_PACKAGE_ADDED)
            val benign = InstalledAppScanner(context).inspect(fixture) { false }
            @Suppress("UNCHECKED_CAST")
            verify(!InstalledAppPolicy.shouldAlert(benign["findings"] as Map<String, Int>, true))
            sendStatus(0, Bundle().apply { putString("stream", "PHASE2_READY_FOR_UPDATE\n") })
            waitUntil { version() == 2 && store.getString("lastEventType", "") == android.content.Intent.ACTION_PACKAGE_REPLACED && scanned() }
            val risky = InstalledAppScanner(context).inspect(fixture) { false }
            verify("installedCombo" in (risky["findings"] as Map<*, *>))
            verify(benign["signers"] == risky["signers"])
            waitUntil { jobs.getPendingJob(ScanScheduler.eventId) == null }
            val previous = store.getString("report", "")
            ScanScheduler.enqueue(context, fixture)
            waitUntil { jobs.getPendingJob(ScanScheduler.eventId) == null }
            verify(previous == store.getString("report", ""))
            val manager = context.getSystemService(android.app.NotificationManager::class.java)
            val alerts = manager.areNotificationsEnabled() && (android.os.Build.VERSION.SDK_INT < 33 ||
                context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == android.content.pm.PackageManager.PERMISSION_GRANTED) &&
                manager.getNotificationChannel("installed")?.importance != android.app.NotificationManager.IMPORTANCE_NONE
            verify(manager.activeNotifications.any { it.tag == "installed" } == alerts)
            sendStatus(0, Bundle().apply { putString("stream", "PHASE2_EVENTS_AND_BACKGROUND_PASSED\n") })
        } finally { InstalledAppMonitor.setEnabled(context, false) }
    }
}
