#!/usr/bin/env python3
"""Deterministic WorldBox-style PIXEL icon factory; original art, never game sprites.

Reads one catalog seed and mass-produces a full, bounded resource/icon/recipe
package. 32px RGBA native pixel tiles; nearest neighbor 64px previews and a
16-column atlas with 1px spacing. No generated image is claimed to be a
licensed WorldBox original. WorldBox categorization is metadata until bound
to an actual in-game menu (device QA required).
"""
import argparse,hashlib,json,random,re,zipfile
from pathlib import Path
from PIL import Image, ImageDraw
BASE=Path(__file__).resolve().parent
PALETTE={"dark":"#202b36","edge":"#33454d","highlight":"#f5dfa5","shadow":"#1b242d"}
PROCESSABLE={"ore","crop","herb","forest","animal"}
UPGRADABLE={"governance"}
def rgb(h):
 h=h.lstrip("#")
 return tuple(int(h[i:i+2],16) for i in (0,2,4))
def tint(c,d):
 return tuple(max(0,min(255,x+d)) for x in c)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def icon(variant,family,stage):
 key=variant["id"]+"@"+stage
 seed=int(hashlib.sha256(key.encode()).hexdigest()[:16],16)
 rng=random.Random(seed)
 c=rgb(variant["color"]);dark=tint(c,-74);light=tint(c,58);rim=(29,38,42)
 im=Image.new("RGBA",(32,32),(0,0,0,0));d=ImageDraw.Draw(im)
 # Hard 1-2px outline/shadow; no anti-alias so original WorldBox pixel style remains crisp.
 kind=family["motif"]
 if kind=="coin":
  for y in (8,10,13,16,19):
   d.ellipse((7,y,24,y+9),fill=(*rim,255),outline=(*dark,255),width=1)
  d.ellipse((7,7,24,22),fill=(*c,255),outline=(*rim,255),width=2)
  d.ellipse((10,10,21,19),outline=(*light,255),width=2)
  d.rectangle((14,12,16,16),fill=(*dark,255))
 elif kind=="crystal":
  polygon=[(16,3),(24,10),(23,23),(16,30),(8,23),(7,10)]
  d.polygon(polygon,fill=(*c,255))
  d.polygon([(16,3),(24,10),(16,13),(11,11)],fill=(*light,255))
  d.polygon([(7,10),(16,13),(16,30),(8,23)],fill=(*dark,255))
  d.line(polygon+[polygon[0]],fill=(*rim,255),width=2)
  d.line((16,4,16,28),fill=(*light,255),width=1)
 elif kind=="ore":
  poly=[(3,21),(7,11),(13,12),(17,5),(26,10),(29,22),(22,29),(10,27)]
  d.polygon(poly,fill=(*rim,255))
  d.polygon([(5,20),(9,11),(17,7),(25,12),(26,22),(21,26),(11,25)],fill=(*c,255))
  d.polygon([(9,12),(17,7),(25,12),(17,17)],fill=(*light,255))
  d.line((17,17,13,23,20,25),fill=(*dark,255),width=2)
 elif kind in ("grain","herb"):
  d.line((16,29,16,12),fill=(*rim,255),width=4)
  d.line((16,28,16,12),fill=(*c,255),width=2)
  if kind=="grain":
   for j in range(5):
    y=8+j*4
    for side in (-1,1):
     d.ellipse((16+side*8-3,y,16+side*8+3,y+5),
               fill=(*(light if j%2 else c),255),outline=(*rim,255))
  else:
   for j in range(4):
    y=8+j*5
    x=16+(-9 if j%2 else 9)
    d.polygon([(16,y+6),(x,y-3),(x+(2 if j%2 else -2),y+7)],
              fill=(*c,255),outline=(*rim,255))
   d.ellipse((12,3,21,11),fill=(*light,255),outline=(*rim,255),width=1)
 elif kind=="log":
  d.polygon([(3,18),(22,8),(30,13),(10,27)],fill=(*dark,255),outline=(*rim,255))
  d.polygon([(3,18),(10,15),(17,20),(10,27)],fill=(*c,255),outline=(*rim,255))
  d.ellipse((6,18,12,24),outline=(*light,255),width=1)
  d.line((14,20,27,13),fill=(*light,255),width=2)
 elif kind=="livestock":
  d.polygon([(7,9),(24,8),(29,17),(22,26),(8,25),(3,15)],
            fill=(*c,255),outline=(*rim,255),width=2)
  d.ellipse((8,10,15,16),fill=(*light,255))
  d.line((15,19,24,14),fill=(*dark,255),width=3)
 elif kind=="material":
  for i in range(3):
   y=8+i*7
   d.polygon([(4,y+3),(21,y),(29,y+5),(12,y+9)],
      fill=(*c,255),outline=(*rim,255))
   d.line((6,y+4,20,y+1),fill=(*light,255),width=2)
 elif kind=="product":
  d.polygon([(16,2),(21,12),(28,18),(21,24),(16,30),(9,24),(4,18),(11,12)],
     fill=(*rim,255))
  d.polygon([(16,5),(20,13),(25,18),(20,22),(16,28),(12,22),(7,18),(12,13)],
     fill=(*c,255))
  d.polygon([(16,6),(20,13),(16,17),(11,13)],fill=(*light,255))
  d.line((9,19,23,19),fill=(*dark,255),width=2)
 elif kind=="flag":
  d.line((6,4,6,29),fill=(*rim,255),width=4)
  d.line((6,5,6,28),fill=(*light,255),width=2)
  d.polygon([(8,5),(28,7),(23,15),(9,14)],fill=(*c,255),outline=(*rim,255))
  d.rectangle((10,9,18,11),fill=(*light,255))
 # Tiny deterministic mineral grains to avoid every variant identical.
 for i in range(5):
  x=rng.randrange(7,26);y=rng.randrange(8,24)
  if im.getpixel((x,y))[3]>0 and rng.random()<.65:
   d.point((x,y),fill=(*light if i%2 else dark,255))
 if stage!="raw":
  # Stage badge actually differentiates semi-products and grown-up offices.
  d.rectangle((20,21,30,30),fill=(*rim,255),outline=(*light,255))
  symbol={"processed":[(22,25),(24,23),(27,27)],"advanced":[(22,23),(28,28)],"level2":[(23,24),(27,27)],"level3":[(22,23),(25,27),(28,23)]}
  pts=symbol.get(stage,[(23,25),(27,25)])
  d.line(pts,fill=(*light,255),width=2)
 return im
def catalog_entries(seed):
 items=[]
 for fam in seed["families"]:
  for it in fam["variants"]:
   stages=["raw"]
   if fam["id"] in PROCESSABLE:stages.append("processed")
   if fam["id"] in UPGRADABLE:stages.extend(["level2","level3"])
   for stage in stages:
    code=it["id"] if stage=="raw" else it["id"]+"_"+stage
    status={"raw":"","processed":"·精制","level2":"·二级","level3":"·三级"}[stage]
    items.append({"id":"wbx_"+code,"name":it["name"]+status,"family":fam["id"],
      "stage":stage,"target_tab":fam["tab"],"icon":"icons/wbx_"+code+".png",
      "category":fam["display"],"sprite_license":"self-generated pixel art from this original factory",
      "needs_original_tab_binding":True,"color":it["color"]})
 ids=[it["id"] for it in items]
 assert len(ids)==len(set(ids)),"duplicate material names"
 return sorted(items,key=lambda it:it["id"])
def recipes(items):
 known={i["id"] for i in items}
 out=[]
 for obj in items:
  if obj["stage"]=="processed":
   origin=obj["id"][:-10] # strip _processed
   if origin not in known:raise ValueError("missing raw ingredient "+origin)
   out.append({"id":"process_"+origin,"work_minutes":30,
     "station":"工坊" if obj["family"] not in ("crop","herb") else "磨坊与药房",
     "inputs":{origin:3},"outputs":{obj["id"]:2},"loss_units":1,
     "research":"processing_"+obj["family"]})
  if obj["stage"] in ("level2","level3"):
   origin=obj["id"].rsplit("_",1)[0]
   previous=origin if obj["stage"]=="level2" else origin+"_level2"
   if previous not in known:raise ValueError("bad office construction chain")
   out.append({"id":"upgrade_"+obj["id"],"work_minutes":240 if obj["stage"]=="level2" else 840,
     "station":"施工工地","inputs":{previous:1,"wbx_qing_brick":30,"wbx_plank":12},
     "outputs":{obj["id"]:1},"workers_required":8 if obj["stage"]=="level2" else 35,
     "research":"administration_construction"})
 return out
def make(outdir,seedfile=BASE/"catalog_seed.json"):
 seed=json.loads(Path(seedfile).read_text(encoding="utf-8"))
 items=catalog_entries(seed);rec=recipes(items)
 outdir=Path(outdir); icons=outdir/"icons";icons.mkdir(parents=True,exist_ok=True)
 fams={x["id"]:x for x in seed["families"]}
 variants={v["id"]:v for fam in seed["families"] for v in fam["variants"]}
 for item in items:
  name=item["id"][4:]
  original=name
  if item["stage"]!="raw":original=name[:-(len(item["stage"])+1)]
  icon(variants[original],fams[item["family"]],item["stage"]).save(outdir/item["icon"],optimize=True)
 w,h=16*34,((len(items)+15)//16)*34
 atlas=Image.new("RGBA",(w,h),(0,0,0,0))
 for index,item in enumerate(items):
  xy=(index%16*34+1,index//16*34+1)
  with Image.open(outdir/item["icon"]) as tile: atlas.alpha_composite(tile,xy)
  item["atlas_rect"]=[xy[0],xy[1],32,32]
 atlas.save(outdir/"resource_atlas.png",optimize=True)
 manifest={"schema":1,"worldbox_game":"0.51.4","status":"GENERATED_ASSETS_NOT_YET_PROVEN_VISIBLE_IN_VANILLA_TABS",
  "pack":"万界仙侠-资源经济工业化v0.35","items":items,"recipes":rec,
  "currency_exchange":seed["exchange"],"administration":seed["administration"],
  "raw_families":len(seed["families"]),"atlas":"resource_atlas.png",
  "license":"source-generated self-owned pixels, not original WorldBox sprites"}
 (outdir/"resource_manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
 checks={"atlas_sha256":sha(outdir/"resource_atlas.png"),"files":len(items),"icons":[]}
 for item in items:checks["icons"].append({"id":item["id"],"sha256":sha(outdir/item["icon"])})
 (outdir/"SHA256SUMS.json").write_text(json.dumps(checks,indent=2)+"\n",encoding="utf8")
 return manifest
def package(outdir,dst):
 root=Path(outdir)
 with zipfile.ZipFile(dst,"w",zipfile.ZIP_DEFLATED,compresslevel=9) as z:
  for p in sorted(root.rglob("*")):
   if p.is_file():z.write(p,p.relative_to(root).as_posix())
 with zipfile.ZipFile(dst) as z:assert z.testzip() is None
if __name__=="__main__":
 ap=argparse.ArgumentParser();ap.add_argument("--out",type=Path,required=True)
 ap.add_argument("--zip",type=Path);a=ap.parse_args()
 result=make(a.out)
 if a.zip:package(a.out,a.zip)
 print(json.dumps({"icon_count":len(result["items"]),"recipe_count":len(result["recipes"]),
                   "sprite_atlas":result["atlas"]},ensure_ascii=False))
