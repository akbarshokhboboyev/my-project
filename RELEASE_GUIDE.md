# Release yig‘ilishi

Final source versiyasi 3.1.0+4. Haqiqiy user-owned production upload keystore taqdim etilmagan. Oldingi versiya artefaktlari ushbu final build sifatida qabul qilinmaydi.

ApplicationId/namespace uz.app.shieldguard, minSdk 26, compile/target SDK 36 (Windows Flutter 3.47.6), AGP 9.1.1/JDK17. Versiya 3.1.0+4. R8 va resource shrinking yoqilgan. Signing qiymatlarini logga chiqarmang; kalitlar Git tashqarisida qoladi.

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

Signing bo‘lmasa assembleRelease/bundleRelease guard bilan to‘xtaydi. Final workflow’da SHIELD_ALLOW_UNSIGNED/shieldAllowUnsigned bypass olib tashlandi; debug.keystore/androiddebugkey production release uchun rad etiladi. Mavjud production kalit bo‘lmasa signed APK/AAB yaratilmaydi. Yangi kalit yoki production identity avtomatik yaratilmaydi.

~~~powershell
Push-Location android
try { .\gradlew.bat :app:minifyReleaseWithR8 }
finally { Pop-Location }
~~~

Bu alohida R8 kompilyatsiya auditi, release APK/AAB yaratish yoki tarqatish emas. Guard o‘zgartirilmaydi. Build’larni ketma-ket bajaring. Direct Gradle’da generated plugin registrant oldingi integration build’dan qolmaganiga e’tibor bering. PDFBox optional JPEG2000 decoder uchun faqat bitta tor R8 dontwarn bor; rasm render qilinmaydi.

Audit natijalari va artefakt izlari TEST_REPORT.md hujjatida saqlanadi.
