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
