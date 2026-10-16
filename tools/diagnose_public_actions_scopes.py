#!/usr/bin/env python3
"""Report PUBLIC repository Actions configuration visibility, never key contents.

Uses only the current workflow's GITHUB_TOKEN and /repos/{PUBLIC_REPO}/ endpoints.
403/404 on secret metadata means metadata is inaccessible, NOT that no secrets
were configured. A secret alias listed in metadata does not prove it is injected
in this job: job-level/organization/environment scopes differ.
"""
from __future__ import annotations
import json
import os
from pathlib import Path
import subprocess

REPO="160701541-cell/xinyanshuo"
ALIASES=(
    "CANGLAN_PCK_SIGNING_KEY_B64",
    "CANGLAN_ORIGINAL_OTA_PRIVATE_KEY_PEM",
    "CANGLAN_UPDATE_PRIVATE_KEY_PEM",
    "CANGLAN_OTA_PRIVATE_KEY_PEM",
    "CANGLAN_UPDATE_SIGNING_KEY_PEM",
)
NON_EQUIVALENT=("CANGLAN_ANDROID_KEYSTORE_B64", "CANGLAN_SITE_PUBLISH_TOKEN")

def request(endpoint: str) -> tuple[str,dict]:
    result=subprocess.run(["gh","api","--method","GET",
                           f"repos/{REPO}/{endpoint}"],
                          stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,
                          text=True,timeout=20,check=False)
    if result.returncode!=0:
        return "ACCESS_UNAVAILABLE_NOT_EVIDENCE_OF_ABSENCE",{}
    try:
        obj=json.loads(result.stdout)
    except ValueError:
        return "INVALID_METADATA_RESPONSE",{}
    return "READABLE",obj

def main() -> None:
    if os.getenv("GITHUB_REPOSITORY")!=REPO:
        raise SystemExit("BLOCKED: only the allowed public repository may be inspected")
    if not os.getenv("GH_TOKEN"):
        raise SystemExit("BLOCKED: actions token not injected")
    report={"repository":REPO,
            "warning":"Only secret ALIAS metadata and access status; no secret values.",
            "workflow_job_environment":os.getenv("CANGLAN_WORKFLOW_ENVIRONMENT","NONE")}
    status,metadata=request("actions/secrets")
    if status=="READABLE":
        existing={v.get("name") for v in metadata.get("secrets",[])}
        report["repository_signer_aliases_in_metadata"]={
            name:name in existing for name in ALIASES
        }
        report["repository_apk_keystore_metadata_present"]=(
            "CANGLAN_ANDROID_KEYSTORE_B64" in existing)
    report["repository_secret_metadata"]=status
    status,metadata=request("environments")
    if status=="READABLE":
        names=[e.get("name","") for e in metadata.get("environments",[])]
        report["available_environment_names"]=names
        report["note_environment"]="Environment secrets do not enter jobs that omit environment:."
    report["environment_metadata"]=status
    status,metadata=request("actions/variables")
    if status=="READABLE":
        existing={v.get("name") for v in metadata.get("variables",[])}
        report["rsa_names_in_actions_variables"]={
            name:name in existing for name in ALIASES
        }
        report["note_variables"]="Actions Variables are not safe storage for RSA private keys."
    report["actions_variables_metadata"]=status
    dest=Path("qa-results/public-only-ota-actions-scope.json")
    dest.parent.mkdir(exist_ok=True,parents=True)
    dest.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
    print(json.dumps(report,ensure_ascii=False))
if __name__=="__main__":
    main()
