package uz.app.shieldguard

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.nio.file.Files
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

fun main() {
    val directory = Files.createTempDirectory("shield-v2-tests").toFile()
    try {
        fun zip(name: String): ByteArray {
            val out = ByteArrayOutputStream()
            ZipOutputStream(out).use { it.putNextEntry(ZipEntry(name)); it.write("benign".toByteArray()); it.closeEntry() }
            return out.toByteArray()
        }
        val analyzer = FileAnalyzer(directory, readApk = { null })
        fun flags(name: String, bytes: ByteArray): Map<*, *> =
            analyzer.inspect(name) { ByteArrayInputStream(bytes) }["findings"] as Map<*, *>
        check("archivePath" in flags("sample.zip", zip("../sample.txt")))
        check("archivePath" in flags("sample.zip", zip("/sample.txt")))
        check("archiveNested" in flags("sample.zip", zip("nested.zip")))
        check("archiveEmbedded" in flags("sample.zip", zip("word/vbaProject.bin")))
        check("unknown" in flags("empty.dat", byteArrayOf()))
        check("pdfUri" in flags("sample.pdf", "%PDF-1.7 /URI (https://example.test) %%EOF".toByteArray()))
        val cancelled = FileAnalyzer(directory, cancelled = { true }, readApk = { null })
        check((cancelled.inspect("a.pdf") { ByteArrayInputStream(byteArrayOf(1)) }["findings"] as Map<*, *>).containsKey("scanCancelled"))
        val limited = FileAnalyzer(directory, ScanLimits(maxFileBytes = 8), readApk = { null })
        check((limited.inspect("a.dat") { ByteArrayInputStream(ByteArray(9)) }["findings"] as Map<*, *>).containsKey("tooLarge"))
        check(directory.list().orEmpty().isEmpty())
        for (size in 0..128) flags("malformed.zip", ByteArray(size) { (it * 17).toByte() })
        val gate = AlertGate()
        check(gate.allow("sample", 0))
        check(!gate.allow("different", 1000))
        check(!gate.allow("sample", 31_000))
        check(gate.allow("different", 31_000))
        check(gate.allow("sample", 301_000))
        println("14 advanced checks and 129 malformed input checks passed.")
    } finally {
        directory.deleteRecursively()
    }
}
