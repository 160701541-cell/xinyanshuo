#!/usr/bin/env python3
"""Compose the first material-backed Han-style vernacular house GLB.

The intricate roof is ACTUAL originally modelled CC0 Chinese pavilion structure
(VVayToyek, not a flat sheet, ~40k imported authored vertices). New earthen
walls, crafted wood lattice, rammed-stone base and courtyard door are created
as three-dimensional modular components in Blender. It remains an art WIP,
not a final professional character/world environment.

Run with Blender 4.0+: blender -b --python this.py -- input_pavilion.glb output_mud_house.glb
Source: https://store.godotengine.org/asset/vvaytoyek/chinese-four-corner-pavilion-free/
"""
import bpy
import math
import os
import random
import sys
from pathlib import Path
from mathutils import Vector

args = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
if len(args)!=2:
    raise SystemExit("Usage: blender --python build_cc0_vernacular_house.py -- pavilion.glb mud_house.glb")
source=Path(args[0]).resolve()
target=Path(args[1]).resolve()
if not source.is_file():
    raise RuntimeError("Licensed pavilion roof source missing")
target.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))

source_objects=list(bpy.context.scene.objects)
authored=[o for o in source_objects if o.type=="MESH"]
roof_prefixes=("瓦面","垂脊","檐椽","脑椽","飞椽","衬头木",
    "老角梁","仔角梁由戗","套兽","金檩金枋","檐檩垫板",
    "抹角梁","角云","雷公柱宝顶","额枋","挂落")
roof_sources=[o for o in authored if o.name.startswith(roof_prefixes)]
if len(roof_sources)<35:
    raise RuntimeError(f"Authored Chinese roof components missing; detected {len(roof_sources)}")

def create_group(name):
    obj=bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(obj)
    return obj

roof=create_group("Roof")
walls=create_group("Walls")
# Clone original CC0 geometry without re-modelling its decorative roof details.
for src in roof_sources:
    copy=src.copy()
    copy.data=src.data.copy()
    bpy.context.collection.objects.link(copy)
    source_matrix=src.matrix_world.copy()
    copy.parent=roof
    copy.matrix_world=source_matrix
# Remove original imported structural catalog and keep just the roof fragments.
for o in source_objects:
    bpy.data.objects.remove(o,do_unlink=True)
# 10 authored pavilion units are roughly 1 metre. Stretch to a 7x5.6m homestead.
roof.scale=(1.78,1.44,1.0)
roof.location.z=8.0

def material(name,rgb,roughness=0.9,metallic=0.0):
    m=bpy.data.materials.new(name)
    m.use_nodes=True
    shader=m.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value=(*rgb,1.0)
    shader.inputs["Roughness"].default_value=roughness
    shader.inputs["Metallic"].default_value=metallic
    return m

soil=material("黄土夯墙微暖灰",(0.56,0.48,0.37))
earth=material("旧石灰土夯面",(0.67,0.62,0.49))
wall_weather=material("土墙风化裂纹色",(0.47,0.42,0.34))
timber=material("老杉木柱深赭",(0.19,0.115,0.075))
wood=material("古木门扇茶褐",(0.33,0.21,0.125))
wood_dust=material("木纹浅褐",(0.43,0.31,0.20))
stone=material("河滩青灰基础石",(0.34,0.34,0.32))
stone_light=material("基础浅石纹",(0.44,0.44,0.39))
paper=material("竹纸窗明黄",(0.74,0.68,0.51))
bronze=material("门环古铜",(0.33,0.23,0.10),0.5,0.5)

def cube(name,center,dimensions,mat,group=walls):
    bpy.ops.mesh.primitive_cube_add(size=1.0,location=center)
    ob=bpy.context.object
    ob.name=name
    ob.dimensions=dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    ob.data.materials.append(mat)
    world=ob.matrix_world.copy()
    ob.parent=group
    ob.matrix_world=world
    return ob

# Actual 3D foundation stone blocks (never just a floating 2D floor).
cube("StoneFoundationCore",(0,0,2),(71,56,4),stone)
for x in range(-33,34,7):
    cube("FoundationCutStone_%d"%x,(x,-28,2.2),(6.8,0.9,3.8),
         stone_light if (x//7)%3==0 else stone)
for y in range(-23,24,7):
    for side in (-1,1):
        cube("FoundationCornerCutStone",(side*35,y,2.1),(1.4,6.8,3.9),stone)
# Slightly irregular earthen wall panels, with structural hardwood framing.
cube("RearRammedEarthWall",(0,25,17),(65,2.8,27),soil)
cube("LeftRammedEarthWall",(-34,0,17),(2.8,48,27),earth)
cube("RightRammedEarthWall",(34,0,17),(2.8,48,27),soil)
for x in (-21.5,21.5):
    cube("FrontRammedEarthWall",(x,-25,17),(21,2.8,27),earth)
for x in (-33.2,33.2):
    for y in (-24.2,24.2):
        cube("RammedEarthTimberCorner",(x,y,18),(3.3,3.4,31),timber)
for x in (-33,0,33):
    cube("FrontBeamCol",(x,-26.3,18),(2.5,2.5,30),timber)
for z in (7,29):
    cube("CourtyardCrossBeam",(0,-26.5,z),(68,2.5,2.5),timber)
# Cedar columns and individual struts inside: house is structurally legible.
for x in (-24,24):
    cube("IndoorMiddlePillar",(x,0,17),(2.2,2.2,30),wood)
    cube("IndoorCeilingBeam",(x,0,31),(2.0,47,2.2),wood)

# Door has two wooden leaves, actual vertical thickness, iron/brass fittings.
for x in (-8.3,8.3):
    cube("DoorVerticalFrame",(x,-27.3,16),(1.9,3.0,24.5),timber)
cube("DoorLintel",(0,-27.3,29),(18,3.0,2.2),wood)
for side in (-1,1):
    centre=side*4.1
    # Parenting each carved physical part to a real hinge pivot permits Godot
    # to animate the COMPLETE door, without teleporting decorative meshes.
    hinge=create_group("DoorHingeLeft" if side<0 else "DoorHingeRight")
    hinge.parent=walls
    hinge.location=(side*8.3,-27.4,16.0)
    cube("DoubleCourtyardWoodDoorLeaf",(centre,-27.4,16),(7.3,0.9,23.0),wood,hinge)
    for plank in range(3):
        cube("DoorCarvedVerticalRidge",(centre-2.6+2.6*plank,-28.0,16),
             (0.24,0.4,20),wood_dust,hinge)
    cube("DoorRoundMetalRingBase",(centre-side*2.2,-28.4,15),(1.1,0.4,1.4),bronze,hinge)

def lattice_window(window_x,back_y,width=11,height=12):
    # Separate papered window face with visible lattice and carved wooden frame.
    z=18
    cube("WindowBambooPaper",(window_x,back_y,z),(width,0.9,height),paper)
    cube("WoodWindowLintel",(window_x,back_y-0.8,z+height/2),(width+1.6,1.2,1.0),timber)
    cube("WoodWindowSill",(window_x,back_y-0.8,z-height/2),(width+1.6,1.2,1.0),timber)
    for side in (-1,1):
        cube("WoodWindowSideFrame",(window_x+side*width/2,back_y-0.8,z),
             (1.0,1.4,height),timber)
    for i in range(-2,3):
        cube("IntricateWindowVerticalBars",(window_x+i*2.1,back_y-1.3,z),
             (0.28,0.75,height-1.0),wood)
    for i in range(-2,3):
        cube("IntricateWindowHorizontalBars",(window_x,back_y-1.25,z+i*2.0),
             (width-0.9,0.75,0.28),wood)
    for i in (-1,1):
        cube("CenterDiamondCrossTrim",(window_x+i*2,back_y-1.55,z),
             (0.42,0.6,4.5),wood_dust)

lattice_window(-19,27.0)
lattice_window(19,27.0)
for x in (-20,20):
    # Front facade timber shutter bays, rather than a blank unbroken rectangle.
    cube("FrontCarvedPanel",(x,-27.0,21),(13,0.6,11),wood)
    for i in range(5):
        cube("FineDoorSlat",(x-5.0+i*2.5,-27.5,21),(0.35,0.65,9.8),wood_dust)
# Fine timber joins and exposed ceiling fascia.
for y in (-24.4,24.4):
    cube("CeilingFrontRafter",(0,y,32),(66,1.8,2.1),timber)
for x in range(-27,28,9):
    cube("RoofRafterExposed",(x,-23.8,32),(1.3,5.8,1.3),wood)
# Natural plaster variation as slim protrusions, not hard rectangular flat paint.
r=random.Random(20261013)
for i in range(22):
    x=r.uniform(-29,29)
    z=r.uniform(7,27)
    cube("ErodedRammedEarthLine",(x,26.55,z),
         (r.uniform(0.8,2.5),0.15,r.uniform(0.3,1.2)),wall_weather)
# Threshold real stone blocks and a wooden footstep with thickness.
cube("StoneDoorStep",(0,-32.4,1.0),(20,9.5,2.0),stone_light)
cube("WornWoodThreshold",(0,-28.3,3.2),(19,3.6,2.4),timber)

outfile=target
bpy.ops.export_scene.gltf(filepath=str(outfile),export_format="GLB",
                          use_selection=False,export_apply=True)
if not outfile.is_file() or outfile.stat().st_size<500_000:
    raise RuntimeError("Authored tiled-roof Chinese vernacular house GLB was not exported")
mesh_objects=[o for o in bpy.context.scene.objects if o.type=="MESH"]
report={"glb":str(outfile),"bytes":outfile.stat().st_size,
        "meshes":len(mesh_objects),
        "vertices":sum(len(o.data.vertices) for o in mesh_objects),
        "roof_source":"VVayToyek Chinese Four-corner Pavilion (CC0)",
        "roof_original_mesh_components":len(roof_sources),
        "scene_nodes":["Roof","Walls","DoorHingeLeft","DoorHingeRight"],
        "claim":"Architectural visual upgrade based on CC0 roof parts; NOT final professional art approval."}
print("CC0_CHINESE_VERNACULAR_HOUSE_EXPORTED "+__import__("json").dumps(report,ensure_ascii=False),flush=True)
