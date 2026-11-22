package uz.app.shieldguard;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.os.Binder;
import android.os.Bundle;
import android.os.ParcelFileDescriptor;
import android.os.Process;
import android.provider.OpenableColumns;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

// Separate test APK process: deliberately uses platform Java only, without the target's Kotlin runtime.
public final class FileShareFixtureProvider extends ContentProvider {
    private static final String AUTHORITY = "uz.app.shieldguard.test.filefixtures";
    private static final List<String> NAMES = Arrays.asList("document.pdf", "fixture.apk",
        "harmless.txt", "broken.zip", "large.dat", "missing.pdf", "photo.jpg.apk", "tampered.apk");
    private File file(String name) { return new File(getContext().getCacheDir(), "phase3-" + name); }

    @Override public boolean onCreate() { prepare(); return true; }
    private void write(String name, byte[] bytes) throws IOException {
        try (OutputStream out = new FileOutputStream(file(name))) { out.write(bytes); }
    }
    private void prepare() {
        try {
            write("document.pdf", pdf());
            write("harmless.txt", "Harmless synthetic document".getBytes(StandardCharsets.US_ASCII));
            write("broken.zip", new byte[]{80, 75, 3, 4, 1});
            String source = getContext().getApplicationInfo().sourceDir;
            try (InputStream in = new FileInputStream(source);
                 OutputStream out = new FileOutputStream(file("fixture.apk"))) {
                byte[] buffer = new byte[8192];
                int count;
                while ((count = in.read(buffer)) != -1) out.write(buffer, 0, count);
            }
            try (InputStream in = new FileInputStream(file("fixture.apk"));
                 OutputStream out = new FileOutputStream(file("photo.jpg.apk"))) {
                byte[] buffer = new byte[8192]; int count;
                while ((count = in.read(buffer)) != -1) out.write(buffer, 0, count);
            }
            // Benign self APK, rewritten without its signing block and with an unsigned extra entry.
            // Never installed or executed: this is exclusively a static signature-integrity fixture.
            try (java.util.zip.ZipFile zip = new java.util.zip.ZipFile(source);
                 java.util.zip.ZipOutputStream out = new java.util.zip.ZipOutputStream(new FileOutputStream(file("tampered.apk")))) {
                Enumeration<? extends java.util.zip.ZipEntry> entries = zip.entries();
                byte[] buffer = new byte[8192];
                while (entries.hasMoreElements()) {
                    java.util.zip.ZipEntry entry = entries.nextElement();
                    out.putNextEntry(new java.util.zip.ZipEntry(entry.getName()));
                    if (!entry.isDirectory()) try (InputStream in = zip.getInputStream(entry)) {
                        int count; while ((count = in.read(buffer)) != -1) out.write(buffer, 0, count);
                    }
                    out.closeEntry();
                }
                out.putNextEntry(new java.util.zip.ZipEntry("SHIELDGUARD_BENIGN_TEST.txt"));
                out.write("Benign integrity regression only".getBytes(StandardCharsets.US_ASCII)); out.closeEntry();
            }
        } catch (IOException error) { throw new IllegalStateException("Synthetic fixture preparation failed", error); }
    }
    @Override public Bundle call(String method, String arg, Bundle extras) {
        if (getContext().getPackageManager().checkSignatures(Binder.getCallingUid(), Process.myUid())
            != PackageManager.SIGNATURE_MATCH) throw new SecurityException();
        if ("cleanup".equals(method)) {
            for (String name : NAMES) {
                getContext().revokeUriPermission(Uri.parse("content://" + AUTHORITY + "/" + name),
                    Intent.FLAG_GRANT_READ_URI_PERMISSION);
                file(name).delete();
            }
        } else if ("prepare".equals(method)) prepare();
        else {
            if (!NAMES.contains(arg)) throw new IllegalArgumentException();
            Uri uri = Uri.parse("content://" + AUTHORITY + "/" + arg);
            if ("grant".equals(method))
                getContext().grantUriPermission("uz.app.shieldguard", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
            else if ("revoke".equals(method))
                getContext().revokeUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
            else throw new IllegalArgumentException();
        }
        return new Bundle();
    }
    private void checkRead(Uri uri) {
        if (!NAMES.contains(uri.getLastPathSegment())) throw new IllegalArgumentException();
        if (Binder.getCallingUid() != Process.myUid() &&
            getContext().checkUriPermission(uri, Binder.getCallingPid(), Binder.getCallingUid(),
                Intent.FLAG_GRANT_READ_URI_PERMISSION) != PackageManager.PERMISSION_GRANTED)
            throw new SecurityException();
    }
    @Override public Cursor query(Uri uri, String[] projection, String selection, String[] args, String order) {
        checkRead(uri);
        String name = uri.getLastPathSegment();
        String[] columns = projection == null
            ? new String[]{OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE} : projection;
        Object[] row = new Object[columns.length];
        for (int i = 0; i < columns.length; i++) {
            if (OpenableColumns.DISPLAY_NAME.equals(columns[i])) row[i] = name;
            else if (OpenableColumns.SIZE.equals(columns[i]))
                row[i] = "large.dat".equals(name) ? 129L * 1024 * 1024 : file(name).length();
        }
        MatrixCursor cursor = new MatrixCursor(columns);
        cursor.addRow(row);
        return cursor;
    }
    @Override public ParcelFileDescriptor openFile(Uri uri, String mode) throws FileNotFoundException {
        checkRead(uri);
        if (!"r".equals(mode)) throw new SecurityException();
        return ParcelFileDescriptor.open(file(uri.getLastPathSegment()), ParcelFileDescriptor.MODE_READ_ONLY);
    }
    @Override public String getType(Uri uri) {
        String name = uri.getLastPathSegment();
        if ("document.pdf".equals(name) || "missing.pdf".equals(name)) return "application/pdf";
        if ("fixture.apk".equals(name)) return "application/vnd.android.package-archive";
        if ("broken.zip".equals(name)) return "application/zip";
        return "application/octet-stream";
    }
    @Override public Uri insert(Uri uri, ContentValues values) { throw new UnsupportedOperationException(); }
    @Override public int update(Uri uri, ContentValues values, String selection, String[] args) { throw new UnsupportedOperationException(); }
    @Override public int delete(Uri uri, String selection, String[] args) { throw new UnsupportedOperationException(); }

    private byte[] pdf() throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write("%PDF-1.4\n".getBytes(StandardCharsets.US_ASCII));
        List<Integer> offsets = new ArrayList<>();
        String[] objects = {"<< /Type /Catalog /Pages 2 0 R >>",
            "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
            "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 100 100] >>"};
        for (int i = 0; i < objects.length; i++) {
            offsets.add(out.size());
            out.write(((i + 1) + " 0 obj\n" + objects[i] + "\nendobj\n").getBytes(StandardCharsets.US_ASCII));
        }
        int xref = out.size();
        out.write("xref\n0 4\n0000000000 65535 f \n".getBytes(StandardCharsets.US_ASCII));
        for (int offset : offsets)
            out.write(String.format(Locale.ROOT, "%010d 00000 n \n", offset).getBytes(StandardCharsets.US_ASCII));
        out.write(("trailer\n<< /Size 4 /Root 1 0 R >>\nstartxref\n" + xref + "\n%%EOF\n").getBytes(StandardCharsets.US_ASCII));
        return out.toByteArray();
    }
}
