#!/usr/bin/env python3
"""Fail-closed check: can EXISTING installed APK176 load the new NPC native AI?

No signing and no release. Original APK is obtained exclusively from current
public repository base-latest.json; never from any other repository.
"""
from __future__ import annotations
import json, pathlib, zipfile

ROOT=pathlib.Path(__file__).resolve().parent.parent
base=json.loads((ROOT/"android-preview/base-latest.json").read_text())
apk=ROOT/base["file"]
assert base["package_name"]=="org.canglan.ancient25d.preview"
assert base["version_code"]==1176
assert apk.is_file(),f"Published original APK binary missing: {apk}"
with zipfile.ZipFile(apk) as z:
    names=z.namelist()
native=[p for p in names if p.startswith("lib/") and p.endswith(".so")]
gdextensions=[p for p in names if p.startswith("assets/") and p.endswith(".gdextension")]
llama=[p for p in names if ("llama" in p.lower() or "canglan_ai" in p.lower() or "ggml" in p.lower())]
manifest={
    "original_app_package":base["package_name"],"original_apk_version_code":1176,
    "original_apk_file":str(base["file"]),"packaging":"original installation, not stand-alone 3D test app",
    "android_abi_libs":[{"file":p,"is_ai_backend":any(a in p.lower() for a in ("llama","ggml","canglan_ai"))} for p in native],
    "gdextension_descriptors":gdextensions,
    "llama_ggml_native_assets":llama,
    "local_ai_api_class_expected":"CanglanLocalLLM",
    "required_native_runtime_exists":bool(llama),
    "may_claim_local_npc_ai_ota_ready":False,
    "why":"No original-APK176 Android native CanglanLocalLLM+Qwen runtime verification; standalone Godot3D scripts are not an original-game OTA patch",
    "status":"NATIVE_AI_APK_UPDATE_OR_COMPATIBILITY_BRIDGE_REQUIRED"
}
path=ROOT/"qa-results/original-apk176-ai-native-audit.json"
path.parent.mkdir(exist_ok=True,parents=True)
path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
print("ORIGINAL_NATIVE_LIBS",len(native),"AI_BACKEND_MATCHES",len(llama))
if llama:
    print("AI_BACKEND_ARCHIVE_ENTRIES_EXIST_BUT_RUNTIME_UNVERIFIED")
else:
    print("P0_BLOCKED_ORIGINAL_APK176_NO_NATIVE_LLAMA_LIBS")
print("NO_REV179_PCK_RELEASE_WITHOUT_REAL_ORIGINAL_3D_RUNTIME_AND_NATIVE_QA")
