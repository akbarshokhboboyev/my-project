---
name: shieldguard-release
description: Prepare and verify ShieldGuard Android release APK/AAB, signing, 16 KiB compatibility, R8, Play Console readiness, privacy disclosures, and secure versioned release workflow.
---

# ShieldGuard release workflow

1. Read `AGENTS.md`, `RELEASE_GUIDE.md`, `PLAY_STORE_CHECKLIST.md`, and relevant Gradle files before any release change.
2. Confirm branch, versionCode/versionName, target SDK, JDK/Flutter/AGP compatibility, exported components, Android 13-16 notification permissions, package visibility, background jobs, and Play policy implications of antivirus features.
3. Audit secrets: keep keystore and passwords outside Git; use ignored local properties or approved secret management. Never print, commit, or request signing passwords in chat.
4. Run targeted tests and a full regression check before release builds. Keep build operations sequential. Audit R8/ProGuard changes narrowly; do not silence broad warnings blindly.
5. Signed release APK/AAB require a real user-owned upload key. If missing, label outputs **unsigned audit artifacts only**, not publishable binaries. Never create a production identity without user authorization.
6. Verify signatures with `apksigner` / `jarsigner`, `zipalign` and 16 KiB page compatibility where relevant. Record SHA-256 and device runtime validation separately.
7. Recheck current official Google Play rules for antivirus/package visibility, restricted permissions, Data Safety, privacy policy, internal testing, screenshots, and signing. Do not publish, accept paid services, or upload to Play without explicit user authorization.
8. Update release docs and report signed/unsigned state, test evidence, unfinished store requirements, and blocked credentials succinctly.
