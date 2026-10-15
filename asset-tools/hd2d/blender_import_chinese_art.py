#!/usr/bin/env python3
"""Run inside Blender: import licensed CC0 FBX files, export actual GLB.

Example:
 blender -b -noaudio --python godot3d/tools/blender_import_chinese_art.py \
   -- godot3d/build/asset_intake godot3d/assets/production/village

This does NOT create procedural meshes or claim source models are final approved art.
Files originate from VVayToyek's CC0 Godot Asset Store packs (SHA256 checked separately).
"""
import bpy
import os
import sys
import zipfile
import json
import tempfile
from pathlib import Path

args = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
if len(args) != 2:
    raise SystemExit("Usage: blender --python script.py -- downloaded_zip_directory output_glb_directory")
input_root = Path(args[0]).resolve()
output_root = Path(args[1]).resolve()
output_root.mkdir(parents=True,exist_ok=True)

assets = [
    ("chinese_pavilion_cc0", "四角亭.fbx", "chinese_pavilion.glb"),
    ("chinese_garden_wall_cc0", "园林围墙.fbx", "chinese_garden_wall_collection.glb"),
]
all_reports=[]

def clean():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for mesh in list(bpy.data.meshes):
        if mesh.users == 0:
            bpy.data.meshes.remove(mesh)

for asset_id,source_name,target_name in assets:
    clean()
    zip_path = input_root / (asset_id + ".zip")
    if not zip_path.is_file():
        raise RuntimeError(f"Missing inspected CC0 archive: {zip_path}")
    with tempfile.TemporaryDirectory() as work:
        directory = Path(work)
        with zipfile.ZipFile(zip_path) as z:
            for item in z.infolist():
                if item.is_dir():
                    continue
                dest=(directory/item.filename).resolve()
                if not dest.is_relative_to(directory.resolve()):
                    raise RuntimeError(f"Unsafe archive: {item.filename}")
                dest.parent.mkdir(parents=True,exist_ok=True)
                with z.open(item) as inp, dest.open("wb") as out:
                    while True:
                        block=inp.read(1024*1024)
                        if not block:break
                        out.write(block)
        fbx_path=next((p for p in directory.rglob("*.fbx") if p.name==source_name),None)
        if not fbx_path:
            raise RuntimeError(f"Expected Chinese geometry {source_name} not found")
        bpy.ops.import_scene.fbx(filepath=str(fbx_path),use_custom_normals=True)
        objects=[o for o in bpy.context.scene.objects]
        mesh_objects=[o for o in objects if o.type=="MESH"]
        if not mesh_objects:
            raise RuntimeError(f"{asset_id} contains no mesh objects")
        for o in mesh_objects:
            o.name = o.name.replace("/", "_")
        faces=sum(len(o.data.polygons) for o in mesh_objects)
        vertex_count=sum(len(o.data.vertices) for o in mesh_objects)
        mat_count=len({m.name for o in mesh_objects for m in o.data.materials if m is not None})
        bounds=[]
        from mathutils import Vector
        for o in mesh_objects:
            for corner in o.bound_box:
                bounds.append(o.matrix_world@Vector(corner))
        vmin=[min(v[i] for v in bounds) for i in range(3)]
        vmax=[max(v[i] for v in bounds) for i in range(3)]
        outfile=output_root/target_name
        bpy.ops.export_scene.gltf(filepath=str(outfile),export_format="GLB",use_selection=False,
                                   export_apply=True)
        report={"id":asset_id,"source_zip":zip_path.name,"fbx":source_name,
                "glb":str(outfile),"glb_bytes":outfile.stat().st_size,
                "meshes":len(mesh_objects),"materials":mat_count,
                "vertices":vertex_count,"faces":faces,"bounds_min":vmin,"bounds_max":vmax,
                "object_names":[o.name for o in mesh_objects][:120]}
        all_reports.append(report)
        print("ART_ASSET_CONVERTED "+json.dumps(report,ensure_ascii=False),flush=True)
        # Garden wall source contains 78 modular variants laid out as an art catalog.
        # Export only chosen original-author components as individually placeable meshes.
        # Placing the full catalog in a small village would look nonsensical.
        if asset_id == "chinese_garden_wall_cc0":
            from mathutils import Vector
            chosen = {
                "围墙_中_10段": "courtyard_wall_section.glb",
                "围墙_中_花窗1_白": "courtyard_flower_window.glb",
                "月洞门1_中": "courtyard_moon_gate.glb"
            }
            for original_name, export_filename in chosen.items():
                item = next((o for o in mesh_objects if o.name == original_name), None)
                if item is None:
                    raise RuntimeError("Required structural CC0 mesh missing: " + original_name)
                # Clone data so resetting the transform cannot affect source catalog.
                bpy.ops.object.select_all(action='DESELECT')
                clone = item.copy()
                clone.data = item.data.copy()
                bpy.context.collection.objects.link(clone)
                clone.matrix_world = item.matrix_world.copy()
                corners = [clone.matrix_world @ Vector(corner) for corner in clone.bound_box]
                cx = (min(v.x for v in corners)+max(v.x for v in corners))/2
                cy = (min(v.y for v in corners)+max(v.y for v in corners))/2
                cz = min(v.z for v in corners)
                clone.matrix_world.translation -= Vector((cx,cy,cz))
                clone.select_set(True)
                bpy.context.view_layer.objects.active = clone
                target = output_root/export_filename
                bpy.ops.export_scene.gltf(filepath=str(target),
                    export_format="GLB",use_selection=True,export_apply=True)
                dims=[max(v[i] for v in corners)-min(v[i] for v in corners) for i in range(3)]
                variant={"id":original_name,"glb":str(target),"bytes":target.stat().st_size,
                         "source_fbx":source_name,"source_bounds_multiply_by_0_1":dims}
                all_reports.append(variant)
                print("CC0_WALL_MODULE_EXPORTED "+json.dumps(variant,ensure_ascii=False),flush=True)
                bpy.data.objects.remove(clone,do_unlink=True)

report_path=input_root/"converted_assets.json"
report_path.write_text(json.dumps(all_reports,ensure_ascii=False,indent=2),encoding="utf8")
print("CC0_CHINESE_ART_GLBS_READY",flush=True)
