# Fayl tahlili

| Format | Ishlaydigan tahlil | Chegara |
| --- | --- | --- |
| APK | ZIP, manifest PackageManager dekoderi, paket, versiya, SDK, ruxsatlar, himoyalanmagan exported komponentlar, sertifikat izlari | Kriptografik imzo yaxlitligi tekshirilmaydi, UI’da ochiq ko‘rsatiladi |
| PDF | Header, EOF, JavaScript, Launch, OpenAction, embedded fayl va URI markerlari | To‘liq xref/obyekt parseri qo‘shilmagan. Siqilgan, escape qilingan obyektlar o‘tib ketishi mumkin |
| PE | MZ/PE, architecture kodi, bo‘limlar jadvali va raw extent chegaralari | Authenticode, import va kod semantikasi tekshirilmaydi |
| ZIP/DOCX/XLSX | Elementlar, e’lon qilingan hajm, nisbat, traversal, nested va makros belgisi | Nested arxiv ochilmaydi. CRC to‘liq tekshirilmaydi |
| JPEG | Imzo, yakun belgisi | To‘liq segment parseri yo‘q |
| PNG | IHDR, chunk chegaralari, CRC, IEND va ortiqcha yakun baytlari | Dekodlash, tasvir mazmuni tekshirilmaydi |

Standart limitlar 128 MiB fayl, 32 MiB arxiv, 4096 element, 256 MiB ochilgan hajm, 200 siqish nisbati, 30 soniya vaqt va 10000 PNG chunk. Ichki arxiv darajasi 0, ularning mazmuni ochilmaydi. ScanLimits Kotlin orqali konfiguratsiya qilinadi. Bekor qilish va vaqt tekshiruvi o‘qishlar oralig‘ida bajariladi. Bloklangan content provider o‘qishini ushbu mexanizm darhol uzolmaydi.

Vaqtinchalik fayl finally orqali o‘chiriladi. Sintetik fixture’lar real zararli dastur ishlatmasdan format, hash va xato yo‘llarini tekshiradi. Hech bir permission, skript yoki metadata yakka holda zararli dastur tasdig‘i emas.
