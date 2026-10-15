#!/usr/bin/env python3
"""WorldX -> Canglan original APK176 Godot image bridge.

WorldX (YGYOOO/WorldX, MIT) outputs image files for maps and character
sprites. Reuse *existing* generated PNGs as textures; this script does NOT
claim WorldX itself can generate without configured model services.
Safely copies existing image pixels, never bundles model API keys or JS runtime.
"""
from __future__ import annotations
import argparse, hashlib, json, pathlib, shutil
from PIL import Image, ImageOps

ALLOWED_SUFFIXES={".png",".jpg",".jpeg",".webp"}
IMAGE_LIMIT=40*1024*1024
PIXEL_LIMIT=36_000_000
SLOTS=("ground","water","roof","courtyard","street","building","foliage","character")
def find_images(root:pathlib.Path):
    found=[]
    for p in root.rglob("*"):
        if not p.is_file() or p.suffix.lower() not in ALLOWED_SUFFIXES:
            continue
        if p.is_symlink() or not 0<p.stat().st_size<IMAGE_LIMIT:
            continue
        if any(x in p.parts for x in ("node_modules",".git","__pycache__")):
            continue
        try:
            with Image.open(p) as im:
                w,h=im.size
                if w<128 or h<128 or w*h>PIXEL_LIMIT: continue
        except (OSError,ValueError):
            continue
        found.append(p)
    return sorted(found, key=lambda p:(0 if "map" in p.parts else 1, "sprite" in p.name.lower(), str(p)))
def convert(root:pathlib.Path, out:pathlib.Path, limit:int):
    root=root.resolve();out.mkdir(parents=True,exist_ok=True)
    candidates=find_images(root)
    if not candidates:
        raise ValueError("WorldX input has NO real raster assets; refusing synthetic or fake results")
    selected=candidates[:limit]
    manifest={"source":"WorldX output raster images / YGYOOO/WorldX MIT pipeline",
              "assets":[],"generation_claim":False,"review_status":"CANDIDATE_NOT_VISUALLY_APPROVED"}
    for idx,p in enumerate(selected):
        with Image.open(p) as img:
            img=ImageOps.exif_transpose(img)
            img.thumbnail((1024,1024),Image.Resampling.LANCZOS)
            img=img.convert("RGBA")
            name=f"worldx_{idx:03}.png"
            dst=out/name
            img.save(dst,optimize=True)
            manifest["assets"].append({"source":str(p.relative_to(root)),"target":name,
                "size":list(img.size),"sha256":hashlib.sha256(dst.read_bytes()).hexdigest(),
                "provenance":"copied pixels from WorldX raster, scaled if necessary",
                "godot_path":f"res://hd2d/worldx/{name}"})
    (out/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    print(f"PASS_WORLDX_ACTUAL_RASTER_IMPORT count={len(manifest['assets'])}")
    return manifest
if __name__=="__main__":
    ap=argparse.ArgumentParser()
    ap.add_argument("--source",type=pathlib.Path,required=True)
    ap.add_argument("--out",type=pathlib.Path,required=True)
    ap.add_argument("--limit",type=int,default=12)
    args=ap.parse_args()
    assert 1<=args.limit<=64
    convert(args.source,args.out,args.limit)
