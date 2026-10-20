#!/usr/bin/env python3
"""Fail-closed Android update signing gate for the WorldBox side project.

Static checks only. Does not expose or reconstruct a signing key.
No commercial game APK should be uploaded to GitHub Actions.
"""
import argparse
import json
import re
import subprocess
from pathlib import Path

OLD_PACKAGE='com.xinyanshuo.worldbox.lab13'
ISOLATED_PACKAGE='com.xinyanshuo.worldbox.lab31'
EXPECTED_OLD_SIGNER='a1fa2827668e11da772e9984f277623bb95fc7e0556622a755b7117b8c407104'
SHA256_PATTERN=re.compile(r'V3\.0 Signer: certificate SHA-256 digest: ([0-9a-f]{64})')


def parse_certificate_sha256(log):
    match=SHA256_PATTERN.search(log)
    if not match:
        raise ValueError('unable to verify v3 signer; do not assume installer compatibility')
    return match.group(1)


def decide_install_path(installed_package, installed_cert, candidate_package, candidate_cert):
    for cert in (installed_cert,candidate_cert):
        if not re.fullmatch(r'[0-9a-f]{64}',cert):
            raise ValueError('invalid signer SHA256')
    if installed_package==candidate_package:
        if installed_cert!=candidate_cert:
            return {'safe_to_update':False,'reason':'SIGNATURE_CONFLICT','recommended':'PRESERVE_INSTALLED_APP_NO_UNINSTALL'}
        return {'safe_to_update':True,'reason':'MATCHING_CERTS','recommended':'CHECK_VERSION_CODE_AND_ANDROID_COMPATIBILITY'}
    if candidate_package==ISOLATED_PACKAGE and installed_package==OLD_PACKAGE:
        return {'safe_to_update':False,'side_by_side_candidate':True,'reason':'SEPARATE_APP_ID','recommended':'INSTALL_SEPARATELY_NO_SAVE_MIGRATION'}
    return {'safe_to_update':False,'reason':'UNKNOWN_PACKAGE_PAIR','recommended':'STOP_REVIEW_MANIFEST'}


def inspect_existing(apksigner_jar,apk):
    proc=subprocess.run(['java','-jar',str(apksigner_jar),'verify','--print-certs','--verbose',str(apk)],capture_output=True,text=True,check=False)
    if proc.returncode:
        raise RuntimeError('APK signature verification failed: '+proc.stderr[:300])
    if 'Verified using v2 scheme (APK Signature Scheme v2): true' not in proc.stdout:
        raise RuntimeError('APK lacks validated v2 signature')
    return parse_certificate_sha256(proc.stdout)


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--apksigner',required=True,type=Path)
    ap.add_argument('--installed-reference',required=True,type=Path)
    ap.add_argument('--new-apk',required=True,type=Path)
    ap.add_argument('--new-package',required=True)
    ap.add_argument('--out',required=True,type=Path)
    args=ap.parse_args()
    reference=inspect_existing(args.apksigner,args.installed_reference)
    candidate=inspect_existing(args.apksigner,args.new_apk)
    state=decide_install_path(OLD_PACKAGE,reference,args.new_package,candidate)
    result={'installed_reference_signature':reference,'new_apk_signature':candidate,
            'actual_device_installed_cert_measured':False,'installed_reference_is_v18':True,
            'new_package':args.new_package,'decision':state,
            'warning':'signed APK checks alone do not prove Android16 installation or WorldBox runtime'}
    args.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print(json.dumps(result,ensure_ascii=False,indent=2))
    if state['reason'] in ('SIGNATURE_CONFLICT','UNKNOWN_PACKAGE_PAIR'):
        raise SystemExit(2)

if __name__=='__main__':main()
