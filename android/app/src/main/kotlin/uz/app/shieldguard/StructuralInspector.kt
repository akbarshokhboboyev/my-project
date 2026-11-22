package uz.app.shieldguard

import java.io.RandomAccessFile
import java.util.zip.CRC32

internal object StructuralInspector {
    fun pe(file: RandomAccessFile, offset: Long, findings: MutableMap<String, Int>): Map<String, Any> {
        if (offset < 64 || offset > file.length() - 24) {
            findings["structure"] = 30
            return emptyMap()
        }
        file.seek(offset + 4)
        val machine = java.lang.Short.reverseBytes(file.readShort()).toInt() and 65535
        val sections = java.lang.Short.reverseBytes(file.readShort()).toInt() and 65535
        file.seek(offset + 20)
        val optionalSize = java.lang.Short.reverseBytes(file.readShort()).toInt() and 65535
        val table = offset + 24 + optionalSize
        if (sections !in 1..96 || table + sections * 40L > file.length()) {
            findings["structure"] = 30
            return mapOf("architecture" to machine, "sections" to sections)
        }
        repeat(sections) { index ->
            file.seek(table + index * 40 + 16)
            val bytes = java.lang.Integer.reverseBytes(file.readInt()).toLong() and 0xffffffffL
            val pointer = java.lang.Integer.reverseBytes(file.readInt()).toLong() and 0xffffffffL
            if (pointer > file.length() || bytes > file.length() - pointer) findings["structure"] = 30
        }
        return mapOf("architecture" to machine, "sections" to sections)
    }

    fun png(file: RandomAccessFile, findings: MutableMap<String, Int>, checkpoint: () -> Unit) {
        file.seek(8)
        var first = true
        var ended = false
        var count = 0
        val buffer = ByteArray(8192)
        while (file.filePointer <= file.length() - 12 && count++ < 10000) {
            checkpoint()
            val size = file.readInt().toLong() and 0xffffffffL
            val type = ByteArray(4).also(file::readFully)
            val name = String(type, Charsets.US_ASCII)
            if (size > file.length() - file.filePointer - 4 || (first && (name != "IHDR" || size != 13L))) {
                findings["structure"] = 30
                return
            }
            first = false
            val crc = CRC32().apply { update(type) }
            var remaining = size
            while (remaining > 0) {
                checkpoint()
                val amount = minOf(remaining, buffer.size.toLong()).toInt()
                file.readFully(buffer, 0, amount)
                crc.update(buffer, 0, amount)
                remaining -= amount
            }
            if (crc.value != (file.readInt().toLong() and 0xffffffffL)) findings["structure"] = 30
            if (name == "IEND") {
                ended = true
                if (size != 0L || file.filePointer != file.length()) findings["structure"] = 30
                break
            }
        }
        if (!ended) findings["structure"] = 30
    }
}
