import io
import os
import unittest
from unittest.mock import patch
from file_hash import lookup_hash

class HashTests(unittest.TestCase):
    def test_no_consent(self):
        with patch("urllib.request.urlopen") as request:
            self.assertEqual(lookup_hash("a"*64)["status"], "consent_required")
            request.assert_not_called()
    def test_no_credentials(self):
        with patch.dict(os.environ, {}, clear=True):
            self.assertEqual(lookup_hash("a"*64, consent=True)["status"], "unconfigured")
    def test_invalid_hash(self):
        with self.assertRaises(ValueError):
            lookup_hash("../secret", consent=True)
    def test_evidence(self):
        with patch.dict(os.environ, {"VT_LICENSE_APPROVED":"true", "VT_API_KEY":"fixture"}):
            with patch("urllib.request.urlopen", return_value=io.BytesIO(
                b'{"data":{"attributes":{"last_analysis_stats":{"malicious":2}}}}')):
                self.assertEqual(lookup_hash("a"*64, consent=True)["malicious"], 2)
