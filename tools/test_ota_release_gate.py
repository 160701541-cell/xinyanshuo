#!/usr/bin/env python3
"""Regression: real APK-pinned RSA signer, tamper rejection, and revision gate."""
import json
from pathlib import Path
import tempfile
import unittest

from tools import ota_release_gate as gate


class ProductionOTALockdownTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base = json.loads(gate.BASE.read_text(encoding="utf-8"))
        cls.live = json.loads(gate.LIVE.read_text(encoding="utf-8"))
        cls.key = gate.pubkey()

    def test_current_feed_is_authenticated_by_actual_client_key(self):
        self.assertTrue(gate.verify_signature(self.live, self.key))

    def test_modifying_authenticated_revision_is_rejected(self):
        modified = dict(self.live)
        modified["revision"] = 177
        self.assertFalse(gate.verify_signature(modified, self.key))

    def test_replacing_url_or_digest_is_rejected(self):
        for key, value in (("pack_url", "https://example.org/fake.pck"),
                           ("sha256", "0"*64),
                           ("notes", "fake patch")):
            with self.subTest(field=key):
                modified = dict(self.live, **{key: value})
                self.assertFalse(gate.verify_signature(modified, self.key))

    def test_apk176_requires_minimum_revision_177(self):
        self.assertEqual(self.base["version_code"], 1176)
        required = max(self.live["revision"], self.base["version_code"]-1000)+1
        self.assertEqual(required, 177)

    def test_unsigned_dummy_pack_cannot_be_published(self):
        with tempfile.TemporaryDirectory() as tmp:
            pack = Path(tmp) / "candidate.pck"
            pack.write_bytes(b"GDPC" + b"0"*1024)
            candidate = dict(self.live)
            candidate["revision"] = 177
            candidate["minimum_android_code"] = 1176
            candidate["pack_url"] = gate.HOST+"canglan-content-rev-177.pck"
            candidate["size_bytes"] = pack.stat().st_size
            import hashlib
            candidate["sha256"] = hashlib.sha256(pack.read_bytes()).hexdigest()
            result = gate.check_candidate(candidate, pack, self.base, self.live)
            self.assertFalse(result["passed"])
            self.assertIn("RSA signature DOES NOT match immutable public key in installed APK", result["errors"])

    def test_repackaging_old_revision_fails_even_if_bytes_match(self):
        with tempfile.TemporaryDirectory() as tmp:
            pack = Path(tmp) / "candidate.pck"
            pack.write_bytes(b"GDPC" + b"0"*1024)
            candidate = dict(self.live)
            candidate["pack_url"] = gate.HOST+"canglan-content-rev-167.pck"
            candidate["size_bytes"] = pack.stat().st_size
            import hashlib
            candidate["sha256"] = hashlib.sha256(pack.read_bytes()).hexdigest()
            result = gate.check_candidate(candidate, pack, self.base, self.live)
            self.assertIn("OTA revision must exceed current feed AND APK176 revision floor", result["errors"])


if __name__ == "__main__":
    unittest.main()
