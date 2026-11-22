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
