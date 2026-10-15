#!/usr/bin/env python3
"""Production-workstation review. A recipe alone never creates a machine.

This audit is NOT the in-game station authority. Godot WorldState must later
prove station entity ID, crafted provenance, real placement, owner and use range.
"""
import argparse
import json
from pathlib import Path
from craft_graph import CraftGraph, CatalogError, require, uniq_ids

STATUS = "preproduction_facility_provenance_no_grants"


def inspect(graph, document):
    require(document.get("schema") == 1, "station_schema")
    require(document.get("status") == STATUS, "station_self_certification")
    require(document.get("world_authority") == "existing_WorldState_only",
            "unauthorized_station_authority")
    require(document.get("unlisted_station_policy") == "BLOCKED",
            "unlisted_station_can_be_free")
    stations = uniq_ids([dict(row, id=row.get("station"))
                         for row in document.get("facilities", [])], "station")
    used = {}
    for rid, recipe in graph.recipes.items():
        used.setdefault(recipe["station"], set()).add(rid)
    for sid, entry in stations.items():
        require(sid in used, "station_not_used_by_catalog:" + sid)
        require(entry.get("required_state") == "placed"
                and entry.get("requires_owned_crafted_entity") is True,
                "station_not_physically_owned:" + sid)
        require(entry.get("real_physical_fit_review") == "BLOCKED",
                "station_review_falsely_approved:" + sid)
        actual = entry.get("recipe_permissions")
        require(isinstance(actual, list) and len(actual) == len(set(actual)),
                "station_duplicate_permissions:" + sid)
        require(set(actual) == used[sid],
                "station_permission_mismatch:" + sid)
        if entry.get("prototype_entity") is not None:
            require(entry["prototype_entity"] == "ceramic_pot" and sid == "mixing_tub",
                    "unsupported_physical_station_alias:" + sid)
    result = {}
    for sid, recipes in sorted(used.items()):
        declared = stations.get(sid)
        result[sid] = {
            "recipes": sorted(recipes),
            "prototype_entity": declared.get("prototype_entity") if declared else None,
            "state": "BLOCKED_REQUIRES_REAL_WORLDSTATE_DEVICE_AND_ART_REVIEW"
            if declared else "BLOCKED_NO_PHYSICAL_DEVICE_DESIGN",
        }
    return {
        "schema": 1, "catalog_recipes": len(graph.recipes),
        "facility_types": len(used), "declared_candidates": len(stations),
        "unrealized_facility_types": len(used),
        "worldstate_station_grants": 0, "release_approved": False,
        "facility_review": result,
        "next_vertical_slice": {
            "recipe": "hand_mix_clay", "station": "mixing_tub",
            "required_next_evidence": [
                "legitimately crafted placed station entity",
                "actor close enough with tool ownership",
                "WorldState job debit and completion receipts",
                "old save roundtrip and duplicate-execution rejection",
                "actual Godot scene and Android visual/manual verification"
            ]
        }
    }


def main():
    cli = argparse.ArgumentParser()
    cli.add_argument("--catalog", type=Path, required=True)
    cli.add_argument("--stations", type=Path, required=True)
    cli.add_argument("--report", type=Path)
    args = cli.parse_args()
    try:
        graph = CraftGraph.load(args.catalog)
        stations = json.loads(args.stations.read_text(encoding="utf-8"))
        report = inspect(graph, stations)
    except (CatalogError, ValueError, KeyError, TypeError) as error:
        raise SystemExit("STATION_PROVENANCE_FAIL_CLOSED:" + str(error))
    output = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.report:
        args.report.write_text(output, encoding="utf-8")
    print(output)


if __name__ == "__main__":
    main()
