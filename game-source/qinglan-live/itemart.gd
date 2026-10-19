extends Node3D

var vb: VoxelBuilder
var solid: StandardMaterial3D
var emis: StandardMaterial3D

func _ready() -> void:
	solid = StandardMaterial3D.new()
	solid.vertex_color_use_as_albedo = true
	solid.roughness = 0.55
	solid.metallic = 0.35
	emis = StandardMaterial3D.new()
	emis.vertex_color_use_as_albedo = true
	emis.emission_enabled = true
	emis.emission = Color(0.9, 0.95, 1.0)
	emis.emission_energy_multiplier = 0.8
	_build_sword(Vector3(-3.2, 0, 0))
	_build_pill(Vector3(0, 0, 0))
	_build_tea(Vector3(3.4, 0, 0))
	_env()
	_cam()

func _env() -> void:
	var we := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.06, 0.07, 0.09)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.40, 0.50)
	e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.glow_enabled = true; e.glow_intensity = 0.55; e.glow_hdr_threshold = 1.0
	we.environment = e; add_child(we)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-38, 34, 0); l.light_energy = 2.2
	l.light_color = Color(1.0, 0.95, 0.86)
	add_child(l)
	var r := OmniLight3D.new()
	r.position = Vector3(-2, 2.5, 3.5); r.light_energy = 6.0; r.omni_range = 9
	r.light_color = Color(0.55, 0.75, 1.0); add_child(r)

func _cam() -> void:
	var c := Camera3D.new(); c.position = Vector3(0, 1.7, 8.6)
	c.fov = 32; add_child(c); c.look_at(Vector3(0, 1.1, 0), Vector3.UP)

func _add(mi: MeshInstance3D, pos: Vector3, scale: float) -> void:
	mi.position = pos; mi.scale = Vector3.ONE * scale; add_child(mi)

func _build_sword(pos: Vector3) -> void:
	vb = VoxelBuilder.new()
	# 剑：刃 + 血槽 + 护手 + 柄 + 缠绳 + 剑首
	vb.box(-1, 0, -1, 2, 26, 1, Color(0.78, 0.84, 0.92), 0.02)
	vb.box(-1, 0, 0, 2, 26, 1, Color(0.92, 0.96, 1.0), 0.01)
	vb.box(0, 0, -1, 1, 26, 0, Color(0.55, 0.62, 0.72))
	vb.box(-5, 26, -2, 6, 29, 1, Color(0.78, 0.62, 0.28), 0.02)
	vb.box(-1, 29, -1, 2, 35, 1, Color(0.30, 0.22, 0.16))
	for i in 3:
		vb.box(-1, 30 + i * 2, -1, 2, 31 + i * 2, 1, Color(0.52, 0.30, 0.22))
	vb.box(-2, 35, -1, 3, 37, 1, Color(0.80, 0.64, 0.30))
	var m: MeshInstance3D = vb.build(solid, emis)[0]
	_add(m, pos, 0.10)

func _build_pill(pos: Vector3) -> void:
	vb = VoxelBuilder.new()
	var base := Color(0.62, 0.52, 0.30)
	vb.sphere(0, 0, 0, 9.0, base, 0.02)
	for i in 3:
		for a in 12:
			var ang := TAU * float(a) / 12.0 + float(i) * 0.7
			vb.put(int(round(cos(ang) * 6.0)), -3 + i * 3, int(round(sin(ang) * 6.0)), Color(0.98, 0.86, 0.46))
	vb.put(0, 9, 0, Color(0.98, 0.90, 0.60))
	var m: MeshInstance3D = vb.build(solid, emis)[0]
	_add(m, pos, 0.15)

func _build_tea(pos: Vector3) -> void:
	vb = VoxelBuilder.new()
	# 茶盏 + 三片叶
	for i in 14:
		var ang := TAU * float(i) / 14.0
		vb.put(int(round(cos(ang) * 9.0)), 0, int(round(sin(ang) * 9.0)), Color(0.86, 0.88, 0.90))
	vb.box(-8, 0, -8, 9, 1, 9, Color(0.80, 0.83, 0.88), 0.01)
	vb.box(-7, 1, -7, 8, 2, 8, Color(0.42, 0.55, 0.36))
	for k in 3:
		var x := -3 + k * 3
		vb.box(x, 2, -1, x + 3, 4, 2, Color(0.34, 0.58, 0.32), 0.04)
		vb.box(x + 1, 4, -1, x + 2, 7, 2, Color(0.30, 0.52, 0.28))
	var m: MeshInstance3D = vb.build(solid, emis)[0]
	_add(m, pos, 0.13)
