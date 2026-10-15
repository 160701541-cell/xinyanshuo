#!/usr/bin/env python3
"""Generate a Godot-Crypto-compatible RSA-PKCS1-v1_5/SHA256 signed PCK manifest.

Run only on a trusted machine or GitHub Actions with a private-key secret.
The signing key must NEVER be checked into the private OR public git repository.
"""
import argparse
import os
import base64
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

CHANNEL = "android-preview"
MAX_SIZE = 536870912


def signing_message(manifest: dict) -> bytes:
    # Exact byte-for-byte counterpart to update_protocol.gd::payload().
    return (
        "canglan-pck-v1\n"
        f"{manifest['schema']}\n{manifest['channel']}\n{manifest['revision']}\n"
        f"{manifest['minimum_android_code']}\n{manifest['maximum_android_code']}\n"
        f"{manifest['sha256']}\n{manifest['size_bytes']}\n"
        f"{manifest['pack_url']}\n{manifest['notes']}\n"
    ).encode("utf-8")


def build_manifest(pack: Path, revision: int, minimum_code: int,
                   maximum_code: int, url: str, notes: str) -> dict:
    if not pack.is_file():
        raise ValueError("PCK pack does not exist")
    size = pack.stat().st_size
    if size < 512 or size > MAX_SIZE:
        raise ValueError("PCK size outside accepted boundaries")
    if not (revision > 0 and 0 < minimum_code <= maximum_code):
        raise ValueError("Revision/Android compatibility range invalid")
    if len(notes) > 256 or "\n" in notes:
        raise ValueError("Release note too long or contains a newline")
    if not re.match(r"^https://[^/\\s@#]+/.+\.pck(?:\?.*)?$", url):
        raise ValueError("Pack must be hosted on an HTTPS URL, with a real host and .pck path")
    sha = hashlib.file_digest(pack.open("rb"), "sha256").hexdigest()
    return {
        "schema": 1,
        "channel": CHANNEL,
        "revision": revision,
        "minimum_android_code": minimum_code,
        "maximum_android_code": maximum_code,
        "sha256": sha,
        "size_bytes": size,
        "pack_url": url,
        "notes": notes,
    }


def sign_manifest(manifest: dict, private_path: Path, public_path: Path) -> dict:
    if not private_path.is_file() or not public_path.is_file():
        raise ValueError("Missing signing key. Do not release an unsigned patch.")
    message = signing_message(manifest)
    signed = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", str(private_path)],
        input=message, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        check=True,
    ).stdout
    with tempfile.TemporaryDirectory() as tmp:
        tmpfile = Path(tmp) / "signature.bin"
        tmpfile.write_bytes(signed)
        subprocess.run(
            ["openssl", "dgst", "-sha256", "-verify", str(public_path),
             "-signature", str(tmpfile)],
            input=message, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            check=True,
        )
    result = dict(manifest)
    result["signature"] = base64.b64encode(signed).decode("ascii")
    return result


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--pack", type=Path, required=True)
    p.add_argument("--revision", type=int, required=True)
    p.add_argument("--minimum-android-code", type=int, required=True)
    p.add_argument("--maximum-android-code", type=int, default=2147483000)
    p.add_argument("--pack-url", required=True)
    p.add_argument("--notes", default="苍岚：内容与资源更新")
    p.add_argument("--private-key", type=Path)
    p.add_argument("--public-key", type=Path,
                   default=Path("godot3d/update/update_signer_public.pem"))
    p.add_argument("--unsigned-template", action="store_true",
                   help="Artifact preview ONLY: never use as a live update feed")
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    if args.unsigned_template and args.private_key is not None:
        p.error("Unsigned template cannot accept a private key")
    if not args.unsigned_template and args.private_key is None:
        p.error("Signed publication requires a private key")
    if not args.unsigned_template:
        # This is the one-time stable APK's versionCode, not THIS CI build's
        # incrementing versionCode. Without it, future patches reject the
        # user's original "install once" base APK.
        fixed_base = os.environ.get("CANGLAN_UPDATE_MIN_BINARY_CODE", "").strip()
        if not fixed_base.isdigit() or int(fixed_base) != args.minimum_android_code:
            raise ValueError(
                "Set CANGLAN_UPDATE_MIN_BINARY_CODE to the FIRST permanent-signed "
                "base APK versionCode before publishing a signed PCK"
            )
        allowed_prefix = "https://160701541-cell.github.io/xinyanshuo/android-preview/"
        if not args.pack_url.startswith(allowed_prefix):
            raise ValueError("Signed OTA release must target the pinned xinyanshuo HTTPS feed")
    manifest = build_manifest(
        args.pack, args.revision, args.minimum_android_code,
        args.maximum_android_code, args.pack_url, args.notes)
    if args.unsigned_template:
        manifest["signature"] = ""
        manifest["_not_a_release"] = "UNSIGNED_DEVELOPER_TEMPLATE_DO_NOT_HOST"
    else:
        manifest = sign_manifest(manifest, args.private_key, args.public_key)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"MANIFEST name={args.output} revision={args.revision} "
        f"sha256={manifest['sha256']} signed={not args.unsigned_template}"
    )


if __name__ == "__main__":
    main()
