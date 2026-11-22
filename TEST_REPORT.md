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
