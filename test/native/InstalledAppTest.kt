package uz.app.shieldguard

fun main() {
    var checks = 0
    fun verify(value: Boolean) { check(value); checks++ }
    fun metadata(vararg permissions: String, access: Boolean = false, exported: Boolean = false) =
        ApkMetadata("uz.app.synthetic", permissions.toSet(), access, listOf("fixture-certificate"),
            mapOf("signatureStatus" to "installedPlatformSignature"), exported)
    val added = "android.intent.action.PACKAGE_ADDED"
    val replaced = "android.intent.action.PACKAGE_REPLACED"
    verify(PackageUpdateMonitor.packageFor(added, "uz.app.sample", false) == "uz.app.sample")
    verify(PackageUpdateMonitor.packageFor(added, "uz.app.sample", true) == null)
    verify(PackageUpdateMonitor.packageFor(replaced, "uz.app.sample", true) == "uz.app.sample")
    verify(PackageUpdateMonitor.packageFor("arbitrary", "uz.app.sample", false) == null)
    verify(PackageUpdateMonitor.packageFor(added, "../sample", false) == null)
    verify(PackageUpdateMonitor.packageFor(added, null, false) == null)
    val visible = linkedMapOf("uz.app.old" to 1L, "uz.app.update" to 2L, "uz.app.new" to 1L)
    val known = mapOf("uz.app.old" to 1L, "uz.app.update" to 1L)
    verify(InstalledAppPolicy.changed(true, visible, known) == listOf("uz.app.update", "uz.app.new"))
    verify(InstalledAppPolicy.changed(false, visible, known).isEmpty())
    verify(InstalledAppPolicy.changed(true, visible, visible).isEmpty())
    verify(InstalledAppPolicy.pendingChanges(setOf("uz.app.old", "uz.app.new"), visible, known) == setOf("uz.app.new"))
    verify(InstalledAppPolicy.pendingChanges(setOf("uz.app.hidden"), visible, known) == setOf("uz.app.hidden"))
    verify(InstalledAppPolicy.changed(true, emptyMap(), known).isEmpty()) // No inferred full visibility.
    verify(InstalledAppPolicy.changed(true, (1..50).associate { "uz.app.p$it" to 1L }, emptyMap()).size == 8)
    fun alerts(info: ApkMetadata, permitted: Boolean = true) =
        InstalledAppPolicy.shouldAlert(InstalledAppPolicy.findings(info), permitted)
    verify(!alerts(metadata("android.permission.INTERNET", exported = true)))
    verify(!alerts(metadata("android.permission.READ_SMS", "android.permission.INTERNET", exported = true)))
    verify(!alerts(metadata("android.permission.REQUEST_INSTALL_PACKAGES", exported = true)))
    verify(!alerts(metadata(access = true, exported = true))) // Accessibility tools are not malware.
    val risky = metadata("android.permission.READ_SMS", "android.permission.INTERNET",
        "android.permission.REQUEST_INSTALL_PACKAGES", exported = true)
    verify(alerts(risky))
    verify(!alerts(risky, permitted = false))
    verify(alerts(metadata("android.permission.SYSTEM_ALERT_WINDOW", access = true)))
    verify(alerts(metadata("android.permission.REQUEST_INSTALL_PACKAGES", access = true)))
    verify(!alerts(metadata("android.permission.SYSTEM_ALERT_WINDOW")))
    verify(InstalledAppPolicy.findings(metadata())["installedTrustUnknown"] == 0)
    verify(!InstalledAppPolicy.shouldAlert(mapOf("installedUnavailable" to 0), true))
    verify(!InstalledAppPolicy.shouldAlert(mapOf("installedMetadataOnly" to 0), true))
    verify(!InstalledAppPolicy.shouldAlert(mapOf("contentLimit" to 0, "scanTimeout" to 0), true))
    verify(InstalledAppPolicy.shouldAlert(mapOf("dexDynamic" to 30, "dexInstaller" to 25), true))
    println("$checks installed-app policy checks passed.")
}
