#!/usr/bin/env python3
"""Repackage an original, genuinely SDK-built WorldBox observer DLL for Android NML.

Only the caller's ORIGINAL observer DLL is bundled; NEVER WorldBox APK, mobile
NML loader, commercial assets, third-party mod DLLs or another game's files.
"""
import argparse
import hashlib
import json
import struct
import zipfile
from pathlib import Path

ROOT = "NMLMods/WorldBoxXianxiaObserver"
UID = "XINYANSHUO_WORLD_BOX_OBSERVER_V07"
REQUIRED_MODTYPE = 1
MAX_BYTES = 5_000_000
NOTICE = ("非官方WorldBox安卓MOD衍生实验；与《苍岚·人生世界》的游戏开发、发布和热更新完全无关。\n"
          "本包不是APK；必须已有兼容的Android NeoModLoader启动链。DEVICE_PENDING：未在用户0.51.4手机实机验收。\n"
          "将NMLMods中的WorldBoxXianxiaObserver整个文件夹放到NeoModLoader实际读取的NMLMods目录；"
          "先备份世界存档，不要覆盖原APK，不要混用PC NML DLL。\n"
          "预编译模块自动被NML识别为COMPILED_NEOMOD，真正Android载入和UI/存档/性能仍待测试。\n")

def sha(data):
    return hashlib.sha256(data).hexdigest()

def validate_metadata(mod):
    if mod.get("GUID") != UID:
        raise ValueError("unexpected MOD GUID")
    if mod.get("ModType") != REQUIRED_MODTYPE:
        raise ValueError("not a compiled NeoMod: ModType must be 1")
    if mod.get("targetGameBuild") != 725:
        raise ValueError("targetGameBuild does not declare Android 0.51.4 build 725")
    if not all(x in mod for x in ("name", "author", "version", "description")):
        raise ValueError("incomplete NML mod.json")

def pack(dll, mod_path, out):
    mod = json.loads(Path(mod_path).read_text(encoding="utf-8"))
    validate_metadata(mod)
    buf = Path(dll).read_bytes()
    # PE/CLI minimal guards; this is NOT a full verifier and cannot prove in-game load.
    if len(buf) < 2048 or len(buf) > MAX_BYTES or buf[:2] != b"MZ":
        raise ValueError("expected small original managed PE DLL, not empty or an APK")
    pe_pointer = struct.unpack_from("<I", buf, 0x3C)[0]
    if pe_pointer + 4 > len(buf) or buf[pe_pointer:pe_pointer+4] != b"PE\\x00\\x00".replace(b"\\x00", b"\x00"):
        raise ValueError("invalid portable executable header")
    files = {
        ROOT + "/mod.json": (json.dumps(mod, ensure_ascii=False, indent=2)+"\n").encode("utf-8"),
        ROOT + "/" + UID + ".dll": buf,
        "README_INSTALL_DEVICE_PENDING.txt": NOTICE.encode("utf-8"),
    }
    checks = "\n".join(f"{sha(body)}  {name}" for name,body in sorted(files.items())) + "\n"
    files["SHA256SUMS.txt"] = checks.encode("utf-8")
    p=Path(out);p.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(p, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zipf:
        for name,body in sorted(files.items()):
            zipf.writestr(name,body)
    return {"package":str(p),"original_dll_sha256":sha(buf),"packaged_entries":sorted(files),
            "state":"ANDROID_DEVICE_PENDING","compiled_sdk_reference":"REAL_PUBLIC_ANDROID_NML_SDK"}

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--dll",type=Path,required=True)
    ap.add_argument("--manifest",type=Path,required=True)
    ap.add_argument("--out",type=Path,required=True)
    args=ap.parse_args()
    print(json.dumps(pack(args.dll,args.manifest,args.out),ensure_ascii=False,indent=2))

if __name__=="__main__":main()
