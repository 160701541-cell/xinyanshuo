#!/usr/bin/env python3
"""Read-only proof of rev179 on public Pages, not merely committed to git.

Checks exact remote manifest, immutable client RSA, complete PCK SHA/size,
and the same 1MiB HTTP Range behaviour required by installed APK176.
Writes a small actionable JSON report; never prints credentials.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import sys
import time
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from ota_release_gate import pubkey, verify_signature

FEED = "https://160701541-cell.github.io/xinyanshuo/android-preview/latest.json"
EXPECTED_REV = 179
CHUNK = 1024 * 1024
REPORT = ROOT / "qa-results/rev179-public-http.json"


def get(url: str, range_header: str | None = None):
    hdr = {"Cache-Control": "no-cache", "Pragma": "no-cache",
           "Accept-Encoding": "identity", "User-Agent": "Canglan-APK176-OTA179-Verify/1"}
    if range_header:
        hdr["Range"] = range_header
    return urlopen(Request(url, headers=hdr), timeout=30)


def probe() -> dict:
    expected = json.loads((ROOT / "android-preview/latest.json").read_text("utf-8"))
    if expected.get("revision") != EXPECTED_REV or not verify_signature(expected, pubkey()):
        raise RuntimeError("LOCAL_REV179_NOT_AUTHENTIC")
    with get(FEED) as response:
        if response.status != 200:
            raise RuntimeError("PAGES_MANIFEST_HTTP_" + str(response.status))
        remote = json.loads(response.read(130000))
        manifest_cache = response.headers.get("Cache-Control", "")
    if remote.get("revision") != EXPECTED_REV:
        raise RuntimeError("PAGES_CDN_STALE_MANIFEST_REMOTE_REV_" + str(remote.get("revision")))
    if remote != expected:
        raise RuntimeError("PAGES_MANIFEST_DIFFERS_FROM_PUBLISHED_GIT_REV179")
    if not verify_signature(remote, pubkey()):
        raise RuntimeError("PAGES_RSA_SIGNATURE_INVALID_FOR_APK176")
    sha = hashlib.sha256()
    received = 0
    pack_url = remote["pack_url"]
    with get(pack_url) as response:
        if response.status != 200:
            raise RuntimeError("PAGES_PCK_HTTP_" + str(response.status))
        while True:
            chunk = response.read(CHUNK)
            if not chunk:
                break
            received += len(chunk)
            if received > expected["size_bytes"]:
                raise RuntimeError("PAGES_PCK_OVERSIZE")
            sha.update(chunk)
    if received != expected["size_bytes"] or sha.hexdigest() != expected["sha256"]:
        raise RuntimeError("PAGES_PCK_MISSING_TRUNCATED_OR_SHA256_MISMATCH")
    with get(pack_url, "bytes=0-" + str(CHUNK - 1)) as response:
        status = response.status
        body = response.read(expected["size_bytes"] + 1)
        content_range = response.headers.get("Content-Range", "")
    if status == 206:
        if len(body) != CHUNK or content_range != "bytes 0-%d/%d" % (CHUNK - 1, received):
            raise RuntimeError("PAGES_RANGE_206_MISMATCH")
    elif status == 200:
        if len(body) != received or hashlib.sha256(body).hexdigest() != expected["sha256"]:
            raise RuntimeError("PAGES_RANGE_IGNORED_BUT_WHOLE_BODY_INVALID")
    else:
        raise RuntimeError("PAGES_RANGE_HTTP_" + str(status))
    return {"status": "PASS_REV179_PUBLIC_HTTPS_RSA_SHA256_AND_RANGE",
            "live_revision": 179, "installed_apk_version_code": 1176,
            "pck_bytes": received, "pck_sha256": sha.hexdigest(),
            "http_range_status": status, "remote_manifest_cache_control": manifest_cache,
            "still_needs_physical_phone_acceptance": True}


def main() -> None:
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(1, 4):
        try:
            result = probe()
            REPORT.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
            print(json.dumps(result, ensure_ascii=False), flush=True)
            return
        except (RuntimeError, HTTPError, URLError, TimeoutError, ValueError, OSError) as exc:
            reason = str(exc)[:240] or type(exc).__name__
            state = {"status": "BLOCKED_REMOTE_REV179_NOT_VERIFIED",
                     "attempt": attempt, "reason": reason}
            REPORT.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n")
            print(json.dumps(state, ensure_ascii=False), flush=True)
            if attempt < 3:
                time.sleep(25)
    raise SystemExit(1)


if __name__ == "__main__":
    main()
