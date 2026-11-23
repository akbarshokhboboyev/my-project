# Google Play tayyorgarligi

Final 3.1.0+4 audit (2026-11-23): target API36 amaldagi phone submission talabiga mos; [rasmiy target SDK talabi](https://developer.android.com/google/play/requirements/target-sdk). REQUEST_INSTALL_PACKAGES, QUERY_ALL_PACKAGES, overlay/admin/accessibility keng huquqlari qo‘shilmadi. Installer API ishlatilmaydi, user-controlled chooser va Android cheklovlari saqlanadi; [installer permission policy](https://support.google.com/googleplay/android-developer/answer/12085295), [visibility policy](https://support.google.com/googleplay/android-developer/answer/10158779). [16 KiB talabi](https://developer.android.com/guide/practices/page-sizes) final artifact/emu bilan alohida tekshiriladi. Play compliance approval, Data Safety submission, public policy URL, production signing va internal testing bu kod auditi bilan avtomatik tugallangan deb hisoblanmaydi. Yakuniy kuzatilgan dalillar FINAL_RELEASE_REPORT.md da.

V3 APK imzo va hash reputatsiya bo‘limlarini qo‘shadi. Flutter hash uchun har safar alohida rozilik oladi. Endpointni faollashtirishdan oldin provider litsenziyasi va Data Safety deklaratsiyasi tugallanishi kerak. store/ ichida 1024×500 feature graphic va 512×512 ikonka tayyor. store/screenshots/ ichida API37 emulyatordan 2 haqiqiy UI skrinshoti bor. Play internal testing hali bajarilmagan.

2026-11-22 sanasida tekshirildi. Android telefon ilovalari uchun 2026-08-31 dan yangi ilova va yangilanishlarga target API 36 talab qilinadi. Loyiha SDK 36 ishlatadi. [Target API siyosati](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)

- [x] O‘zbekcha nom, lokalizatsiya, ikonka, rozilik va privacy oynasi mavjud.
- [x] SMS, Accessibility, umumiy storage yoki VPN ruxsati qo‘shilmagan.
- [x] Release debugging o‘chirilgan, backup o‘chirilgan, PendingIntent immutable.
- [ ] Upload kaliti va Play App Signing sozlash.
- [ ] Ommaviy HTTPS maxfiylik siyosati URL’i, xizmat egasi va aloqa manzilini qo‘shish.
- [ ] Data Safety formasida ixtiyoriy to‘liq URL va SHA-256 uzatilishini deklaratsiya qilish.
- [ ] Notification access uchun ko‘rinadigan rozilik va foydalanish videosini tayyorlash.
- [ ] Content rating, App access, maqsadli auditoriya va security disclosure formalarini to‘ldirish.
- [x] 1024×500 feature graphic va 512×512 store ikonka.
- [x] Telefon o‘lchamidagi 2 haqiqiy UI skrinshoti, sintetik fixture natijasi aniq qayd etilgan.
- [ ] Play internal testing natijalari.
- [ ] AAB’ni imzolash, Play internal testing, pre-launch report va native library 16 KiB sahifa mosligini Play’da tasdiqlash.
- [ ] Billing budjeti, provayder shartlari va Web Risk attribution talablarini nashrdan oldin tekshirish.

Do‘kon uchun qisqa tavsif — «Havola, xabar va fayllardagi shubhali belgilarni o‘zbek tilida tekshiring.»

To‘liq tavsif — ShieldGuard qo‘lda havola va xabar tahlili, tanlangan fayllarning statik tekshiruvi va ruxsat berilgan Telegram bildirishnomalaridan firibgarlik belgilarini aniqlashga yordam beradi. Online Web Risk tekshiruvi alohida sozlash va rozilik bilan ishlaydi. Xavf topilmagani xavfsizlik kafolati bermaydi.

Data Safety javoblari haqiqiy deployment ma’lumot oqimiga mos to‘ldiriladi. Ushbu checklist Play tasdig‘ini bildirmaydi. [User Data](https://support.google.com/googleplay/android-developer/answer/10144311), [Play App Signing](https://developer.android.com/studio/publish/app-signing).
