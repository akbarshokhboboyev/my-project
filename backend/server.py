"""Web Risk gateway. Run behind a TLS reverse proxy with request logging disabled."""
import hmac
import json
import os
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

THREATS = {"MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE"}

def parse_google(value):
    if not isinstance(value, dict):
        raise ValueError()
    if value == {}:
        return {"provider": "webrisk", "matched": False, "expires": datetime.now(timezone.utc).isoformat()}
    threat = value.get("threat")
    if not isinstance(threat, dict):
        raise ValueError()
    kinds, expires = threat.get("threatTypes"), threat.get("expireTime")
    if not isinstance(kinds, list) or not kinds or not set(kinds) <= THREATS:
        raise ValueError()
    if not isinstance(expires, str) or datetime.fromisoformat(expires.replace("Z", "+00:00")) <= datetime.now(timezone.utc):
        raise ValueError()
    return {"provider": "webrisk", "matched": True, "expires": expires}

def lookup(url):
    key = os.environ.get("WEBRISK_API_KEY")
    if not key:
        raise RuntimeError()
    params = urllib.parse.urlencode([("uri", url), ("key", key)] +
                                   [("threatTypes", item) for item in sorted(THREATS)])
    # The supplied URL is data. Only Google's fixed API endpoint is contacted.
    with urllib.request.urlopen("https://webrisk.googleapis.com/v1/uris:search?" + params, timeout=6) as response:
        data = response.read(16385)
    if len(data) > 16384:
        raise ValueError()
    return parse_google(json.loads(data))

class Handler(BaseHTTPRequestHandler):
    lock = threading.Lock()
    next_request = 0.0
    def log_message(self, *_):
        pass
    def do_POST(self):
        token = os.environ.get("SHIELD_GATEWAY_TOKEN", "")
        if not token or not hmac.compare_digest(self.headers.get("Authorization", ""), "Bearer " + token):
            return self.send_json(401, {})
        if self.path != "/v1/check":
            return self.send_json(404, {})
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 1 <= length <= 8192:
                return self.send_json(413, {})
            self.connection.settimeout(8)
            url = json.loads(self.rfile.read(length))["url"]
            if not isinstance(url, str) or len(url) > 4096:
                raise ValueError()
            parsed = urllib.parse.urlsplit(url)
            if parsed.scheme not in ("http", "https") or not parsed.hostname or parsed.username or parsed.password:
                raise ValueError()
            with Handler.lock:
                if time.monotonic() < Handler.next_request:
                    return self.send_json(429, {})
                Handler.next_request = time.monotonic() + 1
            return self.send_json(200, lookup(url))
        except urllib.error.HTTPError as error:
            return self.send_json(429 if error.code == 429 else 502, {})
        except (ValueError, KeyError, TypeError):
            return self.send_json(400, {})
        except Exception:
            return self.send_json(503, {})
    def send_json(self, code, value):
        data = json.dumps(value).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

if __name__ == "__main__":
    if not os.environ.get("SHIELD_GATEWAY_TOKEN"):
        raise SystemExit("SHIELD_GATEWAY_TOKEN is required")
    ThreadingHTTPServer(("127.0.0.1", int(os.environ.get("PORT", "8080"))), Handler).serve_forever()
