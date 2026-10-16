#!/usr/bin/env python3
"""CAC-3D-001 source gate: only verifiable PUBLIC 3D runtime and permissive assets.

Do not confuse source contracts with Godot execution, art review or original OTA.
"""
import argparse, json, pathlib, re, sys
REQUIRED = [
    "project.godot", "scenes/main.tscn", "scripts/world_main.gd",
    "scripts/world_rules.gd", "scripts/terrain_chunk.gd",
    "scripts/building_factory.gd", "scripts/prop_factory.gd",
    "scripts/world_state.gd", "scripts/entity_codes.gd",
    "scripts/world_state_bridge.gd", "scripts/terrain/heightfield.gd",
    "scripts/npc_agent.gd", "scripts/interior_factory.gd",
    "tests/world_smoke.gd", "tools/quality_gate.sh",
    "LICENSE", "opensource/THIRD_PARTY_NOTICES.md",
    "opensource/registry.json",
]
REQUIRED_CONTRACTS = {
    "scripts/world_main.gd": ["StreamingTerrain", "Actual3DSettlements", "Civilians", "OriginalWorldState",
        "IndependentWorldProps", "move_and_slide()", "get_world_3d()", "snapshot()"],
    "scripts/world_rules.gd": ["FastNoiseLite", "OriginalTerrainField", "height_at", "biome_at"],
    "scripts/world_state.gd": ["class_name WorldState", "serialize()", "restore(", "create_actor("],
    "scripts/world_state_bridge.gd": ["sync_actor", "actor_public_code"],
    "scripts/terrain_chunk.gd": ["SurfaceTool", "StaticBody3D", "create_trimesh_shape"],
    "scripts/building_factory.gd": ["ArrayMesh", "DoorHinge", "WallsCollision", "entity_id"],
    "scripts/prop_factory.gd": ["MultiMeshInstance3D", "MultiMesh", "entity_id"],
    "scripts/npc_agent.gd": ["entity_id", "profession", "wake_near_player"],
    "scripts/interior_factory.gd": ["building_id", "IndependentFurniture"],
}
BANNED = (
    "SILICONFLOW_API_KEY", "GITHUB_TOKEN=", "BEGIN PRIVATE KEY",
    "android-preview/latest.json", "HD2DInGameVillage", "hd2d_original_overlay",
    "assets/worldx", "assetcloud.example", "webhook_secret"
)
RUNTIME_ALLOW = {"MIT", "Apache-2.0", "BSD-3-Clause", "BSD-2-Clause", "CC0-1.0", "ISC"}

def verify(root: pathlib.Path):
    game = (root / "game-source/godot3d").resolve()
    if not game.is_relative_to(root.resolve()):
        raise AssertionError("Project escape")
    for relative in REQUIRED:
        p = game / relative
        assert p.is_file() and p.stat().st_size>0, f"missing 3D asset/source: {relative}"
        assert p.resolve().is_relative_to(game), f"symlink escape: {relative}"
    assert 'run/main_scene="res://scenes/main.tscn"' in (game/"project.godot").read_text(), "Bad main scene"
    for relative, needles in REQUIRED_CONTRACTS.items():
        text = (game / relative).read_text(encoding="utf-8")
        for needle in needles:
            assert needle in text, f"{relative}: missing {needle}"
        for token in BANNED:
            assert token not in text, f"{relative}: BANNED private/HD2D dependency"
    inventory = json.loads((game / "opensource/registry.json").read_text(encoding="utf-8"))
    assert inventory.get("policy") == "CAC-3D-001"
    ids = set()
    for item in inventory["entries"]:
        ident = item["id"]
        assert ident not in ids, f"Duplicated OSS id: {ident}"
        ids.add(ident)
        assert item["source"].startswith("https://"), ident
        assert item["license_url"].startswith("https://"), ident
        status = item["status"]
        if status == "ACTIVE":
            assert item["license"] in RUNTIME_ALLOW, "Unvetted runtime license"
            assert item["used_by"] and all((game / p).is_file() for p in item["used_by"])
            assert item["kind"] not in ("downloaded-model","downloaded-material"), "Asset bytes not SHA-pinned"
        elif status == "CANDIDATE_NOT_IMPORTED":
            assert not item.get("used_by"), "Candidate falsely marked used"
        else:
            raise AssertionError("Invalid third party state")
    assert {"godot", "fastnoiselite"}.issubset(ids)
    # Byte-level evidence: these three modules were copied verbatim from
    # private ORIGINAL Godot3D history only after secret audit.
    original_blobs = {
        "scripts/world_state.gd":"f7174a7b59370deb456906d8bf8457c9d13fb52d",
        "scripts/entity_codes.gd":"7d82d7de396208c799d4e5bac23741d1d436a71e",
        "scripts/terrain/heightfield.gd":"7c950e459af84c57557abdb31b7b4f23266e7347",
    }
    import hashlib
    for path,expected in original_blobs.items():
        data=(game/path).read_bytes()
        git_blob=b"blob "+str(len(data)).encode()+b"\\x00"+data
        assert hashlib.sha1(git_blob).hexdigest()==expected, f"Original compatibility module mutated: {path}"
    return {"status":"PASS_SOURCE_ONLY","policy":"CAC-3D-001",
        "files":len(REQUIRED),"native_components":len(ids),
        "visual_qa":"PENDING","android_test":"PENDING",
        "original_signed_game_updated":False}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--root",type=pathlib.Path,default=pathlib.Path("."))
    args=p.parse_args()
    try:
        print(json.dumps(verify(args.root),ensure_ascii=False))
        return 0
    except (AssertionError,ValueError,KeyError,OSError,json.JSONDecodeError) as exc:
        print(json.dumps({"status":"BLOCKED","error":str(exc)},ensure_ascii=False))
        return 2

if __name__=="__main__":
    sys.exit(main())
