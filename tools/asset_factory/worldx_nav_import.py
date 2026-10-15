#!/usr/bin/env python3
"""Convert actual WorldX 05-walkable-grid.json to Godot-friendly compact grid.

WorldX uses 0 for walkable and 1 for blocked. 4x4 majority-downsample
reduces one 344x192 sample to 86x48; collision never inferred from images.
"""
import argparse,json,pathlib,math
def convert(source,manifest_path,out,downsample=4):
    catalog=json.loads(manifest_path.read_text("utf8"))
    out.mkdir(parents=True,exist_ok=True)
    outputs=[]
    for idx,item in enumerate(catalog["assets"]):
        source_file=source/item["source"]
        src=source_file.parent/"05-walkable-grid.json"
        if not src.is_file():continue
        raw=json.loads(src.read_text("utf8"))
        src_cols=int(raw["gridWidth"]);src_rows=int(raw["gridHeight"])
        grid=raw["grid"]
        if len(grid)!=src_rows or any(len(row)!=src_cols for row in grid):
            raise ValueError("WorldX grid dimensions invalid")
        cols=math.ceil(src_cols/downsample)
        rows=math.ceil(src_rows/downsample)
        compact=[]
        free=0
        for y in range(rows):
            line=[]
            for x in range(cols):
                samples=[int(grid[yy][xx]) for yy in range(y*downsample,min((y+1)*downsample,src_rows))
                    for xx in range(x*downsample,min((x+1)*downsample,src_cols))]
                is_walkable=sum(v==0 for v in samples)>=max(1,len(samples)//2)
                line.append("0" if is_walkable else "1")
                free+=int(is_walkable)
            compact.append("".join(line))
        target=out/f"nav_{idx:03}.json"
        target.write_text(json.dumps({"source":str(src.relative_to(source)),
          "image":item["target"],"width":cols,"height":rows,
          "cells":compact,"walkable":free,"blocked":rows*cols-free,
          "semantics":"0=walkable,1=blocked from actual WorldX map grid"},
          ensure_ascii=False,indent=2)+"\n",encoding="utf8")
        outputs.append({"target":target.name,"walkable":free,"blocked":rows*cols-free})
    if not outputs:raise ValueError("WorldX has no source walkability metadata")
    print("PASS_WORLDX_REAL_WALKABLE_GRID",json.dumps(outputs,ensure_ascii=False))
    return outputs
if __name__=="__main__":
    ap=argparse.ArgumentParser()
    ap.add_argument("--source",type=pathlib.Path,required=True)
    ap.add_argument("--manifest",type=pathlib.Path,required=True)
    ap.add_argument("--out",type=pathlib.Path,required=True)
    x=ap.parse_args()
    convert(x.source,x.manifest,x.out)
