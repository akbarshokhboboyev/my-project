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
        val pngOut = ByteArrayOutputStream()
        val pngData = java.io.DataOutputStream(pngOut)
        pngData.write(byteArrayOf(-119, 80, 78, 71, 13, 10, 26, 10))
        fun chunk(type: String, bytes: ByteArray) {
            val crc = java.util.zip.CRC32()
            crc.update(type.toByteArray()); crc.update(bytes)
            pngData.writeInt(bytes.size); pngData.writeBytes(type); pngData.write(bytes)
            pngData.writeInt(crc.value.toInt())
        }
        chunk("IHDR", byteArrayOf(0,0,0,1,0,0,0,1,8,2,0,0,0))
        val compressed = ByteArrayOutputStream()
        java.util.zip.DeflaterOutputStream(compressed).use { it.write(byteArrayOf(0,0,0,0)) }
        chunk("IDAT", compressed.toByteArray())
        chunk("IEND", byteArrayOf())
        val png = pngOut.toByteArray()
        check("structure" !in flags("valid.png", png))
        png[png.lastIndex] = (png.last().toInt() xor 1).toByte()
        check("structure" in flags("invalid.png", png))
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
        println("16 advanced checks and 129 malformed input checks passed.")
    } finally {
        directory.deleteRecursively()
    }
}
