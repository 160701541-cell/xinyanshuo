#!/usr/bin/env python3
"""Secure original-APK RSA secret capability probe. Never prints private key.
Only emits a Boolean capability and original key match result.
"""
import base64, json, os, pathlib, subprocess, tempfile
from ota_release_gate import pubkey

ENV_CANDIDATES=(
    "CANGLAN_PCK_SIGNING_KEY_B64",  # Actual legacy signer alias from canglan-world private CI
    "CANGLAN_ORIGINAL_OTA_PRIVATE_KEY_PEM",
    "CANGLAN_UPDATE_PRIVATE_KEY_PEM",
    "CANGLAN_OTA_PRIVATE_KEY_PEM",
    "CANGLAN_UPDATE_SIGNING_KEY_PEM",
)
def pub_der(input_bytes: bytes, is_private: bool) -> bytes:
    with tempfile.TemporaryDirectory() as work:
        d=pathlib.Path(work)
        p=d/"source.pem"
        p.write_bytes(input_bytes)
        cmd=["openssl","pkey","-in",str(p)]
        if not is_private:
            cmd.append("-pubin")
        cmd.extend(["-pubout","-outform","DER"])
        ret=subprocess.run(cmd,capture_output=True,timeout=10)
        if ret.returncode:
            raise ValueError("Provided signing key is not valid PEM")
        return ret.stdout

def main():
    matched=False
    available=0
    old_pub=pub_der(pubkey().encode("utf8"), False)
    for name in ENV_CANDIDATES:
        value=os.environ.get(name,"").strip()
        if not value:
            continue
        available+=1
        if not value.startswith("-----BEGIN"):
            try:
                value=base64.b64decode(value,validate=True).decode("utf8")
            except (ValueError,UnicodeDecodeError):
                continue
        try:
            matched=matched or pub_der(value.encode("utf8"), True)==old_pub
        except (ValueError,subprocess.SubprocessError):
            pass
    report={
        "probe_repository":os.environ.get("GITHUB_REPOSITORY","unknown"),
        "scope_notice":"This probe reads only explicitly injected xinyanshuo public repository Actions secrets; no other repository is consulted.",
        "original_signing_key_candidates_available":available,
        "original_rsa_key_matches_apk176":matched,
        "safe_to_sign_original_ota":matched,
        "status":"SIGNER_AVAILABLE_IN_THIS_WORKFLOW" if matched else "NO_MATCHING_SIGNER_IN_PUBLIC_WORKFLOW"
    }
    dest=pathlib.Path("qa-results/original-apk176-signing-readiness.json")
    dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_text(json.dumps(report,indent=2)+"\n")
    print(json.dumps(report))
    if not matched:
        raise SystemExit(2)
if __name__=="__main__":
    main()
