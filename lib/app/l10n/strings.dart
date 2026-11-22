import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'strings_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of Strings
/// returned by `Strings.of(context)`.
///
/// Applications need to include `Strings.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/strings.dart';
///
/// return MaterialApp(
///   localizationsDelegates: Strings.localizationsDelegates,
///   supportedLocales: Strings.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the Strings.supportedLocales
/// property.
abstract class Strings {
  Strings(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static Strings? of(BuildContext context) {
    return Localizations.of<Strings>(context, Strings);
  }

  static const LocalizationsDelegate<Strings> delegate = _StringsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('uz')];

  /// No description provided for @home.
  ///
  /// In uz, this message translates to:
  /// **'Bosh sahifa'**
  String get home;

  /// No description provided for @scan.
  ///
  /// In uz, this message translates to:
  /// **'Tekshirish'**
  String get scan;

  /// No description provided for @protection.
  ///
  /// In uz, this message translates to:
  /// **'Himoya'**
  String get protection;

  /// No description provided for @history.
  ///
  /// In uz, this message translates to:
  /// **'Tarix'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get settings;

  /// No description provided for @tagline.
  ///
  /// In uz, this message translates to:
  /// **'Raqamli xavfsizligingiz uchun'**
  String get tagline;

  /// No description provided for @active.
  ///
  /// In uz, this message translates to:
  /// **'Himoya faol'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In uz, this message translates to:
  /// **'Himoya o‘chirilgan'**
  String get inactive;

  /// No description provided for @paused.
  ///
  /// In uz, this message translates to:
  /// **'Himoya vaqtincha to‘xtagan'**
  String get paused;

  /// No description provided for @noAlerts.
  ///
  /// In uz, this message translates to:
  /// **'Ogohlantirishlarga ruxsat kerak'**
  String get noAlerts;

  /// No description provided for @noAccess.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalarga kirish ruxsati kerak'**
  String get noAccess;

  /// No description provided for @link.
  ///
  /// In uz, this message translates to:
  /// **'Havolani tekshirish'**
  String get link;

  /// No description provided for @message.
  ///
  /// In uz, this message translates to:
  /// **'Xabarni tekshirish'**
  String get message;

  /// No description provided for @file.
  ///
  /// In uz, this message translates to:
  /// **'Faylni tekshirish'**
  String get file;

  /// No description provided for @notification.
  ///
  /// In uz, this message translates to:
  /// **'Avtomatik tekshiruv'**
  String get notification;

  /// No description provided for @automatic.
  ///
  /// In uz, this message translates to:
  /// **'Avtomatik himoya'**
  String get automatic;

  /// No description provided for @manual.
  ///
  /// In uz, this message translates to:
  /// **'Qo‘lda tekshirish'**
  String get manual;

  /// No description provided for @choose.
  ///
  /// In uz, this message translates to:
  /// **'Faylni tanlash'**
  String get choose;

  /// No description provided for @pasteLink.
  ///
  /// In uz, this message translates to:
  /// **'Havolani yoki havolali xabarni joylang'**
  String get pasteLink;

  /// No description provided for @pasteMessage.
  ///
  /// In uz, this message translates to:
  /// **'Shubhali xabar matnini joylang'**
  String get pasteMessage;

  /// No description provided for @clearInput.
  ///
  /// In uz, this message translates to:
  /// **'Matnni tozalash'**
  String get clearInput;

  /// No description provided for @working.
  ///
  /// In uz, this message translates to:
  /// **'Tekshirilmoqda'**
  String get working;

  /// No description provided for @cancelled.
  ///
  /// In uz, this message translates to:
  /// **'Fayl tanlash bekor qilindi'**
  String get cancelled;

  /// No description provided for @failed.
  ///
  /// In uz, this message translates to:
  /// **'Amalni bajarib bo‘lmadi. Qayta urinib ko‘ring.'**
  String get failed;

  /// No description provided for @unavailable.
  ///
  /// In uz, this message translates to:
  /// **'Qurilmada kerakli tizim oynasi mavjud emas.'**
  String get unavailable;

  /// No description provided for @busy.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa tekshiruv davom etmoqda.'**
  String get busy;

  /// No description provided for @fileMissing.
  ///
  /// In uz, this message translates to:
  /// **'Fayl topilmadi.'**
  String get fileMissing;

  /// No description provided for @filePermission.
  ///
  /// In uz, this message translates to:
  /// **'Faylni o‘qish uchun ruxsat yo‘q.'**
  String get filePermission;

  /// No description provided for @tooLarge.
  ///
  /// In uz, this message translates to:
  /// **'Fayl 128 MiB chegarasidan katta.'**
  String get tooLarge;

  /// No description provided for @unknown.
  ///
  /// In uz, this message translates to:
  /// **'Fayl formati aniqlanmadi.'**
  String get unknown;

  /// No description provided for @invalid.
  ///
  /// In uz, this message translates to:
  /// **'Havola noto‘g‘ri yoki qo‘llab-quvvatlanmaydi.'**
  String get invalid;

  /// No description provided for @empty.
  ///
  /// In uz, this message translates to:
  /// **'Tekshirish uchun matn yoki havola kiriting.'**
  String get empty;

  /// No description provided for @result.
  ///
  /// In uz, this message translates to:
  /// **'Tekshiruv natijasi'**
  String get result;

  /// No description provided for @low.
  ///
  /// In uz, this message translates to:
  /// **'Past xavf'**
  String get low;

  /// No description provided for @caution.
  ///
  /// In uz, this message translates to:
  /// **'E’tibor talab etadi'**
  String get caution;

  /// No description provided for @high.
  ///
  /// In uz, this message translates to:
  /// **'Yuqori xavf'**
  String get high;

  /// No description provided for @severe.
  ///
  /// In uz, this message translates to:
  /// **'Juda yuqori xavf'**
  String get severe;

  /// No description provided for @score.
  ///
  /// In uz, this message translates to:
  /// **'Xavf balli'**
  String get score;

  /// No description provided for @confidence.
  ///
  /// In uz, this message translates to:
  /// **'Belgilar ishonchliligi'**
  String get confidence;

  /// No description provided for @limited.
  ///
  /// In uz, this message translates to:
  /// **'Cheklangan'**
  String get limited;

  /// No description provided for @moderate.
  ///
  /// In uz, this message translates to:
  /// **'O‘rtacha'**
  String get moderate;

  /// No description provided for @strong.
  ///
  /// In uz, this message translates to:
  /// **'Yuqori'**
  String get strong;

  /// No description provided for @source.
  ///
  /// In uz, this message translates to:
  /// **'Manba'**
  String get source;

  /// No description provided for @local.
  ///
  /// In uz, this message translates to:
  /// **'Qurilmadagi mahalliy qoidalar'**
  String get local;

  /// No description provided for @online.
  ///
  /// In uz, this message translates to:
  /// **'Internet orqali reputatsiya tekshirilmadi.'**
  String get online;

  /// No description provided for @partial.
  ///
  /// In uz, this message translates to:
  /// **'Tekshiruv to‘liq bajarilmadi.'**
  String get partial;

  /// No description provided for @noFindings.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lum xavf belgisi topilmadi. Xavfsizlik kafolatlanmaydi.'**
  String get noFindings;

  /// No description provided for @subject.
  ///
  /// In uz, this message translates to:
  /// **'Domen yoki fayl formati'**
  String get subject;

  /// No description provided for @why.
  ///
  /// In uz, this message translates to:
  /// **'Aniqlangan belgilar'**
  String get why;

  /// No description provided for @limits.
  ///
  /// In uz, this message translates to:
  /// **'Tekshiruv chegaralari'**
  String get limits;

  /// No description provided for @advice.
  ///
  /// In uz, this message translates to:
  /// **'Tavsiya'**
  String get advice;

  /// No description provided for @linkLimit.
  ///
  /// In uz, this message translates to:
  /// **'Sahifa ochilmadi. Yo‘naltirishlar va sahifa mazmuni tekshirilmadi.'**
  String get linkLimit;

  /// No description provided for @messageLimit.
  ///
  /// In uz, this message translates to:
  /// **'Bot yoki yuboruvchining haqiqiyligi tekshirilmadi.'**
  String get messageLimit;

  /// No description provided for @fileLimit.
  ///
  /// In uz, this message translates to:
  /// **'Mahalliy statik tekshiruv ishlatildi. Arxiv ichidagi fayllar ochilmadi. Siqilgan PDF obyektlari va barcha zararli kodlar aniqlanmasligi mumkin.'**
  String get fileLimit;

  /// No description provided for @alertLimit.
  ///
  /// In uz, this message translates to:
  /// **'Android taqdim etgan bildirishnoma matni mahalliy tekshirildi.'**
  String get alertLimit;

  /// No description provided for @linkAdvice.
  ///
  /// In uz, this message translates to:
  /// **'Havola manbasini mustaqil tekshiring. Shubhali sahifaga parol yoki kod kiritmang.'**
  String get linkAdvice;

  /// No description provided for @messageAdvice.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash kodi va parolingizni yubormang. So‘rovni tanish aloqa yo‘li orqali tekshiring.'**
  String get messageAdvice;

  /// No description provided for @fileAdvice.
  ///
  /// In uz, this message translates to:
  /// **'Manbasini tekshirmaguncha faylni ochmang yoki o‘rnatmang.'**
  String get fileAdvice;

  /// No description provided for @http.
  ///
  /// In uz, this message translates to:
  /// **'Havola shifrlanmagan HTTP orqali ishlaydi.'**
  String get http;

  /// No description provided for @userinfo.
  ///
  /// In uz, this message translates to:
  /// **'Havola tarkibida haqiqiy domenni yashirishi mumkin bo‘lgan foydalanuvchi qismi bor.'**
  String get userinfo;

  /// No description provided for @ip.
  ///
  /// In uz, this message translates to:
  /// **'Domen o‘rnida IP manzil ishlatilgan.'**
  String get ip;

  /// No description provided for @idn.
  ///
  /// In uz, this message translates to:
  /// **'Domen xalqaro belgilar yoki Punycode ishlatadi. O‘xshash harflarni tekshiring.'**
  String get idn;

  /// No description provided for @short.
  ///
  /// In uz, this message translates to:
  /// **'Qisqartirilgan havola yakuniy manzilni yashiradi.'**
  String get short;

  /// No description provided for @brand.
  ///
  /// In uz, this message translates to:
  /// **'Domen nomi Telegram xizmatiga taqlid qilishi mumkin.'**
  String get brand;

  /// No description provided for @lure.
  ///
  /// In uz, this message translates to:
  /// **'Havolada kirish, tasdiqlash yoki sovg‘aga oid iboralar bor.'**
  String get lure;

  /// No description provided for @secret.
  ///
  /// In uz, this message translates to:
  /// **'Xabar maxfiy kod yoki parolni yuborish yoki kiritishni so‘raydi.'**
  String get secret;

  /// No description provided for @gift.
  ///
  /// In uz, this message translates to:
  /// **'Sovg‘a va’dasi maxfiy ma’lumot so‘rovi yoki shubhali havola bilan birga kelgan.'**
  String get gift;

  /// No description provided for @urgent.
  ///
  /// In uz, this message translates to:
  /// **'Xabar zudlik bilan harakat qilishga undaydi.'**
  String get urgent;

  /// No description provided for @bot.
  ///
  /// In uz, this message translates to:
  /// **'Xabarda bot nomidan maxfiy ma’lumot so‘rovi yoki shubhali havola bor. Botning haqiqiyligi matndan tasdiqlanmaydi.'**
  String get bot;

  /// No description provided for @support.
  ///
  /// In uz, this message translates to:
  /// **'Xabar o‘zini yordam xizmati deb tanishtirib, maxfiy ma’lumot so‘raydi.'**
  String get support;

  /// No description provided for @install.
  ///
  /// In uz, this message translates to:
  /// **'Xabar havola orqali dastur o‘rnatishga undashi mumkin.'**
  String get install;

  /// No description provided for @messageLink.
  ///
  /// In uz, this message translates to:
  /// **'Xabarda firibgarlik belgilariga ega havola bor.'**
  String get messageLink;

  /// No description provided for @mismatch.
  ///
  /// In uz, this message translates to:
  /// **'Faylning ichki imzosi kengaytmasiga mos kelmaydi.'**
  String get mismatch;

  /// No description provided for @doubleExtension.
  ///
  /// In uz, this message translates to:
  /// **'Fayl nomida chalg‘ituvchi kengaytma yoki yo‘nalish belgisi bor.'**
  String get doubleExtension;

  /// No description provided for @structure.
  ///
  /// In uz, this message translates to:
  /// **'Faylning asosiy tuzilishi buzilgan yoki kutilmagan.'**
  String get structure;

  /// No description provided for @archiveLimit.
  ///
  /// In uz, this message translates to:
  /// **'Arxiv tekshiruv uchun belgilangan resurs chegarasidan oshdi.'**
  String get archiveLimit;

  /// No description provided for @executable.
  ///
  /// In uz, this message translates to:
  /// **'Bu Windows bajariladigan fayli.'**
  String get executable;

  /// No description provided for @pdfAction.
  ///
  /// In uz, this message translates to:
  /// **'PDF ichida avtomatik amal yoki skript belgisi bor.'**
  String get pdfAction;

  /// No description provided for @pdfEmbedded.
  ///
  /// In uz, this message translates to:
  /// **'PDF ichiga fayl biriktirilgan bo‘lishi mumkin.'**
  String get pdfEmbedded;

  /// No description provided for @apkUnreadable.
  ///
  /// In uz, this message translates to:
  /// **'APK ma’lumotlarini o‘qib bo‘lmadi.'**
  String get apkUnreadable;

  /// No description provided for @apkSms.
  ///
  /// In uz, this message translates to:
  /// **'APK qisqa xabarlarga oid sezgir ruxsat so‘raydi.'**
  String get apkSms;

  /// No description provided for @apkAccess.
  ///
  /// In uz, this message translates to:
  /// **'APK qurilmani boshqarish imkonini beruvchi maxsus xizmatni e’lon qilgan.'**
  String get apkAccess;

  /// No description provided for @apkInstall.
  ///
  /// In uz, this message translates to:
  /// **'APK boshqa ilovalarni o‘rnatish ruxsatini so‘raydi.'**
  String get apkInstall;

  /// No description provided for @apkCombo.
  ///
  /// In uz, this message translates to:
  /// **'APK qisqa xabarlar va internetdan birga foydalanishi mumkin.'**
  String get apkCombo;

  /// No description provided for @disclosure.
  ///
  /// In uz, this message translates to:
  /// **'Android ushbu ruxsat orqali bildirishnomalarga kirish beradi. ShieldGuard faqat Telegram va Telegram X xabarlarining tizim ko‘rsatgan qismini qurilmada tahlil qiladi. Matn, kod va parollar yozib olinmaydi yoki uzatilmaydi.'**
  String get disclosure;

  /// No description provided for @enable.
  ///
  /// In uz, this message translates to:
  /// **'Roziman, himoyani yoqish'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In uz, this message translates to:
  /// **'Himoyani o‘chirish'**
  String get disable;

  /// No description provided for @grant.
  ///
  /// In uz, this message translates to:
  /// **'Ruxsat berish'**
  String get grant;

  /// No description provided for @grantAlerts.
  ///
  /// In uz, this message translates to:
  /// **'Ogohlantirishlarni yoqish'**
  String get grantAlerts;

  /// No description provided for @hidden.
  ///
  /// In uz, this message translates to:
  /// **'Maxfiy suhbatlar va Android yashirgan kodlar ko‘rinmasligi mumkin. Bunday xabarlarni qo‘lda tekshirishingiz mumkin.'**
  String get hidden;

  /// No description provided for @guide.
  ///
  /// In uz, this message translates to:
  /// **'Telegram xavfsizlik qo‘llanmasi'**
  String get guide;

  /// No description provided for @twoFactor.
  ///
  /// In uz, this message translates to:
  /// **'Telegram sozlamalarida «Maxfiylik va xavfsizlik» bo‘limidan ikki bosqichli himoyani yoqing. Tiklash elektron pochtangizni himoyalang.'**
  String get twoFactor;

  /// No description provided for @sessions.
  ///
  /// In uz, this message translates to:
  /// **'Telegram sozlamalarida «Qurilmalar» bo‘limini oching. Tanimagan seanslarni tugating.'**
  String get sessions;

  /// No description provided for @codes.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash kodi va ikki bosqichli himoya parolini hech kimga yubormang.'**
  String get codes;

  /// No description provided for @report.
  ///
  /// In uz, this message translates to:
  /// **'Shubhali bot profilidagi menyudan uni bloklang va shikoyat yuboring.'**
  String get report;

  /// No description provided for @incident.
  ///
  /// In uz, this message translates to:
  /// **'Begona kirishdan shubhalansangiz, ishonchli qurilmadan seanslarni tugating, himoya parolini yangilang va kontaktlaringizni ogohlantiring.'**
  String get incident;

  /// No description provided for @selfCheck.
  ///
  /// In uz, this message translates to:
  /// **'Bajarilgan ishlarni qo‘lda belgilang. ShieldGuard Telegram sozlamalarini o‘qimaydi.'**
  String get selfCheck;

  /// No description provided for @historyOpt.
  ///
  /// In uz, this message translates to:
  /// **'Tekshiruv tarixini saqlash'**
  String get historyOpt;

  /// No description provided for @historyDesc.
  ///
  /// In uz, this message translates to:
  /// **'Yozuvda faqat vaqt, tur, ball, belgilar soni va tekshiruv holati qoladi.'**
  String get historyDesc;

  /// No description provided for @historyEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Tekshiruv yozuvlari yo‘q.'**
  String get historyEmpty;

  /// No description provided for @clearHistory.
  ///
  /// In uz, this message translates to:
  /// **'Tarixni tozalash'**
  String get clearHistory;

  /// No description provided for @confirmClear.
  ///
  /// In uz, this message translates to:
  /// **'Barcha tekshiruv yozuvlari o‘chirilsinmi?'**
  String get confirmClear;

  /// No description provided for @later.
  ///
  /// In uz, this message translates to:
  /// **'Keyinroq'**
  String get later;

  /// No description provided for @all.
  ///
  /// In uz, this message translates to:
  /// **'Hammasi'**
  String get all;

  /// No description provided for @onlyRisk.
  ///
  /// In uz, this message translates to:
  /// **'Xavfli tekshiruvlar'**
  String get onlyRisk;

  /// No description provided for @date.
  ///
  /// In uz, this message translates to:
  /// **'Sana'**
  String get date;

  /// No description provided for @last.
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi yozuv'**
  String get last;

  /// No description provided for @events.
  ///
  /// In uz, this message translates to:
  /// **'Yuqori xavfli yozuvlar'**
  String get events;

  /// No description provided for @dark.
  ///
  /// In uz, this message translates to:
  /// **'Qorong‘i mavzu'**
  String get dark;

  /// No description provided for @privacy.
  ///
  /// In uz, this message translates to:
  /// **'Maxfiylik siyosati'**
  String get privacy;

  /// No description provided for @privacyBody.
  ///
  /// In uz, this message translates to:
  /// **'Havola, xabar va fayl tahlili qurilmada amalga oshiriladi. Tarix ixtiyoriy. Xabar matni, to‘liq URL, parol, tasdiqlash kodi, fayl nomi yoki identifikatori tarixga yozilmaydi. Fayl nusxasi tekshiruv vaqtida vaqtincha saqlanadi va yakunda o‘chiriladi. Onlayn himoya alohida rozilik bilan qo‘lda tekshiriladigan to‘liq URL’ni serveringizga va Google Web Risk’ka yuboradi. Rozilik o‘chirilsa reputatsiya keshi tozalanadi.'**
  String get privacyBody;

  /// No description provided for @about.
  ///
  /// In uz, this message translates to:
  /// **'Ilova haqida'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In uz, this message translates to:
  /// **'ShieldGuard havola, xabar va fayllarda shubhali belgilarni mahalliy qoidalar bilan aniqlaydi. Versiya 3.0.0, yig‘ilish 3. Onlayn manba — alohida sozlanadigan Google Web Risk.'**
  String get aboutBody;

  /// No description provided for @help.
  ///
  /// In uz, this message translates to:
  /// **'Yordam'**
  String get help;

  /// No description provided for @helpBody.
  ///
  /// In uz, this message translates to:
  /// **'Xabarni nusxalab ShieldGuard’ga joylang yoki boshqa ilovadagi ulashish menyusidan ShieldGuard’ni tanlang. Faylni tizim oynasi orqali ham tanlashingiz mumkin.'**
  String get helpBody;

  /// No description provided for @intro.
  ///
  /// In uz, this message translates to:
  /// **'ShieldGuard bilan tanishing'**
  String get intro;

  /// No description provided for @continueButton.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get continueButton;

  /// No description provided for @done.
  ///
  /// In uz, this message translates to:
  /// **'Tugallangan'**
  String get done;

  /// No description provided for @back.
  ///
  /// In uz, this message translates to:
  /// **'Orqaga'**
  String get back;

  /// No description provided for @close.
  ///
  /// In uz, this message translates to:
  /// **'Yopish'**
  String get close;

  /// No description provided for @signer.
  ///
  /// In uz, this message translates to:
  /// **'Imzolovchi sertifikat izi'**
  String get signer;

  /// No description provided for @onlineTitle.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn himoya'**
  String get onlineTitle;

  /// No description provided for @onlineConsent.
  ///
  /// In uz, this message translates to:
  /// **'To‘liq URL serveringizga va Google Web Risk xizmatiga yuboriladi. URL ichida maxfiy token bo‘lishi mumkin. Faqat qo‘lda havola tekshiruviga rozilik beraman.'**
  String get onlineConsent;

  /// No description provided for @gateway.
  ///
  /// In uz, this message translates to:
  /// **'Himoyalangan server manzili'**
  String get gateway;

  /// No description provided for @gatewayToken.
  ///
  /// In uz, this message translates to:
  /// **'Serverga kirish tokeni'**
  String get gatewayToken;

  /// No description provided for @gatewayHint.
  ///
  /// In uz, this message translates to:
  /// **'Token faqat joriy seans xotirasida qoladi. Server uchun API kaliti alohida sozlanadi.'**
  String get gatewayHint;

  /// No description provided for @reputationMatch.
  ///
  /// In uz, this message translates to:
  /// **'Web Risk tahdidlar bazasida moslik topildi.'**
  String get reputationMatch;

  /// No description provided for @repMatch.
  ///
  /// In uz, this message translates to:
  /// **'Web Risk bazasida tahdid mosligi bor.'**
  String get repMatch;

  /// No description provided for @repNoMatch.
  ///
  /// In uz, this message translates to:
  /// **'Web Risk bazasida moslik topilmadi. Xavfsizlik kafolatlanmaydi.'**
  String get repNoMatch;

  /// No description provided for @repDisabled.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn tekshiruv o‘chirilgan.'**
  String get repDisabled;

  /// No description provided for @repUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn manba javob bermadi. Mahalliy tahlil bajarildi.'**
  String get repUnavailable;

  /// No description provided for @repRateLimited.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn so‘rovlar vaqtincha cheklangan.'**
  String get repRateLimited;

  /// No description provided for @repInvalidResponse.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn manba yaroqsiz javob qaytardi.'**
  String get repInvalidResponse;

  /// No description provided for @repUnconfigured.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn manba uchun HTTPS server va kirish tokeni kerak.'**
  String get repUnconfigured;

  /// No description provided for @webRisk.
  ///
  /// In uz, this message translates to:
  /// **'Google Web Risk'**
  String get webRisk;

  /// No description provided for @webRiskCache.
  ///
  /// In uz, this message translates to:
  /// **'Google Web Risk mahalliy keshi'**
  String get webRiskCache;

  /// No description provided for @archivePath.
  ///
  /// In uz, this message translates to:
  /// **'Arxiv ichida tashqi yo‘lga ishora qiluvchi nom mavjud.'**
  String get archivePath;

  /// No description provided for @archiveNested.
  ///
  /// In uz, this message translates to:
  /// **'Arxiv ichida yana arxiv bor. Uning mazmuni tekshirilmadi.'**
  String get archiveNested;

  /// No description provided for @archiveEmbedded.
  ///
  /// In uz, this message translates to:
  /// **'Office hujjatida makros yoki biriktirilgan dastur belgisi mavjud.'**
  String get archiveEmbedded;

  /// No description provided for @pdfUri.
  ///
  /// In uz, this message translates to:
  /// **'PDF tashqi manzilga murojaat qilishi mumkin.'**
  String get pdfUri;

  /// No description provided for @scanTimeout.
  ///
  /// In uz, this message translates to:
  /// **'Tekshiruv vaqt chegarasiga yetdi.'**
  String get scanTimeout;

  /// No description provided for @scanCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Tekshiruv bekor qilindi.'**
  String get scanCancelled;

  /// No description provided for @signatureUnchecked.
  ///
  /// In uz, this message translates to:
  /// **'APK imzosi yaxlitligi tekshirilmadi. Sertifikat izi nashriyotchining ishonchliligini tasdiqlamaydi.'**
  String get signatureUnchecked;

  /// No description provided for @apkExported.
  ///
  /// In uz, this message translates to:
  /// **'APK tashqi ilovalarga ochiq, ruxsat bilan himoyalanmagan komponentlarni e’lon qilgan.'**
  String get apkExported;

  /// No description provided for @testAlert.
  ///
  /// In uz, this message translates to:
  /// **'Sinov ogohlantirishini ko‘rsatish'**
  String get testAlert;

  /// No description provided for @testAlertTitle.
  ///
  /// In uz, this message translates to:
  /// **'ShieldGuard sinov ogohlantirishi'**
  String get testAlertTitle;

  /// No description provided for @testAlertBody.
  ///
  /// In uz, this message translates to:
  /// **'Ogohlantirish kanali ishlamoqda. Bu sun’iy sinov.'**
  String get testAlertBody;

  /// No description provided for @metadata.
  ///
  /// In uz, this message translates to:
  /// **'Fayl metama’lumotlari'**
  String get metadata;

  /// No description provided for @cancelScan.
  ///
  /// In uz, this message translates to:
  /// **'Tekshiruvni bekor qilish'**
  String get cancelScan;

  /// No description provided for @versionCode.
  ///
  /// In uz, this message translates to:
  /// **'Versiya raqami'**
  String get versionCode;

  /// No description provided for @versionName.
  ///
  /// In uz, this message translates to:
  /// **'Versiya'**
  String get versionName;

  /// No description provided for @minSdk.
  ///
  /// In uz, this message translates to:
  /// **'Eng eski Android API'**
  String get minSdk;

  /// No description provided for @targetSdk.
  ///
  /// In uz, this message translates to:
  /// **'Maqsadli Android API'**
  String get targetSdk;

  /// No description provided for @permissions.
  ///
  /// In uz, this message translates to:
  /// **'So‘ralgan ruxsatlar'**
  String get permissions;

  /// No description provided for @architecture.
  ///
  /// In uz, this message translates to:
  /// **'Protsessor turi kodi'**
  String get architecture;

  /// No description provided for @sections.
  ///
  /// In uz, this message translates to:
  /// **'PE bo‘limlari soni'**
  String get sections;

  /// No description provided for @archiveDuplicate.
  ///
  /// In uz, this message translates to:
  /// **'Arxivda takroriy nomli elementlar bor.'**
  String get archiveDuplicate;

  /// No description provided for @contentLimit.
  ///
  /// In uz, this message translates to:
  /// **'Tanlangan kontentning bir qismi resurs chegarasi sabab tekshirilmadi.'**
  String get contentLimit;

  /// No description provided for @dexMalformed.
  ///
  /// In uz, this message translates to:
  /// **'DEX tuzilishi buzilgan yoki qo‘llab-quvvatlanmaydi.'**
  String get dexMalformed;

  /// No description provided for @dexDynamic.
  ///
  /// In uz, this message translates to:
  /// **'DEX ichida dinamik kod yuklashga oid statik havola bor.'**
  String get dexDynamic;

  /// No description provided for @dexInstaller.
  ///
  /// In uz, this message translates to:
  /// **'DEX ichida ilova o‘rnatish API’siga statik havola bor.'**
  String get dexInstaller;

  /// No description provided for @dexAccessibility.
  ///
  /// In uz, this message translates to:
  /// **'DEX ichida maxsus imkoniyatlar xizmatiga statik havola bor.'**
  String get dexAccessibility;

  /// No description provided for @dexNotification.
  ///
  /// In uz, this message translates to:
  /// **'DEX ichida bildirishnomalarga kirish xizmatiga statik havola bor.'**
  String get dexNotification;

  /// No description provided for @elfMalformed.
  ///
  /// In uz, this message translates to:
  /// **'Native kutubxona ELF tuzilishi buzilgan.'**
  String get elfMalformed;

  /// No description provided for @signatureVerified.
  ///
  /// In uz, this message translates to:
  /// **'APK imzosi yaxlitligi tasdiqlandi. Bu ishlab chiquvchi ishonchliligini tasdiqlamaydi.'**
  String get signatureVerified;

  /// No description provided for @signatureFailed.
  ///
  /// In uz, this message translates to:
  /// **'APK imzosi yaxlitligini tekshirish muvaffaqiyatsiz.'**
  String get signatureFailed;

  /// No description provided for @signatureStatus.
  ///
  /// In uz, this message translates to:
  /// **'APK imzosi holati'**
  String get signatureStatus;

  /// No description provided for @verdictUnknown.
  ///
  /// In uz, this message translates to:
  /// **'Aniqlab bo‘lmadi'**
  String get verdictUnknown;

  /// No description provided for @verdictPossible.
  ///
  /// In uz, this message translates to:
  /// **'Xavfli bo‘lishi mumkin'**
  String get verdictPossible;

  /// No description provided for @verdictNoFindings.
  ///
  /// In uz, this message translates to:
  /// **'Muhim xavf belgilari topilmadi'**
  String get verdictNoFindings;

  /// No description provided for @splitUnchecked.
  ///
  /// In uz, this message translates to:
  /// **'Ichki APK komponentining imzosi yoki metama’lumoti tekshirilmadi.'**
  String get splitUnchecked;

  /// No description provided for @splitMismatch.
  ///
  /// In uz, this message translates to:
  /// **'Ichki APK komponentlarining paket yoki sertifikatlari mos kelmaydi.'**
  String get splitMismatch;

  /// No description provided for @unknownContainer.
  ///
  /// In uz, this message translates to:
  /// **'Fayl konteyneri to‘liq tekshirilmadi.'**
  String get unknownContainer;

  /// No description provided for @exportReport.
  ///
  /// In uz, this message translates to:
  /// **'Hisobotni nusxalash'**
  String get exportReport;

  /// No description provided for @hashLookup.
  ///
  /// In uz, this message translates to:
  /// **'Fayl xeshini onlayn tekshirish'**
  String get hashLookup;

  /// No description provided for @hashDisclosure.
  ///
  /// In uz, this message translates to:
  /// **'Faylning SHA-256 izi serveringiz va VirusTotal xizmatiga yuboriladi. Fayl yuborilmaydi. Xeshni so‘rash ushbu faylga qiziqishingizni oshkor qilishi mumkin. Bu so‘rovga rozimisiz?'**
  String get hashDisclosure;

  /// No description provided for @hashAllow.
  ///
  /// In uz, this message translates to:
  /// **'Roziman, xeshni tekshirish'**
  String get hashAllow;

  /// No description provided for @hashStatusreported.
  ///
  /// In uz, this message translates to:
  /// **'VirusTotal tahlil hisoblari olindi. Ular zararli faoliyat tasdig‘i yoki ehtimol foizi emas.'**
  String get hashStatusreported;

  /// No description provided for @hashStatusnoMatch.
  ///
  /// In uz, this message translates to:
  /// **'Reputatsiya bazasida fayl topilmadi. Xavfsizlik kafolatlanmaydi.'**
  String get hashStatusnoMatch;

  /// No description provided for @hashStatusdisabled.
  ///
  /// In uz, this message translates to:
  /// **'Xesh tekshiruvi o‘chirilgan.'**
  String get hashStatusdisabled;

  /// No description provided for @hashStatusunconfigured.
  ///
  /// In uz, this message translates to:
  /// **'Xesh manbasi server credentiallari va mos litsenziyani talab qiladi.'**
  String get hashStatusunconfigured;

  /// No description provided for @hashStatusunavailable.
  ///
  /// In uz, this message translates to:
  /// **'Xesh manbasiga ulanish bajarilmadi.'**
  String get hashStatusunavailable;

  /// No description provided for @hashStatusrateLimited.
  ///
  /// In uz, this message translates to:
  /// **'Xesh so‘rovlari vaqtincha cheklangan.'**
  String get hashStatusrateLimited;

  /// No description provided for @hashStatusinvalidResponse.
  ///
  /// In uz, this message translates to:
  /// **'Xesh manbasi yaroqsiz javob qaytardi.'**
  String get hashStatusinvalidResponse;

  /// No description provided for @hashCounts.
  ///
  /// In uz, this message translates to:
  /// **'Zararli deb belgilagan manbalar {malicious}, shubhali deb belgilagan manbalar {suspicious}.'**
  String hashCounts(int malicious, int suspicious);

  /// No description provided for @pdfEncrypted.
  ///
  /// In uz, this message translates to:
  /// **'PDF shifrlangan. Parol so‘ralmaydi, ichki tarkib tekshirilmadi.'**
  String get pdfEncrypted;

  /// No description provided for @pdfParseIncomplete.
  ///
  /// In uz, this message translates to:
  /// **'PDF obyektlarini to‘liq tahlil qilib bo‘lmadi.'**
  String get pdfParseIncomplete;

  /// No description provided for @pdfParsed.
  ///
  /// In uz, this message translates to:
  /// **'PDF obyektlari alohida jarayonda tahlil qilindi.'**
  String get pdfParsed;

  /// No description provided for @installedTitle.
  ///
  /// In uz, this message translates to:
  /// **'O‘rnatilgan ilovalar monitoringi'**
  String get installedTitle;

  /// No description provided for @installedDisclosure.
  ///
  /// In uz, this message translates to:
  /// **'O‘rnatishdan keyingi lokal tekshiruv. Faol jarayonda paket hodisalari, fonda Android rejalashtirgan davriy tekshiruv ishlaydi. Kamida 15 daqiqalik interval, batareya va tizim cheklovlari sabab kechikishi mumkin. Faqat ko‘rinadigan paketlar qamrab olinadi; to‘liq himoya kafolati berilmaydi. Ilovalar ro‘yxati serverga yuborilmaydi.'**
  String get installedDisclosure;

  /// No description provided for @installedScheduled.
  ///
  /// In uz, this message translates to:
  /// **'Davriy tekshiruv rejalashtirilgan.'**
  String get installedScheduled;

  /// No description provided for @installedUnscheduled.
  ///
  /// In uz, this message translates to:
  /// **'Davriy tekshiruv rejalashtirilmagan.'**
  String get installedUnscheduled;

  /// No description provided for @installedScan.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘rinadigan ilovalarni tekshirishni rejalashtirish'**
  String get installedScan;

  /// No description provided for @installedReport.
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi ilova hisobotini ko‘rish'**
  String get installedReport;

  /// No description provided for @installedStatenone.
  ///
  /// In uz, this message translates to:
  /// **'Hali tekshiruv natijasi yo‘q.'**
  String get installedStatenone;

  /// No description provided for @installedStatecontent.
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi ilovaning metadata va chegaralangan APK kontenti tekshirildi.'**
  String get installedStatecontent;

  /// No description provided for @installedStatemetadata.
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi tekshiruv qisman: metadata yoki APK kontentining bir qismi o‘qildi.'**
  String get installedStatemetadata;

  /// No description provided for @installedStateunavailable.
  ///
  /// In uz, this message translates to:
  /// **'Paket ko‘rinmadi yoki metadata o‘qilmadi. Natija aniqlanmadi.'**
  String get installedStateunavailable;

  /// No description provided for @installedStatescheduleFailed.
  ///
  /// In uz, this message translates to:
  /// **'Android fon tekshiruvini rejalashtira olmadi.'**
  String get installedStatescheduleFailed;

  /// No description provided for @installedCombo.
  ///
  /// In uz, this message translates to:
  /// **'Sezgir imkoniyatlar birga so‘ralgan: SMS/internet va APK o‘rnatish yoki Accessibility va overlay/o‘rnatish. Bu malware isboti emas.'**
  String get installedCombo;

  /// No description provided for @installedTrustUnknown.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlangan developer reference mavjud emas; noma’lum sertifikatning o‘zi xavf degani emas.'**
  String get installedTrustUnknown;

  /// No description provided for @installedMetadataOnly.
  ///
  /// In uz, this message translates to:
  /// **'APK kontenti to‘liq tekshirilmadi. Metadata asosidagi natija cheklangan.'**
  String get installedMetadataOnly;

  /// No description provided for @installedUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Ilova o‘chirilgan, ko‘rinmaydi yoki metadata o‘qishga ruxsat yo‘q.'**
  String get installedUnavailable;

  /// No description provided for @installedPlatformSignature.
  ///
  /// In uz, this message translates to:
  /// **'Android o‘rnatilgan paketning joriy signing identity’sini berdi; barcha APK kontenti mustaqil tekshirilmagan.'**
  String get installedPlatformSignature;

  /// No description provided for @installedPackage.
  ///
  /// In uz, this message translates to:
  /// **'Paket nomi'**
  String get installedPackage;

  /// No description provided for @installedLabel.
  ///
  /// In uz, this message translates to:
  /// **'Ilova nomi'**
  String get installedLabel;

  /// No description provided for @installedUpdated.
  ///
  /// In uz, this message translates to:
  /// **'Paketning oxirgi yangilanish vaqti'**
  String get installedUpdated;

  /// No description provided for @installedCoverage.
  ///
  /// In uz, this message translates to:
  /// **'Tekshiruv qamrovi'**
  String get installedCoverage;

  /// No description provided for @installedContent.
  ///
  /// In uz, this message translates to:
  /// **'Metadata va chegaralangan APK kontenti'**
  String get installedContent;

  /// No description provided for @installedPartial.
  ///
  /// In uz, this message translates to:
  /// **'Metadata va APK kontentining bir qismi'**
  String get installedPartial;

  /// No description provided for @batchItem.
  ///
  /// In uz, this message translates to:
  /// **'Fayl tartibi'**
  String get batchItem;

  /// No description provided for @sharedInvalid.
  ///
  /// In uz, this message translates to:
  /// **'Fayl manzili qo‘llab-quvvatlanmaydi yoki noto‘g‘ri. Faylni tanlash orqali qayta tanlang.'**
  String get sharedInvalid;

  /// No description provided for @sharedAdvice.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi harakatni o‘zingiz tanlang: hisobotni nusxalash, boshqa faylni tanlash yoki fayl yuborgan ilovaga qaytish.'**
  String get sharedAdvice;
}

class _StringsDelegate extends LocalizationsDelegate<Strings> {
  const _StringsDelegate();

  @override
  Future<Strings> load(Locale locale) {
    return SynchronousFuture<Strings>(lookupStrings(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_StringsDelegate old) => false;
}

Strings lookupStrings(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'uz':
      return StringsUz();
  }

  throw FlutterError(
    'Strings.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
