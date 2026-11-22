package uz.app.shieldguard

internal data class ApkAssessment(val risk: String, val confidence: String, val score: Int,
    val complete: Boolean, val evidence: List<String>, val method: String = "localStatic") {
    fun asMap(): Map<String, Any> = mapOf("risk" to risk, "confidence" to confidence,
        "score" to score, "complete" to complete, "evidence" to evidence, "method" to method,
        "severity" to if (risk in setOf("confirmedHighConfidenceThreat", "strongSuspicion")) "high"
            else if (risk == "heuristicWarning") "medium" else "undetermined")
}

internal object ApkRiskPolicy {
    // Reputation is a separate, trusted-adapter argument, never taken from file metadata.
    // No live provider is wired here: local scans must never upload automatically.
    fun assess(report: Map<String, Any>, knownMalicious: Boolean = false): ApkAssessment {
        val findings = (report["findings"] as? Map<*, *>).orEmpty()
        val evidence = findings.entries.filter { (it.value as? Int ?: 0) > 0 }
            .mapNotNull { it.key as? String }.take(64)
        val details = (report["details"] as? Map<*, *>).orEmpty()
        val checked = report["signatureChecked"] == true && details["signatureStatus"] in setOf("signatureVerified", "signatureFailed")
        val complete = report["complete"] == true && checked
        val score = findings.values.sumOf { (it as? Int ?: 0).coerceIn(0, 100) }.coerceAtMost(100)
        val integrity = report["signatureChecked"] == true && details["signatureStatus"] == "signatureFailed"
        val sensitiveCombo = "apkAccess" in evidence && "apkInstall" in evidence &&
            ("apkSms" in evidence || evidence.any { it.startsWith("dex") && it !in setOf("dexMalformed", "dexHeader") })
        val risk = when {
            knownMalicious -> "confirmedHighConfidenceThreat"
            integrity || sensitiveCombo -> "strongSuspicion"
            !complete -> "unknown"
            evidence.isNotEmpty() -> "heuristicWarning"
            else -> "noFindings"
        }
        return ApkAssessment(risk, when (risk) {
            "confirmedHighConfidenceThreat" -> "high"
            "strongSuspicion" -> if (integrity) "high" else "medium"
            "unknown" -> "undetermined"
            else -> "limited"
        }, score, complete, if (knownMalicious) listOf("knownMaliciousHash") + evidence else evidence,
            if (knownMalicious) "consentedHashProvider" else "localStatic")
    }
}

internal object ApkDiscoveryCoordinator {
    fun decorate(report: Map<String, Any>, displayName: String): Map<String, Any> {
        val format = (report["format"] as? String).orEmpty().substringBefore(" · ")
        val candidate = format == "APK" || displayName.lowercase().endsWith(".apk")
        if (!candidate) return report
        val assessment = ApkRiskPolicy.assess(report)
        // Filename and URI are neither returned nor persisted as detection evidence.
        return report + mapOf("details" to ((report["details"] as? Map<*, *>).orEmpty() +
            mapOf("apkAssessment" to assessment.asMap(), "apkActualFormat" to (format == "APK"))))
    }
}
