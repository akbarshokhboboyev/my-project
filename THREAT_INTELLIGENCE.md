# Tahdid manbalari

2026-11-22 sanasida rasmiy hujjatlar tekshirildi. Web Risk Lookup adapteri va Python serveri implementatsiya qilindi. Haqiqiy so‘rov uchun WEBRISK_API_KEY, HTTPS gateway va unga kirish tokeni kerak. Pullik xizmat faollashtirilmagan.

| Manba | Litsenziya va narx | Kalit, limit, yangilanish | Maxfiylik va kesh |
| --- | --- | --- | --- |
| Google Safe Browsing v5 | Notijorat foydalanish bepul | API kaliti, loyiha kvotasi. Jonli xesh qidiruvi va lokal ro‘yxatlar | 4 bayt xesh prefiksi, OHTTP imkoniyati. Maxsus kanonizatsiya talab qiladi. Ushbu versiyada adapter yo‘q |
| Google Web Risk | Tijoriy foydalanish uchun tanlangan. Lookup oyiga 100 000 chaqiruvgacha bepul, keyingi 10 milliongacha 1000 so‘rov uchun $0.50 | Server API kaliti, Cloud kvotalari. Google yangilaydigan baza | To‘liq URL server va Google’ga uzatiladi. Ijobiy moslik expireTime tugaguncha SQLite’da URL xeshi bilan saqlanadi. Salbiy natija keshlanmaydi |
| URLhaus | Community fair use bepul. Tijoriy foydalanish obuna talab qilishi mumkin | Auth-Key kerak. Eksport har 5 daqiqada, bundan tez olish mumkin emas | Zararli dastur URL bazasi, universal phishing bazasi emas. Litsenziyali eksport lokal ishlashi mumkin. Adapter yo‘q |
| OpenPhish | Community shaxsiy tadqiqot uchun. Tijoriy mahsulotga yozma rozilik kerak. Premium narxi so‘rov asosida | Community 12 soat, Premium 5 daqiqa | Phishing feed. Foydalanuvchi URL’sini uzatmay lokal solishtirish mumkin. Tarqatish huquqi alohida. Adapter yo‘q |
| PhishTank | API sahifasida qat’iy tijoriy litsenziya va narx kafolati ko‘rsatilmagan | App key ixtiyoriy, kalitsiz limit pastroq. Limit javob headerlarida, oshsa HTTP 509 | Lookup to‘liq URL yuboradi. Lokal baza eksporti mumkin. Adapter yo‘q |

Aniq loyiha kvotasi boshqaruv konsolida tekshiriladi. Manbalar bir xil to‘liqlik va aniqlikka ega emas. Hozir bitta remote provider bor. Qarama-qarshi natija holatida ijobiy reputatsiya belgisi lokal dalilga qo‘shiladi va takroriy finding ID bir marta hisoblanadi.

Dart adapteri 8 soniya timeout, 16 KiB javob limiti, redirect rad etish, takroriy bir vaqtdagi so‘rovlarni birlashtirish va 2–256 soniya exponential backoff ishlatadi. Kesh muddati tugasa online so‘rov bajariladi. Aloqa bo‘lmasa mahalliy natija va alohida online xatosi ko‘rsatiladi. Xabarlar va bildirishnomalar online yuborilmaydi.

## Serverni sozlash

Python 3.11+ kerak. API kalitini faqat server secret manager yoki jarayon muhitiga kiriting. Ilovaning Sozlamalar bo‘limida HTTPS gateway va gateway tokenini kiriting, so‘ng URL uzatilishiga rozilikni yoqing. Gateway tokeni ilova seansida xotirada qoladi.

```powershell
$env:WEBRISK_API_KEY = '<server secret manager orqali>'
$env:SHIELD_GATEWAY_TOKEN = '<server secret manager orqali>'
python backend/server.py
python -m unittest discover -s backend
```

Jarayon faqat 127.0.0.1:8080 ga ulanadi. Ishlab chiqarishda TLS reverse proxy orqali /v1/check ni uzating, request body, Authorization va upstream URL query logging’ini o‘chiring, 8 KiB body limiti va ulanishlar limitini qo‘ying. Gateway 1 soniyada bitta upstream so‘rovga ruxsat beradi. Bu minimal nazoratli o‘rnatish serveri. Ommaviy xizmat uchun foydalanuvchi identifikatsiyasi, alohida kvota va kalit aylantirish talab qilinadi. URL sahifasi hech qachon yuklanmaydi.

Manbalar [Safe Browsing](https://developers.google.com/safe-browsing/reference), [Web Risk Lookup](https://docs.cloud.google.com/web-risk/docs/lookup-api), [narx](https://cloud.google.com/security/products/web-risk), [kesh](https://docs.cloud.google.com/web-risk/docs/caching), [URLhaus](https://urlhaus.abuse.ch/api), [OpenPhish feed](https://openphish.com/phishing_feeds.html), [OpenPhish shartlari](https://openphish.com/terms.html), [PhishTank](https://phishtank.org/api_info.php).
