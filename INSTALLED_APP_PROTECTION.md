# O‘rnatilgan ilovalar himoyasi — PHASE 2

2026-11-22. Monitoring standart holatda o‘chiq. Himoya ekranidagi alohida switch orqali rozilik beriladi; Telegram notification access bundan mustaqil.

## Hodisalar va fon ishlari

ShieldGuardApplication faqat asosiy processda InstalledAppMonitor’ni yuklaydi. Isolated PDF process preferences yoki JobScheduler’ga kirmaydi. Jarayon faol bo‘lganda dinamik receiver ACTION_PACKAGE_ADDED va ACTION_PACKAGE_REPLACED ni oladi. PackageUpdateMonitor update paytidagi qo‘shimcha ADDED/replacing hodisasini tashlab, REPLACED bilan birlashtiradi.

Manifest implicit paket broadcast’lari Android 8+ da universal fon kuzatuvi emas. Jarayon yo‘q bo‘lsa, JobScheduler davriy snapshot’dagi lastUpdateTime o‘zgarishlarini tekshiradi. Interval 15 daqiqa, battery-not-low sharti va OS kvotalari bilan kechikishi mumkin. Periodik job reboot’dan keyin saqlanishi uchun RECEIVE_BOOT_COMPLETED kerak. Force-stop/Doze/OEM cheklovlari hurmat qilinadi. [Broadcast cheklovlari](https://developer.android.com/develop/background-work/background-tasks/broadcasts/broadcast-exceptions), [JobInfo](https://developer.android.com/reference/android/app/job/JobInfo.Builder).

Navbat 32 nom, snapshot 512 ko‘rinadigan paket va batch 8 tekshiruv bilan cheklangan. Bitta executor job’larni ketma-ket bajaradi. Qolgan ishlar keyingi siklga qolishi mumkin. Version timestamp keshi takroriy event scan/alert’larini kamaytiradi. Scan vaqtida paket yana yangilansa, aralash versiya natijasi keshga olinmaydi.

## Scanner va dalillar

PackageManager paket, label, versiya, so‘ralgan permissions, SDK, signing identity va exported komponentlarni beradi. Faqat OS ruxsat bergan sourceDir/splitSourceDirs o‘qiladi. Mavjud FileAnalyzer, apksig, DEX/ELF va ApkRiskAnalyzer qayta ishlatiladi. Har APK 32 MiB, ko‘pi bilan 8 komponent, content stage uchun 5 soniyalik cooperative checkpoint ishlaydi; bu apksig ichidagi har chaqiruvga qattiq wall-clock timeout emas. Job batch 60 soniya o‘tgach yangi paket boshlamaydi; OS stop/opt-out cancellation keyingi checkpoint’da tekshiriladi.

Kontent yetarli o‘qilmasa incomplete/metadata-only yoki partial ko‘rsatiladi. Platform bergan sertifikat izi mustaqil APK verification yoki ishonchli nashriyotchi tasdig‘i deb ko‘rsatilmaydi. Production trusted roots va signing lineage hali yo‘q. Split’larning to‘liq semantikasi V3 cheklovlari bilan qoladi.

SMS+internet va exported launcher’ning o‘zi avtomatik alert bermaydi. Accessibility+overlay/o‘rnatish yoki SMS+internet+o‘rnatish kabi kombinatsiya, imzo xatosi yoki kuchli statik dalillar kerak; umumiy ball kamida 50. Permission so‘ralgani u berilganini anglatmaydi. Heuristika malware isboti emas.

## Alert, privacy va opt-out

Alert o‘zbekcha ilova nomi, standart risk sababi va tavsiya bilan keladi; xabar/OTP/parol olinmaydi. POST_NOTIFICATIONS, umumiy va channel sozlamalari tekshiriladi. Tap alohida lokal alert report’ni ochadi. Keyingi benign report avvalgi alert tafsilotlarini almashtirmaydi. Xabar private visibility bilan chiqariladi; bir notification ID yangilanadi.

Lokal private preferences’da versiya timestamp’lari, 32 paketli navbat, oxirgi event, oxirgi report va oxirgi alert report saqlanadi. Paket/label/permissions/public signing fingerprint serverga yuborilmaydi. Opt-out generation’ni o‘zgartiradi, receiver’ni uzadi, ikkala job’ni bekor qiladi, lokal monitoring keshini va monitoring alert’ini tozalaydi. Generation tekshiruvi va publish/disable lock eski worker’ning opt-out’dan keyin alert chiqarishini to‘sadi.

## Visibility va Play bahosi

QUERY_ALL_PACKAGES qo‘shilmadi. MAIN/LAUNCHER queries va Android avtomatik ko‘rsatgan paketlar bilan cheklangan qamrov tanlandi. Launcher’siz yoki yashirilgan paketlar to‘liq qamrab olinmasligi UI’da ochiq yozilgan. Antivirus broad visibility uchun mos foydalanish holati bo‘lishi mumkin, ammo Play deklaratsiyasi va kamroq keng usul yetmasligini asoslash talab qilinadi; bu bosqichda keng ruxsat yoki Play tasdig‘i olinmadi. [Android visibility](https://developer.android.com/training/package-visibility/declaring), [Play siyosati](https://support.google.com/googleplay/android-developer/answer/10158779?hl=en).

Bu o‘rnatishdan keyingi tekshiruv. O‘rnatishdan oldingi blokirovka, yashirin uninstall, Device Admin yoki global monitoring yo‘q.

## Android sinovini qayta bajarish

Windows’da test/native/build_installed_fixtures.py faqat hasCode=false, kodsiz sintetik fixture’larning ikki versiyasini .dart_tool/installed-fixture ichida yaratadi. Mavjud Android public debug keystore kerak; yangi kalit yaratilmaydi. APK’larni ochmang, CI/GitHub’ga yuklamang.

~~~powershell
flutter build apk --debug
.\android\gradlew.bat -p android :app:assembleDebugAndroidTest
adb -s <id> install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s <id> install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb -s <id> shell am instrument -w uz.app.shieldguard.test/uz.app.shieldguard.InstalledMonitorInstrumentation
~~~

Oddiy runner o‘z APK’sini va absent package’ni o‘qiydi; metadata/sertifikat, cancellation, real job scheduling/execution va opt-out’ni tekshiradi. Boshqa paketlarning kontenti o‘qilmasligi uchun faqat timestamp baseline tayyorlanadi. Monitoring oldindan yoqilgan bo‘lsa, uning holatini buzadigan toggle testlari o‘tkazib yuboriladi.

Event testi uchun fixture avval o‘rnatilmagan bo‘lsin. Runner’ga -e events true bering; PHASE2_READY_FOR_INSTALL chiqqach fixture1.apk’ni, PHASE2_READY_FOR_UPDATE chiqqach fixture2.apk’ni -r bilan o‘rnating. Standart o‘rnatish tasdig‘i kerak; rad etilsa qayta majburlamang. Runner 90 soniyadan keyin timeout va opt-out cleanup qiladi. O‘z fixture paketingizni va test APK’ni sinovdan keyin olib tashlang. Joriy Android16 qurilmada fixture1 o‘rnatilishi rad etildi; bu event ssenariysi unverified.
