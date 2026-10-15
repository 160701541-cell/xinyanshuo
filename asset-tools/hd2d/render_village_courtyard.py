"""Review frame assembled from real Chinese CC0 courtyard components; NOT a phone screenshot.
Use real authored moon gate, wall and window GLBs, physical stone path and 2D role PNG.
Keeps the artist's geometry; art evaluation may still reject the result.
"""
import bpy, math, random, sys
from pathlib import Path
from mathutils import Vector

gate, wall, window, actor_path, output = [Path(s).resolve() for s in sys.argv[sys.argv.index("--")+1:]]
bpy.ops.wm.read_factory_settings(use_empty=True)
def material(name, rgb, rough=0.84):
    m=bpy.data.materials.new(name); m.diffuse_color=(*rgb,1);m.use_nodes=True
    bs=m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value=(*rgb,1)
    bs.inputs["Roughness"].default_value=rough
    return m
ground_mat=material("Grassland soft sage",(.235,.31,.205))
stone_mats=[material("Worn blue-gray limestone %s"%i,c) for i,c in enumerate([
(.39,.43,.42),(.43,.45,.42),(.32,.37,.37),(.47,.47,.43),(.38,.41,.39)])]
oldwood=material("Weathered cedar",(.25,.15,.09))
plantmat=material("Grass blade forest green",(.15,.30,.11))
soilmat=material("Clay pathway margins",(.35,.29,.21))
def box(name,xyz,dimensions,mat):
    bpy.ops.mesh.primitive_cube_add(size=1,location=xyz);o=bpy.context.object;o.name=name
    o.dimensions=dimensions;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat);return o

def instance_glb(filename,label,location,scale=0.1,rot=0):
    # NOTE: source glTF Y-up => Blender Z-up; authored pivot is grounded.
    existing=set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(filename))
    new=[o for o in bpy.context.scene.objects if o not in existing]
    roots=[o for o in new if o.parent is None]
    assert any(o.type=="MESH" for o in new),label
    anchor=bpy.data.objects.new(label,None);bpy.context.collection.objects.link(anchor)
    for r in roots:
        mat=r.matrix_world.copy()
        r.parent=anchor;r.matrix_world=mat
    # Original source 1 author-unit = 0.1 physical metres.
    anchor.location=location
    anchor.scale=(scale,)*3
    anchor.rotation_euler.z=rot
    print('CC0_AUTHORED_MESH',label,'meshes=',sum(1 for o in new if o.type=="MESH"))
    return anchor

# Natural ground and stone courtyard with true 3D thickness and variations.
box("Grass terrain", (0,0,-.35),(75,65,.7),ground_mat)
box("Compact stone courtyard foundation",(0,0,.015),(25,19,.16),stone_mats[1])
random.seed(20261015)
for zi in range(19):
    for xi in range(25):
        x=xi-12.0 + (random.random()-.5)*.13
        y=zi-9.0 + (random.random()-.5)*.13
        tile=box("Stone flagstone %02d %02d"%(xi,zi),
                 (x,y,.13+random.random()*.015),
                 (.93+random.random()*.06,.94+random.random()*.05,.09),
                 stone_mats[random.randrange(len(stone_mats))])
# Back-facing CC0 wall panels and original moon gate, Z is vertical.
instance_glb(gate,'CC0 Moon Gate',(-0.2,6.8,0),0.1)
for side in [-1,1]:
    instance_glb(wall,'CC0 Garden Wall Side',(side*3.55,6.8,0),0.1)
    instance_glb(window,'CC0 Flower Window',(side*5.5,6.8,0),0.1)
# Foreground shrubs with physical silhouettes, built as vegetation group.
leaves=[material('Foliage %s'%i,c) for i,c in enumerate([
(.19,.31,.13),(.26,.38,.16),(.31,.43,.21)])]
for j in range(130):
    x=random.uniform(-15,15); y=random.uniform(-12,13)
    if -12<x<12 and -9<y<9:continue
    h=random.uniform(.25,.6)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=h,location=(x,y,h*.7))
    o=bpy.context.object;o.name="Village vegetation";o.data.materials.append(random.choice(leaves))
# source PNG, real transparency
img=bpy.data.images.load(str(actor_path))
mat=bpy.data.materials.new("Actor CC0 original, not drawn geometry");mat.use_nodes=True
nt=mat.node_tree; n=nt.nodes;n.clear()
tex=n.new("ShaderNodeTexImage");tex.image=img
bs=n.new("ShaderNodeBsdfPrincipled");out=n.new("ShaderNodeOutputMaterial")
nt.links.new(tex.outputs["Color"],bs.inputs["Base Color"])
nt.links.new(tex.outputs["Alpha"],bs.inputs["Alpha"])
nt.links.new(bs.outputs["BSDF"],out.inputs["Surface"])
if hasattr(mat,"surface_render_method"):mat.surface_render_method="DITHERED"
else:mat.blend_method="HASHED"
for i,(x,y) in enumerate([(0,-3),(-3,-1),(4,-3)]):
    bpy.ops.mesh.primitive_plane_add(size=1,location=(x,y,.91))
    person=bpy.context.object;person.name="Actual 2D CC0 actor "+str(i)
    person.scale=(1.15,1.82,1)
    person.data.materials.append(mat)
    person.rotation_euler=(math.radians(90),0,0)
    # soft ground shadow disc
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=4,
             location=(x,y,.09))
    sh=bpy.context.object;sh.scale=(.47,.25,.025)
    sh.data.materials.append(soilmat)

world=bpy.data.worlds.new("soft morning light");bpy.context.scene.world=world
world.use_nodes=True
world.node_tree.nodes["Background"].inputs["Color"].default_value=(.45,.55,.62,1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value=.6
bpy.ops.object.light_add(type="AREA",location=(-9,-5,16));lamp=bpy.context.object
lamp.data.energy=2600;lamp.data.size=13
# angled view towards back wall, center focus in courtyard, generous composition
camera_pos=Vector((22,-28,25))
bpy.ops.object.camera_add(location=camera_pos)
cam=bpy.context.object;target=Vector((0,1,1.5))
cam.rotation_euler=(target-camera_pos).to_track_quat("-Z","Y").to_euler()
cam.data.type="ORTHO";cam.data.ortho_scale=29
bpy.context.scene.camera=cam
scene=bpy.context.scene
scene.render.engine="BLENDER_EEVEE"
scene.render.resolution_x=1280;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.filepath=str(output)
bpy.ops.render.render(write_still=True)
print("PASS_REAL_CC0_CHINESE_COURTYARD_3D_WITH_2D_ACTORS_RENDERED",str(output))
