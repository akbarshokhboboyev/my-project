package uz.app.shieldguard

internal data class FamilyAssessment(val family: String, val status: String, val evidence: List<String>,
    val complete: Boolean) {
    fun asMap(): Map<String, Any> = mapOf("family" to family, "status" to status, "evidence" to evidence,
        "complete" to complete, "method" to "staticReferencesAndManifest",
        "severity" to when (status) { "strongIndicators" -> "high"; "possibleIndicators" -> "medium"; "noIndicatorsObserved" -> "low"; else -> "undetermined" },
        "confidence" to when (status) { "strongIndicators" -> "medium"; "possibleIndicators" -> "limited"; else -> "undetermined" },
        "explanation" to "family${family.replaceFirstChar { it.uppercase() }}Explanation")
}

/** Static combinations only. Neither API references nor permissions prove execution or intent. */
internal object ThreatFamilyAnalyzer {
    val families = listOf("ransomware", "spyware", "banking", "rat")
    fun metadata(info: ApkMetadata): Set<String> = buildSet {
        fun permission(name: String) = "android.permission.$name" in info.permissions
        if (permission("INTERNET")) add("networkPermission")
        if (permission("MANAGE_EXTERNAL_STORAGE") || permission("WRITE_EXTERNAL_STORAGE")) add("broadStoragePermission")
        if (permission("SYSTEM_ALERT_WINDOW")) add("overlayPermission")
        if (permission("READ_SMS") || permission("RECEIVE_SMS")) add("smsPermission")
        if (permission("CAMERA")) add("cameraPermission")
        if (permission("RECORD_AUDIO")) add("microphonePermission")
        if (info.accessibility) add("accessibilityService")
        if (info.details["keyboardService"] == true) add("keyboardService")
        if (info.details["notificationService"] == true) add("notificationService")
        if (info.details["declaredService"] == true) add("declaredService")
    }

    // Read bounded DEX string-table entries, not arbitrary ZIP assets or raw appended strings.
    fun dexEvidence(bytes: ByteArray): Set<String>? = runCatching {
        if (bytes.size < 112) return null
        val data = java.nio.ByteBuffer.wrap(bytes).order(java.nio.ByteOrder.LITTLE_ENDIAN)
        val count = data.getInt(56); val offset = data.getInt(60)
        if (count !in 0..65536 || offset < 0 || offset.toLong() + count * 4L > bytes.size) return null
        var budget = 1024 * 1024
        val strings = hashSetOf<String>()
        for (index in 0 until count) {
            var position = data.getInt(offset + index * 4)
            if (position !in 112 until bytes.size) return null
            var prefix = 0
            do {
                if (position >= bytes.size || ++prefix > 5) return null
                val value = bytes[position++].toInt() and 255
            } while (value and 128 != 0)
            val start = position
            while (position < bytes.size && bytes[position] != 0.toByte() && position - start <= 2048) position++
            if (position >= bytes.size || position - start > 2048) return null
            budget -= position - start
            if (budget < 0) return null
            strings.add(String(bytes, start, position - start, Charsets.UTF_8))
        }
        references(strings)
    }.getOrNull()

    internal fun references(strings: Set<String>): Set<String> = buildSet {
        fun has(vararg values: String) = values.any { it in strings }
        if (has("Ljavax/crypto/Cipher;")) add("cryptoReference")
        if (has("Ljava/io/FileOutputStream;", "Ljava/nio/file/Files;")) add("fileWriteReference")
        if (has("walkFileTree", "listFiles")) add("fileEnumerationReference")
        if (strings.any { it.lowercase() in setOf("your files are encrypted", "decrypt your files", "ransom payment") }) add("ransomDemandString")
        if (has("onAccessibilityEvent", "onKey", "getCurrentInputConnection") &&
            has("Landroid/view/accessibility/AccessibilityEvent;", "Landroid/view/inputmethod/InputConnection;")) add("inputCaptureReference")
        if (has("Ljava/net/HttpURLConnection;", "Lokhttp3/Request;", "Ljava/net/Socket;")) add("networkCodeReference")
        if (has("getText", "getTextBeforeCursor") && has("password", "otp")) add("credentialCaptureStrings")
        if (has("bank_login", "banking_credentials")) add("bankTargetStrings")
        if (has("keylog_upload", "credential_upload")) add("captureUploadString")
        if (has("Landroid/media/projection/MediaProjection;", "Landroid/accessibilityservice/GestureDescription;")) add("screenControlReference")
        if (has("Ljava/lang/Runtime;", "Ljava/lang/ProcessBuilder;") && has("exec", "start")) add("processExecutionReference")
        if (has("remote_shell", "execute_command")) add("remoteCommandString")
        if (has("hide_icon", "disable_security")) add("concealmentString")
    }

    fun assess(evidence: Set<String>, complete: Boolean): List<FamilyAssessment> {
        fun all(vararg ids: String) = ids.all { it in evidence }
        fun row(name: String, relevant: Set<String>, strong: Boolean, possible: Boolean): FamilyAssessment {
            val status = when { strong -> "strongIndicators"; possible -> "possibleIndicators"; !complete -> "insufficientEvidence"; else -> "noIndicatorsObserved" }
            return FamilyAssessment(name, status, evidence.intersect(relevant).sorted(), complete)
        }
        val ransom = setOf("cryptoReference", "fileWriteReference", "fileEnumerationReference", "broadStoragePermission", "declaredService", "ransomDemandString")
        val spy = setOf("accessibilityService", "keyboardService", "notificationService", "overlayPermission", "inputCaptureReference", "networkPermission", "networkCodeReference", "credentialCaptureStrings", "captureUploadString")
        val bank = spy + setOf("bankTargetStrings", "smsPermission")
        val rat = setOf("screenControlReference", "processExecutionReference", "remoteCommandString", "concealmentString", "cameraPermission", "microphonePermission", "networkPermission", "networkCodeReference", "declaredService", "accessibilityService", "captureUploadString")
        val inputService = "accessibilityService" in evidence || "keyboardService" in evidence
        val network = all("networkPermission", "networkCodeReference")
        return listOf(
            row("ransomware", ransom, evidence.containsAll(ransom), all("cryptoReference", "fileWriteReference", "fileEnumerationReference", "broadStoragePermission")),
            row("spyware", spy, inputService && network && all("inputCaptureReference", "credentialCaptureStrings", "captureUploadString"), inputService && network && "inputCaptureReference" in evidence),
            row("banking", bank, network && all("accessibilityService", "overlayPermission", "credentialCaptureStrings", "bankTargetStrings", "captureUploadString") &&
                ("smsPermission" in evidence || "notificationService" in evidence), all("accessibilityService", "overlayPermission", "credentialCaptureStrings") && network),
            row("rat", rat, network && all("screenControlReference", "processExecutionReference", "remoteCommandString", "concealmentString", "declaredService") &&
                ("cameraPermission" in evidence || "microphonePermission" in evidence), network && all("screenControlReference", "remoteCommandString", "declaredService"))
        )
    }

    fun decorate(report: Map<String, Any>, evidence: Set<String>, coverage: Boolean): Map<String, Any> {
        val rows = assess(evidence, coverage && report["complete"] == true)
        val findings = (report["findings"] as? Map<*, *>).orEmpty().filterKeys { it is String && !it.startsWith("sx") && !it.startsWith("family") }.toMutableMap()
        rows.forEach { row ->
            val key = "family${row.family.replaceFirstChar { it.uppercase() }}"
            if (row.status == "strongIndicators") findings[key] = 70
            else if (row.status == "possibleIndicators") findings[key + "Possible"] = 10
        }
        return report + mapOf("findings" to findings, "details" to ((report["details"] as? Map<*, *>).orEmpty() +
            mapOf("staticEvidence" to evidence.sorted(), "threatFamilies" to rows.map { it.asMap() })))
    }
}
