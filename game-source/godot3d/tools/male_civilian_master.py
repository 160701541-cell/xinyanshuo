#!/usr/bin/env python3
"""CAC-MALE-001: shared low-poly civilian male master and muted occupation variants.

Geometry is original, parameterized, +Y up, +Z forward. Not skinned.
All roles derive from a single body layout and stable attach landmarks.
"""
from __future__ import annotations
import argparse, hashlib, json, math
from pathlib import Path
import numpy as np
import trimesh

PALETTES = {
 "villager": dict(cloth="#8a9a93", undercollar="#d6d5c9", sleeve="#83938a", hem="#87948b", apron="#aab4ac", belt="#726d5f", trouser="#706f66", shoe="#494d49", accent="#807564"),
 "merchant": dict(cloth="#849cb0", undercollar="#e1ddd1", sleeve="#819bb2", hem="#788fa2", apron="#abb6b5", belt="#998974", trouser="#877e71", shoe="#54514b", accent="#a18c72"),
 "apprentice": dict(cloth="#ae8780", undercollar="#dfd3c2", sleeve="#aa837e", hem="#9c7f75", apron="#9a9d96", belt="#796b61", trouser="#737c80", shoe="#555957", accent="#91877d"),
 "guard": dict(cloth="#667a76", undercollar="#d8d0bf", sleeve="#647672", hem="#5e6b65", apron="#8f9790", belt="#615d50", trouser="#67716e", shoe="#464b47", accent="#595d56"),
 "scholar": dict(cloth="#a0aba3", undercollar="#e5e2d5", sleeve="#9ca99f", hem="#99a29c", apron="#b9bfaf", belt="#8b8273", trouser="#8b8980", shoe="#5a5853", accent="#9b9487"),
}
SKIN = "#d2b49d"
HAIR = "#49433e"
FACE = "#685c50"
LANDMARKS = {
 "root":(0,0,0),"hips":(0,1.05,0),"spine":(0,1.33,0),"chest":(0,1.58,0),
 "neck":(0,1.81,0),"head":(0,2.12,0),
 "shoulder_l":(-.445,1.66,0),"elbow_l":(-.62,1.3,.01),"wrist_l":(-.7,.99,.03),
 "shoulder_r":(.445,1.66,0),"elbow_r":(.62,1.3,.01),"wrist_r":(.7,.99,.03),
 "knee_l":(-.205,.51,0),"ankle_l":(-.205,.15,0),
 "knee_r":(.205,.51,0),"ankle_r":(.205,.15,0),
}

def rgb(v):
    v=v.lstrip("#")
    return np.array([int(v[i:i+2],16) for i in (0,2,4)]+[255],dtype=np.uint8)

def add(scene,name,geometry,tint):
    assert len(geometry.vertices)>=4 and len(geometry.faces)>0
    geometry.visual.vertex_colors=np.tile(rgb(tint),(len(geometry.vertices),1))
    scene.add_geometry(geometry,geom_name=name,node_name=name)

def box(scene,name,at,size,tint):
    g=trimesh.creation.box(extents=size)
    g.apply_translation(at)
    add(scene,name,g,tint)

def orb(scene,name,at,size,tint,subdivisions=1):
    g=trimesh.creation.icosphere(subdivisions=subdivisions,radius=1)
    g.apply_scale(size)
    g.apply_translation(at)
    add(scene,name,g,tint)

def cone_segment(scene,name,p0,p1,rad0,rad1,tint,n=9):
    a=np.asarray(p0,float)
    b=np.asarray(p1,float)
    dr=b-a
    dr/=np.linalg.norm(dr)
    radial=np.cross(dr,[0,0,1])
    if np.linalg.norm(radial)<.01:
        radial=np.cross(dr,[1,0,0])
    radial/=np.linalg.norm(radial)
    across=np.cross(dr,radial)
    v=[]
    for point,rad in [(a,rad0),(b,rad1)]:
        for k in range(n):
            theta=2*math.pi*k/n
            v.append(point+rad*(math.cos(theta)*radial+math.sin(theta)*across))
    faces=[]
    for k in range(n):
        nxt=(k+1)%n
        faces.extend([(k,nxt,n+nxt),(k,n+nxt,n+k)])
    v.extend([a,b])
    for k in range(n):
        nxt=(k+1)%n
        faces.extend([(2*n,nxt,k),(2*n+1,n+k,n+nxt)])
    add(scene,name,trimesh.Trimesh(vertices=v,faces=faces,process=False),tint)

def cloth_loft(scene,name,levels,tint,n=10):
    # Each section: center x/y/z, ellipse x/z radii. Capped triangulated mesh.
    v=[]
    for x,y,z,rx,rz in levels:
        for k in range(n):
            theta=2*math.pi*k/n
            v.append((x+rx*math.cos(theta),y,z+rz*math.sin(theta)))
    faces=[]
    for k in range(len(levels)-1):
        for j in range(n):
            q=(j+1)%n
            a=k*n+j
            b=k*n+q
            faces.extend([(a,a+n,b),(b,a+n,b+n)])
    v.extend([(levels[0][0],levels[0][1],levels[0][2]),
              (levels[-1][0],levels[-1][1],levels[-1][2])])
    lo=len(v)-2
    hi=lo+1
    for k in range(n):
        q=(k+1)%n
        faces.extend([(lo,k,q),(hi,(len(levels)-1)*n+q,(len(levels)-1)*n+k)])
    add(scene,name,trimesh.Trimesh(vertices=v,faces=faces,process=False),tint)

def fabric(scene,name,points,tint):
    assert len(points)==6
    f=[(0,1,3),(3,1,4),(1,2,4),(4,2,5),
       (3,1,0),(4,1,3),(4,2,1),(5,2,4)]
    add(scene,name,trimesh.Trimesh(vertices=points,faces=f,process=False),tint)

def collar(scene,tint):
    # Genuine folded diagonal cloth bands, layered at chest; NOT pasted X lines.
    left=[(-.345,1.74,.245),(-.300,1.76,.250),(-.255,1.73,.260),
          (.011,1.37,.325),(.067,1.36,.350),(.118,1.36,.343)]
    right=[(.224,1.77,.251),(.267,1.77,.251),(.317,1.745,.244),
           (-.155,1.42,.343),(-.112,1.39,.352),(-.065,1.37,.342)]
    fabric(scene,"left_true_cross_collar",left,tint)
    fabric(scene,"right_cross_collar_overlap",right,"#d9d2c4")
    orb(scene,"soft_inner_shirt_throat",(0,1.783,.078),(.145,.075,.134),"#d9d2c4")

def build_male(kind="villager"):
    if kind not in PALETTES:
        raise ValueError("Unknown male outfit: "+str(kind))
    p=PALETTES[kind]
    s=trimesh.Scene()
    cloth_loft(s,"tapered_torso",[(0,1.02,0,.355,.225),(0,1.29,0,.365,.230),
              (0,1.57,0,.389,.233),(0,1.76,0,.338,.204)],p["cloth"])
    cloth_loft(s,"split_lower_robe",[(0,.71,0,.416,.262),
              (0,.89,0,.389,.231),(0,1.095,0,.356,.231)],p["hem"])
    for side,name in ((-1,"L"),(1,"R")):
        x=side*.205
        cloth_loft(s,"separate_trouser_"+name,
                   [(x,.16,0,.147,.145),(x,.55,0,.154,.141),(x,.94,0,.167,.162)],
                   p["trouser"],8)
        box(s,"grounded_cloth_shoe_"+name,(x,.084,.09),(.30,.16,.46),p["shoe"])
        cone_segment(s,"upper_sleeve_"+name,(side*.445,1.70,0),
                     (side*.545,1.315,.027),.182,.164,p["sleeve"])
        cone_segment(s,"forearm_taper_sleeve_"+name,(side*.549,1.33,.027),
                     (side*.615,1.017,.065),.163,.124,p["sleeve"])
        cone_segment(s,"cuff_hem_"+name,(side*.613,1.04,.065),
                     (side*.621,1.007,.069),.136,.129,p["accent"],8)
        orb(s,"hand_"+name,(side*.626,.922,.092),(.088,.123,.083),SKIN)
        cone_segment(s,"cloth_folds_"+name,(side*.538,1.35,.155),
                     (side*.543,1.26,.150),.035,.020,p["hem"],7)
    box(s,"belt", (0,1.105,0),(.79,.105,.48),p["belt"])
    box(s,"belt_knot",(.04,1.10,.266),(.13,.11,.05),p["accent"])
    collar(s,p["undercollar"])
    if kind in ("villager","apprentice","merchant"):
        # Suspended from the belt, triangular fold, NOT hard oval abdomen plate.
        fabric(s,"hanging_cloth_apron",
               [(-.31,1.079,.277),(-.04,1.082,.327),(.285,1.073,.275),
                (-.34,.560,.335),(-.025,.548,.379),(.300,.561,.332)],p["apron"])
        box(s,"apron_waistband",(0,1.059,.292),(.70,.060,.061),p["belt"])
        box(s,"apron_bottom_binding",(0,.556,.365),(.63,.033,.033),p["accent"])
    if kind=="merchant":
        box(s,"merchant_ledger_pouch",(-.420,1.012,.189),(.25,.235,.17),p["accent"])
    elif kind=="apprentice":
        box(s,"apprentice_tool_pouch",(.42,.89,.173),(.20,.30,.175),p["accent"])
    elif kind=="guard":
        box(s,"plain_guard_cross_strap",(0,1.38,.295),(.48,.082,.09),p["accent"])
        box(s,"cloth_bracer_L",(-.635,1.15,.088),(.16,.20,.16),p["belt"])
        box(s,"cloth_bracer_R",(.635,1.15,.088),(.16,.20,.16),p["belt"])
    elif kind=="scholar":
        box(s,"scholar_scroll",(.42,.97,.175),(.125,.38,.12),p["accent"])
    cloth_loft(s,"neck",[(0,1.76,0,.104,.099),(0,1.91,0,.102,.098)],SKIN,8)
    orb(s,"adult_human_face",(0,2.107,0),(.236,.267,.192),SKIN,2)
    orb(s,"ear_L",(-.242,2.11,0),(.058,.074,.042),SKIN)
    orb(s,"ear_R",(.242,2.11,0),(.058,.074,.042),SKIN)
    for side,name in ((-1,"L"),(1,"R")):
        orb(s,"eye_"+name,(side*.083,2.128,.177),(.019,.021,.014),FACE)
        box(s,"eyebrow_"+name,(side*.082,2.182,.164),(.071,.018,.023),HAIR)
    orb(s,"nose",(0,2.053,.206),(.037,.054,.026),SKIN)
    box(s,"quiet_mouth",(0,1.976,.177),(.073,.012,.016),FACE)
    orb(s,"hair_under_hat",(0,2.309,-.006),(.240,.086,.186),HAIR)
    if kind in ("villager","apprentice"):
        orb(s,"cloth_cap",(0,2.354,-.015),(.240,.093,.199),p["accent"])
        box(s,"cap_brim",(0,2.295,.130),(.41,.056,.20),p["belt"])
    elif kind=="merchant":
        orb(s,"merchant_hat",(0,2.35,-.006),(.250,.096,.203),p["belt"])
        box(s,"merchant_hat_band",(0,2.315,.153),(.43,.047,.103),p["accent"])
    elif kind=="guard":
        cloth_loft(s,"guard_soft_headwrap",[(0,2.30,0,.23,.191),
                   (0,2.42,0,.194,.17)],p["belt"],8)
    else:
        cloth_loft(s,"scholar_cap",[(0,2.31,0,.214,.188),
                   (0,2.425,0,.17,.15)],p["belt"],8)
    assert len(s.geometry)>=28
    return s

def male_master_manifest():
    return {"schema":1,"master_id":"CAC_MALE_CIVILIAN_V1",
      "skeleton_status":"LANDMARKS_ONLY_NOT_SKINNED",
      "forward_axis":"+Z","up_axis":"+Y","units":"meters",
      "archetype":"adult male ordinary civilian",
      "identity_features":["real_cross_collar","actual_waist_belt","tapered_sleeves",
                           "separate_shoes","natural_face","real_draped_apron"],
      "reference_palette":"muted sage, grey-blue, clay rose and flax",
      "variants":list(PALETTES),"bone_guide_positions":{k:list(v) for k,v in LANDMARKS.items()},
      "release":"UNRIGGED_ART_CANDIDATE_NOT_APPROVED"}

def export_male_set(root:Path):
    root.mkdir(parents=True,exist_ok=True)
    doc=male_master_manifest()
    doc["files"]=[]
    for occupation in PALETTES:
        scene=build_male(occupation)
        mesh=trimesh.util.concatenate(list(scene.dump()))
        data=trimesh.Scene(mesh).export(file_type="glb")
        assert data[:4]==b"glTF" and len(data)>2000
        filename="male_"+occupation+"_v1.glb"
        (root/filename).write_bytes(data)
        doc["files"].append({"role":occupation,"filename":filename,
          "sha256":hashlib.sha256(data).hexdigest(),"bytes":len(data),
          "faces":int(len(mesh.faces)),"semantic_parts":len(scene.geometry)})
    (root/"male_master_manifest.json").write_text(json.dumps(doc,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    return doc

if __name__=="__main__":
    cli=argparse.ArgumentParser()
    cli.add_argument("--out",type=Path,required=True)
    args=cli.parse_args()
    results=export_male_set(args.out)
    for row in results["files"]:
        print("PASS_MALE_V1",row["filename"],row["faces"],row["semantic_parts"])
