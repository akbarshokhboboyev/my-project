package uz.app.shieldguard

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

internal fun Context.options() = getSharedPreferences("shieldguard", Context.MODE_PRIVATE)

class TelegramThreatListener : NotificationListenerService() {
    private val recent = LinkedHashMap<String, Long>()
    private var lastAlert = -30_000L

    override fun onListenerConnected() { connected = true; connectionChanged?.invoke() }
    override fun onListenerDisconnected() { connected = false; connectionChanged?.invoke() }
    override fun onDestroy() {
        connected = false
        connectionChanged?.invoke()
        super.onDestroy()
    }

    override fun onNotificationPosted(event: StatusBarNotification) {
        if (!connected || event.packageName !in telegram || !options().getBoolean("enabled", false)) return
        val notification = event.notification
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        val body = (notification.extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: notification.extras.getCharSequence(Notification.EXTRA_TEXT))
            ?.take(8192)?.toString() ?: return
        val findings = NotificationAnalyzer.inspect(body)
        val score = findings.values.sum().coerceAtMost(100)
        if (score < 50) return
        val manager = getSystemService(NotificationManager::class.java)
        if (!manager.areNotificationsEnabled() ||
            (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED)) return
        manager.createNotificationChannel(NotificationChannel("protection", getString(R.string.alert_channel),
            NotificationManager.IMPORTANCE_HIGH))
        if (manager.getNotificationChannel("protection")?.importance == NotificationManager.IMPORTANCE_NONE) return
        val now = SystemClock.elapsedRealtime()
        val key = event.key + findings.keys.joinToString()
        if (now - lastAlert < 30_000 || recent[key]?.let { now - it < 300_000 } == true) return
        if (recent.size >= 128) recent.remove(recent.keys.first())
        recent[key] = now
        lastAlert = now
        val time = System.currentTimeMillis()
        historyWorker.execute {
            runCatching { HistoryStore(this).use { it.record("notification", score, findings.size, true, time) } }
        }
        val tap = Intent(this, MainActivity::class.java).setAction(MainActivity.SHOW_ALERT)
            .putExtra("proof", alertProof(this))
            .putExtra("time", time)
            .putExtra("indicators", findings.keys.toTypedArray())
        val pending = PendingIntent.getActivity(this, 1, tap,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        manager.notify(1, Notification.Builder(this, "protection")
            .setSmallIcon(android.R.drawable.ic_dialog_alert).setContentTitle(getString(R.string.alert_title))
            .setContentText(getString(R.string.alert_body)).setVisibility(Notification.VISIBILITY_PRIVATE)
            .setContentIntent(pending).setAutoCancel(true).build())
    }

    companion object {
        @Volatile internal var connected = false
        internal var connectionChanged: (() -> Unit)? = null
        private val historyWorker = java.util.concurrent.Executors.newSingleThreadExecutor()
        private val telegram = setOf("org.telegram.messenger", "org.telegram.messenger.web", "org.thunderdog.challegram")
    }
}

@Synchronized
internal fun alertProof(context: Context): String {
    val prefs = context.options()
    return prefs.getString("alertProof", null) ?: java.util.UUID.randomUUID().toString().also {
        prefs.edit().putString("alertProof", it).apply()
    }
}
