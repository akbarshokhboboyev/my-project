package uz.app.shieldguard

internal data class ScanLimits(
    val maxFileBytes: Long = 128L * 1024 * 1024,
    val maxArchiveBytes: Long = 32L * 1024 * 1024,
    val maxEntries: Int = 4096,
    val maxExpandedBytes: Long = 256L * 1024 * 1024,
    val maxMillis: Long = 15_000
) {
    init {
        require(maxFileBytes > 0 && maxArchiveBytes > 0 && maxEntries > 0 &&
            maxExpandedBytes > 0 && maxMillis > 0)
    }
}
internal class ScanStopped(val code: String) : RuntimeException()
