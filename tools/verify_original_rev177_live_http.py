#!/usr/bin/env python3
"""Check the *deployed* APK176 rev177 OTA bytes on official HTTPS, not Git source.

Never claim a release is live based only on GitHub commits/Actions artifacts.
Validates the installed app's exact RSA public key and full remote PCK SHA256.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import time
from urllib.error import URLError, HTTPError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from ota_release_gate import pubkey, verify_signature

FEED = "https://160701541-cell.github.io/xinyanshuo/android-preview/latest.json"
PACK = "https://160701541-cell.github.io/xinyanshuo/android-preview/canglan-content-rev-177.pck"
KNOWN_PACK_SHA = "af5e08020e7ae473a31ed2917839ea3544bdf3747b15790bcea49e46a54eb6f3"
KNOWN_PACK_BYTES = 20361696
CHUNK = 1024 * 1024


def fetch_headers(url: str, headers: dict | None = None):
    request = Request(url, headers={"Cache-Control": "no-cache",
                                    "Accept-Encoding": "identity",
                                    **(headers or {})})
    return urlopen(request, timeout=35)


def check_once():
    with fetch_headers(FEED) as f:
        if f.status != 200:
            raise RuntimeError(f"Remote manifest responded {f.status}")
        body = f.read(130000)
    value = json.loads(body)
    if (value.get("revision") != 177 or
            value.get("minimum_android_code") != 1176 or
            value.get("maximum_android_code") != 1176 or
            value.get("sha256") != KNOWN_PACK_SHA or
            value.get("size_bytes") != KNOWN_PACK_BYTES or
            value.get("pack_url") != PACK):
        raise RuntimeError("Remote feed not yet correct signed rev177 for original APK176")
    if not verify_signature(value, pubkey()):
        raise RuntimeError("Remote feed RSA signature INVALID for original installed APK")
    print("PASS_ORIGINAL_APK176_LIVE_FEED_RSA_REV177", value["revision"], flush=True)

    sha = hashlib.sha256()
    total = 0
    with fetch_headers(PACK) as f:
        if f.status != 200:
            raise RuntimeError(f"Remote complete PCK returned HTTP {f.status}")
        while True:
            data = f.read(CHUNK)
            if not data:
                break
            total += len(data)
            if total > KNOWN_PACK_BYTES:
                raise RuntimeError("Remote PCK exceeds exactly pinned length")
            sha.update(data)
    if total != KNOWN_PACK_BYTES or sha.hexdigest() != KNOWN_PACK_SHA:
        raise RuntimeError(f"Remote PCK hash mismatch / partial deploy bytes={total}")
    print("PASS_ORIGINAL_APK176_LIVE_PCK177_HTTPS_SHA256",
          sha.hexdigest(), total, flush=True)

    # The installed APK176 fetches HTTP ranges of exactly 1 MiB. Prove
    # the Pages CDN honours 206 ranges or its explicitly supported 200
    # full-file fallback; otherwise the native updater cannot download.
    with fetch_headers(PACK, {"Range": f"bytes=0-{CHUNK-1}"}) as r:
        received = r.read(KNOWN_PACK_BYTES + 1)
        status = r.status
        cr = r.headers.get("Content-Range", "")
    if status == 206:
        expected = f"bytes 0-{CHUNK-1}/{KNOWN_PACK_BYTES}"
        if len(received) != CHUNK or cr != expected:
            raise RuntimeError(f"HTTP Range incorrect for installed updater: {cr} length={len(received)}")
    elif status == 200:
        if len(received) != KNOWN_PACK_BYTES or hashlib.sha256(received).hexdigest() != KNOWN_PACK_SHA:
            raise RuntimeError("Server ignored Range without returning verified whole PCK")
    else:
        raise RuntimeError(f"Updater cannot handle HTTP {status} Range response")
    print("PASS_ORIGINAL_APK176_OTA177_CDN_HTTP_RANGE", status, len(received), flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--attempts", type=int, default=1)
    parser.add_argument("--wait-seconds", type=int, default=70)
    args = parser.parse_args()
    assert 1 <= args.attempts <= 6 and 0 <= args.wait_seconds <= 120
    for i in range(args.attempts):
        try:
            check_once()
            print("PASS_REV177_NOW_DELIVERABLE_TO_INSTALLED_ORIGINAL_GAME", flush=True)
            return
        except (RuntimeError, json.JSONDecodeError, URLError, HTTPError, TimeoutError) as e:
            print("PAGES_DEPLOYMENT_NOT_YET_PROVEN", i+1, str(e)[:210], flush=True)
            if i + 1 == args.attempts:
                raise SystemExit(1)
            time.sleep(args.wait_seconds)


if __name__ == "__main__":
    main()
