#!/usr/bin/env python3
"""Privately stage OWN Mono MOD source into a user-supplied already bootstrapped APK.

Does not inject a loader, patch game code, change purchases/saves, or sign APKs.
The returned APK is UNSIGNED; sign privately and verify on a real device.
Never upload the game APK, signing keys or foreign MOD binaries to public GitHub.
"""
import argparse, hashlib, io, json, os, posixpath, re, zipfile
from pathlib import Path

ROOT="assets/worldbox-xianxia/v18/"
MANIFEST=ROOT+"install.json"
MOD="Mods/WorldBoxXianxiaObserver/"
BRIDGE="WorldBoxXianxiaMonoBridge.dll"

def sha(data):
    return hashlib.sha256(data).hexdigest()

def path_ok(name):
    if not isinstance(name,str) or len(name)>240 or "\\" in name or name.startswith("/") or name.endswith("/"):
        return False
    if any(piece in ("",".","..") for piece in name.split("/")) or posixpath.normpath(name)!=name:
        return False
    return name.startswith(MOD) and Path(name).suffix.lower() in (".cs",".json",".txt")

def preflight_base(apk):
    present=set(apk.namelist())
    if not {MANIFEST,"classes5.dex","assets/Mono/Managed.zip"}.issubset(present):
        raise ValueError("not a verified previously loader-integrated user APK")
    with zipfile.ZipFile(io.BytesIO(apk.read("assets/Mono/Managed.zip"))) as m:
        if BRIDGE not in m.namelist() or "Assembly-CSharp.dll" not in m.namelist():
            raise ValueError("no existing user-owned Mono bridge; cannot stage inert assets")
    manifest=json.loads(apk.read(MANIFEST))
    entries=manifest.get("files")
    if not isinstance(entries,list) or not 1<=len(entries)<=2000 or not manifest.get("build_token"):
        raise ValueError("invalid original deployment manifest")
    targets=set()
    for entry in entries:
        t=entry.get("target")
        if not isinstance(t,str) or ".." in t.split("/") or t.startswith("/") or t in targets:
            raise ValueError("bad or duplicated base target")
        targets.add(t)
        if ROOT+t not in present or apk.getinfo(ROOT+t).file_size!=entry.get("size"):
            raise ValueError("missing or mismatched original deployment asset: "+t)
    return manifest

def preflight_mod(mod_zip):
    data={}
    for member in mod_zip.infolist():
        if member.is_dir() or member.filename in ("SHA256SUMS.txt","README_传统Mono安装前必读.txt"):
            continue
        if not path_ok(member.filename):
            raise ValueError("unsafe or unexpected source-only MOD path")
        if member.filename in data or len(data)>=120 or member.file_size>500000:
            raise ValueError("repeated or oversized module entry")
        if ((member.external_attr>>16)&0o170000)==0o120000:
            raise ValueError("no archive symlinks")
        data[member.filename]=mod_zip.read(member)
    if sum(map(len,data.values()))>4000000:
        raise ValueError("module source quota exceeded")
    if MOD+"mod.json" not in data or MOD+"Code/XianxiaObserverV07.cs" not in data:
        raise ValueError("not a complete Mono module")
    meta=json.loads(data[MOD+"mod.json"])
    if meta.get("GUID")!="XINYANSHUO_WORLD_BOX_OBSERVER_V07" or meta.get("ModType")!=0:
        raise ValueError("wrong loader format or MOD identity")
    if not re.fullmatch(r"0\.27\.[\w.-]+",str(meta.get("version",""))):
        raise ValueError("only tested v0.27 candidate accepted")
    return data

def stage(base_apk, mono_zip, output, replace_own_module=False):
    base_apk,mono_zip,output=map(Path,(base_apk,mono_zip,output))
    if output.resolve() in (base_apk.resolve(),mono_zip.resolve()):
        raise ValueError("never overwrite original")
    with zipfile.ZipFile(mono_zip) as mod:
        files=preflight_mod(mod)
    with zipfile.ZipFile(base_apk) as apk:
        old=preflight_base(apk)
        existing={entry["target"] for entry in old["files"] if entry["target"].startswith(MOD)}
        archived={name[len(ROOT):] for name in apk.namelist() if name.startswith(ROOT+MOD)}
        if existing!=archived:
            raise ValueError("own module assets differ from deployment manifest")
        if existing and not replace_own_module:
            raise ValueError("already contains this mod; no silent replacement")
        # Replacement is limited to this module's deployment assets. Never
        # rewrite foreign MODs, Managed.zip, DEX, package identity or user saves.
        for entry in old["files"]:
            target=entry["target"]
            digest=entry.get("sha256")
            if not isinstance(digest,str) or not re.fullmatch(r"[0-9a-f]{64}",digest):
                raise ValueError("missing valid base asset checksum: "+target)
            if sha(apk.read(ROOT+target))!=digest:
                raise ValueError("base deployment checksum mismatch: "+target)
        retained=[entry for entry in old["files"] if entry["target"] not in existing]
        manifest=dict(old)
        manifest["build_token"]="v28-zh-"+sha(mono_zip.read_bytes())[:18]
        manifest["device_test"]="DEVICE_PENDING"
        manifest["mods"]=list(dict.fromkeys([*old.get("mods",[]),"WorldBoxXianxiaObserver 0.27"]))
        manifest["files"]=[*retained,*(
            {"target":name,"size":len(blob),"sha256":sha(blob)}
            for name,blob in sorted(files.items())
        )]
        manifest_bytes=(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n").encode()
        output.parent.mkdir(parents=True,exist_ok=True)
        partial=Path(str(output)+".partial")
        try:
            with zipfile.ZipFile(partial,"w",allowZip64=True) as out:
                out.comment=apk.comment
                for entry in apk.infolist():
                    if entry.filename.startswith(ROOT) and entry.filename[len(ROOT):] in existing:
                        continue
                    if entry.filename.startswith("META-INF/") and entry.filename.upper().endswith(
                        (".RSA",".DSA",".EC",".SF","MANIFEST.MF")):
                        continue  # original signature invalidated by private modification
                    blob=manifest_bytes if entry.filename==MANIFEST else apk.read(entry)
                    out.writestr(entry,blob,compress_type=entry.compress_type)
                for name,blob in sorted(files.items()):
                    out.writestr(ROOT+name,blob,compress_type=zipfile.ZIP_DEFLATED)
            with zipfile.ZipFile(partial) as out:
                if out.testzip()!=None:raise ValueError("staged ZIP CRC failed")
                actual=json.loads(out.read(MANIFEST))
                if actual["build_token"]==old["build_token"]:raise ValueError("cache not invalidated")
                names=out.namelist()
                if len(names)!=len(set(names)):raise ValueError("duplicate archive entry")
                for record in actual["files"]:
                    blob=out.read(ROOT+record["target"])
                    if len(blob)!=record["size"] or sha(blob)!=record["sha256"]:
                        raise ValueError("payload corrupted: "+record["target"])
            os.replace(partial,output)
        finally:
            if partial.exists():partial.unlink()
    return {"status":"UNSIGNED_STAGED_DEVICE_PENDING",
            "original_apk_untouched":True,
            "existing_mono_bridge_reused":True,
            "source_files_added":len(files),
            "own_module_files_replaced":len(existing),
            "foreign_deployment_files_retained":len(retained),
            "deployment_records":len(manifest["files"]),
            "build_token":manifest["build_token"],
            "worldbox_device_loaded":False,
            "android_installed":False,
            "signing_required":True}

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--base-apk",type=Path,required=True)
    p.add_argument("--mono-zip",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--replace-own-module",action="store_true",
                   help="Explicitly replace only existing WorldBoxXianxiaObserver deployment assets")
    args=p.parse_args()
    print(json.dumps(stage(args.base_apk,args.mono_zip,args.out,args.replace_own_module),ensure_ascii=False,indent=2))
