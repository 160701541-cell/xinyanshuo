#!/usr/bin/env python3
"""Source-only export QA, no networked image models or WorldBox DLLs."""
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from PIL import Image
def main():
    root=Path(__file__).resolve().parent
    with tempfile.TemporaryDirectory() as td:
        p=Path(td)
        src=p/"src";src.mkdir()
        a=Image.new("RGBA",(64,32))
        for x in range(6,24):
            for y in range(7,29):a.putpixel((x,y),(160,110,50,255))
        for x in range(38,54):
            for y in range(4,26):a.putpixel((x,y),(31,150,200,255))
        a.save(src/"alchemy_idle_spritesheet.png")
        target=p/"out"
        subprocess.run([sys.executable,str(root/"export_nml_sprites.py"),"--sheets",str(src),"--out",str(target),"--size","64","--pixel","2"],check=True)
        data=json.loads((target/"asset_manifest.json").read_text())
        assert data["frames"]==2
        assert len(data["sequences"])==1
        seq=data["sequences"][0]
        import hashlib
        for entry in seq["frames"]:
            out=target/entry["path"]
            with Image.open(out) as im:
                assert im.size==(64,64)
                assert im.getpixel((0,0))[3]==0
            assert hashlib.sha256(out.read_bytes()).hexdigest()==entry["sha256"]
        settings=json.loads((target/"GameResources/xianxia/buildings/sprites.json").read_text())
        assert settings["Default"]["PivotY"]==0.0
        assert seq["frames"][0]["sha256"]!=seq["frames"][1]["sha256"]
    print("PASS_WORLDBOX_EXPORT_SOURCE_QA: 2 real distinct alpha PNG, manifest SHA256, NML pivot")
if __name__=="__main__":main()
