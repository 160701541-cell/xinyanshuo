#!/usr/bin/env python3
"""Read-only static audit for user-owned Android WorldBox APK and loader ZIP.

Nothing is patched, signed, installed or re-shared by this tool.
"""
import argparse, hashlib, io, json, zipfile
from pathlib import Path

def digest(path):
    h=hashlib.sha256()
    with Path(path).open("rb") as f:
        for b in iter(lambda: f.read(1<<20),b""):h.update(b)
    return h.hexdigest()

def audit(apk,loader):
    with zipfile.ZipFile(apk) as z:
        names=set(z.namelist())
        inner="assets/Mono/Managed.zip" in names
        dll=False
        if inner:
            with zipfile.ZipFile(io.BytesIO(z.read("assets/Mono/Managed.zip"))) as mz:
                dll=any(x.lower().endswith("assembly-csharp.dll") for x in mz.namelist())
        native=[n for n in names if n.startswith("lib/") and n.endswith(".so")]
        features={
            "mono_runtime_present":any(x.endswith("libmonosgen-2.0.so") for x in native),
            "il2cpp_runtime_present":any(x.endswith("libil2cpp.so") for x in native),
            "managed_archive_present":inner,
            "assembly_csharp_in_managed_archive":dll,
            "nml_bootstrap_in_apk_confirmed":False}
    with zipfile.ZipFile(loader) as z:
        files=[n for n in z.namelist() if not n.endswith("/")]
        nms={Path(n).name.lower() for n in files}
        mobile="neomodloader_mobile.dll" in nms
        generic="neomodloader.dll" in nms
    blockers=[]
    if not features["mono_runtime_present"]:blockers.append("No mono runtime evidence")
    if not dll:blockers.append("No managed Assembly-CSharp.dll evidence")
    if not mobile:blockers.append("The supplied loader ZIP lacks an Android neomodloader_mobile.dll")
    blockers.append("No device proof of injected bootstrap, NML load or the observer mod")
    return {
       "project":"WORLDBOX_THIRD_PARTY_MOD_DERIVATIVE_TEST",
       "status":"DEVICE_PENDING","apk_file":apk.name,"apk_sha256":digest(apk),
       "loader_file":loader.name,"loader_sha256":digest(loader),
       "apk_static_features":features,"loader_entries":files,
       "neomodloader_dll_present":generic,"neomodloader_mobile_dll_present":mobile,
       "android_loader_verified":False,"game_runtime_verified":False,
       "blockers":blockers}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--apk",type=Path,required=True)
    p.add_argument("--loader",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    a=p.parse_args()
    result=audit(a.apk,a.loader)
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
    print("APK audit:",result["status"],"mobile_loader_present:",result["neomodloader_mobile_dll_present"])
if __name__=="__main__":main()
