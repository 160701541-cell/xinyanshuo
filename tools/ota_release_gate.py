#!/usr/bin/env python3
"""Real original-APK OTA release guard. Never signs with a temporary key.
Check a *candidate* PCK + signed manifest against the APK's pinned public key.
This tool does not substitute for actual scene gameplay or phone acceptance.
"""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CHANNEL_SOURCE = ROOT / "logic-qa/scripts/update_channel.gd"
BASE = ROOT / "android-preview/base-latest.json"
LIVE = ROOT / "android-preview/latest.json"
MAX_PACK = 536870912
HOST = "https://160701541-cell.github.io/xinyanshuo/android-preview/"
EXPECTED_APP_ID = "org.canglan.ancient25d.preview"

def pubkey() -> str:
    source = CHANNEL_SOURCE.read_text(encoding="utf-8")
    match = re.search(r"-----BEGIN PUBLIC KEY-----[\s\S]*?-----END PUBLIC KEY-----", source)
    if not match:
        raise ValueError("APK public signing key missing")
    return match.group(0) + "\n"

def signed_bytes(manifest: dict) -> bytes:
    keys = ("schema", "channel", "revision", "minimum_android_code",
            "maximum_android_code", "sha256", "size_bytes", "pack_url", "notes")
    if any(key not in manifest for key in keys):
        raise ValueError("missing signed manifest fields")
    return ("canglan-pck-v1\n" + "".join(str(manifest[k]) + "\n" for k in keys)).encode("utf-8")

def verify_signature(manifest: dict, key: str) -> bool:
    try:
        raw_sig = base64.b64decode(manifest["signature"], validate=True)
        with tempfile.TemporaryDirectory() as work:
            d = Path(work)
            (d / "key.pem").write_text(key, encoding="utf-8")
            (d / "sig.bin").write_bytes(raw_sig)
            result = subprocess.run(
                ["openssl", "dgst", "-sha256", "-verify", str(d / "key.pem"),
                 "-signature", str(d / "sig.bin")],
                input=signed_bytes(manifest), capture_output=True,
                timeout=10, check=False)
            return result.returncode == 0
    except (ValueError, KeyError, subprocess.SubprocessError):
        return False

def check_candidate(candidate: dict, pck: Path, base: dict, current: dict) -> dict:
    errors = []
    def fail(reason): errors.append(reason)
    if base.get("package_name") != EXPECTED_APP_ID:
        fail("Android package identity changed")
    if not re.fullmatch(r"[0-9a-f]{64}", str(base.get("signature_cert_sha256", ""))):
        fail("base APK signing certificate identity missing")
    if base.get("version_code", 0) < 1176:
        fail("unsupported base APK")
    if candidate.get("schema") != 1 or candidate.get("channel") != "android-preview":
        fail("invalid signed update channel")
    if candidate.get("revision", 0) <= max(current.get("revision", 0), base.get("version_code", 0) - 1000):
        fail("OTA revision must exceed current feed AND APK176 revision floor")
    if int(candidate.get("minimum_android_code", 0)) > base["version_code"]:
        fail("candidate excludes APK176")
    if int(candidate.get("maximum_android_code", 0)) < base["version_code"]:
        fail("candidate maximum version excludes APK176")
    if candidate.get("pack_url", "") != HOST + "canglan-content-rev-" + str(candidate.get("revision")) + ".pck":
        fail("candidate pack_url not pinned to official public feed")
    if not pck.is_file() or not 512 <= pck.stat().st_size <= MAX_PACK:
        fail("candidate PCK missing or out of bounds")
    else:
        payload = pck.read_bytes()
        if payload[:4] != b"GDPC":
            fail("not a Godot PCK")
        if candidate.get("size_bytes") != len(payload):
            fail("PCK size mismatch")
        if candidate.get("sha256") != hashlib.sha256(payload).hexdigest():
            fail("PCK SHA256 mismatch")
    if not verify_signature(candidate, pubkey()):
        fail("RSA signature DOES NOT match immutable public key in installed APK")
    return {"passed": not errors, "errors": errors,
            "candidate_revision": candidate.get("revision"),
            "base_android_code": base.get("version_code"),
            "current_public_revision": current.get("revision"),
            "signer_matches_base": "RSA signature DOES NOT match immutable public key in installed APK" not in errors}

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--candidate", type=Path)
    ap.add_argument("--pck", type=Path)
    ap.add_argument("--report", type=Path)
    args = ap.parse_args()
    base = json.loads(BASE.read_text())
    current = json.loads(LIVE.read_text())
    key = pubkey()
    existing_signature_valid = verify_signature(current, key)
    summary = {
        "base_apk_version_code": base.get("version_code"),
        "base_apk_package": base.get("package_name"),
        "current_revision": current.get("revision"),
        "required_next_revision": max(int(current.get("revision", 0)), int(base.get("version_code", 0)) - 1000) + 1,
        "existing_feed_signature_valid": existing_signature_valid,
        "candidate_checked": bool(args.candidate and args.pck),
        "release_status": "BLOCKED_NOT_SIGNED"
    }
    if args.candidate or args.pck:
        if not (args.candidate and args.pck):
            ap.error("--candidate and --pck must be provided together")
        candidate = json.loads(args.candidate.read_text(encoding="utf-8"))
        result = check_candidate(candidate, args.pck, base, current)
        summary["candidate"] = result
        summary["release_status"] = "CRYPTO_AND_BYTES_PASS_REQUIRES_VISUAL_QA" if result["passed"] else "BLOCKED_INVALID_CANDIDATE"
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(summary, indent=2, ensure_ascii=False)+"\n", encoding="utf-8")
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    if args.candidate and args.pck and not summary["candidate"]["passed"]:
        raise SystemExit(1)

if __name__ == "__main__":
    main()
