#!/usr/bin/env python3
"""Recolor the ORIGINAL real anime VRM hair/iris texture atlas instead of adding
fake geometric eyes/hair. This is internal lookdev, not a finished DeepSeek NPC.
Preserves CC0 author/licence metadata, 103-bone rig, face morphs and UVs.
"""
import hashlib, io, json, struct, sys
from pathlib import Path
import numpy as np
from PIL import Image

JSON_TYPE=0x4E4F534A
BIN_TYPE=0x004E4942

def parse(raw):
    if raw[:4]!=b"glTF" or struct.unpack_from("<I",raw,8)[0]!=len(raw):
        raise ValueError("Invalid source GLB")
    pos=12;parts={}
    while pos<len(raw):
        n,t=struct.unpack_from("<II",raw,pos);pos+=8
        if pos+n>len(raw):raise ValueError("Truncated GLB")
        parts[t]=raw[pos:pos+n];pos+=n
    return json.loads(parts[JSON_TYPE]),parts[BIN_TYPE]

def gradient_hair(image):
    rgba=np.array(image.convert("RGBA"),dtype=np.uint8)
    src=rgba[:,:,:3].astype(np.float32)
    y=np.linspace(0,1,rgba.shape[0],dtype=np.float32)[:,None,None]
    root=np.array([31.,53.,132.],dtype=np.float32)
    tip=np.array([91.,169.,228.],dtype=np.float32)
    t=.11+.86*np.power(y,.83)
    base=root*(1-t)+tip*t
    brightness=(src[:,:,0]*.2126+src[:,:,1]*.7152+src[:,:,2]*.0722)/255.
    scale=np.clip(.58+.61*brightness,.58,1.25)[:,:,None]
    rgba[:,:,:3]=np.clip(base*scale,0,255).astype(np.uint8)
    return Image.fromarray(rgba,"RGBA")

def iris_blue(image):
    rgba=np.array(image.convert("RGBA"),dtype=np.uint8)
    src=rgba[:,:,:3].astype(np.float32)
    r,g,b=src[:,:,0],src[:,:,1],src[:,:,2]
    mask=(r>g*1.08)&(r>b*1.11)&(r>38)&(rgba[:,:,3]>0)
    value=np.maximum(np.max(src,axis=2),1.)
    target=np.stack([value*.19,value*.46,value*.87],axis=2)
    rgba[:,:,:3][mask]=np.clip(target,0,255).astype(np.uint8)[mask]
    return Image.fromarray(rgba,"RGBA")

def make(source,target):
    j,bin_orig=parse(Path(source).read_bytes())
    rights=j.get("extensions",{}).get("VRM",{}).get("meta",{}).get("licenseName")
    if str(rights).upper()!="CC0":
        raise ValueError("No CC0 rights in embedded source model")
    hairs={i for i,im in enumerate(j["images"]) if
        "Hair_" in im.get("name","") and
        not im.get("name","").lower().endswith(("_nml","_spe"))}
    eyes={i for i,im in enumerate(j["images"]) if "EyeIris_" in im.get("name","")}
    if len(hairs)<4 or not eyes:
        raise ValueError("Real independent anime hair/iris UV maps not found")
    body=bytearray(bin_orig)
    result=[]
    for i in sorted(hairs|eyes):
        im=j["images"][i]
        bv=j["bufferViews"][im["bufferView"]]
        a=bv.get("byteOffset",0);b=bv["byteLength"]
        image=Image.open(io.BytesIO(bin_orig[a:a+b]))
        image=gradient_hair(image) if i in hairs else iris_blue(image)
        stream=io.BytesIO();image.save(stream,format="PNG",optimize=True)
        png=stream.getvalue()
        offset=len(body);body.extend(png);body.extend(b"\0"*((-len(body))%4))
        im["bufferView"]=len(j["bufferViews"])
        im["mimeType"]="image/png"
        j["bufferViews"].append({"buffer":0,"byteOffset":offset,"byteLength":len(png)})
        result.append((i,im.get("name",""),len(png)))
    for i,m in enumerate(j.get("materials",[])):
        name=m.get("name","").lower()
        if "hair" not in name and "eyeiris" not in name:continue
        m.setdefault("pbrMetallicRoughness",{})["baseColorFactor"]=[1,1,1,1]
        props=j["extensions"]["VRM"]["materialProperties"][i].setdefault("vectorProperties",{})
        props["_Color"]=[1,1,1,1]
        props["_ShadeColor"]=[.27,.40,.73,1.] if "hair" in name else [.28,.48,.88,1.]
    j["buffers"][0]["byteLength"]=len(body)
    json_bytes=json.dumps(j,ensure_ascii=False,separators=(",",":")).encode("utf-8")
    json_bytes+=b" "*((-len(json_bytes))%4)
    bin_bytes=bytes(body);bin_bytes+=b"\0"*((-len(bin_bytes))%4)
    size=12+8+len(json_bytes)+8+len(bin_bytes)
    output=struct.pack("<4sII",b"glTF",2,size)+struct.pack("<II",len(json_bytes),JSON_TYPE)+json_bytes+struct.pack("<II",len(bin_bytes),BIN_TYPE)+bin_bytes
    Path(target).parent.mkdir(parents=True,exist_ok=True)
    Path(target).write_bytes(output)
    print("REAL_UV_BLUE_ANIME_LOOKDEV",len(output),"sha256",hashlib.sha256(output).hexdigest(),"maps",result)
    print("NOT DEEPSEEK REFERENCE FAITHFUL. Real facial mesh/rig/UV preserved.")
if __name__=="__main__":
    if len(sys.argv)!=3:raise SystemExit("usage: recolor_vrm_anime.py source.vrm target.vrm")
    make(sys.argv[1],sys.argv[2])
