// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class StringsUz extends Strings {
  StringsUz([String locale = 'uz']) : super(locale);

  @override
  String get home => 'Bosh sahifa';

  @override
  String get scan => 'Tekshirish';

  @override
  String get protection => 'Himoya';

  @override
  String get history => 'Tarix';

  @override
  String get settings => 'Sozlamalar';

  @override
  String get tagline => 'Raqamli xavfsizligingiz uchun';

  @override
  String get active => 'Himoya faol';

  @override
  String get inactive => 'Himoya o‘chirilgan';

  @override
  String get paused => 'Himoya vaqtincha to‘xtagan';

  @override
  String get noAlerts => 'Ogohlantirishlarga ruxsat kerak';

  @override
  String get noAccess => 'Bildirishnomalarga kirish ruxsati kerak';

  @override
  String get link => 'Havolani tekshirish';

  @override
  String get message => 'Xabarni tekshirish';

  @override
  String get file => 'Faylni tekshirish';

  @override
  String get notification => 'Avtomatik tekshiruv';

  @override
  String get automatic => 'Avtomatik himoya';

  @override
  String get manual => 'Qo‘lda tekshirish';

  @override
  String get choose => 'Faylni tanlash';

  @override
  String get pasteLink => 'Havolani yoki havolali xabarni joylang';

  @override
  String get pasteMessage => 'Shubhali xabar matnini joylang';

  @override
  String get clearInput => 'Matnni tozalash';

  @override
  String get working => 'Tekshirilmoqda';

  @override
  String get cancelled => 'Fayl tanlash bekor qilindi';

  @override
  String get failed => 'Amalni bajarib bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get unavailable => 'Qurilmada kerakli tizim oynasi mavjud emas.';

  @override
  String get busy => 'Boshqa tekshiruv davom etmoqda.';

  @override
  String get fileMissing => 'Fayl topilmadi.';

  @override
  String get filePermission => 'Faylni o‘qish uchun ruxsat yo‘q.';

  @override
  String get tooLarge => 'Fayl 128 MiB chegarasidan katta.';

  @override
  String get unknown => 'Fayl formati aniqlanmadi.';

  @override
  String get invalid => 'Havola noto‘g‘ri yoki qo‘llab-quvvatlanmaydi.';

  @override
  String get empty => 'Tekshirish uchun matn yoki havola kiriting.';

  @override
  String get result => 'Tekshiruv natijasi';

  @override
  String get low => 'Past xavf';

  @override
  String get caution => 'E’tibor talab etadi';

  @override
  String get high => 'Yuqori xavf';

  @override
  String get severe => 'Juda yuqori xavf';

  @override
  String get score => 'Xavf balli';

  @override
  String get confidence => 'Belgilar ishonchliligi';

  @override
  String get limited => 'Cheklangan';

  @override
  String get moderate => 'O‘rtacha';

  @override
  String get strong => 'Yuqori';

  @override
  String get source => 'Manba';

  @override
  String get local => 'Qurilmadagi mahalliy qoidalar';

  @override
  String get online => 'Internet orqali reputatsiya tekshirilmadi.';

  @override
  String get partial => 'Tekshiruv to‘liq bajarilmadi.';

  @override
  String get noFindings =>
      'Ma’lum xavf belgisi topilmadi. Xavfsizlik kafolatlanmaydi.';

  @override
  String get subject => 'Domen yoki fayl formati';

  @override
  String get why => 'Aniqlangan belgilar';

  @override
  String get limits => 'Tekshiruv chegaralari';

  @override
  String get advice => 'Tavsiya';

  @override
  String get linkLimit =>
      'Sahifa ochilmadi. Yo‘naltirishlar va sahifa mazmuni tekshirilmadi.';

  @override
  String get messageLimit =>
      'Bot yoki yuboruvchining haqiqiyligi tekshirilmadi.';

  @override
  String get fileLimit =>
      'Mahalliy statik tekshiruv ishlatildi. Arxiv ichidagi fayllar ochilmadi. Siqilgan PDF obyektlari va barcha zararli kodlar aniqlanmasligi mumkin.';

  @override
  String get alertLimit =>
      'Android taqdim etgan bildirishnoma matni mahalliy tekshirildi.';

  @override
  String get linkAdvice =>
      'Havola manbasini mustaqil tekshiring. Shubhali sahifaga parol yoki kod kiritmang.';

  @override
  String get messageAdvice =>
      'Tasdiqlash kodi va parolingizni yubormang. So‘rovni tanish aloqa yo‘li orqali tekshiring.';

  @override
  String get fileAdvice =>
      'Manbasini tekshirmaguncha faylni ochmang yoki o‘rnatmang.';

  @override
  String get http => 'Havola shifrlanmagan HTTP orqali ishlaydi.';

  @override
  String get userinfo =>
      'Havola tarkibida haqiqiy domenni yashirishi mumkin bo‘lgan foydalanuvchi qismi bor.';

  @override
  String get ip => 'Domen o‘rnida IP manzil ishlatilgan.';

  @override
  String get idn =>
      'Domen xalqaro belgilar yoki Punycode ishlatadi. O‘xshash harflarni tekshiring.';

  @override
  String get short => 'Qisqartirilgan havola yakuniy manzilni yashiradi.';

  @override
  String get brand => 'Domen nomi Telegram xizmatiga taqlid qilishi mumkin.';

  @override
  String get lure =>
      'Havolada kirish, tasdiqlash yoki sovg‘aga oid iboralar bor.';

  @override
  String get secret =>
      'Xabar maxfiy kod yoki parolni yuborish yoki kiritishni so‘raydi.';

  @override
  String get gift =>
      'Sovg‘a va’dasi maxfiy ma’lumot so‘rovi yoki shubhali havola bilan birga kelgan.';

  @override
  String get urgent => 'Xabar zudlik bilan harakat qilishga undaydi.';

  @override
  String get bot =>
      'Xabarda bot nomidan maxfiy ma’lumot so‘rovi yoki shubhali havola bor. Botning haqiqiyligi matndan tasdiqlanmaydi.';

  @override
  String get support =>
      'Xabar o‘zini yordam xizmati deb tanishtirib, maxfiy ma’lumot so‘raydi.';

  @override
  String get install =>
      'Xabar havola orqali dastur o‘rnatishga undashi mumkin.';

  @override
  String get messageLink => 'Xabarda firibgarlik belgilariga ega havola bor.';

  @override
  String get mismatch => 'Faylning ichki imzosi kengaytmasiga mos kelmaydi.';

  @override
  String get doubleExtension =>
      'Fayl nomida chalg‘ituvchi kengaytma yoki yo‘nalish belgisi bor.';

  @override
  String get structure => 'Faylning asosiy tuzilishi buzilgan yoki kutilmagan.';

  @override
  String get archiveLimit =>
      'Arxiv tekshiruv uchun belgilangan resurs chegarasidan oshdi.';

  @override
  String get executable => 'Bu Windows bajariladigan fayli.';

  @override
  String get pdfAction => 'PDF ichida avtomatik amal yoki skript belgisi bor.';

  @override
  String get pdfEmbedded => 'PDF ichiga fayl biriktirilgan bo‘lishi mumkin.';

  @override
  String get apkUnreadable => 'APK ma’lumotlarini o‘qib bo‘lmadi.';

  @override
  String get apkSms => 'APK qisqa xabarlarga oid sezgir ruxsat so‘raydi.';

  @override
  String get apkAccess =>
      'APK qurilmani boshqarish imkonini beruvchi maxsus xizmatni e’lon qilgan.';

  @override
  String get apkInstall =>
      'APK boshqa ilovalarni o‘rnatish ruxsatini so‘raydi.';

  @override
  String get apkCombo =>
      'APK qisqa xabarlar va internetdan birga foydalanishi mumkin.';

  @override
  String get disclosure =>
      'Android ushbu ruxsat orqali bildirishnomalarga kirish beradi. ShieldGuard faqat Telegram va Telegram X xabarlarining tizim ko‘rsatgan qismini qurilmada tahlil qiladi. Matn, kod va parollar yozib olinmaydi yoki uzatilmaydi.';

  @override
  String get enable => 'Roziman, himoyani yoqish';

  @override
  String get disable => 'Himoyani o‘chirish';

  @override
  String get grant => 'Ruxsat berish';

  @override
  String get grantAlerts => 'Ogohlantirishlarni yoqish';

  @override
  String get hidden =>
      'Maxfiy suhbatlar va Android yashirgan kodlar ko‘rinmasligi mumkin. Bunday xabarlarni qo‘lda tekshirishingiz mumkin.';

  @override
  String get guide => 'Telegram xavfsizlik qo‘llanmasi';

  @override
  String get twoFactor =>
      'Telegram sozlamalarida «Maxfiylik va xavfsizlik» bo‘limidan ikki bosqichli himoyani yoqing. Tiklash elektron pochtangizni himoyalang.';

  @override
  String get sessions =>
      'Telegram sozlamalarida «Qurilmalar» bo‘limini oching. Tanimagan seanslarni tugating.';

  @override
  String get codes =>
      'Tasdiqlash kodi va ikki bosqichli himoya parolini hech kimga yubormang.';

  @override
  String get report =>
      'Shubhali bot profilidagi menyudan uni bloklang va shikoyat yuboring.';

  @override
  String get incident =>
      'Begona kirishdan shubhalansangiz, ishonchli qurilmadan seanslarni tugating, himoya parolini yangilang va kontaktlaringizni ogohlantiring.';

  @override
  String get selfCheck =>
      'Bajarilgan ishlarni qo‘lda belgilang. ShieldGuard Telegram sozlamalarini o‘qimaydi.';

  @override
  String get historyOpt => 'Tekshiruv tarixini saqlash';

  @override
  String get historyDesc =>
      'Yozuvda faqat vaqt, tur, ball, belgilar soni va tekshiruv holati qoladi.';

  @override
  String get historyEmpty => 'Tekshiruv yozuvlari yo‘q.';

  @override
  String get clearHistory => 'Tarixni tozalash';

  @override
  String get confirmClear => 'Barcha tekshiruv yozuvlari o‘chirilsinmi?';

  @override
  String get later => 'Keyinroq';

  @override
  String get all => 'Hammasi';

  @override
  String get onlyRisk => 'Xavfli tekshiruvlar';

  @override
  String get date => 'Sana';

  @override
  String get last => 'Oxirgi yozuv';

  @override
  String get events => 'Yuqori xavfli yozuvlar';

  @override
  String get dark => 'Qorong‘i mavzu';

  @override
  String get privacy => 'Maxfiylik siyosati';

  @override
  String get privacyBody =>
      'Havola, xabar va fayl tahlili qurilmada amalga oshiriladi. Tarix ixtiyoriy. Xabar matni, to‘liq URL, parol, tasdiqlash kodi, fayl nomi yoki identifikatori tarixga yozilmaydi. Fayl nusxasi tekshiruv vaqtida vaqtincha saqlanadi va yakunda o‘chiriladi. Onlayn himoya alohida rozilik bilan qo‘lda tekshiriladigan to‘liq URL’ni serveringizga va Google Web Risk’ka yuboradi. Rozilik o‘chirilsa reputatsiya keshi tozalanadi.';

  @override
  String get about => 'Ilova haqida';

  @override
  String get aboutBody =>
      'ShieldGuard havola, xabar, APK va ruxsatli papkalarda shubhali statik belgilarni mahalliy tekshiradi. Versiya 3.1.0, yig‘ilish 4. Bu universal antivirus yoki zararsizlik kafolati emas. Onlayn tekshiruv alohida rozilik va sozlangan provider bilan ishlaydi.';

  @override
  String get help => 'Yordam';

  @override
  String get helpBody =>
      'Xabarni nusxalab ShieldGuard’ga joylang yoki boshqa ilovadagi ulashish menyusidan ShieldGuard’ni tanlang. Faylni tizim oynasi orqali ham tanlashingiz mumkin.';

  @override
  String get intro => 'ShieldGuard bilan tanishing';

  @override
  String get continueButton => 'Davom etish';

  @override
  String get done => 'Tugallangan';

  @override
  String get back => 'Orqaga';

  @override
  String get close => 'Yopish';

  @override
  String get signer => 'Imzolovchi sertifikat izi';

  @override
  String get onlineTitle => 'Onlayn himoya';

  @override
  String get onlineConsent =>
      'To‘liq URL serveringizga va Google Web Risk xizmatiga yuboriladi. URL ichida maxfiy token bo‘lishi mumkin. Faqat qo‘lda havola tekshiruviga rozilik beraman.';

  @override
  String get gateway => 'Himoyalangan server manzili';

  @override
  String get gatewayToken => 'Serverga kirish tokeni';

  @override
  String get gatewayHint =>
      'Token faqat joriy seans xotirasida qoladi. Server uchun API kaliti alohida sozlanadi.';

  @override
  String get reputationMatch => 'Web Risk tahdidlar bazasida moslik topildi.';

  @override
  String get repMatch => 'Web Risk bazasida tahdid mosligi bor.';

  @override
  String get repNoMatch =>
      'Web Risk bazasida moslik topilmadi. Xavfsizlik kafolatlanmaydi.';

  @override
  String get repDisabled => 'Onlayn tekshiruv o‘chirilgan.';

  @override
  String get repUnavailable =>
      'Onlayn manba javob bermadi. Mahalliy tahlil bajarildi.';

  @override
  String get repRateLimited => 'Onlayn so‘rovlar vaqtincha cheklangan.';

  @override
  String get repInvalidResponse => 'Onlayn manba yaroqsiz javob qaytardi.';

  @override
  String get repUnconfigured =>
      'Onlayn manba uchun HTTPS server va kirish tokeni kerak.';

  @override
  String get webRisk => 'Google Web Risk';

  @override
  String get webRiskCache => 'Google Web Risk mahalliy keshi';

  @override
  String get archivePath =>
      'Arxiv ichida tashqi yo‘lga ishora qiluvchi nom mavjud.';

  @override
  String get archiveNested =>
      'Arxiv ichida yana arxiv bor. Uning mazmuni tekshirilmadi.';

  @override
  String get archiveEmbedded =>
      'Office hujjatida makros yoki biriktirilgan dastur belgisi mavjud.';

  @override
  String get pdfUri => 'PDF tashqi manzilga murojaat qilishi mumkin.';

  @override
  String get scanTimeout => 'Tekshiruv vaqt chegarasiga yetdi.';

  @override
  String get scanCancelled => 'Tekshiruv bekor qilindi.';

  @override
  String get signatureUnchecked =>
      'APK imzosi yaxlitligi tekshirilmadi. Sertifikat izi nashriyotchining ishonchliligini tasdiqlamaydi.';

  @override
  String get apkExported =>
      'APK tashqi ilovalarga ochiq, ruxsat bilan himoyalanmagan komponentlarni e’lon qilgan.';

  @override
  String get testAlert => 'Sinov ogohlantirishini ko‘rsatish';

  @override
  String get testAlertTitle => 'ShieldGuard sinov ogohlantirishi';

  @override
  String get testAlertBody =>
      'Ogohlantirish kanali ishlamoqda. Bu sun’iy sinov.';

  @override
  String get metadata => 'Fayl metama’lumotlari';

  @override
  String get cancelScan => 'Tekshiruvni bekor qilish';

  @override
  String get versionCode => 'Versiya raqami';

  @override
  String get versionName => 'Versiya';

  @override
  String get minSdk => 'Eng eski Android API';

  @override
  String get targetSdk => 'Maqsadli Android API';

  @override
  String get permissions => 'So‘ralgan ruxsatlar';

  @override
  String get architecture => 'Protsessor turi kodi';

  @override
  String get sections => 'PE bo‘limlari soni';

  @override
  String get archiveDuplicate => 'Arxivda takroriy nomli elementlar bor.';

  @override
  String get contentLimit =>
      'Tanlangan kontentning bir qismi resurs chegarasi sabab tekshirilmadi.';

  @override
  String get dexMalformed =>
      'DEX tuzilishi buzilgan yoki qo‘llab-quvvatlanmaydi.';

  @override
  String get dexDynamic =>
      'DEX ichida dinamik kod yuklashga oid statik havola bor.';

  @override
  String get dexInstaller =>
      'DEX ichida ilova o‘rnatish API’siga statik havola bor.';

  @override
  String get dexAccessibility =>
      'DEX ichida maxsus imkoniyatlar xizmatiga statik havola bor.';

  @override
  String get dexNotification =>
      'DEX ichida bildirishnomalarga kirish xizmatiga statik havola bor.';

  @override
  String get elfMalformed => 'Native kutubxona ELF tuzilishi buzilgan.';

  @override
  String get signatureVerified =>
      'APK imzosi yaxlitligi tasdiqlandi. Bu ishlab chiquvchi ishonchliligini tasdiqlamaydi.';

  @override
  String get signatureFailed =>
      'APK imzosi yaxlitligini tekshirish muvaffaqiyatsiz.';

  @override
  String get signatureStatus => 'APK imzosi holati';

  @override
  String get verdictUnknown => 'Aniqlab bo‘lmadi';

  @override
  String get verdictPossible => 'Xavfli bo‘lishi mumkin';

  @override
  String get verdictNoFindings => 'Muhim xavf belgilari topilmadi';

  @override
  String get splitUnchecked =>
      'Ichki APK komponentining imzosi yoki metama’lumoti tekshirilmadi.';

  @override
  String get splitMismatch =>
      'Ichki APK komponentlarining paket yoki sertifikatlari mos kelmaydi.';

  @override
  String get unknownContainer => 'Fayl konteyneri to‘liq tekshirilmadi.';

  @override
  String get exportReport => 'Hisobotni nusxalash';

  @override
  String get hashLookup => 'Fayl xeshini onlayn tekshirish';

  @override
  String get hashDisclosure =>
      'Faylning SHA-256 izi serveringiz va VirusTotal xizmatiga yuboriladi. Fayl yuborilmaydi. Xeshni so‘rash ushbu faylga qiziqishingizni oshkor qilishi mumkin. Bu so‘rovga rozimisiz?';

  @override
  String get hashAllow => 'Roziman, xeshni tekshirish';

  @override
  String get hashStatusreported =>
      'VirusTotal tahlil hisoblari olindi. Ular zararli faoliyat tasdig‘i yoki ehtimol foizi emas.';

  @override
  String get hashStatusnoMatch =>
      'Reputatsiya bazasida fayl topilmadi. Xavfsizlik kafolatlanmaydi.';

  @override
  String get hashStatusdisabled => 'Xesh tekshiruvi o‘chirilgan.';

  @override
  String get hashStatusunconfigured =>
      'Xesh manbasi server credentiallari va mos litsenziyani talab qiladi.';

  @override
  String get hashStatusunavailable => 'Xesh manbasiga ulanish bajarilmadi.';

  @override
  String get hashStatusrateLimited => 'Xesh so‘rovlari vaqtincha cheklangan.';

  @override
  String get hashStatusinvalidResponse =>
      'Xesh manbasi yaroqsiz javob qaytardi.';

  @override
  String hashCounts(int malicious, int suspicious) {
    return 'Zararli deb belgilagan manbalar $malicious, shubhali deb belgilagan manbalar $suspicious.';
  }

  @override
  String get pdfEncrypted =>
      'PDF shifrlangan. Parol so‘ralmaydi, ichki tarkib tekshirilmadi.';

  @override
  String get pdfParseIncomplete =>
      'PDF obyektlarini to‘liq tahlil qilib bo‘lmadi.';

  @override
  String get pdfParsed => 'PDF obyektlari alohida jarayonda tahlil qilindi.';

  @override
  String get installedTitle => 'O‘rnatilgan ilovalar monitoringi';

  @override
  String get installedDisclosure =>
      'O‘rnatishdan keyingi lokal tekshiruv. Faol jarayonda paket hodisalari, fonda Android rejalashtirgan davriy tekshiruv ishlaydi. Kamida 15 daqiqalik interval, batareya va tizim cheklovlari sabab kechikishi mumkin. Faqat ko‘rinadigan paketlar qamrab olinadi; to‘liq himoya kafolati berilmaydi. Ilovalar ro‘yxati serverga yuborilmaydi.';

  @override
  String get installedScheduled => 'Davriy tekshiruv rejalashtirilgan.';

  @override
  String get installedUnscheduled => 'Davriy tekshiruv rejalashtirilmagan.';

  @override
  String get installedScan =>
      'Ko‘rinadigan ilovalarni tekshirishni rejalashtirish';

  @override
  String get installedReport => 'Oxirgi ilova hisobotini ko‘rish';

  @override
  String get installedStatenone => 'Hali tekshiruv natijasi yo‘q.';

  @override
  String get installedStatecontent =>
      'Oxirgi ilovaning metadata va chegaralangan APK kontenti tekshirildi.';

  @override
  String get installedStatemetadata =>
      'Oxirgi tekshiruv qisman: metadata yoki APK kontentining bir qismi o‘qildi.';

  @override
  String get installedStateunavailable =>
      'Paket ko‘rinmadi yoki metadata o‘qilmadi. Natija aniqlanmadi.';

  @override
  String get installedStatescheduleFailed =>
      'Android fon tekshiruvini rejalashtira olmadi.';

  @override
  String get installedCombo =>
      'Sezgir imkoniyatlar birga so‘ralgan: SMS/internet va APK o‘rnatish yoki Accessibility va overlay/o‘rnatish. Bu malware isboti emas.';

  @override
  String get installedTrustUnknown =>
      'Tasdiqlangan developer reference mavjud emas; noma’lum sertifikatning o‘zi xavf degani emas.';

  @override
  String get installedMetadataOnly =>
      'APK kontenti to‘liq tekshirilmadi. Metadata asosidagi natija cheklangan.';

  @override
  String get installedUnavailable =>
      'Ilova o‘chirilgan, ko‘rinmaydi yoki metadata o‘qishga ruxsat yo‘q.';

  @override
  String get installedPlatformSignature =>
      'Android o‘rnatilgan paketning joriy signing identity’sini berdi; barcha APK kontenti mustaqil tekshirilmagan.';

  @override
  String get installedPackage => 'Paket nomi';

  @override
  String get installedLabel => 'Ilova nomi';

  @override
  String get installedUpdated => 'Paketning oxirgi yangilanish vaqti';

  @override
  String get installedCoverage => 'Tekshiruv qamrovi';

  @override
  String get installedContent => 'Metadata va chegaralangan APK kontenti';

  @override
  String get installedPartial => 'Metadata va APK kontentining bir qismi';

  @override
  String get batchItem => 'Fayl tartibi';

  @override
  String get sharedInvalid =>
      'Fayl manzili qo‘llab-quvvatlanmaydi yoki noto‘g‘ri. Faylni tanlash orqali qayta tanlang.';

  @override
  String get sharedAdvice =>
      'Keyingi harakatni o‘zingiz tanlang: hisobotni nusxalash, boshqa faylni tanlash yoki fayl yuborgan ilovaga qaytish.';

  @override
  String get folderTitle => 'Papkalar xavfsizligi';

  @override
  String get folderDisclosure =>
      'Faqat o‘zingiz tanlagan papkalar o‘qish rejimida davriy tekshiriladi. 15 daqiqalik JobScheduler intervali batareya va Android cheklovlari sabab kechikishi mumkin; bu uzluksiz real-time himoya emas. Har yurishda 256 metadata, 8 fayl va 2 darajali ichki papka chegarasi bor. Fayllar serverga yuborilmaydi.';

  @override
  String get folderOffCleanup =>
      'Monitoringni o‘chirish tanlangan papkalar ro‘yxati, read ruxsatlari va monitoring keshini tozalaydi. Fayllarning o‘zi o‘zgartirilmaydi.';

  @override
  String get folderAdd => 'Papka qo‘shish';

  @override
  String get folderRemove => 'Papkani olib tashlash';

  @override
  String get folderPeriodic => 'Davriy papka tekshiruvini yoqish';

  @override
  String get folderNow => 'Hozir tekshirish';

  @override
  String get folderCancel => 'Joriy papka tekshiruvini bekor qilish';

  @override
  String get folderLast => 'Oxirgi tekshiruv';

  @override
  String get folderNever => 'Hali tekshirilmagan';

  @override
  String get folderCountvisited => 'Ko‘rilgan metadata';

  @override
  String get folderCountscanned => 'Tahlil qilingan fayllar';

  @override
  String get folderCountcached => 'O‘zgarmagan metadata: keshdan';

  @override
  String get folderCountunverified => 'Tekshirilmagan yoki incomplete (kamida)';

  @override
  String get folderIndicators => 'Xavf indikatorlari turlari';

  @override
  String get folderCoverageBounded =>
      'Oxirgi yurishda ruxsatli, chegaralangan qamrov ko‘rildi. Bu xavfsizlik kafolati emas.';

  @override
  String get folderCoveragePartial =>
      'Qamrov qisman yoki hali aniqlanmagan. Limitdan tashqari fayllar soni noma’lum bo‘lishi mumkin; xavfsiz deb tasdiqlanmaydi.';

  @override
  String get folderScheduled => 'Davriy papka job’i rejalashtirilgan.';

  @override
  String get folderUnscheduled => 'Davriy papka job’i rejalashtirilmagan.';

  @override
  String get folderGranted => 'O‘qish ruxsati bor.';

  @override
  String get folderPermission =>
      'Papka ruxsati yo‘q yoki bu joyni Android tanlashga ruxsat bermaydi. Papkani qayta tanlang.';

  @override
  String get folderUnnamed => 'Tanlangan papka';

  @override
  String get folderLimit => 'Ko‘pi bilan 4 ta papka tanlash mumkin.';

  @override
  String get folderCleanupPending =>
      'Ruxsatni qaytarish tugallanmagan. Monitoring to‘xtatilgan; keyingi ishga tushishda qayta tekshiriladi.';

  @override
  String get folderStateidle => 'Papka tekshiruvi kutilmoqda.';

  @override
  String get folderStaterunning => 'Papka tekshirilmoqda.';

  @override
  String get folderStatequeued => 'Tekshiruv OS navbatida.';

  @override
  String get folderStatedone => 'Oxirgi yurish tugadi.';

  @override
  String get folderStatepartial => 'Oxirgi yurish qisman tugadi.';

  @override
  String get folderStatedeferred => 'Android tekshiruvni keyinga qoldirdi.';

  @override
  String get folderStatecancelled => 'Joriy yurish bekor qilindi.';

  @override
  String get folderStatepermissionLost =>
      'Ruxsat yo‘qoldi. Monitoring to‘xtatildi; papkani qayta tanlang.';

  @override
  String get folderStateproviderError =>
      'DocumentProvider javob bermadi yoki xato qaytardi. Natija aniqlanmagan.';

  @override
  String get folderStatescheduleFailed =>
      'Android papka job’ini rejalashtira olmadi.';

  @override
  String get folderStateinterrupted =>
      'Oldingi yurish uzilgan; qamrov aniqlanmagan.';

  @override
  String get apkTitle => 'APK o‘rnatish himoyasi';

  @override
  String get apkBoundary =>
      'ShieldGuard faqat o‘zi boshqaradigan ochish/uzatish oqimini to‘xtata oladi. Telegram yoki fayl menejeridan bevosita Android installer orqali o‘rnatish bu gate’dan o‘tmaydi. Yuklab olish to‘xtatilmaydi. Yopiq Telegram papkasidagi faylni Share/Open orqali ShieldGuard’ga yuboring yoki ruxsatli SAF papka tanlang.';

  @override
  String get apkAutoBlock =>
      'Kuchli xavfda ShieldGuard orqali uzatishni bloklash';

  @override
  String get apkStrict => 'Qat’iy APK himoyasi';

  @override
  String get apkStrictHelp =>
      'Qat’iy rejim noma’lum yoki incomplete APK’ni ham uzatmaydi. Bu ehtiyot chorasi, virus tasdig‘i emas. Default o‘chiq.';

  @override
  String get apkAlerts =>
      'Ruxsatli papkadagi shubhali APK haqida bildirishnoma';

  @override
  String get apkAlertsHelp =>
      'Alohida rozilik. Davriy papka monitoringi yoqilgan va notification ruxsati bor bo‘lishi kerak. Heads-up ko‘rinishi Android sozlamalariga bog‘liq. Boshqa ilova ustiga modal chiqarilmaydi.';

  @override
  String get apkSources =>
      'Telegram orqali noma’lum APK o‘rnatilishini Android sozlamalarida taqiqlang. Telegram va boshqa o‘rnatish manbalari uchun Allow from this source ruxsatini o‘zingiz o‘chiring. ShieldGuard bu holatni yashirin o‘zgartirmaydi va tekshirildi deb da’vo qilmaydi.';

  @override
  String get apkSettings => 'O‘rnatish ruxsatlarini tekshirish';

  @override
  String get apkHistory => 'APK himoyasi tarixi';

  @override
  String get apkHistoryEmpty => 'APK himoyasi hodisalari yo‘q.';

  @override
  String get apkClear => 'APK tarixini tozalash';

  @override
  String get apkOffHelp =>
      'Avto-bloklashni o‘chirish qat’iy rejim, APK bildirishnomalari, lokal hisobot va kutilayotgan uzatish nusxalarini ham tozalaydi. Telegram, installed-app va papka scanner’i mustaqil qoladi.';

  @override
  String get apkBlockedTitle => 'APK BLOKLANDI';

  @override
  String get apkIncompleteTitle => 'APK uzatish to‘xtatildi';

  @override
  String get apkBlockedBody =>
      'ShieldGuard orqali ochish/o‘rnatishga uzatish to‘xtatildi. Bu fayl Android’ning boshqa yo‘lidan hali ham o‘rnatilishi mumkin.';

  @override
  String get apkAdvice =>
      'Shubhali APK’ni o‘rnatmang. Manbasini va imzosini tekshiring. Kerak bo‘lsa noma’lum manbadan o‘rnatish ruxsatini Android sozlamalarida o‘chiring. Noma’lum natija xavfsizlik kafolati emas.';

  @override
  String get apkDetails => 'Xavf tafsilotlari';

  @override
  String get apkAdviceButton => 'Xavfsizlik tavsiyalari';

  @override
  String get apkOpen => 'APK nusxasini boshqa ilovada ochish';

  @override
  String get apkForwardConfirm => 'Tashqi ilovaga uzatish';

  @override
  String get apkForwardHelp =>
      'Bu alohida harakatingiz bilan skanerlangan lokal APK nusxasini Android tanlov oynasiga uzatadi. Fayl avtomatik o‘rnatilmaydi. Natija zararsizlik kafolati emas. Android o‘rnatishni rad etishi mumkin; ShieldGuard installer huquqini so‘ramaydi.';

  @override
  String get apkProceed => 'Ogohlantirishni tushundim, uzatish';

  @override
  String get apkRiskconfirmedHighConfidenceThreat =>
      'Tasdiqlangan kuchli xavf dalili';

  @override
  String get apkRiskstrongSuspicion =>
      'Kuchli shubha: yaxlitlik yoki sezgir imkoniyatlar kombinatsiyasi';

  @override
  String get apkRiskheuristicWarning =>
      'Evristik ogohlantirish; malware tasdig‘i emas';

  @override
  String get apkRiskunknown => 'Noma’lum yoki tugallanmagan tekshiruv';

  @override
  String get apkRisknoFindings =>
      'Mavjud tekshiruvda xavf dalili topilmadi; kafolat emas';

  @override
  String get apkOutcomeBlocked => 'ShieldGuard uzatishni blokladi';

  @override
  String get apkOutcomeblockedByShieldGuard => 'ShieldGuard uzatishni blokladi';

  @override
  String get apkOutcomeblockedByAndroid =>
      'Android uzatish so‘rovini xavfsizlik xatosi bilan rad etdi';

  @override
  String get apkOutcomewarningOnly =>
      'Ogohlantirish; o‘rnatish bloklangani tasdiqlanmadi';

  @override
  String get apkOutcomescanIncomplete =>
      'Tekshiruv tugallanmagani sabab uzatish to‘xtatildi';

  @override
  String get apkOutcomenotIntercepted => 'ShieldGuard bu oqimni kuzatmagan';

  @override
  String get apkConfidencehigh =>
      'Dalilga ishonch: yuqori; malware tasdig‘iga teng emas';

  @override
  String get apkConfidencemedium => 'Dalilga ishonch: o‘rta';

  @override
  String get apkConfidencelimited => 'Dalilga ishonch: cheklangan';

  @override
  String get apkConfidenceundetermined => 'Dalilga ishonch: aniqlanmagan';

  @override
  String get apkExpired =>
      'APK nusxasi eskirgan yoki bekor qilingan. Faylni qayta tekshiring.';

  @override
  String get apkAndroidDenied =>
      'Android ochish so‘rovini rad etdi. Tizim cheklovi chetlab o‘tilmaydi.';

  @override
  String get apkDisabled => 'Avval APK uzatish himoyasini yoqing.';

  @override
  String get apkScanning => 'APK tekshirilmoqda...';

  @override
  String get apkUnavailableSnapshot =>
      'Xavfsiz uzatish nusxasi mavjud emas. Ruxsat va cheklovlarni tekshirib, faylni qayta skanerlang.';

  @override
  String get apkDialogBlockedTitle => 'APK BLOKLANDI';

  @override
  String get apkDialogBlockedBody =>
      'ShieldGuard ushbu APK’ni o‘rnatish jarayoniga uzatishni to‘xtatdi. Aniqlangan kuchli statik yoki yaxlitlik dalillari sabab uni o‘rnatmang.';

  @override
  String get apkDialogClearTitle => 'Tekshiruvda xavf belgisi topilmadi';

  @override
  String get apkDialogClearBody =>
      'ShieldGuard mavjud tekshiruvlarda shubhali belgi aniqlamadi. Bu faylning mutlaq xavfsizligini kafolatlamaydi.';

  @override
  String get apkDialogWarningTitle => 'Shubhali APK';

  @override
  String get apkDialogWarningBody =>
      'Ayrim shubhali indikatorlar bor, ammo bu malware tasdig‘i emas. Tavsiya etilgan xavfsiz amal — o‘rnatmaslik. Davom etish alohida ogohlantirish tasdig‘ini talab qiladi.';

  @override
  String get apkDialogUnknownTitle => 'Tekshiruv yakunlanmadi';

  @override
  String get apkDialogUnknownBody =>
      'Bu APK’ni yetarli darajada tekshirib bo‘lmadi. Ruxsat, vaqt yoki tahlil cheklovlarini tekshiring. Natija xavfsizlik tasdig‘i emas; qat’iy rejimda uzatish to‘xtatiladi.';

  @override
  String get apkDialogBoundary =>
      'Bu himoya faqat ShieldGuard orqali uzatishga tegishli. Boshqa manbadan Android installer’ga bevosita o‘tishni universal bloklay olmaydi. Fayl avtomatik o‘rnatilmaydi.';

  @override
  String get apkDoNotInstall => 'O‘rnatmaslik';

  @override
  String get apkCancel => 'Bekor qilish';

  @override
  String get apkInstallContinue => 'O‘rnatishga davom etish';

  @override
  String get apkHandoffRequested =>
      'Android tanlov oynasiga uzatish so‘raldi. Bu APK muvaffaqiyatli o‘rnatildi degani emas.';

  @override
  String get familyransomware => 'Ransomware statik indikatorlari';

  @override
  String get familyspyware => 'Keylogger / spyware statik indikatorlari';

  @override
  String get familybanking => 'Banking Trojan statik indikatorlari';

  @override
  String get familyrat => 'RAT statik indikatorlari';

  @override
  String get familyStatusstrongIndicators =>
      'Kuchli indikatorlar kombinatsiyasi';

  @override
  String get familyStatuspossibleIndicators =>
      'Ehtimoliy indikatorlar; malware tasdig‘i emas';

  @override
  String get familyStatusinsufficientEvidence =>
      'Yetarli dalil yoki qamrov yo‘q';

  @override
  String get familyStatusnoIndicatorsObserved =>
      'Mavjud tekshiruvda indikator kuzatilmadi';

  @override
  String get familyLimit =>
      'Bu faqat statik kod reference va manifest bahosi. Haqiqiy xatti-harakat yoki zararsizlik kafolati emas.';

  @override
  String get familyIncomplete => 'Ushbu baholash qamrovi tugallanmagan.';

  @override
  String get familyRansomwareExplanation =>
      'Crypto, fayl yozish/aylanib chiqish, keng storage, xizmat va to‘lov talabi belgilari birgalikda baholanadi. Crypto kutubxonasi yolg‘iz yetarli emas.';

  @override
  String get familySpywareExplanation =>
      'Kiritish hodisalari, accessibility/klaviatura, tarmoq va ma’lumot uzatish belgilarining birikmasi. Haqiqiy tugma bosishlari kuzatilmagan.';

  @override
  String get familyBankingExplanation =>
      'Accessibility, overlay, credential/OTP, bank nishoni va uzatish belgilarining birikmasi. Bank nomi yoki login oynasi yolg‘iz yetarli emas.';

  @override
  String get familyRatExplanation =>
      'Ekran boshqaruvi, process/remote command, tarmoq va yashirish belgilarining birikmasi. Qonuniy remote support funksiyasi yolg‘iz hukm emas.';

  @override
  String get familyRansomware =>
      'Ransomware bilan mos kuchli statik kombinatsiya aniqlandi.';

  @override
  String get familySpyware =>
      'Keylogger/spyware bilan mos kuchli statik kombinatsiya aniqlandi.';

  @override
  String get familyBanking =>
      'Banking Trojan bilan mos kuchli statik kombinatsiya aniqlandi.';

  @override
  String get familyRat => 'RAT bilan mos kuchli statik kombinatsiya aniqlandi.';

  @override
  String get familyRansomwarePossible =>
      'Crypto va fayl operatsiyalari kombinatsiyasi bor; ransomware tasdig‘i emas.';

  @override
  String get familySpywarePossible =>
      'Kiritish/tarmoq kombinatsiyasi bor; spyware tasdig‘i emas.';

  @override
  String get familyBankingPossible =>
      'Sezgir UI/tarmoq kombinatsiyasi bor; banking trojan tasdig‘i emas.';

  @override
  String get familyRatPossible =>
      'Remote-support bilan ham mos belgilar bor; RAT tasdig‘i emas.';

  @override
  String get evidencecryptoReference => 'Shifrlash API reference’i';

  @override
  String get evidencefileWriteReference => 'Fayl yozish API reference’i';

  @override
  String get evidencefileEnumerationReference =>
      'Fayllarni aylanib chiqish reference’i';

  @override
  String get evidenceransomDemandString =>
      'Shifrlash/to‘lov talabi bilan mos statik satr';

  @override
  String get evidencebroadStoragePermission =>
      'Keng storage imkoniyati manifestda e’lon qilingan';

  @override
  String get evidencedeclaredService =>
      'Manifestda xizmat e’lon qilingan; fonda ishlayotgani tasdiqlanmagan';

  @override
  String get evidenceaccessibilityService =>
      'Accessibility xizmati e’lon qilingan';

  @override
  String get evidencekeyboardService => 'Klaviatura xizmati e’lon qilingan';

  @override
  String get evidencenotificationService =>
      'Notification listener xizmati e’lon qilingan';

  @override
  String get evidenceoverlayPermission => 'Overlay ruxsati so‘ralgan';

  @override
  String get evidencesmsPermission =>
      'SMS o‘qish/qabul qilish ruxsati so‘ralgan';

  @override
  String get evidenceinputCaptureReference =>
      'Kiritish hodisalariga mos API reference’lari';

  @override
  String get evidencenetworkPermission => 'Internet ruxsati so‘ralgan';

  @override
  String get evidencenetworkCodeReference => 'Tarmoq API reference’i';

  @override
  String get evidencecredentialCaptureStrings =>
      'Credential/OTP kiritishga mos statik satrlar';

  @override
  String get evidencecaptureUploadString =>
      'Kiritilgan ma’lumotni uzatishga mos statik marker';

  @override
  String get evidencebankTargetStrings =>
      'Bank login/credential nishoniga mos statik marker';

  @override
  String get evidencescreenControlReference =>
      'Ekran/gesture boshqaruviga mos API reference’i';

  @override
  String get evidenceprocessExecutionReference =>
      'Process ishga tushirish API reference’i';

  @override
  String get evidenceremoteCommandString =>
      'Masofaviy buyruqqa mos statik marker';

  @override
  String get evidenceconcealmentString =>
      'Yashirish/himoyani o‘chirishga mos statik marker';

  @override
  String get evidencecameraPermission => 'Kamera ruxsati so‘ralgan';

  @override
  String get evidencemicrophonePermission => 'Mikrofon ruxsati so‘ralgan';

  @override
  String get knownMaliciousHash =>
      'Alohida rozilik bilan ishonchli provider bergan zararli xesh dalili';

  @override
  String get routeErrorTitle => 'ShieldGuard’ga qaytish';

  @override
  String get routeErrorBody =>
      'Bu manzil ilova sahifasi emas. APK yoki boshqa faylni tekshirish uchun uni ShieldGuard’ga qayta ulashing yoki bosh sahifadan faylni tanlang. Fayl tekshirilgan yoki xavfsiz deb hisoblanmaydi.';
}
