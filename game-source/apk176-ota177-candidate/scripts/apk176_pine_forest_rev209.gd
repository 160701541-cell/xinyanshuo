extends RefCounted
## 《苍岚·人生世界》rev209 松林与竹丛（REV209-VEG-001）
##
## 目的：把"绿球插在棕棍上"的远景树换成黄山松（三层扁锥合并成一棵树的单一网格）
## 与竹丛；成片分布用低频噪声做林窗，避免整片均匀撒点。
##
## 关键约定（与 rev208 一致）：
##   - 高程只用 terrain.call("height_at", x, z)，不自己造地形
##   - 全部 MultiMesh，实例色做 ±14% 明度扰动，手机上只有 3 次 draw call
##   - 无光照平涂（SHADING_MODE_UNSHADED + 顶点色），与本作"工笔平涂"一致
##
## 安全性：本模块只做"新增"。它不替换任何现有节点，未被调用时零副作用。

const MODULE: String = "apk176_pine_forest_rev209.gd"

const PINE_COUNT: int = 9000
const BAMBOO_COUNT: int = 1600
const PINE_HI: float = 1560.0
const PINE_LO: float = 1120.0
const BAMBOO_HI: float = 1230.0
const BAMBOO_LO: float = 1080.0
const SPAN_X: float = 1700.0
const SPAN_Z0: float = -2300.0
const SPAN_Z1: float = 1200.0

var _trunk_mesh: Mesh
var _tier_mesh: Mesh
var _bamboo_mesh: Mesh
var _ready_built: bool = false

func initialize() -> Dictionary:
	_trunk_mesh = _make_trunk_mesh()
	_tier_mesh = _make_tier_mesh()
	_bamboo_mesh = _make_bamboo_mesh()
	_ready_built = true
	return {"module": MODULE, "ok": true,
		"meshes": {"trunk": _trunk_mesh != null, "tier": _tier_mesh != null, "bamboo": _bamboo_mesh != null}}

## world: 世界根节点；terrain: 必须提供 height_at(x, z)
func spawn(world: Node3D, terrain: Node3D, density: float = 1.0) -> Dictionary:
	if not _ready_built:
		initialize()
	if world == null or terrain == null or not terrain.has_method("height_at"):
		return {"module": MODULE, "ok": false, "reason": "地形缺少 height_at"}

	var pines: Array[Vector3] = _scatter(terrain, int(PINE_COUNT * density), PINE_LO, PINE_HI, 0.62)
	var bamboo: Array[Vector3] = _scatter(terrain, int(BAMBOO_COUNT * density), BAMBOO_LO, BAMBOO_HI, 0.28)
	_draw(world, _trunk_mesh, pines, Color(0.20, 0.155, 0.125), 0.75, 1.45, 5.0, 0.10, "rev209_trunks")
	_draw(world, _tier_mesh, pines, Color(0.135, 0.255, 0.195), 0.70, 1.55, 0.0, 0.16, "rev209_tiers")
	_draw(world, _bamboo_mesh, bamboo, Color(0.20, 0.34, 0.24), 0.70, 1.30, 0.0, 0.14, "rev209_bamboo")
	return {"module": MODULE, "ok": true, "pines": pines.size(), "bamboo": bamboo.size()}

# ---------------- 地形采样 ----------------

func _height(terrain: Node3D, x: float, z: float) -> float:
	return float(terrain.call("height_at", x, z))

func _slope(terrain: Node3D, x: float, z: float) -> float:
	var d: float = 30.0
	var hx: float = _height(terrain, x + d, z) - _height(terrain, x - d, z)
	var hz: float = _height(terrain, x, z + d) - _height(terrain, x, z - d)
	return sqrt(hx * hx + hz * hz) / (2.0 * d)

func _scatter(terrain: Node3D, n: int, hlo: float, hhi: float, slope_max: float) -> Array[Vector3]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261019
	var pts: Array[Vector3] = []
	var tries: int = 0
	var cap: int = n * 24
	while pts.size() < n and tries < cap:
		tries += 1
		var x: float = rng.randf_range(-SPAN_X, SPAN_X)
		var z: float = rng.randf_range(SPAN_Z0, SPAN_Z1)
		var h: float = _height(terrain, x, z)
		if h < hlo or h > hhi:
			continue
		# 林窗：低频噪声，制造疏密而不是均匀撒点
		var grove: float = sin(x * 0.0041) * cos(z * 0.0037) + sin((x + z) * 0.0019) * 0.8
		if grove < -0.35:
			continue
		if _slope(terrain, x, z) >= slope_max:
			continue
		pts.append(Vector3(x, h, z))
	return pts

# ---------------- 绘制 ----------------

func _draw(world: Node3D, mesh: Mesh, pts: Array[Vector3], col: Color,
		slo: float, shi: float, yoff: float, tint: float, node_name: String) -> void:
	if mesh == null or pts.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = pts.size()
	for i in pts.size():
		var s: float = rng.randf_range(slo, shi)
		var tilt := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.05, 0.05))
		var b := tilt.scaled(Vector3(s, s * rng.randf_range(0.9, 1.2), s))
		mm.set_instance_transform(i, Transform3D(b, pts[i] + Vector3(0, yoff * s, 0)))
		var k: float = 1.0 + rng.randf_range(-tint, tint)
		mm.set_instance_color(i, Color(col.r * k, col.g * k, col.b * k))
	var mi := MultiMeshInstance3D.new()
	mi.name = node_name
	mi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi)

# ---------------- 网格 ----------------

func _make_trunk_mesh() -> Mesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.55
	c.bottom_radius = 1.25
	c.height = 10.0
	c.radial_segments = 5
	c.rings = 1
	return c

## 一棵松 = 三层扁锥（越高越小），一次 draw 画完整片松林
func _make_tier_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cone(st, 6.6, 3.30, 1.55)
	_cone(st, 8.5, 2.55, 1.40)
	_cone(st, 10.2, 1.75, 1.25)
	st.generate_normals()
	return st.commit()

func _cone(st: SurfaceTool, y: float, r: float, h: float, seg: int = 7) -> void:
	var apex := Vector3(0, y + h, 0)
	for i in seg:
		var a0: float = TAU * float(i) / float(seg)
		var a1: float = TAU * float(i + 1) / float(seg)
		var p0 := Vector3(cos(a0) * r, y, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, y, sin(a1) * r)
		st.add_vertex(p0)
		st.add_vertex(p1)
		st.add_vertex(apex)
		st.add_vertex(Vector3(0, y, 0))
		st.add_vertex(p1)
		st.add_vertex(p0)

## 一丛竹 = 三根错落竹竿 + 顶部斜叶
func _make_bamboo_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var ang: float = TAU * float(k) / 3.0
		var bx: float = cos(ang) * 0.6
		var bz: float = sin(ang) * 0.6
		var hh: float = 7.0 + float(k) * 1.1
		_culm(st, Vector3(bx, 0.0, bz), hh, 0.16)
		_blades(st, Vector3(bx, hh - 0.6, bz))
	st.generate_normals()
	return st.commit()

func _culm(st: SurfaceTool, base: Vector3, h: float, r: float, seg: int = 5) -> void:
	for i in seg:
		var a0: float = TAU * float(i) / float(seg)
		var a1: float = TAU * float(i + 1) / float(seg)
		var p0: Vector3 = base + Vector3(cos(a0) * r, 0.0, sin(a0) * r)
		var p1: Vector3 = base + Vector3(cos(a1) * r, 0.0, sin(a1) * r)
		var q0: Vector3 = p0 + Vector3(0.0, h, 0.0)
		var q1: Vector3 = p1 + Vector3(0.0, h, 0.0)
		st.add_vertex(p0); st.add_vertex(p1); st.add_vertex(q1)
		st.add_vertex(p0); st.add_vertex(q1); st.add_vertex(q0)

func _blades(st: SurfaceTool, top: Vector3) -> void:
	for k in 3:
		var ang: float = TAU * float(k) / 3.0 + 0.4
		var tip: Vector3 = top + Vector3(cos(ang) * 1.9, 0.5, sin(ang) * 1.9)
		var w: Vector3 = Vector3(-sin(ang) * 0.42, 0.0, cos(ang) * 0.42)
		st.add_vertex(top - w)
		st.add_vertex(top + w)
		st.add_vertex(tip)

func summary() -> Dictionary:
	return {"module": MODULE, "built": _ready_built,
		"pine_count": PINE_COUNT, "bamboo_count": BAMBOO_COUNT,
		"height_api": "terrain.height_at(x, z)"}
