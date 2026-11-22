import json
import os
import threading
import unittest
import urllib.error
import urllib.request
from http.server import ThreadingHTTPServer
from unittest.mock import patch
import server

class GatewayTests(unittest.TestCase):
    def setUp(self):
        self.token = patch.dict(os.environ, {"SHIELD_GATEWAY_TOKEN": "fixture"})
        self.token.start()
        self.http = ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
        self.thread = threading.Thread(target=self.http.serve_forever, daemon=True)
        self.thread.start()
        server.Handler.next_request = 0

    def tearDown(self):
        self.http.shutdown()
        self.http.server_close()
        self.token.stop()

    def send(self, body, token="fixture", path="/v1/check"):
        request = urllib.request.Request(("http://127.0.0.1:%d" % self.http.server_port) + path,
            data=json.dumps(body).encode(), headers={"Authorization": "Bearer " + token})
        try:
            with urllib.request.urlopen(request, timeout=2) as response:
                return response.status, json.loads(response.read())
        except urllib.error.HTTPError as error:
            code = error.code
            error.close()
            return code, {}

    def test_unauthorized(self):
        with patch("server.lookup") as lookup:
            self.assertEqual(self.send({"url":"https://example.test"}, "wrong")[0], 401)
            lookup.assert_not_called()

    def test_invalid_url(self):
        for url in ("file:///sample", "https://user:password@example.test", 5):
            self.assertEqual(self.send({"url":url})[0], 400)

    def test_match_and_rate_limit(self):
        value = {"provider":"webrisk", "matched":True, "expires":"2099-01-01T00:00:00Z"}
        with patch("server.lookup", return_value=value):
            self.assertEqual(self.send({"url":"https://example.test"})[1], value)
            self.assertEqual(self.send({"url":"https://example.test"})[0], 429)

    def test_unavailable(self):
        with patch("server.lookup", side_effect=OSError()):
            self.assertEqual(self.send({"url":"https://example.test"})[0], 503)

    def test_hash_requires_separate_consent(self):
        with patch("server.lookup_hash") as lookup:
            self.assertEqual(self.send({"sha256":"a"*64}, path="/v1/hash")[0], 403)
            lookup.assert_not_called()

    def test_distinct_users_have_distinct_budgets(self):
        server.Handler.user_requests.clear()
        with patch.dict(os.environ, {"SHIELD_USER_TOKENS": json.dumps({"one":"a"*32, "two":"b"*32})}):
            with patch("server.lookup", return_value={}):
                self.assertEqual(self.send({"url":"https://example.test"}, "a"*32)[0], 200)
                self.assertEqual(self.send({"url":"https://example.test"}, "b"*32)[0], 200)
                self.assertEqual(self.send({"url":"https://example.test"}, "a"*32)[0], 429)

if __name__ == "__main__":
    unittest.main()
