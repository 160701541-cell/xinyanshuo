#!/usr/bin/env python3
"""Pin and install real Godot 4 VRM + MToon importers from V-Sekai.
The two addon folders are copied from the same verified repository snapshot.
No user avatar artwork, secrets or account logins are required.
"""
from pathlib import Path
import hashlib, io, os, urllib.request, zipfile
ROOT=Path(__file__).resolve().parent.parent
UPSTREAM="V-Sekai/godot-vrm"
PIN="e15199f980064028bfa4fbee5e70dddb82dd55c3"
BASE=f"https://codeload.github.com/{UPSTREAM}/zip/{PIN}"
WHITELIST=("addons/vrm/","addons/Godot-MToon-Shader/")
MAX_ZIP=18_000_000
OUT=ROOT/"addons"
def fetch_zip():
    request=urllib.request.Request(BASE,headers={"User-Agent":"ZhiYin-VRM-AssetPipeline/0.1"})
    with urllib.request.urlopen(request,timeout=80) as response:
        raw=response.read(MAX_ZIP+1)
    if len(raw)>MAX_ZIP:
        raise ValueError("VRM plugin archive too large")
    return raw
def main():
    raw=fetch_zip()
    digest=hashlib.sha256(raw).hexdigest()
    prefix="godot-vrm-"+PIN+"/"
    total=0
    with zipfile.ZipFile(io.BytesIO(raw)) as z:
        all_paths=set(z.namelist())
        for needed in ["addons/vrm/plugin.cfg","addons/vrm/LICENSE",
                       "addons/Godot-MToon-Shader/plugin.cfg"]:
            if prefix+needed not in all_paths:
                raise ValueError("VRM importer has missing required file: "+needed)
        lic=z.read(prefix+"addons/vrm/LICENSE").decode("utf-8")
        if "MIT License" not in lic:
            raise ValueError("Unverified VRM licensing")
        for item in z.infolist():
            if item.is_dir():
                continue
            relative=item.filename.removeprefix(prefix)
            if not relative.startswith(WHITELIST):
                continue
            p=Path(relative)
            if p.is_absolute() or ".." in p.parts:
                raise ValueError("Dangerous archived path")
            if item.file_size>4_000_000:
                raise ValueError("Unexpected oversized plugin file")
            dest=ROOT/p
            dest.parent.mkdir(parents=True,exist_ok=True)
            dest.write_bytes(z.read(item))
            total+=1
    print("VRM_MTOON_READY",UPSTREAM,PIN,"files",total,"archive_sha256",digest)
    if total<40:
        raise ValueError("VRM plugin snapshot unexpectedly incomplete")
    (ROOT/"VRM_PLUGIN_PROVENANCE.txt").write_text(
        "Source: https://github.com/"+UPSTREAM+"\n"+
        "Pinned commit: "+PIN+"\n"+
        "Zip SHA256: "+digest+"\n"+
        "License: MIT - upstream addon license bundled alongside source\n",
        encoding="utf-8")
if __name__=="__main__":
    main()
