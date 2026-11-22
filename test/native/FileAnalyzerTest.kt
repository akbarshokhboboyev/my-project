package uz.app.shieldguard

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.FileNotFoundException
import java.nio.file.Files
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

private fun archive(vararg names: String): ByteArray {
    val output = ByteArrayOutputStream()
    ZipOutputStream(output).use { zip ->
        for (name in names) {
            zip.putNextEntry(ZipEntry(name))
            zip.write("sample".toByteArray())
            zip.closeEntry()
        }
    }
    return output.toByteArray()
}

fun main() {
    val directory = Files.createTempDirectory("shieldguard-test-").toFile()
    try {
        val analyzer = FileAnalyzer(directory) {
            check(it.extension == "apk")
            ApkMetadata("example.fixture", setOf("android.permission.RECEIVE_SMS", "android.permission.INTERNET"),
                true, listOf("certificate-fixture"))
        }
        fun inspect(name: String, bytes: ByteArray) = analyzer.inspect(name) { ByteArrayInputStream(bytes) }
        fun finding(result: Map<String, Any>, key: String) = (result["findings"] as Map<*, *>).containsKey(key)

        val unknown = inspect("sample.dat", "abc".toByteArray())
        check(unknown["hash"] == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        check(unknown["complete"] == false && finding(unknown, "unknown"))
        val pdf = "%PDF-1.7 /OpenAction /EmbeddedFile %%EOF".toByteArray()
        val pdfResult = inspect("sample.pdf", pdf)
        check(pdfResult["format"] == "PDF" && finding(pdfResult, "pdfAction") && finding(pdfResult, "pdfEmbedded"))
        check(finding(inspect("sample.pdf", "%PDF-1.7".toByteArray()), "structure"))
        check(finding(inspect("sample.jpg", pdf), "mismatch"))
        check(finding(inspect("sample.pdf.exe", pdf), "doubleExtension"))

        val jpeg = byteArrayOf(-1, -40, -1, -32, -1, -39)
        check(inspect("sample.jpeg", jpeg)["format"] == "JPEG")
        check(finding(inspect("sample.jpeg", jpeg.copyOf(4)), "structure"))
        val png = ByteArray(45)
        byteArrayOf(-119, 80, 78, 71, 13, 10, 26, 10).copyInto(png)
        "IEND".toByteArray().copyInto(png, 37)
        check(inspect("sample.png", png)["format"] == "PNG")

        val pe = ByteArray(68)
        pe[0] = 77
        pe[1] = 90
        pe[60] = 64
        pe[64] = 80
        pe[65] = 69
        check(finding(inspect("sample.exe", pe), "executable"))
        check(inspect("sample.zip", archive("sample.txt"))["format"] == "ZIP")
        check(inspect("sample.docx", archive("[Content_Types].xml", "word/document.xml"))["format"] == "DOCX")
        check(inspect("sample.xlsx", archive("[Content_Types].xml", "xl/workbook.xml"))["format"] == "XLSX")
        check(finding(inspect("sample.zip", byteArrayOf(80, 75, 3, 4)), "structure"))

        val apk = inspect("sample.apk", archive("AndroidManifest.xml"))
        check(apk["format"] == "APK · example.fixture" && apk["signers"] == listOf("certificate-fixture"))
        check(finding(apk, "apkSms") && finding(apk, "apkAccess") && finding(apk, "apkCombo"))
        check(runCatching { analyzer.inspect("missing.pdf") { throw FileNotFoundException() } }
            .exceptionOrNull() is FileNotFoundException && directory.list().orEmpty().isEmpty())
        println("17 native file checks passed.")
    } finally {
        directory.deleteRecursively()
    }
}
