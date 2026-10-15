#!/usr/bin/env python3
"""Pure-stdlib release stage security regressions. Never contacts a publisher."""
import hashlib
import importlib.util
import json
import tempfile
import unittest
import sys
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parent / "publish_xinyanshuo_release.py"
sys.path.insert(0, str(SCRIPT.parent))
spec = importlib.util.spec_from_file_location("site_ota_stager", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

CERT = "353c65d2bdde16509b33c976e9bed615013080b071629cfbf7fdeb43e4217057"
APK_SHA = "3cef8894246ddd4c481c48abfc99a55008f82be17885706f2cbd060b9ed21a7a"


class SiteReleaseRevisionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.checkout = self.root / "site"
        (self.checkout / "android-preview").mkdir(parents=True)
        (self.checkout / "android-preview" / "base-latest.json").write_text(
            json.dumps({"schema": 1, "version_code": 1176, "sha256": APK_SHA,
                        "signature_cert_sha256": CERT}), encoding="utf-8"
        )
        (self.checkout / "android-preview" / "latest.json").write_text(
            json.dumps({"schema": 1, "revision": 167}), encoding="utf-8"
        )
        self.pack = self.root / "canglan-content-rev-177.pck"
        self.pack.write_bytes(b"REAL-DATA-NOT-FAKE-PCK" * 80)
        self.manifest = self.root / "latest.json"
        self.manifest.write_text("{}", encoding="utf-8")
        self.public = self.root / "dummy-public.pem"
        self.public.write_text("never called")
        self.template = self.root / "template"
        self.template.mkdir()
        for filename in ("index.html", "style.css", "site.js", "favicon.svg", ".nojekyll"):
            (self.template / filename).write_text("website fixture")

    def attempt(self, revision, min_code=1102, max_code=2147483000):
        manifest = {"revision": revision, "minimum_android_code": min_code,
                    "maximum_android_code": max_code, "size_bytes": self.pack.stat().st_size,
                    "sha256": hashlib.sha256(self.pack.read_bytes()).hexdigest()}
        with patch.object(module, "verify_signed", return_value=manifest):
            return module.stage_site(self.template, self.checkout, self.pack,
                                     self.manifest, self.public)

    def test_apk176_rejects_pck168_despite_fake_cryptographic_pass(self):
        with self.assertRaisesRegex(ValueError, "ignored by APK"):
            self.attempt(168)

    def test_apk176_allows_revision177_only_when_all_stage_gates_pass(self):
        self.assertEqual(self.attempt(177), 177)
        self.assertTrue((self.checkout / "android-preview" / "canglan-content-rev-177.pck").exists())

    def test_changed_apk_sha_blocks(self):
        p = self.checkout / "android-preview" / "base-latest.json"
        d = json.loads(p.read_text())
        d["sha256"] = "0" * 64
        p.write_text(json.dumps(d))
        with self.assertRaisesRegex(ValueError, "identity changed"):
            self.attempt(177)

    def test_modified_version_code_blocks(self):
        p = self.checkout / "android-preview" / "base-latest.json"
        d = json.loads(p.read_text())
        d["version_code"] = 1177
        p.write_text(json.dumps(d))
        with self.assertRaisesRegex(ValueError, "identity changed"):
            self.attempt(177)

    def test_signed_range_must_contain_apk176(self):
        with self.assertRaisesRegex(ValueError, "does not permit"):
            self.attempt(177, min_code=1177)

    def test_legacy_rollback_blocked(self):
        with self.assertRaisesRegex(ValueError, "ignored by APK"):
            self.attempt(167)


if __name__ == "__main__":
    unittest.main()
