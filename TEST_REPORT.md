# Sinov hisoboti

Sinov muhiti Windows 11, Flutter 3.47.6, Dart 3.13.5, JDK 17.

- `flutter analyze --suggestions` Java, Gradle 9.3.1, AGP 9.1.0 va Kotlin konfiguratsiyasini mos deb topdi. Tekshiruv usuli [Flutter rasmiy qo‘llanmasi](https://docs.flutter.dev/release/breaking-changes/android-java-gradle-migration-guide) bilan solishtirildi.
- Mahalliy Dart va Flutter sinovlari havola, firibgarlik xabarlari, ball chegaralari va asosiy ekranlarni qamrab oladi. Xavfsiz sun’iy matnlar va namuna domenlari ishlatildi.
- `flutter analyze` xato topmadi. `flutter test --coverage` barcha 64 ta testdan o‘tdi. Dart satr qamrovi 583/779 (74,8 foiz), jumladan avtomatik yaratilgan lokalizatsiya kodi.
- Kotlin sinovlarida 12 ta bildirishnoma qoidasi va 17 ta fayl tekshiruvi JVM’da o‘tdi. Fayl sinovlari sun’iy imzolar, SHA-256, format nomuvofiqligi, arxiv metama’lumoti va vaqtinchalik faylni tozalashni qamrab oldi. APK metama’lumoti uchun test namunasi ishlatildi.
- Dart qamrov ma’lumoti `coverage/lcov.info` faylida. Kotlin, Android ruxsatlari, haqiqiy fayl tanlagich va bildirishnoma qamrovi ushbu hisobotga kirmaydi.
- Ulangan Android 16 qurilmada `flutter test integration_test` natijasi 2/2. Platforma holati, tarix metama’lumoti va mavzu sozlamasining saqlanishi tekshirildi. Dastlabki o‘rnatish rad etildi, Flutter qayta uringach sinovlar ishladi.
- `flutter build apk --debug` muvaffaqiyatli yakunlandi va APK Android 16 qurilmaga o‘rnatildi. Paket API 26+ uchun `armeabi-v7a`, `arm64-v8a` va `x86_64` variantlarini o‘z ichiga oladi.
- `integration_test/share_smoke.ps1` Android 16 qurilmada sovuq ishga tushirish orqali `ACTION_SEND` havolasini qabul qilish va 67/100 ballni ko‘rsatish yo‘lini tasdiqladi.
- Android 16 tizim fayl tanlagichi orqali sun’iy PDF qabul qilindi. Ekranda 45/100 ball va kutilgan SHA-256 izi ko‘rindi. Qayta bajarish skripti `integration_test/saf_smoke.ps1`. Boshqa ilovadan PDF ulashish yo‘li tasdiqlanmagan, chunki ADB manba URI’si uchun o‘qish ruxsatini bera olmadi.
- Android 16’da mavjud listener ruxsati vaqtincha bekor qilinganda xizmat uzildi. Ruxsat asl holatiga qaytarilgach xizmat qayta ulandi. Jonli Telegram ogohlantirishi va ogohlantirishni bosish yo‘li qurilmada tasdiqlanmagan.
- Yakuniy debug APK SHA-256 izi `2d7ffc6e64ddb47e7d054533ffb8f9255996a8839f88ea953a516de4f4a1645f`.

Mustaqil Kotlin kompilyatori mavjud bo‘lsa, JVM sinovlarini quyidagicha qayta bajarish mumkin.

```powershell
$src = 'android/app/src/main/kotlin/uz/app/shieldguard'
kotlinc "$src/FileAnalyzer.kt" "$src/NotificationAnalyzer.kt" test/native/FileAnalyzerTest.kt test/native/NotificationAnalyzerTest.kt -include-runtime -d build/native-tests.jar
java -cp build/native-tests.jar uz.app.shieldguard.FileAnalyzerTestKt
java -cp build/native-tests.jar uz.app.shieldguard.NotificationAnalyzerTestKt
```
