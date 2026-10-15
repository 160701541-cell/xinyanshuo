#!/usr/bin/env python3
"""Produce a versioned asset demand manifest for Canglan starter village.
No PNG is synthesized or declared approved by this tool.
"""
import argparse
import json
from collections import Counter
from pathlib import Path

FAMILIES = {
 "terrain": {"ground_grass": 8, "ground_dirt": 8, "ground_stone": 8, "road": 12, "river": 12, "riverbank": 8, "slope": 8, "farmland": 6},
 "buildings": {"house": 12, "inn": 3, "apothecary": 3, "workshop": 4, "shop": 5, "warehouse": 3, "barn": 3, "pavilion": 2},
 "architecture": {"wall": 10, "roof": 10, "door": 8, "window": 6, "floor": 8, "stairs": 4, "gate": 4},
 "vegetation": {"tree": 12, "sapling": 4, "bamboo": 6, "bush": 6, "herb": 8, "rock": 8},
 "props": {"well": 2, "bucket": 3, "barrel": 3, "cart": 4, "stall": 5, "table": 4, "chair": 4, "chest": 3, "stove": 3, "lantern": 4, "medicine_cabinet": 2, "woodpile": 4, "drying_rack": 3, "tool_rack": 4},
 "actors": {"farmer": 4, "merchant": 4, "villager": 8, "child": 4, "guard": 4, "herbalist": 2, "cultivator": 4},
 "equipment": {"sword": 3, "bow": 2, "medicine_bottle": 3, "spirit_stone": 3, "talisman": 4}
}
STATE_RULES = {
 "door": ["closed", "open"], "gate": ["closed", "open"],
 "lantern": ["unlit", "lit"], "tree": ["spring", "summer", "autumn", "winter"],
 "sapling": ["spring", "summer", "autumn", "winter"],
 "house": ["intact", "damaged", "burned", "collapsed"],
 "inn": ["intact", "damaged", "burned", "collapsed"],
 "apothecary": ["intact", "damaged", "burned", "collapsed"],
 "workshop": ["intact", "damaged", "burned", "collapsed"],
 "shop": ["intact", "damaged", "burned", "collapsed"],
}
ACTOR_ACTIONS = ["idle", "walk", "run", "interact"]
ACTOR_DIRECTIONS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]


def build():
    records = []
    for family, objects in FAMILIES.items():
        for kind, count in objects.items():
            for i in range(1, count + 1):
                base = f"CL.{family.upper()}.{kind.upper()}.{i:03d}"
                states = STATE_RULES.get(kind, ["default"])
                if family == "actors":
                    variants = [{"action": a, "direction": d} for a in ACTOR_ACTIONS for d in ACTOR_DIRECTIONS]
                else:
                    variants = [{"state": state} for state in states]
                for variant in variants:
                    suffix = "-".join(variant.values())
                    aid = f"{base}.{suffix}"
                    records.append({
                        "id": aid, "prototype_id": base, "family": family, "kind": kind,
                        "variant": variant, "status": "SPEC_ONLY",
                        "world_png": f"hd2d-assets/starter_village/{family}/{base}/{suffix}.png",
                        "icon_png": f"hd2d-assets/starter_village/icons/{base}.png",
                        "qa": {"technical": "NOT_RUN", "visual": "NOT_REVIEWED", "godot": "NOT_RUN"},
                        "source_sha256": None, "license": None
                    })
    return {"schema": "canglan-starter-village-assets/1", "scene": "starter_village",
            "asset_count": len(records), "prototype_count": sum(map(lambda x: sum(x.values()), FAMILIES.values())),
            "status": "SPEC_ONLY", "assets": records}


def validate(data):
    assets = data["assets"]
    ids = [a["id"] for a in assets]
    assert len(ids) == len(set(ids)), "duplicate asset IDs"
    assert len(ids) == data["asset_count"]
    assert len({a["prototype_id"] for a in assets}) == data["prototype_count"]
    assert all(a["status"] == "SPEC_ONLY" for a in assets)
    assert all(not a["source_sha256"] for a in assets)
    assert all(a["world_png"].endswith(".png") and ".." not in a["world_png"] for a in assets)
    assert all(a["icon_png"].endswith(".png") for a in assets)
    assert Counter(a["family"] for a in assets)["terrain"] >= 50
    return True


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="tools/asset_factory/starter_village_demand.json")
    args = p.parse_args()
    result = build()
    validate(result)
    path = Path(args.out)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"SPEC_ONLY: {result['prototype_count']} prototypes, {result['asset_count']} variants; 0 image files generated")


if __name__ == "__main__":
    main()
