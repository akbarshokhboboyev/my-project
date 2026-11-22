package uz.app.shieldguard

import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.content.ComponentName
import android.content.Context

// Same JobScheduler pattern as ScanScheduler; separate IDs keep installed-app work independent.
internal object FolderScanScheduler {
    const val periodicId = 7201
    const val manualId = 7202
    private fun jobs(context: Context) = context.getSystemService(JobScheduler::class.java)
    fun ensure(context: Context) {
        if (jobs(context).getPendingJob(periodicId) != null) return
        val result = jobs(context).schedule(JobInfo.Builder(periodicId,
            ComponentName(context, FolderScanJobService::class.java)).setPeriodic(15 * 60 * 1000L)
            .setPersisted(true).setRequiresBatteryNotLow(true).build())
        if (result != JobScheduler.RESULT_SUCCESS)
            AuthorizedFolderMonitor.store(context).edit().putString("state", "scheduleFailed").apply()
    }
    fun manual(context: Context) = synchronized(AuthorizedFolderMonitor.lock) {
        if (!AuthorizedFolderMonitor.validate(context)) throw SecurityException("folderPermission")
        if (AuthorizedFolderMonitor.rows(context).isEmpty()) throw IllegalArgumentException("folderEmpty")
        if (jobs(context).getPendingJob(manualId) == null) {
            val result = jobs(context).schedule(JobInfo.Builder(manualId,
                ComponentName(context, FolderScanJobService::class.java))
                .setMinimumLatency(1000).setRequiresBatteryNotLow(true).build())
            AuthorizedFolderMonitor.store(context).edit()
                .putString("state", if (result == JobScheduler.RESULT_SUCCESS) "queued" else "scheduleFailed").apply()
        }
    }
    fun cancel(context: Context) {
        jobs(context).cancel(periodicId)
        jobs(context).cancel(manualId)
    }
    fun scheduled(context: Context) = jobs(context).getPendingJob(periodicId) != null
}
