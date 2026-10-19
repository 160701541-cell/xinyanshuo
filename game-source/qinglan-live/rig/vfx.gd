extends Node3D
# 仙侠特效样板：剑气 / 护体灵光 / 聚宝盆 / 掌天瓶，全部程序化生成（零素材）
const Stage := preload("res://rig/stage.gd")

func _unshaded(c: Color, add := true, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.vertex_color_use_as_albedo = false
	if add:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _glass(c: Color, alpha := 0.22) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _metal(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.85
	m.roughness = 0.28
	return m

func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh; mi.material_override = mat
	mi.position = pos; mi.rotation_degrees = rot; mi.scale = scl
	parent.add_child(mi)
	return mi

# ── ① 剑气·半月斩 ─────────────────────────────
func crescent_arc(radius := 0.62, span := 2.2, thick := 0.26, segs := 40) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var a: float = lerp(-span * 0.5, span * 0.5, t)
		var w := thick * sin(PI * t) * (0.55 + 0.45 * t) + 0.012
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(Vector3(cos(a) * radius, sin(a) * radius, 0))
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(Vector3(cos(a) * (radius + w), sin(a) * (radius + w), 0))
	st.generate_tangents()
	return st.commit()

func build_slash(p: Node3D) -> void:
	var arc := crescent_arc()
	_mesh(p, arc, _unshaded(Color(0.55, 0.95, 1.0), true, 0.95), Vector3(0, 1.05, 0), Vector3(0, 0, -20))
	_mesh(p, arc, _unshaded(Color(0.85, 1.0, 1.0), true, 0.55), Vector3(0, 1.05, 0.01), Vector3(0, 0, -20), Vector3(0.86, 0.86, 1))
	# 剑芒碎屑
	var par := CPUParticles3D.new()
	par.amount = 90; par.lifetime = 0.9; par.one_shot = false; par.emitting = true
	par.position = Vector3(0, 1.05, 0)
	par.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	par.emission_sphere_radius = 0.55
	par.direction = Vector3(1, 0.2, 0); par.spread = 55.0
	par.initial_velocity_min = 1.2; par.initial_velocity_max = 3.4
	par.gravity = Vector3(0.4, -0.6, 0)
	par.scale_amount_min = 0.02; par.scale_amount_max = 0.055
	par.mesh = BoxMesh.new()
	(par.mesh as BoxMesh).size = Vector3(0.04, 0.04, 0.004)
	par.material_override = _unshaded(Color(0.6, 0.95, 1.0))
	p.add_child(par)

# ── ② 护体灵光 ───────────────────────────────
func build_shield(p: Node3D) -> void:
	var sph := SphereMesh.new(); sph.radius = 0.52; sph.height = 1.16; sph.radial_segments = 24; sph.rings = 12
	_mesh(p, sph, _glass(Color(0.45, 0.85, 1.0), 0.16), Vector3(0, 0.85, 0), Vector3.ZERO, Vector3(1, 1.15, 1))
	var ring := TorusMesh.new(); ring.inner_radius = 0.50; ring.outer_radius = 0.545; ring.rings = 28; ring.ring_segments = 6
	var rm := _mesh(p, ring, _unshaded(Color(0.6, 0.95, 1.0), true, 0.9), Vector3(0, 0.55, 0))
	rm.set_meta("spin", Vector3(70, 0, 0))
	var ring2 := TorusMesh.new(); ring2.inner_radius = 0.46; ring2.outer_radius = 0.50; ring2.rings = 28; ring2.ring_segments = 6
	var rm2 := _mesh(p, ring2, _unshaded(Color(0.9, 0.85, 1.0), true, 0.8), Vector3(0, 1.10, 0))
	rm2.set_meta("spin", Vector3(-70, 0, 0))
	var par := CPUParticles3D.new()
	par.amount = 60; par.lifetime = 1.8
	par.position = Vector3(0, 0.2, 0)
	par.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	par.emission_ring_radius = 0.55; par.emission_ring_height = 0.05
	par.direction = Vector3(0, 1, 0); par.spread = 12.0
	par.initial_velocity_min = 0.5; par.initial_velocity_max = 1.1
	par.gravity = Vector3(0, 0.15, 0)
	par.scale_amount_min = 0.015; par.scale_amount_max = 0.04
	par.mesh = BoxMesh.new()
	(par.mesh as BoxMesh).size = Vector3(0.03, 0.03, 0.003)
	par.material_override = _unshaded(Color(0.65, 0.95, 1.0))
	p.add_child(par)

# ── ③ 聚宝盆 ─────────────────────────────────
func build_bowl(p: Node3D) -> void:
	var bowl := CylinderMesh.new(); bowl.top_radius = 0.40; bowl.bottom_radius = 0.20; bowl.height = 0.26
	bowl.radial_segments = 28
	_mesh(p, bowl, _metal(Color(0.72, 0.58, 0.26)), Vector3(0, 0.18, 0))
	var rim := TorusMesh.new(); rim.inner_radius = 0.385; rim.outer_radius = 0.435; rim.rings = 32; rim.ring_segments = 8
	_mesh(p, rim, _metal(Color(0.86, 0.72, 0.34)), Vector3(0, 0.31, 0), Vector3(0, 0, 0))
	# 盆里堆的元宝
	for i in 11:
		var ang := float(i) * 2.3
		var r := 0.10 + 0.09 * float(i % 4)
		var coin := CylinderMesh.new(); coin.top_radius = 0.055; coin.bottom_radius = 0.055; coin.height = 0.022
		coin.radial_segments = 10
		_mesh(p, coin, _metal(Color(0.95, 0.80, 0.34)), Vector3(cos(ang) * r, 0.30 + 0.03 * float(i % 3), sin(ang) * r), Vector3(0, ang * 30.0, 12))
	# 金光
	var half := SphereMesh.new(); half.radius = 0.30; half.height = 0.60; half.is_hemisphere = true
	_mesh(p, half, _glass(Color(1.0, 0.82, 0.35), 0.20), Vector3(0, 0.30, 0))
	var par := CPUParticles3D.new()
	par.amount = 80; par.lifetime = 2.0
	par.position = Vector3(0, 0.32, 0)
	par.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	par.emission_sphere_radius = 0.26
	par.direction = Vector3(0, 1, 0); par.spread = 22.0
	par.initial_velocity_min = 0.3; par.initial_velocity_max = 0.8
	par.gravity = Vector3(0, 0.25, 0)
	par.scale_amount_min = 0.012; par.scale_amount_max = 0.035
	par.mesh = BoxMesh.new()
	(par.mesh as BoxMesh).size = Vector3(0.03, 0.03, 0.004)
	par.material_override = _unshaded(Color(1.0, 0.85, 0.4))
	p.add_child(par)

# ── ④ 掌天瓶（凡人修仙传）──────────────────────
func build_bottle(p: Node3D) -> void:
	var body := SphereMesh.new(); body.radius = 0.16; body.height = 0.40; body.radial_segments = 20; body.rings = 10
	_mesh(p, body, _glass(Color(0.30, 0.85, 0.62), 0.55), Vector3(0, 0.42, 0), Vector3.ZERO, Vector3(1, 1.25, 1))
	var neck := CylinderMesh.new(); neck.top_radius = 0.045; neck.bottom_radius = 0.075; neck.height = 0.13
	_mesh(p, neck, _glass(Color(0.35, 0.90, 0.66), 0.65), Vector3(0, 0.665, 0))
	var cap := CylinderMesh.new(); cap.top_radius = 0.06; cap.bottom_radius = 0.06; cap.height = 0.045
	_mesh(p, cap, _metal(Color(0.82, 0.68, 0.30)), Vector3(0, 0.742, 0))
	var glow := SphereMesh.new(); glow.radius = 0.30; glow.height = 0.60
	_mesh(p, glow, _glass(Color(0.35, 1.0, 0.65), 0.10), Vector3(0, 0.42, 0))
	# 瓶口溢出的灵光
	var par := CPUParticles3D.new()
	par.amount = 70; par.lifetime = 1.6
	par.position = Vector3(0, 0.76, 0)
	par.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	par.emission_sphere_radius = 0.05
	par.direction = Vector3(0, 1, 0); par.spread = 30.0
	par.initial_velocity_min = 0.4; par.initial_velocity_max = 1.2
	par.gravity = Vector3(0, 0.35, 0)
	par.scale_amount_min = 0.012; par.scale_amount_max = 0.04
	par.mesh = BoxMesh.new()
	(par.mesh as BoxMesh).size = Vector3(0.03, 0.03, 0.003)
	par.material_override = _unshaded(Color(0.45, 1.0, 0.7))
	p.add_child(par)

func _ready() -> void:
	Stage.setup(self, Color(0.06, 0.07, 0.09), 0.55)
	Stage.grid_ground(self, 8.0, 0.5)
	var builders: Array[Callable] = [build_slash, build_shield, build_bowl, build_bottle]
	var names: Array[String] = ["剑气·半月斩", "护体灵光", "聚宝盆", "掌天瓶·凡人修仙传"]
	for i in 4:
		var g := Node3D.new(); add_child(g)
		g.position = Vector3(-2.25 + i * 1.5, 0, 0)
		builders[i].call(g)
		Stage.label(self, names[i], Vector3(-2.25 + i * 1.5, 0.02, -0.75), 28)
	Stage.camera(self, Vector3(0, 1.55, -6.0), Vector3(0, 0.95, 0), 30)
	# 让粒子跑几帧再截图
	for f in 30:
		await get_tree().process_frame
	await Shot.grab(self, "res://out/vfx.png")
	get_tree().quit()
