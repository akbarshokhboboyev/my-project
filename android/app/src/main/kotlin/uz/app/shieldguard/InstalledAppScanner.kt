package uz.app.shieldguard

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import java.io.File
import java.security.MessageDigest

internal class InstalledAppScanner(private val context: Context) {
    @Suppress("DEPRECATION")
    fun inspect(name: String, cancelled: () -> Boolean): Map<String, Any> {
        val pm = context.packageManager
        val info = try {
            pm.getPackageInfo(name, PackageManager.GET_PERMISSIONS or PackageManager.GET_SERVICES or
                PackageManager.GET_ACTIVITIES or PackageManager.GET_RECEIVERS or PackageManager.GET_PROVIDERS or
                if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES)
        } catch (_: PackageManager.NameNotFoundException) { return unavailable() }
          catch (_: SecurityException) { return unavailable() }
        if (cancelled()) return unavailable("scanCancelled")
        val app = info.applicationInfo ?: return unavailable()
        val signers = (if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners
            else info.signatures).orEmpty().map {
            MessageDigest.getInstance("SHA-256").digest(it.toByteArray()).joinToString("") { b -> "%02x".format(b) }
        }
        val label = pm.getApplicationLabel(app).toString()
            .filterNot { it.isISOControl() || it in '\u202a'..'\u202e' || it in '\u2066'..'\u2069' }.take(64)
        val details = mapOf<String, Any>(
            "installedPackage" to name, "installedLabel" to label,
            "familyMetadataChecked" to true,
            "keyboardService" to info.services.orEmpty().any { it.permission == "android.permission.BIND_INPUT_METHOD" },
            "notificationService" to info.services.orEmpty().any { it.permission == "android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" },
            "declaredService" to info.services.orEmpty().isNotEmpty(),
            "versionCode" to (if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()),
            "versionName" to (info.versionName ?: ""), "minSdk" to app.minSdkVersion,
            "targetSdk" to app.targetSdkVersion, "permissions" to info.requestedPermissions.orEmpty().toList(),
            "signatureStatus" to "installedPlatformSignature", "installedUpdated" to info.lastUpdateTime)
        val metadata = ApkMetadata(name, info.requestedPermissions.orEmpty().toSet(),
            info.services.orEmpty().any { it.permission == "android.permission.BIND_ACCESSIBILITY_SERVICE" },
            signers, details,
            info.activities.orEmpty().any { it.exported && it.permission.isNullOrEmpty() } ||
                info.receivers.orEmpty().any { it.exported && it.permission.isNullOrEmpty() } ||
                info.providers.orEmpty().any { it.exported && it.readPermission.isNullOrEmpty() && it.writePermission.isNullOrEmpty() } ||
                info.services.orEmpty().any { it.exported && it.permission.isNullOrEmpty() })
        val findings = InstalledAppPolicy.findings(metadata).toMutableMap()
        val sources = listOfNotNull(app.sourceDir) + app.splitSourceDirs.orEmpty()
        var complete = sources.isNotEmpty() && sources.size <= 8
        var contentRead = false
        val staticEvidence = ThreatFamilyAnalyzer.metadata(metadata).toMutableSet()
        var familyCoverage = complete
        var verified = complete
        for (source in sources.take(8)) {
            if (cancelled()) return unavailable("scanCancelled")
            val file = File(source)
            if (!file.isFile || !file.canRead() || file.length() !in 1..(32L * 1024 * 1024)) {
                complete = false; verified = false; familyCoverage = false; continue
            }
            val report = try {
                FileAnalyzer(File(context.cacheDir, "shield-scans"),
                    ScanLimits(maxFileBytes = 32L * 1024 * 1024, maxMillis = 5_000),
                    cancelled, readApk = NativeFileInspector(context)::readApk)
                    .inspect("base.apk") { file.inputStream() }
            } catch (_: Exception) { null }
            if (report == null) { complete = false; verified = false; familyCoverage = false; continue }
            val sourceDetails = report["details"] as? Map<*, *>
            staticEvidence.addAll((sourceDetails?.get("staticEvidence") as? List<*>)?.filterIsInstance<String>().orEmpty())
            familyCoverage = familyCoverage && sourceDetails?.get("familyCoverage") == true
            contentRead = true
            complete = complete && report["complete"] == true
            verified = verified && report["signatureChecked"] == true &&
                (report["details"] as? Map<*, *>)?.get("signatureStatus") == "signatureVerified"
            (report["findings"] as? Map<*, *>)?.forEach { (key, value) ->
                if (key is String && value is Int) findings[key] = value
            }
        }
        if (!complete) findings["installedMetadataOnly"] = 0
        if (cancelled()) return unavailable("scanCancelled")
        val report = mapOf("kind" to "file", "format" to ("APK · " + name), "signers" to signers,
            "signatureChecked" to (verified || "signatureFailed" in findings), "findings" to findings, "complete" to complete,
            "time" to System.currentTimeMillis(),
            "details" to (details + mapOf("installedCoverage" to
                (if (complete) "installedContent" else if (contentRead) "installedPartial" else "installedMetadataOnly"),
                "signatureStatus" to if ("signatureFailed" in findings) "signatureFailed"
                    else if (verified) "signatureVerified" else "installedPlatformSignature", "familyCoverage" to familyCoverage)))
        return ThreatFamilyAnalyzer.decorate(report, staticEvidence, familyCoverage && complete)
    }

    private fun unavailable(reason: String = "installedUnavailable"): Map<String, Any> =
        mapOf("kind" to "file", "complete" to false, "findings" to mapOf(reason to 0),
            "details" to mapOf("installedCoverage" to "installedUnavailable"), "time" to System.currentTimeMillis())
}
