# ShieldGuard V3.1 — PHASE 4 bosqichma-bosqich sinovlari

## APK open route — Windows va jismoniy Android16 (2026-11-23)

Lokal HEAD `45de1a3` dagi route tuzatishi qayta tekshirilib, telefonga o‘rnatildi. Qurilmada oldingi `31c3878f...` APK qolgan edi; unda `flutter_deeplinking_enabled=false` va keyingi route/channel tuzatishlari yo‘q. Amaldagi kod `3c231d6`/`84d9b5e` tuzatishlarini o‘z ichiga oladi: file URI native handler’da qoladi, recovery sahifasidan keyin ham native natija yo‘qolmaydi.

| Tekshiruv | Shu sessiyadagi kuzatilgan natija |
| --- | --- |
| Windows Flutter 3.47.6 / Dart 3.13.5, JDK17 / AGP9.1.1 | Joriy kod analyze/test/debug build bilan ishladi; macOS 3.50.1 natijasi quyida alohida tarix |
| `flutter test test/file_open_route_test.dart test/file_share_test.dart test/apk_guard_test.dart` | 17/17 PASS |
| `flutter analyze` | No issues found |
| `flutter test --coverage` | 208/208; LH/LF 1349/1671 = 80,73% |
| `flutter build apk --debug` | PASS, 317,2 s; yangi APK adb install -r: Success |
| Packaged AndroidManifest audit | `flutter_deeplinking_enabled=false` haqiqiy APK ichida tasdiqlandi |
| `integration_test/file_open_route_smoke.ps1` | Jismoniy Android16 API36: cold VIEW, warm VIEW, warm SEND — 3/3 PASS |
| Himoya holati | Update’dan keyin listener ulanmagan; foydalanuvchi mavjud notification-access ruxsatini off/on qildi. Android service bound va real bosh sahifada “Himoya faol” tasdiqlandi |

Yangi smoke skript mavjud bo‘lmagan sintetik `content:` APK URI’sini **read grant’siz** yuboradi. Kutilgan natija — o‘zbekcha o‘qish ruxsati yo‘qligi va scan result; raw URI/GoException ko‘rsatilmasligi. Bu haqiqiy APK kontent/signature parsing, Telegram sender yoki installer sinovi emas. Har warm intent oldidan bosh sahifa alohida tekshiriladi, shuning uchun oldingi natija yangisi sifatida qabul qilinmaydi. Cold holat Activity/task’ni qayta yaratadi, app force-stop qilinmaydi. Sinov APK o‘rnatmaydi/execute qilmaydi, fayl yaratmaydi; faqat o‘z UUID UI XML dump’ini tozalaydi.

Artifact: `build/app/outputs/flutter-apk/app-debug.apk`, 173321034 bytes; SHA-256 `5da0f5b6c1da40af7b32a55b880108135f9d6677d5d545f10ef50b367d13e3c5`. Windows SDK sabab oldindan mavjud `pubspec.lock` test_api 0.7.12 o‘zgarishi bu verification commit’iga kiritilmadi. Kotlin/Python/native runner bu route-only tekshiruvda takrorlanmadi; quyidagi natijalar o‘z muhitiga tegishli.

Qayta bajarish: `powershell -NoProfile -ExecutionPolicy RemoteSigned -File integration_test/file_open_route_smoke.ps1 -Adb <adb.exe> -Serial <qurilma-id>`. Telefon qulfdan ochiq bo‘lishi kerak. Bildirishnomaga kirish ruxsati Android’da qolgan bo‘lsa ham, app update’dan keyin service ulanishi alohida tekshiriladi; “faol” holat faqat haqiqiy ulanishda ko‘rsatiladi.

## 4D-R — `3c231d6` dan keyingi regressiya, emulator va build (2026-11-23)

Muhit: macOS, Flutter 3.50.1 (stable), JDK 17, Kotlin compiler 2.2.21 (Gradle keshidan), AGP 9.1.1, Android emulator `Pixel_8` AVD (API 36, arm64). Barcha device natijalari **emulator**da olingan; jismoniy telefon va haqiqiy Telegram ilovasi ishlatilmagan. Faqat o‘zimiz yaratgan benign/sintetik fixture’lar; scanned APK install/execute qilinmadi (PHASE 2 uchun o‘zimizning kodsiz `hasCode=false` fixture’i o‘rnatilib, keyin o‘chirildi).

### Topilgan va tuzatilgan xatolar

| # | Xato | Ta’sir | Tuzatish | Dalil |
| --- | --- | --- | --- | --- |
| 1 | `3c231d6` dagi `RouteRecoveryPage` ochiq paytda `Workspace` dispose bo‘lib, `setMethodCallHandler(null)` native `incoming` handler’ini o‘chirardi | Noto‘g‘ri route’dan keyin kelgan fayl natijasi ko‘rsatilmasdi (talab 5 buzilgan) | Kanalning yagona egasi (`claimShieldChannel`/`releaseShieldChannel`); recovery sahifasi `incoming` kelsa `/` ga qaytadi, Workspace native navbatni drain qiladi. Eski sahifa dispose’i yangi egani o‘chirmaydi | `file_open_route_test.dart` 2-testi tuzatishsiz FAIL, tuzatish bilan PASS; yangi 3-test teskari o‘tishni qo‘riqlaydi (u eski kodda ham o‘tadi — kelajakdagi regressiya uchun) |
| 2 | Lokal Flutter 3.50.1 AGP ≥ 9.1.1 talab qiladi, loyiha 9.1.0 da edi | `flutter build`/`flutter test -d` ishlamasdi | `android/settings.gradle.kts` AGP 9.1.0 → 9.1.1 (patch) | Debug/release build va integration test o‘tdi |
| 3 | Flutter 3.47+ `package:flutter/material.dart` va `GlobalMaterial/CupertinoLocalizations` deprecated | `flutter analyze` 11 issue (1 warning + 10 info) | `material_ui ^1.11.1`, `cupertino_ui ^1.1.7`; importlar ko‘chirildi; app yangi delegatlardan foydalanadi; generatsiya qilinadigan `strings.dart` uchun `l10n.yaml` `header` ignore’i (gen-l10n hali eski delegat chiqaradi); test’dagi unused import olib tashlandi | `flutter analyze`: No issues found |
| 4 | `ApkGuardInstrumentation` (test harness) sender bergan URI grant’ga tayanardi, `am instrument` esa target paketni force-stop qilib vaqtinchalik grant’larni bekor qiladi | 4D runner hech qachon o‘ta olmasdi (`Owner URI grant required`) | Runner signature-tekshiruvli fixture provider’dan o‘z fayllari uchun grant’ni o‘zi so‘raydi. Production kod o‘zgarmagan | Emulator’da 32/32 |

Kuzatilgan, xato emas: Flutter 3.50 `Intent verification failed ... IGNORED in release builds` logi faqat `route`/`dart_entrypoint`/cached-engine extra’larini cheklaydi. ShieldGuard fayl URI’sini native `FileOpenScanHandler` orqali o‘qiydi; release build’da `VIEW` va `SEND` emulator’da ishlashi tasdiqlandi.

### Avtomatik testlar (joriy HEAD + yuqoridagi tuzatishlar)

| Buyruq | Natija |
| --- | --- |
| `flutter analyze` | PASS — No issues found |
| `flutter test test/file_open_route_test.dart` | PASS 3/3 (tuzatishsiz: 1 FAIL) |
| `flutter test test/apk_guard_test.dart` / `file_share_test.dart` / `folder_monitor_test.dart` | PASS 9/9, 5/5, 7/7 |
| `flutter test --coverage` | PASS **208/208**; Dart LH/LF **1349/1671 = 80,73%** |
| Native JVM: `run_tests.ps1` mantiqi macOS bash’da (`-KotlinLib` rejimi, Kotlin 2.2.21) | PASS **238 + 387 malformed** (17+12+16+9+27+31+30+35+54+7). `pwsh` o‘rnatilmagan; skript Windows `;` classpath ajratuvchisidan foydalanadi |
| `python3 -m unittest discover -s backend` | PASS 13/13 |
| `flutter test integration_test/shieldguard_test.dart -d emulator-5554` | PASS 3/3 (emulator) |
| `flutter build apk --debug` | PASS; SHA-256 `87e9d290a58a249e1ede78972fca2a56fb379da572117c1051f6646bfd41780c` |
| `flutter build apk --release` (production kalitsiz) | Kutilganidek to‘xtadi: “Release imzolash sozlanmagan” |
| Xuddi shu, faqat lokal env orqali debug keystore bilan | PASS (R8/minify, 59,8 MB). Tarqatish uchun emas; kalit/parol repo’ga yozilmagan |

### Emulator device matritsasi

| # | Stsenariy | Holat | Usul |
| --- | --- | --- | --- |
| 1–2 | Telegram Share/Open → ShieldGuard | **UNVERIFIED** (Telegram yo‘q) | Ekvivalent `SEND`/`VIEW` intentlari adb va 3A runner orqali PASS |
| — | `3c231d6`: cold-start `VIEW` (debug va release) | PASS | Natija ko‘rsatildi; URI, token, `GoException`, recovery sahifasi yo‘q; “Tekshiruv to‘liq bajarilmadi” |
| — | Warm-start (boshqa tab ochiq) va background (HOME) `VIEW`, warm `SEND` (debug/release) | PASS | uiautomator |
| 3 | Multiple-file share | PASS | 3A runner `ArrayList<Uri>` `SEND_MULTIPLE` (“Fayl tartibi · 2”). adb `--eua` `Uri[]` yuboradi — bu adb cheklovi, ilova xatosi emas |
| 4 | Signature-invalid APK | PASS | 4D: `signatureFailed` → `blockedByShieldGuard`, launch=0 |
| 5 | Valid benign APK | PASS | 4D: `signatureVerified`, `warningOnly`, tasdiqsiz forward yo‘q |
| 6 | Strong suspicion blocking + Uzbek modal | PASS | 4D: real `APK BLOKLANDI` modal, ShieldGuard oynasida |
| 7 | Strict incomplete | PASS | 4D: batch timeout → `scanIncomplete`, forward blocked |
| 8 | Auto-block o‘chirish/yoqish | PASS | 4D: opt-out epoch in-flight token’ni bekor qiladi |
| 9 | Background APK notification | PASS | 4D notificationsOnly, ruxsat bilan: shown=true, `VISIBILITY_PRIVATE`, public version, URI yo‘q (9/9) |
| 10 | Notification permission denied | PASS | permission=false → shown=false; ruxsat asl holatga qaytarildi |
| 11 | SAF permission revoke | PASS | 3B: `permissionLost`, kesh tozalandi, manual scan `SecurityException` |
| 12 | Folder manual scan | PASS | 3B: 3 scanned → 3 cached |
| 13 | Process restart | PASS (qisman) | Force-stop’dan keyin cold-start; 3B `recover()` process-start simulyatsiyasi |
| 14 | Reboot recovery | **UNVERIFIED** | Emulator reboot qilinmadi |
| 15 | Snapshot mutation / generation | PASS | 4D: o‘zgargan snapshot rad etildi, eski validation qayta ishlatilmaydi |
| 15 | Snapshot 10-daqiqalik real expiry | **UNVERIFIED** | Real vaqt kutilmadi; JVM testlari qoplaydi |
| 16 | Cancellation | PASS | 3A/4D `scanCancelled` |
| 16 | Parallel so‘rovlar | Qisman | Disk cap (≤8) va staging semaphore tekshirildi; haqiqiy parallel intent oqimi sinalmadi |
| 17 | Unknown-source settings | **UNVERIFIED (bu sikl)** | 4D da oldin real qurilmada tasdiqlangan |
| 18 | PHASE 2 install/update | PASS | 21/21 self/job + 27/27 ADDED/REPLACED; fixture o‘chirildi |
| 19 | PHASE 3A 25-case | PASS 25/25 | `FileShareInstrumentation` + sender |
| 20 | PHASE 3B native | PASS 26/26 | Real DocumentsUI tanlovi; “changes” rejimi ishga tushirilmadi |
| 21 | PHASE 4D native | PASS 32/32 | Oldin `unverified` edi |

Device triage eslatmalari: (a) `flutter test integration_test` `app-debug.apk` ni integration harness bilan qayta yozadi — keyin o‘rnatilgan APK splash’da drayverni kutadi; bu ilova xatosi emas, oddiy `flutter build apk --debug` dan keyin hal bo‘ldi. (b) `pm clear` dan keyingi intro modal 3A/4D UI tekshiruvlarini to‘sdi; intro yopilgach o‘tdi.

Cleanup: test paketi `uz.app.shieldguard.test` va sintetik monitor fixture o‘chirildi; Download’dagi barcha sintetik fayl/papkalar o‘chirildi; POST_NOTIFICATIONS `granted=false` holatiga qaytarildi; app data tozalanib debug APK qayta o‘rnatildi.

## 4D — yakuniy Android16 tekshiruvi (2026-11-22)

| Amal | Kuzatilgan natija |
| --- | --- |
| Yakuniy debug build / install | 18,6 s; API36’da Success; debug v2 signature Verifies |
| APK guard test runner build | BUILD SUCCESSFUL, 7 s |
| APK guard test runner install/run | **unverified** — INSTALL_FAILED_USER_RESTRICTED; runner ishga tushmadi |
| Real SAF, benign kodsiz APK imzosi buzilgan nusxa | `signatureFailed`, `strongSuspicion`, complete=true; Uzbek APK BLOKLANDI modal; history blockedByShieldGuard |
| Real SAF, asl benign APK | 15 ball exported launcher; heuristicWarning/warningOnly; bloklash modal yo‘q |
| Benign explicit external open | Native snapshot/hash/FileProvider yo‘li Android ChooserActivity’gacha ishladi; installer tanlanmadi, install bajarilmadi |
| Authorized folder, manual job, app HOME’da | 2 scanned/0 cached; partial=false/unverified=0; OS’da apk-guard notification qayd etildi |
| POST_NOTIFICATIONS vaqtincha denied | O‘zgargan APK: 1 scanned/1 cached; permission denied haqiqiy; APK notification yo‘q. Avvalgi granted holat tiklandi |
| Unknown-source settings tugmasi | Real ManageExternalSourcesActivity ochildi; sozlamalar o‘zgartirilmadi |
| Cleanup | Own roots/cache/summary/history/private snapshots bo‘sh; consent strict/alerts false; auto-block true; owned test papka/fayllar olib tashlandi |

Bu UI/SAF tekshiruvlari native instrumentation o‘rniga hisoblanmaydi. Background testi manual JobScheduler ishini HOME’dan tekshiradi, tabiiy 15-daqiqalik periodic ishga tushish yoki real Telegram sender testi emas. Kuchli integrity dalili malware tasdig‘i emas. Snapshot mutation/generation/limits bo‘yicha yangi Android assertion’lar kompilyatsiya qilindi, ammo alohida runner install rad etilgani uchun ularning device natijasi **unverified**.

SAF helper birinchi urinishda lock-screen sabab tile topmadi; foydalanuvchi qulfni ochgach block modal dalili ko‘rindi. Benign helper’dagi anchored regex Flutter merged semantics bilan mos kelmadi; keyingi bevosita UI/metadata tekshiruvi heuristic-only natija va explicit chooser handoff’ni tasdiqladi. Bular app scanner crash emas. Papka helper’i eski scroll pozitsiyasida bir marta tugmacha topmadi; cold launch’dan keyin haqiqiy tree tanlandi. Testlar uchun qo‘shimcha production test endpoint yoki UI backdoor yaratilmagan.

Persistable read grant removal bajarildi; Android picker’ning vaqtinchalik Activity grant’i process tugaguncha yashashi kuzatildi. Cold launch’dan keyin owned URI permission yozuvi ham qolmadi. Hech qanday foydalanuvchi fayli yoki boshqa ilova sozlamasi o‘zgartirilmadi. O‘z app’imiz POST_NOTIFICATIONS ruxsati faqat talab qilingan test uchun revoke/grant qilinib, avvalgi holat tiklandi.

Yakuniy regressiya: Flutter **205/205**, Kotlin **238 + 387 malformed**, Python **13/13**, analyze **No issues found**, Dart LH/LF **1318/1641 = 80,32%** (4C’da shu Dart source bilan bajarilgan). 4D o‘zgarishlari native gate/Android testlarga tegishli, final main va test APK kompilyatsiyasi yuqorida. Manifest APK auditida faqat INTERNET, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED va androidx ichki receiver permission’i bor; installer/storage/overlay/admin ruxsati qo‘shilmadi. `shieldguard-release` faqat manifest/Play auditida ishlatildi.

APK SHA-256: `31c3878f3265e30771b45a125841cde7276c5da8a3131213a1ff7e5cc081b4fe`, 191135457 bytes. Build APK va sintetik APK’lar Git’ga commit qilinmaydi. PHASE 2 install/update, PHASE 3A 25-case, PHASE 3B native instrumentation va real Telegram notification hali ochiq.

## 4A–4C regressiya tarixi

4C: `flutter test test/apk_guard_test.dart test/file_share_test.dart test/folder_monitor_test.dart` **21/21**. `flutter analyze` toza. `flutter test --coverage` **205/205**, LH/LF **1318/1641 = 80,32%**. Native runner **238 + 387 malformed** (35 APK assertion). Python **13/13**. Yangi 9 Flutter testi mocked MethodChannel bilan Uzbek modal/no-forward, strict incomplete, heuristic false-positive, explicit confirm/cancel, settings navigation, default-off strict/alerts va alohida history clear’ni tekshiradi. 7 native notification policy assertion permission/consent/channel/risk/opt-out shartlarini mock bilan qoplaydi; bular real OS notification natijasi emas.

Dastlabki Flutter compile/lint va bitta eski folder testining scroll regressiyasi tuzatildi; yakuniy to‘liq Flutter suite o‘tdi. Kotlin Android build’dagi Intent.setClipData Unit-return xatosi tuzatildi. Native gate batch timeout’dan keyingi downgraded completeness’ni ham ishlatadi; strict qarori eski per-file verdict’ga tayanmaydi. Signature failure “verifier ishladi, integrity yaroqsiz” holati bo‘lib, verification complete va signature validity alohida talqin qilinadi.

4B: native runner **231 + 387 malformed** o‘tdi (28 yangi discovery/risk/gate). Mock launch callback orqali blocked no-forward, strict incomplete, auto-block off, explicit user approval va benign false-positive tekshirildi. Debug build muvaffaqiyatli. Bu Android installer ishga tushdi yoki boshqa ilovaning install’i bloklandi degan dalil emas.

2026-11-22. Baseline `1641653`. 4A: native runner yangi 17 risk/discovery assertion bilan **220 + 387 malformed** o‘tdi. Signature success/failure/unchecked, no findings, single heuristic, sensitive combination, incomplete, spoofed reputation va actual-format ajratish synthetic map bilan tekshirildi. Bu real Telegram/device sinovi emas. Flutter va Android adapter regressiyalari keyingi kichik bosqichlarda qayta bajariladi. PHASE 2 install/update, PHASE 3A 25-case, PHASE 3B native instrumentation va real Telegram notification ochiq qoladi.

# ShieldGuard V3.1 — PHASE 3B sinovlari

2026-11-22. `feature/shieldguard-v3-1`, baseline `02c8dc2`. `shieldguard-security` va `shieldguard-testing` qo‘llandi; release skill yuklanmadi. Quyidagilar shu bosqichda kuzatilgan natijalar.

| Tekshiruv | Natija |
| --- | --- |
| `flutter test test/folder_monitor_test.dart` | 7/7 |
| `flutter analyze` | No issues found |
| `flutter test --coverage` | 196/196; oldingi 189 saqlandi |
| `test/native/run_tests.ps1 -KotlinLib <Gradle 9.3.1/lib>` | 203 tekshiruv + 387 malformed input; 30 yangi folder holati |
| `python -m unittest discover -s backend` | 13/13 |
| Dart line coverage, `coverage/lcov.info` LH/LF yig‘indisi | 1134/1425 = 79,58% |
| `flutter build apk --debug` | Muvaffaqiyatli; yakuniy build 21,9 s |
| `:app:assembleDebugAndroidTest -PshieldTestRunner=uz.app.shieldguard.FolderMonitorInstrumentation` | BUILD SUCCESSFUL; runner install alohida rad etildi |
| Android16 API36 real SAF picker | O‘zimiz yaratgan Download ichidagi test papka tanlandi; grant lokal saqlandi |
| Android16 UI orqali manual scan, debug lokal summary bilan tasdiq | O‘zgarmagan 3 fayl: 0 scanned / 3 cached; o‘zgargan ZIP: 1 / 2; yangi PDF: 1 / 3; har safar partial=false, unverified=0 |
| Android16 force-stop → cold launch | Persisted root saqlandi; periodic 7201 waiting holatida qayta yaratildi; manual 0 scanned / 4 cached. Bu fizik reboot sinovi emas |
| Android16 real UI opt-out | Roots/cache/summary tozalandi, owned persisted grant yo‘q; 7201/7202 job’lari unknown. Faqat o‘zimiz yaratgan 4 benign fayl va bo‘sh test papkasi o‘chirildi |
| Android16 native folder instrumentation | **unverified**: test APK `INSTALL_FAILED_USER_RESTRICTED` / Install canceled by user; bypass qilinmadi |
| PHASE 3A kengaytirilgan 25-case E2E | **Ochiq, unverified**; PHASE 3B natijasiga qo‘shilmadi |

30 JVM holati metadata adapterlari va inspect callback mock bilan: yangi PDF/ZIP/APK, o‘zgargan/o‘zgarmagan fayl, duplicate document identity, empty folder, 256 metadata/8 analysis limiti, keyingi batch navbati, depth/cycle, denied/provider exception, disabled/cancel/mid-cancel, unknown va cached incomplete, zaif metadata, TTL/backward clock, per-file error va fake-clock timeout. Bu testlar Android persistable grant yoki real APK signing tekshiruvi emas. Mavjud parser/signature regressiyalari o‘zgarmadi.

7 Flutter testi mocked MethodChannel bilan default-off Uzbek UI, explicit folder selection, Telegramdan mustaqillik, opt-out tozalash, manual/cancel, revoke/partial counts va ID orqali removal’ni qoplaydi. Android scheduler, read-only grant, revoke, process recovery va opt-out uchun alohida native runner yozildi, ammo o‘rnatilmagani sabab uning assertion’lari o‘tdi deb ko‘rsatilmaydi. Yuqoridagi UI va lokal summary tekshiruvlari ushbu runnerdan mustaqil. Haqiqiy telefon reboot, tashqi permission revoke va low-battery OS scheduling hali unverified.

Qurilma helper’ining birinchi UI counter assertion’i o‘tmadi (scroll/selector); lokal summary scan tugaganini ko‘rsatdi. Helper explicit UI trigger + debug private summary tekshiruviga tuzatildi; xom URI/nom/cache chiqarilmaydi. Keyingi urinishda boshqa ilova faol bo‘lgani sabab to‘xtatildi; foydalanuvchi telefonni bo‘sh qoldirishini tasdiqlagach qayta bajarildi. Bu helper xatolari app scanner crash deb baholanmadi.

Benign sintetik plain PDF, readme ZIP va imzolangan hasCode=false APK fayl sifatida ishlatildi; APK execute/install qilinmadi. APK launcher export indikatori zararli hukm deb talqin qilinmaydi. Background interval aniq vaqtli kafolat emas. Incomplete natija safe emas; bloklangan DocumentProvider I/O darhol uzilishi kafolatlanmaydi. Batafsil: `FILE_MONITORING.md`.

Debug artifact: `build/app/outputs/flutter-apk/app-debug.apk`, 191116054 bytes, SHA-256 `255a5e47d62e7039a88ad6f5f1f72831fe6888fc4bd262d3c0e11f346a71c0e6`. APK Git’ga commit qilinmaydi. Yakuniy build queue-rejection/cancel generation guard’ini ham kompilyatsiya qildi va Android16’da muvaffaqiyatli o‘rnatildi; real SAF tekshiruvlari shu himoya qo‘shilishidan oldingi debug build’da bajarildi.

Quyida PHASE 3A va oldingi tarix o‘z holicha saqlangan; ularning davriga tegishli cheklovlar hozirgi implementatsiya bayonoti emas.

# ShieldGuard V3.1 — PHASE 3A sinovlari

2026-11-22. feature/shieldguard-v3-1, PHASE 2 baseline 5215543. shieldguard-security va shieldguard-testing qo‘llandi. Faqat file open/share; folder monitoring va PHASE 4–8 o‘zgartirilmadi.

| Tekshiruv | Shu bosqichdagi natija |
| --- | --- |
| flutter test test/file_share_test.dart | 5/5 o‘tdi |
| flutter analyze | No issues found |
| flutter test --coverage | 189/189; oldingi 184 saqlandi |
| test/native/run_tests.ps1 -KotlinLib <Gradle 9.3.1/lib> | 173 tekshiruv + 387 malformed input o‘tdi; 31 yangi shared-file holati |
| python -m unittest discover -s backend | 13/13 o‘tdi |
| flutter build apk --debug | Muvaffaqiyatli, yakuniy build 30,5 s |
| :app:assembleDebugAndroidTest -PshieldTestRunner=uz.app.shieldguard.FileShareInstrumentation | BUILD SUCCESSFUL |
| Android16 API36 dastlabki file open/share runner | 24 ta tekshiruv o‘tdi; quyidagi qamrovga qarang |
| Android16 kengaytirilgan 25-case runner qayta sinovi | Unverified: test APK qayta o‘rnatilishi INSTALL_FAILED_USER_RESTRICTED bilan rad etildi |
| Mavjud Android16 SAF PDF regressiyasi | O‘tdi: yangi umumiy scanner yo‘lida isolated PDF parser dalili UI’da ko‘rindi |

31 yangi JVM holati haqiqiy FileAnalyzer bilan benign PDF/raw format, synthetic APK ZIP (PackageManager/signature metadata callback mock), unknown format, malformed ZIP, oversized input, har bir fayl uchun error isolation, read flag/actual grant rad etilishi, scheme/URI invalid, normalized-scheme dedup, 8 fayl limit, cancellation va fake-clock batch timeout’ni tekshirdi. JVM APK case haqiqiy signature verification deb ko‘rsatilmaydi.

5 Flutter testi startup inbox, warm incoming, individual verdict, progress/cancel/busy, eski text share va o‘zbekcha natijani tekshiradi. MethodChannel bu testlarda mock. Pending fayllar avtomatik online reputatsiyaga yuborilmasligi bridge chaqiruvlarida tekshirildi.

## Qurilmada kuzatilgan qamrov va cheklov

Dastlab muvaffaqiyatli runner 24 ta real Android tekshiruvini bajardi. Cross-UID test provider’dan haqiqiy URI grant/revoke; bitta PDF; apksig tasdiqlagan o‘z benign test APK arxivi; VIEW, SEND(data/stream/ClipData), SEND_MULTIPLE; dedup; missing flag/grant; invalid file URI; metadata’da katta deb ko‘rsatilgan faylni ochmasdan rad etish; unknown/harmless format; malformed ZIP; missing+valid aralash batch; cancellation va text fallback tekshirildi. Shu running o‘zida real MainActivity cold-start VIEW PDF va warm SEND APK o‘zbekcha Flutter natijasida kuzatildi; eski activity destroyed bo‘lmagani ham tekshirildi.

Keyin multiple-file share’ning Activity UI’da 2-tartibli natijasini tekshiradigan 25-case runner tayyorlandi. Bu qayta urinishda fixture provider grant/bootstrap holati tufayli Unknown authority xatosi kuzatildi. Runner’ga boshlangandan keyin sender grant’ini kutadigan PHASE3A_READY_FOR_SENDER handshake qo‘shildi va test APK kompilyatsiya qilindi. Lekin yangi APK’ni qayta o‘rnatish INSTALL_FAILED_USER_RESTRICTED / Install canceled by user bilan rad etildi. Ushbu kengaytirilgan E2E qayta sinovi unverified; 25/25 deb ko‘rsatilmaydi. Dastlabki 24 ta kuzatilgan muvaffaqiyat asosiy debug APK A34A55... uchun amal qiladi. Physical policy o‘zgartirilmadi va rad etilgan install qayta majburlanmadi.

Dastlab Android testidagi MatrixCursor type inference va Intent.setClipData Unit qaytarishi bilan bog‘liq compile xatolari tuzatildi. AGP instrument runner’ni defaultConfig’dan tanlashi uchun shieldTestRunner property qo‘shildi; default Phase2 runner saqlandi. Alohida test processida target APK’ning Kotlin runtime’i bo‘lmagani crash log bilan aniqlandi: provider va sender Java/platform API’lariga o‘tkazildi. Bu fixture/test harness xatolari production parser muvaffaqiyati deb ko‘rsatilmaydi.

Test APK provider’i faqat o‘z private cache’idagi sintetik fayllarni beradi; read permission va per-URI grant tekshiriladi. APK fixture o‘z signed benign test APK arxivi, ishga tushirish/o‘rnatish buyrug‘i bilan skanerlanmagan. Haqiqiy malware ishlatilmadi. Test APK yakunda o‘chirildi; uning synthetic cache’i va grant’lari shu package bilan olib tashlandi. Asosiy debug ilova qurilmada qoldi.

PHASE 2 Android21 instrumentation, jonli Telegram, boshqa Android versiyalari, adversarial provider hang va production online API bu bosqichda qayta tekshirilmadi. Existing installed-app/Telegram JVM regressiyalari to‘liq o‘tdi. Provider blocking query/read uchun hard interruption kafolati yo‘q; timeout/cancellation cooperative, FILE_ANALYSIS.md ga qarang.

## Coverage, artefakt va qayta bajarish

coverage/lcov.info LH/LF = 1000/1279 = 78,19%; generated l10n kiradi. Kotlin/Android satr qamrovi bu foizga kirmaydi.

build/app/outputs/flutter-apk/app-debug.apk — 191103142 bayt.
SHA-256: a34a55f102cb6d6ffd3e192627626ab776cb31dbe20b12a885c93092b33f4b8d.
apksigner v2 verify o‘tdi. Source version 3.0.0+3 — development build, production release emas.

Production manifestga faqat SEND_MULTIPLE va content VIEW intent filter’lari qo‘shildi. Storage, QUERY_ALL_PACKAGES yoki Device Admin ruxsati qo‘shilmadi. No automatic upload/install/execute. Test-only provider/sender androidTest APK’da; production APK’da ular yo‘q.

~~~powershell
flutter analyze
flutter test --coverage
python -m unittest discover -s backend
powershell -NoProfile -ExecutionPolicy RemoteSigned -File test/native/run_tests.ps1 -KotlinLib <Gradle-lib>
flutter build apk --debug
.\android\gradlew.bat -p android :app:assembleDebugAndroidTest '-PshieldTestRunner=uz.app.shieldguard.FileShareInstrumentation'
~~~

Androidda ikkala APK’ni standart tasdiqlash bilan o‘rnating. Terminal A’da am instrument -w uz.app.shieldguard.test/uz.app.shieldguard.FileShareInstrumentation ni ishga tushiring. PHASE3A_READY_FOR_SENDER chiqqach, Terminal B’da am start -W -n uz.app.shieldguard.test/uz.app.shieldguard.FileShareTestSender ni ishga tushiring. Yakuniy expanded runner hali qurilmada tasdiqlanmagan; install policy ruxsat bermasa bypass qilmang. So‘ng faqat o‘zingiz o‘rnatgan uz.app.shieldguard.test test package’ini o‘chiring. PHASE 2 runner uchun shieldTestRunner parametrini bermang.

Quyidagi PHASE 2/1/V3 natijalari tarixiy baseline.

---

# ShieldGuard V3.1 — PHASE 2 sinovlari

2026-11-22. Windows, Flutter 3.47.6, Dart 3.13.5, JDK 17. feature/shieldguard-v3-1, PHASE 1 baseline 63ade45. shieldguard-security va shieldguard-testing qo‘llandi; release skill ishlatilmadi.

| Buyruq / ssenariy | Shu bosqichda kuzatilgan natija |
| --- | --- |
| flutter test test/installed_monitor_test.dart | Dastlabki 4/4 o‘tdi; keyin report localization testi qo‘shildi |
| flutter analyze | No issues found |
| flutter test --coverage | 184/184; oldingi 179 test saqlandi |
| test/native/run_tests.ps1 -KotlinLib <Gradle 9.3.1/lib> | 142 tekshiruv + 387 malformed input o‘tdi; 27 yangi installed-app policy holati |
| python -m unittest discover -s backend | 13/13 o‘tdi |
| flutter build apk --debug | Muvaffaqiyatli, yakuniy incremental build 12,2 s |
| Gradle :app:assembleDebugAndroidTest | BUILD SUCCESSFUL |
| Android16 API36 real instrumentation | 21/21 o‘tdi |
| Android16 isolated PDF SAF regressiyasi | O‘tdi: alohida parser process dalili UI’da ko‘rindi |
| Install/update fixture E2E | Unverified: fixture install INSTALL_FAILED_USER_RESTRICTED bilan rad etildi, update bajarilmadi |
| Automatic high-risk alert E2E | Unverified: riskli permission kombinatsiyali kodsiz fixture o‘rnatilmadi |

JVM testlari PACKAGE_ADDED, replacing ADDED’ni tashlash, PACKAGE_REPLACED, noto‘g‘ri event/nom, yangi/yangilangan paket rejasi, monitoring disabled, visibility bo‘sh natija, takroriy event, batch limit, benign/SMS+internet/exported false-positive nazorati, sezgir kombinatsiya, notification denied va incomplete findings’ni tekshiradi. Bu OS broadcast yetkazilishining real sinovi emas.

5 ta yangi Flutter test: mustaqil opt-in/out, lokal scheduling tugmasi, metadata-only verdict, unavailable verdict va o‘zbekcha report qamrovi. Bridge native metodi widget testlarda mock, live Android deb ko‘rsatilmaydi.

21 Android tekshiruvi haqiqiy PackageManager’da o‘z APK’sining paket/signing ma’lumotlari, katta APK uchun metadata-only va signature-unchecked, absent package va cancellation’ni tekshirdi. JobScheduler rejalash, dedup queue, opt-out va keshni o‘chirish tasdiqlandi. O‘z APK’siga yo‘naltirilgan haqiqiy fon job’i OS orqali ishga tushdi, report yozdi va keyin opt-out uni tozaladi. Boshqa ilovalarning APK kontenti tahlil qilinmadi; test faqat timestamp baseline’ni o‘qidi. Hech qanday force-job yoki policy bypass ishlatilmadi.

## Kuzatilgan xatolar va cheklovlar

Dastlab widget tap pastki navigatsiyaga to‘g‘ri keldi; test scroll alignment tuzatildi. Uchta analyze ogohlantirishi tuzatildi. Dastlab custom instrumentation start chaqiruvi yetishmadi; test runner tuzatilib, so‘ng 21 tekshiruv o‘tdi.

Oldingi PHASE 1 o‘rnatish rad etilishi dastur xatosi deb olinmadi. Qurilmadagi cheklov yozuvlari read-only tekshirildi; primary-user uchun barcha restriction’lar faol degan xulosa qilinmadi. Foydalanuvchi tasdiqlashga tayyorligini bildirdi, ShieldGuard va test APK keyin muvaffaqiyatli o‘rnatildi. hasCode=false sintetik fixture1 esa INSTALL_FAILED_USER_RESTRICTED / Install canceled by user bilan rad etildi. Kutayotgan event runner timeout (IllegalStateException) bilan yakunlandi va finally monitoringni o‘chirib keshni tozaladi. Bu test muvaffaqiyat deb hisoblanmaydi; fixture qayta majburlanmadi, policy o‘zgartirilmadi, fixture2 o‘rnatilmadi.

Faqat kodsiz, o‘zimiz yaratgan benign fixture builder mavjud. Haqiqiy shubhali APK o‘rnatilmadi yoki ishga tushirilmadi. Fixture qurilmada yo‘qligi pm path bilan tasdiqlandi. O‘z androidTest APK’si sinovdan keyin o‘chirildi; ikkala monitoring job’i unknown/not found, ya’ni opt-out’dan keyin qolmadi. ShieldGuard debug APK qurilmada qoldi; monitoring standart holatda o‘chiq.

Jonli Telegram, Google/Web Risk yoki hash production API, signing lineage, Android13–15 runtime, natural reboot/Doze, broad package visibility, katta install storm va notification high-risk payload device tekshiruvi bu bosqichda bajarilmadi. Python adapterlari faqat mock bilan tekshirildi. PHASE 3–8 implementatsiya qilinmadi.

## Coverage va artefakt

coverage/lcov.info LH/LF = 958/1260 = 76,03%; generated l10n kiradi, Kotlin va Android satr qamrovi kirmaydi. Precision/recall va statistik false-positive rate uchun labeled real corpus yo‘q.

Debug APK: build/app/outputs/flutter-apk/app-debug.apk, 191101723 bayt.
SHA-256: 6c6735790418cc336e83144a413550a41042b83d35c5f1fdbdd72ebb44836c58.
apksigner v2 verify o‘tdi. Development source version 3.0.0+3; production release deb ko‘rsatilmaydi.

Manifest audit: INTERNET, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED va AndroidX ichki signature receiver permission. QUERY_ALL_PACKAGES, Device Admin, SMS read yoki Accessibility runtime permission ShieldGuard’ga qo‘shilmadi. Yangi RECEIVE_BOOT_COMPLETED faqat persisted job uchun. Installed-app ma’lumotlari tarmoqqa yuborilmaydi.

Arxitektura/chegaralar va qayta bajarish: INSTALLED_APP_PROTECTION.md. Quyidagi PHASE 1 va V3 natijalari tarixiy baseline, hozirgi artefakt sifatida qabul qilinmaydi.

---

# ShieldGuard V3.1 — PHASE 1 sinovlari

2026-11-22, Windows, Flutter 3.47.6 / Dart 3.13.5 / JDK 17. Branch: feature/shieldguard-v3-1. Faqat Telegram anti-phishing bosqichi; 2–8 bosqichlar bajarilmadi. shieldguard-security va shieldguard-testing skill’lari qo‘llandi.

| Buyruq / tekshiruv | Shu bosqichda kuzatilgan natija |
| --- | --- |
| flutter test test/engine_test.dart test/telegram_phishing_test.dart | Dastlab 116/116 o‘tdi; ikki port ssenariysi qo‘shilgach telegram_phishing_test.dart 58/58 o‘tdi |
| flutter analyze | No issues found; avval test nomidagi bitta interpolation lint tuzatildi |
| flutter test --coverage | 179/179 o‘tdi |
| test/native/run_tests.ps1 -KotlinLib <Gradle 9.3.1/lib> | Oldingi 54 + yangi 54 umumiy ssenariy + 7 bound/cooldown = 115 tekshiruv, 387 malformed input o‘tdi |
| flutter build apk --debug | Muvaffaqiyatli, yakuniy incremental build 19,6 s; dastlabki 69,7 s build’da SDK XML versiyasi haqida ogohlantirish bor |
| Android 16 ACTION_SEND | Bajarilmadi: adb install -r INSTALL_FAILED_USER_RESTRICTED (Install canceled by user) bilan rad etildi; yangi build uchun share testi ishga tushmadi |

Noto‘g‘ri Unicode-host portlari (65536 va bad) ikkala detector’da ham riskli link sifatida baholanmasligi qo‘shimcha regressiyada tekshirildi.

Yangi testlar: test/fixtures/telegram_phishing.tsv dagi 54 benign/sintetik xabarni Dart va Kotlin bir xil finding ID hamda ball bo‘yicha tekshiradi. test/telegram_phishing_test.dart yana 4 ta extraction, dedup va lokalizatsiya holatini tekshiradi. Native testlar 8192 belgili limit, takroriy domen, 30 soniyalik cooldown va 5 daqiqalik dedup chegaralarini tekshiradi. Mavjud native fayl regressiyalari ham qayta o‘tdi.

Coverage: coverage/lcov.info dagi LH/LF yig‘indisi 899/1188 = 75,67%; generated l10n ham kiradi. Kotlin/Android qamrovi bu foizga kirmaydi. Bu yorliqlangan real malware korpusi emas; precision/recall da’vo qilinmaydi.

Yangi debug APK SHA-256: 54f6f8ac2e4f706287faf7f033ba37c8a777f5c6ffa4fce7a8f64ff2e4a24a2a. APK Git’ga kiritilmaydi; source version hozircha 3.0.0+3, bu V3.1 PHASE 1 development build’i.

Jonli Telegram akkaunti/bildirishnomasi, notification ruxsatini qayta yoqish/revoke qilish, Android integration_test to‘plami, Python gateway, SAF va release bu bosqichda qayta sinovdan o‘tkazilmadi. Quyidagi V3 natijalari tarixiy baseline, yangi branch natijalari emas. Eski artefakt izlari tarixiy V3 build’lariga tegishli.

---

# ShieldGuard V3 sinov hisoboti

2026-11-22. Windows, Flutter 3.47.6, Dart 3.13.5, JDK 17. V2 boshlang‘ich regressiya 95/95 o‘tdi. Bu hujjat V3 natijalarini ajratadi; V2 artefakt izlari Git tarixida.

| To‘plam | Tasdiqlangan natija |
| --- | --- |
| Flutter unit/widget/HTTP mock | 121/121; v3-tests.log |
| Flutter analyze | No issues found |
| Kotlin mavjud fayl / notification | 17 + 12 tekshiruv |
| Kotlin advanced | 16 holat + 129 malformed input |
| Kotlin V3 | 9 assertion + 258 malformed input |
| Python | 13/13; consent, quota, hash response va error mocklari |
| Android 16 integratsiya | 3/3; SQLite cache/consent revoke, theme va typed bridge |
| Dart coverage | 890/1179 satr = 75,49%; generated l10n ham kiradi |
| Debug APK | Kompilyatsiya va apksigner v2 verification o‘tdi |
| Release APK / AAB | R8 bilan ikkalasi kompilyatsiya bo‘ldi; imzosiz |

Android 16 integratsiya yangi isolated PDF xizmatini, hash rozilik UI’sini yoki ko‘p faylli picker yo‘lini tekshirmaydi. Widget/HTTP mocklar hash rozilik, bekor qilish va response holatlarini tekshiradi. Jonli API kaliti bilan so‘rov bajarilmadi. Jonli Telegram akkaunt sinovi bajarilmadi.

## Qurilma fixture tekshiruvi

SAF avtomatlashtirishida UI selector va Downloads provider muammolari, ADB uzilishlari kuzatildi. 6320f75b API31 Android12; hqyd9xx4t8cekf7p API36 Android16. Ularni bir xil qurilma deb hisoblamaymiz. Keyin SAF skripti multi-select uchun long-press va Open tasdig‘iga moslandi. Android16 haqiqiy qurilma va Android17 API37 test emulyatorida har birida uchala ssenariy o‘tdi: isolated PDF obyekt tahlili, valid APK imzosini qabul qilish, o‘zgartirilgan APK imzosini rad etish — jami 6/6. Bu fixture APK’lar o‘rnatilmadi, faqat o‘qildi. Avvalgi UI xatolari muvaffaqiyat deb hisoblanmadi.

475-byte to‘g‘ri xref/object tuzilishli sintetik PDF yaratildi. Imzo fixture’lari faqat o‘z debug arxivimizdan olingan benign kontent bilan tayyorlandi: host apksigner valid v2/v3 ni qabul qildi, qo‘shimcha asset bilan o‘zgartirilgan nusxani rad etdi. Fixture APK’lar o‘rnatilmadi/bajarilmadi va Git’ga kiritilmaydi.

DEX/ELF malformed bounds, split paket/sertifikat mismatch va unchecked, duplicate ZIP, kengaytma/bidi aldovi hamda resource limitlar sintetik testlar bilan tekshirildi. Bu haqiqiy malware korpusi emas. To‘y arxivi / OneID asl namunasi berilmagan; precision, recall yoki statistik false-positive rate hisoblanmagan.

## V3 artefaktlari

| Fayl | Bayt | SHA-256 |
| --- | --- | --- |
| build/app/outputs/flutter-apk/app-debug.apk | 191093075 | 6f2d0070d9799b50c227f22707e424896a6360e8bb24bcb482511c02b59daa3e |
| build/app/outputs/flutter-apk/app-release.apk | 60932835 | b4bcb0c1c5e99fa8e3fbe8600b99ffccb2c23b540494a449c18cdf74b1586ad9 |
| build/app/outputs/bundle/release/app-release.aab | 59609815 | 4e93b96e3e55f3f7617d0014d575e062838176f7896b4688749fb9ddd2dff891 |

zipalign -c -P 16 4 release APK uchun exit 0 qaytardi; jarsigner AAB uchun jar is unsigned qaytardi. Bu Play pre-launch yoki minified release runtime sinovini almashtirmaydi.

Versiya 3.0.0+3. Debug imzosi Android public debug keystore; production imzo emas. Release uchun apksigner DOES NOT VERIFY — kutilgan natija. Haqiqiy signing credential yo‘q. SHIELD_ALLOW_UNSIGNED=true faqat kompilyatsiya auditi uchun ishlatildi; odatiy signed release yo‘li kalitsiz guard bilan rad etiladi. APK/AAB Play’ga yuborilmadi.

PDFBox qo‘shilgach R8 optional JP2Decoder yo‘qligi uchun to‘xtadi. Rasmiy JPXFilter source bu kutubxonani reflection bilan optional tekshiradi. Parser rasm render qilmaydi; proguard-rules.pro faqat shu bitta class uchun dontwarn qo‘shadi. Shundan keyin release APK 105,9s va AAB 39,6s da yig‘ildi. Bu to‘liq dependency xavfsizlik auditi emas.

## Qayta bajarish

Buyruqlarni ketma-ket bajaring. Flutter integration/debug va release build’larini parallel bajarmang: generated plugin registrant o‘zgaradi.

~~~powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test --coverage
python -m unittest discover -s backend
powershell -NoProfile -ExecutionPolicy RemoteSigned -File test/native/run_tests.ps1
flutter test integration_test -d <qurilma-id>
flutter build apk --debug
~~~

Kotlinc bo‘lmasa run_tests.ps1 -KotlinLib <Gradle Kotlin compiler lib> ishlaydi. integration_test/saf_smoke.ps1 -Serial <id> -FixturePath <benign-file> -ExpectedText <regex> real SAF orqali tekshiradi. Skript faqat o‘zi yaratgan UUID fayllarni o‘chiradi. Haqiqiy zararli fayllar ishlatilmadi.

Store uchun 1080×2400 o‘lchamdagi 2 haqiqiy UI skrinshoti toza API37 emulyatordan olindi; ikkinchisi sintetik tampered APK natijasidir. To‘liq screenshot provenance store/README.md da. Android12 qurilmasi uzilgani sabab qo‘lda yuborilgan benign /sdcard/Download/ShieldGuard-validation.pdf (475 bayt) keyingi ulanishda tozalanishi kerak; UUID skript fixture’lari finally orqali o‘chirildi.
