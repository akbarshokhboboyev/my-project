package uz.app.shieldguard

import android.Manifest
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.service.notification.NotificationListenerService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private lateinit var bridge: MethodChannel
    private var picker: MethodChannel.Result? = null
    private var nextRebindAt = 0L
    private val inbox = ArrayDeque<Map<String, Any>>()
    private val worker = ThreadPoolExecutor(1, 1, 0L, TimeUnit.SECONDS, ArrayBlockingQueue(4))

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        bridge = MethodChannel(engine.dartExecutor.binaryMessenger, "uz.app.shieldguard/platform")
        TelegramThreatListener.connectionChanged = { bridge.invokeMethod("statusChanged", null) }
        bridge.setMethodCallHandler { call, reply ->
            when (call.method) {
                "status" -> {
                    val manager = getSystemService(NotificationManager::class.java)
                    val component = ComponentName(this, TelegramThreatListener::class.java)
                    val access = if (Build.VERSION.SDK_INT >= 27) manager.isNotificationListenerAccessGranted(component)
                    else Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                        ?.split(':')?.any { ComponentName.unflattenFromString(it) == component } == true
                    val enabled = options().getBoolean("enabled", false)
                    val now = SystemClock.elapsedRealtime()
                    if (access && enabled && !TelegramThreatListener.connected && now >= nextRebindAt) {
                        nextRebindAt = now + 15_000
                        runCatching { NotificationListenerService.requestRebind(component) }
                    }
                    reply.success(mapOf(
                        "access" to access, "connected" to TelegramThreatListener.connected,
                        "enabled" to enabled,
                        "alerts" to (manager.areNotificationsEnabled() &&
                            manager.getNotificationChannel("protection")?.importance != NotificationManager.IMPORTANCE_NONE),
                        "history" to options().getBoolean("history", false),
                        "intro" to options().getBoolean("intro", false),
                        "dark" to options().getBoolean("dark", false)
                    ))
                }
                "option" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<Boolean>("value")
                    if (key == null || key !in setOf("enabled", "history", "intro", "dark") || value == null) {
                        reply.error("invalid", null, null)
                    } else {
                        options().edit().putBoolean(key, value).apply()
                        reply.success(null)
                    }
                }
                "access" -> {
                    settings(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS), reply)
                }
                "alerts" -> {
                    val canPrompt = Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED &&
                        (!options().getBoolean("alertsPrompted", false) ||
                            shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS))
                    if (canPrompt) {
                        options().edit().putBoolean("alertsPrompted", true).apply()
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 82)
                        reply.success(null)
                    } else {
                        settings(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName), reply)
                    }
                }
                "pick" -> {
                    if (picker != null) reply.error("busy", null, null)
                    else {
                        picker = reply
                        try {
                            @Suppress("DEPRECATION")
                            startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT)
                                .addCategory(Intent.CATEGORY_OPENABLE).setType("*/*"), 81)
                        } catch (_: RuntimeException) {
                            picker = null
                            reply.error("unavailable", null, null)
                        }
                    }
                }
                "pending" -> reply.success(inbox.removeFirstOrNull())
                "history" -> background(reply) { HistoryStore(this).use { it.entries() } }
                "clear" -> background(reply) { HistoryStore(this).use { it.clear() }; null }
                "record" -> background(reply) {
                    val type = call.argument<String>("type") ?: "file"
                    val score = call.argument<Int>("score") ?: 0
                    val count = call.argument<Int>("count") ?: 0
                    val complete = call.argument<Boolean>("complete") ?: false
                    val time = call.argument<Number>("time")?.toLong() ?: System.currentTimeMillis()
                    HistoryStore(this).use { it.record(type, score, count, complete, time) }
                    null
                }
                else -> reply.notImplemented()
            }
        }
        accept(intent)
    }

    private fun settings(intent: Intent, reply: MethodChannel.Result) {
        try {
            startActivity(intent)
            reply.success(null)
        } catch (_: android.content.ActivityNotFoundException) {
            reply.error("unavailable", null, null)
        }
    }

    private fun background(reply: MethodChannel.Result?, action: () -> Any?) {
        try {
            worker.execute {
                try {
                    val value = action()
                    runOnUiThread { if (reply != null) reply.success(value) else if (value is Map<*, *>) enqueue(value) }
                } catch (e: Exception) {
                    val code = when (e) {
                        is SecurityException -> "filePermission"
                        is FileNotFoundException -> "fileMissing"
                        else -> "failed"
                    }
                    runOnUiThread {
                        if (reply != null) reply.error(code, null, null)
                        else enqueue(mapOf("kind" to "file", "complete" to false, "findings" to mapOf(code to 0)))
                    }
                }
            }
        } catch (_: java.util.concurrent.RejectedExecutionException) {
            if (reply != null) reply.error("busy", null, null)
            else enqueue(mapOf("kind" to "file", "complete" to false, "findings" to mapOf("busy" to 0)))
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun enqueue(value: Map<*, *>) {
        if (inbox.size >= 8) inbox.removeFirst()
        inbox.addLast(value as Map<String, Any>)
        bridge.invokeMethod("incoming", null)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        accept(intent)
    }

    private fun accept(intent: Intent?) {
        if (intent == null) return
        try {
            when (intent.action) {
                Intent.ACTION_SEND -> {
                    @Suppress("DEPRECATION")
                    val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                    if (uri?.scheme == "content" && intent.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION != 0) {
                        background(null) { NativeFileInspector(applicationContext).inspect(uri) }
                    } else if (uri == null) {
                        intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.take(32000)?.toString()?.let {
                            enqueue(mapOf("kind" to "text", "text" to it))
                        }
                    } else {
                        enqueue(mapOf("kind" to "file", "complete" to false, "findings" to mapOf("filePermission" to 0)))
                    }
                }
                SHOW_ALERT -> {
                    if (intent.getStringExtra("proof") != alertProof(this)) return
                    val codes = intent.getStringArrayExtra("indicators").orEmpty().take(8)
                    val findings = NotificationAnalyzer.weights.filterKeys { it in codes }
                    if (findings.isNotEmpty()) enqueue(mapOf("kind" to "alert", "findings" to findings,
                        "complete" to true, "time" to intent.getLongExtra("time", 0)))
                }
            }
        } catch (_: RuntimeException) {
            enqueue(mapOf("kind" to "file", "complete" to false, "findings" to mapOf("failed" to 0)))
        } finally {
            setIntent(Intent(this, MainActivity::class.java))
        }
    }

    @Deprecated("Used by FlutterActivity's Android result API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 81) return
        val reply = picker ?: return
        picker = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) reply.success(null)
        else background(reply) { NativeFileInspector(applicationContext).inspect(uri) }
    }

    override fun onDestroy() {
        TelegramThreatListener.connectionChanged = null
        if (::bridge.isInitialized) bridge.setMethodCallHandler(null)
        worker.shutdown()
        super.onDestroy()
    }

    companion object {
        internal const val SHOW_ALERT = "uz.app.shieldguard.SHOW_ALERT"
    }
}
