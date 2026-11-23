# Fayl tahlili

## 3.1.1 APK read-budget correction

The old32MiB generic archive check returned ZIP before looking for AndroidManifest.xml. A valid larger APK could miss manifest/signature analysis and receive a misleading extension-mismatch finding. APK recognition now precedes that generic archive budget. APK streams are bounded at256MiB, generic archives remain32MiB;4096 entries,256MiB expanded size, ratio200, DEX/ELF8MiB per entry/16MiB total and cancellation remain enforced. Native-code behavior or incomplete DEX evidence still yields qualified unknown family coverage, with specific Uzbek explanations.

Optional provider metadata-query failures fall back to the granted bounded stream; actual stream permission failures remain denied. Columns are resolved by name. Reports include scanned byte count. A file named APK whose detected format is different is explicitly described as non-APK and is never forwarded to install. Over-limit ZIP contents are not falsely labeled an APK mismatch when the manifest was not inspected.

## PHASE 3A — faylni ochish va ulashish

Foydalanuvchi ShieldGuard’ni tanlaganda ACTION_VIEW (content), ACTION_SEND va ACTION_SEND_MULTIPLE fayllari FileOpenScanHandler orqali mavjud NativeFileInspector/FileAnalyzer’ga beriladi. SEND stream, data yoki ClipData’dan; MULTIPLE bounded stream list/ClipData’dan olinadi. Text-only SEND eski havola/xabar tahliliga boradi. Cold-start configureFlutterEngine va warm onNewIntent bir accept yo‘lini ishlatadi. [Android Intent](https://developer.android.com/reference/android/content/Intent), [URI grant](https://developer.android.com/reference/androidx/core/content/FileProvider).

Fayl turi sender MIME’iga ishonib emas, mavjud magic/ZIP/manifest tahlili bilan aniqlanadi. APK imzosi va available indikatorlar mavjud apksig/DEX/ELF qoidalarida tekshiriladi. Tahlil incomplete bo‘lsa verdict unknown; permission/limit/missing-file xatosi boshqa faylni to‘xtatmaydi.

Share uchun read flag va actual checkUriPermission talab qilinadi; SAF Android bergan read grant bilan ishlaydi. Faqat valid content URI, 4096 belgigacha; userinfo/fragment/unsupported scheme rad etiladi. Global storage ruxsati, hidden filesystem access yoki persistable grant olinmaydi.

64 candidate’gacha ko‘riladi, scheme normalizatsiyasi bilan bir xil URI dedup qilinadi, dastlabki 8 unique fayl tekshiriladi; ortiqchasi incomplete contentLimit sifatida ko‘rsatiladi. Dedup URI bo‘yicha, barcha provider alias’larining bir fayl ekanini kafolatlamaydi. Bir activity’da bitta file batch; band holatda yangi file request busy bilan rad etiladi. Mavjud worker queue chegarasi saqlandi.

Batch 60 soniyalik monotonic cooperative deadline va cancel token ishlatadi. Per-file stream/format stage mavjud 30 soniyalik checkpoint va hajm limitlari bilan qoladi. Provider metadata query yoki bloklangan read chaqiruvini har doim darhol to‘xtatish mumkin emas; hard wall-clock isolation qo‘shilmadi. Cancel/deadline qaytganda natija incomplete; bajarilgan oldingi fayllarning dalillari saqlanadi.

Metadata SIZE 256 MiB’dan katta deb berilsa, fayl stream’i ochilmasdan incomplete tooLarge qaytadi. SIZE noma’lum/yolg‘on kichik bo‘lsa ham real stream 256 MiB limitida to‘xtaydi. Arxivlar uchun mavjud 32 MiB va boshqa limitlar saqlandi. Resource limitning o‘zi malware isboti emas.

Natijalar o‘zbekcha per-file kartalarda chiqadi. Foydalanuvchi hisobotni nusxalashi, boshqa fayl tanlashi yoki asl ilovaga qaytishi mumkin. Fayl avtomatik ochilmaydi, o‘rnatilmaydi, bajarilmaydi va serverga yuborilmaydi. Vaqtinchalik cache nusxasi finally bilan o‘chiriladi; raw URI va fayl nomi history/report export’ga kiritilmaydi. Boshqa ilovalarda ochilgan barcha fayllar universal kuzatilmaydi. Folder monitoring PHASE 3B bu yerga kirmaydi.


| Format | V3 tekshiruvi | Chegara |
| --- | --- | --- |
| APK | PackageManager manifest, paket/versiya/SDK/ruxsatlar/exported komponentlar; apksig imzo yaxlitligi va verifier sertifikat SHA-256 | Imzo ishlab chiquvchiga ishonch kafolati emas; lineage alohida tekshirilmaydi |
| DEX | Magic, 112-byte header, endian, file/string table bounds va API satr indikatorlari | Call graph/dataflow yo‘q; satr mavjudligi API bajarilganini bildirmaydi |
| ELF | Header, class/endian va section bounds | To‘liq per-library hash/metadata hisoboti yo‘q |
| PDF | Raw markerlar va isolated PDFBox obyekt traversal: JS, OpenAction, AA, Launch, embedded, URI | 4 MiB fayl, 20 000 obyekt/navbat, 10 soniya; encrypted/parse xatosi incomplete. Render/bajarish yo‘q. Lenient parse to‘liq format validatsiyasi emas |
| ZIP / Office | Ichki yo‘llar, kengaytmalar, macro/OLE/embedded va traversal belgilar | Nested archive to‘liq ochilmaydi; OOXML to‘liq semantik parser emas |
| APKS/APKM/XAPK | Ichki APK paket va verified signer set solishtirishi | 8 komponent, har biri 8 MiB; to‘liq format semantikasi yo‘q |
| MID | Unknown container | Parser amalga oshirilmagan |
| PNG / JPEG / PE | PNG chunk/CRC, JPEG imzo/yakun, PE strukturasi | JPEG segmentlari va bajarilish xatti-harakati tekshirilmaydi |

Stream 256 MiB, ZIP 32 MiB, 4096 entry, expanded 256 MiB, ratio 200 va 30 soniyalik checkpoint byudjeti mavjud. DEX/ELF kontent entry 8 MiB va jami 16 MiB. Bloklangan content-provider read darhol uzilmasligi mumkin. Bir batch dastlabki 8 fayl bilan cheklangan.

PDF read-only descriptor bilan exported=false isolatedProcess xizmatiga beriladi. PDFBox stream storage uchun 8 MiB main-memory limiti bor; bu butun Android process heap limiti emas. Timeout/cancel xizmatdan uziladi; onUnbind parser processini tugatadi. Fayl bajarilmaydi va tashqariga yuborilmaydi.

Vaqtinchalik fayllar finally orqali o‘chiriladi. Sintetik fixture’lar haqiqiy malware o‘rnini bosmaydi. Permission, marker yoki metadata yakka holda zararli dastur tasdig‘i emas.
