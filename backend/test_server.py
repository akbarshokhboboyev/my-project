import unittest
from datetime import datetime, timedelta, timezone
from server import parse_google

class ResponseTests(unittest.TestCase):
    def test_match(self):
        value = parse_google({"threat": {"threatTypes": ["MALWARE"],
            "expireTime": (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()}})
        self.assertTrue(value["matched"])
    def test_no_match(self):
        self.assertFalse(parse_google({})["matched"])
    def test_invalid(self):
        for value in ([], None, {"threat": {}}, {"threat": {"threatTypes": ["OTHER"]}}):
            with self.subTest(value=value), self.assertRaises(ValueError):
                parse_google(value)

if __name__ == "__main__":
    unittest.main()
