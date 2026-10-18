#!/usr/bin/env python3
"""REV208 P0 physical CC0 mature-tree candidate intake; rejects missing real GLB.
Never passes a screenshot for 3D geometry, never publishes to an installed phone.
"""
import hashlib
import html
import json
import re
import struct
import sys
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

SOURCE_PAGES = {
  "oak": ("oak-street-tree-detailed-leaves-a273fef9", "8.6m", "5.9MB"),
  "maple": ("maple-street-tree-detailed-leaves-006cddf4", "9.5m", "4.6MB"),
  "linden": ("linden-street-tree-detailed-leaves-6300c26e", "8.8m", "3.7MB"),
}
DOMAIN = "https://www.innerscene.com/tools/library/3d-parts/"
AGENT = "CanglanCC0AssetIntake/2026-10-18 (+open-source xinyanshuo)"
MAX_BYTES = 18_000_000

class Links(HTMLParser):
  def __init__(self):
    super().__init__()
    self.items = []
    self._href = None
    self._label = []
  def handle_starttag(self,tag,attrs):
    a=dict(attrs)
    if tag=="a":
      self._href=a.get("href")
      self._label=[]
  def handle_data(self,data):
    if self._href:self._label.append(data)
  def handle_endtag(self,tag):
    if tag=="a" and self._href:
      self.items.append((self._href,"".join(self._label)))
      self._href=None
def request(url):
  u=urllib.request.Request(url,headers={"User-Agent":AGENT,"Accept":"*/*"})
  with urllib.request.urlopen(u,timeout=40) as res:
    return res.read(MAX_BYTES+1),res.geturl(),res.headers.get("Content-Type","")
def candidates(page,body):
  text=body.decode("utf8","replace")
  parser=Links();parser.feed(text)
  urls=[]
  for href,label in parser.items:
    if any(key in (href+" "+label).lower() for key in ["download","\.glb",".glb"]):
      urls.append(urllib.parse.urljoin(page,html.unescape(href)))
  # Next.js and similar static builds often put the signed GLB asset in JSON.
  for val in re.findall(r'(?:https?[^\s"<>\\]+|/[^\s"<>\\]+)\.glb(?:\?[^\s"<>\\]*)?',text,re.I):
    urls.append(urllib.parse.urljoin(page,html.unescape(val)))
  # Restrict URL shapes before any attempts: do not crawl arbitrary domains.
  kept=[]
  for url in urls:
    u=urllib.parse.urlsplit(url)
    if u.scheme=="https" and url not in kept and len(url)<3000:
      kept.append(url)
  return kept
def parse_glb(data):
  if len(data)<28 or data[:4]!=b"glTF":
    raise ValueError("not a genuine glTF2 binary")
  magic,version,size=struct.unpack_from("<4sII",data,0)
  if version!=2 or size!=len(data):
    raise ValueError("glTF 2 length mismatch")
  chunk_len,kind=struct.unpack_from("<I4s",data,12)
  if kind!=b"JSON" or 20+chunk_len>len(data):
    raise ValueError("glTF JSON chunk missing")
  obj=json.loads(data[20:20+chunk_len].decode("utf8").rstrip(" \x00"))
  acc=obj.get("accessors",[])
  tris=0
  for mesh in obj.get("meshes",[]):
    for prim in mesh.get("primitives",[]):
      if prim.get("mode",4)!=4: continue
      idx=prim.get("indices")
      if isinstance(idx,int) and 0<=idx<len(acc): tris+=int(acc[idx]["count"])//3
      else:
        pos=prim.get("attributes",{}).get("POSITION")
        if isinstance(pos,int) and 0<=pos<len(acc):tris+=int(acc[pos]["count"])//3
  if tris<12_000:
    raise ValueError("too few triangles for genuine near-camera mature-tree candidate")
  return {"mesh_parts":len(obj.get("meshes",[])),"triangles":tris,
     "materials":len(obj.get("materials",[])),"images":len(obj.get("images",[])),
     "animations":len(obj.get("animations",[])),"skins":len(obj.get("skins",[]))}
def main(folder):
  root=Path(folder);root.mkdir(parents=True,exist_ok=True)
  results={}
  for kind,(slug,published_height,published_bytes) in SOURCE_PAGES.items():
    page=DOMAIN+slug
    result={"source_page":page,"source_provider":"Innerscene original CC0",
       "license_claim":"CC0 1.0 on exact source model page, license review mandatory",
       "published_height_description":published_height,
       "published_size_description":published_bytes,
       "status":"SOURCE_NOT_DOWNLOADED_UNAPPROVED"}
    results[kind]=result
    try:
      page_bytes,_,_=request(page)
      decoded=page_bytes.decode("utf8","replace")
      if not re.search(r'(CC0|public domain)',decoded,re.I):
        raise ValueError("source page did NOT assert CC0/public-domain status")
      links=candidates(page,page_bytes)
      result["candidate_links_found"]=len(links)
      print("SOURCE_WEB_EVIDENCE",kind,"CC0",len(links),"links")
      found=False
      for url in links[:12]:
        try:
          b,actual_url,ct=request(url)
          if len(b)>MAX_BYTES:continue
          info=parse_glb(b)
          name=kind+"_cc0_mature_detailed_source.glb"
          (root/name).write_bytes(b)
          result.update({"status":"REAL_GLTF2_VALID_UNAPPROVED_GODOT",
             "file":name,"source_download_url":actual_url,
             "bytes":len(b),"sha256":hashlib.sha256(b).hexdigest(),
             "measured_glb_geometry":info,
             "android_import":"PENDING_REAL_GODOT_4_4_1",
             "lod":"PENDING_SOURCE_TO_ANDROID_OPTIMIZATION",
             "visual_approval":"PENDING_USER"})
          print("REAL_MATURE_TREE_SOURCE",kind,info["triangles"],"triangles",len(b),"bytes")
          found=True;break
        except Exception as e:
          print("CANDIDATE_NOT_GLTF",kind,type(e).__name__,str(e)[:180])
      if not found:raise ValueError("no downloadable verifiable GLTF2 found on exact source page")
    except Exception as e:
      result["blocker"]=type(e).__name__+": "+str(e)[:300]
      print("BLOCKED_LICENSED_TREE_SOURCE",kind,result["blocker"])
    (root/(kind+".json")).write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
  (root/"intake_manifest.json").write_text(json.dumps(
     {"schema":1,"revision":208,"status":"GLB_SOURCE_ONLY_NOT_APPROVED",
      "models":results,"game_assets_imported":False,"published_to_android":False},
     indent=2,ensure_ascii=False)+"\n")
  passed=sum(x["status"]=="REAL_GLTF2_VALID_UNAPPROVED_GODOT" for x in results.values())
  print("SOURCE_INTENDED_3_MATURE_TREES_REAL_GLTF_DOWNLOADED",passed)
  if passed<3:
    raise SystemExit("P0 HQ TREE INTAKE BLOCKED: evidence saved, do not publish fake glTF")
if __name__=="__main__":
  if len(sys.argv)!=2: raise SystemExit("Usage: rev208_intake_real_mature_cc0_trees.py OUTPUT_DIR")
  main(sys.argv[1])
