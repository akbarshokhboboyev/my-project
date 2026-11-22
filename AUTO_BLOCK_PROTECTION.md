# ShieldGuard PHASE 4 — APK qo‘riqchi

2026-11-22, `feature/shieldguard-v3-1`, boshlang‘ich commit `1641653`.

## 4A — discovery va risk policy

`ApkDiscoveryCoordinator` va `ApkRiskPolicy` mavjud `NativeFileInspector` natijasini boyitadi. PHASE 3A ACTION_SEND/VIEW/SEND_MULTIPLE va PHASE 3B authorized folder scanner avtomatik shu yo‘ldan o‘tadi; mavjud parserlar, limitlar va ruxsat tekshiruvlari saqlanadi. Haqiqiy APK formati va faqat `.apk` deb nomlangan boshqa format ajratiladi. Double extension mavjud FileAnalyzer qoidasi bilan tekshiriladi.

Risk balli, confidence, completeness va evidence alohida. Signature failure — kuchli integrity shubhasi, malware tasdig‘i emas. Bitta permission yoki exported launcher heuristic xolos. `confirmedHighConfidenceThreat` faqat ishonchli adapter orqali alohida berilgan known-malicious reputation dalili uchun; jonli provider avtomatik ulanmagan. Online hash tekshiruvi avvalgi alohida consent yo‘lida qoladi. Imzo muvaffaqiyati zararsizlik kafolati emas. Trusted Developer Registry mavjud cheklovlari saqlanadi; yangi production trust root yoki malware corpus yo‘q.

Telegram manbasi Intent nomidan ishonchli tasdiqlanmaydi. Boshqa ilovaning private storage’i yoki unga tegishli Downloads’dagi non-media APK uchun universal MediaStore kirishi yo‘q: foydalanuvchi authorized SAF tree yoki share/open orqali ruxsat beradi. Papka tekshiruvi periodic, real-time emas. Fayl o‘qilmasa natija unknown/incomplete. Hech qanday avtomatik upload/execute/install yo‘q.

4A dalil: 17 yangi pure Kotlin risk/discovery assertion, jami 220 + 387 malformed input o‘tdi.

## 4B — real forwarding boundary

`AutomaticBlockEngine` strong/confirmed dalilda auto-block yoqilgan bo‘lsa `blockedByShieldGuard`, strict incomplete holatda `scanIncomplete` beradi. So‘nggi holat malware tasdig‘i emas. Auto-block o‘chiq bo‘lsa ogohlantirish saqlanadi. Gate explicit tasdiqsiz hech qanday launch callback chaqirmaydi.

`InstallProtectionCoordinator` faqat foreground file-open/share yo‘lida skanerlangan byte’lardan private snapshot oladi; original URI qayta ochilib boshqa byte’lar forward qilinmaydi. Random token, ko‘pi bilan 8 × 32 MiB snapshot, 10 daqiqa expiry; sender nomi yoki URI saqlanmaydi. Forward oldidan SHA-256 qayta tekshiriladi, expiry/generation/current settings yana tekshiriladi. Cancel snapshotlarni bekor qiladi. Faqat o‘z cache nusxalari o‘chiriladi. Process o‘lsa tokenlar amal qilmaydi; orphan cache keyingi cleanup’da tozalanadi, bu diskdagi qoldiqni aniq vaqtda o‘chirish kafolati emas.

4B dalil: 28 discovery/risk/gate assertion, jami 231 + 387 malformed o‘tdi. Blocked callback count=0, user approval bo‘lmasa count=0, benign explicit approval’da count=1. Bu mock callback launch dalili, haqiqiy Android installer E2E emas. Native Android kod debug build’da kompilyatsiya qilindi. Native gate’ni explicit Flutter tugmasi bilan ochish, dialog va notification 4C’da qo‘shiladi.

Android manbalari: [shared storage](https://developer.android.com/training/data-storage/shared/media), [SAF](https://developer.android.com/training/data-storage/shared/documents-files). Global install veto yoki Android Device Owner provisioning yo‘q.
