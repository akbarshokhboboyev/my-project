package uz.app.shieldguard

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

internal class HistoryStore(private val context: Context) :
    SQLiteOpenHelper(context, "history.db", null, 1) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("CREATE TABLE scans (id INTEGER PRIMARY KEY, type TEXT, score INTEGER, count INTEGER, complete INTEGER, time INTEGER)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit

    fun record(type: String, score: Int, count: Int, complete: Boolean, time: Long) {
        if (!context.options().getBoolean("history", false)) return
        val db = writableDatabase
        db.beginTransaction()
        try {
            db.insertOrThrow("scans", null, ContentValues().apply {
                put("type", type)
                put("score", score.coerceIn(0, 100))
                put("count", count)
                put("complete", complete)
                put("time", time)
            })
            db.execSQL("DELETE FROM scans WHERE id NOT IN (SELECT id FROM scans ORDER BY id DESC LIMIT 1000)")
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    fun clear() { writableDatabase.delete("scans", null, null) }

    fun entries(): List<Map<String, Any>> = readableDatabase.rawQuery(
        "SELECT type, score, count, complete, time FROM scans ORDER BY id DESC", null
    ).use { cursor ->
        buildList {
            while (cursor.moveToNext()) add(mapOf("type" to cursor.getString(0), "score" to cursor.getInt(1),
                "count" to cursor.getInt(2), "complete" to (cursor.getInt(3) == 1), "time" to cursor.getLong(4)))
        }
    }
}
