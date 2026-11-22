# Arxitektura

PHASE 2: ShieldGuardApplication → dinamik InstalledAppMonitor/PackageUpdateMonitor → ScanScheduler/JobScheduler → InstalledAppJobService → InstalledAppScanner → lokal report va InstalledAppAlert. Mavjud FileAnalyzer/apksig qayta ishlatiladi; umumiy APK risk qoidalari ApkRiskAnalyzer’da ajratildi. Alohida opt-in/generation cancellation va isolated PDF process guard mavjud. Cheklangan visibility va fon qoidalari INSTALLED_APP_PROTECTION.md da.


V3 qo‘shimchalari ApkContentInspector, SplitApkAnalyzer, NativeFileInspector ichidagi apksig verifikatsiyasi va TrustedDeveloperRegistry. Markaziy ScanResult verdict ko‘rsatadi. PdfInspector/PdfParserService isolated PDFBox, FileHashReputationProvider, per-request consent va /v1/hash ham qo‘shildi. To‘liq yagona ShieldGuardSecurityEngine fasadi hali ajratilmagan.

Mavjud Flutter Material 3, Riverpod, go_router va ARB tuzilmasi saqlandi.

| Qatlam | Vazifa |
| --- | --- |
| ThreatEngine | Lokal sintaksis, domen, xabar konteksti va deterministik ball |
| ThreatIntelligenceEngine | Rozilik, SHA-256 kesh kaliti, request birlashtirish va exponential backoff |
| ReputationProvider | Mustaqil almashtiriladigan remote adapter interfeysi |
| RemoteReputationProvider | HTTPS gateway, 8 soniya timeout, 16 KiB javob va schema tekshiruvi |
| ThreatCache | Interfeys, Android SQLite implementatsiyasi |
| aggregateReputation | Lokal va reputatsiya belgilarini birlashtirish, takroriy finding ID ballini cheklash |
| backend/server.py | Web Risk API kalitini saqlash va fixed Google endpointga so‘rov |
| NativeFileInspector | Android SAF URI va PackageManager APK dekoderi |
| FileAnalyzer, StructuralInspector | JVM’da tekshiriladigan stream va statik struktura tahlili |
| AlertGate | Xom matnni saqlamasdan cooldown va dedup |
| TelegramThreatListener | Android ruxsat, lokal qoidalar va xavf ogohlantirishi |

Tarix bazasi va reputatsiya keshi mustaqil. Kesh ijobiy Web Risk javobi muddati bilan boshqariladi. Salbiy Lookup javobi saqlanmaydi. Online so‘rovlar qo‘lda URL yoki alohida rozilik bilan hash tekshiruvida bajariladi.

Safe Browsing va feed adapterlari implementatsiya qilinmagan. Web Risk tanlovi tijoriy foydalanish imkoniyati va rasmiy Lookup API hujjatlariga asoslangan. Hash-prefix kanonizatsiyasi to‘liq implementatsiyasiz ishlatilmagan.
