# ShieldGuard — Codex project instructions

- This is the existing Flutter/Dart + Android/Kotlin + Python security application; do not rebuild it from scratch.
- Work on the current task's branch. Never merge to `main`, force-push, or delete existing work without specific authorization.
- Keep user-facing UI, warnings, and Android notifications in Uzbek Latin using existing localization resources.
- Be privacy-first: no raw Telegram messages, OTPs, passwords, files, certificates/private keys, or secrets sent to remote services without specific informed consent; do not commit samples, keys, or private data.
- Do not execute, install, or dynamically test untrusted APKs. Use benign synthetic fixtures and bounded, read-only static analysis.
- Android consumer app has no global file interception, universal threat blocking, or automatic Device Owner rights. Respect SAF, package visibility, background scheduling, and Play policies; label incomplete checks honestly.
- Keep changes focused: inspect only relevant files, make a small patch, run targeted tests first, then the full regression suite at milestone boundaries. Never run Flutter integration/debug builds concurrently with release builds.
- Use the matching project skill **only when relevant**:
  - `$shieldguard-security`: phishing, Telegram, APK/file analysis, installed-app monitoring, permissions, device-management evaluation.
  - `$shieldguard-testing`: test generation, regressions, coverage, device checks, failure triage.
  - `$shieldguard-release`: APK/AAB signing, Android compatibility, Play compliance, release checks.
- For ordinary security feature work, use `$shieldguard-security`; invoke testing skill when tests are requested or a milestone completes. Do not load all skills for every small change.
- Current documented V3 baseline (not a current verification): Flutter 121 tests, Python 13 tests, Android integration 3 tests, device SAF 6 scenarios; see `TEST_REPORT.md`.
- Report briefly: files changed, tests actually run with pass/fail, what is untested, permissions/credentials missing, and next concrete action.
