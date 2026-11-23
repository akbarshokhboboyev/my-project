package uz.app.shieldguard

import java.util.zip.ZipFile
import java.util.zip.CRC32

/** Bounded reference inspection. API references do not establish execution. */
internal object ApkContentInspector {
    fun inspect(zip: ZipFile, findings: MutableMap<String, Int>, checkpoint: () -> Unit) {
        var budget = 16L * 1024 * 1024
        val names = HashSet<String>()
        for (entry in zip.entries()) {
            checkpoint()
            if (!names.add(entry.name)) findings["archiveDuplicate"] = 20
            val dex = Regex("classes\\d*\\.dex").matches(entry.name)
            val elf = entry.name.startsWith("lib/") && entry.name.endsWith(".so")
            if (!dex && !elf) continue
            if (entry.size !in 0..minOf(8L * 1024 * 1024, budget)) {
                findings["contentLimit"] = 0
                continue
            }
            val bytes = zip.getInputStream(entry).use { source ->
                val output = java.io.ByteArrayOutputStream()
                val buffer = ByteArray(8192)
                var remaining = minOf(8L * 1024 * 1024, budget)
                while (true) {
                    checkpoint()
                    val count = source.read(buffer)
                    if (count < 0) break
                    if (count > remaining) {
                        findings["contentLimit"] = 0
                        return
                    }
                    remaining -= count
                    output.write(buffer, 0, count)
                }
                output.toByteArray()
            }
            budget -= bytes.size
            if (CRC32().apply { update(bytes) }.value != entry.crc) findings["structure"] = 30
            if (dex) inspectDex(bytes, findings) else { inspectElf(bytes, findings); findings["sxNativeOpaque"] = 0 }
        }
        if (zip.getEntry("AndroidManifest.xml") != null) findings["sxCodeChecked"] = 0
    }

    fun inspectDex(bytes: ByteArray, findings: MutableMap<String, Int>) {
        if (bytes.size < 112 || !bytes.copyOfRange(0, 4).contentEquals(byteArrayOf(100,101,120,10))) {
            findings["dexMalformed"] = 20
            return
        }
        val data = java.nio.ByteBuffer.wrap(bytes).order(java.nio.ByteOrder.LITTLE_ENDIAN)
        if (data.getInt(32) != bytes.size || data.getInt(36) != 112 || data.getInt(40) != 0x12345678) {
            findings["dexMalformed"] = 20
            return
        }
        val count = data.getInt(56)
        val offset = data.getInt(60)
        if (count < 0 || offset < 0 || offset.toLong() + count.toLong() * 4 > bytes.size) {
            findings["dexMalformed"] = 20
            return
        }
        val text = String(bytes, Charsets.ISO_8859_1)
        if ("Ldalvik/system/DexClassLoader;" in text || "Ldalvik/system/InMemoryDexClassLoader;" in text)
            findings["dexDynamic"] = 15
        if ("Landroid/content/pm/PackageInstaller;" in text) findings["dexInstaller"] = 10
        if ("Landroid/accessibilityservice/AccessibilityService;" in text) findings["dexAccessibility"] = 15
        if ("Landroid/service/notification/NotificationListenerService;" in text) findings["dexNotification"] = 10
        val evidence = ThreatFamilyAnalyzer.dexEvidence(bytes)
        if (evidence == null) findings["sxIncomplete"] = 0
        else evidence.forEach { findings["sx$it"] = 0 }
    }

    fun inspectElf(bytes: ByteArray, findings: MutableMap<String, Int>) {
        if (bytes.size < 52 || !bytes.copyOfRange(0,4).contentEquals(byteArrayOf(127,69,76,70)) ||
            bytes[4].toInt() !in 1..2 || bytes[5].toInt() !in 1..2) {
            findings["elfMalformed"] = 20
            return
        }
        val wide = bytes[4].toInt() == 2
        if (wide && bytes.size < 64) { findings["elfMalformed"] = 20; return }
        val data = java.nio.ByteBuffer.wrap(bytes).order(
            if (bytes[5].toInt() == 1) java.nio.ByteOrder.LITTLE_ENDIAN else java.nio.ByteOrder.BIG_ENDIAN)
        val offset = if (wide) data.getLong(40) else data.getInt(32).toLong() and 0xffffffffL
        val size = data.getShort(if (wide) 58 else 46).toInt() and 65535
        val count = data.getShort(if (wide) 60 else 48).toInt() and 65535
        if (offset < 0 || offset > bytes.size || size.toLong() * count > bytes.size - offset)
            findings["elfMalformed"] = 20
    }
}
