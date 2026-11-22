package uz.app.shieldguard

fun main() {
    val cases = mapOf(
        "Telegram tasdiqlash kodi yuboring" to "secret",
        "Please send the verification code" to "secret",
        "Пришлите код" to "secret",
        "Open https://telegram.example/premium" to "messageLink",
        "Enter password to claim your Premium gift" to "gift",
        "Install example.apk" to "install",
        "Urgent: send your password" to "urgent"
    )
    for ((sample, signal) in cases) {
        check(signal in NotificationAnalyzer.inspect(sample)) { "Missing signal: $signal" }
    }
    for (sample in listOf(
        "Never share your password",
        "Tasdiqlash kodi hech kimga yubormang",
        "Никому не сообщайте код",
        "https://t.me/premium",
        "Premium is available"
    )) {
        check(NotificationAnalyzer.inspect(sample).isEmpty()) { "Unexpected signal: $sample" }
    }
    println("12 native notification rule checks passed.")
}
