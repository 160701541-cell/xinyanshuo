#!/usr/bin/env python3
"""Actual exported GLB test, not a model request count or mock dataset."""
import argparse, hashlib, json, pathlib, struct
import trimesh

def inspect(root: pathlib.Path):
    meta=json.loads((root/"manifest.json").read_text("utf-8"))
    assert meta["schema"]==1 and meta["count"]==38
    assert meta["status"]=="CANDIDATE_NOT_ART_APPROVED"
    names=set()
    categories={"architecture":0,"props":0,"npc":0}
    for row in meta["models"]:
        name=row["path"]
        assert name not in names and "/" in name and ".." not in name
        names.add(name)
        category=name.split("/")[0]
        assert category in categories
        categories[category]+=1
        data=(root/name).read_bytes()
        assert data[:4]==b"glTF" and len(data)==row["bytes"]
        assert struct.unpack_from("<I",data,8)[0]==len(data)
        assert hashlib.sha256(data).hexdigest()==row["sha256"]
        scene=trimesh.load(root/name,force="scene")
        assert len(scene.geometry)>=1 and scene.bounds is not None
        assert all(v>0 for v in scene.extents)
    assert categories=={"architecture":18,"props":10,"npc":10},categories
    return {"status":"PASS_GLTF_BYTES","counts":categories,"models":len(names),
            "visual_qa":"PENDING","rigging":"NOT_RIGGED",
            "original_signed_game_updated":False}

if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("--root",type=pathlib.Path,required=True)
    print(json.dumps(inspect(p.parse_args().root),ensure_ascii=False))
