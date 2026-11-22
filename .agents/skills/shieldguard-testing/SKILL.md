---
name: shieldguard-testing
description: Run focused and regression tests for ShieldGuard Flutter/Dart, Android Kotlin, Python gateway, APK/PDF parser fixtures, Telegram phishing detectors, and Android device compatibility; record only observed outcomes.
---

# ShieldGuard testing workflow

1. Read `AGENTS.md` and `TEST_REPORT.md`; treat historical counts as baseline, not current passing results.
2. Identify changed modules, then run the smallest relevant test set first. Add deterministic benign tests for risky cases and counterexamples; do not use genuine malware in CI/device execution.
3. Test representative phishing inputs: `t.me-premium.uz`, safe `https://t.me/premium`, `5 xonali kodni yuboring`, and `Hech kimga tasdiqlash kodini yubormang`. Verify both Dart and native notification analyzer.
4. For automatic scanning, test package added/replaced, app visibility denied, URI grants and revocation, ACTION_VIEW/SEND/SEND_MULTIPLE, allowed-folder changes, duplicate scans, background restrictions, low battery, opt-out, and incomplete results.
5. Run appropriate commands in order (adjust for OS and available tools):
   - `flutter analyze`
   - `flutter test --coverage`
   - `python -m unittest discover -s backend`
   - `powershell -NoProfile -ExecutionPolicy RemoteSigned -File test/native/run_tests.ps1` on Windows
   - `flutter test integration_test -d <device-id>` only with a confirmed device
   - `flutter build apk --debug` when a build is required
6. Do not run Flutter integration/debug and release builds concurrently. Device fixture tests must use benign data and cleanup owned fixture files only.
7. Update `TEST_REPORT.md` and `IMPLEMENTATION_STATUS.md` with command, environment, pass/fail/skip, coverage method, and real-device evidence. Never invent precision/recall without labeled corpus.
8. If tools, credentials, devices, or Android APIs are unavailable, mark the exact limitation; do not label a mock as a live test.
9. Summarize narrowly: tested modules, actual counts, failures, and unverified areas.
