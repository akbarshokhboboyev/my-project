package uz.app.shieldguard

internal data class ScanLimits(
    val maxFileBytes: Long = 256L * 1024 * 1024,
    val maxArchiveBytes: Long = 32L * 1024 * 1024,
    val maxEntries: Int = 4096,
    val maxExpandedBytes: Long = 256L * 1024 * 1024,
    val maxMillis: Long = 30_000
) {
    init {
        require(maxFileBytes > 0 && maxArchiveBytes > 0 && maxEntries > 0 &&
            maxExpandedBytes > 0 && maxMillis > 0)
    }
}

internal object ApkSnapshotBudget {
    const val maxFileBytes = 256L * 1024 * 1024
    const val maxCacheBytes = 512L * 1024 * 1024
    fun fits(existingBytes: Long, incomingBytes: Long) = incomingBytes in 0..maxFileBytes &&
        existingBytes >= 0 && existingBytes <= maxCacheBytes - incomingBytes
}
internal class ScanStopped(val code: String) : RuntimeException()
