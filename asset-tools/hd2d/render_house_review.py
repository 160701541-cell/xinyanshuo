"""Blender headless *review screenshot*, not a finished user-facing game scene.
Actual building is imported licensed CC0 GLB; original Chinese actor is PNG plane.
Background/ground are inspection-only surfaces, NOT presented as approved art.
"""
import bpy
import math
import sys
from pathlib import Path
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
house_path, actor_path, out_path = map(Path, args)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(house_path.resolve()))
meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
assert meshes, "No real Chinese building meshes"
# Same FBX author-units -> Godot metres conversion as WorldVisualBinding.
for obj in bpy.context.scene.objects:
    if obj.type != "CAMERA" and obj.type != "LIGHT":
        obj.scale *= 0.1
bpy.context.view_layer.update()
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
min_corner=Vector((1e10,1e10,1e10))
max_corner=Vector((-1e10,-1e10,-1e10))
from mathutils import Vector as V
for obj in meshes:
    for corner in obj.bound_box:
        p=obj.matrix_world @ V(corner)
        for axis in range(3):
            min_corner[axis]=min(min_corner[axis],p[axis])
            max_corner[axis]=max(max_corner[axis],p[axis])
center=(min_corner+max_corner)*0.5
dims=max_corner-min_corner
assert 0.1<max(dims)<1000, dims
print("AUTHORED_CHINESE_HOUSE_BOUNDS", list(dims), "MESHES",len(meshes))
# Character is an actual external CC0 PNG image facing the review camera.
img=bpy.data.images.load(str(actor_path.resolve()))
mat=bpy.data.materials.new("LicensedCC0ActorPNG")
mat.diffuse_color=(1,1,1,1)
mat.use_nodes=True
n=mat.node_tree.nodes
n.clear()
tex=n.new("ShaderNodeTexImage")
tex.image=img
tex.interpolation="Linear"
bsdf=n.new("ShaderNodeBsdfPrincipled")
if "Alpha" in bsdf.inputs:
    mat.node_tree.links.new(tex.outputs["Alpha"],bsdf.inputs["Alpha"])
mat.node_tree.links.new(tex.outputs["Color"],bsdf.inputs["Base Color"])
out=n.new("ShaderNodeOutputMaterial")
mat.node_tree.links.new(bsdf.outputs["BSDF"],out.inputs["Surface"])
if hasattr(mat,"surface_render_method"):mat.surface_render_method="DITHERED"
else: mat.blend_method="HASHED"
bpy.ops.mesh.primitive_plane_add(size=1,location=(center.x+dims.x*.2, min_corner.y-dims.y*.05,min_corner.z+0.9))
actor=bpy.context.object
actor.name="ActualCC0HanFigure2D_NoRig"
actor.scale=(1.2,1.8,1)
actor.data.materials.append(mat)
# World space landscape is deliberately neutral: evaluate visual consistency first.
bpy.ops.mesh.primitive_plane_add(size=200, location=(center.x,center.y,min_corner.z-0.03))
ground=bpy.context.object
gmat=bpy.data.materials.new("TemporaryReviewGround")
gmat.diffuse_color=(0.45,0.52,0.40,1)
ground.data.materials.append(gmat)
bpy.ops.object.light_add(type="AREA",location=(center.x+12,center.y-8,center.z+15))
bpy.context.object.data.energy=1600
bpy.context.object.data.shape="DISK"
bpy.context.object.data.size=10
bpy.ops.object.camera_add(location=center+Vector((dims.x*1.6,-dims.y*2.0,max(dims.x,dims.y)*1.3)))
camera=bpy.context.object
look=center-Vector((0,0,dims.z*.15))
camera.rotation_euler=(look-camera.location).to_track_quat("-Z","Y").to_euler()
camera.data.type="ORTHO"
camera.data.ortho_scale=max(dims.x,dims.y)*2.0
bpy.context.scene.camera=camera
# Face actor plane toward the camera yaw.
actor.rotation_euler[2]=(camera.location.xy-actor.location.xy).angle_signed(Vector((0,-1))) if False else math.atan2(camera.location.y-actor.location.y,camera.location.x-actor.location.x) + math.pi/2
world=bpy.context.scene.world
world.color=(0.66,0.73,0.78)
scene=bpy.context.scene
scene.render.engine="BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in {i.identifier for i in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items} else "BLENDER_EEVEE"
scene.render.resolution_x=1280
scene.render.resolution_y=720
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.render.filepath=str(out_path.resolve())
bpy.ops.render.render(write_still=True)
print("PASS_REAL_CC0_CHINESE_BUILDING_AND_2D_PERSON_REVIEW_FRAME",out_path)
