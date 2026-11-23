# ShieldGuard V3.1 — final security hardening

2026-11-23 · `feature/shieldguard-v3-1` · version **3.1.0+4**.

**Later activation recovery, 2026-11-23:** at the user's request, the existing notification-access grant was cycled through Android's visible settings and confirmation flow. Android subsequently listed ShieldGuard under live notification listeners and its service record was present; local Telegram monitoring remained enabled. This resolves the earlier unbound-service observation below. A fresh Telegram threat notification and the Home status label were not verified in this recovery check. No code or privileged permission override was needed.

Implementation and automated regression are complete. **Production release is blocked by unavailable user-owned signing credentials.** No production APK/AAB was generated or published; the release guard remains enforced. Device verification is qualified below, rather than represented as full acceptance.

## Implemented behavior

- Bounded static ransomware, spyware/keylogger, banking and RAT assessments combine manifest and DEX string-table evidence. Each family includes fixed evidence IDs, severity, confidence, completeness and a qualified status. Legitimate encryption, keyboard/accessibility, banking and remote-support counterexamples are tested.
- The existing file scanner, installed-app scanner and authorized-folder scanner reuse these assessments. Rule-version changes invalidate old monitoring caches without enabling monitoring or extending permissions.
- Explicit APK VIEW/SEND/SAF flows show Uzbek scanning, blocked, warning, no-findings or incomplete UI. Strong evidence with Auto Block enabled prevents ShieldGuard handoff. Strict incomplete results are held. No-findings requires an explicit press; warning requires a separate confirmation. Closing/cancelling discards only the corresponding staged snapshot and temporary grant, never the original document.
- Existing SHA-256 revalidation, snapshot expiry, generation and native policy checks remain authoritative. Android chooser handoff is recorded as a request, never as a successful install. The router navigator is mounted during dialogs so system Back can cancel without the GoRouter navigator assertion.

## Observed verification

Windows Flutter 3.47.6 / Dart 3.13.5, JDK17, AGP9.1.1, compile/target36, min26. Commands were run sequentially at build boundaries.

| Check | Current observed result |
| --- | --- |
| `flutter analyze` | PASS; no issues |
| `flutter test --coverage` | **214/214 PASS**; LCOV LH/LF **1497/1887 = 79.33%** |
| `test/native/run_tests.ps1` with cached Kotlin compiler | **275 checks + 387 malformed inputs PASS**, including 37 new threat-family assertions |
| `python -m unittest discover -s backend` | **13/13 PASS** |
| Targeted APK dialog, Back and threat-family tests | PASS; included in the totals above |
| `flutter build apk --debug` | PASS; versioned artifact below |
| Android test APK build | PASS; all four existing runners registered |
| `:app:minifyReleaseWithR8` | PASS; 2m48s; compilation audit only |
| `flutter build apk --release` without credentials | Expected guard rejection: release signing not configured |
| `apksigner verify --verbose` on final debug APK | PASS; v2 signature, one debug signer |
| `zipalign -c -P 16 4` on final debug APK | PASS |
| Packaged ELF PT_LOAD alignment | All four native libraries 65536 bytes; not a substitute for runtime/store testing |

Coverage is line execution coverage, not malware detection accuracy. The changed UI adds lines and branches, so the percentage must not be compared as detection precision with the historical 80.73% baseline. Local ignored logs `final-analyze.log`, `final-flutter.log`, `final-native.log`, `final-python.log`, `final-debug.log`, `final-test-build.log`, `final-r8.log` and `final-release-guard.log` support these observations; they are not committed as private build artifacts.

## Android evidence

Physical Android16: final debug APK installed successfully, PackageManager reports **3.1.0 / code4**. A benign signed codeless synthetic APK was selected through real SAF. The Uzbek no-findings dialog and explicit Continue/Cancel controls were visible. Pressing Continue opened the Android chooser; no fixture was installed or executed. Additional outcomes are recorded in TEST_REPORT.md.

The real strong-indicator blocked modal was also verified: no Continue action, and explicit discard removed only its own snapshot (2→1). Inaccessible-URI cold VIEW / warm VIEW / warm SEND routing passed **3/3** after correcting the smoke harness's distinction between an incomplete result page and an open dialog. Warning phone E2E attempts did not establish the expected warning and remain unverified. Android retained notification access, but the listener was not live-bound after update and user permission toggles; live Telegram protection on this final phone build remains unverified/paused. This is not represented as an active protection pass.

Separate headless emulator: API37/Android17, x86_64, actual 16384-byte page size. Two native APK guard runs each reached **24 checks before failing** at the real foreground modal assertion while Launcher/SystemUI ANRs were present. A subsequent boot with 4096 MiB runtime RAM ended with `Process crashed` before a check count. These are **failed/incomplete E2E**, not passing runners or Android16 results. The dedicated emulator was stopped; no user data was wiped. Earlier macOS API36 successes remain historical evidence only.

Full current-device background notification, fresh installed-package events, authorized-folder changes/reboot and complete native instrumentation remain **unverified** unless individually recorded as current passes in TEST_REPORT.md. PHASE3A's historical expanded 25-case E2E gap remains open; it is not filled by unit tests or this APK smoke test.

## Security and dependency audit

Manifest retains only INTERNET, POST_NOTIFICATIONS and RECEIVE_BOOT_COMPLETED as requested uses-permissions. No QUERY_ALL_PACKAGES, REQUEST_INSTALL_PACKAGES, MANAGE_EXTERNAL_STORAGE, Device Admin, overlay or Accessibility service was added. Exported MainActivity accepts user-selected intents; content grants and format checks gate reads. FileProvider is non-exported, URI-grant based and snapshot scoped. Jobs are non-exported and protected by BIND_JOB_SERVICE; the isolated PDF service is non-exported. Backup and cleartext traffic remain disabled. The notification listener is user-authorized; its permission is not silently changed.

New family extraction returns bounded fixed evidence IDs, not raw decoded strings. No new upload, telemetry, original-file deletion, malware execution, silent install/uninstall or raw-message logging was introduced. This is a focused source/manifest audit, not a penetration test or a full dependency/SBOM certification.

PDFBox-Android remains **2.0.27.0**, the latest listed [fork release](https://github.com/TomRoush/PdfBox-Android/releases) at review. [Upstream PDFBox security](https://pdfbox.apache.org/security.html) describes recent ExtractEmbeddedFiles example-tool vulnerabilities; ShieldGuard uses neither that example nor embedded-file extraction to disk. This does not establish complete fork CVE coverage. Parsing remains isolated and bounded; provider I/O and parser denial-of-service cannot be universally ruled out. Further dependency review remains a release consideration.

## Artifact and release blockers

Debug-only artifact: `build/final/3.1.0+4/shieldguard-3.1.0-debug.apk`.

- Size: **200428032 bytes**.
- SHA-256: `ff0a8684006af77ad51f8cd725a84d826bc3f924e4bdb12b5f430d056502a9a8`.
- Debug signing only; binaries and test fixtures are ignored and not committed.
- Production upload key is absent. No replacement identity was generated. The unsigned escape hatch was removed; standard debug keystore/alias are rejected for production assemble/bundle.
- Play submission, public privacy URL/owner details, Data Safety review, internal testing and signed-release runtime verification remain open in PLAY_STORE_CHECKLIST.md. No Play upload occurred.

## Practical limits

This blocks **ShieldGuard's own forwarding path** under its configured policy. It cannot veto every installer invocation from Telegram or other apps. Installed-app events are post-install and visibility limited; SAF folders are opt-in periodic scans subject to Android scheduling. Other apps' private storage is not inspected.

DEX evidence is string-table/reference-like evidence, not validated call graphs or observed behavior. Obfuscation, decoy strings, encrypted payloads, native code and inaccessible content can cause misses or false positives. Strong indicators are not a verified malware-family diagnosis; no-findings is not a safety guarantee. Real labeled-corpus precision/recall and live provider reputation are **unverified**. Only benign synthetic inputs and mocked evidence were used; no malware was executed.
