package uz.app.shieldguard

internal object NotificationAnalyzer {
    val weights = mapOf("secret" to 55, "gift" to 22, "messageLink" to 50, "install" to 30,
        "urgent" to 23, "support" to 20, "bot" to 20)
    private val clauses = Regex("""[\n.!?;,]+|(?:^|\s)(?:but|ammo|lekin|но|однако)(?=\s|$)""")
    private val request = Regex("""yubor|kiriting|bering|ayting|jo.nat|tasdiqlang|\b(?:send|enter|provide|share|submit)\b|введ|отправ|пришл|сообщ|подтверд|переда""")
    private val secret = Regex("""tasdiqlash kod|kirish kod|sms[ -]?kod|telegram kod|\bkodni\b|[4-8][ -]*(?:xonali|raqamli|digit)[ -]+(?:kod|code)|parol|\botp\b|(?:login|verification|confirmation|security) code|password|passcode|код|парол""")
    private val warning = Regex("""yubormang|bermang|aytmang|jo.natmang|kiritmang|o.rnatmang|(?:do not|don.t|never) (?:share|send|enter|provide|install)|не (?:сообщ|отправ|присыл|ввод|переда|делит|устанав)""")
    private val url = Regex("""(?:https?://|www\.)[^\s<>"«»]+|(?<![\p{L}\p{N}_@./-])(?:[\p{L}\p{N}](?:[\p{L}\p{N}-]{0,61}[\p{L}\p{N}])?\.)+(?:[\p{L}]{2,63}|xn--[a-z0-9-]{2,59})(?::\d{1,5})?(?:[/?#][^\s<>"«»]*)?""")
    private val domain = Regex("""^(?:[\p{L}\p{N}](?:[\p{L}\p{N}-]{0,61}[\p{L}\p{N}])?\.)+[\p{L}\p{N}-]{1,63}$""")
    private val brand = Regex("""telegram|te1egram|teiegram|teleqram|(?:^|\.)t\.me(?:[.-]|$)""")
    private val lure = Regex("login|verify|verification|confirm|premium|gift|bonus|password|signin")
    private val urgent = Regex("zudlik|bloklan|darhol|shoshil|urgent|suspend|blocked|срочно|блокир")
    private val install = Regex("install|o.rnat|установ")
    private val gift = Regex("premium|sovg.a|gift|подар")
    private val support = Regex("qo.llab.quvvatlash|texnik yordam|support|поддержк")
    private val bot = Regex("""\bbot\b|бот(?=$|[\s:,.!?])|@[a-z0-9_]{5,32}bot\b""")
    private val lookalikes = mapOf('а' to 'a', 'е' to 'e', 'г' to 'r', 'і' to 'i',
        'ӏ' to 'l', 'м' to 'm', 'о' to 'o', 'р' to 'p', 'т' to 't',
        'α' to 'a', 'ε' to 'e', 'τ' to 't')
    private val trusted = setOf("t.me", "telegram.org", "telegram.me")
    private val shorteners = setOf("bit.ly", "tinyurl.com", "t.co", "cutt.ly", "is.gd", "rb.gy")

    // Syntax inspection only: no DNS, URL fetches, or bot identity lookup.
    private fun linkScore(raw: String): Int {
        val parsed = runCatching { java.net.URI(if ("://" in raw) raw else "https://" + raw) }.getOrNull()
            ?: return 0
        if (parsed.scheme !in setOf("http", "https")) return 0
        val authority = parsed.authority ?: return 0
        val hostAndPort = authority.substringAfterLast('@')
        if (!hostAndPort.startsWith("[") && ':' in hostAndPort) {
            val port = hostAndPort.substringAfterLast(':').toIntOrNull() ?: return 0
            if (port !in 1..65535) return 0
        }
        val host = (parsed.host ?: hostAndPort.substringBefore(':'))
            .trimEnd('.').lowercase().removeSurrounding("[", "]")
        if (host.length > 253 || (!domain.matches(host) && ':' !in host)) return 0
        if (parsed.port != -1 && parsed.port !in 1..65535) return 0
        val official = trusted.any { host == it || host.endsWith("." + it) }
        val skeleton = host.map { lookalikes[it] ?: it }.joinToString("")
        val context = host + " " + parsed.path.orEmpty() + " " + parsed.query.orEmpty()
        var score = 0
        if (parsed.scheme == "http") score += 10
        if ('@' in authority) score += 35
        if (':' in host || Regex("""^\d+(?:\.\d+)+$""").matches(host)) score += 25
        if (host.split('.').any { it.startsWith("xn--") } || host.any { it.code > 127 }) score += 30
        if (host in shorteners) score += 25
        if (!official && brand.containsMatchIn(skeleton)) score += 45
        if (!official && lure.containsMatchIn(context)) score += 18
        return score
    }

    fun inspect(input: String): Map<String, Int> {
        val text = input.take(8192).lowercase()
        val scores = url.findAll(text).take(24)
            .map { linkScore(it.value.trimEnd('.', ',', ')', '}', '!', '?', ';', ':')) }.toList()
        val parts = text.split(clauses)
        val requestsSecret = parts.any {
            request.containsMatchIn(it) && secret.containsMatchIn(it) && !warning.containsMatchIn(it)
        }
        val suspicious = scores.any { it >= 45 }
        val requestsAction = parts.any { request.containsMatchIn(it) && !warning.containsMatchIn(it) }
        return buildMap {
            if (requestsSecret) put("secret", 55)
            if (suspicious) put("messageLink", 50)
            else if (scores.any { it >= 25 }) put("messageLink", 25)
            if ((requestsSecret || scores.any { it >= 25 }) && gift.containsMatchIn(text)) put("gift", 22)
            if (urgent.containsMatchIn(text) && (requestsAction || suspicious)) put("urgent", 23)
            if (support.containsMatchIn(text) && (requestsSecret || suspicious)) put("support", 20)
            if (bot.containsMatchIn(text) && (requestsSecret || suspicious)) put("bot", 20)
            if (parts.any { install.containsMatchIn(it) && !warning.containsMatchIn(it) } &&
                (scores.isNotEmpty() || ".apk" in text)) put("install", 30)
        }
    }
}
