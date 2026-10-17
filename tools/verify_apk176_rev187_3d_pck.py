#!/usr/bin/env python3
"""Audit original APK176 preview PCK: exact resource paths and real GLB payloads.

This is a structural/integrity gate, not a substitute for native Godot runtime
checks or Android device acceptance.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import struct
import sys

REQUIRED = {
    "scenes/main.tscn.remap",
    "scenes/main_original_quality_rev187.tscn",
    "scripts/apk176_living_resource_world_rev187.gd",
    "scripts/hd2d_original_overlay_ota177.gd",
    "scripts/hd2d_house_portal.gd",
    "canglan_rev187/worldbox_life_sim.gd",
    "canglan_rev187/ecology_growth.gd",
    "canglan_rev187/visual_palette.gd",
    "canglan_rev187/kenney_multimesh.gd",
    "canglan_rev187/strata_terrain.gd",
    "canglan_rev187/vivid_material.gd",
    "canglan_rev187/player_controller.gd",
    "canglan_rev187/backpack.gd",
    "canglan_rev187/root_taxonomy.gd",
    "canglan_rev187/city_population.gd",
    "canglan_rev187/quality_profiles.gd",
    "canglan_rev187/Textures/colormap.png",
    "Textures/colormap.png",
}
BASE_DIR = Path(__file__).resolve().parents[1]
EXPECTED_MODELS = {
    "canglan_rev187/tree_oak.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/kenney/3d/nature/tree_oak.glb",
    "canglan_rev187/rocks_small.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/kenney/3d/castle/rocks-small.glb",
    "canglan_rev187/tree_log.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/kenney/3d/castle/tree-log.glb",
    "canglan_rev187/wood_fence.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/kenney/3d/castle/wall-narrow-wood-fence.glb",
    "canglan_rev187/stone_steps.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/kenney/3d/castle/stairs-stone.glb",
    "canglan_rev187/wood_door.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/kenney/3d/castle/door.glb",
    "canglan_rev187/animated_knight.glb": BASE_DIR / "game-source/godot3d/assets/free_cc0/quaternius_knight/public/models/knight.glb",
}
REQUIRED.update(EXPECTED_MODELS)
# rev205 real open-source vectors must exactly match repository originals
# and be bundled with complete ISC/MIT licensing (not remote CDN UI).
UI_SOURCE = BASE_DIR / "game-source/apk176-ota177-candidate/ui/lucide"
UI_ICONS = ("backpack","swords","crosshair","pickaxe","shield",
            "book-open","house","compass","eye","move-3d","leaf","menu","zap")
REQUIRED.update("canglan_rev187/ui/lucide/" + name + ".svg" for name in UI_ICONS)
REQUIRED.add("canglan_rev187/ui/lucide/LICENSE")
# Source-verified original GLBs from Quaternius CC0 (no procedural meshes)
ASSET_ROOT = BASE_DIR / "game-source/apk176-ota177-candidate/assets/cc0-rev206"
CC0_PROOF = json.loads((ASSET_ROOT / "asset_intake_proof.json").read_text())
assert CC0_PROOF["asset_total"] == 14 and CC0_PROOF["committed_under_license"] == "CC0-1.0"
CC0_MODELS = {}
for item in CC0_PROOF["models"]:
    key = "canglan_rev187/cc0_rev206/" + item["role"] + "/" + item["name"] + ".glb"
    CC0_MODELS[key] = (BASE_DIR / item["path"], item["sha256"])
REQUIRED.update(CC0_MODELS)
# Nine 512px source-verified original Quaternius CC0 albedo/normal/ORM maps:
# a missing, corrupted or substituted white flat map is a HARD release fail.
PBR_ROOT = BASE_DIR / "game-source/apk176-ota177-candidate/materials/rev207"
PBR_PROOF = json.loads((PBR_ROOT / "manifest.json").read_text())
assert PBR_PROOF["schema"] == 207 and PBR_PROOF["count"] == 9
assert PBR_PROOF["size"] == 512 and PBR_PROOF["license"] == "CC0-1.0"
REAL_PBR = {
    "canglan_rev187/materials_rev207/" + item["file"]: (PBR_ROOT / item["file"], item["output_sha256"])
    for item in PBR_PROOF["maps"]
}
assert len(REAL_PBR) == 9
REQUIRED.update(REAL_PBR)
REQUIRED.add("canglan_rev187/materials_rev207/manifest.json")





def audit(path: Path) -> dict:
    raw = path.read_bytes()
    if len(raw) < 512 or raw[:4] != b"GDPC":
        raise ValueError("BLOCKED: candidate is not a real Godot PCK")
    fmt, major, minor, patch, flags = struct.unpack_from("<IIIII", raw, 4)
    if (fmt, major, minor) != (2, 4, 4) or flags != 0:
        raise ValueError("BLOCKED: incompatible or flagged Godot PCK")
    file_base = struct.unpack_from("<Q", raw, 0x18)[0]
    count = struct.unpack_from("<I", raw, 0x60)[0]
    if not (0x68 <= file_base <= len(raw) and 7 <= count <= 140):
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
    for filename in (*[name + ".svg" for name in UI_ICONS], "LICENSE"):
        target = "canglan_rev187/ui/lucide/" + filename
        assert found[target] == (UI_SOURCE / filename).read_bytes(), (
            "BLOCKED: non-source or missing licensed UI vector " + filename)
    for model_path, (source, expected_sha256) in CC0_MODELS.items():
        packed = found[model_path]
        assert packed[:4] == b"glTF"
        assert len(packed) >= 20 and struct.unpack_from("<I", packed, 8)[0] == len(packed)
        assert hashlib.sha256(packed).hexdigest() == expected_sha256, (
            "BLOCKED: Altered original Quaternius CC0 model: " + model_path)
        assert packed == source.read_bytes(), (
            "BLOCKED: Original model packed with changed content: " + model_path)
    assert json.loads(found["canglan_rev187/materials_rev207/manifest.json"]) == PBR_PROOF, (
        "BLOCKED: signed PCK PBR license/texture provenance mismatch")
    for rel, (actual_source, sha256) in REAL_PBR.items():
        raw_texture = found[rel]
        assert raw_texture.startswith(bytes.fromhex("89504e470d0a1a0a")), (
            "BLOCKED: not real source-derived PNG "+rel)
        assert hashlib.sha256(raw_texture).hexdigest()==sha256
        assert raw_texture==actual_source.read_bytes(), (
            "BLOCKED: PBR texture not from licensed artist "+rel)
    palette = found["canglan_rev187/Textures/colormap.png"]
    if palette[:8] != bytes.fromhex("89504e470d0a1a0a") or len(palette) < 128:
        raise ValueError("BLOCKED: official Kenney external palette is missing or corrupt")
    if found["Textures/colormap.png"] != palette:
        raise ValueError("BLOCKED: legacy and GLB-relative Kenney palettes differ")
    scene = found["scenes/main_original_quality_rev187.tscn"]
    if (b"apk176_living_resource_world_rev187.gd" not in scene
            or b"export-3ad5c15c4f3250da0cc7c1af1770d85f-main.scn" not in scene):
        raise ValueError("BLOCKED: original compiled APK176 scene not inherited")
    if b"main_original_quality_rev187.tscn" not in found["scenes/main.tscn.remap"]:
        raise ValueError("BLOCKED: original APK entrypoint not pointed at 3D preview")
    if (b"gather_to_actor" not in found["canglan_rev187/worldbox_life_sim.gd"] or
            b"deliver_carried" not in found["canglan_rev187/worldbox_life_sim.gd"]):
        raise ValueError("BLOCKED: actual finite resource transport backend missing")
    return {"resource_count": len(found), "real_verified_cc0_glb_count": len(EXPECTED_MODELS),
            "size_bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest(),
            "original_compiled_main_preserved": True}


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: verify_apk176_rev187_3d_pck.py unsigned.pck")
    report = audit(Path(sys.argv[1]))
    print("PASS_APK176_REV187_SEVEN_LICENSED_GLB_SOURCE_AND_ORIGINAL_MAIN_PCK", report)


if __name__ == "__main__":
    main()
