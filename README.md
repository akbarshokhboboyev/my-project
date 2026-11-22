# ShieldGuard

V3 ish branchida cheklangan APK kontent tahlili, apksig imzo verifikatsiyasi, isolated PDFBox parseri, hash rozilik UI’si, 8 faylli batch va clipboard JSON hisoboti qo‘shildi. Amaldagi imkoniyat va cheklovlar [MALWARE_DETECTION.md](MALWARE_DETECTION.md), [APK_SIGNATURE_VERIFICATION.md](APK_SIGNATURE_VERIFICATION.md) va [SPLIT_APK_SUPPORT.md](SPLIT_APK_SUPPORT.md) hujjatlarida.

V2 uchun [onlayn manbalar va server sozlash](THREAT_INTELLIGENCE.md), [fayl tahlili chegaralari](FILE_ANALYSIS.md), [Android sinovlari](ANDROID_NOTIFICATION_TESTS.md), [release signing](RELEASE_GUIDE.md) va [Play Store ro‘yxati](PLAY_STORE_CHECKLIST.md) tayyorlandi.

Android uchun mahalliy kiberxavfsizlik ilovasi. Havola, xabar va foydalanuvchi tanlagan fayllardagi xavf belgilarini o‘zbek tilida tushuntiradi. Android bildirishnomalariga asoslangan himoya alohida rozilik bilan yoqiladi.

## Windows muhitida ishga tushirish

Flutter 3.47.6, Dart 3.13.5, JDK 17 va Android SDK bilan ishlashga mo‘ljallangan. Android 8 (API 26) yoki yangiroq qurilma kerak.

```powershell
flutter doctor -v
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze --suggestions
flutter analyze
flutter test --coverage
flutter build apk --debug
flutter devices
flutter run
```

Yig‘ilish muvaffaqiyatli bo‘lsa, APK `build/app/outputs/flutter-apk/app-debug.apk` manzilida bo‘ladi. Ulangan qurilmaga o‘rnatish uchun `adb install -r build/app/outputs/flutter-apk/app-debug.apk` buyrug‘ini bajaring. Qurilma sinovi `flutter test integration_test -d <qurilma-id>` orqali ishga tushadi. Tarqatish uchun tegishli release imzolash konfiguratsiyasi kerak.

[Arxitektura](ARCHITECTURE.md) · [Xavfsizlik](SECURITY.md) · [Maxfiylik](PRIVACY.md) · [Sinovlar](TEST_REPORT.md) · [Holat](IMPLEMENTATION_STATUS.md)
