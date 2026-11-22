# Telegram V3.1 — PHASE 1

Flutter ThreatEngine va Kotlin NotificationAnalyzer umumiy sintetik TSV korpus bilan tekshiriladi. t.me-premium.uz va t.me.evil.example kabi soxta hostlar, matn ichidagi protokolsiz domenlar, Unicode o‘xshash harflar va Punycode indikatorlari baholanadi. URL ochilmaydi, DNS yoki bot identity so‘rovi bajarilmaydi. Official host rasmiy bot yoki xabarning haqiqiyligini kafolatlamaydi.

Kod/parolni yuborish yoki kiritish so‘rovlari o‘zbek, rus va ingliz tilida tekshiriladi, jumladan 5 xonali kod va login code. Bot/yordam xizmati belgisi faqat maxfiy ma’lumot so‘rovi yoki kuchli shubhali havola bilan birga ball oladi. Oddiy “Premium sovg‘angiz tayyor” va “Hech kimga tasdiqlash kodini yubormang” alohida xavf belgisi emas. Ogohlantirishdan keyingi comma/contrast bilan ajratilgan yangi talab mustaqil baholanadi; bu to‘liq tabiiy til tushunish emas.

Mahalliy link score kamida 45 bo‘lsa messageLink 50, kamida 25 bo‘lsa 25 ball oladi. Secret so‘rovi 55, bot/support 20, gift 22. Kuchli soxta domenning o‘zi alert uchun yetadi; oddiy IDN/shortener ehtiyotkor belgidir. t.me-premium.uz va telegram.example/premium misollari xabarda 72 ball, rasmiy https://t.me/premium esa 0 ball beradi. Statik ball malware yoki bot shaxsini tasdiqlamaydi.

NotificationListenerService Android ko‘rsatgan Telegram matniga mavjud opt-in va notification access bilan ishlaydi. Android yashirgan xabarlar olinmaydi. Input 8192 belgi va 24 link bilan cheklangan. 50 ball alert chegarasi, 30 soniya cooldown, 5 daqiqa salted-hash dedup va 128 yozuvli xotira limiti saqlandi. Xom matn, OTP va parollar tarix, log yoki tashqi xizmatga yozilmaydi.

Faol seanslar, ikki bosqichli himoya va begona qurilmalarni uzish bo‘yicha mavjud qo‘llanma saqlandi. ShieldGuard hisobni bevosita boshqarmaydi. Jonli Telegram akkaunt/bildirishnoma sinovi bu bosqichda bajarilmadi; unit fixture yoki ACTION_SEND bunday sinovni almashtirmaydi.
# PHASE 4A APK discovery

Telegram’da faylni ShieldGuard’ga Share/Open qilish yoki oldindan ruxsat berilgan SAF papkaga saqlash mavjud scanner’ni ishlatadi. APK risk/confidence alohida baholanadi. Private Telegram storage va ShieldGuard chetlab o‘tilgan installer universal kuzatilmaydi. Davriy folder monitoring real-time emas; o‘qilmagan fayl xavfsiz deyilmaydi. Tafsilot: AUTO_BLOCK_PROTECTION.md.

4C: ShieldGuard boshqaradigan oqimda strong gate block modal ko‘rsatiladi; qat’iy rejim default o‘chiq va unknown/incomplete’ni ehtiyot chorasi sifatida ushlab turadi. Telegram uchun Install unknown apps ruxsatini foydalanuvchi Android sozlamasida o‘zi o‘chiradi; ShieldGuard uning holatini tekshirgan deb da’vo qilmaydi. APK yuklab olish yoki tashqi installer universal bloklanmaydi. Bildirishnoma matni faylning haqiqatan Telegram’dan kelganini tasdiqlamaydi.
