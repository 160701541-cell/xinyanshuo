#!/usr/bin/env python3
"""Verify and stage a signed Canglan PCK release for the public xinyanshuo site.

Never publish an unsigned template or a package that does not match the
immutable production RSA verification key and canonical HTTPS URL.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

from sign_pck_release import signing_message

PUBLIC_ORIGIN = "https://160701541-cell.github.io/xinyanshuo"
FEED_DIR = PUBLIC_ORIGIN + "/android-preview"
CHANNEL = "android-preview"
MAX_PCK_BYTES = 95 * 1024 * 1024  # GitHub Pages is unsuitable for huge packs.
MAX_SITE_BYTES = 950 * 1024 * 1024


def verify_signed(pack: Path, manifest_path: Path, public_key: Path) -> dict:
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or data.get("signature", "") == "":
        raise ValueError("UNSIGNED PCK is forbidden")
    if "_not_a_release" in data:
        raise ValueError("Unsigned developer template must never be published")
    if data.get("schema") != 1 or data.get("channel") != CHANNEL:
        raise ValueError("Unexpected manifest schema/channel")
    revision = data.get("revision")
    if type(revision) is not int or not 0 < revision < 1000000000:
        raise ValueError("Release revision invalid")
    expected_url = f"{FEED_DIR}/canglan-content-rev-{revision}.pck"
    if data.get("pack_url") != expected_url:
        raise ValueError(f"Pack URL must match fixed xinyanshuo domain: {expected_url}")
    if pack.name != f"canglan-content-rev-{revision}.pck":
        raise ValueError("Pack file name must correspond to the manifest revision")
    # Rev177 is an intentionally NON-CUMULATIVE three-file touch hotfix.
    # Never let it replace cumulative PCK167 on APK165 or any older client.
    # Bind this guard at the independent publisher, not just at the signer.
    if revision == 177 and (
        type(data.get("minimum_android_code")) is not int
        or data["minimum_android_code"] != 1176
    ):
        raise ValueError("PCK177 tiny overlay MUST be scoped to APK176+ (minimum_android_code=1176)")
    if type(data.get("size_bytes")) is not int or data["size_bytes"] != pack.stat().st_size:
        raise ValueError("Pack size differs from signed metadata")
    if not 512 <= pack.stat().st_size <= MAX_PCK_BYTES:
        raise ValueError("GitHub Pages PCK exceeds permitted size")
    if data.get("sha256") != hashlib.sha256(pack.read_bytes()).hexdigest():
        raise ValueError("Pack SHA-256 mismatch")
    if not 0 < int(data.get("minimum_android_code", 0)) <= int(data.get("maximum_android_code", -1)):
        raise ValueError("Incompatible APK range")
    if not isinstance(data.get("notes"), str) or len(data["notes"]) > 256:
        raise ValueError("Malformed release notes")
    signature = base64.b64decode(data["signature"], validate=True)
    if len(signature) < 256:
        raise ValueError("RSA signature too small")
    with tempfile.TemporaryDirectory() as td:
        sigfile = Path(td) / "signature.bin"
        sigfile.write_bytes(signature)
        result = subprocess.run(
            ["openssl", "dgst", "-sha256", "-verify", str(public_key),
             "-signature", str(sigfile)],
            input=signing_message(data), stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if result.returncode != 0:
            raise ValueError("Signed PCK does NOT match baked-in release verification key")
    return data


def stage_site(template: Path, checkout: Path, pack: Path,
               manifest_file: Path, public_key: Path) -> int:
    signed = verify_signed(pack, manifest_file, public_key)
    # APK176's original updater refuses any OTA revision <= Build.CODE-1000.
    # Read the genuine public APK identity in the website checkout, not an
    # invented or caller-supplied environment variable. Reject PCK168 even
    # when its RSA signature and SHA-256 are valid.
    base_file = checkout / "android-preview" / "base-latest.json"
    if not base_file.is_file():
        raise ValueError("Missing public signed base APK identity; release blocked")
    base = json.loads(base_file.read_text(encoding="utf-8"))
    base_code = base.get("version_code")
    if type(base_code) is not int or base_code < 1000:
        raise ValueError("Invalid Android base APK versionCode")
    if not isinstance(base.get("signature_cert_sha256"), str) or not re.fullmatch(
        r"[0-9a-f]{64}", base["signature_cert_sha256"]
    ):
        raise ValueError("Base APK signing identity missing or invalid")
    # Fail closed if website APK metadata no longer matches the independently
    # verified 2026-10-15 original APK176. Require a new phone/update audit
    # before ever changing this pin.
    if (base_code != 1176 or base.get("sha256") !=
            "3cef8894246ddd4c481c48abfc99a55008f82be17885706f2cbd060b9ed21a7a"):
        raise ValueError("Published APK identity changed; re-audit before issuing OTA")
    if signed["revision"] <= base_code - 1000:
        raise ValueError(
            f"OTA revision {signed['revision']} is ignored by APK versionCode "
            f"{base_code}; must exceed {base_code - 1000}"
        )
    if not (int(signed["minimum_android_code"]) <= base_code <= int(signed["maximum_android_code"])):
        raise ValueError("Signed PCK does not permit currently published Android APK")
    # Existing public release must not silently roll back.
    live_manifest = checkout / "android-preview" / "latest.json"
    if live_manifest.exists():
        previous = json.loads(live_manifest.read_text(encoding="utf-8"))
        if int(previous.get("revision", 0)) >= signed["revision"]:
            raise ValueError("Refusing to replace published PCK with older/same revision")
    # CRITICAL SITE-OWNER RULE: The official Pages project owns its web
    # design, creative concepts, group links and live development journal.
    # An OTA/PCK publisher may ship ONLY signed release data, NEVER overwrite
    # newer public index.html/style.css/site.js with this old APK template.
    # Previously release #148 destroyed the updated cinematic website on
    # publish, despite the public site's own checks being green. Fix it here.
    for filename in ("index.html", "style.css", "site.js", "favicon.svg", ".nojekyll"):
        origin = template / filename
        dest = checkout / filename
        if not origin.exists():
            raise ValueError(f"Missing fallback website template: {origin}")
        if not dest.exists():
            shutil.copy2(origin, dest)  # Bootstrap only, never destructive.
            print("SITE_BOOTSTRAP_ONLY", filename)
        else:
            print("SITE_OWNER_PRESERVED", filename)
    pck_root = checkout / "android-preview"
    pck_root.mkdir(parents=True, exist_ok=True)
    existing_pack = pck_root / pack.name
    if existing_pack.exists() and hashlib.sha256(existing_pack.read_bytes()).hexdigest() != signed["sha256"]:
        raise ValueError("Existing revision has different contents")
    shutil.copy2(pack, existing_pack)
    # The public site's latest.json is committed together with its PCK so
    # clients never see new pointers to a missing file on git branches.
    shutil.copy2(manifest_file, live_manifest)
    size_sum = sum(p.stat().st_size for p in checkout.rglob("*")
                   if p.is_file() and ".git" not in p.parts)
    if size_sum > MAX_SITE_BYTES:
        raise ValueError("Public GitHub Pages site nearing GitHub Pages size limits")
    print(f"XINYANSHUO_READY revision={signed['revision']} "
          f"size={signed['size_bytes']} pack_sha256={signed['sha256']} "
          f"site={PUBLIC_ORIGIN} (git push still required)")
    return signed["revision"]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--template", type=Path, default=Path("site/xinyanshuo"))
    ap.add_argument("--checkout", type=Path, required=True)
    ap.add_argument("--pack", type=Path, required=True)
    ap.add_argument("--manifest", type=Path, required=True)
    ap.add_argument("--public-key", type=Path, default=Path("godot3d/update/update_signer_public.pem"))
    args = ap.parse_args()
    stage_site(args.template, args.checkout, args.pack, args.manifest, args.public_key)


if __name__ == "__main__":
    main()
