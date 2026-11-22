# ShieldGuard PHASE 4 — APK qo‘riqchi

2026-11-22, `feature/shieldguard-v3-1`, boshlang‘ich commit `1641653`.

## 4A — discovery va risk policy

`ApkDiscoveryCoordinator` va `ApkRiskPolicy` mavjud `NativeFileInspector` natijasini boyitadi. PHASE 3A ACTION_SEND/VIEW/SEND_MULTIPLE va PHASE 3B authorized folder scanner avtomatik shu yo‘ldan o‘tadi; mavjud parserlar, limitlar va ruxsat tekshiruvlari saqlanadi. Haqiqiy APK formati va faqat `.apk` deb nomlangan boshqa format ajratiladi. Double extension mavjud FileAnalyzer qoidasi bilan tekshiriladi.

Risk balli, confidence, completeness va evidence alohida. Signature failure — kuchli integrity shubhasi, malware tasdig‘i emas. Bitta permission yoki exported launcher heuristic xolos. `confirmedHighConfidenceThreat` faqat ishonchli adapter orqali alohida berilgan known-malicious reputation dalili uchun; jonli provider avtomatik ulanmagan. Online hash tekshiruvi avvalgi alohida consent yo‘lida qoladi. Imzo muvaffaqiyati zararsizlik kafolati emas. Trusted Developer Registry mavjud cheklovlari saqlanadi; yangi production trust root yoki malware corpus yo‘q.

Telegram manbasi Intent nomidan ishonchli tasdiqlanmaydi. Boshqa ilovaning private storage’i yoki unga tegishli Downloads’dagi non-media APK uchun universal MediaStore kirishi yo‘q: foydalanuvchi authorized SAF tree yoki share/open orqali ruxsat beradi. Papka tekshiruvi periodic, real-time emas. Fayl o‘qilmasa natija unknown/incomplete. Hech qanday avtomatik upload/execute/install yo‘q.

4A dalil: 17 yangi pure Kotlin risk/discovery assertion, jami 220 + 387 malformed input o‘tdi.

## 4B — real forwarding boundary

`AutomaticBlockEngine` strong/confirmed dalilda auto-block yoqilgan bo‘lsa `blockedByShieldGuard`, strict incomplete holatda `scanIncomplete` beradi. So‘nggi holat malware tasdig‘i emas. Auto-block o‘chiq bo‘lsa ogohlantirish saqlanadi. Gate explicit tasdiqsiz hech qanday launch callback chaqirmaydi.

`InstallProtectionCoordinator` faqat foreground file-open/share yo‘lida skanerlangan byte’lardan private snapshot oladi; original URI qayta ochilib boshqa byte’lar forward qilinmaydi. Random token, ko‘pi bilan 8 × 32 MiB snapshot, 10 daqiqa expiry; sender nomi yoki URI saqlanmaydi. Forward oldidan SHA-256 qayta tekshiriladi, expiry/generation/current settings yana tekshiriladi. Cancel snapshotlarni bekor qiladi. Faqat o‘z cache nusxalari o‘chiriladi. Process o‘lsa tokenlar amal qilmaydi; orphan cache keyingi cleanup’da tozalanadi, bu diskdagi qoldiqni aniq vaqtda o‘chirish kafolati emas.

4B dalil: 28 discovery/risk/gate assertion, jami 231 + 387 malformed o‘tdi. Blocked callback count=0, user approval bo‘lmasa count=0, benign explicit approval’da count=1. Bu mock callback launch dalili, haqiqiy Android installer E2E emas. Native Android kod debug build’da kompilyatsiya qilindi. Native gate’ni explicit Flutter tugmasi bilan ochish, dialog va notification 4C’da qo‘shiladi.

Android manbalari: [shared storage](https://developer.android.com/training/data-storage/shared/media), [SAF](https://developer.android.com/training/data-storage/shared/documents-files). Global install veto yoki Android Device Owner provisioning yo‘q.

## 4C — foydalanuvchi oqimi va privacy

Himoya ekranida auto-block (default yoqilgan, faqat ShieldGuard gate), strict (default o‘chiq), authorized folder APK bildirishnomalari (default o‘chiq, alohida opt-in) va Android unknown-source settings tugmasi mavjud. Android sozlamasini foydalanuvchi o‘zi o‘zgartiradi; Telegram ruxsati holati o‘qildi deb ko‘rsatilmaydi. Boshqa manbalar ham mavjudligi va yuklab olish to‘xtatilmasligi tushuntiriladi.

Foreground strong block modalida o‘zbekcha sabab, confidence, gate chegarasi, tafsilot/yopish/tavsiya bor. Strict incomplete boshqa sarlavha bilan ehtiyot chorasi sifatida ko‘rsatiladi. Background lifecycle’da Flutter modal chiqarilmaydi; faol bo‘lganda ko‘rsatilishi mumkin. Native background folder topilmasi `warningOnly`, hech qachon yolg‘on “bloklandi” emas. Notification faqat opt-in + POST_NOTIFICATIONS + system/channel ruxsati bilan; HIGH channel heads-up imkonini beradi, ko‘rinishi kafolatlanmaydi. Public/lock-screen matnida fayl nomi/URI yo‘q. Tap immutable proof bilan faqat lokal tarix tafsilotini ochadi; background Activity launch yo‘q.

`BlockedThreatHistory`: bounded 50 lokal yozuv, 10 daqiqa dedup; risk/method/severity/confidence/completeness/outcome/time/advice va indikator kodlari. Xom fayl, nom, URI, Telegram xabari yoki OTP saqlanmaydi. Alohida clear mavjud. Avto-bloklashni o‘chirish APK strict/alerts, pending snapshot va APK tarixini tozalaydi; boshqa himoya modullari mustaqil. Faqat scanner yaratgan private snapshotlar tozalanadi, original fayllar o‘chirilmaydi.

Tashqi ochish uchun alohida tasdiqdan so‘ng FileProvider’ning faqat `apk-forward/` private nusxasiga vaqtinchalik read grant bilan Android chooser ochiladi; o‘z Activity’si chiqarib tashlanadi. Outcome `warningOnly` va `handoffRequested` — install yoki installer muvaffaqiyati emas. `blockedByAndroid` faqat launch Android SecurityException bilan rad etilganda yoziladi. Boshqa ilovadan bevosita install `notIntercepted` doirasida; uni veto qiluvchi hook qo‘shilmagan. `REQUEST_INSTALL_PACKAGES`, PackageInstaller session yoki ACTION_INSTALL_PACKAGE ishlatilmaydi: ShieldGuard installer emas, ayrim Android handlerlari ushbu APK ochishni rad etishi mumkin. Bu ruxsatni chetlab o‘tish yo‘li emas. [Google Play cheklovi](https://support.google.com/googleplay/android-developer/answer/12085295).

FileProvider exported=false, grantUriPermissions=true va bitta tor cache-path; global storage, overlay, accessibility, fullscreen intent, Device Admin yoki yangi permission yo‘q. `shieldguard-release` faqat shu manifest/Play auditida qo‘llandi; production signing/release/Play upload bajarilmadi. Enterprise DO/PO alohida boshqariladigan provisioning va tegishli user restriction vakolatlarini talab qiladi; consumer rejimga qo‘shilmadi va qurilma provision qilinmadi.

4C dalil: maqsadli Flutter 21/21, to‘liq Flutter 205/205; analyze toza; Dart line coverage 1318/1641 (80,32%); native 238 + 387 malformed (35 yangi APK assertion); Python 13/13. Android va real notification natijasi 4D’da alohida qayd qilinadi. Reputation testi mock, precision/recall da’vosi yo‘q.

## 4D — Android16 dalillari va ochiq tekshiruvlar

API36 qurilmada yakuniy debug APK o‘rnatildi. `ApkGuardInstrumentation` va synthetic provider test APK’si BUILD SUCCESSFUL (7 s), ammo uning install’i `INSTALL_FAILED_USER_RESTRICTED / Install canceled by user` bilan rad etildi. Runner **ishga tushmadi**; uning snapshot mutation, expiry/generation, limit, duplicate va native callback assertion’lari real device’da o‘tdi deb berilmaydi. Qayta majburlash yoki siyosat bypass yo‘q.

Instrumentation’dan mustaqil, haqiqiy DocumentsUI/SAF va Flutter UI orqali:

- O‘zimizning imzolangan hasCode=false APK (DEX/ELF yo‘q) ZIP sifatida qayta yozilib, signing block buzildi. U faqat fayl sifatida o‘qildi; execute/install qilinmadi. Native natija `signatureFailed`, `strongSuspicion`, high confidence, complete=true; o‘zbekcha `APK BLOKLANDI` modal va lokal `blockedByShieldGuard` qayd etildi. Bu integrity xavfi, real malware tasdig‘i emas.
- Asl benign APK uchun faqat exported launcher indikatori (15 ball), `heuristicWarning / warningOnly`, blocking modal yo‘q. Host apksigner v2/v3 imzosini tasdiqladi. Foydalanuvchi tasdig‘iga teng UI action’dan so‘ng native hash validation + tor FileProvider orqali Android `com.android.intentresolver.ChooserActivity` ochildi. Installer tanlanmadi; install natijasi da’vo qilinmaydi.
- Alohida, faqat o‘zimiz yaratgan SAF test papkada 2 kodsiz APK: JobScheduler manual job HOME ekraniga o‘tilgandan keyin 2 scanned/0 cached, partial=false, unverified=0. APK alert consent va real POST_NOTIFICATIONS granted bo‘lganda OS notification key `...|uz.app.shieldguard|4|apk-guard|...` qayd etildi. Background outcome `warningOnly`, install bloklandi emas. Tabiiy 15-daqiqalik periodic ishga tushish bu sinovda kutilmadi.
- Faqat o‘z app’imizning POST_NOTIFICATIONS ruxsati test uchun vaqtincha revoke qilindi; own APK o‘zgartirildi. 1 scanned/1 cached, complete coverage; real permission denied va APK notification yo‘qligi tasdiqlandi. Oldingi granted ruxsati keyin qaytarildi. Bu test amali production kodida yo‘q.
- Real settings tugmasi `com.android.settings.Settings$ManageExternalSourcesActivity` oynasini ochdi. Hech qaysi install-source sozlamasi o‘zgartirilmadi yoki tekshirildi deb ko‘rsatilmadi.
- Root removal va APK opt-out/on orqali test grant, root/cache/summary/history/snapshot/alerts tozalandi; auto-block default yoqilgan, strict/alerts o‘chiq holat tiklandi. Persistable read grant olib tashlangach system picker’ning vaqtinchalik Activity grant’i process tugaguncha qolishi kuzatildi; force-stop/cold-launch’dan keyin u ham yo‘q. Faqat owned 2 APK va bo‘sh UUID test papkasi o‘chirildi.

4D hardening: scan boshidagi generation staging’gacha uzatiladi, shuning uchun opt-out’dan oldingi ish qayta token chiqara olmaydi. Disk cap consumed/orphan snapshotlarni ham sanaydi; bitta bounded copy permit, 8 retained snapshot (bitta copy va scanner temp’i vaqtincha qo‘shimcha), monotonic token TTL. Failed revalidation oldingi validation flag’ini bekor qiladi. Batch timeout final completeness native gate’ga qayta qo‘llanadi. Bu maxsus failure-path assertion’lari test runner’da yozilib kompilyatsiya qilindi, lekin runner o‘rnatilmagani uchun device darajasida **unverified**.

Qayta bajarish: `flutter test test/apk_guard_test.dart`, `flutter analyze`, `flutter test --coverage`, native `run_tests.ps1 -KotlinLib <Gradle/lib>`, Python suite; `flutter build apk --debug`. Android runner build: android katalogida `./gradlew.bat :app:assembleDebugAndroidTest '-PshieldTestRunner=uz.app.shieldguard.ApkGuardInstrumentation'`. O‘rnatishga ruxsat bo‘lsa, test APK’dagi FileShareTestSender owner grant’ini beradi va `adb shell am instrument -w uz.app.shieldguard.test/uz.app.shieldguard.ApkGuardInstrumentation` ishlaydi. Runner mavjud user APK history bo‘lsa uni tozalashga urinmaydi; faqat o‘z fixture’larini tozalaydi. `-e notificationsOnly true` notification-only synthetic mode. Test APK install rad etilsa runner’ni muvaffaqiyatli deb hisoblamang.

Debug artifact `build/app/outputs/flutter-apk/app-debug.apk`: 191135457 bytes; SHA-256 `31c3878f3265e30771b45a125841cde7276c5da8a3131213a1ff7e5cc081b4fe`. Debug v2 imzo verifies. Yangi sensitive permission yo‘q; androidx ichki non-exported receiver permission’i bundan mustasno. Release/Play publish yoki yangi production signing identity yaratilmagan.

Ochiq: 4D native runner, tabiiy periodic/low-battery/reboot adversarial scheduling; haqiqiy reputation credential/provider va production developer trust roots; labeled malware corpus. PHASE 2 install/update, PHASE 3A 25-case, PHASE 3B native instrumentation, real Telegram notification oldingi holicha ochiq. Haqiqiy Telegram sender sinovi sifatida SAF fixture ko‘rsatilmaydi. PHASE 5–8 implementatsiya qilinmadi.
