# Release yig‘ilishi

Mavjud applicationId va namespace uz.app.shieldguard. minSdk 26, compile/target SDK Flutter 3.47.6 shablonidan 36. Versiya 2.0.0+2. R8 va resource shrinking yoqilgan. Haqiqiy release kaliti topilmadi.

Upload key Play’ga yuboriladigan AAB’ni imzolaydi. Play App Signing qurilmaga tarqatiladigan APK’larni app signing key bilan imzolaydi. Kalitlarni saqlash va yangilash mavjud ilova yangilanishlariga ta’sir qiladi. [Android qo‘llanmasi](https://developer.android.com/studio/publish/app-signing)

## Lokal sozlash

Kalitni repository tashqarisida yarating yoki mavjud upload kalitini ishlating. Quyidagi buyruq parolni interaktiv so‘raydi.

```powershell
keytool -genkeypair -v -keystore C:/secure/shieldguard-upload.jks -alias shieldguard-upload -keyalg RSA -keysize 3072 -validity 10000
Copy-Item android/key.properties.example android/key.properties
```

key.properties ichida haqiqiy storeFile, storePassword, keyAlias, keyPassword qiymatlarini lokal kiriting. Andozadagi REPLACE_LOCALLY qiymatlari credential emas. CI’da SHIELD_STORE_FILE, SHIELD_STORE_PASSWORD, SHIELD_KEY_ALIAS va SHIELD_KEY_PASSWORD secrets orqali beriladi.

```powershell
flutter build apk --release
flutter build appbundle --release
Get-FileHash build/app/outputs/flutter-apk/app-release.apk -Algorithm SHA256
Get-FileHash build/app/outputs/bundle/release/app-release.aab -Algorithm SHA256
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-release.apk
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

Signing bo‘lmasa odatiy release buyruqlari aniq xato bilan to‘xtaydi. Faqat CI kompilyatsiya auditi uchun Gradle’ga -PshieldAllowUnsigned berish mumkin. Bunday unsigned artefakt o‘rnatish yoki Play’ga yuklashga tayyor emas.

```powershell
Push-Location android
.\gradlew.bat :app:assembleRelease :app:bundleRelease '-PshieldAllowUnsigned=true' '-Ptarget=lib/main.dart' '-Ptarget-platform=android-arm,android-arm64,android-x64'
Pop-Location
```

Audit natijalari va artefakt izlari TEST_REPORT.md hujjatida saqlanadi.
