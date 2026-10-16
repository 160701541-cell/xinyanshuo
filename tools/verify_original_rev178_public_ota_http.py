#!/usr/bin/env python3
"""Verify REAL public GitHub Pages original-APK176 in-game rev178 update.

Read-only. Never uses private keys, never publishes APK or PCK. Confirms that
the precise URL requested by the installed client really serves the new,
original-RSA-signed manifest and the full intact official content pack.
"""
from __future__ import annotations
import hashlib
import json
import pathlib
import sys
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/"tools"))
from ota_release_gate import pubkey, verify_signature

HOST = "https://160701541-cell.github.io/xinyanshuo/android-preview/"
MANIFEST_URL = HOST + "latest.json"
PACK_URL = HOST + "canglan-content-rev-178.pck"
PACK_SHA = "4bf2e3e9e934a0bbdea97275b824317dbe6472b1782ee50a461673ffc4d93bdc"
PACK_SIZE = 21021440

def fetch(url: str, timeout: int=45) -> bytes:
    req = urllib.request.Request(url,headers={
        "User-Agent":"Canglan-original-APK176-public-OTA-integrity-audit",
        "Cache-Control":"no-cache", "Pragma":"no-cache"})
    with urllib.request.urlopen(req,timeout=timeout) as resp:
        if resp.status!=200:
            raise RuntimeError(f"HTTP status {resp.status}")
        return resp.read()

def main() -> None:
    site=None
    for trial in range(14):
        try:
            manifest=json.loads(fetch(MANIFEST_URL,timeout=25))
            if manifest.get("revision")==178:
                site=manifest
                break
            print("PAGES_PROPAGATION_WAIT",trial+1,manifest.get("revision"),flush=True)
        except (urllib.error.URLError,TimeoutError,ValueError) as err:
            print("PAGES_NOT_READY_RETRY",trial+1,type(err).__name__,flush=True)
        if trial<13:
            time.sleep(12)
    if site is None:
        raise SystemExit("BLOCKED: public original OTA feed does not expose rev178")
    assert site["schema"]==1 and site["channel"]=="android-preview"
    assert site["minimum_android_code"]<=1176<=site["maximum_android_code"]
    assert site["revision"]==178 and site["pack_url"]==PACK_URL
    assert site["sha256"]==PACK_SHA and site["size_bytes"]==PACK_SIZE
    assert verify_signature(site,pubkey()),"BLOCKED: published manifest is not signed by installed APK176 RSA key"
    local=json.loads((ROOT/"android-preview/latest.json").read_text())
    assert site==local,"BLOCKED: remote manifest differs from signed official GitHub manifest"
    print("PASS_PUBLIC_HTTP_ORIGINAL_APK176_SIGNED_MANIFEST_178",flush=True)
    # The actual PCK URL is immutable; fetch the entire binary, not just HEAD.
    pack=fetch(PACK_URL,timeout=105)
    assert len(pack)==PACK_SIZE,(len(pack),PACK_SIZE)
    assert pack[:4]==b"GDPC","BLOCKED: PCK missing Godot binary header"
    assert hashlib.sha256(pack).hexdigest()==PACK_SHA,"BLOCKED: remote PCK corrupt or stale"
    report={"status":"PASS_PUBLIC_GITHUB_PAGES_REV178_INTEGRITY",
        "original_installed_apk_version_code":1176,
        "channel":site["channel"],"revision":178,
        "manifest_url":MANIFEST_URL,"pack_url":PACK_URL,
        "bytes":len(pack),"sha256":PACK_SHA,
        "original_rsa_manifest_valid":True,
        "phone_device_test":"NOT_YET_RUN_ON_USER_PHONE"}
    output=ROOT/"qa-results/original-rev178-public-http-acceptance.json"
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
    print("PASS_PUBLIC_HTTPS_ORIGINAL_APK176_REV178_FULL_PACK_SHA256",PACK_SHA,flush=True)

if __name__=="__main__":
    main()
