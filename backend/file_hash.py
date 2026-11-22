"""Hash-only lookup. Requires separately licensed VirusTotal access and explicit consent."""
import json
import os
import re
import urllib.request
import urllib.error

def lookup_hash(sha256, *, consent=False):
    if not consent:
        return {"status": "consent_required"}
    if not isinstance(sha256, str) or not re.fullmatch("[0-9a-fA-F]{64}", sha256):
        raise ValueError("invalid SHA-256")
    if os.environ.get("VT_LICENSE_APPROVED") != "true" or not os.environ.get("VT_API_KEY"):
        return {"status": "unconfigured"}
    request = urllib.request.Request("https://www.virustotal.com/api/v3/files/" + sha256.lower(),
        headers={"x-apikey": os.environ["VT_API_KEY"]})
    try:
        with urllib.request.urlopen(request, timeout=6) as response:
            raw = response.read(65537)
        if len(raw) > 65536:
            return {"status": "invalid_response"}
        stats = json.loads(raw)["data"]["attributes"]["last_analysis_stats"]
        if not isinstance(stats, dict) or any(not isinstance(v, int) or isinstance(v, bool) or v < 0 for v in stats.values()):
            return {"status": "invalid_response"}
        # Counts are reported as evidence. No claim of confirmed malware from one engine.
        return {"status": "reported", "malicious": stats.get("malicious", 0),
                "suspicious": stats.get("suspicious", 0)}
    except urllib.error.HTTPError as error:
        code = error.code
        error.close()
        return {"status": "not_found" if code == 404 else "rate_limited" if code == 429 else "unavailable"}
    except Exception:
        return {"status": "unavailable"}
