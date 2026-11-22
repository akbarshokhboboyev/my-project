package uz.app.shieldguard

fun main() {
    val directory = java.nio.file.Files.createTempDirectory("sg-split-test").toFile()
    try {
        val pdf = "%PDF-1.7 /OpenAction %%EOF".toByteArray()
        val parsed = FileAnalyzer(directory, inspectPdf = { mapOf("pdfParsed" to 0) to true }, readApk = { null })
            .inspect("fixture.pdf") { pdf.inputStream() }
        check(parsed["complete"] == true && "pdfParsed" in (parsed["findings"] as Map<*, *>))
        val incomplete = FileAnalyzer(directory, inspectPdf = { mapOf("pdfParseIncomplete" to 0) to false }, readApk = { null })
            .inspect("fixture.pdf") { pdf.inputStream() }
        check(incomplete["complete"] == false && "pdfAction" in (incomplete["findings"] as Map<*, *>))
        val archive = java.io.File(directory, "fixture.zip")
        java.util.zip.ZipOutputStream(archive.outputStream()).use { zip ->
            for (name in listOf("base.apk", "config.apk")) {
                zip.putNextEntry(java.util.zip.ZipEntry(name))
                zip.write(name.toByteArray())
                zip.closeEntry()
            }
        }
        val analyzer: (java.io.File) -> ApkMetadata? = { file ->
            ApkMetadata("example.fixture", emptySet(), false, listOf(file.readText()),
                mapOf("signatureStatus" to "signatureVerified"))
        }
        java.util.zip.ZipFile(archive).use { zip ->
            check("splitMismatch" in SplitApkAnalyzer.inspect(zip, directory, analyzer) {})
            check("splitUnchecked" in SplitApkAnalyzer.inspect(zip, directory, { null }) {})
            val matching: (java.io.File) -> ApkMetadata? = {
                ApkMetadata("example.fixture", emptySet(), false, listOf("fixture-cert"),
                    mapOf("signatureStatus" to "signatureVerified"))
            }
            check(SplitApkAnalyzer.inspect(zip, directory, matching) {}.isEmpty())
        }
    } finally { directory.deleteRecursively() }
    fun inspect(bytes: ByteArray, dex: Boolean): Map<String, Int> {
        val findings = linkedMapOf<String, Int>()
        if (dex) ApkContentInspector.inspectDex(bytes, findings)
        else ApkContentInspector.inspectElf(bytes, findings)
        return findings
    }
    check("dexMalformed" in inspect(byteArrayOf(), true))
    check("elfMalformed" in inspect(byteArrayOf(127,69,76,70), false))
    val api = "Ldalvik/system/DexClassLoader;".toByteArray()
    val dex = ByteArray(112 + api.size)
    byteArrayOf(100,101,120,10,48,51,53,0).copyInto(dex)
    val buffer = java.nio.ByteBuffer.wrap(dex).order(java.nio.ByteOrder.LITTLE_ENDIAN)
    buffer.putInt(32,dex.size); buffer.putInt(36,112); buffer.putInt(40,0x12345678)
    api.copyInto(dex,112)
    check("dexDynamic" in inspect(dex,true))
    buffer.putInt(56,Int.MAX_VALUE)
    check("dexMalformed" in inspect(dex,true))
    for (size in 0..128) {
        inspect(ByteArray(size), true)
        inspect(ByteArray(size), false)
    }
    println("9 V3 assertions and 258 malformed checks passed.")
}
