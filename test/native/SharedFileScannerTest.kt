package uz.app.shieldguard

import java.io.ByteArrayInputStream
import java.io.FileNotFoundException
import java.nio.file.Files
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import java.io.ByteArrayOutputStream

fun main() {
    val directory = Files.createTempDirectory("shared-fixture").toFile()
    var count = 0
    var reads = 0
    fun verify(value: Boolean) { check(value); count++ }
    val pdf = "%PDF-1.4\nbenign fixture\n%%EOF".toByteArray()
    val apk = ByteArrayOutputStream().also { output ->
        ZipOutputStream(output).use { zip ->
            zip.putNextEntry(ZipEntry("AndroidManifest.xml")); zip.write(byteArrayOf(1)); zip.closeEntry()
        }
    }.toByteArray()
    fun metadata() =
        ApkMetadata("uz.app.synthetic", emptySet(), false, listOf("fixture-only"),
            mapOf("signatureStatus" to "signatureVerified"))
    val scanner = SharedFileScanner({ it != "content://fixtures/denied" }, { raw, cancelled ->
        reads++
        if (raw.endsWith("/missing")) throw FileNotFoundException()
        if (raw.endsWith("/exception")) throw SecurityException()
        val bytes = when {
            raw.endsWith(".apk") -> apk
            raw.endsWith(".zip") -> byteArrayOf(80, 75, 3, 4, 1, 2)
            raw.endsWith(".txt") -> "Harmless document".toByteArray()
            else -> pdf
        }
        // Actual existing parser, with mock package metadata only for the synthetic JVM APK.
        FileAnalyzer(directory, cancelled = cancelled, readApk = { metadata() })
            .inspect(raw.substringAfterLast('/')) { ByteArrayInputStream(bytes) }
    })
    fun scan(vararg names: String, granted: Boolean = true): List<Map<*, *>> =
        (scanner.scan(SharedFileRequest(names.toList(), granted)) { false }["batch"] as List<*>).map { it as Map<*, *> }
    try {
        val single = scan("content://fixtures/benign.pdf").single()
        verify(single["format"] == "PDF")
        verify((single["findings"] as Map<*, *>).values.sumOf { it as Int } == 0)
        verify(scan("content://fixtures/benign.apk").single()["signatureChecked"] == true)
        verify(scan("content://fixtures/benign.pdf", "content://fixtures/benign.apk").size == 2)
        reads = 0
        verify(scan("CONTENT://fixtures/benign.pdf", "content://fixtures/benign.pdf").size == 1)
        verify(reads == 1)
        for (raw in listOf("file:///private/a.pdf", "https://example.com/a.pdf", "content:///a.pdf",
            "content://fixtures/a b", "content://user@fixtures/a", "content://fixtures/a#part", "")) {
            verify("sharedInvalid" in (scan(raw).single()["findings"] as Map<*, *>))
        }
        reads = 0
        verify("filePermission" in (scan("content://fixtures/benign.pdf", granted = false).single()["findings"] as Map<*, *>))
        verify(reads == 0)
        verify("filePermission" in (scan("content://fixtures/denied").single()["findings"] as Map<*, *>))
        val mixed = scan("content://fixtures/exception", "content://fixtures/benign.pdf", "content://fixtures/missing")
        verify(mixed.size == 3)
        verify("filePermission" in (mixed[0]["findings"] as Map<*, *>))
        verify(mixed[1]["format"] == "PDF")
        verify("fileMissing" in (mixed[2]["findings"] as Map<*, *>))
        verify(scan("content://fixtures/unknown.txt").single()["complete"] == false)
        verify((scan("content://fixtures/unknown.txt").single()["findings"] as Map<*, *>).values.all { it == 0 })
        verify(scan("content://fixtures/malformed.zip").single()["complete"] == false)
        val cancelled = scanner.scan(SharedFileRequest(listOf("content://fixtures/a.pdf"), true)) { true }
        verify("scanCancelled" in (((cancelled["batch"] as List<*>).single() as Map<*, *>)["findings"] as Map<*, *>))
        var now = 0L
        val timeout = SharedFileScanner({ true }, { _, _ ->
            now = 61; mapOf("complete" to true, "findings" to emptyMap<String, Int>())
        }, { now }, maxMillis = 60)
        val timed = (timeout.scan(SharedFileRequest(listOf("content://fixtures/a"), true)) { false }["batch"] as List<*>).single() as Map<*, *>
        verify(timed["complete"] == false)
        verify("scanTimeout" in (timed["findings"] as Map<*, *>))
        var stop = false
        val during = SharedFileScanner({ true }, { _, _ ->
            stop = true; mapOf("complete" to true, "findings" to emptyMap<String, Int>())
        }).scan(SharedFileRequest(listOf("content://fixtures/a", "content://fixtures/b"), true)) { stop }
        verify((during["batch"] as List<*>).size == 1)
        val overflow = scanner.scan(SharedFileRequest((1..9).map { "content://fixtures/$it.pdf" }, true)) { false }
        verify((overflow["batch"] as List<*>).size == 9)
        verify("contentLimit" in (((overflow["batch"] as List<*>).last() as Map<*, *>)["findings"] as Map<*, *>))
        val small = FileAnalyzer(directory, ScanLimits(maxFileBytes = 8), readApk = { null })
            .inspect("large.txt") { ByteArrayInputStream(ByteArray(9)) }
        verify("tooLarge" in (small["findings"] as Map<*, *>))
        verify(directory.list().orEmpty().isEmpty())
        println("$count shared-file scanner checks passed.")
    } finally { directory.deleteRecursively() }
}
