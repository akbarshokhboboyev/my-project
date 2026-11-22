package uz.app.shieldguard

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process

internal object FileOpenScanHandler {
    @Suppress("DEPRECATION")
    fun request(intent: Intent): SharedFileRequest? {
        val flag = intent.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION != 0
        if (intent.action == Intent.ACTION_VIEW)
            return SharedFileRequest(listOfNotNull(intent.data?.toString()), flag)
        if (intent.action !in setOf(Intent.ACTION_SEND, Intent.ACTION_SEND_MULTIPLE)) return null
        val streams = if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
            if (Build.VERSION.SDK_INT >= 33) intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
            else intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
        } else listOfNotNull(if (Build.VERSION.SDK_INT >= 33)
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            else intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM))
        val clip = intent.clipData
        val candidates = streams.orEmpty().take(64).map { it.toString() } +
            (0 until minOf(clip?.itemCount ?: 0, 64)).mapNotNull { clip?.getItemAt(it)?.uri?.toString() }
        val uris = candidates.ifEmpty { listOfNotNull(intent.data?.toString()) }
        if (uris.isEmpty() && intent.action == Intent.ACTION_SEND && !intent.hasExtra(Intent.EXTRA_STREAM)) return null
        return SharedFileRequest(uris.take(64), flag,
            streams.orEmpty().size > 64 || (clip?.itemCount ?: 0) > 64 || uris.size > 64)
    }

    fun scanner(context: Context) = SharedFileScanner(
        readable = { raw ->
            context.checkUriPermission(Uri.parse(raw).normalizeScheme(), Process.myPid(), Process.myUid(),
                Intent.FLAG_GRANT_READ_URI_PERMISSION) == PackageManager.PERMISSION_GRANTED
        },
        inspect = { raw, cancelled ->
            NativeFileInspector(context).inspect(Uri.parse(raw).normalizeScheme(), cancelled)
        }
    )
}
