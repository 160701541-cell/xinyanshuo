#!/usr/bin/env python3
"""Open 3D GLB asset factory: 18 houses, 10 props, 10 role mannequins.

Only original parameterized geometry, no proprietary AI/API/assets.
Build-time Python dependencies: trimesh 4.11.1 MIT, numpy 2.3.5 BSD-3.
The GLBs are ART_UNAPPROVED, not pre-rigged humanoid models.
"""
from __future__ import annotations
import argparse, hashlib, json, math
from pathlib import Path
import numpy as np
import trimesh

COLORS={
 "plaster":(211,203,180,255),"roof":(68,91,98,255),
 "tiles":(124,142,144,255),"wood":(95,67,47,255),
 "stone":(141,143,135,255),"paper":(202,185,151,255),
 "leaves":(87,132,81,255),"robe":(81,114,111,255),
 "skin":(198,157,127,255),"hair":(44,40,37,255)
}
def add(scene,name,geom,color):
    geom.visual.vertex_colors=np.tile(COLORS[color],(len(geom.vertices),1))
    scene.add_geometry(geom,geom_name=name,node_name=name)
def box(scene,name,pos,size,color):
    g=trimesh.creation.box(extents=size)
    g.apply_translation(pos)
    add(scene,name,g,color)
def cylinder(scene,name,at,radius,height,color,segments=9):
    g=trimesh.creation.cylinder(radius=radius,height=height,sections=segments)
    g.apply_translation(at)
    add(scene,name,g,color)
def roof(scene,name,w,d,eave,ridge):
    ex=w*0.5+0.6;ez=d*0.5+0.7
    verts=np.array([[-ex,eave,-ez],[ex,eave,-ez],[-ex,ridge,0],[ex,ridge,0],
       [-ex,eave,ez],[ex,eave,ez]],float)
    g=trimesh.Trimesh(vertices=verts,faces=[[0,1,3],[0,3,2],[2,3,5],[2,5,4]],process=False)
    add(scene,name,g,"roof")
    box(scene,name+"_ridge",(0,ridge+0.1,0),(w+1.4,0.24,0.36),"tiles")
    for side in (-1,1):
        box(scene,f"{name}_eave_{side}",(0,eave-0.1,side*ez),(w+1.3,0.19,0.27),"tiles")
        for row in range(10):
            x=-ex+0.25+row*2*(ex-0.25)/9
            for j in range(5):
                t=(j+0.5)/5
                box(scene,f"{name}_tile_{side}_{row}_{j}",
                    (x,ridge+(eave-ridge)*t+0.04,side*ez*t),
                    (0.07,0.08,ez/6),"tiles")
def house(kind,variant):
    s=trimesh.Scene()
    w=8.1+variant*0.65+(2.3 if kind in ("inn","academy","temple") else 0)
    d=6.4+variant*0.42
    h=4.0+(1.0 if kind in ("inn","academy","temple") else 0)
    box(s,"stone_footprint",(0,0.16,0),(w+0.6,0.33,d+0.7),"stone")
    box(s,"rear_wall",(0,h*0.5,-d*0.5),(w,h,0.30),"plaster")
    for side in (-1,1):
        box(s,f"side_wall_{side}",(side*w/2,h/2,0),(0.3,h,d),"plaster")
        box(s,f"entry_wall_{side}",(side*(w+2.6)/4,h/2,d/2),
            ((w-2.6)/2,h,0.29),"plaster")
        for z in (-d/2,d/2):
            box(s,f"pillar_{side}_{z}",(side*w/2,h/2,z),(0.36,h,0.37),"wood")
        x=side*(w/2-1.5)
        box(s,f"window_{side}",(x,2.1,d/2+0.19),(1.52,1.48,0.17),"paper")
        for ix in (-1,0,1):
            box(s,f"lattice_{side}_{ix}",(x+ix*0.44,2.1,d/2+0.33),
                (0.065,1.48,0.08),"wood")
    # Door leaves are runtime-hinged independent entities in building_factory.gd,
    # never baked shut into the imported static GLB geometry.
    box(s,"door_beam",(0,h-0.31,d/2+0.24),(3.1,0.4,0.38),"wood")
    roof(s,"Han_Ceramic_Roof",w,d,h+0.22,h+1.9)
    return s
def prop(kind,variant):
    s=trimesh.Scene()
    if kind=="tree":
        cylinder(s,"trunk",(0,1.7,0),0.27,3.4,"wood")
        for i in range(5):
            ang=i*2.39
            g=trimesh.creation.icosphere(subdivisions=1,radius=1.15+0.13*variant)
            g.apply_translation((math.cos(ang)*0.85,3.6+(i%3)*0.5,math.sin(ang)*0.85))
            add(s,f"foliage_{i}",g,"leaves")
    elif kind=="bamboo":
        for i in range(7):
            cylinder(s,f"bamboo_{i}",((i-3)*0.32,1.5+0.05*i,0),0.05,3.0+0.1*i,"leaves")
    elif kind=="well":
        g=trimesh.creation.annulus(r_min=0.7,r_max=1.12,height=0.7,sections=16)
        g.apply_translation((0,0.4,0))
        add(s,"stone_ring",g,"stone")
        for side in (-1,1):
            box(s,f"well_post_{side}",(side*1.0,1.4,0),(0.21,2.8,0.21),"wood")
        box(s,"cross_winch",(0,2.67,0),(2.25,0.21,0.23),"wood")
    elif kind=="lantern":
        box(s,"lamp_post",(0,2.0,0),(0.13,4.0,0.13),"wood")
        box(s,"lamp_shade",(0,3.18,0),(0.62,0.8,0.62),"paper")
        box(s,"lamp_roof",(0,3.66,0),(0.8,0.16,0.8),"wood")
    elif kind=="cart":
        box(s,"carriage",(0,1.2,0),(2.7,0.54,1.8),"wood")
        for side in (-1,1):
            for front in (-1,1):
                cylinder(s,f"wheel_{side}_{front}",(side*1.05,0.7,front*1.07),
                    0.52,0.19,"wood")
        box(s,"pull_bar",(0,0.8,2.1),(0.14,0.14,2.5),"wood")
    elif kind=="gate":
        for side in (-1,1):
            box(s,f"gate_post_{side}",(side*1.8,1.6,0),(0.42,3.2,0.42),"stone")
        box(s,"gate_lintel",(0,3.45,0),(4.5,0.40,0.55),"wood")
        roof(s,"gate_tiled_eaves",4.1,1.6,3.65,4.14)
    else:
        mat="wood" if kind in ("barrel","stall") else "stone"
        box(s,f"{kind}_body",(0,0.68,0),(2.2,1.35,1.1),mat)
        if kind=="stall":
            box(s,"market_awning",(0,2.7,0),(3.4,0.25,1.8),"paper")
    return s
def role_mesh(role):
    s=trimesh.Scene()
    # Ten different roles share a human scale but not an identical dress silhouette.
    garment=[(81,114,111,255),(147,111,74,255),(101,104,107,255),
             (112,92,71,255),(125,137,103,255),(84,113,146,255),
             (81,93,93,255),(144,131,102,255),(106,122,149,255),
             (162,112,87,255)][role]
    robes=trimesh.creation.cylinder(radius=0.34+0.015*(role%3),height=1.12,
                                     sections=10)
    robes.apply_translation((0,1.28,0))
    robes.visual.vertex_colors=np.tile(garment,(len(robes.vertices),1))
    s.add_geometry(robes,geom_name="independent_role_robe",
                   node_name="independent_role_robe")
    g=trimesh.creation.icosphere(subdivisions=2,radius=0.25)
    g.apply_translation((0,2.12,0))
    add(s,"face",g,"skin")
    box(s,"cap",(0,2.37+role%3*0.04,0),
        (0.4+role%3*0.12,0.13,0.4),"hair")
    if role in (1,5,8):
        box(s,"traveller_scroll_or_ledger",(0.55,1.12,0.23),(0.33,0.5,0.17),"paper")
    if role in (0,3):
        box(s,"worker_tool_pouch",(-0.4,0.83,0.12),(0.3,0.33,0.22),"wood")
    if role == 6:
        box(s,"guard_chest_armor",(0,1.42,0.3),(0.67,0.62,0.21),"stone")
    for side in (-1,1):
        cylinder(s,f"arm_{side}",(side*0.45,1.34,0),0.11,0.85,"robe")
        cylinder(s,f"leg_{side}",(side*0.19,0.36,0),0.12,0.72,"wood")
    return s
def generate(out:Path,seed:int=20261016):
    out.mkdir(parents=True,exist_ok=True)
    tasks=[]
    for kind in ("home","farmhouse","shop","teahouse","inn","academy","temple","granary","workshop"):
        for i in (0,1):
            tasks.append((f"architecture/{kind}_{i}.glb",house(kind,i)))
    for kind in ("tree","well","lantern","cart","bamboo","barrel","stall","gate"):
        for i in (range(3) if kind=="tree" else range(1)):
            tasks.append((f"props/{kind}_{i}.glb",prop(kind,i)))
    for i in range(10):
        tasks.append((f"npc/role_{i:02d}.glb",role_mesh(i)))
    manifest={"schema":1,"seed":seed,"status":"CANDIDATE_NOT_ART_APPROVED","count":len(tasks),"models":[]}
    for rel,scene in tasks:
        path=out/rel
        path.parent.mkdir(parents=True,exist_ok=True)
        # Merge baked static parts into one vertex-colored GLB mesh.
        # Thousands of tiny tile meshes as separate Godot nodes would be
        # catastrophic for Android draw-call budgets.
        combined = trimesh.util.concatenate(list(scene.dump()))
        assert combined.vertices.shape[0] > 20
        compact_scene = trimesh.Scene(combined)
        data=compact_scene.export(file_type="glb")
        assert data[:4]==b"glTF" and len(data)>400
        path.write_bytes(data)
        bounds=compact_scene.bounds
        assert np.isfinite(bounds).all()
        manifest["models"].append({"path":rel,"sha256":hashlib.sha256(data).hexdigest(),
            "bytes":len(data),"bounds":[list(map(float,bounds[0])),list(map(float,bounds[1]))]})
    (out/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    return manifest
if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--seed",type=int,default=20261016)
    args=p.parse_args()
    print("PASS_PUBLIC_PROCEDURAL_GLB_GENERATOR",generate(args.out,args.seed)["count"])
