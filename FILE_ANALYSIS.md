# Fayl tahlili

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

Stream 128 MiB, ZIP 32 MiB, 4096 entry, expanded 256 MiB, ratio 200 va 15 soniyalik checkpoint byudjeti mavjud. DEX/ELF kontent entry 8 MiB va jami 16 MiB. Bloklangan content-provider read darhol uzilmasligi mumkin. Bir batch dastlabki 8 fayl bilan cheklangan.

PDF read-only descriptor bilan exported=false isolatedProcess xizmatiga beriladi. PDFBox stream storage uchun 8 MiB main-memory limiti bor; bu butun Android process heap limiti emas. Timeout/cancel xizmatdan uziladi; onUnbind parser processini tugatadi. Fayl bajarilmaydi va tashqariga yuborilmaydi.

Vaqtinchalik fayllar finally orqali o‘chiriladi. Sintetik fixture’lar haqiqiy malware o‘rnini bosmaydi. Permission, marker yoki metadata yakka holda zararli dastur tasdig‘i emas.
