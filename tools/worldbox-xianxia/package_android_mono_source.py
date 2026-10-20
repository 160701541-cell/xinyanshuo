#!/usr/bin/env python3
"""Create user-APK-specific *source-only* NeoModLoader Mono candidate.

The user's own bundle instructions mention:
  Android/data/com.mkarpenko.worldbox/files/mods/NeoModLoader.dll
  Android/data/com.mkarpenko.worldbox/Mods/<mod>/mod.json
This path is NOT the official IL2CPP/LemonLoader NMLMods branch.
No crack, native APK editing or third-party DLL is distributed.
"""
import argparse
import hashlib
import json
import re
import zipfile
from pathlib import Path

ROOT = "Mods/WorldBoxXianxiaObserver"
UID = "XINYANSHUO_WORLD_BOX_OBSERVER_V07"
NOTICE = ("世界盒子 WorldBox 安卓传统Mono NeoModLoader **源码型** MOD测试候选；与《苍岚》原创游戏开发完全无关。\n"
          "此包依据用户提供的改版说明中 Android/data/com.mkarpenko.worldbox/Mods 目录组织；"
          "它并不保证当前手机已成功加载NeoModLoader。\n"
          "先备份世界存档，确认实验模式和NML日志。不要覆盖安装或修改APK、不要把电脑DLL和手机新旧加载方案混用。\n"
          "这里的代码会尝试由已装载的传统NeoModLoader在手机内编译，如报错，请保留完整错误日志。\n"
          "真实Android0.51.4兼容性：DEVICE_PENDING。\n")

def create(source, original_manifest, output, extra_sources=()):
    code=Path(source).read_text(encoding="utf8")
    if "BasicMod<" not in code or "OnModLoad()" not in code or "World.world.GetTile" not in code:
        raise ValueError("incompatible observer source")
    if "HarmonyPatch" in code or "File.Write" in code:
        raise ValueError("no mutating game code in initial mobile probe")
    mod=json.loads(Path(original_manifest).read_text(encoding="utf8"))
    if mod.get("GUID") != UID:raise ValueError("unexpected MOD GUID")
    mod["ModType"]=0
    mod["name"]="万界仙侠·微观观察（传统Mono源码候选）"
    mod["description"]=("WorldBox Android third-party MOD experiment, unrelated to Canglan. "
                        "Traditional MONO source-only NeoModLoader candidate. DEVICE_PENDING.")
    files={
        ROOT+"/Code/XianxiaObserverV07.cs":code.encode("utf8"),
        ROOT+"/mod.json":(json.dumps(mod,ensure_ascii=False,indent=2)+"\n").encode("utf8"),
        "README_传统Mono安装前必读.txt":NOTICE.encode("utf8")
    }
    for extra_path in extra_sources:
        extra_path=Path(extra_path)
        if extra_path.suffix.lower()!=".cs" or not extra_path.name.isascii():
            raise ValueError("unsafe additional source name")
        extra_code=extra_path.read_text(encoding="utf8")
        if "HarmonyPatch" in extra_code or "File.Write" in extra_code:
            raise ValueError("unsafe game save modification in source")
        files[ROOT+"/Code/"+extra_path.name]=extra_code.encode("utf8")
    checks="\n".join(hashlib.sha256(v).hexdigest()+"  "+k for k,v in sorted(files.items()))+"\n"
    files["SHA256SUMS.txt"]=checks.encode("utf8")
    output=Path(output);output.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(output,"w",zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for k,v in sorted(files.items()):z.writestr(k,v)
    return {"status":"DEVICE_PENDING","kind":"SOURCE_MONO","files":len(files),"zip":str(output)}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--source",type=Path,required=True)
    p.add_argument("--manifest",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--extra-source",type=Path,action="append",default=[])
    a=p.parse_args()
    print(json.dumps(create(a.source,a.manifest,a.out,a.extra_source),ensure_ascii=False,indent=2))

if __name__=="__main__":main()
