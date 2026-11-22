# Arxitektura

- Flutter ilovasi Material 3, Riverpod, go_router va o‘zbekcha ARB katalogidan foydalanadi. `ShieldPlatform` Android ko‘prigini, `ThreatEngine` esa qo‘lda kiritilgan havola va matn qoidalarini boshqaradi.
- `NativeFileInspector` Android URI va APK to‘plami ma’lumotlarini o‘qiydi. Android’ga bog‘liq bo‘lmagan `FileAnalyzer` oqim orqali SHA-256 izini hisoblaydi va cheklangan statik tahlil bajaradi. Og‘ir fayl va SQLite operatsiyalari alohida ish oqimida ishlaydi.
- Android xizmati faqat ruxsat berilgan Telegram bildirishnomalarining ko‘rsatilgan matnini tahlil qiladi. U Flutter ishga tushmaganida ham Kotlin qoidalarini bajara oladi. Kotlin va Dart’da moslashtirilgan alohida qoidalar bor va natijalar bir xil ball chegaralarini ishlatadi.
- SQLite tarixida faqat o‘lchangan xavf balli, vaqt, tur, belgilar soni va tekshiruv holati saqlanadi. Oxirgi 1000 yozuv saqlanadi.
- Kotlin ko‘prigi fayl va ogohlantirishlardan faqat tuzilgan natijani qaytaradi. Ulangan xabar esa bir martalik tahlil uchun xotirada uzatiladi.
