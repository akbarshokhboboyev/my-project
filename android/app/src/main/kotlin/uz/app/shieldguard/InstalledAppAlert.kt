package uz.app.shieldguard

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

internal object InstalledAppAlert {
    fun show(context: Context, report: Map<String, Any>): Boolean {
        @Suppress("UNCHECKED_CAST")
        val findings = report["findings"] as? Map<String, Int> ?: return false
        val manager = context.getSystemService(NotificationManager::class.java)
        val permitted = manager.areNotificationsEnabled() && (Build.VERSION.SDK_INT < 33 ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
        if (!InstalledAppPolicy.shouldAlert(findings, permitted)) return false
        manager.createNotificationChannel(NotificationChannel("installed", context.getString(R.string.installed_channel),
            NotificationManager.IMPORTANCE_HIGH))
        if (manager.getNotificationChannel("installed")?.importance == NotificationManager.IMPORTANCE_NONE) return false
        val details = report["details"] as? Map<*, *> ?: return false
        val label = details["installedLabel"] as? String ?: return false
        val reasons = buildList {
            if ("installedCombo" in findings) add(context.getString(R.string.installed_reason_combo))
            if ("signatureFailed" in findings) add(context.getString(R.string.installed_reason_signature))
            if (isEmpty()) add(context.getString(R.string.installed_reason_static))
        }.joinToString(" ")
        val body = context.getString(R.string.installed_alert_body, label, reasons)
        val tap = PendingIntent.getActivity(context, 7102,
            Intent(context, MainActivity::class.java).setAction(MainActivity.SHOW_INSTALLED)
                .putExtra("proof", alertProof(context)),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        manager.notify("installed", 1, Notification.Builder(context, "installed")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(context.getString(R.string.installed_alert_title)).setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body)).setVisibility(Notification.VISIBILITY_PRIVATE)
            .setContentIntent(tap).setOnlyAlertOnce(true).setAutoCancel(true).build())
        return true
    }
}
