package uz.app.shieldguard

import java.io.File

fun main(args: Array<String>) {
    val rows = File(args.single()).readLines(Charsets.UTF_8).filter { it.isNotBlank() && !it.startsWith("#") }
    for (row in rows) {
        val fields = row.split('\t')
        val expected = if (fields[1] == "-") emptySet() else fields[1].split(',').toSet()
        val actual = NotificationAnalyzer.inspect(fields[0])
        check(actual.keys == expected) { "Unexpected findings for " + fields[0] + ": " + actual }
        check(actual.values.sum().coerceAtMost(100) == fields[2].toInt()) { "Wrong score: " + fields[0] }
    }
    val gate = AlertGate()
    check(gate.allow("t.me-premium.uz", 0))
    check(!gate.allow("other", 29_999))
    check(gate.allow("other", 30_000))
    check(!gate.allow("t.me-premium.uz", 299_999))
    check(gate.allow("t.me-premium.uz", 300_000))
    check(NotificationAnalyzer.inspect(" ".repeat(8192) + "Send your login code").isEmpty())
    check(NotificationAnalyzer.inspect("t.me-premium.uz ".repeat(24)).values.sum() == 72)
    println(rows.size.toString() + " shared Telegram fixtures and 7 bound/cooldown checks passed.")
}
