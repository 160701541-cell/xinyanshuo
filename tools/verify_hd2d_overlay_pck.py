#!/usr/bin/env python3
"""Audit bounded old-Canglan HD2D pack with real WorldX maps & NPC sprite sheets."""
import sys,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"logic-qa/tools"))
import audit_tiny_ota_pck as pck

REQUIRED={"scenes/main.tscn.remap","scenes/main_hd2d_ota177.tscn",
"scripts/hd2d_original_overlay_ota177.gd","scripts/hd2d_stone_road.gd",
"scripts/hd2d_worldx_npcs.gd","hd2d/atlas_village_ota177.jpg"}
OPTIONAL={"hd2d/worldx/npcs/npcs.json"}
OPTIONAL.update("hd2d/worldx/worldx_%03d.png"%i for i in range(8))
OPTIONAL.update("hd2d/worldx/zones_%03d.json"%i for i in range(8))
OPTIONAL.update("hd2d/worldx/npcs/npc_%02d.png"%i for i in range(16))

def names_only(raw):
    if raw[:4]!=b"GDPC":raise ValueError("No Godot PCK header")
    count=struct.unpack_from("<I",raw,0x60)[0]
    if not 6<=count<=39:raise ValueError("Unbounded resource count")
    position=0x64
    result=set()
    for _ in range(count):
        length=struct.unpack_from("<I",raw,position)[0]
        position+=4
        if not 1<=length<=1024:raise ValueError("Invalid PCK path length")
        name=raw[position:position+length].split(bytes([0]),1)[0].decode("utf-8","strict")
        position+=length+36
        if name in result:raise ValueError("Duplicate PCK resource")
        result.add(name)
    return result

def verify(path):
    raw=path.read_bytes()
    paths=names_only(raw)
    if not REQUIRED.issubset(paths) or not paths.issubset(REQUIRED|OPTIONAL):
        raise ValueError("Missing base assets or unauthorized PCK entries")
    npc="hd2d/worldx/npcs/npcs.json"
    if npc in paths and not "hd2d/worldx/npcs/npc_00.png" in paths:
        raise ValueError("NPC manifest without character sprite")
    if path.stat().st_size>36_000_000:raise ValueError("Oversized mobile candidate")
    pck.ALLOWED=paths
    entries=pck.read_index(raw)
    if set(x["name"] for x in entries)!=paths:raise ValueError("PCK index corrupt")
    print("PASS_APK176_HD2D_RESOURCE_PCK_INDEX",len(entries))
    for item in entries:
        print("HD2D_OTA_INDEX_ENTRY",item["name"],item["size"],item["sha256"])
if __name__=="__main__":
    if len(sys.argv)!=2:raise SystemExit("usage: verify_hd2d_overlay_pck.py path.pck")
    verify(Path(sys.argv[1]))
