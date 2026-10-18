"""Convert immutable author-licensed CC0 Chinese FBX into real Godot GLB.

Intended invocation from pinned GitHub QA (Blender headless):
    blender -b --python THIS_FILE -- --input /path/source.fbx \
        --output /path/output.glb --manifest /path/output.json

This never fabricates a model or claims texel channels that were not included
with the CC0 source. No signing and NO automatic phone OTA.
"""
import hashlib
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
params = {}
for pair in args:
    if not pair.startswith("--") or "=" not in pair:
        raise RuntimeError("EXPECTED_KEY_VALUE_ARG: " + pair)
    k, v = pair[2:].split("=", 1)
    params[k] = v
for item in ("input", "output", "manifest"):
    if not params.get(item):
        raise RuntimeError("MISSING_ARG_" + item)

inp = Path(params["input"])
out = Path(params["output"])
proof = Path(params["manifest"])
if not inp.is_file() or inp.suffix.lower() != ".fbx":
    raise RuntimeError("AUTHOR_REAL_FBX_MISSING")
if inp.stat().st_size > 70_000_000:
    raise RuntimeError("UNVERIFIED_FBX_TOO_LARGE")

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for mesh in list(bpy.data.meshes):
    if mesh.users == 0:
        bpy.data.meshes.remove(mesh)

# Preserve source model topology, UVs, normals, object hierarchy and names.
# The vendor-specific UV layout PNGs are NOT actual albedo/normal texture
# maps; declaring them as authored PBR maps would violate the QA contract.
bpy.ops.import_scene.fbx(filepath=str(inp), use_anim=False)
bpy.context.view_layer.update()
nodes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
if not nodes:
    raise RuntimeError("NO_ACTUAL_VENDOR_3D_GEOMETRY_IMPORT")
triangles = 0
verts = 0
uv_nodes = 0
material_names = set()
lo = [float("inf")] * 3
hi = [-float("inf")] * 3
for part in nodes:
    verts += len(part.data.vertices)
    triangles += sum(max(0, len(poly.vertices) - 2) for poly in part.data.polygons)
    if part.data.uv_layers:
        uv_nodes += 1
    for slot in part.material_slots:
        if slot.material is not None:
            material_names.add(slot.material.name)
    for corner in part.bound_box:
        world_pos = part.matrix_world @ Vector(corner)
        for axis in range(3):
            lo[axis] = min(lo[axis], world_pos[axis])
            hi[axis] = max(hi[axis], world_pos[axis])
if triangles <= 0 or verts < 100 or uv_nodes < 1:
    raise RuntimeError("SOURCE_LACKS_REAL_TRIANGLES_AND_UVS")
dimensions = [hi[i] - lo[i] for i in range(3)]
if not all(x >= 0 for x in dimensions) or max(dimensions) > 500000:
    raise RuntimeError("MODEL_UNBOUNDED_OR_INVALID_REAL_WORLD_SIZE")

# Only original FBX geometry is selected, never Blender test scene proxies.
bpy.ops.object.select_all(action="DESELECT")
for item in nodes:
    item.select_set(True)
bpy.context.view_layer.objects.active = nodes[0]

out.parent.mkdir(parents=True, exist_ok=True)
proof.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(
    filepath=str(out),
    export_format="GLB",
    use_selection=True,
    export_apply=False,
    export_texcoords=True,
    export_normals=True,
    export_materials="EXPORT",
)
raw = out.read_bytes()
if raw[:4] != b"glTF" or len(raw) < 1024:
    raise RuntimeError("EXPORT_NOT_REAL_GLTF_BINARY")
# Read the actual GLB2 manifest, not Blender's claimed export flag.
if int.from_bytes(raw[4:8], "little") != 2:
    raise RuntimeError("EXPORT_NOT_GLTF2")
index_len = int.from_bytes(raw[12:16], "little")
if raw[16:20] != b"JSON" or index_len > len(raw):
    raise RuntimeError("MISSING_GLTF_JSON_CHUNK")
index = json.loads(raw[20:20 + index_len].decode("utf-8"))
if not index.get("meshes") or not index.get("materials"):
    raise RuntimeError("MODEL_HAS_NO_REAL_GLTF_MESH_MATERIALS")
if not any("TEXCOORD_0" in primitive.get("attributes", {})
           for mesh in index["meshes"] for primitive in mesh.get("primitives", [])):
    raise RuntimeError("REAL_VENDOR_UV_WAS_LOST_IN_CONVERSION")
record = {
    "schema": 208,
    "source_name": inp.name,
    "source_fbx_sha256": hashlib.sha256(inp.read_bytes()).hexdigest(),
    "converted_glb_name": out.name,
    "converted_glb_sha256": hashlib.sha256(raw).hexdigest(),
    "converted_bytes": len(raw),
    "source_actual_mesh_objects": len(nodes),
    "source_vertices": verts,
    "source_polygon_triangles": triangles,
    "source_uv_mesh_objects": uv_nodes,
    "source_material_slot_names": sorted(material_names)[:200],
    "source_world_bounds_units": dimensions,
    "source_mesh_name_sample": [item.name for item in nodes[:180]],
    "actual_converted_gltf_meshes": len(index["meshes"]),
    "actual_converted_gltf_materials": len(index["materials"]),
    "source_original_vendor_geometry_preserved": True,
    "source_website_claims_cc0_verified_separately": True,
    "actual_authored_pbr_textures": "NOT_CLAIMED_SOURCE_UV_LAYOUT_ONLY",
    "godot_original_main_qa": "NOT_TESTED",
    "android_real_device_30min": "NOT_TESTED",
    "game_asset_approved": False,
    "release_policy": "QUARANTINED_DO_NOT_SIGN_OR_OTA",
}
proof.write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding="utf-8")
print("PASS_REV208_SOURCE_CC0_CHINESE_ARCHITECTURE_TRUE_TRIANGULATED_MESH_AND_GLB2_UVS",
      inp.name, triangles, len(nodes), len(index["materials"]), len(raw), flush=True)
