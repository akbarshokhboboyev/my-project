package uz.app.shieldguard

import android.Manifest
import android.app.Instrumentation
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import java.io.File

// Benign test-APK bytes only. Never invokes an installer or executes a scanned APK.
class ApkGuardInstrumentation : Instrumentation() {
    private var notificationsOnly = false
    override fun onCreate(arguments: Bundle?) {
        super.onCreate(arguments)
        notificationsOnly = arguments?.getString("notificationsOnly") == "true"
        start()
    }
    override fun onStart() { Thread {
        val ctx = targetContext
        var checks = 0
        var ownsState = false
        var failure: Throwable? = null
        val keys = listOf("apkAutoBlock", "apkStrict", "apkAlerts")
        val before = ctx.options().all.filterKeys { it in keys }
        val base = Uri.parse("content://uz.app.shieldguard.test.filefixtures")
        fun verify(value: Boolean, reason: String) { check(value) { reason }; checks++ }
        fun send(name: String) = Intent(Intent.ACTION_SEND).setType("application/vnd.android.package-archive")
            .putExtra(Intent.EXTRA_STREAM, Uri.withAppendedPath(base, name)).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        fun scan(intent: Intent): Map<String, Any> {
            val batch = FileOpenScanHandler.scanner(ctx, stageForward = true)
                .scan(requireNotNull(FileOpenScanHandler.request(intent))) { false }
            @Suppress("UNCHECKED_CAST")
            return (InstallProtectionCoordinator.finalizeBatch(ctx, batch)["batch"] as List<*>).single() as Map<String, Any>
        }
        fun details(report: Map<String, Any>) = report["details"] as Map<*, *>
        fun token(report: Map<String, Any>) = details(report)["apkToken"] as String
        fun outcome(report: Map<String, Any>) = (details(report)["apkGate"] as Map<*, *>)["outcome"]
        try {
            check(BlockedThreatHistory.entries(ctx).isEmpty()) { "Existing user APK history: device test not authorized to clear it" }
            ownsState = true
            InstallProtectionCoordinator.setEnabled(ctx, true)
            ctx.options().edit().putBoolean("apkStrict", false).putBoolean("apkAlerts", false).commit()
            if (!notificationsOnly) {
                // `am instrument` force-stops the target package, which drops any transient URI grant
                // a sender gave earlier. The signature-checked fixture provider re-grants its own files.
                for (name in listOf("fixture.apk", "photo.jpg.apk", "tampered.apk", "missing.pdf"))
                    ctx.contentResolver.call(base, "grant", name, null)
                verify(ctx.checkUriPermission(Uri.withAppendedPath(base, "fixture.apk"), android.os.Process.myPid(),
                    android.os.Process.myUid(), Intent.FLAG_GRANT_READ_URI_PERMISSION) == PackageManager.PERMISSION_GRANTED, "Owner URI grant required")
                ctx.contentResolver.call(base, "prepare", null, null)
                val benign = scan(send("fixture.apk"))
                verify((benign["format"] as? String).orEmpty().startsWith("APK"), "Actual APK format")
                verify(details(benign)["signatureStatus"] == "signatureVerified", "Real benign signature verification")
                verify(outcome(benign) == "warningOnly", "Benign false-positive gate")
                val view = Intent(Intent.ACTION_VIEW).setDataAndType(Uri.withAppendedPath(base, "fixture.apk"), "application/vnd.android.package-archive")
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                verify(outcome(scan(view)) == "warningOnly", "VIEW shares same gate")
                val double = scan(send("photo.jpg.apk"))
                verify("doubleExtension" in (double["findings"] as Map<*, *>), "Double extension")
                verify(outcome(double) == "warningOnly", "Double extension alone is not malware")
                val tampered = scan(send("tampered.apk"))
                verify(details(tampered)["signatureStatus"] == "signatureFailed", "Real tampered signature verification")
                verify(outcome(tampered) == "blockedByShieldGuard", "Strong integrity gate")
                var launches = 0
                InstallProtectionCoordinator.validate(ctx, token(tampered))
                val blocked = InstallProtectionCoordinator.forward(ctx, token(tampered), true) { launches++ }
                verify(blocked.blocked && launches == 0, "Real coordinator must not launch for blocked APK")
                val blockedToken = token(tampered)
                InstallProtectionCoordinator.discard(ctx, blockedToken)
                verify(!File(ctx.cacheDir, "apk-forward/$blockedToken.apk").exists(), "Do-not-install removes only its private snapshot")
                var discarded = false
                try { InstallProtectionCoordinator.validate(ctx, blockedToken) } catch (_: Exception) { discarded = true }
                verify(discarded, "Discarded token cannot forward")
                verify((details(benign)["threatFamilies"] as? List<*>)?.size == 4, "All static family assessments attached")
                InstallProtectionCoordinator.validate(ctx, token(benign))
                InstallProtectionCoordinator.forward(ctx, token(benign), false) { launches++ }
                verify(launches == 0, "Explicit approval required")
                InstallProtectionCoordinator.forward(ctx, token(benign), true) { launches++ }
                verify(launches == 1, "Benign approved mock-launch callback")
                val corrupt = scan(send("fixture.apk"))
                InstallProtectionCoordinator.validate(ctx, token(corrupt))
                val snapshot = File(ctx.cacheDir, "apk-forward/${token(corrupt)}.apk")
                snapshot.setWritable(true); snapshot.appendBytes(byteArrayOf(1))
                var changed = false
                try { InstallProtectionCoordinator.validate(ctx, token(corrupt)) } catch (_: Exception) { changed = true }
                verify(changed, "Changed snapshot hash rejection")
                // Earlier successful validation must never remain usable after failed revalidation.
                var forwardedChanged = false
                try { InstallProtectionCoordinator.forward(ctx, token(corrupt), true) { forwardedChanged = true } } catch (_: Exception) { }
                verify(!forwardedChanged, "Changed snapshot cannot bypass validation")
                ctx.options().edit().putBoolean("apkStrict", true).commit()
                val original = scan(send("fixture.apk"))
                val downgraded = InstallProtectionCoordinator.finalizeBatch(ctx, mapOf("batch" to listOf(original +
                    mapOf("complete" to false, "findings" to mapOf("scanTimeout" to 0)))))
                @Suppress("UNCHECKED_CAST")
                val incomplete = (downgraded["batch"] as List<*>).single() as Map<String, Any>
                verify(outcome(incomplete) == "scanIncomplete", "Final batch timeout reaches strict gate")
                InstallProtectionCoordinator.validate(ctx, token(incomplete))
                verify(InstallProtectionCoordinator.forward(ctx, token(incomplete), true) { launches++ }.blocked, "Strict incomplete no-forward")
                ctx.options().edit().putBoolean("apkStrict", false).commit()
                val cancelled = FileOpenScanHandler.scanner(ctx, true).scan(requireNotNull(FileOpenScanHandler.request(view))) { true }
                verify((((cancelled["batch"] as List<*>).single() as Map<*, *>)["findings"] as Map<*, *>).containsKey("scanCancelled"), "Cancellation")
                verify((scan(send("fixture.apk").setFlags(0))["findings"] as Map<*, *>).containsKey("filePermission"), "Missing read flag")
                verify((scan(send("missing.pdf"))["findings"] as Map<*, *>).containsKey("fileMissing"), "Inaccessible file")
                val oldEpoch = InstallProtectionCoordinator.epoch()
                InstallProtectionCoordinator.setEnabled(ctx, false)
                InstallProtectionCoordinator.setEnabled(ctx, true)
                val stale = FileOpenScanHandler.scanner(ctx, true, oldEpoch).scan(requireNotNull(FileOpenScanHandler.request(view))) { false }
                val staleRow = (stale["batch"] as List<*>).single() as Map<*, *>
                verify(!((staleRow["details"] as Map<*, *>).containsKey("apkToken")), "Opt-out invalidates in-flight scan")
                for (i in 0..9) scan(send("fixture.apk"))
                verify(File(ctx.cacheDir, "apk-forward").listFiles().orEmpty().size <= 8, "Disk snapshot count bound")

                // Actual foreground SEND to Flutter; no installer is ever invoked.
                startActivitySync(Intent(send("tampered.apk")).setClass(ctx, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                val deadline = android.os.SystemClock.elapsedRealtime() + 45_000
                var modal = false
                while (!modal && android.os.SystemClock.elapsedRealtime() < deadline) {
                    fun contains(node: android.view.accessibility.AccessibilityNodeInfo?): Boolean {
                        if (node == null) return false
                        if ((node.text?.toString().orEmpty() + node.contentDescription?.toString().orEmpty()).contains("APK BLOKLANDI")) return true
                        return (0 until node.childCount).any { contains(node.getChild(it)) }
                    }
                    modal = contains(uiAutomation.rootInActiveWindow)
                    if (!modal) Thread.sleep(200)
                }
                verify(modal, "Real Uzbek foreground block dialog")
                verify(uiAutomation.rootInActiveWindow?.packageName?.toString() == ctx.packageName, "Blocking dialog remains in ShieldGuard")
                uiAutomation.executeShellCommand("input keyevent KEYCODE_BACK").close()
                BlockedThreatHistory.clear(ctx)
                val epoch = InstallProtectionCoordinator.epoch()
                TelegramApkGuard.observe(ctx, tampered, epoch)
                TelegramApkGuard.observe(ctx, tampered, epoch)
                verify(BlockedThreatHistory.entries(ctx).size == 1, "Duplicate background event")
                verify(BlockedThreatHistory.entries(ctx).single()["outcome"] == "warningOnly", "Folder discovery never claims install blocked")
                val serialized = org.json.JSONArray(BlockedThreatHistory.entries(ctx)).toString()
                verify(!serialized.contains("content://") && !serialized.contains("tampered.apk") && !serialized.contains("apkToken"), "History contains no URI/name/token")
            } else {
                val synthetic = mapOf<String, Any>("format" to "APK", "complete" to true, "hash" to "a".repeat(64),
                    "signatureChecked" to true, "details" to mapOf("signatureStatus" to "signatureFailed"),
                    "findings" to mapOf("signatureFailed" to 30))
                BlockedThreatHistory.record(ctx, synthetic, "warningOnly")
            }
            val id = BlockedThreatHistory.entries(ctx).first().getValue("id") as String
            verify(!TelegramApkGuard.show(ctx, id), "Notification consent defaults off")
            ctx.options().edit().putBoolean("apkAlerts", true).commit()
            val manager = ctx.getSystemService(NotificationManager::class.java)
            val permission = ctx.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED && manager.areNotificationsEnabled()
            val channelAllowed = manager.getNotificationChannel("apk-guard")?.importance != NotificationManager.IMPORTANCE_NONE
            val shown = TelegramApkGuard.show(ctx, id)
            verify(shown == (permission && channelAllowed), "Actual OS notification permission respected")
            sendStatus(0, Bundle().apply { putString("stream", "PHASE4_NOTIFICATION permission=$permission shown=$shown\n") })
            if (shown) {
                val notification = manager.activeNotifications.first { it.tag == "apk-guard" }.notification
                verify(notification.visibility == android.app.Notification.VISIBILITY_PRIVATE, "Private lock-screen visibility")
                verify(notification.publicVersion != null, "Generic public version")
                verify(!notification.extras.toString().contains("content://"), "Notification contains no URI")
            }
            InstallProtectionCoordinator.setEnabled(ctx, false)
            verify(BlockedThreatHistory.entries(ctx).isEmpty(), "Opt-out clears history")
            verify(File(ctx.cacheDir, "apk-forward").listFiles().orEmpty().isEmpty(), "Opt-out clears owned snapshots")
            verify(manager.activeNotifications.none { it.tag == "apk-guard" }, "Opt-out cancels notification")
            verify(!InstallProtectionCoordinator.strict(ctx) && !ctx.options().getBoolean("apkAlerts", false), "Opt-out clears strict/alerts")
        } catch (error: Throwable) { failure = error }
        finally {
            if (ownsState) {
                InstallProtectionCoordinator.clear(ctx); BlockedThreatHistory.clear(ctx)
                val edit = ctx.options().edit()
                keys.forEach { edit.remove(it) }
                before.forEach { (key, value) -> if (value is Boolean) edit.putBoolean(key, value) }
                edit.commit()
                if (!notificationsOnly) runCatching { ctx.contentResolver.call(base, "cleanup", null, null) }
            }
        }
        finish(if (failure == null) 0 else 1, Bundle().apply {
            putString("stream", if (failure == null) "$checks PHASE4 Android checks passed.\n"
                else "$checks PHASE4 checks before failure: ${failure?.javaClass?.simpleName}: ${failure?.message.orEmpty().take(140)}\n")
        })
    }.start() }
}
