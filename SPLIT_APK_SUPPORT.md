# Murakkab konteynerlar

ZIP ichidagi APK komponentlari nom bilan topilib, har biri yopiq tasodifiy vaqtinchalik faylga oqim orqali ko‘chiriladi. Yo‘l nomlari disk yo‘liga aylantirilmaydi. 8 komponent, komponent uchun 8 MiB va umumiy mavjud fayl/vaqt limitlari amal qiladi. PackageManager va apksig callback orqali paket hamda sertifikat mosligi baholanadi. Ichki komponent finally orqali o‘chiriladi.

Ichki arxiv topilsa umumiy natija qisman qoladi. APKS/APKM/XAPK to‘liq format spetsifikatsiyasi va split resurslar mosligi implementatsiya qilinmagan. MID sarlavhasi unknown holatda qoladi va malware balli bermaydi. MID split APK sifatida taxmin qilinmaydi.
