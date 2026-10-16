#!/usr/bin/env python3
"""CAC-HAN-V2 — original stylized Chinese civilian outfits, Y up, +Z forward.

Not a historic replica or rigged character. Shared master + occupation variants.
Requires male_civilian_master.py (body/face helpers), NumPy and Trimesh (OSS).
"""
from __future__ import annotations
import argparse, hashlib, json, math
from pathlib import Path
import numpy as np
import trimesh
from male_civilian_master import (
    PALETTES, LANDMARKS, SKIN, HAIR, FACE, build_male,
    add, box, orb, cloth_loft, fabric
)

JOBS = ("villager","merchant","apprentice","guard","scholar")
HEMS = {"villager":.60, "merchant":.36, "apprentice":.75,
        "guard":.65, "scholar":.31}
WIDTH = {"villager":.49, "merchant":.54, "apprentice":.44,
         "guard":.46, "scholar":.58}
WIDE = {"villager":.035, "merchant":.13, "apprentice":-.015,
        "guard":-.025, "scholar":.19}
IDENTITY = (
    "交领右衽：单条贯穿至右腰的斜向压襟，而非贴片X",
    "衣身侧开衩、布料分层、下摆长短按身份区分",
    "布腰封系结与自然下垂系带，而非西式皮带搭扣",
    "束发髻、布巾或儒巾，禁用西式鸭舌帽",
    "宽窄有身份差异的斜肩直袖和袖缘",
    "低饱和苍岚乡民配色和独立圆头布鞋"
)

def strip(scene, source):
    # V1 only contributes a CONSISTENT HEAD/HAND/LEG master:
    # never inherit its Western cap, X-banded collar, or barrel torso.
    keep=("neck","adult_human_face","ear_","eye_","eyebrow_","nose",
          "quiet_mouth","hair_under_hat","hand_",
          "separate_trouser_","grounded_cloth_shoe_")
    for name,mesh in source.geometry.items():
        if name.startswith(keep):
            scene.add_geometry(mesh.copy(),geom_name=name,node_name=name)

def ribbon(scene,name,points,width,color):
    pts=np.asarray(points,dtype=float)
    verts=[]
    for i,p in enumerate(pts):
        v=pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]
        v/=max(np.linalg.norm(v),1e-8)
        across=np.array([-v[1],v[0],0.])
        across/=max(np.linalg.norm(across),1e-8)
        verts.extend([p+across*width/2,p-across*width/2])
    faces=[]
    for i in range(len(pts)-1):
        a=2*i;b=a+2
        faces.extend([[a,b,a+1],[a+1,b,b+1]])
    faces += [x[::-1] for x in faces]
    add(scene,name,trimesh.Trimesh(vertices=verts,faces=faces,process=False),color)

def cloth_sleeve(scene,side,main,accent,lining,wide):
    s=float(side)
    rings=[(s*.37,1.68,.000,.155,.180),
           (s*.50,1.41,.018,.172,.204),
           (s*.605,1.12,.041,.188+wide,.207+wide*.47)]
    # Eight bevelled corners per section, not circular pipe sleeves.
    corners=[(-1,-.7),(-.72,-1),(.72,-1),(1,-.7),(1,.7),(.72,1),(-.72,1),(-1,.7)]
    verts=[]
    for x,y,z,rx,rz in rings:
        verts.extend([[x+rx*u,y+u*.035,z+rz*v] for u,v in corners])
    faces=[]
    for section in range(2):
        for j in range(8):
            a=section*8+j;b=section*8+(j+1)%8
            c=(section+1)*8+j;d=(section+1)*8+(j+1)%8
            faces.extend([[a,c,b],[b,c,d]])
    add(scene,f"斜肩直袖_{side}",trimesh.Trimesh(
        vertices=verts,faces=faces,process=False),main)
    # Real narrow cuff piping as mesh.
    for j in range(8):
        ribbon(scene,f"袖口包边_{side}_{j}",[verts[16+j],verts[16+(j+1)%8]],.025,lining)
    ribbon(scene,f"袖缝_{side}",[(s*.494,1.43,.219),(s*.56,1.24,.245)],.016,accent)

def wrap_robe(scene,role,main,secondary,offwhite,trim):
    hem=HEMS[role];width=WIDTH[role]
    cloth_loft(scene,"中式直身外袍",[
       (0,hem,0,width,.309),(0,(hem+1.09)/2,0,width*.91,.265),
       (0,1.09,0,.359,.242),(0,1.38,0,.353,.228),
       (0,1.66,0,.384,.215),(0,1.78,0,.295,.187)],main,12)
    # Separate left underlap and right-closing large cloth face.
    fabric(scene,"下层衣襟",[
        (-.292,1.657,.225),(-.082,1.685,.273),(.020,1.595,.275),
        (-width*.79,hem+.045,.245),(-.12,hem+.035,.344),(.097,hem+.036,.31)],secondary)
    fabric(scene,"右衽大片交叠襟",[
        (-.10,1.61,.267),(.05,1.58,.291),(.22,1.51,.233),
        (-.17,hem+.05,.306),(.12,hem+.035,.364),(.34,hem+.05,.268)],secondary)
    # ONE dominant diagonal, with the opposite collar stopping above the chest.
    # This is not the conspicuous Western criss-cross in the rejected V1.
    ribbon(scene,"交领右衽_主襟",[
        (-.28,1.775,.200),(-.184,1.671,.261),(.017,1.503,.315),
        (.207,1.322,.321),(.351,1.163,.267)],.069,offwhite)
    ribbon(scene,"交领_内衬短缘",[
        (.241,1.761,.201),(.170,1.683,.256),(.104,1.629,.276)],.044,trim)
    ribbon(scene,"竖向襟缘",[(.342,1.16,.285),(.348,.86,.311),
           (.325,hem+.10,.313)],.030,trim)
    cloth_loft(scene,"传统衣摆滚边",[
        (0,hem-.019,0,width+.010,.318),
        (0,hem+.036,0,width+.011,.320)],trim,12)
    for side in (-1,1):
        ribbon(scene,f"袍侧开衩_{side}",[
             (side*width*.94,hem+.05,.139),
             (side*width*.88,hem+.25,.143)],.020,offwhite)
    # Authentic soft cloth sash around waist, asymmetrical knot, two ends.
    cloth_loft(scene,"系布腰封",[
        (0,1.040,0,.376,.281),(0,1.123,0,.373,.275)],trim,12)
    fabric(scene,"腰封右侧系结",[
        (.262,1.11,.224),(.328,1.13,.242),(.390,1.10,.214),
        (.251,1.01,.252),(.333,1.04,.280),(.393,1.019,.217)],offwhite)
    ribbon(scene,"系带一",[(.359,1.064,.272),(.368,.877,.276),
                              (.358,.735,.266)],.071,offwhite)
    ribbon(scene,"系带二",[(.388,1.063,.230),(.442,.941,.238),
                              (.444,.818,.228)],.052,secondary)

def hair_and_hat(scene,role,shade,accent):
    # Bound topknot, not a flat Western felt cap.
    orb(scene,"束发发根",(0,2.306,-.021),(.225,.079,.174),HAIR)
    cloth_loft(scene,"汉式绾发髻",[
        (0,2.301,-.043,.085,.085),(0,2.389,-.043,.101,.096),
        (0,2.442,-.039,.061,.071)],HAIR,10)
    for side in (-1,1):
        orb(scene,f"鬓角束发_{side}",(side*.184,2.18,-.076),(.051,.111,.069),HAIR)
    if role=="scholar":
        # Scholar's square four-cornered headscarf, not a western beret.
        box(scene,"方巾本体",(0,2.374,-.056),(.402,.224,.30),shade)
        ribbon(scene,"方巾前折线",[(-.19,2.280,.128),(0,2.291,.140),
                                   (.19,2.280,.128)],.038,accent)
    elif role=="merchant":
        cloth_loft(scene,"商贾包头巾",[
           (0,2.260,-.026,.226,.186),
           (0,2.308,-.026,.230,.183),
           (0,2.330,-.026,.194,.165)],shade,12)
        ribbon(scene,"头巾褶皱",[(-.207,2.291,.092),(0,2.311,.162),
                                 (.212,2.293,.089)],.035,accent)
    else:
        ribbon(scene,"乡民扎头巾",[(-.211,2.263,.116),(0,2.286,.180),
                                  (.209,2.263,.108)],.065,shade)
        ribbon(scene,"头巾结绳",[(.208,2.280,-.112),(.234,2.185,-.162),
                                (.193,2.140,-.220)],.051,accent)

def build_han_male(role="villager"):
    if role not in JOBS:
        raise ValueError(role)
    p=PALETTES[role];scene=trimesh.Scene()
    strip(scene,build_male(role))
    main=p["cloth"];secondary=p["hem"];offwhite=p["undercollar"];trim=p["belt"]
    wrap_robe(scene,role,main,secondary,offwhite,trim)
    for side in (-1,1):
        cloth_sleeve(scene,side,main,secondary,offwhite,WIDE[role])
    if role=="merchant":
        orb(scene,"商人钱袋",(-.444,.969,.182),(.125,.17,.105),p["accent"])
        ribbon(scene,"钱袋绳",[(-.341,1.11,.222),(-.440,1.010,.221)],.02,trim)
    if role=="apprentice":
        fabric(scene,"工作垂布围裙",[
            (-.20,1.03,.273),(0,1.04,.311),(.21,1.022,.271),
            (-.19,.567,.298),(0,.558,.359),(.19,.567,.298)],offwhite)
    if role=="guard":
        for side in (-1,1):
            ribbon(scene,f"护腕束带_{side}",[
                (side*.590,1.257,.239),(side*.629,1.11,.258)],.070,trim)
    if role=="scholar":
        orb(scene,"书生卷轴",(-.435,.932,.143),(.053,.206,.050),offwhite)
    if role=="villager":
        orb(scene,"乡民布袋",(-.440,.939,.14),(.120,.139,.094),secondary)
    hair_and_hat(scene,role,trim,secondary)
    return scene

def manifest():
    return {"schema":2,"master_id":"CAC_HAN_MALE_V2",
        "style":"historically inspired Chinese commoner clothing (fictional era)",
        "identity_features":list(IDENTITY),"roles":list(JOBS),
        "skeleton_status":"UNRIGGED_LANDMARKS_ONLY",
        "bone_guide_positions":{k:list(v) for k,v in LANDMARKS.items()},
        "mobile_status":"ART_CANDIDATE_NOT_APPROVED"}

def export_pack(root):
    root=Path(root);root.mkdir(parents=True,exist_ok=True)
    m=manifest();m["files"]=[]
    for role in JOBS:
        sc=build_han_male(role)
        merged=trimesh.util.concatenate(list(sc.dump()))
        data=trimesh.Scene(merged).export(file_type="glb")
        assert data[:4]==b"glTF" and len(data)>2000
        height=merged.bounds[1,1]-merged.bounds[0,1]
        assert 2.25<height<2.55, (role,height)
        dest=f"male_{role}_han_v2.glb"
        (root/dest).write_bytes(data)
        m["files"].append({"role":role,"path":dest,
          "sha256":hashlib.sha256(data).hexdigest(),
          "bytes":len(data),"faces":len(merged.faces),
          "height_m":round(height,3)})
    (root/"male_han_v2_manifest.json").write_text(
        json.dumps(m,ensure_ascii=False,indent=2)+"\\n",encoding="utf-8")
    return m

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--out",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export_pack(args.out),ensure_ascii=False)[:3000])
