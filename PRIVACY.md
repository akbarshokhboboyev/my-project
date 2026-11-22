# Maxfiylik siyosati

V3 backend hash endpointi alohida rozilik flagisiz ishlamaydi. Flutter har bir SHA-256 so‘rovi oldidan alohida rozilik oladi; hash HTTPS gateway va VirusTotal’ga borishi tushuntiriladi. Fayl kontenti yuborilmaydi. Natijalar seans xotirasida qoladi. Clipboard JSON xom xabar, URL va fayl nomini chiqarib tashlaydi. DEX, ELF va split APK tarkibi lokal tekshiriladi.

ShieldGuard havola, xabar va fayllarni standart holatda qurilmada tahlil qiladi. Xabarlar, OTP, parol, to‘liq URL va fayl nomi tarixga yozilmaydi. Ixtiyoriy tarix faqat vaqt, tur, ball, belgilar soni va holatni saqlaydi.

Onlayn tekshiruv Sozlamalar ekranida alohida rozilik bilan yoqiladi. Qo‘lda kiritilgan havolaning to‘liq URL’i tanlangan HTTPS serverga, u yerdan Google Web Risk’ka yuboriladi. URL ichida shaxsiy token bo‘lishi mumkin. Xabar va Telegram bildirishnomalari avtomatik tashqi serverga uzatilmaydi. API kaliti faqat serverda, gateway kirish tokeni ilova seansi xotirasida qoladi. Rozilik qaytarib olinsa reputatsiya keshi tozalanadi.

SQLite reputatsiya keshi URL o‘rniga SHA-256 kalit va moslik muddati saqlaydi. Bunday xesh taxmin qilinadigan URL’lar uchun anonimlashtirish kafolati bermaydi. Keshdagi ijobiy natija Google expireTime bilan tugaydi. Muddati tugagan yozuvlar keyingi kesh operatsiyasida o‘chiriladi. Tarix va reputatsiya alohida bazalarda saqlanadi.

Vaqtinchalik fayllar yopiq keshda turadi va tekshiruv finally bosqichida o‘chiriladi. Jarayon kutilmaganda o‘lsa keyingi fayl tekshiruvida bir kundan eski qoldiqlar tozalanadi. Backup o‘chirilgan.

Bildirishnomalarga kirish Android sozlamalaridan istalgan vaqtda bekor qilinadi. Ommaviy nashrdan oldin xizmat egasi, aloqa manzili va serverning haqiqiy saqlash siyosati ushbu hujjatga qo‘shiladi.
