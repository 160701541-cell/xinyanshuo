#!/usr/bin/env python3
"""WorldX MIT map regions/elements -> actual selectable Canglan Godot hotspots.

Coordinates are source WorldX image pixels and are mapped to the verified
output raster dimensions. Interaction descriptions are display-only until a
real character economy/save transaction handler exists.
"""
from __future__ import annotations
import argparse,json,pathlib
from PIL import Image

def generate(source:pathlib.Path,manifest_file:pathlib.Path,out:pathlib.Path):
    manifest=json.loads(manifest_file.read_text("utf-8"))
    out.mkdir(parents=True,exist_ok=True)
    results=[]
    for i,rec in enumerate(manifest.get("assets",[])):
        source_png=source / rec["source"]
        map_dir=source_png.parent
        if not source_png.is_file() or source_png.name!="06-background.png":
            raise ValueError("Wrong WorldX source map")
        with Image.open(source_png) as im:
            source_w,source_h=im.size
        target_w,target_h=rec["size"]
        zones=[]
        for label,filename in (("region","06-regions-scaled.json"),("element","06-elements-scaled.json")):
            candidate=map_dir/filename
            if not candidate.is_file():continue
            items=json.loads(candidate.read_text("utf-8"))
            if not isinstance(items,list):continue
            for item in items:
                if not isinstance(item,dict):continue
                a=item.get("topLeft")
                b=item.get("bottomRight")
                if not isinstance(a,dict) or not isinstance(b,dict):continue
                x0,x1=sorted([float(a.get("x",0)),float(b.get("x",0))])
                y0,y1=sorted([float(a.get("y",0)),float(b.get("y",0))])
                x0=max(0,min(source_w,x0));x1=max(0,min(source_w,x1))
                y0=max(0,min(source_h,y0));y1=max(0,min(source_h,y1))
                if x1-x0<16 or y1-y0<16:continue
                interactions=item.get("interactions",[])
                zones.append({
                    "id":str(item.get("id",""))[:80],
                    "name":str(item.get("name","未命名区域"))[:50],
                    "description":str(item.get("description",""))[:180],
                    "kind":label,
                    "rect":[round(x0*target_w/source_w,1),round(y0*target_h/source_h,1),
                            round((x1-x0)*target_w/source_w,1),round((y1-y0)*target_h/source_h,1)],
                    "actions":[{"id":str(a.get("id",""))[:80],
                                "name":str(a.get("name",""))[:80],
                                "description":str(a.get("description",""))[:160]}
                               for a in interactions[:6] if isinstance(a,dict)]})
        target=out/f"zones_{i:03d}.json"
        target.write_text(json.dumps({"source_map":rec["source"],"image":rec["target"],
            "image_size":rec["size"],"zones":zones,
            "economy_effects_applied":False},ensure_ascii=False,indent=2)+"\n",encoding="utf8")
        results.append({"target":target.name,"zones":len(zones)})
    if not results:raise ValueError("No WorldX raster to link hotspots")
    print("PASS_WORLDX_MAP_REGION_IMPORT",json.dumps(results,ensure_ascii=False))
    return results
if __name__=="__main__":
    ap=argparse.ArgumentParser()
    ap.add_argument("--source",type=pathlib.Path,required=True)
    ap.add_argument("--manifest",type=pathlib.Path,required=True)
    ap.add_argument("--out",type=pathlib.Path,required=True)
    x=ap.parse_args()
    generate(x.source,x.manifest,x.out)
