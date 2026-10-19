extends Node3D
# 开局小山村：土路 + 茅屋 + 院落 + 农田 + 水井 + 树

const VOX := 0.25
var solid_mat: StandardMaterial3D
var emis_mat: StandardMaterial3D
var vb
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 445566
	solid_mat = StandardMaterial3D.new()
	solid_mat.vertex_color_use_as_albedo = true
	solid_mat.roughness = 0.95
	solid_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	emis_mat = StandardMaterial3D.new()
	emis_mat.vertex_color_use_as_albedo = true
	emis_mat.emission_enabled = true
	emis_mat.emission = Color(1, 0.78, 0.45)
	emis_mat.emission_energy_multiplier = 1.6
	_env()
	_ground()
	vb = load("res://voxel.gd").new()
	_road()
	_houses()
	_fields()
	_well()
	_fences()
	_trees()
	_people()
	var arr: Array = vb.build(solid_mat, emis_mat)
	for m in arr:
		add_child(m)
	_camera()

func _env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.36, 0.52, 0.74)
	sm.sky_horizon_color = Color(0.82, 0.86, 0.90)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_light_color = Color(0.78, 0.83, 0.88)
	env.fog_density = 0.00045
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, 34, 0)
	sun.light_energy = 1.6
	sun.light_color = Color(1, 0.94, 0.82)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)

func _ground() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(420, 1, 420)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.33, 0.38, 0.24)
	m.roughness = 1.0
	mi.material_override = m
	mi.position = Vector3(0, -0.5, 0)
	add_child(mi)

func _road() -> void:
	# 土路：南北向主线 + 一条东西支路
	vb.box(-7, -1, -86, 7, 0, 86, Color(0.46, 0.40, 0.30), 0.05)
	vb.box(-64, -1, 14, 64, 0, 26, Color(0.46, 0.40, 0.30), 0.05)

func _house(cx: int, cz: int, w: int, d: int, h: int, rot: int) -> void:
	var wall := Color(0.74, 0.68, 0.55)
	var beam := Color(0.36, 0.26, 0.18)
	var thatch := Color(0.56, 0.46, 0.28)
	if rot == 0 or rot == 180:
		vb.box(cx - w/2, 0, cz - d/2, cx + w/2, 1, cz + d/2, Color(0.62, 0.60, 0.55))
		vb.box(cx - w/2, 1, cz - d/2, cx + w/2, h, cz + d/2, wall, 0.04)
		for sx in [-1, 1]:
			vb.box(cx + sx*w/2 - 1, 1, cz - d/2, cx + sx*w/2, h, cz + d/2, beam)
		vb.box(cx - w/2, h - 1, cz - d/2, cx + w/2, h, cz + d/2, beam)
		# 人字茅草顶：层层外挑
		for i in 3:
			var ext := 2 - i * 1
			vb.box(cx - w/2 - ext, h + i * 2, cz - d/2 - ext, cx + w/2 + ext, h + i * 2 + 2, cz + d/2 + ext, thatch.darkened(float(i) * 0.07), 0.06)
		vb.box(cx - 2, h + 6, cz - 2, cx + 2, h + 8, cz + 2, thatch.darkened(0.2))
		# 门与窗
		vb.box(cx - 2, 1, cz - d/2 - 1, cx + 2, 4, cz - d/2, Color(0.26, 0.18, 0.12))
		vb.box(cx - w/2 - 1, 2, cz + 1, cx - w/2, 4, cz + 4, Color(0.20, 0.15, 0.10))
		vb.box_e(cx + w/2, 2, cz + 1, cx + w/2 + 1, 4, cz + 4, Color(1.0, 0.74, 0.38))
	else:
		vb.box(cx - d/2, 0, cz - w/2, cx + d/2, 1, cz + w/2, Color(0.62, 0.60, 0.55))
		vb.box(cx - d/2, 1, cz - w/2, cx + d/2, h, cz + w/2, wall, 0.04)
		for sz in [-1, 1]:
			vb.box(cx - d/2, 1, cz + sz*w/2 - 1, cx + d/2, h, cz + sz*w/2, beam)
		vb.box(cx - d/2, h - 1, cz - w/2, cx + d/2, h, cz + w/2, beam)
		for i in 3:
			var ext := 2 - i * 1
			vb.box(cx - d/2 - ext, h + i * 2, cz - w/2 - ext, cx + d/2 + ext, h + i * 2 + 2, cz + w/2 + ext, thatch.darkened(float(i) * 0.07), 0.06)
		vb.box(cx - 2, h + 6, cz - 2, cx + 2, h + 8, cz + 2, thatch.darkened(0.2))
		vb.box(cx - d/2 - 1, 1, cz - 2, cx - d/2, 4, cz + 2, Color(0.26, 0.18, 0.12))
		vb.box_e(cx + d/2, 2, cz - 4, cx + d/2 + 1, 4, cz - 1, Color(1.0, 0.74, 0.38))

func _houses() -> void:
	var specs := [
		[-34, -44, 22, 18, 8, 0], [34, -46, 20, 16, 8, 0],
		[-38, 6, 20, 16, 7, 180], [38, 2, 22, 18, 8, 180],
		[-34, 46, 21, 17, 8, 0], [34, 52, 20, 16, 7, 0],
		[-62, -18, 18, 15, 7, 90], [62, -12, 19, 15, 7, 90],
	]
	for s in specs:
		_house(int(s[0]), int(s[1]), int(s[2]), int(s[3]), int(s[4]), int(s[5]))

func _fields() -> void:
	for f in [[-64, 66, 40, 30], [58, 70, 34, 28]]:
		var cx: int = int(f[0])
		var cz: int = int(f[1])
		var w: int = int(f[2])
		var d: int = int(f[3])
		vb.box(cx - w/2, -1, cz - d/2, cx + w/2, 0, cz + d/2, Color(0.34, 0.26, 0.17), 0.04)
		for x in range(cx - w/2 + 2, cx + w/2 - 1, 3):
			vb.box(x, 0, cz - d/2 + 1, x + 2, 1, cz + d/2 - 1, Color(0.40, 0.62, 0.28), 0.12)
		# 稻草人
		vb.box(cx, 0, cz + d/2 - 2, cx + 1, 5, cz + d/2 - 1, Color(0.40, 0.30, 0.20))
		vb.box(cx - 2, 3, cz + d/2 - 2, cx + 3, 4, cz + d/2 - 1, Color(0.58, 0.48, 0.30))
		vb.box(cx - 1, 5, cz + d/2 - 2, cx + 2, 6, cz + d/2 - 1, Color(0.82, 0.72, 0.40))

func _well() -> void:
	var cx := 20
	var cz := 24
	for a in 8:
		var ang := TAU * float(a) / 8.0
		var x := cx + int(round(cos(ang) * 3.0))
		var z := cz + int(round(sin(ang) * 3.0))
		vb.box(x, 0, z, x + 1, 2, z + 1, Color(0.56, 0.55, 0.52), 0.05)
	vb.box(cx - 2, 1, cz - 2, cx + 2, 2, cz + 2, Color(0.10, 0.14, 0.18))
	vb.box(cx - 3, 0, cz - 3, cx + 3, 1, cz + 3, Color(0.50, 0.49, 0.46))
	for sx in [-2, 2]:
		vb.box(cx + sx, 2, cz - 2, cx + sx + 1, 7, cz - 1, Color(0.34, 0.24, 0.16))
	vb.box(cx - 3, 7, cz - 3, cx + 4, 8, cz + 2, Color(0.42, 0.32, 0.20))
	vb.box(cx - 1, 5, cz - 1, cx + 1, 6, cz, Color(0.36, 0.26, 0.18))

func _fences() -> void:
	for i in range(-84, 85, 8):
		vb.box(-9, 0, i, -8, 5, i + 2, Color(0.36, 0.27, 0.19))
		vb.box(8, 0, i, 9, 5, i + 2, Color(0.36, 0.27, 0.19))
	for i in range(-84, 84, 8):
		vb.box(-9, 3, i, -7, 4, i + 2, Color(0.42, 0.32, 0.22), 0.05)
		vb.box(7, 3, i, 9, 4, i + 2, Color(0.42, 0.32, 0.22), 0.05)

func _tree(vb2, kind: String, x: int, z: int, h: int) -> void:
	var tg = load("res://trees.gd").new()
	tg.vb = vb2
	match kind:
		"pine": tg.pine(h, Color(0.15, 0.28, 0.16))
		"broadleaf": tg.broadleaf(h, Color(0.22, 0.38, 0.19))
		"peach": tg.peach(h, Color(0.86, 0.55, 0.60))
		"bamboo": tg.bamboo(h, Color(0.34, 0.54, 0.24))
		"willow": tg.willow(h, Color(0.32, 0.46, 0.22))

func _trees() -> void:
	var pts := [
		["pine", -84, -70, 30], ["pine", 84, -66, 28], ["pine", -80, 40, 26],
		["broadleaf", 80, 40, 28], ["broadleaf", -86, 12, 26], ["peach", 52, -76, 18],
		["bamboo", -54, -80, 24], ["willow", 74, 84, 24], ["pine", 4, -92, 32],
	]
	for p in pts:
		# 树要落在世界坐标：先把构建器原点挪过去
		var sub = load("res://voxel.gd").new()
		var tg = load("res://trees.gd").new()
		tg.vb = sub
		match str(p[0]):
			"pine": tg.pine(int(p[3]), Color(0.15, 0.28, 0.16))
			"broadleaf": tg.broadleaf(int(p[3]), Color(0.22, 0.38, 0.19))
			"peach": tg.peach(int(p[3]), Color(0.86, 0.55, 0.60))
			"bamboo": tg.bamboo(int(p[3]), Color(0.34, 0.54, 0.24))
			"willow": tg.willow(int(p[3]), Color(0.32, 0.46, 0.22))
		for k in sub.solid.keys():
			vb.put(int(k.x) + int(p[1]), int(k.y), int(k.z) + int(p[2]), sub.solid[k])

func _people() -> void:
	var specs := [[-3, 18, Color(0.86, 0.84, 0.78), Color(0.14, 0.13, 0.16)],
		[4, 30, Color(0.42, 0.56, 0.80), Color(0.12, 0.12, 0.14)],
		[-8, 44, Color(0.74, 0.32, 0.26), Color(0.16, 0.14, 0.18)]]
	for s in specs:
		var x: int = int(s[0])
		var z: int = int(s[1])
		var robe: Color = s[2]
		var hair: Color = s[3]
		vb.box(x, 0, z, x + 3, 1, z + 3, Color(0.12, 0.12, 0.13))
		vb.box(x, 1, z, x + 3, 5, z + 3, robe, 0.05)
		vb.box(x, 3, z, x + 3, 5, z + 3, Color(0.80, 0.64, 0.30), 0.03)
		vb.box(x, 5, z, x + 3, 8, z + 3, Color(0.96, 0.83, 0.72))
		vb.box(x, 7, z, x + 3, 8, z + 3, hair, 0.04)
		vb.box(x, 5, z, x + 3, 8, z + 1, hair, 0.04)
		vb.box(x, 5, z + 3, x + 1, 6, z + 4, Color(0.08, 0.09, 0.14))
		vb.box(x + 2, 5, z + 3, x + 3, 6, z + 4, Color(0.08, 0.09, 0.14))

func _camera() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(30, 34, 46)
	cam.fov = 42
	add_child(cam)
	cam.look_at(Vector3(0, 3, 0), Vector3.UP)
