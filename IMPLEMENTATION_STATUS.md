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
