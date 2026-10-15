#!/usr/bin/env python3
"""Fail-closed inspection of APK176 HD2D MAIN SCENE candidate, never publish."""
import sys
import struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"logic-qa/tools"))
import audit_tiny_ota_pck as pck
pck.ALLOWED={
    "scenes/main.tscn.remap",
    "scenes/main_hd2d_ota177.tscn",
    "scripts/hd2d_original_overlay_ota177.gd",
    "scripts/hd2d_stone_road.gd",
    "hd2d/atlas_village_ota177.jpg",
}
def verify(path:Path):
    raw=path.read_bytes()
    # Exact canonical resource names: five original-game assets and up to
    # eight sequential WorldX map PNGs. Never allow arbitrary script paths.
    n=struct.unpack_from("<I",raw,0x60)[0]
    assert 5<=n<=13, f"Unexpected PCK resource count {n}"
    for i in range(n-5):
        pck.ALLOWED.add("hd2d/worldx/worldx_%03d.png"%i)
    entries=pck.read_index(raw)
    assert {x["name"] for x in entries}==pck.ALLOWED
    assert path.stat().st_size<32_000_000,"candidate unexpectedly large"
    print("PASS_APK176_HD2D_RESOURCE_PCK_INDEX",len(entries))
    for entry in entries:
        print("HD2D_OTA_INDEX_ENTRY",entry["name"],entry["size"],entry["sha256"])
if __name__=="__main__":
    if len(sys.argv)!=2:
        raise SystemExit("usage: verify_hd2d_overlay_pck.py candidate.pck")
    verify(Path(sys.argv[1]))
