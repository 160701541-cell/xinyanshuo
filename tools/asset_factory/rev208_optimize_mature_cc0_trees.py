#!/usr/bin/env python3
"""Combine 625 separately authored GLB nodes into 4 original-material meshes.
Preserves original vertex geometry, normals, UV and vendor PBR color factors.
P0 HQ: actual SHA-pinned original CC0 trees, no procedural low-poly cylinders.
"""
import hashlib
import io
import json
import sys
from pathlib import Path
from urllib.request import Request,urlopen
import numpy as np
import trimesh
from rev208_intake_real_mature_cc0_trees import parse_glb, SOURCE_PAGES

SOURCES={
 "oak":{"url":"https://www.innerscene.com/api/library/oak-street-tree-detailed-leaves-a273fef9/download",
        "sha256":"a02698ef246d8005110c291c510b8f7f397ae26e69414aa538cc4993b06256dd","height_m":8.6059,"triangles":213372},
 "maple":{"url":"https://www.innerscene.com/api/library/maple-street-tree-detailed-leaves-006cddf4/download",
        "sha256":"089aa5e0ce4bfa83c281c2f66808dd69ebab899f227bedaf8a1d379034ac56ce","height_m":9.5,"triangles":175572},
 "linden":{"url":"https://www.innerscene.com/api/library/linden-street-tree-detailed-leaves-6300c26e/download",
        "sha256":"a43ce066178c88c024e9cafa05a9ebbd6eba70dd1a7586f9bf25b85e187137a9","height_m":8.8,"triangles":137772},
}
def get_source(k,meta):
 req=Request(meta["url"],headers={"User-Agent":"CanglanHQCC0TreeProduction/1"})
 with urlopen(req,timeout=60) as res:
  raw=res.read(18_000_001)
 if len(raw)>18_000_000 or hashlib.sha256(raw).hexdigest()!=meta["sha256"]:
  raise ValueError("Source SHA mismatch or exceeds 18 MB: "+k)
 actual=parse_glb(raw)
 if actual["triangles"]!=meta["triangles"]:
  raise ValueError("Source triangle baseline mismatch: "+k)
 return raw,actual
def collapse(raw):
 scene=trimesh.load(io.BytesIO(raw),file_type="glb",force="scene")
 groups={}
 for node in scene.graph.nodes_geometry:
  transform,geom_name=scene.graph.get(node)
  geom=scene.geometry[geom_name].copy()
  geom.apply_transform(transform)
  material=getattr(geom.visual,"material",None)
  if material is None: raise ValueError("Untextured source node")
  color=tuple(int(v) for v in getattr(material,"baseColorFactor",[]))
  key=(str(getattr(material,"name","")),color)
  groups.setdefault(key,[]).append(geom)
 if len(groups)!=4:
  raise ValueError("Expected exactly 4 vendor bark+leaf PBR color materials, got "+str(len(groups)))
 merged=trimesh.Scene()
 for index,models in enumerate(groups.values()):
  geom=trimesh.util.concatenate(models)
  if len(geom.faces)<1000:raise ValueError("Unexpected empty PBR source part")
  merged.add_geometry(geom,geom_name="Original_CC0_PBR_Mat_%d"%index)
 raw2=merged.export(file_type="glb")
 before=parse_glb(raw)
 after=parse_glb(raw2)
 if after["triangles"]!=before["triangles"] or after["mesh_parts"]!=4 or after["materials"]!=4:
  raise ValueError("Conversion geometry/material count drift source="+str(before)+" converted="+str(after)+" bucket_keys="+str(list(groups.keys())))
 if not np.allclose(merged.bounds,scene.bounds,rtol=0,atol=0.012):
  raise ValueError("Conversion displaced physical tree dimensions")
 return raw2,after,float(merged.extents[1])
def main(out):
 dest=Path(out);dest.mkdir(parents=True,exist_ok=True)
 manifest={"schema":1,"release_policy":"CANDIDATE_SOURCE_NOT_OTA_NOT_PHONE_PASSED",
   "provider":"Innerscene original CC0 glTF (specific per-model page)",
   "converter":"trimesh 4.x transform bake+merge by exact PBR source material",
   "art_approval":"PENDING_REAL_GODOT_AND_USER",
   "items":{}}
 for k,meta in SOURCES.items():
  original,source_stats=get_source(k,meta)
  derived,stats,height=collapse(original)
  name="mature_"+k+"_hq_lod0.glb"
  (dest/name).write_bytes(derived)
  manifest["items"][k]={
    "source_name":k+"_cc0_mature_detailed_source.glb",
    "source_author":"Innerscene - original model",
    "source_page":"https://www.innerscene.com/tools/library/3d-parts/"+SOURCE_PAGES[k][0],
    "source_url_or_asset_id":meta["url"],"license":"CC0 source page individually verified",
    "original_sha256":meta["sha256"],"converted_sha256":hashlib.sha256(derived).hexdigest(),
    "source_triangles":source_stats["triangles"],
    "triangle_lod0":stats["triangles"],"triangle_lod1":"NOT_PRODUCED",
    "triangle_lod2":"NOT_PRODUCED","texture_resolution":"no image textures; original 4 PBR color materials",
    "material_channels":"original PBR baseColorFactors, not scanned normal/bark texture",
    "collision_type":"simple trunk cylinder existing natural resource",
    "godot_import_notes":"PENDING real original APK176 4.4.1 GLB parse and visible frame",
    "source_height_m":round(height,3),"render_meshes":stats["mesh_parts"],
    "file":name,"bytes":len(derived),"sha256":hashlib.sha256(derived).hexdigest(),
    "game_asset_approved":False}
  print("SOURCE_MATURE_TREE_MERGED",k,stats["triangles"],
    "tris",stats["mesh_parts"],"mesh_parts",round(height,2),"meters",len(derived),"bytes")
 (dest/"manifest.json").write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+"\n",encoding="utf8")
 print("PASS_REV208_REAL_3_CC0_MATURE_TREES_MERGED_PBR_AUTHORED_GLTF_NO_ASSET_LOSS")
if __name__=="__main__":
 if len(sys.argv)!=2: raise SystemExit("Usage: ... OUTPUT_DIR")
 main(sys.argv[1])
