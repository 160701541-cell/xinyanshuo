#!/usr/bin/env python3
"""Export art rendered by character-pipeline into NML GameResources (candidate art).

Supported inputs:
  --sheets: <asset>_<state>_spritesheet.png, N square frames in one row
  --renders: character-pipeline out/roles or out/beings (single-angle previews)
Output: independent PNG, sprites.json, metadata with SHA256.
Not an APK patch, not an animation registration in WorldBox.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path
from PIL import Image

IDENT = re.compile(r"^[a-zA-Z][a-zA-Z0-9_-]{0,70}$")
def valid(s):
    if not IDENT.fullmatch(s):
        raise ValueError("unsafe asset ID: " + s)
    return s

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def normalize(image, side=64, pixel=2, bottom=True):
    im = image.convert("RGBA")
    bb = im.getchannel("A").getbbox()
    if bb is None:
        raise ValueError("blank frame")
    im = im.crop(bb)
    low = side // pixel
    target = low - 4
    scale = min(target / im.width, target / im.height)
    wh = (max(1, round(im.width * scale)), max(1, round(im.height * scale)))
    method = Image.Resampling.LANCZOS if scale < 1 else Image.Resampling.NEAREST
    im = im.resize(wh, method)
    a = im.getchannel("A").point(lambda v: 255 if v >= 48 else 0)
    im.putalpha(a)
    canvas = Image.new("RGBA", (low, low), (0,0,0,0))
    canvas.alpha_composite(im, ((low-im.width)//2, low-2-im.height if bottom else (low-im.height)//2))
    return canvas.resize((side, side), Image.Resampling.NEAREST)

def save_frame(out, category, asset, state, direction, i, image, size, pixel):
    for name in (category,asset,state,direction): valid(name)
    rel = Path("GameResources") / "xianxia" / category / asset / state / ("%s_%02d.png" % (direction,i))
    dst = out / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    normalize(image,size,pixel,category in ("buildings","characters","beasts","vegetation")).save(dst,optimize=True)
    return {"path": rel.as_posix(), "sha256": sha(dst)}

def export_sheets(folder,out,size,pixel):
    sequences=[]
    for src in sorted(folder.glob("*_spritesheet.png")):
        title=src.stem.removesuffix("_spritesheet")
        asset,state=title.rsplit("_",1)
        with Image.open(src) as img:
            if not img.height or img.width % img.height:
                raise ValueError("not N square tiles: " + src.name)
            n=img.width//img.height
            if not 1 <= n <= 32: raise ValueError("bad number of frames")
            frames=[save_frame(out,"buildings",asset,state,"iso",i,img.crop((i*img.height,0,(i+1)*img.height,img.height)),size,pixel) for i in range(n)]
        sequences.append({"id":asset+"/"+state,"category":"buildings","state":state,"fps":4,"loop":state!="construction","frames":frames,"source_sha256":sha(src)})
    return sequences

def export_renders(folder,out,size,pixel):
    sequences=[]
    for src in sorted(folder.rglob("*.png")):
        family=src.parent.name.lower()
        category=("characters" if family in ("roles","beings","characters") else
                  "beasts" if family=="beasts" else
                  "items" if family in ("matrix","batch","prod","items") else None)
        if category is None:continue
        # Preserve unique five-element identifiers instead of replacing all Hanzi with '_'.
        element={"火":"fire","雷":"thunder","水":"water","木":"wood","金":"metal"}
        stem=src.stem
        for ch,ascii_name in element.items():stem=stem.replace(ch,"_"+ascii_name)
        name=re.sub(r"[^A-Za-z0-9_-]","_",stem)
        direction="iso"
        m=re.fullmatch(r"(.+)_([0-3])",name)
        if m: name,direction=m.group(1),"d"+m.group(2)
        with Image.open(src) as img:
            frame=save_frame(out,category,name,"idle",direction,0,img,size,pixel)
        sequences.append({"id":category+"/"+name+"/"+direction,"category":category,
                          "state":"idle","fps":1,"loop":False,"frames":[frame],"source_sha256":sha(src),
                          "warning":"One rendered angle is not a walking or attack animation"})
    return sequences

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--sheets",type=Path)
    p.add_argument("--renders",type=Path)
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--size",type=int,default=64,choices=(32,48,64,96,128))
    p.add_argument("--pixel",type=int,default=2)
    a=p.parse_args()
    if a.size % a.pixel or a.pixel < 1:p.error("invalid pixel block size")
    if a.renders is None and a.sheets is None:p.error("need --renders or --sheets")
    result=[]
    if a.sheets:result+=export_sheets(a.sheets,a.out,a.size,a.pixel)
    if a.renders:result+=export_renders(a.renders,a.out,a.size,a.pixel)
    cats=set(x["category"] for x in result)
    for cat in cats:
        folder=a.out/"GameResources"/"xianxia"/cat
        bottom=cat in ("buildings","characters","beasts","vegetation")
        data={"Default":{"PixelsPerUnit":1,"PivotX":0.5,"PivotY":0.0 if bottom else 0.5},"Specific":[]}
        (folder/"sprites.json").write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
    output={"schema":"xianxia.worldbox.sprite-candidates.v1","status":"UNVERIFIED_ANDROID",
            "upstream":"character-pipeline","sequences":result,
            "frames":sum(len(s["frames"]) for s in result)}
    a.out.mkdir(parents=True,exist_ok=True)
    (a.out/"asset_manifest.json").write_text(json.dumps(output,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
    print("candidate assets:",len(result),"animations",output["frames"],"PNG")
if __name__=="__main__":main()
