package uz.app.shieldguard

import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

fun main() {
    var checks = 0
    fun verify(value: Boolean) { check(value); checks++ }
    fun row(family: String, ids: Set<String>, complete: Boolean = true) = ThreatFamilyAnalyzer.assess(ids, complete).first { it.family == family }
    val ransomware = setOf("cryptoReference", "fileWriteReference", "fileEnumerationReference", "broadStoragePermission", "declaredService", "ransomDemandString")
    val spyware = setOf("keyboardService", "inputCaptureReference", "credentialCaptureStrings", "captureUploadString", "networkPermission", "networkCodeReference")
    val banking = setOf("accessibilityService", "overlayPermission", "credentialCaptureStrings", "bankTargetStrings", "captureUploadString", "notificationService", "networkPermission", "networkCodeReference")
    val rat = setOf("screenControlReference", "processExecutionReference", "remoteCommandString", "concealmentString", "declaredService", "cameraPermission", "networkPermission", "networkCodeReference")
    for ((family, ids) in listOf("ransomware" to ransomware, "spyware" to spyware, "banking" to banking, "rat" to rat)) {
        val result = row(family, ids)
        verify(result.status == "strongIndicators")
        verify(result.evidence.isNotEmpty() && result.complete)
        verify(result.asMap()["confidence"] == "medium")
        verify(row(family, ids, false).complete == false)
    }
    verify(row("ransomware", setOf("cryptoReference")).status == "noIndicatorsObserved")
    verify(row("ransomware", ransomware - "ransomDemandString").status == "possibleIndicators") // encryption/backup library
    verify(row("spyware", setOf("accessibilityService", "networkPermission")).status == "noIndicatorsObserved")
    verify(row("spyware", spyware - "captureUploadString").status == "possibleIndicators") // legitimate keyboard assistance
    verify(row("banking", setOf("networkPermission", "credentialCaptureStrings", "bankTargetStrings")).status == "noIndicatorsObserved")
    verify(row("banking", banking - "captureUploadString").status == "possibleIndicators")
    verify(row("rat", rat - setOf("concealmentString", "processExecutionReference")).status == "possibleIndicators") // legitimate remote support
    verify(row("rat", setOf("networkPermission")).status == "noIndicatorsObserved")
    verify(ThreatFamilyAnalyzer.assess(emptySet(), false).all { it.status == "insufficientEvidence" })
    verify(ThreatFamilyAnalyzer.assess(emptySet(), true).all { it.status == "noIndicatorsObserved" })
    val metadata = ApkMetadata("benign.fixture", setOf("android.permission.INTERNET", "android.permission.CAMERA"), false, emptyList(), mapOf("keyboardService" to true))
    verify(ThreatFamilyAnalyzer.metadata(metadata) == setOf("networkPermission", "cameraPermission", "keyboardService"))
    fun dex(strings: List<String>): ByteArray {
        val body = ByteArrayOutputStream(); val offsets = mutableListOf<Int>()
        strings.forEach { value ->
            offsets.add(112 + strings.size * 4 + body.size())
            val bytes = value.toByteArray(); check(bytes.size < 128)
            body.write(bytes.size); body.write(bytes); body.write(0)
        }
        val bytes = ByteArray(112 + strings.size * 4) + body.toByteArray()
        "dex\n035\u0000".toByteArray().copyInto(bytes)
        val buffer = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        buffer.putInt(32, bytes.size); buffer.putInt(36, 112); buffer.putInt(40, 0x12345678)
        buffer.putInt(56, strings.size); buffer.putInt(60, 112)
        offsets.forEachIndexed { index, offset -> buffer.putInt(112 + index * 4, offset) }
        return bytes
    }
    val strings = listOf("Ljavax/crypto/Cipher;", "Ljava/io/FileOutputStream;", "listFiles", "your files are encrypted")
    verify(ThreatFamilyAnalyzer.dexEvidence(dex(strings)) == ransomware - setOf("broadStoragePermission", "declaredService"))
    verify(ThreatFamilyAnalyzer.dexEvidence(dex(emptyList()) + "your files are encrypted".toByteArray()).orEmpty().isEmpty())
    verify(ThreatFamilyAnalyzer.dexEvidence(ByteArray(3)) == null)
    val broken = dex(strings); ByteBuffer.wrap(broken).order(ByteOrder.LITTLE_ENDIAN).putInt(112, Int.MAX_VALUE)
    verify(ThreatFamilyAnalyzer.dexEvidence(broken) == null)
    val directory = java.nio.file.Files.createTempDirectory("family-fixture").toFile()
    try {
        val archive = ByteArrayOutputStream().apply { ZipOutputStream(this).use { out ->
            out.putNextEntry(ZipEntry("AndroidManifest.xml")); out.write(byteArrayOf(1)); out.closeEntry()
            out.putNextEntry(ZipEntry("classes.dex")); out.write(dex(strings)); out.closeEntry()
        } }.toByteArray()
        val report = FileAnalyzer(directory, readApk = { ApkMetadata("synthetic.fixture", setOf("android.permission.MANAGE_EXTERNAL_STORAGE"), false,
            listOf("a".repeat(64)), mapOf("familyMetadataChecked" to true, "declaredService" to true, "signatureStatus" to "signatureVerified")) })
            .inspect("benign-synthetic.apk") { archive.inputStream() }
        verify((report["findings"] as Map<*, *>)["familyRansomware"] == 70)
        verify((report["findings"] as Map<*, *>).keys.none { it.toString().startsWith("sx") })
        verify(ApkRiskPolicy.assess(report).risk == "strongSuspicion")
        var launches = 0
        val result = AutomaticBlockEngine.decide(ApkRiskPolicy.assess(report), true, true, false)
        verify(!AutomaticBlockEngine.forward(result, true) { launches++ } && launches == 0)
        verify(!AutomaticBlockEngine.decide(ApkRiskPolicy.assess(report), true, false, false).blocked)
        val downgraded = ApkDiscoveryCoordinator.decorate(report + mapOf("complete" to false), "fixture.apk")
        verify(!( (downgraded["details"] as Map<*, *>)["threatFamilies"] as List<*>).filterIsInstance<Map<*, *>>().any { it["complete"] == true })
    } finally { directory.listFiles()?.forEach { it.delete() }; directory.delete() }
    println("$checks threat-family checks passed (synthetic references and mocked APK metadata; no malware executed).")
}
