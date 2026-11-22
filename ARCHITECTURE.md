# Arxitektura

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

Tarix bazasi va reputatsiya keshi mustaqil. Kesh ijobiy Web Risk javobi muddati bilan boshqariladi. Salbiy Lookup javobi saqlanmaydi. Online so‘rovlar faqat qo‘lda havola tekshiruvida bajariladi.

Safe Browsing va feed adapterlari implementatsiya qilinmagan. Web Risk tanlovi tijoriy foydalanish imkoniyati va rasmiy Lookup API hujjatlariga asoslangan. Hash-prefix kanonizatsiyasi to‘liq implementatsiyasiz ishlatilmagan.
