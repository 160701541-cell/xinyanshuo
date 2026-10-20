#!/usr/bin/env python3
"""Private, read-only Android loader evidence audit for a user-owned WorldBox APK.
Checks *static* binary/ZIP presence only. Does not patch, sign, install, reverse
payments/entitlement checks or publish any commercial game text or binary.
"""
from __future__ import annotations
import argparse
import hashlib
import io
import json
import zipfile
from pathlib import Path

BOOTSTRAP = ("neomodloader", "melonloader", "lemonloader", "fusioncore", "godforge")
DEX_LIMIT = 30_000_000
MANAGED_ZIP_LIMIT = 70_000_000

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024*1024), b""):
            h.update(block)
    return h.hexdigest()

def audit(apk: Path, loader: Path) -> dict:
    if not zipfile.is_zipfile(apk) or not zipfile.is_zipfile(loader):
        raise ValueError("输入必须是有效的用户私有APK及加载器ZIP")
    with zipfile.ZipFile(apk) as z:
        paths = set(z.namelist())
        mono = "lib/arm64-v8a/libmonosgen-2.0.so" in paths
        il2cpp = "lib/arm64-v8a/libil2cpp.so" in paths
        managed_path = "assets/Mono/Managed.zip"
        embedded_names = []
        if managed_path in paths:
            info = z.getinfo(managed_path)
            if info.file_size > MANAGED_ZIP_LIMIT:
                raise ValueError("Mono托管程序集归档超过私有静态分析限制")
            with zipfile.ZipFile(io.BytesIO(z.read(info))) as managed:
                embedded_names = [
                    item.filename for item in managed.infolist()
                    if not item.is_dir() and not item.filename.startswith("__MACOSX/")
                ]
        managed_lower = {Path(name).name.lower() for name in embedded_names}
        dex_files = sorted(n for n in paths if n.startswith("classes") and n.endswith(".dex"))
        dex_markers = {}
        for label in BOOTSTRAP:
            needle = label.encode("ascii")
            present = False
            for name in dex_files:
                info = z.getinfo(name)
                if info.file_size > DEX_LIMIT:
                    raise ValueError("DEX文件过大，拒绝无界读取")
                if needle in z.read(info).lower():
                    present = True
                    break
            dex_markers[label] = present
        apk_entry_hints = sorted(
            p for p in paths if
            any(k in Path(p).name.lower() for k in BOOTSTRAP)
        )[:30]
    with zipfile.ZipFile(loader) as z:
        entries = [n for n in z.namelist() if not n.endswith("/")]
        names = {Path(n).name.lower() for n in entries}
        generic = "neomodloader.dll" in names
        mobile = "neomodloader_mobile.dll" in names
        desktop_instructions = False
        for n in entries:
            if n.lower().endswith(".txt") and z.getinfo(n).file_size < 128000:
                raw = z.read(n).lower()
                if b"worldbox_data/streamingassets" in raw:
                    desktop_instructions = True
    markers_found = any(dex_markers.values()) or bool(apk_entry_hints) or any(
        any(needle in name for needle in BOOTSTRAP) for name in managed_lower
    )
    return {
        "scope": "WORLDBOX_THIRD_PARTY_MOD_DERIVATIVE_TEST",
        "apk_sha256": sha256(apk),
        "loader_zip_sha256": sha256(loader),
        "read_only": True,
        "commercial_apk_repacked": False,
        "device_installed_or_passed": False,
        "apk_static": {
            "mono_arm64_present": mono,
            "il2cpp_arm64_present": il2cpp,
            "managed_archive_present": managed_path in paths,
            "managed_csharp_present": "assembly-csharp.dll" in managed_lower,
            "managed_loader_dll_present": any(
                any(k in n for k in BOOTSTRAP) for n in managed_lower
            ),
            "bootstrap_named_apk_entries": apk_entry_hints,
            "dex_loader_name_markers": dex_markers,
            "has_any_static_named_bootstrap_hint": markers_found,
        },
        "supplied_loader": {
            "desktop_neomodloader_dll": generic,
            "mobile_neomodloader_dll": mobile,
            "desktop_install_instructions": desktop_instructions,
        },
        "compatible_runtime_proven": False,
        "decision": (
            "原版APK中即使存在Mono/IL2CPP，也不能当作安卓MOD引导已运行。"
            "所给加载器若只有桌面NeoModLoader.dll，不能代替新版NeoModLoader_mobile.dll。"
            "后续必须先获取用户手机的真实运行日志或可信的加载器安装验证，"
            "再选择对应的传统Mono源码版或LemonLoader移动NML预编译版。"
            "静态名称命中不构成已加载、已汉化或可安装APK的证明。"
        ),
        "device_qa": "BLOCKED_NO_DEVICE_LOADER_EVIDENCE",
    }

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--apk", required=True, type=Path)
    p.add_argument("--loader", required=True, type=Path)
    p.add_argument("--out", required=True, type=Path)
    a = p.parse_args()
    result = audit(a.apk, a.loader)
    a.out.parent.mkdir(parents=True, exist_ok=True)
    a.out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("PRIVATE_APK_READ_ONLY", result["device_qa"])

if __name__ == "__main__":
    main()
