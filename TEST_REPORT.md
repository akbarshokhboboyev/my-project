# ShieldGuard V2 sinov hisoboti

2026-11-22. Windows, Flutter 3.47.6, Dart 3.13.5, JDK 17. Flutter doctor va analyze --suggestions qayta bajarildi. Java/Gradle/AGP/Kotlin mosligi tasdiqlandi. AGP SDK XML haqida ogohlantirish chiqardi. CMake 3.22.1 release kompilyatsiyasi uchun SDK orqali o‘rnatildi.

## Regressiya va yangi sinovlar

| To‘plam | Natija |
| --- | --- |
| Boshlang‘ich Flutter regressiyasi | 64/64 qayta o‘tdi |
| Yakuniy Flutter unit/widget/HTTP mock | 95/95 o‘tdi |
| Kotlin mavjud fayl sinovlari | 17 ta o‘tdi |
| Kotlin mavjud bildirishnoma qoidalari | 12 ta o‘tdi |
| Yangi Kotlin tekshiruvlari | 16 ta aniq holat va 129 benign malformed input o‘tdi |
| Python gateway va response testlari | 7/7 o‘tdi |
| Android 16 integratsiya | 3/3 o‘tdi |
| Flutter analyze | Xato yoki lint topilmadi |
| ACTION_SEND havola | Yakuniy debug qurilmada kutilgan 67/100 natija ko‘rsatdi |
| SAF PDF | Yakuniy debug qurilmada kutilgan 45/100 va SHA-256 ko‘rsatdi |

Yangi online testlar rozilik bo‘lmaganda so‘rov yubormaslik, moslik, moslik yo‘qligi, kesh va expiry, backoff, parallel so‘rovni birlashtirish, HTTP 429/503/302, noto‘g‘ri JSON, hajm chegarasi va SocketException holatlarini tekshiradi. Tarmoq javoblari sun’iy HttpClient va lokal mock HTTP server orqali berilgan. Google Web Risk’ka haqiqiy kalitli so‘rov bajarilmadi.

Android integratsiyasi SQLite reputatsiya keshining saqlanishi, online consent qaytarilganda keshni tozalash, mavzu saqlanishi hamda holat va tarix turlarini tekshirdi. Bu testlar jonli Telegram xabarini tekshirish o‘rnini bosmaydi. Test qurilmasida org.telegram.messenger paketi borligi pm list packages bilan tasdiqlandi.

SAF skriptining birinchi urinishida Android UI daraxti vaqtincha mavjud bo‘lmadi. Skriptga ekran uyg‘otish va cheklangan qayta urinish qo‘shilib, test qayta o‘tdi. Faqat sun’iy PDF qurilmaga ko‘chirildi va sinov yakunida o‘chirildi.

## Qamrov

coverage/lcov.info dagi LF va LH yig‘indisi 751/998, ya’ni 75,3 foiz. Boshlang‘ich 74,8 foizdan yuqori. Avtomatik yaratilgan strings.dart va strings_uz.dart chiqarilganda 670/827, ya’ni 81,0 foiz. Bu satr qamrovi. Kotlin, Python va Android ruxsatlarining qamrovi ushbu foizga kirmaydi.

## Qayta bajarish

```powershell
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze --suggestions
flutter analyze
flutter test --coverage
python -m unittest discover -s backend
powershell -NoProfile -ExecutionPolicy RemoteSigned -File test/native/run_tests.ps1
flutter test integration_test -d <qurilma-id>
flutter build apk --debug
```

Kotlin skripti standart holatda kotlinc talab qiladi. Kotlinc o‘rnatilmagan ushbu muhitda Gradle distributividagi Kotlin 2.2.21 kompilyator kutubxonasi -KotlinLib parametri bilan ishlatildi. Android build o‘zining Kotlin 2.4.0 konfiguratsiyasini saqladi.

Havola va fayl UI sinovlari integration_test/share_smoke.ps1 va integration_test/saf_smoke.ps1 orqali bajariladi. Qurilma ulangan va ochilgan bo‘lishi kerak.

## Artefaktlar

Yakuniy debug APK build/app/outputs/flutter-apk/app-debug.apk manzilida. Imzo Android apksigner verify orqali v2 sxemada tasdiqlandi. Hajmi 203924572 bayt. SHA-256 izi 6b5fc065103475e5abf38a17f209a125d054016aa7611d9cb368d8166e5a1a07.

Oddiy flutter build apk --release va flutter build appbundle --release buyruqlari haqiqiy signing credential yo‘qligini aniq xato bilan ko‘rsatdi. Signed release mavjud emas. Imzosiz release kompilyatsiya auditi alohida -PshieldAllowUnsigned=true bilan bajariladi.

Imzosiz auditda Gradle :app:assembleRelease va :app:bundleRelease -PshieldAllowUnsigned=true bilan R8/lint bosqichlaridan o‘tib BUILD SUCCESSFUL qaytardi. API 26/36, versiya 2.0.0+2 va uch ABI aapt bilan tasdiqlandi. Release manifestida application-debuggable belgisi yo‘q. Internet va bildirishnoma ruxsatlari hamda AndroidX ichki receiver ruxsati bor.

| Artefakt | Bayt | SHA-256 |
| --- | --- | --- |
| build/app/outputs/apk/release/app-release-unsigned.apk | 55481883 | 871e9ca37efa676d0de020eaa3c43b0c9d6400206b19861db6bd5f229108d161 |
| build/app/outputs/bundle/release/app-release.aab | 53897185 | 0f72bfef76a1620f19967f45ac97a333e64dd5a1975844af0ea3bdc80f2fba51 |

apksigner release uchun DOES NOT VERIFY, jarsigner AAB uchun jar is unsigned qaytardi. Bu kutilgan natija. Imzosiz release qurilmaga o‘rnatilmadi va Play’ga yuborilmadi.

Uch ABI’dagi oltita ELF kutubxonasining LOAD alignment qiymatlari kamida 16384 ekanligi statik tekshirildi. zipalign -c -P 16 -v 4 imzosiz APK uchun Verification successful qaytardi. Bu qurilmada release runtime sinovi yoki Play pre-launch hisobotini almashtirmaydi.

Android 16’da yakuniy debug APK uchun ACTION_SEND havola va SAF PDF sinovlari qayta o‘tdi. Sun’iy sinov ogohlantirishi tizimda ko‘rindi va bosilganda ShieldGuard ochildi. Mavjud listener ruxsati vaqtincha bekor qilinganda xizmat uzildi, asl holatiga qaytarilganda xizmat ulandi. Ushbu sinov haqiqiy Telegram bildirishnomasini yaratmagan.

Jonli Telegram phishing bildirishnomasi, Android 13–15 qurilmalari, qurilmani qayta yuklash va yashirilgan OTP holatlari bajarilmagan. PDF to‘liq parseri va native APK imzo verifikatori yo‘q. Tashqi zaiflik bazasi bo‘yicha to‘liq dependency auditi bajarilmagan.
