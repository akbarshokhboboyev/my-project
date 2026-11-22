package uz.app.shieldguard

import android.app.Instrumentation
import android.content.*
import android.net.Uri
import android.os.Bundle
import android.view.accessibility.AccessibilityNodeInfo

class FileShareInstrumentation : Instrumentation() {
    override fun onCreate(arguments: Bundle?) { super.onCreate(arguments); start() }
    override fun onStart() {
        Thread {
            var checks = 0
            fun verify(value: Boolean) { check(value); checks++ }
            val ctx = targetContext
            val base = Uri.parse("content://uz.app.shieldguard.test.filefixtures")
            fun uri(name: String) = Uri.withAppendedPath(base, name)
            fun grant(name: String) { ctx.contentResolver.call(base, "grant", name, null) }
            fun batch(intent: Intent): List<Map<*, *>> =
                (FileOpenScanHandler.scanner(ctx).scan(requireNotNull(FileOpenScanHandler.request(intent))) { false }["batch"] as List<*>)
                    .map { it as Map<*, *> }
            fun send(name: String) = Intent(Intent.ACTION_SEND).setType("application/octet-stream")
                .putExtra(Intent.EXTRA_STREAM, uri(name)).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            try {
                sendStatus(0, Bundle().apply { putString("stream", "PHASE3A_READY_FOR_SENDER\n") })
                val grantDeadline = android.os.SystemClock.elapsedRealtime() + 45_000
                while (ctx.checkUriPermission(uri("document.pdf"), android.os.Process.myPid(), android.os.Process.myUid(),
                        Intent.FLAG_GRANT_READ_URI_PERMISSION) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    check(android.os.SystemClock.elapsedRealtime() < grantDeadline) { "Synthetic sender grant timeout" }
                    Thread.sleep(100)
                }
                ctx.contentResolver.call(base, "prepare", null, null)
                for (name in listOf("document.pdf", "fixture.apk", "harmless.txt", "broken.zip", "large.dat", "missing.pdf")) grant(name)
                val pdf = batch(send("document.pdf")).single()
                verify(pdf["format"] == "PDF")
                verify(pdf["complete"] == true)
                verify((pdf["findings"] as Map<*, *>).values.all { it == 0 })
                val apk = batch(send("fixture.apk")).single()
                verify((apk["format"] as? String)?.startsWith("APK") == true)
                verify(apk["signatureChecked"] == true)
                verify((apk["details"] as Map<*, *>)["signatureStatus"] == "signatureVerified")
                val view = Intent(Intent.ACTION_VIEW).setDataAndType(uri("document.pdf"), "application/pdf")
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                verify(batch(view).single()["format"] == "PDF")
                verify(batch(Intent(Intent.ACTION_SEND).setDataAndType(uri("document.pdf"), "application/pdf")
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)).single()["format"] == "PDF")
                val many = Intent(Intent.ACTION_SEND_MULTIPLE).setType("*/*")
                    .putParcelableArrayListExtra(Intent.EXTRA_STREAM, arrayListOf(uri("document.pdf"), uri("fixture.apk"), uri("document.pdf")))
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                verify(batch(many).size == 2)
                val clip = send("document.pdf").apply { clipData = ClipData.newRawUri("fixture", uri("document.pdf")) }
                verify(batch(clip).size == 1)
                verify("filePermission" in (batch(send("document.pdf").setFlags(0)).single()["findings"] as Map<*, *>))
                ctx.contentResolver.call(base, "revoke", "document.pdf", null)
                verify("filePermission" in (batch(send("document.pdf")).single()["findings"] as Map<*, *>))
                grant("document.pdf")
                val invalid = Intent(Intent.ACTION_VIEW).setData(Uri.parse("file:///private/a.pdf"))
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                verify("sharedInvalid" in (batch(invalid).single()["findings"] as Map<*, *>))
                verify("tooLarge" in (batch(send("large.dat")).single()["findings"] as Map<*, *>))
                verify(batch(send("harmless.txt")).single()["complete"] == false)
                verify((batch(send("harmless.txt")).single()["findings"] as Map<*, *>).values.all { it == 0 })
                verify(batch(send("broken.zip")).single()["complete"] == false)
                val mixed = Intent(Intent.ACTION_SEND_MULTIPLE).setType("*/*")
                    .putParcelableArrayListExtra(Intent.EXTRA_STREAM, arrayListOf(uri("missing.pdf"), uri("document.pdf")))
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                val reports = batch(mixed)
                verify("fileMissing" in (reports.first()["findings"] as Map<*, *>))
                verify(reports.last()["format"] == "PDF")
                val stopped = FileOpenScanHandler.scanner(ctx).scan(requireNotNull(FileOpenScanHandler.request(view))) { true }
                verify("scanCancelled" in (((stopped["batch"] as List<*>).single() as Map<*, *>)["findings"] as Map<*, *>))
                verify(FileOpenScanHandler.request(Intent(Intent.ACTION_SEND).putExtra(Intent.EXTRA_TEXT, "Hello")) == null)

                // Real Activity cold-start VIEW then warm-start SEND, observed through Uzbek Flutter semantics.
                val activity = startActivitySync(Intent(view).setClass(ctx, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                verify(waitText("PDF obyektlari alohida jarayonda tahlil"))
                ctx.startActivity(send("fixture.apk").setClass(ctx, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP))
                verify(waitText("APK imzosi yaxlitligi tasdiqlandi"))
                verify(!activity.isDestroyed)
                ctx.startActivity(Intent(many).setClass(ctx, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP))
                verify(waitText("Fayl tartibi · 2"))
                finish(0, Bundle().apply { putString("stream", "$checks file open/share Android checks passed.\n") })
            } catch (error: Throwable) {
                finish(1, Bundle().apply {
                    putString("stream", "$checks file open/share checks completed before failure: " + error.javaClass.simpleName +
                        " " + error.message.orEmpty().take(250) + " at " +
                        error.stackTrace.firstOrNull { it.className.contains("FileShareInstrumentation") }?.lineNumber + "\n")
                })
            } finally {
                runCatching { ctx.contentResolver.call(base, "cleanup", null, null) }
            }
        }.start()
    }

    private fun waitText(text: String): Boolean {
        val end = android.os.SystemClock.elapsedRealtime() + 45_000
        fun collect(node: AccessibilityNodeInfo?): String {
            if (node == null) return ""
            val own = node.packageName?.toString() == targetContext.packageName
            val value = if (own) node.text?.toString().orEmpty() + node.contentDescription?.toString().orEmpty() else ""
            return value + (0 until node.childCount).joinToString("") { collect(node.getChild(it)) }
        }
        fun scroll(node: AccessibilityNodeInfo?): Boolean {
            if (node == null || node.packageName?.toString() != targetContext.packageName) return false
            if (node.isScrollable && node.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)) return true
            return (0 until node.childCount).any { scroll(node.getChild(it)) }
        }
        while (android.os.SystemClock.elapsedRealtime() < end) {
            val root = uiAutomation.rootInActiveWindow
            if (collect(root).contains(text)) return true
            scroll(root)
            Thread.sleep(400)
        }
        return false
    }
}
