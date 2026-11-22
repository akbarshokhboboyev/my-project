# ShieldGuard PHASE 4 — APK qo‘riqchi

2026-11-22, `feature/shieldguard-v3-1`, boshlang‘ich commit `1641653`.

## 4A — discovery va risk policy

`ApkDiscoveryCoordinator` va `ApkRiskPolicy` mavjud `NativeFileInspector` natijasini boyitadi. PHASE 3A ACTION_SEND/VIEW/SEND_MULTIPLE va PHASE 3B authorized folder scanner avtomatik shu yo‘ldan o‘tadi; mavjud parserlar, limitlar va ruxsat tekshiruvlari saqlanadi. Haqiqiy APK formati va faqat `.apk` deb nomlangan boshqa format ajratiladi. Double extension mavjud FileAnalyzer qoidasi bilan tekshiriladi.

Risk balli, confidence, completeness va evidence alohida. Signature failure — kuchli integrity shubhasi, malware tasdig‘i emas. Bitta permission yoki exported launcher heuristic xolos. `confirmedHighConfidenceThreat` faqat ishonchli adapter orqali alohida berilgan known-malicious reputation dalili uchun; jonli provider avtomatik ulanmagan. Online hash tekshiruvi avvalgi alohida consent yo‘lida qoladi. Imzo muvaffaqiyati zararsizlik kafolati emas. Trusted Developer Registry mavjud cheklovlari saqlanadi; yangi production trust root yoki malware corpus yo‘q.

Telegram manbasi Intent nomidan ishonchli tasdiqlanmaydi. Boshqa ilovaning private storage’i yoki unga tegishli Downloads’dagi non-media APK uchun universal MediaStore kirishi yo‘q: foydalanuvchi authorized SAF tree yoki share/open orqali ruxsat beradi. Papka tekshiruvi periodic, real-time emas. Fayl o‘qilmasa natija unknown/incomplete. Hech qanday avtomatik upload/execute/install yo‘q.

4A dalil: 17 yangi pure Kotlin risk/discovery assertion, jami 220 + 387 malformed input o‘tdi. Android adapter kompilyatsiyasi va device tekshiruvlari keyingi bosqichda alohida qayd etiladi. 4B gate va 4C modal hali bu commitda qo‘shilmadi.

Android manbalari: [shared storage](https://developer.android.com/training/data-storage/shared/media), [SAF](https://developer.android.com/training/data-storage/shared/documents-files). Global install veto yoki Android Device Owner provisioning yo‘q.
