package uz.app.shieldguard

import java.io.File
import java.io.InputStream
import java.io.RandomAccessFile
import java.security.MessageDigest
import java.util.zip.ZipException
import java.util.zip.ZipFile

internal data class ApkMetadata(
    val packageName: String,
    val permissions: Set<String>,
    val accessibility: Boolean,
    val signers: List<String>,
    val details: Map<String, Any> = emptyMap(),
    val unprotectedExports: Boolean = false
)

internal class FileAnalyzer(
    private val directory: File,
    private val limits: ScanLimits = ScanLimits(),
    private val cancelled: () -> Boolean = { false },
    private val inspectPdf: ((File) -> Pair<Map<String, Int>, Boolean>)? = null,
    private val onAnalyzed: (File, Map<String, Any>) -> Map<String, Any> = { _, report -> report },
    private val readApk: (File) -> ApkMetadata?
) {
    fun inspect(displayName: String, open: () -> InputStream): Map<String, Any> {
        val started = System.nanoTime()
        fun checkpoint() {
            if (cancelled() || Thread.currentThread().isInterrupted) throw ScanStopped("scanCancelled")
            if ((System.nanoTime() - started) / 1_000_000 > limits.maxMillis) throw ScanStopped("scanTimeout")
        }
        val extension = displayName.lowercase()
        directory.mkdirs()
        val staleBefore = System.currentTimeMillis() - 24L * 60 * 60 * 1000
        directory.listFiles()?.forEach { file ->
            if (file.name.startsWith("scan-") && file.lastModified() < staleBefore) file.delete()
        }
        // PackageManager expects the archive to have an APK suffix.
        val temp = File.createTempFile("scan-", ".apk", directory)
        try {
            val digest = MessageDigest.getInstance("SHA-256")
            var size = 0L
            val pdfFindings = linkedMapOf<String, Int>()
            var overlap = ""
            open().buffered().use { source ->
                source.mark(5)
                val pdf = "%PDF-".all { source.read() == it.code }
                source.reset()
                temp.outputStream().use { output ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        checkpoint()
                        val count = source.read(buffer)
                        if (count < 0) break
                        size += count
                        if (size > limits.maxFileBytes) return result("tooLarge")
                        if (pdf) {
                            val chunk = overlap + String(buffer, 0, count, Charsets.ISO_8859_1)
                            if (pdfAction.containsMatchIn(chunk)) pdfFindings["pdfAction"] = 25
                            if (pdfEmbedded.containsMatchIn(chunk)) pdfFindings["pdfEmbedded"] = 20
                            if (Regex("/URI\\b").containsMatchIn(chunk)) pdfFindings["pdfUri"] = 10
                            overlap = chunk.takeLast(64)
                        }
                        digest.update(buffer, 0, count)
                        output.write(buffer, 0, count)
                    }
                }
            }
            val findings = linkedMapOf<String, Int>()
            var complete = true
            var details = emptyMap<String, Any>()
            val format = RandomAccessFile(temp, "r").use { file ->
                val header = ByteArray(minOf(64L, size).toInt())
                file.readFully(header)
                fun starts(vararg bytes: Int) =
                    header.size >= bytes.size && bytes.indices.all { (header[it].toInt() and 255) == bytes[it] }
                fun tail(amount: Int): ByteArray {
                    val bytes = ByteArray(minOf(amount.toLong(), size).toInt())
                    file.seek(size - bytes.size)
                    file.readFully(bytes)
                    return bytes
                }
                when {
                    starts(77, 73, 68) -> {
                        complete = false
                        findings["unknownContainer"] = 0
                        "MID"
                    }
                    starts(0x25, 0x50, 0x44, 0x46, 0x2d) -> {
                        findings.putAll(pdfFindings)
                        if (!String(tail(2048), Charsets.ISO_8859_1).contains("%%EOF")) findings["structure"] = 30
                        inspectPdf?.invoke(temp)?.let { (parsed, parsedComplete) ->
                            findings.putAll(parsed)
                            if (!parsedComplete) complete = false
                        }
                        checkpoint()
                        "PDF"
                    }
                    starts(0xff, 0xd8, 0xff) -> {
                        if (!tail(2).contentEquals(byteArrayOf(-1, -39))) findings["structure"] = 30
                        "JPEG"
                    }
                    starts(137, 80, 78, 71, 13, 10, 26, 10) -> {
                        StructuralInspector.png(file, findings, ::checkpoint)
                        if (size < 45 || !String(tail(12), Charsets.ISO_8859_1).contains("IEND")) findings["structure"] = 30
                        "PNG"
                    }
                    starts(77, 90) -> {
                        val offset = if (header.size >= 64) java.nio.ByteBuffer.wrap(header)
                            .order(java.nio.ByteOrder.LITTLE_ENDIAN).getInt(60).toLong() else -1L
                        if (offset < 64 || offset > size - 4) findings["structure"] = 30
                        else {
                            file.seek(offset)
                            if (file.readInt() == 0x50450000) {
                                findings["executable"] = 50
                                details = StructuralInspector.pe(file, offset, findings)
                            }
                            else findings["structure"] = 30
                        }
                        if ("executable" in findings) "PE" else "MZ"
                    }
                    starts(80, 75, 3, 4) || starts(80, 75, 5, 6) -> {
                        val end = tail(65557)
                        var entries = -1
                        for (i in end.size - 22 downTo 0) {
                            if (end[i] == 80.toByte() && end[i+1] == 75.toByte() &&
                                end[i+2] == 5.toByte() && end[i+3] == 6.toByte()) {
                                entries = (end[i+10].toInt() and 255) or ((end[i+11].toInt() and 255) shl 8)
                                break
                            }
                        }
                        if (entries < 0) findings["structure"] = 30
                        if (entries > limits.maxEntries) findings["archiveLimit"] = 0
                        if (entries !in 0..limits.maxEntries || size > limits.maxArchiveBytes) {
                            if (size > limits.maxArchiveBytes) findings["archiveLimit"] = 0
                            complete = false
                            "ZIP"
                        } else try {
                            ZipFile(temp).use { zip ->
                                ApkContentInspector.inspect(zip, findings, ::checkpoint)
                                findings.putAll(SplitApkAnalyzer.inspect(zip, directory, readApk, ::checkpoint))
                                val enumeration = zip.entries()
                                var total = 0L
                                var count = 0
                                while (enumeration.hasMoreElements()) {
                                    checkpoint()
                                    val entry = enumeration.nextElement()
                                    val path = entry.name.replace('\\', '/')
                                    if (path.startsWith("/") || Regex("^[A-Za-z]:").containsMatchIn(path) ||
                                        path.split('/').contains("..")) findings["archivePath"] = 45
                                    if (Regex("(?i)\\.(zip|apk|jar|7z|rar)$").containsMatchIn(path)) {
                                        findings["archiveNested"] = 0
                                        complete = false
                                    }
                                    if (Regex("(?i)(vbaproject\\.bin|embeddings/.*\\.(exe|dll|js|vbs))").containsMatchIn(path))
                                        findings["archiveEmbedded"] = 30
                                    count++
                                    if (count > limits.maxEntries || entry.size !in 0..limits.maxExpandedBytes ||
                                        entry.size > limits.maxExpandedBytes - total ||
                                        (entry.size > 1024 * 1024 && entry.size / maxOf(1, entry.compressedSize) > 200)) {
                                        findings["archiveLimit"] = 0
                                        complete = false
                                        break
                                    }
                                    total += entry.size
                                }
                                when {
                                    zip.getEntry("AndroidManifest.xml") != null -> "APK"
                                    zip.getEntry("[Content_Types].xml") != null && zip.getEntry("word/document.xml") != null -> "DOCX"
                                    zip.getEntry("[Content_Types].xml") != null && zip.getEntry("xl/workbook.xml") != null -> "XLSX"
                                    else -> "ZIP"
                                }
                            }
                        } catch (_: ZipException) {
                            findings["structure"] = 30
                            complete = false
                            "ZIP"
                        }
                    }
                    else -> { complete = false; findings["unknown"] = 0; "" }
                }
            }
            val expected = mapOf("pdf" to "PDF", "jpg" to "JPEG", "jpeg" to "JPEG",
                "png" to "PNG", "apk" to "APK", "exe" to "PE", "zip" to "ZIP",
                "docx" to "DOCX", "xlsx" to "XLSX")
            val suffix = extension.substringAfterLast('.', "")
            if (format.isNotEmpty() && expected[suffix]?.let { it != format } == true) findings["mismatch"] = 55
            if (extension.any { it in '\u202a'..'\u202e' || it in '\u2066'..'\u2069' } ||
                Regex("""\.(pdf|jpg|jpeg|png|mp4|mp3|docx|xlsx|zip)\.(apk|exe|scr|bat|cmd|js)$""").containsMatchIn(extension)) {
                findings["doubleExtension"] = 45
            }
            var packageName: String? = null
            var familyMetadata: ApkMetadata? = null
            if ("contentLimit" in findings || "dexMalformed" in findings || "elfMalformed" in findings) complete = false
            var signerHashes = emptyList<String>()
            if (format == "APK" && "structure" !in findings && "archiveLimit" !in findings) {
                val info = readApk(temp)
                if (info == null) {
                    findings["apkUnreadable"] = 30
                    complete = false
                } else {
                    familyMetadata = info
                    packageName = info.packageName
                    signerHashes = info.signers
                    details = info.details
                    findings.putAll(ApkRiskAnalyzer.inspect(info))
                }
            }
            val report = buildMap<String, Any> {
                put("kind", "file")
                put("complete", complete && "structure" !in findings)
                put("findings", findings)
                put("hash", digest.digest().joinToString("") { "%02x".format(it) })
                put("signers", signerHashes)
                put("details", details)
                put("signatureChecked", details["signatureStatus"] in setOf("signatureVerified", "signatureFailed"))
                if (format.isNotEmpty()) put("format", listOfNotNull(format, packageName).joinToString(" · "))
            }
            val finalReport = if (format == "APK") {
                val static = findings.keys.filter { it.startsWith("sx") && it !in setOf("sxCodeChecked", "sxIncomplete", "sxNativeOpaque") }.map { it.removePrefix("sx") }.toSet() +
                    (familyMetadata?.let { ThreatFamilyAnalyzer.metadata(it) } ?: emptySet())
                val coverage = familyMetadata?.details?.get("familyMetadataChecked") == true &&
                    "sxCodeChecked" in findings && "sxIncomplete" !in findings && "sxNativeOpaque" !in findings
                ThreatFamilyAnalyzer.decorate(report + mapOf("details" to (details + mapOf("familyCoverage" to coverage))), static, coverage)
            } else report + mapOf("findings" to findings.filterKeys { !it.startsWith("sx") })
            return onAnalyzed(temp, finalReport)
        } catch (stop: ScanStopped) {
            return result(stop.code)
        } finally {
            temp.delete()
        }
    }

    private fun result(code: String) = mapOf("kind" to "file", "complete" to false,
        "findings" to mapOf(code to 0))

    companion object {
        private val pdfAction = Regex("""/(JavaScript|JS|Launch|OpenAction|AA)\b""")
        private val pdfEmbedded = Regex("""/(EmbeddedFile|EmbeddedFiles|Filespec)\b""")
        private val smsPermissions = setOf("android.permission.READ_SMS",
            "android.permission.RECEIVE_SMS", "android.permission.SEND_SMS")
    }
}
