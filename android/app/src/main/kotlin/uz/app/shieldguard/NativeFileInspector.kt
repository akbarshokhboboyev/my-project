package uz.app.shieldguard

import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import java.io.File
import java.io.FileNotFoundException
import java.security.MessageDigest

internal class NativeFileInspector(private val context: Context) {
    fun inspect(uri: Uri, cancelled: () -> Boolean = { false }): Map<String, Any> {
        require(uri.scheme == "content")
        val displayName = context.contentResolver.query(
            uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null
        )?.use { if (it.moveToFirst()) it.getString(0) else null }.orEmpty()
        val analyzer = FileAnalyzer(File(context.cacheDir, "shield-scans"), cancelled = cancelled,
            inspectPdf = { file ->
                PdfInspector(context).inspect(file, cancelled).let { it.findings to it.complete }
            }, readApk = ::readApk)
        return analyzer.inspect(displayName) {
            context.contentResolver.openInputStream(uri) ?: throw FileNotFoundException()
        }
    }

    @Suppress("DEPRECATION")
    private fun readApk(file: File): ApkMetadata? {
        val info = context.packageManager.getPackageArchiveInfo(file.path,
            PackageManager.GET_PERMISSIONS or PackageManager.GET_SERVICES or PackageManager.GET_ACTIVITIES or
                PackageManager.GET_RECEIVERS or PackageManager.GET_PROVIDERS) ?: return null
        val verification = runCatching {
            com.android.apksig.ApkVerifier.Builder(file)
                .setMinCheckedPlatformVersion(maxOf(26, info.applicationInfo?.minSdkVersion ?: 26))
                .build().verify()
        }.getOrNull()
        val signerHashes = verification?.signerCertificates.orEmpty().map { certificate ->
            MessageDigest.getInstance("SHA-256").digest(certificate.encoded)
                .joinToString("") { "%02x".format(it) }
        }
        return ApkMetadata(
            info.packageName,
            info.requestedPermissions.orEmpty().toSet(),
            info.services.orEmpty().any { it.permission == "android.permission.BIND_ACCESSIBILITY_SERVICE" },
            signerHashes,
            mapOf("versionCode" to (if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()),
                "versionName" to (info.versionName ?: ""),
                "minSdk" to (info.applicationInfo?.minSdkVersion ?: 0),
                "targetSdk" to (info.applicationInfo?.targetSdkVersion ?: 0),
                "permissions" to info.requestedPermissions.orEmpty().toList(),
                "signatureStatus" to when (verification?.isVerified) {
                    true -> "signatureVerified"
                    false -> "signatureFailed"
                    null -> "signatureUnchecked"
                }),
            info.activities.orEmpty().any { it.exported && it.permission.isNullOrEmpty() } ||
                info.receivers.orEmpty().any { it.exported && it.permission.isNullOrEmpty() } ||
                info.services.orEmpty().any { it.exported && it.permission.isNullOrEmpty() } ||
                info.providers.orEmpty().any { it.exported && it.readPermission.isNullOrEmpty() && it.writePermission.isNullOrEmpty() }
        )
    }
}
