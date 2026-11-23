package uz.app.shieldguard

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.nio.file.Files
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

fun main() {
    val directory = Files.createTempDirectory("apk-read-budget-").toFile()
    var checks = 0
    fun verify(value: Boolean) { check(value); checks++ }
    fun zip(name: String): ByteArray = ByteArrayOutputStream().also { output ->
        ZipOutputStream(output).use { zip ->
            zip.putNextEntry(ZipEntry(name)); zip.write("benign fixture".toByteArray()); zip.closeEntry()
        }
    }.toByteArray()
    try {
        var metadataReads = 0
        val analyzer = FileAnalyzer(directory, ScanLimits(maxArchiveBytes = 32), readApk = {
            metadataReads++
            ApkMetadata("benign.fixture", emptySet(), false, listOf("mocked signer"),
                mapOf("signatureStatus" to "signatureVerified", "familyMetadataChecked" to true))
        })
        fun inspect(name: String, bytes: ByteArray) = analyzer.inspect(name) { ByteArrayInputStream(bytes) }
        val apk = zip("AndroidManifest.xml")
        verify(apk.size > 32)
        val report = inspect("fixture.apk", apk)
        verify((report["format"] as String).startsWith("APK"))
        verify(report["complete"] == true && report["signatureChecked"] == true)
        verify(metadataReads == 1)
        verify((report["findings"] as Map<*, *>).keys.none { it in setOf("mismatch", "archiveLimit") })
        verify(ApkRiskPolicy.assess(report).risk == "noFindings")
        verify((report["details"] as Map<*, *>)["scannedBytes"] == apk.size.toLong())
        val generic = inspect("fixture.apk", zip("plain.txt"))
        verify(generic["format"] == "ZIP" && generic["complete"] == false)
        verify("archiveLimit" in generic["findings"] as Map<*, *>)
        verify("mismatch" !in generic["findings"] as Map<*, *>)
        verify(metadataReads == 1)
        val disguised = inspect("document.pdf.apk", "%PDF-1.7 %%EOF".toByteArray())
        verify(disguised["format"] == "PDF")
        verify((disguised["findings"] as Map<*, *>).keys.containsAll(listOf("mismatch", "doubleExtension")))
        val notApk = ApkDiscoveryCoordinator.unavailable(disguised)
        verify("apkNotActualFormat" in notApk["findings"] as Map<*, *>)
        verify("apkUnavailableSnapshot" !in notApk["findings"] as Map<*, *>)
        val unavailable = ApkDiscoveryCoordinator.unavailable(report)
        verify("apkUnavailableSnapshot" in unavailable["findings"] as Map<*, *>)
        verify(unavailable["complete"] == false && ApkRiskPolicy.assess(unavailable).risk == "unknown")
        val nativeZip = ByteArrayOutputStream()
        ZipOutputStream(nativeZip).use { z ->
            z.putNextEntry(ZipEntry("AndroidManifest.xml")); z.write("benign".toByteArray()); z.closeEntry()
            z.putNextEntry(ZipEntry("lib/arm64-v8a/fixture.so"))
            val elf = ByteArray(64); byteArrayOf(127, 69, 76, 70, 2, 1).copyInto(elf)
            z.write(elf); z.closeEntry()
        }
        val nativeReport = inspect("fixture.apk", nativeZip.toByteArray())
        verify("apkNativeCoverage" in nativeReport["findings"] as Map<*, *>)
        verify(ApkRiskPolicy.assess(nativeReport).risk == "unknown")
        val limited = FileAnalyzer(directory, ScanLimits(maxEntries = 1), readApk = { error("Must not parse over limit") })
        val out = ByteArrayOutputStream()
        ZipOutputStream(out).use { z ->
            for (name in listOf("AndroidManifest.xml", "extra")) { z.putNextEntry(ZipEntry(name)); z.closeEntry() }
        }
        val capped = limited.inspect("fixture.apk") { ByteArrayInputStream(out.toByteArray()) }
        verify(capped["complete"] == false && "archiveLimit" in capped["findings"] as Map<*, *>)
        verify("mismatch" !in capped["findings"] as Map<*, *>)
        verify(ApkSnapshotBudget.fits(0, 33L * 1024 * 1024))
        verify(ApkSnapshotBudget.fits(ApkSnapshotBudget.maxFileBytes, ApkSnapshotBudget.maxFileBytes))
        verify(!ApkSnapshotBudget.fits(ApkSnapshotBudget.maxCacheBytes, 1))
        verify(!ApkSnapshotBudget.fits(0, ApkSnapshotBudget.maxFileBytes + 1))
        verify(!ApkSnapshotBudget.fits(-1, 1) && !ApkSnapshotBudget.fits(0, -1))
        verify(!ApkSnapshotBudget.fits(Long.MAX_VALUE, Long.MAX_VALUE))
        verify(directory.list().orEmpty().isEmpty())
        println("$checks APK read/snapshot budget checks passed.")
    } finally { directory.deleteRecursively() }
}
