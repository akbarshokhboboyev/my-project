package uz.app.shieldguard

fun main() {
    var checks = 0
    fun verify(v: Boolean) { check(v); checks++ }
    fun report(findings: Map<String, Int> = emptyMap(), status: String = "signatureVerified", complete: Boolean = true) =
        mapOf<String, Any>("format" to "APK · benign.fixture", "signatureChecked" to (status != "signatureUnchecked"),
            "details" to mapOf("signatureStatus" to status), "complete" to complete, "findings" to findings)
    verify(ApkRiskPolicy.assess(report()).risk == "noFindings")
    verify(ApkRiskPolicy.assess(report(mapOf("apkSms" to 25))).risk == "heuristicWarning")
    verify(ApkRiskPolicy.assess(report(mapOf("doubleExtension" to 45))).risk == "heuristicWarning")
    verify(ApkRiskPolicy.assess(report(status = "signatureFailed")).risk == "strongSuspicion")
    verify(ApkRiskPolicy.assess(report(), knownMalicious = true).risk == "confirmedHighConfidenceThreat")
    verify(ApkRiskPolicy.assess(report(complete = false)).risk == "unknown")
    verify(ApkRiskPolicy.assess(report(status = "signatureUnchecked")).risk == "unknown")
    verify(ApkRiskPolicy.assess(report(mapOf("apkAccess" to 30, "apkInstall" to 25, "apkSms" to 25))).risk == "strongSuspicion")
    verify(ApkRiskPolicy.assess(report(mapOf("apkAccess" to 30, "apkInstall" to 25))).risk == "heuristicWarning")
    verify(ApkRiskPolicy.assess(report(mapOf("apkExported" to 15))).risk == "heuristicWarning")
    verify(ApkRiskPolicy.assess(report()).confidence != "high")
    verify(!ApkRiskPolicy.assess(report(status = "signatureFailed")).complete)
    verify((ApkDiscoveryCoordinator.decorate(report(), "photo.jpg.apk")["details"] as Map<*, *>)["apkActualFormat"] == true)
    val fake = mapOf<String, Any>("format" to "PDF", "complete" to true)
    verify((ApkDiscoveryCoordinator.decorate(fake, "fake.apk")["details"] as Map<*, *>)["apkActualFormat"] == false)
    verify(ApkDiscoveryCoordinator.decorate(fake, "plain.pdf") == fake)
    verify(ApkRiskPolicy.assess(report() + mapOf("knownMalicious" to true)).risk == "noFindings")
    verify(ApkRiskPolicy.assess(report(mapOf("apkSms" to 100, "apkInstall" to 100))).score == 100)
    println("$checks APK discovery/risk checks passed.")
}
