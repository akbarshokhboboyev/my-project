# ShieldGuard V2 holati

2026-11-22 auditi. Mavjud loyiha saqlandi, boshlang‘ich main branch toza edi. Git remote akbarshokhboboyev/my-project va HEAD 91a95ee bilan ishlash boshlandi. O‘zgarishlar feature/shieldguard-v2 branchida. Boshlang‘ich 64 ta Flutter testi ushbu ishda mustaqil qayta o‘tdi.

| Modul | Holat | Dalil yoki cheklov |
| --- | --- | --- |
| Lokal havola va xabar | To‘liq ishlaydi va sinovdan o‘tgan | Mavjud regressiya testlari saqlandi |
| Online Web Risk adapteri | Tashqi xizmat yoki credential talab qiladi | Adapter, gateway va mock HTTP testlari bor. Haqiqiy Google so‘rovi kalit yo‘qligi sabab bajarilmadi |
| SQLite reputatsiya keshi | To‘liq ishlaydi va sinovdan o‘tgan | Android integratsiyada persist va consent revoke bilan tozalash |
| Avtomatik himoya | Android tomonidan cheklangan | Lokal qoidalar, dedup, cooldown, ruxsat va xizmat lifecycle. Jonli Telegram flow hali tasdiqlanmagan |
| Fayl | Qisman ishlaydi | APK metadata, PE chegaralari, PNG CRC, ZIP xavf belgilari. PDF to‘liq obyekt parseri va APK imzo verifikatori yo‘q |
| O‘zbekcha interfeys | Ishlaydi, lekin qo‘shimcha sinov kerak | Online rozilik, natijalar, bekor qilish va sinov tugmasi qo‘shildi |
| Debug APK | To‘liq ishlaydi va sinovdan o‘tgan | Yig‘ildi. Yakuniy artefakt tafsilotlari TEST_REPORT.md hujjatida |
| Release signing | Tashqi xizmat yoki credential talab qiladi | key.properties andozasi, CI secrets va guard mavjud. Shaxsiy keystore topilmadi |
| Imzosiz release APK/AAB | To‘liq ishlaydi va sinovdan o‘tgan | R8 bilan kompilyatsiya qilindi. O‘rnatish va tarqatish uchun imzo kerak |
| Google Play | Qisman ishlaydi | Checklist va o‘zbekcha tavsif tayyor. Play Console nashri bajarilmagan |

## Texnik qarorlar

| Qaror | Sabab |
| --- | --- |
| Web Risk Lookup | Tijoriy foydalanish uchun hujjatlashtirilgan API |
| Server API kaliti | Mobil paketda provider sirini saqlamaslik |
| To‘liq URL uchun alohida rozilik | Hash-prefix kanonizatsiyasining soxta implementatsiyasini kiritmaslik |
| Ijobiy kesh expireTime | Provayder cache siyosatini bajarish |
| Nested archive ochilmaydi | Resurs sarfini chegaralash va tekshirilmagan kontentni ochiq ko‘rsatish |
| SDK versiyalari saqlandi | Flutter suggestions moslikni tasdiqladi |
| Release kalitisiz guard | Imzosiz natijani tarqatishga tayyor deb ko‘rsatmaslik |
