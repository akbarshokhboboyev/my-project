# Android bildirishnoma sinovlari

V3’dagi jonli Telegram testlari bajarilmadi. Pastdagi V2 sinov natijalari qayta bajarilgan V3 testi sifatida ko‘rsatilmaydi.

Telegram paketlari org.telegram.messenger, org.telegram.messenger.web va Telegram X org.thunderdog.challegram ro‘yxati saqlangan. Qurilmada pm list packages orqali mavjud paketlar tekshiriladi. Jonli Telegram sinovi faqat rozilik berilgan test akkaunti orqali bajariladi.

V2 sinov qurilmasida org.telegram.messenger mavjudligi tasdiqlandi. Google Play’dagi [Telegram](https://play.google.com/store/apps/details?id=org.telegram.messenger) va [Telegram X](https://play.google.com/store/apps/details?id=org.thunderdog.challegram) sahifalari paket nomlari uchun tekshirildi.

| Holat | V2 holati |
| --- | --- |
| Lokal Uzbek/Russian/English qoidalar | JVM regressiya to‘plamida tekshiriladi |
| Cooldown va bir xil matn deduplikatsiyasi | Vaqtinchalik tuzlangan xesh, JVM sinovi |
| Oddiy xabar, OTP maxfiyligi | Xom matn tarix va logga yozilmaydi |
| Listener ruxsati bekor qilish va qaytarish | Android 16’da xizmat uzildi va qayta ulandi |
| Sinov ogohlantirishi | Qurilmada chiqdi, bosilganda ShieldGuard ochildi |
| Jonli Telegram phishing/sovg‘a bildirishnomasi | Bajarilmadi |
| Telegram ogohlantirishini bosish | Bajarilmadi |
| Qayta yuklangan qurilma | Bajarilmadi |
| Android 13/14/15 variantlari | Bajarilmadi |

Android 15+ tizim yashirgan OTP yoki maxfiy kontent tahlilga kelmasligi mumkin. Ilova ushbu cheklovni aylanib o‘tmaydi. Avtomatik himoya uchun matn lokal ishlanadi. UI’dagi online rozilik bu xabarlarni serverga uzatmaydi.
