# ShieldGuard V3.1 - PHASE 3B: papkalar xavfsizligi

2026-11-22. Branch: `feature/shieldguard-v3-1`; baseline: `02c8dc2`.

## Rozilik va ruxsat

Himoya > Papkalar xavfsizligi > Papka qo'shish Android `ACTION_OPEN_DOCUMENT_TREE` oynasini ochadi. Faqat foydalanuvchi tanlagan `content:` tree uchun persistable **read** permission olinadi; write so'ralmaydi. Ko'pi bilan 4 papka. URI va papka nomi private lokal preferences'da; Flutter faqat lokal ID, ko'rsatiladigan nom va ruxsat holatini oladi. Nom uzunligi/control/bidi belgilar cheklanadi.

Default davriy monitoring o'chiq. Tanlangan papkani qo'lda tekshirish mumkin. Davriy monitoringni o'chirish 7201/7202 job'larini bekor qiladi, root ro'yxati, natija/keshni tozalaydi va faqat shu modul olgan read grant'larini bo'shatadi. Grant release xatosi qolsa UI ko'rsatadi va keyingi recovery'da qayta urinadi; tugamaguncha yangi root qo'shilmaydi. Papkani olib tashlash shu papka grant'ini qaytaradi. Ruxsat yo'qolishi monitoringni to'xtatadi; qayta tanlash talab qilinadi.

Android 11+ system picker cheklovlari saqlanadi: storage root, Download(s) root va Android/data, Android/obb subtree'lari rad etiladi. Ruxsatli Download ichidagi alohida test papkasi tanlanishi mumkin. Global storage, Device Admin, accessibility yoki yangi runtime permission qo'shilmadi.

## Scheduling va scanner

`AuthorizedFolderMonitor`, `FolderScanScheduler`, `FolderScanJobService`, `IncrementalFileScanner` PHASE 2'dagi native JobScheduler usulini qayta ishlatadi; WorkManager kerak emas. Persisted periodic job 7201: 15 daqiqalik minimal interval, battery-not-low; manual job 7202. Installed-app 7101/7102 mustaqil. Takroriy job oldi olinadi. OS ishni keyinga surishi mumkin; bu uzluksiz yoki aniq vaqtdagi real-time himoya emas. Application recovery persisted grant va scheduling'ni tekshiradi; mavjud BOOT receiver process'ni boshlaydi. Stop/cancel epoch generation bilan eski worker natijasini nashr qilishdan saqlaydi.

Metadata enumeration: 256 hujjat/yurish, 2 daraja rekursiya, 256 bounded directory queue; 4 root navbatini aylantirish. Tahlil: 8 fayl/yurish, 60 soniya cooperative deadline/cancel; single-thread executor va 1 queued task. Alohida fayl xatosi qolganlarini yiqitmaydi. Cheklovdan ortgan yoki o'qilmagan qamrov partial/incomplete; UI tekshirilmaganlar sonini **kamida** deb ko'rsatadi. 256 dan katta provider listing'da to'liq traversal yoki har bir fayl keyingi yurishda albatta ko'rilishi kafolatlanmaydi.

Tree authority + document ID SHA-256 kaliti overlap/duplicate URI'ni birlashtiradi. Musbat modified + ma'lum size o'zgarmasa metadata kesh ko'pi bilan 1 soat ishlatiladi. Eski/zaif/noma'lum metadata qayta tahlil qilinadi; eng eski tekshirilgan pending fayllar oldin olinadi. SHA-256 mavjud scanner'dan olinib lokal yoziladi; kontent hashini olishning o'zi faylni o'qishni talab qiladi. Bir xil size/mtime bilan yashirin o'zgarish TTL tugamaguncha sezilmasligi mumkin; metadata kriptografik kafolat emas. Unknown/incomplete kesh ham incomplete qoladi.

PHASE 3A `SharedFileScanner` -> `NativeFileInspector` -> `FileAnalyzer`, PDF/apksig qayta ishlatiladi. Fayl actual format'i, APK signing va mavjud indikatorlar tekshiriladi. Mavjud 128 MiB stream, ZIP/decompression va parser limitlari saqlanadi. Fayl ochilmaydi/ishga tushirilmaydi/o'rnatilmaydi/o'zgartirilmaydi. Android DocumentProvider query/read bloklansa cooperative timeout uni darhol uzishni kafolatlamaydi. Incomplete hech qachon 'xavfsiz' tasdiq emas; indikator zararli dastur isboti emas.

## Maxfiylik va sinov

Avtomatik upload, reputatsiya so'rovi yoki telemetry yo'q; nom/URI tarmoqqa yuborilmaydi. Lokal cache bounded 256 hashed key, metadata, timestamp, mavjud SHA-256, complete va indikatorlarni saqlaydi. Online reputation avvalgi alohida consent yo'lida qoladi. Boshqa ilovada ochilgan fayllarga universal himoya da'vosi yo'q.

`test/native/IncrementalFileScannerTest.kt`: 30 sintetik holat; `test/folder_monitor_test.dart`: 7 mocked Flutter holat. Native Android test `FolderMonitorInstrumentation` faqat o'ziga tegishli `ShieldGuard-folder-test-*` SAF root bilan ishlaydi; test APK o'rnatilishi qurilma siyosati bilan rad etilgani sabab runner **unverified**. JVM metadata/permission adapterlari mock; real SAF yoki real APK signature verifikatsiyasi sifatida berilmaydi. Real Android UI/SAF dalillari va aniq regressiya natijalari `TEST_REPORT.md` da.

Qayta bajarish: avval debug APK o'rnating; faqat benign 3 fixture bo'lgan yagona test papka uchun `integration_test/folder_saf_smoke.ps1 -Adb <adb> -Serial <serial> -FolderName ShieldGuard-folder-test-<8hex>`. `folder_scan_smoke.ps1` UI orqali manual scan'ni boshlaydi va debug `run-as` bilan faqat natija hisoblagichlarini tekshiradi; URI/cache chiqarilmaydi. Bu helper device UI o'lchamiga moslashtirish talab qilishi mumkin. Instrumentation'ni build qilish: `./gradlew.bat :app:assembleDebugAndroidTest -PshieldTestRunner=uz.app.shieldguard.FolderMonitorInstrumentation` (android katalogidan). Ruxsat tasdiqlanmagan install'ni chetlab o'tmang.

Android primary references: [SAF](https://developer.android.com/training/data-storage/shared/documents-files), [Android 11 storage restrictions](https://developer.android.com/about/versions/11/privacy/storage), [JobInfo](https://developer.android.com/reference/android/app/job/JobInfo).
# PHASE 4A APK discovery

Folder scan mavjud NativeFileInspector orqali APK assessment oladi: actual format, imzo, permission va mavjud DEX/ELF/split indikatorlari. URI yoki fayl nomi yangi risk metadata’siga kiritilmaydi; avtomatik online hash so‘rovi yo‘q. 4C’da kuchli APK shubhasi alohida guard consent va Android notification permission/channel bilan warning notification beradi. Folder discovery install’ni bloklagan deb yozilmaydi. Duplicate hash/outcome dedup qilinadi; canceled/old-generation scan yangi alert nashr qilmaydi. Folder scanning installer uchun snapshot yaratmaydi.

4D Android16: faqat own SAF tree’dagi 2 kodsiz APK manual job bilan HOME’da tekshirildi; strong integrity uchun notification, benign launcher indikatori uchun avtomatik block yo‘q. POST_NOTIFICATIONS denied’da o‘zgargan APK qayta tahlil qilindi, notification yo‘q; ruxsat qayta tiklandi. Bu tabiiy periodic schedule testi emas. Papka olib tashlanganda persistable read grant bekor qilindi; system picker vaqtinchalik Activity grant’i process tugaguncha qolishi mumkin. Native folder runner’ning eski unverified holati o‘zgarmadi.
