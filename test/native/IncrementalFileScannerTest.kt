package uz.app.shieldguard

fun main() {
    var checks = 0
    fun verify(value: Boolean) { check(value); checks++ }
    val root = FolderDocument("root", "content://fixture/root", true)
    val pdf = FolderDocument("pdf", "content://fixture/new.pdf", false, 10, 100)
    val zip = FolderDocument("zip", "content://fixture/changed.zip", false, 20, 200)
    val apk = FolderDocument("apk", "content://fixture/benign.apk", false, 30, 300)
    var time = 1000L
    var reads = 0
    fun report() = mapOf<String, Any>("complete" to true, "hash" to "a".repeat(64), "findings" to emptyMap<String, Int>())
    fun engine(children: Map<String, List<FolderDocument>>, inspect: (FolderDocument, () -> Boolean) -> Map<String, Any> = { _, _ -> reads++; report() }) =
        IncrementalFileScanner({ parent, budget, emit ->
            val rows = children[parent.key].orEmpty()
            rows.take(budget).forEach(emit)
            rows.size > budget
        }, inspect, clock = { 0 }, now = { time })
    val scanner = engine(mapOf("root" to listOf(pdf, zip, apk)))
    val first = scanner.scan(listOf(root), emptyMap()) { false }
    verify(first.scanned == 3)
    verify(first.visited == 3)
    verify(!first.partial && first.unverified == 0)
    verify(first.indicators.isEmpty())
    verify(first.records["pdf"]?.hash == "a".repeat(64))
    reads = 0
    val same = scanner.scan(listOf(root), first.records) { false }
    verify(same.scanned == 0 && same.cached == 3 && reads == 0)
    val changed = engine(mapOf("root" to listOf(zip.copy(modified = 21))))
        .scan(listOf(root), first.records) { false }
    verify(changed.scanned == 1)
    val dedup = engine(mapOf("root" to listOf(pdf, pdf.copy(uri = "content://fixture/alias.pdf"))))
        .scan(listOf(root), emptyMap()) { false }
    verify(dedup.scanned == 1)
    val empty = engine(emptyMap()).scan(listOf(root), emptyMap()) { false }
    verify(empty.visited == 0 && empty.scanned == 0 && !empty.partial)
    val many = (1..300).map { FolderDocument("f$it", "content://fixture/$it", false, 1, 1) }
    val limited = engine(mapOf("root" to many)).scan(listOf(root), emptyMap()) { false }
    verify(limited.visited == 256)
    verify(limited.scanned == 8)
    verify(limited.partial && limited.unverified >= 248)
    verify(limited.records.size <= 256)
    val next = engine(mapOf("root" to many)).scan(listOf(root), limited.records) { false }
    verify(next.scanned == 8 && next.cached == 8)
    val d1 = root.copy(key = "d1"); val d2 = root.copy(key = "d2"); val d3 = root.copy(key = "d3")
    val nested = engine(mapOf("root" to listOf(d1), "d1" to listOf(d2),
        "d2" to listOf(pdf, d3), "d3" to listOf(apk)))
        .scan(listOf(root), emptyMap()) { false }
    verify(nested.scanned == 1 && nested.partial)
    verify(nested.visited == 4)
    val cycle = engine(mapOf("root" to listOf(root))).scan(listOf(root), emptyMap()) { false }
    verify(cycle.visited == 1)
    val denied = IncrementalFileScanner({ _, _, _ -> throw SecurityException() }, { _, _ -> report() })
        .scan(listOf(root), emptyMap()) { false }
    verify(denied.denied && denied.partial && denied.scanned == 0)
    val providerError = IncrementalFileScanner({ _, _, _ -> throw IllegalStateException() }, { _, _ -> report() })
        .scan(listOf(root), emptyMap()) { false }
    verify(providerError.partial && providerError.unverified > 0)
    val disabled = scanner.scan(listOf(root), first.records, authorized = false) { false }
    verify(disabled.scanned == 0 && disabled.partial)
    val cancelled = scanner.scan(listOf(root), first.records) { true }
    verify(cancelled.scanned == 0 && cancelled.partial)
    var stop = false
    val during = engine(mapOf("root" to listOf(pdf, zip))) { _, _ -> stop = true; report() }
        .scan(listOf(root), emptyMap()) { stop }
    verify(during.scanned == 1 && during.partial)
    verify(during.records["pdf"]?.complete == false)
    val unknown = engine(mapOf("root" to listOf(pdf))) { _, _ ->
        mapOf("complete" to false, "findings" to mapOf("unknown" to 0))
    }.scan(listOf(root), emptyMap()) { false }
    verify(unknown.unverified == 1 && unknown.partial && unknown.indicators.isEmpty())
    val cachedUnknown = engine(mapOf("root" to listOf(pdf))).scan(listOf(root), unknown.records) { false }
    verify(cachedUnknown.cached == 1 && cachedUnknown.unverified == 1 && cachedUnknown.partial)
    val weak = pdf.copy(modified = null, size = null)
    val weakFirst = engine(mapOf("root" to listOf(weak))).scan(listOf(root), emptyMap()) { false }
    verify(engine(mapOf("root" to listOf(weak))).scan(listOf(root), weakFirst.records) { false }.scanned == 1)
    time += 3_600_001
    verify(scanner.scan(listOf(root), first.records) { false }.scanned == 3)
    time = 10
    verify(scanner.scan(listOf(root), first.records) { false }.scanned == 3)
    val perFile = engine(mapOf("root" to listOf(pdf, zip))) { doc, _ ->
        if (doc.key == "pdf") throw SecurityException() else report()
    }.scan(listOf(root), emptyMap()) { false }
    verify(perFile.scanned == 2 && perFile.unverified == 1)
    var clock = 0L
    val timed = IncrementalFileScanner({ _, _, emit -> emit(pdf); false },
        { _, _ -> clock = 100; report() }, clock = { clock }, maxMillis = 50)
        .scan(listOf(root), emptyMap()) { false }
    verify(timed.partial && timed.records["pdf"]?.complete == false)
    println("$checks incremental folder scanner checks passed.")
}
