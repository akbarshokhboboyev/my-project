package uz.app.shieldguard

import android.app.Instrumentation
import android.app.job.JobScheduler
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import org.json.JSONObject

// Uses only an explicitly selected, uniquely named SAF test folder. Never edits its contents.
class FolderMonitorInstrumentation : Instrumentation() {
    private var changes = false
    override fun onCreate(arguments: Bundle?) {
        super.onCreate(arguments)
        changes = arguments?.getString("changes") == "true"
        start()
    }
    override fun onStart() {
        Thread {
            val context = targetContext
            var checks = 0
            var ownsTestRoot = false
            var failure: Throwable? = null
            fun verify(value: Boolean) { check(value); checks++ }
            fun progress(text: String) { sendStatus(0, Bundle().apply { putString("stream", text + "\n") }) }
            fun waitUntil(condition: () -> Boolean) {
                val deadline = android.os.SystemClock.elapsedRealtime() + 60_000
                while (!condition()) {
                    check(android.os.SystemClock.elapsedRealtime() < deadline) { "Folder job/provider timeout" }
                    Thread.sleep(200)
                }
            }
            try {
                val roots = AuthorizedFolderMonitor.rows(context)
                check(roots.size == 1 && roots.single().optString("label").startsWith("ShieldGuard-folder-test-")) {
                    "Select only the owned SAF test folder before running"
                }
                ownsTestRoot = true
                val tree = Uri.parse(roots.single().getString("uri"))
                verify(AuthorizedFolderMonitor.allowedTree(tree))
                val permission = context.contentResolver.persistedUriPermissions.first { it.uri == tree }
                verify(permission.isReadPermission && !permission.isWritePermission)
                verify(AuthorizedFolderMonitor.validate(context))
                val oldEpoch = AuthorizedFolderMonitor.epoch(context)
                AuthorizedFolderMonitor.add(context, tree, Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION, oldEpoch)
                verify(AuthorizedFolderMonitor.epoch(context) > oldEpoch)
                verify(AuthorizedFolderMonitor.rows(context).size == 1)
                val store = AuthorizedFolderMonitor.store(context)
                fun summary() = JSONObject(store.getString("summary", "{}") ?: "{}")
                fun runScan(): JSONObject {
                    val before = summary().optLong("time")
                    FolderScanScheduler.manual(context)
                    waitUntil { summary().optLong("time") > before }
                    return summary()
                }
                val jobs = context.getSystemService(JobScheduler::class.java)
                AuthorizedFolderMonitor.setEnabled(context, true)
                verify(jobs.getPendingJob(FolderScanScheduler.periodicId)?.isPersisted == true)
                FolderScanScheduler.ensure(context)
                verify(jobs.allPendingJobs.count { it.id == FolderScanScheduler.periodicId } == 1)
                verify(FolderScanScheduler.periodicId != ScanScheduler.periodicId)
                val first = runScan()
                verify(first.getInt("scanned") == 3)
                verify(first.getInt("visited") == 3)
                verify(!first.getBoolean("partial"))
                val records = FolderScanJobService.decodeRecords(store.getString("cache", "{}") ?: "{}")
                verify(records.size == 3 && records.keys.all { it.matches(Regex("[a-f0-9]{64}")) })
                verify(records.values.all { it.hash?.length == 64 && it.complete })
                verify(records.values.all { it.findings.values.sum() < 25 }) // Benign APK may expose its launcher.
                val second = runScan()
                verify(second.getInt("scanned") == 0 && second.getInt("cached") == 3)
                if (changes) {
                    progress("PHASE3B_READY_FOR_CHANGED_ZIP")
                    // Host changes only its own harmless.zip. Re-list through the selected tree.
                    val before = records.values.map { it.size }.toSet()
                    waitUntil {
                        val treeDoc = android.provider.DocumentsContract.buildDocumentUriUsingTree(tree,
                            android.provider.DocumentsContract.getTreeDocumentId(tree))
                        val children = android.provider.DocumentsContract.buildChildDocumentsUriUsingTree(treeDoc,
                            android.provider.DocumentsContract.getDocumentId(treeDoc))
                        context.contentResolver.query(children,
                            arrayOf(android.provider.DocumentsContract.Document.COLUMN_SIZE), null, null, null)?.use { cursor ->
                            var changed = false
                            while (cursor.moveToNext()) if (!cursor.isNull(0) && cursor.getLong(0) !in before) changed = true
                            changed
                        } == true
                    }
                    val changed = runScan()
                    verify(changed.getInt("scanned") == 1 && changed.getInt("cached") == 2)
                    progress("PHASE3B_READY_FOR_NEW_PDF")
                    waitUntil {
                        val rootId = android.provider.DocumentsContract.getTreeDocumentId(tree)
                        val children = android.provider.DocumentsContract.buildChildDocumentsUriUsingTree(tree, rootId)
                        context.contentResolver.query(children,
                            arrayOf(android.provider.DocumentsContract.Document.COLUMN_DOCUMENT_ID), null, null, null)?.use { it.count == 4 } == true
                    }
                    verify(runScan().getInt("scanned") == 1)
                }
                FolderScanScheduler.cancel(context)
                AuthorizedFolderMonitor.recover(context) // Process-start recovery, not an actual phone reboot.
                verify(jobs.getPendingJob(FolderScanScheduler.periodicId) != null)
                val epoch = AuthorizedFolderMonitor.epoch(context)
                FolderScanScheduler.manual(context)
                AuthorizedFolderMonitor.cancel(context)
                verify(AuthorizedFolderMonitor.epoch(context) > epoch)
                verify(jobs.getPendingJob(FolderScanScheduler.manualId) == null)
                verify(AuthorizedFolderMonitor.status(context)["partial"] == true)
                context.contentResolver.releasePersistableUriPermission(tree, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                AuthorizedFolderMonitor.recover(context)
                verify(!AuthorizedFolderMonitor.enabled(context))
                verify(jobs.getPendingJob(FolderScanScheduler.periodicId) == null)
                verify(store.getString("state", "") == "permissionLost")
                verify(FolderScanJobService.decodeRecords(store.getString("cache", "{}") ?: "{}").isEmpty())
                var denied = false
                try { FolderScanScheduler.manual(context) } catch (_: SecurityException) { denied = true }
                verify(denied)
                AuthorizedFolderMonitor.setEnabled(context, false)
                verify(AuthorizedFolderMonitor.rows(context).isEmpty())
                verify(context.contentResolver.persistedUriPermissions.none { it.uri == tree && it.isReadPermission })
            } catch (error: Throwable) { failure = error }
            finally { if (ownsTestRoot) AuthorizedFolderMonitor.setEnabled(context, false) }
            finish(if (failure == null) 0 else 1, Bundle().apply {
                putString("stream", if (failure == null) "$checks authorized folder Android checks passed.\n"
                    else "$checks folder checks completed before failure: " + failure?.javaClass?.simpleName +
                        " " + failure?.message.orEmpty().take(150) + "\n")
            })
        }.start()
    }
}
