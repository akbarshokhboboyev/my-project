# ShieldGuard V3.1 — PHASE 3A

2026-11-22. feature/shieldguard-v3-1. File open/share kodi implementatsiya qilindi; kengaytirilgan E2E qayta sinovi qo‘shimcha tasdiq talab qiladi.

- FileOpenScanHandler: VIEW, SEND va SEND_MULTIPLE; stream/data/ClipData; sovuq va ishlab turgan ilova intent’lari. Eski text SEND saqlandi.
- SharedFileScanner: SAF bilan umumiy 8 unique URI batch, 64 candidate cap, dedup, har fayl uchun error isolation, cancellation va 60s cooperative batch deadline.
- Sender read flag’i va Android’dagi actual per-URI read permission tekshiriladi. Faqat content URI; file/http/invalid URI rad etiladi. URI/fayl nomi history’ga yoki tarmoqqa yozilmaydi.
- Mavjud NativeFileInspector/FileAnalyzer/PDF/apksig qayta ishlatiladi. SIZE katta bo‘lsa stream ochilmaydi; noma’lum hajmda mavjud stream limiti ishlaydi.
- Flutter progress/cancel, Uzbek per-file verdict, batch tartibi va keyingi harakatni foydalanuvchiga tanlash izohi.
- Flutter 189/189, Kotlin 173 + 387 malformed, Python 13/13, analyze toza. Debug APK yig‘ildi va Android16’da o‘rnatildi.
- Dastlabki Android16 file open/share 24 tekshiruv o‘tdi: real grants/format/signature/error isolation va cold VIEW/warm SEND UI.
- Qo‘shimcha MULTIPLE UI case bilan 25-case runner qayta sinovi unverified: yakuniy test APK o‘rnatilishi INSTALL_FAILED_USER_RESTRICTED bilan rad etildi. Policy bypass bo‘lmadi.
- SAF regressiyasi: O‘tdi: yangi umumiy scanner yo‘lida isolated PDF parser dalili UI’da ko‘rindi.
- Hech qanday avtomatik file execute/install/upload yoki global interception yo‘q. Grant’lar persist qilinmaydi. Provider blocking I/O hard interruption kafolati emas.
- PHASE 3B folder monitoring va PHASE 4–8 implementatsiya qilinmadi. Mavjud installed-app/Telegram funksiyalari saqlandi.

Tafsilotlar TEST_REPORT.md va FILE_ANALYSIS.md da. Quyida PHASE 2/1/V3 tarixi saqlangan.

---

# ShieldGuard V3.1 — PHASE 2

2026-11-22. feature/shieldguard-v3-1. Installed-app monitoring kodi va testlari qo‘shildi. Holat: ishlaydi, lekin qo‘shimcha real install/update/alert sinovi kerak.

- InstalledAppMonitor: asosiy processdagi dinamik package receiver; PackageUpdateMonitor install/update va replacing/dedup qoidalari.
- ScanScheduler/InstalledAppJobService: persisted 15 daqiqalik JobScheduler, 32 paketli navbat, 8 paketli batch, battery-not-low va generation cancellation.
- InstalledAppScanner: PackageManager metadata/signing/exported komponentlar; OS ruxsat bergan 32 MiB gacha APK’lar uchun mavjud FileAnalyzer/apksig/DEX/ELF qayta ishlatiladi. Partial/metadata-only unknown verdict.
- InstalledAppAlert: o‘zbekcha ilova nomi, risk sababi va tavsiya. Notification ruxsati va channel tekshiriladi; benign SMS+internet/exported yoki unknown certificate yakka holda alert bermaydi.
- Himoya UI: mustaqil opt-in/out, qamrov izohi, scheduling, oxirgi report. Default o‘chiq. Opt-out receiver/job/cache/monitor alert’ini tozalaydi, eski worker publish’ini to‘sadi.
- Visibility: QUERY_ALL_PACKAGES qo‘shilmadi; launcher queries va avtomatik ko‘rinadigan paketlar bilan cheklangan. Bu o‘rnatishdan keyingi tekshiruv, universal blokirovka emas.
- Flutter 184/184, Kotlin 142 + 387 malformed, Python 13/13, analyze toza. Debug APK yig‘ildi va Android16’da o‘rnatildi.
- Android16 real PackageManager/JobScheduler 21/21; o‘z APK’si uchun tabiiy fon job’i ishladi. PDF isolated SAF regressiyasi ham o‘tdi.
- Install/update va high-risk alert E2E unverified: kodsiz fixture o‘rnatilishi INSTALL_FAILED_USER_RESTRICTED bilan rad etildi. Policy bypass yoki qayta majburlash bo‘lmadi.
- Monitoring ma’lumotlari faqat lokal. Noaniq signing identity trusted deb ko‘rsatilmaydi; production developer roots/lineage hali ochiq.
- PHASE 3–8 hozircha boshlanmadi. Web Risk/hash credential’lari, jonli Telegram, MID, signed APK/AAB va Play internal testing ochiq qoladi.

Tafsilotlar: TEST_REPORT.md va INSTALLED_APP_PROTECTION.md. Quyidagi PHASE 1/V3 holati tarixiy baseline.

---

# ShieldGuard V3.1 — PHASE 1

2026-11-22. feature/shieldguard-v3-1. Faqat Telegram anti-phishing bosqichi implementatsiya qilindi.

- Protokolsiz domen, t.me-prefiksli soxta host, Unicode/homograph va Punycode indikatorlari Flutter/Kotlin’da tekshiriladi.
- O‘zbek/rus/ingliz kod/parol so‘rovlari, bot va texnik yordam bahonalari baholanadi. Matn bot identity’sini tasdiqlamaydi.
- Oddiy ogohlantirish, rasmiy havola, emailni URL deb qabul qilmaslik va mustaqil Premium taklifi uchun false-positive qarshi testlari bor.
- NotificationListener mavjud NotificationAnalyzer yo‘lida yangi qoidalarni ishlatadi. Package filtri, opt-in, permission tekshiruvi, 50 ball alert chegarasi va AlertGate saqlandi.
- Flutter 179/179, Kotlin 115 tekshiruv + 387 malformed input o‘tdi; analyze toza; debug build tayyor.
- Android 16 ACTION_SEND: Bajarilmadi: adb install -r INSTALL_FAILED_USER_RESTRICTED (Install canceled by user) bilan rad etildi; yangi build uchun share testi ishga tushmadi. Jonli Telegram notification holati unverified.
- Holat: lokal detector ishlaydi va sintetik testlardan o‘tgan; jonli Telegram transporti qo‘shimcha sinov talab qiladi.
- Keyingi bosqichlar: installed-app monitoring, file/folder monitoring, advanced malware, dashboard, device-admin evaluation, kengaytirilgan test/release hozircha boshlanmagan. Ular uchun alohida topshiriq kutiladi.
- Web Risk/hash production API, signing lineage, MID, signed APK/AAB va Play internal testing ochiq qoladi.

Quyida tarixiy V3 holati saqlangan; Phase 1’da bajarilgan ish deb talqin qilinmaydi.

---

# ShieldGuard V3 holati

2026-11-22. V2 saqlandi; ish feature/shieldguard-v3 tarmog‘ida. Sinov dalillari TEST_REPORT.md da.

| Modul | Holat va chegaralar |
| --- | --- |
| Lokal havola/xabar | To‘liq ishlaydi va sinovdan o‘tgan; mavjud regressiya saqlangan |
| Verdict va clipboard JSON | To‘liq ishlaydi va sinovdan o‘tgan; incomplete tahlil unknown, ball malware tasdig‘i emas |
| APK imzo yaxlitligi | Qisman ishlaydi; valid/tampered APK Android16 va API37 da o‘tdi; lineage/trust provenance yetishmaydi |
| DEX / ELF | Qisman ishlaydi; bounded header, struktura va satr indikatorlari |
| Ichki APK komponentlari | Qisman ishlaydi; paket/sertifikat mosligi, 8 komponent va 8 MiB limit |
| MID | Hali amalga oshirilmagan; unknown ko‘rsatiladi |
| PDF obyekt parseri | Ishlaydi, lekin qo‘shimcha sinov kerak; benign obyekt parsing Android16/API37 da o‘tdi, encrypted/timeout device holatlari hali tekshirilmagan |
| ZIP / Office / rasm / PE | Qisman ishlaydi; statik format va xavf belgilari, FILE_ANALYSIS.md ga qarang |
| Hash reputatsiya | Tashqi servis yoki credential talab qiladi; Flutter alohida rozilik UI va backend/mock testlar mavjud |
| Web Risk | Tashqi servis yoki credential talab qiladi; HTTPS adapter va mocklar bor, haqiqiy so‘rov bajarilmagan |
| Ishonchli nashriyotchi | Qisman ishlaydi; typed registry bor, production reference va UI trust verdict ulanmagan |
| Bir nechta fayl | Ishlaydi, lekin qurilmada batch sinovi kerak; dastlabki 8 fayl |
| Telegram avtomatik himoya | Android tomonidan cheklangan; ruxsat/lifecycle/qoidalar bor, jonli akkaunt sinovi bajarilmagan |
| Imzosiz release APK/AAB | To‘liq ishlaydi va sinovdan o‘tgan; R8 bilan kompilyatsiya, tarqatish uchun imzo kerak |
| Signed release va Play | Tashqi servis yoki credential talab qiladi; upload key va Play Console yo‘q |

Yagona ShieldGuardSecurityEngine fasadi, chuqur DEX dataflow/call graph, signing lineage, to‘liq split format semantikasi, JPEG segment parseri, haqiqiy malware korpusi va precision/recall hali tugallanmagan. To‘y arxivi va OneID asl namunasi berilmagan.
