package uz.app.shieldguard

internal object NotificationAnalyzer {
    val weights = mapOf("secret" to 55, "gift" to 22, "messageLink" to 50, "install" to 30, "urgent" to 23)
    private val request = Regex("yubor|kiriting|bering|send|enter|share|provide|отправ|введ|пришл|сообщ")
    private val secret = Regex("tasdiqlash kodi|parol|sms.kod|otp|verification code|password|код|парол")
    private val warning = Regex("hech kimga|yubormang|bermang|do not share|never share|никому|не сообщ")
    private val url = Regex("""https?://[^\s<>"«»]+""")
    private val brand = Regex("""telegram|te1egram|teiegram|teleqram|(?:^|\.)t\.me\.""")
    private val lure = Regex("login|verify|premium|gift|bonus|password|signin")
    private val urgent = Regex("zudlik|bloklan|darhol|urgent|suspend|blocked|срочно|блокир")
    private val install = Regex("install|o.rnat|установ")
    private val gift = Regex("premium|sovg.a|gift|подар")

    fun inspect(input: String): Map<String, Int> {
        val text = input.lowercase()
        val links = url.findAll(text).take(24).map { it.value.trimEnd('.', ',', ')', '!', ';') }.toList()
        val requestsSecret = text.split(Regex("""[\n.!?;]+""")).any {
            request.containsMatchIn(it) && secret.containsMatchIn(it) && !warning.containsMatchIn(it)
        }
        val suspicious = links.any { raw ->
            val parsed = runCatching { java.net.URI(raw) }.getOrNull()
            val host = parsed?.host?.trimEnd('.') ?: return@any false
            val official = listOf("t.me", "telegram.org", "telegram.me").any { host == it || host.endsWith(".$it") }
            (!official && brand.containsMatchIn(host) && lure.containsMatchIn(raw)) ||
                !parsed.userInfo.isNullOrEmpty() && lure.containsMatchIn(raw)
        }
        val codes = buildList {
            if (requestsSecret) add("secret")
            if (suspicious) add("messageLink")
            if ((requestsSecret || suspicious) && gift.containsMatchIn(text)) add("gift")
            if (urgent.containsMatchIn(text) && (request.containsMatchIn(text) || links.isNotEmpty())) add("urgent")
            if (install.containsMatchIn(text) && (links.isNotEmpty() || ".apk" in text)) add("install")
        }
        return codes.associateWith { weights.getValue(it) }
    }
}
