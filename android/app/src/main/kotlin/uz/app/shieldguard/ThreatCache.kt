package uz.app.shieldguard

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.time.Instant

internal class ThreatCache(context: Context) : SQLiteOpenHelper(context, "reputation.db", null, 1) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("CREATE TABLE cache (key TEXT PRIMARY KEY, matched INTEGER, expires TEXT)")
    }
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit
    fun read(key: String): Map<String, Any>? {
        purge()
        return readableDatabase.query("cache", arrayOf("matched", "expires"), "key = ?",
            arrayOf(key), null, null, null).use {
            if (!it.moveToFirst()) null
            else if (Instant.parse(it.getString(1)).toEpochMilli() <= System.currentTimeMillis()) {
                writableDatabase.delete("cache", "key = ?", arrayOf(key))
                null
            } else mapOf("provider" to "webrisk", "matched" to (it.getInt(0) == 1), "expires" to it.getString(1))
        }
    }
    fun write(key: String, matched: Boolean, expires: String) {
        purge()
        require(Regex("[a-f0-9]{64}").matches(key))
        require(Instant.parse(expires).toEpochMilli() > System.currentTimeMillis())
        writableDatabase.insertWithOnConflict("cache", null, ContentValues().apply {
            put("key", key); put("matched", matched); put("expires", expires)
        }, SQLiteDatabase.CONFLICT_REPLACE)
        writableDatabase.execSQL("DELETE FROM cache WHERE rowid NOT IN (SELECT rowid FROM cache ORDER BY rowid DESC LIMIT 1000)")
        writableDatabase.execSQL("DELETE FROM cache WHERE key NOT IN (SELECT key FROM cache ORDER BY expires DESC LIMIT 1000)")
    }
    private fun purge() {
        // julianday handles UTC ISO timestamps and different fractional precision.
        writableDatabase.execSQL("DELETE FROM cache WHERE julianday(expires) <= julianday('now')")
    }
    fun clear() { writableDatabase.delete("cache", null, null) }
}
