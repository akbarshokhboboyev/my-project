package uz.app.shieldguard

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

internal object TelegramApkGuard {
    // A user-authorized file is not proof that Telegram supplied it. No source attribution is persisted.
    fun observe(context: Context, report: Map<String, Any>, epoch: Long) =
        InstallProtectionCoordinator.withCurrent(epoch) {
            if (!(report["format"] as? String).orEmpty().startsWith("APK")) return@withCurrent
            val risk = ApkRiskPolicy.assess(report).risk
            if (risk !in setOf("confirmedHighConfidenceThreat", "strongSuspicion")) return@withCurrent
            // Discovery outside the controlled forward gate is a warning, never a claimed block.
            val id = BlockedThreatHistory.record(context, report, "warningOnly") ?: return@withCurrent
            show(context, id)
        }

    fun show(context: Context, id: String): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java)
        val risk = BlockedThreatHistory.entries(context).firstOrNull { it["id"] == id }?.get("risk") as? String ?: "unknown"
        val permission = manager.areNotificationsEnabled() && (Build.VERSION.SDK_INT < 33 ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
        if (!ApkAlertPolicy.allowed(InstallProtectionCoordinator.enabled(context),
            context.options().getBoolean("apkAlerts", false), permission, true, risk)) return false
        manager.createNotificationChannel(NotificationChannel("apk-guard", context.getString(R.string.apk_channel),
            NotificationManager.IMPORTANCE_HIGH))
        if (manager.getNotificationChannel("apk-guard")?.importance == NotificationManager.IMPORTANCE_NONE) return false
        val tap = PendingIntent.getActivity(context, 7401, Intent(context, MainActivity::class.java)
            .setAction(MainActivity.SHOW_APK).putExtra("proof", alertProof(context)).putExtra("entry", id),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val public = Notification.Builder(context, "apk-guard").setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(context.getString(R.string.app_name)).setContentText(context.getString(R.string.apk_alert_body)).build()
        val notification = Notification.Builder(context, "apk-guard").setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(context.getString(R.string.apk_alert_title)).setContentText(context.getString(R.string.apk_alert_body))
            .setContentIntent(tap).setVisibility(Notification.VISIBILITY_PRIVATE).setPublicVersion(public)
            .setAutoCancel(true).setOnlyAlertOnce(true).build()
        return runCatching { manager.notify("apk-guard", 4, notification); true }.getOrDefault(false)
    }
}
