#!/usr/bin/env python3
"""Production gate for ZhiYin's reference-faithful custom anime avatar.

This cannot judge likeness automatically. Passing means the editable 3D file
contains essential authored meshes, VRM humanoid, facial expressions and
textures. A separate HUMAN art review using front/side/back actual in-engine
screenshots remains mandatory for release.
"""
from __future__ import annotations
import json
import struct
import sys
from pathlib import Path

BLUE_REQUIRED = {
    "hair":"hair",
    "whale side fins":"fin",
    "whale tail":"tail",
    "frilled headband":"headband",
    "blue-white maid outfit":"dress",
    "white apron":"apron",
    "hair bows":"bow",
    "eye materials":"eye",
}
EXPR_GROUPS = {
    "blink": {"blink","blinkleft","blinkright"},
    "joy": {"happy","smile","joy"},
    "angry pout": {"angry","pout","fun"},
    "open-mouth vowel A": {"aa","a"},
    "open-mouth vowel E": {"ee","e"},
    "open-mouth vowel I": {"ih","i"},
    "open-mouth vowel O": {"oh","o"},
    "open-mouth vowel U": {"ou","u"},
}

def read_glb(path:Path)->dict:
    raw=path.read_bytes()
    if len(raw)<24 or raw[:4]!=b"glTF":
        raise ValueError("Expected a binary glTF / .vrm file")
    version,total=struct.unpack_from("<II",raw,4)
    if version!=2 or total!=len(raw):
        raise ValueError("GLB version or byte count incorrect")
    offset=12
    while offset+8<=len(raw):
        count,chunk_type=struct.unpack_from("<II",raw,offset)
        offset+=8
        if count<0 or offset+count>len(raw):
            raise ValueError("Truncated GLB data")
        if chunk_type==0x4e4f534a:
            return json.loads(raw[offset:offset+count].decode("utf-8"))
        offset+=count
    raise ValueError("No glTF JSON chunk")

def verify(path:Path,who:str="npc_deepseek_blue")->dict:
    if not path.is_file():
        raise FileNotFoundError("Missing authored character model: "+str(path))
    j=read_glb(path)
    ex=j.get("extensions",{})
    vrm=ex.get("VRMC_vrm") or ex.get("VRM")
    if not vrm:
        raise ValueError("Not a VRM humanoid. A renamed generic GLB is not enough.")
    skins=j.get("skins",[])
    joint_count=max((len(s.get("joints",[])) for s in skins),default=0)
    if joint_count<45:
        raise ValueError("Humanoid must contain at least 45 usable joints")
    meshes=j.get("meshes",[])
    if len(meshes)<6:
        raise ValueError("Insufficient separately authored clothing, hair and face meshes")
    materials=j.get("materials",[])
    textures=j.get("textures",[])
    if len(materials)<6 or len(textures)<5:
        raise ValueError("Anime skin/eyes/hair/dress/tail require actual texture materials")
    names=" ".join((str(n.get("name","")) for n in j.get("nodes",[])))+" "+ " ".join(str(m.get("name","")) for m in meshes)
    lower=names.lower().replace(" ","").replace("_","")
    missing=[label for label,needle in BLUE_REQUIRED.items() if needle.replace("_","") not in lower]
    if who=="npc_deepseek_blue" and missing:
        raise ValueError("Missing authored whale-girl assets: "+", ".join(missing))
    # This catches empty expressions which are only named but cannot deform meshes.
    expressions=(vrm.get("expressions") or {})
    preset=expressions.get("preset") or {}
    custom=expressions.get("custom") or {}
    all_expr={str(x).lower():v for x,v in dict(preset,**custom).items()}
    def real(name):
        props=all_expr.get(name,{})
        return bool(props.get("morphTargetBinds") or props.get("binds"))
    missing_expr=[]
    for category,candidates in EXPR_GROUPS.items():
        if not any(real(n) for n in candidates):
            missing_expr.append(category)
    if missing_expr:
        raise ValueError("No actual morph binds for: "+", ".join(missing_expr))
    nonempty_shapes=sum(bool(p.get("targets")) for m in meshes for p in m.get("primitives",[]))
    if nonempty_shapes<1:
        raise ValueError("Expressions cannot be driven: meshes contain no blend shapes")
    meta=vrm.get("meta",{})
    if who=="npc_deepseek_blue" and not any(w in str(meta.get("name","")).lower() for w in ("deepseek","鲸","blue")):
        raise ValueError("VRM metadata must identify the intended blue character, not the generic base")
    return {"name":meta.get("name",""),"humanoid_bones":joint_count,
            "mesh_parts":len(meshes),"materials":len(materials),"textures":len(textures),
            "bound_expression_categories":list(EXPR_GROUPS),
            "has_whale_parts":who=="npc_deepseek_blue",
            "warning":"Structural only. Human visual reference review still required."}

if __name__=="__main__":
    if len(sys.argv)<2:
        raise SystemExit("usage: verify_avatar_asset.py path/to/deepseek_blue.vrm")
    try:
        report=verify(Path(sys.argv[1]))
        print(json.dumps(report,indent=2,ensure_ascii=False))
        print("STRUCTURAL PASS ONLY -- visual fidelity and in-game motion not yet verified")
    except Exception as exc:
        print("P0 REJECT:",type(exc).__name__,str(exc))
        raise SystemExit(2)
