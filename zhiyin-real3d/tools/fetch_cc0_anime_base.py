#!/usr/bin/env python3
"""Acquire a copyright-reviewed CC0 anime VRM solely as an internal base study.

This is NOT the user's DeepSeek whale-girl, NOT a finished character, and NOT
added to the app's shipped assets. Don't mistake a prettier sample for a custom
model. VRM 0.x metadata is checked in addition to the official pixiv FAQ.
"""
from pathlib import Path
import hashlib,json,struct,urllib.request
ROOT=Path(__file__).resolve().parent.parent
REPO="GY19A/jev-stage"
REV="14168affb0c187441c0fe5fe3e67fbaaa4b6d2cb"
SOURCE=f"https://raw.githubusercontent.com/{REPO}/{REV}/static/vrm/anime_girl.vrm"
DEST=ROOT/"qa_samples"/"anime_cc0_lookdev.vrm"
MAX_LEN=25_000_000

def check(data:bytes):
    if len(data)<20 or data[:4]!=b"glTF":
        raise ValueError("No valid VRM/glTF data")
    _,n=struct.unpack_from("<II",data,4)
    if n!=len(data):raise ValueError("Partial VRM file")
    sz,ctype=struct.unpack_from("<II",data,12)
    if ctype!=0x4e4f534a:raise ValueError("No JSON data chunk")
    gltf=json.loads(data[20:20+sz])
    old=gltf.get("extensions",{}).get("VRM",{})
    newer=gltf.get("extensions",{}).get("VRMC_vrm",{})
    meta=old.get("meta",newer.get("meta",{}))
    rights=str(meta.get("licenseName","")).lower()
    if rights!="cc0":
        raise ValueError("Staging sample's embedded old-beta license is not CC0: "+rights)
    if len(gltf.get("skins",[]))<1 or len(gltf.get("meshes",[]))<2:
        raise ValueError("Not a real rigged avatar")
    if not gltf.get("images") or not gltf.get("materials"):
        raise ValueError("This anime model is missing its hair/face textures")
    print("LOOKDEV_CC0_ANIME_BASE verified",{
        "source":SOURCE,"model_name":meta.get("title") or meta.get("name"),
        "license":rights,"skins":len(gltf["skins"]),
        "meshes":len(gltf["meshes"]),
        "materials":len(gltf["materials"]),
        "images":len(gltf["images"]),
        "blendshapes":len(old.get("blendShapeMaster",{}).get("blendShapeGroups",[]))
    })
def main():
    req=urllib.request.Request(SOURCE,headers={"User-Agent":"ZhiYin-CC0AnimeLookdev/0.1"})
    with urllib.request.urlopen(req,timeout=80) as response:
        data=response.read(MAX_LEN+1)
    if len(data)>MAX_LEN:
        raise ValueError("Anime base exceeds safety size limit")
    check(data)
    DEST.parent.mkdir(parents=True,exist_ok=True)
    DEST.write_bytes(data)
    print("LOOKDEV_BASE_SHA256",hashlib.sha256(data).hexdigest(),"bytes",len(data))
    print("NOT AN OFFICIAL DEEPSEEK CHARACTER; not packaged in the release APK.")
if __name__=="__main__":
    main()
