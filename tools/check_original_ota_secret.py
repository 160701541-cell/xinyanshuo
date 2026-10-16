#!/usr/bin/env python3
"""Secure original-APK RSA secret capability probe. Never prints private key.
Only emits a Boolean capability and original key match result.
"""
import base64, json, os, pathlib, re, subprocess, tempfile
from ota_release_gate import pubkey

ENV_CANDIDATES=(
    "CANGLAN_PCK_SIGNING_KEY_B64",  # Content-signing RSA; never Android keystore
    "CANGLAN_ORIGINAL_OTA_PRIVATE_KEY_PEM",
    "CANGLAN_UPDATE_PRIVATE_KEY_PEM",
    "CANGLAN_OTA_PRIVATE_KEY_PEM",
    "CANGLAN_UPDATE_SIGNING_KEY_PEM",
)
def decode_private_secret(value: str) -> bytes:
    """Accept PEM, escaped-newline PEM or whitespace-wrapped base64 PEM.
    Return key bytes in memory only; never log the value.
    """
    raw=value.strip()
    if not raw:
        raise ValueError("empty secret")
    if raw.startswith("-----BEGIN "):
        return (raw.replace("\\n","\n").rstrip()+"\n").encode("utf-8")
    compact=re.sub(r"\s+","",raw)
    decoded=base64.b64decode(compact,validate=True)
    if not decoded.startswith(b"-----BEGIN "):
        raise ValueError("content signing secret is not a PEM-formatted RSA key")
    return decoded.rstrip()+b"\n"


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
    # Boolean/status-only diagnostics. Never print secret bytes, lengths or
    # hashes; never confuse Android APK signing credentials with the OTA RSA.
    secret_status={}
    for name in ENV_CANDIDATES:
        value=os.environ.get(name,"")
        if not value.strip():
            secret_status[name]="NOT_INJECTED_IN_THIS_JOB"
            continue
        available+=1
        try:
            key=decode_private_secret(value)
            if pub_der(key,True)==old_pub:
                matched=True
                secret_status[name]="MATCHES_ORIGINAL_APK_RSA_PUBLIC_KEY"
            else:
                secret_status[name]="INJECTED_BUT_DIFFERENT_RSA_KEY"
        except (ValueError,subprocess.SubprocessError,OSError):
            secret_status[name]="INJECTED_BUT_INVALID_RSA_PEM_OR_ENCODING"
    report={
        "signing_alias_diagnostics":secret_status,
        "android_apk_keystore_secret_present":bool(os.environ.get("CANGLAN_ANDROID_KEYSTORE_B64","").strip()),
        "site_publish_token_alias_set":os.environ.get("PUBLIC_SITE_PUBLISH_TOKEN_PRESENT","").lower()=="true",
        "ota_release_enabled_variable":os.environ.get("PUBLIC_OTA_RELEASE_ENABLED","").lower()=="true",
        "note_site_publisher":"CANGLAN_SITE_PUBLISH_TOKEN only pushes site updates; it cannot sign APK176 PCK manifests.",
        "note_android_keystore":"Android APK keystore is NOT a valid content-update RSA manifest signer",
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
