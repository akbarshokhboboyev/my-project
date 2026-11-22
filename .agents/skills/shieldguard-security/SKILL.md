---
name: shieldguard-security
description: Implement and audit ShieldGuard defensive Flutter/Kotlin features: Telegram phishing and fake-bot detection, APK/file static analysis, installed-app event monitoring, user-selected file scanning, security permissions, and privacy.
---

# ShieldGuard security workflow

1. Read `AGENTS.md` and only the files involved in the specific requested threat scenario. Preserve existing V3 architecture and API contracts.
2. Before coding, separate **Android-possible**, **permission-dependent**, and **not-possible-for-normal-apps** behaviors. `ACTION_PACKAGE_ADDED/REPLACED` occurs after installation, not before. Do not claim global on-open interception or Device Owner privileges.
3. For Telegram phishing: edit `lib/core/engine.dart` and `NotificationAnalyzer.kt` consistently; cover bare domains such as `t.me-premium.uz`, Unicode/IDN impersonation, secret-code solicitation in Uzbek/Russian/English, and harmless safety-warning counterexamples. Never claim that text alone verifies a bot's identity.
4. For real-time protection: use documented package events, PackageManager metadata and bounded workers; for files use SAF and user-chosen `ACTION_VIEW` / `ACTION_SEND` / `ACTION_SEND_MULTIPLE` entries only. Authorized folder checks must respect scoped storage, revocation, and background limits. Distinguish scheduled scans from real-time monitoring.
5. For APK/PDF/ZIP/DEX work, reuse existing parsers. All untrusted files remain read-only and unexecuted. Enforce time/size/depth limits, graceful incomplete status, and false-positive controls. Signatures/reputation are evidence, not safety guarantees.
6. Online URL/hash lookup requires specific opt-in, approved licensing, and server-held secrets. No uploading full files or Telegram message contents by default.
7. Device Admin must be an **evaluation first**; never add coercive activation, stealth admin, uninstall prevention, automatic wiping, or unauthorized app control. Keep Enterprise Device Owner as a separate authorized managed-device design.
8. Keep Uzbek localization, alert deduplication, cancellation, bounded queues, and accurate coverage/status indicators.
9. Add benign-focused unit tests for changed rules and ask for `$shieldguard-testing` when a full test pass or device validation is needed.
10. Finish with a short summary of evidence, remaining gaps, and exact files touched; do not invent completed real-device or malware tests.
