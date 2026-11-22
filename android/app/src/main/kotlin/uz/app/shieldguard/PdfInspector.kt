package uz.app.shieldguard

import android.content.*
import android.os.*
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

internal data class PdfInspection(val findings: Map<String, Int>, val complete: Boolean)

internal class PdfInspector(private val context: Context) {
    fun inspect(file: File, cancelled: () -> Boolean): PdfInspection {
        if (file.length() > 4L * 1024 * 1024) return PdfInspection(mapOf("contentLimit" to 0), false)
        val done = CountDownLatch(1)
        var result = PdfInspection(mapOf("pdfParseIncomplete" to 0), false)
        val descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
        val receiver = Messenger(Handler(Looper.getMainLooper()) { response ->
            val findings = response.data.getBundle("findings") ?: Bundle()
            result = PdfInspection(findings.keySet().associateWith { findings.getInt(it) },
                response.data.getBoolean("complete"))
            done.countDown()
            true
        })
        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName, binder: IBinder) {
                try {
                    Messenger(binder).send(Message.obtain().apply {
                        replyTo = receiver
                        data = Bundle().apply { putParcelable("file", descriptor) }
                    })
                } catch (_: RemoteException) { done.countDown() }
            }
            override fun onServiceDisconnected(name: ComponentName) { done.countDown() }
            override fun onNullBinding(name: ComponentName) { done.countDown() }
            override fun onBindingDied(name: ComponentName) { done.countDown() }
        }
        var bound = false
        try {
            bound = context.bindService(Intent(context, PdfParserService::class.java), connection, Context.BIND_AUTO_CREATE)
            if (!bound) return result
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(10)
            while (!done.await(100, TimeUnit.MILLISECONDS)) {
                if (cancelled()) return PdfInspection(mapOf("scanCancelled" to 0), false)
                if (System.nanoTime() >= deadline) return PdfInspection(mapOf("scanTimeout" to 0), false)
            }
            return result
        } finally {
            if (bound) context.unbindService(connection)
            descriptor.close()
        }
    }
}
