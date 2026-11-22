# ShieldGuard V3 store materiallari

- feature_graphic_v3.png: 1024×500 RGB, generate_assets.ps1 orqali mavjud navy/mint shield dizayniga mos yaratilgan.
- store_icon_v3.png: 512×512 RGB.
- screenshots/01-home.png: 1080×2400, haqiqiy V3 debug UI, toza Android17 API37 emulyator.
- screenshots/02-synthetic-apk-result.png: 1080×2400, o‘z debug APK kontentidan tayyorlangan, imzosi ataylab buzilgan benign fixture natijasi. Bu haqiqiy malware aniqlangani yoki production xizmat sinovi degani emas. Fixture o‘rnatilmagan/bajarilmagan.

Skrinshotlar ADB screencap bilan olingan va tahrirlanmagan. Maxfiy foydalanuvchi ma’lumoti yoki real malware namunasi yo‘q. Grafikalar repository ichida qayta yaratiladi:

~~~powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File store/generate_assets.ps1
~~~

Play Console nashri, signed AAB, privacy URL, xizmat egasi/aloqa, Data Safety, access disclosure videosi va internal testing hali talab qilinadi. Yakuniy store metadata va tasvirlar xizmat egasi tomonidan Play Console’da tekshirilishi kerak.
