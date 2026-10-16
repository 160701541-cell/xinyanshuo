#!/usr/bin/env python3
"""Publish EXACT tested APK176 content into original phone's RSA-signed OTA.

Never signs with a new identity, never stores/logs the original private key,
and never edits the site's public feed without validated Godot+crypto gates.
Designed for a trusted GitHub Actions main-branch runner only.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "logic-qa" / "release-gate"))
from check_original_ota_secret import ENV_CANDIDATES, pub_der
from ota_release_gate import pubkey, pubkey as actual_apk_public_key
from ota_release_gate import check_candidate, verify_signature
from sign_pck_release import build_manifest, sign_manifest
from publish_xinyanshuo_release import stage_site, verify_signed

BASE_SHA256 = "3cef8894246ddd4c481c48abfc99a55008f82be17885706f2cbd060b9ed21a7a"
PACK_URL = ("https://160701541-cell.github.io/xinyanshuo/android-preview/"
            "canglan-content-rev-177.pck")
REQUIRED_QA_MARKER = (
    "OBSERVED_APK176_MAIN_INSTANCE_WITH_PORTAL_AND_IMAGES_PENDING_ENGINE_ERROR_AUDIT"
)


def matching_original_private() -> bytes | None:
    """Return PEM bytes ONLY within the current process, never print them."""
    pinned = pub_der(actual_apk_public_key().encode("utf-8"), False)
    for name in ENV_CANDIDATES:
        value = os.environ.get(name, "").strip()
        if not value:
            continue
        if value.startswith("-----BEGIN "):
            key_bytes = (value + ("\n" if not value.endswith("\n") else "")).encode()
        else:
            try:
                key_bytes = base64.b64decode(value, validate=True)
            except ValueError:
                continue
        try:
            if pub_der(key_bytes, True) == pinned:
                return key_bytes
        except (ValueError, OSError):
            pass
    return None


def source_qa_valid(root: Path, pack: Path, unsigned: Path, log: Path) -> dict:
    base = json.loads((root / "android-preview/base-latest.json").read_text())
    live = json.loads((root / "android-preview/latest.json").read_text())
    if (base.get("version_code") != 1176 or
            base.get("package_name") != "org.canglan.ancient25d.preview" or
            base.get("sha256") != BASE_SHA256):
        raise RuntimeError("BLOCKED: source APK176 has changed; re-audit required")
    if live.get("revision") != 167 or not verify_signature(live, pubkey()):
        raise RuntimeError("BLOCKED: current signed public feed is not pinned rev167")
    report = json.loads(unsigned.read_text(encoding="utf-8"))
    if (report.get("_not_a_release") != "UNSIGNED_DEVELOPER_TEMPLATE_DO_NOT_HOST"
            or report.get("signature") != ""
            or report.get("revision") != 177
            or report.get("minimum_android_code") != 1176
            or report.get("maximum_android_code") != 1176
            or report.get("pack_url") != PACK_URL):
        raise RuntimeError("BLOCKED: no properly bounded, unsigned QA template")
    if not pack.is_file() or not 512 < pack.stat().st_size < 95 * 1024 * 1024:
        raise RuntimeError("BLOCKED: PCK missing or too large for Pages")
    if pack.read_bytes()[:4] != b"GDPC":
        raise RuntimeError("BLOCKED: not an actual Godot PCK")
    if (report["size_bytes"] != pack.stat().st_size or
            report["sha256"] != hashlib.sha256(pack.read_bytes()).hexdigest()):
        raise RuntimeError("BLOCKED: accepted QA manifest and PCK do not match")
    log_text = log.read_text(encoding="utf-8")
    if REQUIRED_QA_MARKER not in log_text or any(
        bad in log_text for bad in
        ("SCRIPT ERROR:", "Parse Error:", "ERROR:", "FAIL_APK176_ACTUAL_MAIN_RUNTIME")
    ):
        raise RuntimeError("BLOCKED: real original APK Godot live gameplay QA failed")
    print("PASS_PINNED_REAL_APK176_QA_RASTER_PCK_AND_EXISTING_SIGNED_FEED",
          report["sha256"], report["size_bytes"])
    return report


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preflight", action="store_true")
    parser.add_argument("--qa-pack", type=Path)
    parser.add_argument("--qa-manifest", type=Path)
    parser.add_argument("--qa-runtime-log", type=Path)
    parser.add_argument("--staging", type=Path, default=ROOT)
    args = parser.parse_args()
    private = matching_original_private()
    if private is None:
        print("BLOCKED_ORIGINAL_RSA_PRIVATE_KEY_NOT_CONFIGURED_OR_NOT_MATCHED")
        print("APK176_CANNOT_ACCEPT_A_NEW_RSA_KEY_DO_NOT_PUBLISH_OR_REPLACE_APP")
        raise SystemExit(2)
    print("PASS_ORIGINAL_APK176_RSA_PRIVATE_KEY_MATCHES_IMMUTABLE_CLIENT_KEY")
    if args.preflight:
        return
    if not all((args.qa_pack, args.qa_manifest, args.qa_runtime_log)):
        parser.error("All 3 real QA artifact paths are required")
    root = args.staging.resolve()
    passed = source_qa_valid(root, args.qa_pack, args.qa_manifest, args.qa_runtime_log)
    with tempfile.TemporaryDirectory(prefix="canglan-original-rsa-") as t:
        work = Path(t)
        priv_path = work / "private.pem"
        priv_path.write_bytes(private)
        priv_path.chmod(0o600)
        public_path = work / "original-apk176-public.pem"
        public_path.write_text(pubkey(), encoding="utf-8")
        sitepack = work / "canglan-content-rev-177.pck"
        shutil.copyfile(args.qa_pack, sitepack)
        manifest = build_manifest(
            pack=sitepack, revision=177, minimum_code=1176,
            maximum_code=1176, url=PACK_URL,
            notes="苍岚：原版HD2D WorldX场景、可进入正房与室内候选测试",
        )
        signed = sign_manifest(manifest, priv_path, public_path)
        if not verify_signature(signed, pubkey()):
            raise RuntimeError("Signed candidate FAILED original client verification")
        checker = check_candidate(
            signed, sitepack,
            json.loads((root / "android-preview/base-latest.json").read_text()),
            json.loads((root / "android-preview/latest.json").read_text()),
        )
        if not checker["passed"]:
            raise RuntimeError("BLOCKED by release gate: " + repr(checker["errors"]))
        signed_path = work / "latest.json"
        signed_path.write_text(json.dumps(signed, indent=2, ensure_ascii=False)+"\n",
                               encoding="utf-8")
        verify_signed(sitepack, signed_path, public_path)
        stage_site(
            template=root, checkout=root,
            pack=sitepack, manifest_file=signed_path,
            public_key=public_path,
        )
        assert (root / "android-preview" / sitepack.name).is_file()
        assert verify_signature(
            json.loads((root / "android-preview/latest.json").read_text()), pubkey()
        )
        release_report = {
            "status": "STAGED_VALID_SIGNED_OTA_NOT_YET_DEPLOYED",
            "apk_version_code": 1176, "revision": 177,
            "pack_sha256": passed["sha256"],
            "pack_size_bytes": passed["size_bytes"],
            "original_client_signature_verified": True,
            "source": "real-main-Godot-PCK-QA",
            "pack_url": PACK_URL,
        }
        dest = root / "qa-results/real-rev177-signed-release-report.json"
        dest.parent.mkdir(exist_ok=True, parents=True)
        dest.write_text(json.dumps(release_report, indent=2, ensure_ascii=False)+"\n")
        print("PASS_CANG LAN_REV177_SAME_ORIGINAL_APK_RSA_SIGNED_RELEASE_STAGED".replace(" ", ""),
              passed["sha256"], "revision=177")


if __name__ == "__main__":
    main()
