#!/usr/bin/env python3
"""Audit original APK176 preview PCK: exact resource paths and real GLB payloads.

This is a structural/integrity gate, not a substitute for native Godot runtime
checks or Android device acceptance.
"""
from __future__ import annotations
import hashlib
from pathlib import Path
import struct
import sys

REQUIRED = {
    "scenes/main.tscn.remap",
    "scenes/main_original_visual_rev183.tscn",
    "scripts/apk176_living_resource_world_rev183.gd",
    "scripts/hd2d_original_overlay_ota177.gd",
    "scripts/hd2d_house_portal.gd",
    "canglan_rev183/worldbox_life_sim.gd",
    "canglan_rev183/ecology_growth.gd",
    "canglan_rev183/visual_palette.gd",
    "canglan_rev183/kenney_multimesh.gd",
    "Textures/colormap.png",
}
BASE_DIR = Path(__file__).resolve().parents[1]
EXPECTED_MODELS = {
    "canglan_rev183/tree_oak.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/kenney/3d/nature/tree_oak.glb",
    "canglan_rev183/rocks_small.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/kenney/3d/castle/rocks-small.glb",
    "canglan_rev183/tree_log.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/kenney/3d/castle/tree-log.glb",
    "canglan_rev183/wood_fence.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/kenney/3d/castle/wall-narrow-wood-fence.glb",
    "canglan_rev183/stone_steps.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/kenney/3d/castle/stairs-stone.glb",
    "canglan_rev183/wood_door.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/kenney/3d/castle/door.glb",
    "canglan_rev183/animated_knight.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/quaternius_knight/public/models/knight.glb",
}
REQUIRED.update(EXPECTED_MODELS)



def audit(path: Path) -> dict:
    raw = path.read_bytes()
    if len(raw) < 512 or raw[:4] != b"GDPC":
        raise ValueError("BLOCKED: candidate is not a real Godot PCK")
    fmt, major, minor, patch, flags = struct.unpack_from("<IIIII", raw, 4)
    if (fmt, major, minor) != (2, 4, 4) or flags != 0:
        raise ValueError("BLOCKED: incompatible or flagged Godot PCK")
    file_base = struct.unpack_from("<Q", raw, 0x18)[0]
    count = struct.unpack_from("<I", raw, 0x60)[0]
    if not (0x68 <= file_base <= len(raw) and 7 <= count <= 80):
        raise ValueError("BLOCKED: invalid PCK file table")
    offset = 0x64
    found: dict[str, bytes] = {}
    for _ in range(count):
        if offset + 4 > file_base:
            raise ValueError("BLOCKED: truncated PCK entry")
        length = struct.unpack_from("<I", raw, offset)[0]
        offset += 4
        if not (1 <= length <= 1024 and offset + length + 36 <= file_base):
            raise ValueError("BLOCKED: invalid resource pathname")
        name = raw[offset:offset + length].split(b"\x00", 1)[0].decode("utf-8")
        offset += length
        start, size = struct.unpack_from("<QQ", raw, offset)
        offset += 16
        md5 = raw[offset:offset + 16]
        offset += 16
        entry_flags = struct.unpack_from("<I", raw, offset)[0]
        offset += 4
        if name.startswith("/") or "\\" in name or ".." in Path(name).parts or name in found:
            raise ValueError("BLOCKED: unsafe/duplicate PCK path")
        if entry_flags != 0 or not (0 < size <= 95 * 1024 * 1024) or start + size > len(raw) - file_base:
            raise ValueError("BLOCKED: unexpected/invalid PCK entry")
        data = raw[file_base + start:file_base + start + size]
        if hashlib.md5(data).digest() != md5:
            raise ValueError("BLOCKED: corrupted PCK resource " + name)
        found[name] = data
    if not REQUIRED.issubset(found):
        raise ValueError("BLOCKED: missing original-game/3D resources " + str(REQUIRED - found.keys()))
    if offset > file_base:
        raise ValueError("BLOCKED: PCK index overflow")
    for model_path, source in EXPECTED_MODELS.items():
        value = found[model_path]
        if value[:4] != b"glTF" or len(value) < 100:
            raise ValueError("BLOCKED: asset is not a binary GLB: " + model_path)
        version, glb_length = struct.unpack_from("<II", value, 4)
        if version != 2 or glb_length != len(value):
            raise ValueError("BLOCKED: corrupted GLB header " + model_path)
        if hashlib.sha256(value).hexdigest() != hashlib.sha256(source.read_bytes()).hexdigest():
            raise ValueError("BLOCKED: altered/non-licensed staged model " + model_path)
    palette = found["Textures/colormap.png"]
    if palette[:8] != bytes.fromhex("89504e470d0a1a0a") or len(palette) < 128:
        raise ValueError("BLOCKED: official Kenney external palette is missing or corrupt")
    scene = found["scenes/main_original_visual_rev183.tscn"]
    if (b"apk176_living_resource_world_rev183.gd" not in scene
            or b"export-3ad5c15c4f3250da0cc7c1af1770d85f-main.scn" not in scene):
        raise ValueError("BLOCKED: original compiled APK176 scene not inherited")
    if b"main_original_visual_rev183.tscn" not in found["scenes/main.tscn.remap"]:
        raise ValueError("BLOCKED: original APK entrypoint not pointed at 3D preview")
    if (b"gather_to_actor" not in found["canglan_rev183/worldbox_life_sim.gd"] or
            b"deliver_carried" not in found["canglan_rev183/worldbox_life_sim.gd"]):
        raise ValueError("BLOCKED: actual finite resource transport backend missing")
    return {"resource_count": len(found), "real_verified_cc0_glb_count": len(EXPECTED_MODELS),
            "size_bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest(),
            "original_compiled_main_preserved": True}


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: verify_apk176_rev183_3d_pck.py unsigned.pck")
    report = audit(Path(sys.argv[1]))
    print("PASS_APK176_REV183_SEVEN_LICENSED_GLB_SOURCE_AND_ORIGINAL_MAIN_PCK", report)


if __name__ == "__main__":
    main()
