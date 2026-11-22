package uz.app.shieldguard

import java.io.File
import java.util.zip.ZipFile

internal object SplitApkAnalyzer {
    fun inspect(zip: ZipFile, directory: File, readApk: (File) -> ApkMetadata?,
        checkpoint: () -> Unit): Map<String, Int> {
        val findings = linkedMapOf<String, Int>()
        val components = zip.entries().asSequence().filter { it.name.endsWith(".apk", true) }.take(9).toList()
        if (components.isEmpty()) return findings
        if (components.size > 8 || components.any { it.size !in 1..8L*1024*1024 }) {
            findings["contentLimit"] = 0
            return findings
        }
        var identity: Pair<String, Set<String>>? = null
        for (entry in components) {
            checkpoint()
            val temp = File.createTempFile("component-", ".apk", directory)
            try {
                zip.getInputStream(entry).use { source ->
                    temp.outputStream().use { output ->
                        val buffer = ByteArray(8192)
                        var total = 0
                        while (true) {
                            checkpoint()
                            val count = source.read(buffer)
                            if (count < 0) break
                            total += count
                            if (total > 8 * 1024 * 1024) { findings["contentLimit"] = 0; return findings }
                            output.write(buffer, 0, count)
                        }
                    }
                }
                val info = readApk(temp)
                if (info == null || info.details["signatureStatus"] != "signatureVerified" || info.signers.isEmpty()) {
                    findings["splitUnchecked"] = 0
                    continue
                }
                val current = info.packageName to info.signers.toSet()
                if (identity != null && identity != current) findings["splitMismatch"] = 35
                identity = current
            } finally {
                temp.delete()
            }
        }
        return findings
    }
}
