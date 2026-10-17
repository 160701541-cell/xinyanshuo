#!/usr/bin/env python3
"""rev208 quarantined *real* CC0 foliage intake, not generated geometry.
Every provider page is checked individually and downloaded binaries are SHA-pinned.
No phone/release manifest is ever modified by this script.
"""
from __future__ import annotations
import hashlib
import json
import re
import struct
import sys
import time
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

BASE="https://www.innerscene.com"
# Exact public CC0 source pages, as opposed to an assumed license for a model site.
ASSETS={
 "pine":{"slug":"mature-scots-pine-tree-280307e1","layer":"mature","height_range":[15.0,21.0],"author":"Innerscene"},
 "cypress":{"slug":"columnar-cypress-tree-46fad033","layer":"mature","height_range":[10.0,14.0],"author":"Innerscene"},
 "conifer":{"slug":"mature-norway-spruce-tree-48c2566f","layer":"mature","height_range":[14.0,18.0],"author":"Innerscene"},
 "fern":{"slug":"fern-clumps-82a87bea","layer":"groundcover","height_range":[0.1,1.5],"author":"Rob Tuytel and Rico Cilliers (Poly Haven)"},
 "hydrangea":{"slug":"flowering-hydrangea-shrub-af2da5d3","layer":"shrub","height_range":[0.6,1.7],"author":"Innerscene"},
 "rose":{"slug":"flowering-rose-bush-a9534324","layer":"shrub","height_range":[0.5,1.5],"author":"Innerscene"},
 "lavender":{"slug":"lavender-bush-6d454088","layer":"shrub","height_range":[0.3,1.2],"author":"Innerscene"},
 "grass":{"slug":"ornamental-grass-clump-feb33ef2","layer":"groundcover","height_range":[0.6,1.6],"author":"Innerscene"},
 "medicinal_wood":{"slug":"hydrangea-flower-with-stem-77d795e6","layer":"independent_spirit_plant","height_range":[0.35,0.75],"author":"Innerscene"},
 "medicinal_fire":{"slug":"rose-flower-with-stem-b2a45a50","layer":"independent_spirit_plant","height_range":[0.3,0.7],"author":"Innerscene"},
 "medicinal_water":{"slug":"lily-flower-with-stem-176a1c74","layer":"independent_spirit_plant","height_range":[0.4,0.75],"author":"Innerscene"}
}
MAX=19_000_000
def fetch(url):
  # The vendor explicitly returned HTTP 429 in GH run 39078571156.
  # Bounded 429/5xx retry only, never bypass license proof or change host.
  for attempt in range(6):
    try:
      with urlopen(Request(url,headers={
          "User-Agent":"Canglan-REV208-HQCC0/1","Accept":"*/*"}),timeout=50) as resp:
        body=resp.read(MAX+1)
        if len(body)>MAX: raise ValueError("asset above verified download limit")
        if resp.geturl().split("/")[2] not in ("www.innerscene.com","innerscene.com"):
          raise ValueError("unexpected redirect host")
        return body
    except HTTPError as exc:
      if exc.code not in (429,500,502,503,504) or attempt==5:
        raise
      delay=min(90.0,5.0*(2**attempt))
      print("REV208_VENDOR_RATE_LIMIT_RETRY",exc.code,"seconds",delay,flush=True)
      time.sleep(delay)
  raise RuntimeError("unreachable")
def glb_stats(b):
  if len(b)<28 or b[:4]!=b"glTF": raise ValueError("not a binary GLTF2 model")
  magic,version,n=struct.unpack_from("<4sII",b,0)
  if version!=2 or n!=len(b): raise ValueError("GLB version/length mismatch")
  size,kind=struct.unpack_from("<I4s",b,12)
  if kind!=b"JSON" or size+20>len(b):raise ValueError("missing GLTF JSON chunk")
  doc=json.loads(b[20:20+size].decode("utf-8").rstrip(" \\x00"))
  acc=doc.get("accessors",[])
  tris=0
  for mesh in doc.get("meshes",[]):
    for prim in mesh.get("primitives",[]):
      if prim.get("mode",4)!=4:continue
      ix=prim.get("indices",None)
      px=prim.get("attributes",{}).get("POSITION",None)
      at=ix if isinstance(ix,int) else px
      if isinstance(at,int) and 0<=at<len(acc):
        tris+=int(acc[at].get("count",0))//3
  if tris<100 or not doc.get("materials"):raise ValueError("no real authored mesh/materials")
  return {"triangle_lod0":tris,"materials":len(doc["materials"]),
          "meshes":len(doc.get("meshes",[])),
          "images":len(doc.get("images",[])),
          "has_nodes":bool(doc.get("nodes"))}
def main(out):
  out=Path(out);out.mkdir(parents=True,exist_ok=True)
  manifest={"schema":1,"revision":208,"art_approval":"PENDING_REAL_GODOT_AND_USER",
    "release_policy":"QUARANTINED_NO_SIGNING_NO_OTA","items":{}}
  old_manifest={}
  if (out/"manifest.json").exists():
    old_manifest=json.loads((out/"manifest.json").read_text(encoding="utf-8")).get("items",{})
  for key,entry in ASSETS.items():
    slug=entry["slug"]
    pinned=old_manifest.get(key,{})
    if (pinned.get("source_name")==slug and pinned.get("license","").startswith("CC0")
        and pinned.get("source_page")==f"{BASE}/tools/library/3d-parts/{slug}"
        and pinned.get("file") and (out/pinned["file"]).is_file()):
      old_data=(out/pinned["file"]).read_bytes()
      if hashlib.sha256(old_data).hexdigest()==pinned.get("original_sha256") and (
          glb_stats(old_data)["triangle_lod0"]==pinned.get("triangle_lod0")):
        manifest["items"][key]=pinned
        print("REV208_REUSE_SOURCE_SHA_AND_LICENSE_ALREADY_PROVEN",key,flush=True)
        continue
    page=f"{BASE}/tools/library/3d-parts/{slug}"
    raw_page=fetch(page).decode("utf-8","replace")
    if not ("Public domain (CC0)" in raw_page and "Free to use" in raw_page):
      raise ValueError(f"CC0 exact-page proof absent: {page}")
    url=f"{BASE}/api/library/{slug}/download"
    data=fetch(url)
    details=glb_stats(data)
    filename=f"hq_{key}_cc0_lod0.glb"
    (out/filename).write_bytes(data)
    digest=hashlib.sha256(data).hexdigest()
    manifest["items"][key]={
      "source_name":slug,"source_author":entry["author"],
      "source_page":page,"source_url_or_asset_id":url,
      "license":"CC0 (exact source page checked at intake)",
      "original_sha256":digest,"converted_sha256":digest,
      "file":filename,"bytes":len(data),"sha256":digest,
      "layer":entry["layer"],"published_height_range_m":entry["height_range"],
      "measured_godot_height_m":"PENDING_GODOT_4_4_1",
      **details,"triangle_lod1":"NOT_PRODUCED","triangle_lod2":"NOT_PRODUCED",
      "texture_resolution":"NOT_MEASURED","material_channels":"SOURCE_GLTF_MATERIALS_UNMODIFIED",
      "collision_type":"NON_INTERACTIVE_BOTANICAL_VISUAL_TRUNK_SIMPLIFIED_FOR_TREES",
      "godot_import_notes":"PENDING_ORIGINAL_MAIN_IMPORT_AND_REAL_RENDER",
      "game_asset_approved":False
    }
    print("REV208_SOURCE_CC0_REAL_GLTF",key,digest,"tris",details["triangle_lod0"],flush=True)
    time.sleep(2.0)
  (out/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
  print("PASS_REV208_CC0_11_PHYSICAL_VENDOR_3D_FOLIAGE_AND_MEDICINAL_SOURCES_NOT_ART_APPROVED")
if __name__=="__main__":
  if len(sys.argv)!=2:raise SystemExit("usage: rev208_intake_cc0_evergreen_understory.py OUT_DIR")
  main(sys.argv[1])
