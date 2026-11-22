package uz.app.shieldguard

internal object ApkRiskAnalyzer {
    fun inspect(info: ApkMetadata): Map<String, Int> = buildMap {
        val sms = info.permissions.any { it in setOf("android.permission.READ_SMS",
            "android.permission.RECEIVE_SMS", "android.permission.SEND_SMS") }
        if (info.details["signatureStatus"] == "signatureFailed") put("signatureFailed", 30)
        if (info.unprotectedExports) put("apkExported", 15)
        if (sms) put("apkSms", 25)
        if (info.accessibility) put("apkAccess", 30)
        if ("android.permission.REQUEST_INSTALL_PACKAGES" in info.permissions) put("apkInstall", 25)
        if (sms && "android.permission.INTERNET" in info.permissions) put("apkCombo", 20)
    }
}

internal object PackageUpdateMonitor {
    fun packageFor(action: String?, name: String?, replacing: Boolean): String? {
        if (name == null || name.length > 255 ||
            !Regex("""[a-zA-Z][a-zA-Z0-9_]*(?:\.[a-zA-Z][a-zA-Z0-9_]*)+""").matches(name)) return null
        return when (action) {
            "android.intent.action.PACKAGE_ADDED" -> if (replacing) null else name
            "android.intent.action.PACKAGE_REPLACED" -> name
            else -> null
        }
    }
}

internal object InstalledAppPolicy {
    const val batchSize = 8
    const val inventoryLimit = 512
    const val queueLimit = 32
    fun changed(enabled: Boolean, visible: Map<String, Long>, known: Map<String, Long>): List<String> =
        if (!enabled) emptyList() else visible.filter { (name, stamp) -> known[name] != stamp }.keys.take(batchSize)

    fun pendingChanges(pending: Set<String>, visible: Map<String, Long>, known: Map<String, Long>) =
        pending.filter { visible[it] == null || visible[it] != known[it] }.toSet()

    fun findings(info: ApkMetadata): Map<String, Int> = ApkRiskAnalyzer.inspect(info).toMutableMap().apply {
        val install = "android.permission.REQUEST_INSTALL_PACKAGES" in info.permissions
        val overlay = "android.permission.SYSTEM_ALERT_WINDOW" in info.permissions
        if ((info.accessibility && (install || overlay)) ||
            ("apkCombo" in this && install)) put("installedCombo", 30)
        put("installedTrustUnknown", 0) // No production developer roots have been supplied.
    }

    // SMS + Internet and an exported launcher alone must not trigger an automatic alarm.
    fun shouldAlert(findings: Map<String, Int>, notificationsAllowed: Boolean): Boolean =
        notificationsAllowed && findings.values.sum() >= 50 &&
            ("installedCombo" in findings || "signatureFailed" in findings ||
                findings.filterKeys { it !in setOf("apkSms", "apkCombo", "apkExported",
                    "apkAccess", "apkInstall", "installedTrustUnknown") }.values.sum() >= 50)
}
