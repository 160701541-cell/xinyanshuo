#!/usr/bin/env python3
"""Inspect the ACTUAL published signed Android APK (read-only, no signing secrets).

Produces evidence about APK176's embedded Godot pack and the minimum OTA
revision that its real update_mount.gd will accept. Does not claim phone QA.
"""
import hashlib
import json
import re
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path

BASE = "https://160701541-cell.github.io/xinyanshuo/"
OUTPUT = Path("qa-results/apk176-inspection.json")


def require(test, explanation):
    if not test:
        raise ValueError(explanation)


def run():
    apk_meta = json.loads(Path("android-preview/base-latest.json").read_text("utf-8"))
    pck_meta = json.loads(Path("android-preview/latest.json").read_text("utf-8"))
    require(apk_meta.get("schema") == 1, "APK manifest schema is not 1")
    require(pck_meta.get("schema") == 1, "PCK manifest schema is not 1")
    code = apk_meta.get("version_code")
    revision = pck_meta.get("revision")
    require(type(code) is int and code >= 1000, "Android code invalid")
    require(type(revision) is int and revision > 0, "PCK revision invalid")
    min_patch = max(code - 1000, revision) + 1
    require(min_patch > revision, "nonmonotonic patch revision")
    path = apk_meta.get("file", "")
    expected = apk_meta.get("sha256", "")
    expected_size = apk_meta.get("size_bytes")
    require(isinstance(path, str) and re.fullmatch(r"android-preview/base/[A-Za-z0-9_.-]+[.]apk", path), "untrusted APK file path")
    require(isinstance(expected, str) and re.fullmatch("[0-9a-f]{64}", expected), "bad advertised APK SHA256")
    require(type(expected_size) is int and 10_000_000 <= expected_size <= 200_000_000, "unrealistic APK size")
    result = {
        "apk_code": code,
        "apk_version": apk_meta["version_name"],
        "public_revision": revision,
        "minimum_acceptable_next_pck": min_patch,
        "advertised_apk_sha256": expected,
        "published_apk_verified": False,
        "godot_pack_detected": False,
        "godot_asset_tree_detected": False,
        "godot_payload_detected": False,
        "exported_scripts": {},
        "apk_pack_candidates": [],
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    try:
        with tempfile.TemporaryDirectory() as temp:
            local = Path(temp) / "published.apk"
            req = urllib.request.Request(BASE + path, headers={"User-Agent": "Canglan-CI-APK-Inspector/1"})
            with urllib.request.urlopen(req, timeout=75) as response, local.open("wb") as dest:
                h = hashlib.sha256()
                length = 0
                while chunk := response.read(1024 * 1024):
                    dest.write(chunk)
                    h.update(chunk)
                    length += len(chunk)
                    require(length <= 200_000_000, "remote APK exceeds limit")
            result["actual_size_bytes"] = length
            result["actual_sha256"] = h.hexdigest()
            require(length == expected_size, "signed APK byte length differs from public manifest")
            require(h.hexdigest() == expected, "signed APK sha256 differs from public manifest")
            result["published_apk_verified"] = True
            print("PASS_APK176_BYTES", length, h.hexdigest())
            with zipfile.ZipFile(local) as apk:
                names = apk.namelist()
                result["entry_count"] = len(names)
                result["assets_sample"] = [n for n in names if n.startswith("assets/")][:70]
                result["pack_filename_candidates"] = [n for n in names if n.lower().endswith((".pck", ".obb"))][:20]
                require("AndroidManifest.xml" in names, "not a real Android APK ZIP")
                for info in apk.infolist():
                    if info.is_dir() or not info.filename.startswith("assets/"):
                        continue
                    # Determine if a packed Godot file is embedded in APK assets.
                    if info.file_size < 512 or info.file_size > 200_000_000:
                        continue
                    is_candidate = info.filename.lower().endswith((".pck", ".obb")) or info.filename.lower().endswith("/godot_project")
                    if is_candidate:
                        with apk.open(info) as member:
                            start = member.read(4)
                        result["apk_pack_candidates"].append({
                            "name": info.filename,
                            "size": info.file_size,
                            "signature": start.hex(),
                            "is_godot_gdpc_pack": start == b"GDPC",
                        })
                        if start == b"GDPC":
                            result["godot_pack_detected"] = True
                # Godot 4.4.1 Android's stock exporter packages a LOOSE exported
                # resource tree, not necessarily an inner GDPC .pck. We verified
                # its exact signed APK176 ZIP contents in official runner 38704424271.
                required = (
                    "assets/project.binary",
                    "assets/scripts/build_info.gdc",
                    "assets/scripts/update_mount.gdc",
                    "assets/scripts/update_protocol.gdc",
                    "assets/scripts/touch_look_router.gdc",
                    "assets/scripts/touch_look_router.gd.remap",
                    "lib/arm64-v8a/libgodot_android.so",
                )
                if all(name in names for name in required):
                    result["godot_asset_tree_detected"] = True
                    for name in required:
                        if name.endswith((".gdc", ".gd.remap", "project.binary")):
                            with apk.open(name) as entry:
                                raw = entry.read(2_000_000)
                            require(raw, "exported APK entry empty: " + name)
                            result["exported_scripts"][name] = {
                                "size_bytes": len(raw),
                                "sha256": hashlib.sha256(raw).hexdigest(),
                            }
                    # Godot remaps scripts to the .gdc bytecode in APK. The OTA
                    # publisher must separately prove a mounted res:// .gd wins.
                    with apk.open("assets/scripts/touch_look_router.gd.remap") as entry:
                        remap = entry.read(4096).decode("utf-8", errors="replace")
                    require("touch_look_router.gdc" in remap, "Android compiled script remap target missing")
                    result["touch_router_remap"] = remap.strip()[:350]
                    # Written ONLY into the ephemeral runner's existing QA
                    # fixture. No decoded APK binary is committed or uploaded.
                    target_dir = Path("logic-qa/apk176-export-fixture/scripts")
                    target_dir.mkdir(parents=True, exist_ok=True)
                    for basename in ("touch_look_router.gdc", "touch_look_router.gd.remap"):
                        member_name = "assets/scripts/" + basename
                        member_info = apk.getinfo(member_name)
                        require(0 < member_info.file_size < 2_000_000,
                                "unexpected signed APK compiled script length")
                        (target_dir / basename).write_bytes(apk.read(member_name))
                    result["ephemeral_apk176_bytecode_fixture"] = True
                result["godot_payload_detected"] = bool(
                    result["godot_pack_detected"] or result["godot_asset_tree_detected"]
                )
                if not result["godot_payload_detected"]:
                    print("APK_CONTROL_AND_BOOTSTRAP_ENTRIES", json.dumps(
                        [n for n in names if any(term in n.lower() for term in
                        ("touch_look", "build_info", "update_mount", "update_protocol",
                         "project.binary", "androidmanifest"))], ensure_ascii=False))
                    raise ValueError("APK176 Godot resource layout unresolved; release blocked")
                print("PASS_APK176_EXPORTED_GODOT_CONTENT", 
                      "loose_compiled_assets" if result["godot_asset_tree_detected"] else "embedded_PCK")
    finally:
        OUTPUT.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", "utf-8")
        print("RELEASE_RULE:", "signed PCK revision must be >=", min_patch)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(run())
    except Exception as e:
        print("BLOCKED_APK176_INTEROP:", type(e).__name__, str(e))
        sys.exit(2)
