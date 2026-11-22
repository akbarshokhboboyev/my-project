# Maxfiylik siyosati

PHASE 3B: foydalanuvchi SAF orqali tanlagan papkalar uchun faqat persistable read ruxsati olinadi. Davriy monitoring default o'chiq; aniq vaqtdagi himoya emas. Root URI/nom, bounded hashed-document metadata/kontent SHA-256 keshi va oxirgi yurish hisoblagichlari faqat private lokal preferences'da saqlanadi. Fayllar va nom/URI telemetry yoki serverga avtomatik yuborilmaydi. Monitoringni o'chirish shu modul job, ro'yxat, kesh/natija va read grant'larini tozalaydi; grant release muvaffaqiyatsiz bo'lsa UI holat va keyingi recovery retry saqlanadi. Papka ichidagi fayllar o'zgartirilmaydi. Online reputatsiya uchun alohida rozilik talabi saqlanadi. Tafsilot: FILE_MONITORING.md.

PHASE 2’da alohida rozilik bilan installed-app monitoring qo‘shildi. Paket/versiya timestamp keshi, bounded event navbati, oxirgi event, oxirgi scan va alert report private lokal preferences’da saqlanadi. Report ilova label’i, permissions va public signing fingerprint’ni o‘z ichiga olishi mumkin; serverga yuborilmaydi. Opt-out job/receiver’larni to‘xtatib monitoring keshini va alert’ini o‘chiradi. QUERY_ALL_PACKAGES ishlatilmaydi; ko‘rinadigan paketlar qamrovi UI’da tushuntiriladi. Backup o‘chiq. Boshqa mavjud tarix/online consent sozlamalari mustaqil qoladi.


V3 backend hash endpointi alohida rozilik flagisiz ishlamaydi. Flutter har bir SHA-256 so‘rovi oldidan alohida rozilik oladi; hash HTTPS gateway va VirusTotal’ga borishi tushuntiriladi. Fayl kontenti yuborilmaydi. Natijalar seans xotirasida qoladi. Clipboard JSON xom xabar, URL va fayl nomini chiqarib tashlaydi. DEX, ELF va split APK tarkibi lokal tekshiriladi.

ShieldGuard havola, xabar va fayllarni standart holatda qurilmada tahlil qiladi. Xabarlar, OTP, parol, to‘liq URL va fayl nomi tarixga yozilmaydi. Ixtiyoriy tarix faqat vaqt, tur, ball, belgilar soni va holatni saqlaydi.

Onlayn tekshiruv Sozlamalar ekranida alohida rozilik bilan yoqiladi. Qo‘lda kiritilgan havolaning to‘liq URL’i tanlangan HTTPS serverga, u yerdan Google Web Risk’ka yuboriladi. URL ichida shaxsiy token bo‘lishi mumkin. Xabar va Telegram bildirishnomalari avtomatik tashqi serverga uzatilmaydi. API kaliti faqat serverda, gateway kirish tokeni ilova seansi xotirasida qoladi. Rozilik qaytarib olinsa reputatsiya keshi tozalanadi.

SQLite reputatsiya keshi URL o‘rniga SHA-256 kalit va moslik muddati saqlaydi. Bunday xesh taxmin qilinadigan URL’lar uchun anonimlashtirish kafolati bermaydi. Keshdagi ijobiy natija Google expireTime bilan tugaydi. Muddati tugagan yozuvlar keyingi kesh operatsiyasida o‘chiriladi. Tarix va reputatsiya alohida bazalarda saqlanadi.

Vaqtinchalik fayllar yopiq keshda turadi va tekshiruv finally bosqichida o‘chiriladi. Jarayon kutilmaganda o‘lsa keyingi fayl tekshiruvida bir kundan eski qoldiqlar tozalanadi. Backup o‘chirilgan.

Bildirishnomalarga kirish Android sozlamalaridan istalgan vaqtda bekor qilinadi. Ommaviy nashrdan oldin xizmat egasi, aloqa manzili va serverning haqiqiy saqlash siyosati ushbu hujjatga qo‘shiladi.
