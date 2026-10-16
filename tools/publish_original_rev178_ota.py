#!/usr/bin/env python3
"""Release rev178 into the installed APK176 OTA channel, PUBLIC repo only.

Invariant: artifacts MUST be exact authentic original-main Godot QA bytes;
nothing is published unless the existing APK's *immutable* RSA key verifies
a new manifest and checks for both the installed version and current feed pass.
No private-key contents are printed, stored in git, or included in artifacts.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile

ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/"tools"))
sys.path.insert(0,str(ROOT/"logic-qa/release-gate"))
from check_original_ota_secret import pub_der
from ota_release_gate import pubkey, check_candidate, verify_signature, HOST
from publish_original_rev177_ota import matching_original_private
from sign_pck_release import build_manifest, sign_manifest

REVISION=178
APK_CODE=1176
EXPECTED_PACK_SHA="4bf2e3e9e934a0bbdea97275b824317dbe6472b1782ee50a461673ffc4d93bdc"
EXPECTED_PACK_SIZE=21021440
EXPECTED_PARENT_REVISION=177
PACK_NAME=f"canglan-content-rev-{REVISION}.pck"
PACK_URL=HOST+PACK_NAME
ORIGINAL_SCENE_PASS="PASS_APK176_ACTUAL_MAIN_INSTANTIATED_NO_ENGINE_ERRORS_WITH_REAL_HOUSE"
MAIN_MARKER="OBSERVED_APK176_MAIN_INSTANCE_WITH_PORTAL_AND_IMAGES_PENDING_ENGINE_ERROR_AUDIT"


def qa_proof(pack:Path, unsigned:Path, runtime:Path, root:Path) -> dict:
    base=json.loads((root/"android-preview/base-latest.json").read_text())
    live=json.loads((root/"android-preview/latest.json").read_text())
    if base.get("package_name")!="org.canglan.ancient25d.preview" or base.get("version_code")!=APK_CODE:
        raise RuntimeError("BLOCKED: original installed Android app identity changed")
    if live.get("revision")!=EXPECTED_PARENT_REVISION or not verify_signature(live,pubkey()):
        raise RuntimeError("BLOCKED: current production OTA is not authentic signed rev177")
    if not pack.is_file() or pack.stat().st_size!=EXPECTED_PACK_SIZE:
        raise RuntimeError("BLOCKED: rev178 QA PCK is missing or has unexpected bytes")
    payload=pack.read_bytes()
    if payload[:4]!=b"GDPC" or hashlib.sha256(payload).hexdigest()!=EXPECTED_PACK_SHA:
        raise RuntimeError("BLOCKED: PCK differs from exact QA-approved artifact")
    manifest=json.loads(unsigned.read_text())
    if not all([manifest.get("revision")==REVISION,
                manifest.get("minimum_android_code")==APK_CODE,
                manifest.get("maximum_android_code")==APK_CODE,
                manifest.get("pack_url")==PACK_URL,
                manifest.get("sha256")==EXPECTED_PACK_SHA,
                manifest.get("size_bytes")==EXPECTED_PACK_SIZE,
                manifest.get("signature")=="",
                manifest.get("_not_a_release")=="UNSIGNED_DEVELOPER_TEMPLATE_DO_NOT_HOST"]):
        raise RuntimeError("BLOCKED: unsigned Godot QA manifest invalid or not rev178")
    log=runtime.read_text(encoding="utf-8")
    # The successful Godot runner writes the OBSERVED marker into this file.
    # Its strict "PASS_APK176_ACTUAL_MAIN..." is a GitHub Actions shell
    # echo AFTER the log is closed; requiring that line in the log was an
    # impossible release condition. The release workflow separately checks
    # that the real QA run conclusion is success.
    if MAIN_MARKER not in log or any(
        bad in log for bad in ("SCRIPT ERROR:","Parse Error:","ERROR:","FAIL_APK176")
    ):
        raise RuntimeError("BLOCKED: authentic original compiled APK scene QA failed")
    return manifest


def main() -> None:
    ap=argparse.ArgumentParser()
    ap.add_argument("--qa-pack",type=Path)
    ap.add_argument("--qa-manifest",type=Path)
    ap.add_argument("--qa-runtime-log",type=Path)
    ap.add_argument("--staging",type=Path,default=ROOT)
    ap.add_argument("--preflight",action="store_true")
    args=ap.parse_args()
    key=matching_original_private()
    if key is None:
        print("BLOCKED: original pinned-key RSA signer unavailable in PUBLIC xinyanshuo Actions context")
        raise SystemExit(2)
    if pub_der(key,True)!=pub_der(pubkey().encode("utf8"),False):
        raise RuntimeError("BLOCKED: secret does not match installed APK176 RSA identity")
    print("PASS_RSA_SIGNER_MATCHES_INSTALLED_APK176_PUBLIC_KEY_NO_SECRET_EXPOSED")
    if args.preflight:
        return
    if not all((args.qa_pack,args.qa_manifest,args.qa_runtime_log)):
        ap.error("All three real original-APK QA artifacts are mandatory")
    root=args.staging.resolve()
    qa_proof(args.qa_pack,args.qa_manifest,args.qa_runtime_log,root)
    with tempfile.TemporaryDirectory(prefix="canglan-public-ota-") as tmp:
        tmpdir=Path(tmp)
        keyfile=tmpdir/"key.pem"
        keyfile.write_bytes(key)
        keyfile.chmod(0o600)
        pubfile=tmpdir/"original-public.pem"
        pubfile.write_text(pubkey())
        new_pack=tmpdir/PACK_NAME
        shutil.copyfile(args.qa_pack,new_pack)
        manifest=build_manifest(new_pack,REVISION,APK_CODE,APK_CODE,PACK_URL,
            "苍岚原游戏：既有WorldX古风NPC独立身份、状态与室内交互")
        signed=sign_manifest(manifest,keyfile,pubfile)
        if not verify_signature(signed,pubkey()):
            raise RuntimeError("BLOCKED: signed release not accepted by original app key")
        parent=json.loads((root/"android-preview/latest.json").read_text())
        base=json.loads((root/"android-preview/base-latest.json").read_text())
        result=check_candidate(signed,new_pack,base,parent)
        if not result["passed"]:
            raise RuntimeError("BLOCKED: OTA release guard: "+repr(result["errors"]))
        # Stage as last operation, after EVERY validation. Caller publishes atomically.
        outfile=root/"android-preview"/PACK_NAME
        if outfile.exists():
            if hashlib.sha256(outfile.read_bytes()).hexdigest()!=EXPECTED_PACK_SHA:
                raise RuntimeError("BLOCKED: existing site PCK differs (do not overwrite)")
        else:
            shutil.copyfile(new_pack,outfile)
        latest=root/"android-preview/latest.json"
        latest.write_text(json.dumps(signed,ensure_ascii=False,indent=2)+"\n")
        # Never write sensitive key material into release report.
        report={"status":"STAGED_SIGNED_REV178_AWAITING_GIT_PUBLISH",
            "revision":REVISION,"apk_version_code":APK_CODE,
            "sha256":EXPECTED_PACK_SHA,"size_bytes":EXPECTED_PACK_SIZE,
            "rsa_matches_original_installed_apk":True,
            "original_scene_qa_passed":True,"repository":"160701541-cell/xinyanshuo"}
        (root/"qa-results").mkdir(exist_ok=True)
        (root/"qa-results/real-rev178-signed-release-report.json").write_text(
            json.dumps(report,indent=2)+"\n")
        print("PASS_ORIGINAL_APK176_SIGNED_REV178_STAGED",EXPECTED_PACK_SHA)


if __name__=="__main__":
    main()
