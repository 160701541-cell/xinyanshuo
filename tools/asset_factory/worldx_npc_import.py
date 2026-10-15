#!/usr/bin/env python3
"""Import REAL WorldX MIT character sprite sheets and source-defined animation timing.

Only characters for one world (first lexicographic world by default), not a
random incompatible collage. Source sheets are copied without reinterpolation.
Godot reads the manifest and spritesheets at runtime. No model credentials.
"""
import argparse,hashlib,json,pathlib,shutil
from PIL import Image
def run(source:pathlib.Path,out:pathlib.Path,limit:int=6):
    worlds=sorted(p for p in source.iterdir() if p.is_dir() and (p/"characters").is_dir())
    if not worlds: raise ValueError("No actual WorldX characters folders")
    world=worlds[0]
    out.mkdir(parents=True,exist_ok=True)
    result={"source":"https://github.com/YGYOOO/WorldX","license":"MIT",
            "source_world":world.name,"characters":[],"visual_qa":"CANDIDATE"}
    for character_dir in sorted((world/"characters").iterdir()):
        meta=character_dir/"metadata.json"
        art=character_dir/"spritesheet.png"
        if not meta.is_file() or not art.is_file(): continue
        m=json.loads(meta.read_text(encoding="utf-8"))
        fw,fh,cols,rows=(int(m[k]) for k in ("frameWidth","frameHeight","columns","rows"))
        if min(fw,fh,cols,rows)<1 or cols*rows<21:continue
        with Image.open(art) as im:
            im.verify()
        with Image.open(art) as im:
            w,h=im.size
        if w < fw*cols or h < fh*rows:continue
        if w*h>20_000_000:continue
        n=len(result["characters"])
        dest=f"npc_{n:02d}.png"
        shutil.copyfile(art,out/dest)
        result["characters"].append({
            "id":str(m.get("id",character_dir.name)),"name":str(m.get("name","旅人"))[:60],
            "description":str(m.get("description",""))[:200],
            "sheet":dest,"frame_width":fw,"frame_height":fh,
            "columns":cols,"rows":rows,
            "animations":m.get("animations",{}),
            "sha256":hashlib.sha256((out/dest).read_bytes()).hexdigest(),
            "origin":str(art.relative_to(source)),
            "source_metadata":str(meta.relative_to(source))})
        if len(result["characters"])>=limit:break
    if not result["characters"]:raise ValueError("No valid WorldX sprite sheets")
    (out/"npcs.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("PASS_WORLDX_ORIGINAL_NPC_SPRITES",len(result["characters"]),
          "frames_per_sheet",result["characters"][0]["columns"]*result["characters"][0]["rows"])
    return result
if __name__=="__main__":
    ap=argparse.ArgumentParser()
    ap.add_argument("--source",type=pathlib.Path,required=True)
    ap.add_argument("--out",type=pathlib.Path,required=True)
    ap.add_argument("--limit",type=int,default=6)
    args=ap.parse_args()
    assert 1<=args.limit<=24
    run(args.source,args.out,args.limit)
