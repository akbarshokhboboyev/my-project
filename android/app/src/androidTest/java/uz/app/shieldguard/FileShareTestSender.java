package uz.app.shieldguard;

import android.app.Activity;
import android.net.Uri;
import android.os.Bundle;

// Test APK only; grants known synthetic files from their owning UID.
public final class FileShareTestSender extends Activity {
    @Override public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Uri base = Uri.parse("content://uz.app.shieldguard.test.filefixtures");
        getContentResolver().call(base, "prepare", null, null);
        for (String name : new String[]{"document.pdf", "fixture.apk", "harmless.txt", "broken.zip", "large.dat", "missing.pdf"})
            getContentResolver().call(base, "grant", name, null);
        finish();
    }
}
