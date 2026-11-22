# Xavfsizlik

V3 apksig APK yaxlitligi verifikatorini qo‘shadi. PDF parseri exported=false isolated UID jarayonida ishlaydi. DEX va ELF elementlari 8 MiB dan, jami 16 MiB kontent byudjeti bilan o‘qiladi. Split komponentlar tasodifiy vaqtinchalik nomlar bilan olinadi, tashqi arxiv yo‘llari ishlatilmaydi.

URL sahifalari va redirect nishonlari yuklanmaydi. HTTPS gateway adapteri redirect kuzatmaydi. Web Risk API kaliti server muhiti orqali olinadi. So‘rov hajmi, javob hajmi, timeout, tezlik va retry cheklovlari mavjud. Minimal gateway faqat nazoratli o‘rnatish uchun mo‘ljallangan. Ommaviy xizmat uchun autentifikatsiya va deployment konfiguratsiyasi THREAT_INTELLIGENCE.md hujjatida.

Fayl tahlili statik. Arxiv entry yo‘llari disk yo‘li sifatida ishlatilmaydi. Ichki APK faqat tasodifiy cache fayliga ko‘chiriladi; bajarilmaydi. Traversal yo‘llari indikator sifatida ko‘rsatiladi. ScanLimits vaqt va hajmni cheklaydi, ammo bloklangan content provider read chaqiruvini darhol uzolmaydi. PDFBox chegaralangan obyekt parseri va apksig kriptografik tekshiruvi qo‘shilgan. PDF uchun 4 MiB fayl/20 000 obyekt/10 soniya limit; 8 MiB PDFBox stream storage butun process heap limiti emas. JPEG segment parseri hali qo‘shilmagan. APK sertifikat izi ishonchlilik kafolati bermaydi.

Bildirishnoma xom matni log, tarix va ogohlantirishga yozilmaydi. Dedup xeshi tasodifiy seans tuzi bilan faqat xotirada qoladi. Immutable PendingIntent va ilova ichki tasodifiy proof qiymati natijani tashqaridan soxtalashtirishni cheklaydi.

Release debug flag o‘chirilgan, R8 va resurs shrinking yoqilgan. Kalitlar Git’dan chiqarilgan. SMS, Accessibility, root yoki VPN ruxsatlari yo‘q. Tashqi transport HTTPS bilan cheklangan.

Bog‘liqlik versiyalari saqlangan va lockfile yangilangan. To‘liq zaiflik bazasi auditi yoki penetration test o‘tkazilgani da’vo qilinmaydi. [Android listener](https://developer.android.com/reference/android/service/notification/NotificationListenerService), [Google Play User Data](https://support.google.com/googleplay/android-developer/answer/10144311).
