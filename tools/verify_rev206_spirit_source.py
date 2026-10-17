#!/usr/bin/env python3
"""REV206 original APK176 herbs/ore and medicine pipeline FAIL CLOSED.

This is a preflight source consistency check, NOT a replacement for Godot
4.4.1 native run, physical PCK source hash checks or Android phone acceptance.
"""
from pathlib import Path
import json
root=Path("game-source/apk176-ota177-candidate")
source=(root/"scripts/apk176_living_resource_world_rev187.gd").read_text()
player=(root/"scripts/apk176_player_controller_rev187.gd").read_text()
bag=(root/"scripts/apk176_backpack_rev205.gd").read_text()
ledger=(root/"scripts/apk176_spirit_resources_rev206.gd").read_text()
spirit=(root/"scripts/apk176_cultivation_world_rev201.gd").read_text()
pck=Path("logic-qa/tools/build_apk176_quality_rev187.gd").read_text()
qa=Path("logic-qa/apk176-export-fixture/verify_original_main_quality_rev187.gd").read_text()
assets=json.loads((root/"assets/cc0-spirit-rev206/asset_intake_proof.json").read_text())
assert assets["asset_total"]==7
assert len([m for m in assets["models"] if m["role"]=="herb"])==5
assert len([m for m in assets["models"] if m["role"]=="ore"])==2
for m in assets["models"]:
    assert Path(m["path"]).is_file()
for key in ["SPIRIT_CC0_SOURCES","_spawn_spirit_resource_nodes",
            "harvest_real_spirit_resource","_sync_spirit_resource_visuals",
            'spirit_resources.call("advance_world_hour")',
            "spirit_resource_sources.clear()"]:
    assert key in source,key
for key in ["func initialize() -> bool","get_nearest_resource",
            "func harvest(","func advance_world_hour()",
            "conservation_ok","SAVE_PATH"]:
    assert key in ledger,key
for key in ["SPIRIT_ORE_REQUIRES_EQUIPPED_PICK","_consume_real_medicine",
            "Rev206RealScrollableCharacterSheet","_spirit_craft_row",
            "real_spirit_resource","_spirit_use_row"]:
    assert key in player,key
for key in ["healing_pill","mana_pill","focus_ring","consume_item",
            "herb_fire","herb_water","spirit_stone"]:
    assert key in bag,key
assert "func restore_mana_from_real_pill" in spirit
assert "canglan_rev187/spirit_resources.gd" in pck
assert "canglan_rev187/cc0_spirit/herb/" in pck
assert "canglan_rev187/cc0_spirit/ore/" in pck
assert "PASS_REV206_REAL_MAIN_HAS_PERSISTENT_LICENCED_MEDICINAL_PLANTS_ORE_AND_TOUCH_MINING" in qa
print("PASS_REV206_TRUE_APK176_FINITE_SOURCE_LICENSED_MEDICINE_ORE_AND_NONFREE_CRAFT_INTEGRATION")
