package uz.app.shieldguard

import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import java.io.File
import java.io.FileNotFoundException
import java.security.MessageDigest

internal class NativeFileInspector(private val context: Context, private val stageForward: Boolean = false,
    private val expectedEpoch: Long = InstallProtectionCoordinator.epoch()) {
    fun inspect(uri: Uri, cancelled: () -> Boolean = { false }): Map<String, Any> {
        require(uri.scheme == "content")
        var oversized = false
        // Optional provider metadata must not prevent an otherwise authorized stream read.
        val displayName = runCatching { context.contentResolver.query(
            uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null
        )?.use {
            if (!it.moveToFirst()) return@use null
            val sizeColumn = it.getColumnIndex(OpenableColumns.SIZE)
            oversized = sizeColumn >= 0 && !it.isNull(sizeColumn) && it.getLong(sizeColumn) > ScanLimits().maxFileBytes
            val nameColumn = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (nameColumn >= 0 && !it.isNull(nameColumn)) it.getString(nameColumn) else null
        } }.getOrNull().orEmpty()
        if (oversized) return ApkDiscoveryCoordinator.decorate(SharedFileScanner.error("tooLarge"), displayName)
        val analyzer = FileAnalyzer(File(context.cacheDir, "shield-scans"), cancelled = cancelled,
            inspectPdf = { file ->
                PdfInspector(context).inspect(file, cancelled).let { it.findings to it.complete }
            }, readApk = ::readApk, onAnalyzed = { file, report ->
                val decorated = ApkDiscoveryCoordinator.decorate(report, displayName)
                if (stageForward) InstallProtectionCoordinator.stage(context, file, decorated, cancelled, expectedEpoch) else decorated
            })
        val report = analyzer.inspect(displayName) {
            context.contentResolver.openInputStream(uri) ?: throw FileNotFoundException()
        }
        return ApkDiscoveryCoordinator.decorate(report, displayName)
    }

    @Suppress("DEPRECATION")
    internal fun readApk(file: File): ApkMetadata? {
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
                "familyMetadataChecked" to true,
                "keyboardService" to info.services.orEmpty().any { it.permission == "android.permission.BIND_INPUT_METHOD" },
                "notificationService" to info.services.orEmpty().any { it.permission == "android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" },
                "declaredService" to info.services.orEmpty().isNotEmpty(),
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
