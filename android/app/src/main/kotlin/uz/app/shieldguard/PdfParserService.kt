package uz.app.shieldguard

import android.app.Service
import android.content.Intent
import android.os.*
import com.tom_roush.pdfbox.cos.*
import com.tom_roush.pdfbox.io.MemoryUsageSetting
import com.tom_roush.pdfbox.pdmodel.PDDocument
import java.util.Collections
import java.util.IdentityHashMap

/** Read-only descriptors are parsed in an isolated UID without application permissions. */
class PdfParserService : Service() {
    override fun onCreate() {
        super.onCreate()
        com.tom_roush.pdfbox.android.PDFBoxResourceLoader.init(applicationContext)
    }
    private val messenger = Messenger(Handler(Looper.getMainLooper()) { request ->
        val reply = request.replyTo
        @Suppress("DEPRECATION")
        val descriptor = request.data.getParcelable<ParcelFileDescriptor>("file")
        if (descriptor == null || reply == null) return@Handler true
        Thread({
            val findings = Bundle()
            var complete = false
            try {
                ParcelFileDescriptor.AutoCloseInputStream(descriptor).use { input ->
                    PDDocument.load(input, MemoryUsageSetting.setupMainMemoryOnly(8L * 1024 * 1024)).use { document ->
                        val queue = ArrayDeque<COSBase>()
                        val visited = Collections.newSetFromMap(IdentityHashMap<COSBase, Boolean>())
                        if (document.document.objects.size > 20000) throw IllegalStateException()
                        document.document.objects.forEach { queue.add(it) }
                        var count = 0
                        while (queue.isNotEmpty()) {
                            if (++count > 20000 || queue.size > 20000) throw IllegalStateException()
                            val value = queue.removeFirst()
                            if (!visited.add(value)) continue
                            when (value) {
                                is COSObject -> value.getObject()?.let { queue.add(it) }
                                is COSDictionary -> {
                                    for ((key, child) in value.entrySet()) {
                                        when (key.name) {
                                            "JS", "JavaScript", "OpenAction", "AA", "Launch" -> findings.putInt("pdfAction", 25)
                                            "EmbeddedFiles", "EmbeddedFile", "Filespec" -> findings.putInt("pdfEmbedded", 20)
                                            "URI" -> findings.putInt("pdfUri", 10)
                                        }
                                        if (child is COSName) {
                                            when (child.name) {
                                                "JavaScript", "Launch" -> findings.putInt("pdfAction", 25)
                                                "EmbeddedFile", "Filespec" -> findings.putInt("pdfEmbedded", 20)
                                            }
                                        }
                                        queue.add(child)
                                    }
                                }
                                is COSArray -> for (child in value) queue.add(child)
                            }
                        }
                        complete = true
                        findings.putInt("pdfParsed", 0)
                    }
                }
            } catch (_: com.tom_roush.pdfbox.pdmodel.encryption.InvalidPasswordException) {
                findings.putInt("pdfEncrypted", 0)
            } catch (_: Exception) {
                findings.putInt("pdfParseIncomplete", 0)
            } finally {
                runCatching { descriptor.close() }
                runCatching {
                    reply.send(Message.obtain().apply {
                        data = Bundle().apply {
                            putBundle("findings", findings)
                            putBoolean("complete", complete)
                        }
                    })
                }
            }
        }, "shieldguard-pdf").start()
        true
    })
    override fun onBind(intent: Intent): IBinder = messenger.binder
    override fun onUnbind(intent: Intent): Boolean {
        Process.killProcess(Process.myPid())
        return false
    }
}
