extends Node3D
# 特效重制（ART_DIRECTION 第 3/5/7 条）：C 形弧、上尖下宽、饱和面积 ≤5%
const JADE   := Color("57C7A3")
const WHITE  := Color("FFF3DC")
const GOLD   := Color("E8B33B")
const CINNABAR := Color("C0392B")
const INK    := Color("14161A")

func _mat(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(c.r, c.g, c.b, 1.0)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

# 一段 C 形弧带：两端收成尖（上尖下宽），中段最宽
func arc(parent: Node3D, center: Vector3, radius: float, a0: float, a1: float, width: float, c: Color, e := 2.0) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 48
	for i in range(n):
		var t0 := float(i) / float(n)
		var t1 := float(i + 1) / float(n)
		var p0 := _pt(center, radius, a0, a1, t0)
		var p1 := _pt(center, radius, a0, a1, t1)
		var w0 := width * pow(sin(PI * clamp(t0, 0.001, 0.999)), 0.65)
		var w1 := width * pow(sin(PI * clamp(t1, 0.001, 0.999)), 0.65)
		var dr0 := p0.normalized() * w0
		var dr1 := p1.normalized() * w1
		var a := p0 - dr0
		var b := p0 + dr0
		var c2 := p1 + dr1
		var d := p1 - dr1
		for v in [a, b, c2, a, c2, d]:
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _mat(c, e)
	parent.add_child(mi)
	return mi

func _pt(center: Vector3, r: float, a0: float, a1: float, t: float) -> Vector3:
	var a := deg_to_rad(lerpf(a0, a1, t))
	return center + Vector3(cos(a) * r, sin(a) * r, 0)

func _boxlight(p: Node3D, pos: Vector3, w: float, h: float) -> void:
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.position = pos
	var m := _mat(JADE, 0.9)
	mi.material_override = m
	p.add_child(mi)

func ring(parent: Node3D, center: Vector3, r: float, thick: float, c: Color, e := 1.6, squash := 1.0) -> MeshInstance3D:
	var tm := TorusMesh.new()
	tm.inner_radius = r
	tm.outer_radius = r + thick
	tm.rings = 48
	tm.ring_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.position = center
	mi.scale = Vector3(1, squash, 1)
	mi.material_override = _mat(c, e)
	parent.add_child(mi)
	return mi

# ① 剑气·半月斩：三层 C 形弧，由内到外 玉→米白，越外越淡
func build_slash(p: Node3D) -> void:
	arc(p, Vector3(0, 0, 0), 0.34, -40.0, 140.0, 0.055, WHITE, 2.6)
	arc(p, Vector3(0, 0, 0), 0.46, -34.0, 146.0, 0.085, JADE, 2.2)
	arc(p, Vector3(0, 0, 0), 0.60, -26.0, 154.0, 0.052, JADE.darkened(0.18), 1.2)

# ② 护体灵光：两圈低饱和玉环 + 一层极淡的钟形罩
func build_ward(p: Node3D) -> void:
	ring(p, Vector3(0, 0.72, 0), 0.44, 0.012, JADE, 1.4, 0.42)
	ring(p, Vector3(0, 0.40, 0), 0.56, 0.012, JADE, 1.3, 0.40)
	ring(p, Vector3(0, 0.08, 0), 0.64, 0.010, JADE, 1.0, 0.38)
	# 内壁半球：只渲远端面（cull_front）+ 极低 alpha，得到"有体积但不糊"的罩
	var dm := SphereMesh.new()
	dm.radius = 0.68
	dm.height = 1.30
	var di := MeshInstance3D.new()
	di.mesh = dm
	di.position = Vector3(0, 0.30, 0)
	var fm := ShaderMaterial.new()
	fm.shader = load("res://rig/fresnel.gdshader")
	fm.set_shader_parameter("tint", JADE)
	fm.set_shader_parameter("power", 3.4)
	fm.set_shader_parameter("strength", 1.05)
	di.material_override = fm
	p.add_child(di)
	# 四条竖向光条撑起"罩"的骨架
	# 罩体已由菲涅尔撑起，竖条只留 3 根做方位暗示
	for k in range(3):
		var ang := deg_to_rad(45.0 + 120.0 * float(k))
		_boxlight(p, Vector3(cos(ang) * 0.62, 0.46, sin(ang) * 0.62), 0.005, 0.60)

# ③ 聚宝盆：金钵 + 上升的金粒 + 顶上一枚玉光
func build_basin(p: Node3D) -> void:
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.34
	bowl.bottom_radius = 0.20
	bowl.height = 0.20
	bowl.radial_segments = 24
	var bm := MeshInstance3D.new()
	bm.mesh = bowl
	bm.position = Vector3(0, 0.10, 0)
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.albedo_color = GOLD.darkened(0.15)
	gm.emission_enabled = true
	gm.emission = GOLD
	gm.emission_energy_multiplier = 0.55
	bm.material_override = gm
	p.add_child(bm)
	ring(p, Vector3(0, 0.21, 0), 0.30, 0.010, WHITE, 1.4, 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(10):
		var s := SphereMesh.new()
		s.radius = 0.012 + rng.randf() * 0.012
		s.height = s.radius * 2.0
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.position = Vector3(rng.randf_range(-0.22, 0.22), 0.26 + rng.randf() * 0.55, rng.randf_range(-0.10, 0.10))
		mi.material_override = _mat(GOLD, 2.2)
		p.add_child(mi)
	ring(p, Vector3(0, 0.78, 0), 0.20, 0.012, JADE, 1.8, 0.6)
