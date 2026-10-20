extends RefCounted
## NPC 脸型变形（FaceMorph）
##
## 让同一个底模（character_ea.glb）按 NPC 的 id 长出稳定、各不相同的脸。
## 只改骨相/体块（11 个对称参数），不碰五官贴片：贴片由 cloth.gd 按头部包围盒摆放，
## 所以变形必须在 cloth.gd 读完 GLB、算包围盒之前做。
##
## 核心是一个"按位置计算的位移场" displace(p, params, frame)：
##   - 只依赖点的位置，所以对 SuperHero_Male / Eyes / Eyebrows 三块网格施加同一个函数，
##     眼睛、眉毛会和脸皮一起动，不会脱开；UV 缝处重合的顶点也保持重合。
##   - 位移场在下巴以下（t < T_MIN）恒为 0，不会影响脖子以下的身体、袖、袍。
##   - 左右严格镜像（dx 奇对称，dy/dz 偶对称）。
##
## 所有参数范围 [-1, 1]，0 = 底模原样，正值 = "更多"（更宽、更长、更突出、更深）。
## 用法见 docs/NPC_FACE_MORPH.md。

# ---- 参数表（顺序固定：种子生成按此顺序取随机数，改顺序会让所有 NPC 换脸）----
const PARAM_NAMES: PackedStringArray = [
	"face_width", "jaw_width", "chin_length", "chin_forward", "cheek_bone",
	"brow_ridge", "eye_socket_depth", "nose_bridge", "nose_tip", "nose_width",
	"forehead",
]

const PARAM_LABELS_CN: Dictionary = {
	"face_width": "脸宽", "jaw_width": "下颌宽", "chin_length": "下巴长",
	"chin_forward": "下巴前伸", "cheek_bone": "颧骨", "brow_ridge": "眉骨",
	"eye_socket_depth": "眼窝深", "nose_bridge": "鼻梁高", "nose_tip": "鼻头",
	"nose_width": "鼻翼宽", "forehead": "额头前凸",
}

## |参数| = 1 时的最大位移（米；face_width / jaw_width 是相对 x 的比例）
const SCALE: Dictionary = {
	"face_width": 0.05, "jaw_width": 0.10,
	"chin_length": 0.012, "chin_forward": 0.010,
	"cheek_bone": 0.006, "brow_ridge": 0.007, "eye_socket_depth": 0.004,
	"nose_bridge": 0.006, "nose_tip": 0.007, "nose_width": 0.004,
	"forehead": 0.006,
}

## 位移场作用的最低高度（归一化：下巴 = 0，头顶 = 1）。更低处原样不动。
const T_MIN: float = -0.08

## 按 character_ea.glb 实测标定（头顶 y≈1.81，下巴 y≈1.58，正面朝 +Z）。
## 默认写死而不是每次从网格里量：NPC 的脸必须跨版本稳定。
const DEFAULT_FRAME: Dictionary = {
	"top_y": 1.8096, "chin_y": 1.5822,
	"center_x": 0.0, "center_z": 0.0,
	"half_w": 0.075, "front": 1.0,
}

## 一个 id 对应的参数集必须永远不变（存档里的 NPC 不能换脸）。
## 改动种子算法/参数顺序前，先看 tests/npc_face_morph_test.gd 里的金标准。
const _FNV_OFFSET: int = 0x811C9DC5
const _FNV_PRIME: int = 0x01000193
const _MASK32: int = 0xFFFFFFFF


# ---------------------------------------------------------------- 参数

## 由 NPC id 生成一组稳定的参数。
## strength：整体幅度（0 = 底模，1 = 全幅）；bias：按参数名叠加的偏置（如 {"nose_bridge": -0.3}）。
static func params_from_id(npc_id: String, strength: float = 1.0, bias: Dictionary = {}) -> Dictionary:
	var h: int = _FNV_OFFSET
	for b in npc_id.to_utf8_buffer():
		h = ((h ^ int(b)) * _FNV_PRIME) & _MASK32
	var s: int = h if h != 0 else 0x9E3779B9
	for _i in 3:
		s = _xorshift32(s)
	var out: Dictionary = {}
	for name in PARAM_NAMES:
		s = _xorshift32(s)
		var r1: float = float(s) / 4294967296.0
		s = _xorshift32(s)
		var r2: float = float(s) / 4294967296.0
		var v: float = (r1 + r2 - 1.0) * strength + float(bias.get(name, 0.0))
		out[name] = clampf(v, -1.0, 1.0)
	return out


## 返回错误描述列表；空 = 合法。未出现的参数视为 0。
static func validate(params: Dictionary) -> PackedStringArray:
	var errs: PackedStringArray = PackedStringArray()
	for k in params.keys():
		if not (k is String):
			errs.append("参数名不是字符串: %s" % str(k))
			continue
		var key: String = k
		if not PARAM_NAMES.has(key):
			errs.append("未知参数: %s" % key)
			continue
		var v: Variant = params[key]
		if not (v is float or v is int):
			errs.append("%s 不是数字" % key)
			continue
		var f: float = float(v)
		if is_nan(f) or is_inf(f):
			errs.append("%s 不是有限数" % key)
		elif absf(f) > 1.0:
			errs.append("%s = %s 超出 [-1, 1]" % [key, str(f)])
	return errs


# ---------------------------------------------------------------- 位移场

## 用网格顶点量一个 frame（换了别的底模时用；默认的 DEFAULT_FRAME 只对 character_ea.glb 标定）。
static func make_frame(verts: PackedVector3Array) -> Dictionary:
	var top: float = -1e9
	var low: float = 1e9
	for v in verts:
		low = minf(low, v.y)
		if absf(v.x) < 0.2:
			top = maxf(top, v.y)
	return {
		"top_y": top, "chin_y": top - 0.125 * (top - low),
		"center_x": 0.0, "center_z": 0.0, "half_w": 0.075, "front": 1.0,
	}


## 点 p 在给定参数下的新位置。纯函数，只依赖 p。
## 也用来搬动别的东西（发帽顶点、五官贴片锚点）：对它们调用同一个函数即可跟脸走。
static func displace(p: Vector3, params: Dictionary, frame: Dictionary = DEFAULT_FRAME) -> Vector3:
	var chin_y: float = float(frame["chin_y"])
	var t: float = (p.y - chin_y) / (float(frame["top_y"]) - chin_y)
	if t < T_MIN:
		return p
	var rel_x: float = p.x - float(frame["center_x"])
	var au: float = absf(rel_x) / float(frame["half_w"])
	var sx: float = signf(rel_x)
	var fr: float = float(frame["front"])
	# 0 = 头的中截面及更靠后，1 = 离中截面 5cm 以上的正面。后脑不被脸部参数凹进去。
	var wf: float = _ss(0.0, 0.05, (p.z - float(frame["center_z"])) * fr)

	var dx: float = 0.0
	var dy: float = 0.0
	var dz: float = 0.0
	var a: float

	a = _g(params, "face_width")
	if a != 0.0:
		dx += a * SCALE["face_width"] * rel_x * _ss(T_MIN, 0.12, t)

	a = _g(params, "jaw_width")
	if a != 0.0:
		dx += a * SCALE["jaw_width"] * rel_x * _ss(T_MIN, 0.08, t) * (1.0 - _ss(0.20, 0.50, t))

	var wc: float = _ss(T_MIN, 0.0, t) * (1.0 - _ss(0.06, 0.30, t)) * wf
	a = _g(params, "chin_length")
	if a != 0.0:
		dy -= a * SCALE["chin_length"] * wc
	a = _g(params, "chin_forward")
	if a != 0.0:
		dz += a * SCALE["chin_forward"] * wc

	a = _g(params, "cheek_bone")
	if a != 0.0:
		var wk: float = _bell(t, 0.45, 0.14) * _ss(0.25, 0.70, au) * wf
		dx += sx * a * SCALE["cheek_bone"] * wk
		dz += a * SCALE["cheek_bone"] * 0.67 * wk

	a = _g(params, "brow_ridge")
	if a != 0.0:
		dz += a * SCALE["brow_ridge"] * _bell(t, 0.64, 0.10) * (1.0 - _ss(0.70, 1.10, au)) * wf

	a = _g(params, "eye_socket_depth")
	if a != 0.0:
		dz -= a * SCALE["eye_socket_depth"] * _bell(t, 0.52, 0.08) * _ss(0.12, 0.30, au) * (1.0 - _ss(0.55, 0.90, au)) * wf

	a = _g(params, "nose_bridge")
	if a != 0.0:
		dz += a * SCALE["nose_bridge"] * _bell(t, 0.48, 0.12) * (1.0 - _ss(0.15, 0.35, au)) * wf

	var wn: float = _bell(t, 0.33, 0.07) * (1.0 - _ss(0.10, 0.30, au)) * wf
	a = _g(params, "nose_tip")
	if a != 0.0:
		dz += a * SCALE["nose_tip"] * wn
		dy += a * 0.003 * wn

	a = _g(params, "nose_width")
	if a != 0.0:
		dx += sx * a * SCALE["nose_width"] * _bell(t, 0.33, 0.07) * _ss(0.08, 0.20, au) * (1.0 - _ss(0.25, 0.45, au)) * wf

	a = _g(params, "forehead")
	if a != 0.0:
		dz += a * SCALE["forehead"] * _bell(t, 0.82, 0.18) * (1.0 - _ss(0.70, 1.20, au)) * wf

	return Vector3(p.x + dx, p.y + dy, p.z + dz * fr)


# ---------------------------------------------------------------- 网格

## 对一个 surface 的数组做变形，返回 {"arrays", "moved", "max_disp"}。不修改传入的数组。
## 顶点位置改变；骨骼/权重/UV/索引原样保留（蒙皮不破）；受影响处重算法线。
static func morph_arrays(arrays: Array, params: Dictionary, frame: Dictionary = DEFAULT_FRAME) -> Dictionary:
	var src: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: int = src.size()
	var out: PackedVector3Array = src.duplicate()
	var moved: PackedByteArray = PackedByteArray()
	moved.resize(n)
	var count: int = 0
	var max_d: float = 0.0
	for i in n:
		var q: Vector3 = displace(src[i], params, frame)
		var d: float = q.distance_to(src[i])
		if d > 1e-9:
			out[i] = q
			moved[i] = 1
			count += 1
			max_d = maxf(max_d, d)
	var res: Array = arrays.duplicate()
	res[Mesh.ARRAY_VERTEX] = out
	if count > 0 and arrays[Mesh.ARRAY_INDEX] != null and arrays[Mesh.ARRAY_NORMAL] != null:
		res[Mesh.ARRAY_NORMAL] = _renormal(src, out, arrays[Mesh.ARRAY_INDEX], arrays[Mesh.ARRAY_NORMAL], moved)
	return {"arrays": res, "moved": count, "max_disp": max_d}


## 对节点树里所有 MeshInstance3D 施加同一个位移场（会把 mesh 换成新的 ArrayMesh，
## 原 mesh 资源不被修改）。返回 {"ok", "meshes", "moved", "max_disp", "errors"}。
## 必须在 cloth.gd 的 _grab() 之前调用。
static func apply_to_tree(root: Node, params: Dictionary, frame: Dictionary = DEFAULT_FRAME) -> Dictionary:
	var stats: Dictionary = {"ok": false, "meshes": 0, "moved": 0, "max_disp": 0.0, "errors": PackedStringArray()}
	var errs: PackedStringArray = validate(params)
	if not errs.is_empty():
		stats["errors"] = errs
		push_error("NpcFaceMorph: 参数不合法: " + "; ".join(errs))
		return stats
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		var am: ArrayMesh = mi.mesh as ArrayMesh
		if am == null:
			continue
		if am.get_blend_shape_count() > 0:
			push_warning("NpcFaceMorph: %s 带 blend shape，跳过（位移场不作用于形态键）" % mi.name)
			continue
		var nm: ArrayMesh = ArrayMesh.new()
		nm.resource_name = am.resource_name
		var mesh_moved: int = 0
		for s in am.get_surface_count():
			var r: Dictionary = morph_arrays(am.surface_get_arrays(s), params, frame)
			var flags: int = am.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
			nm.add_surface_from_arrays(am.surface_get_primitive_type(s), r["arrays"], [], {}, flags)
			nm.surface_set_material(s, am.surface_get_material(s))
			nm.surface_set_name(s, am.surface_get_name(s))
			mesh_moved += int(r["moved"])
			stats["max_disp"] = maxf(float(stats["max_disp"]), float(r["max_disp"]))
		if mesh_moved > 0:
			mi.mesh = nm
			stats["meshes"] = int(stats["meshes"]) + 1
			stats["moved"] = int(stats["moved"]) + mesh_moved
	stats["ok"] = true
	return stats


# ---------------------------------------------------------------- 内部

static func _g(params: Dictionary, key: String) -> float:
	return float(params.get(key, 0.0))


static func _ss(a: float, b: float, x: float) -> float:
	var t: float = clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## 升余弦钟形：中心 c、半宽 w，|x-c| >= w 处为 0，处处 C1 连续。
static func _bell(x: float, c: float, w: float) -> float:
	var d: float = clampf((x - c) / w, -1.0, 1.0)
	return 0.5 * (1.0 + cos(PI * d))


static func _xorshift32(s: int) -> int:
	s = (s ^ (s << 13)) & _MASK32
	s = s ^ (s >> 17)
	s = (s ^ (s << 5)) & _MASK32
	return s


## 只重算"被移动的顶点及其相邻三角形"涉及的法线；按原始位置焊接，
## 这样 UV 缝两侧的顶点法线一致、不出现缝线。朝向以原法线为准（避免绕序约定带来的翻转）。
static func _renormal(src: PackedVector3Array, out: PackedVector3Array, idx: PackedInt32Array, old: PackedVector3Array, moved: PackedByteArray) -> PackedVector3Array:
	var n: int = src.size()
	var keys: Array[Vector3i] = []
	keys.resize(n)
	for i in n:
		keys[i] = Vector3i(roundi(src[i].x * 10000.0), roundi(src[i].y * 10000.0), roundi(src[i].z * 10000.0))
	var acc: Dictionary = {}
	var affected: Dictionary = {}
	var t: int = 0
	while t + 2 < idx.size():
		var i0: int = idx[t]
		var i1: int = idx[t + 1]
		var i2: int = idx[t + 2]
		t += 3
		var fn: Vector3 = (out[i1] - out[i0]).cross(out[i2] - out[i0])
		var hit: bool = moved[i0] == 1 or moved[i1] == 1 or moved[i2] == 1
		for i in [i0, i1, i2]:
			var k: Vector3i = keys[i]
			acc[k] = (acc[k] as Vector3 if acc.has(k) else Vector3.ZERO) + fn
			if hit:
				affected[k] = true
	var res: PackedVector3Array = old.duplicate()
	for i in n:
		if not affected.has(keys[i]):
			continue
		var nn: Vector3 = (acc[keys[i]] as Vector3)
		if nn.length_squared() < 1e-20:
			continue
		nn = nn.normalized()
		if nn.dot(old[i]) < 0.0:
			nn = -nn
		res[i] = nn
	return res
