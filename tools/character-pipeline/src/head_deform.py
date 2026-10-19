import bpy, sys, math
from mathutils import Vector

SRC = "/root/game/assets/cc0/character.glb"
DST = "/root/game/assets/cc0/character_ea.glb"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)

# 取顶点最多的网格（身体）
target = None; best = -1
for o in bpy.data.objects:
    if o.type == 'MESH' and len(o.data.vertices) > best:
        best = len(o.data.vertices); target = o
print("MESH", target.name, best)

me = target.data
zs = [v.co.z for v in me.vertices]
zmin, zmax = min(zs), max(zs)
H = zmax - zmin
head_z = zmax - 0.135 * H        # 头底（约下巴）
eye_z  = zmax - 0.078 * H        # 眼线

# 判断正面朝向：头部区域里 |y| 最大的顶点就是鼻尖
head_vs = [v for v in me.vertices if v.co.z > head_z]
nose = max(head_vs, key=lambda v: abs(v.co.y))
f = 1.0 if nose.co.y > 0 else -1.0
print("FRONT", f, "zmin", round(zmin,3), "zmax", round(zmax,3), "head_z", round(head_z,3), "eye_z", round(eye_z,3))

n_brow = n_jaw = n_nose = n_all = 0
for v in me.vertices:
    c = v.co
    if c.z < head_z:
        continue
    n_all += 1
    # 整脸收窄
    c.x *= 0.935
    # 收下颌
    if c.z < eye_z - 0.055:
        c.x *= 0.86
        c.y -= 0.003 * f
        n_jaw += 1
    # 压眉骨：眼线以上 0~2.5cm 的前额/眉区
    if eye_z <= c.z <= eye_z + 0.025 and (c.y * f) > 0.0:
        c.y -= 0.0070 * f
        n_brow += 1
    # 低鼻梁：中线附近
    if abs(c.x) < 0.016 and (eye_z - 0.03) < c.z < (eye_z + 0.02) and (c.y * f) > 0.02:
        c.y -= 0.0060 * f
        n_nose += 1

print("VERTS head", n_all, "brow", n_brow, "jaw", n_jaw, "nose", n_nose)

for o in bpy.data.objects:
    o.select_set(True)
bpy.context.view_layer.objects.active = target
bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', use_selection=False,
                          export_yup=True, export_skins=True, export_apply=False)
print("WROTE", DST)
