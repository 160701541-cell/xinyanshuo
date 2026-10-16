#!/usr/bin/env python3
"""Stage existing MIT-licensed WorldX NPC sheets for 3D billboard rendering.

No re-generation. Original character identities are visual templates ONLY:
canonical citizen ID, age, name, belongings and profession live elsewhere.
"""
from __future__ import annotations
import argparse,hashlib,json,shutil
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/"game-source/apk176-ota177-candidate/hd2d/worldx/npcs"
VISUAL_ARCHETYPES={"merchant":0,"scholar":1,"guard":2,"plain_civilian":3,"tavern":4}
# Character 05 (modern dress with smartphone) is prohibited in historic simulation.

def stage(out:Path):
    if not SOURCE.is_dir():
        raise FileNotFoundError(f"Original approved-source PNG folder missing: {SOURCE}")
    meta=json.loads((SOURCE/"npcs.json").read_text(encoding="utf-8"))
    persons=meta["characters"]
    assert meta["license"]=="MIT" and len(persons)>=6
    dst=out/"npc/worldx"
    dst.mkdir(parents=True,exist_ok=True)
    sheets=[]
    for archetype,idx in VISUAL_ARCHETYPES.items():
        char=persons[idx]
        src=SOURCE/char["sheet"]
        payload=src.read_bytes()
        assert payload[:8]==b"\x89PNG\r\n\x1a\n" and len(payload)>5000,src
        digest=hashlib.sha256(payload).hexdigest()
        assert digest==char["sha256"],(src,digest)
        assert char["columns"]==6 and char["rows"]==5
        assert char["frame_width"]==170 and char["frame_height"]==204
        out_name=f"{archetype}.png"
        (dst/out_name).write_bytes(payload)
        sheets.append({"archetype":archetype,"original_character":char["name"],
            "file":f"npc/worldx/{out_name}","sha256":digest,"bytes":len(payload),
            "columns":6,"rows":5,
            "animations":char["animations"]})
    manifest={"schema":1,"license":meta["license"],"source":meta["source"],
        "source_world":meta["source_world"],"art_status":"EXISTING_SOURCE_ASSET_TEST_CANDIDATE",
        "mapping":sheets,"excluded":["npc_05.png: modern character with smartphone"]}
    (dst/"worldx_sprites_manifest.json").write_text(
        json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    return manifest

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--out",required=True,type=Path)
    a=parser.parse_args()
    result=stage(a.out)
    print("PASS_WORLDX_5_EXISTING_ROLE_SHEETS_STAGED",len(result["mapping"]))
