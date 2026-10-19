extends Node3D
# 轮廓旋转体（平滑面）物品渲染器：参数 → 高分辨率母版 → 只缩不放大
const MASTER := 1056
const SEG := 96

var _tier := 0
var _pat := 0
var _pat_col := Color(0.10, 0.08, 0.06)
var cam: Camera3D
var root: Node3D
var mat_mat: ShaderMaterial
var mat_met: ShaderMaterial

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.background_energy_multiplier = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	root = Node3D.new()
	add_child(root)
	cam = Camera3D.new()
	cam.fov = 24.0
	cam.position = Vector3(0.0, 0.255, -1.28)
	add_child(cam)
	cam.current = true
	cam.look_at(Vector3(0.0, 0.255, 0.0), Vector3.UP)
	mat_mat = ShaderMaterial.new()
	mat_mat.shader = load("res://rig/icon_light.gdshader")
	mat_mat.set_shader_parameter("spec_k", 0.40)
	mat_mat.set_shader_parameter("rim_k", 0.30)
	mat_met = ShaderMaterial.new()
	mat_met.shader = load("res://rig/icon_light.gdshader")
	mat_met.set_shader_parameter("spec_k", 0.90)
	mat_met.set_shader_parameter("rim_k", 0.45)
	for a3 in OS.get_cmdline_user_args():
		if a3.begins_with("--roles="):
			await _run_roles(a3.split("=")[1])
			return
	for a3 in OS.get_cmdline_user_args():
		if a3.begins_with("--produce="):
			var pp: PackedStringArray = a3.split("=")[1].split(",")
			await _run_produce(pp[0], pp[1], int(pp[2]))
			return
	for a3 in OS.get_cmdline_user_args():
		if a3.begins_with("--expo="):
			var parts: PackedStringArray = a3.split("=")[1].split(",")
			await _run_expo(float(parts[0]), parts[1])
			return
	for a3 in OS.get_cmdline_user_args():
		if a3.begins_with("--grid="):
			await _run_grid(a3.split("=")[1], 1)
			return
	for a3 in OS.get_cmdline_user_args():
		if a3.begins_with("--four2="):
			await _run_four(a3.split("=")[1])
			return
		if a3.begins_with("--four="):
			await _run_four(a3.split("=")[1])
			return
	if "--tiles" in OS.get_cmdline_user_args():
		await _run_tiles()
		return
	if "--giant" in OS.get_cmdline_user_args():
		await _run_giant()
		return
	if "--beings2" in OS.get_cmdline_user_args():
		await _run_beings2()
		return
	if "--beings" in OS.get_cmdline_user_args():
		await _run_beings()
		return
	if "--matrix" in OS.get_cmdline_user_args():
		await _run_matrix()
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--batch="):
			await _run_batch(int(a.split("=")[1]))
			return
	if "--shot" in OS.get_cmdline_user_args():
		await _run()
	else:
		root.add_child(_build(_spec("bottle")))


const PAL := [
	Color(0.10, 0.40, 0.36), Color(0.13, 0.46, 0.42), Color(0.16, 0.56, 0.46),
	Color(0.62, 0.16, 0.13), Color(0.72, 0.26, 0.20), Color(0.34, 0.30, 0.55),
	Color(0.62, 0.44, 0.16), Color(0.30, 0.36, 0.44),
]

func _variant(idx: int) -> Array:
	var base: String = ["bottle", "vase", "burner", "pill"][idx % 4]
	var sp := _spec(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = idx * 7919 + 13
	var c: Color = PAL[(idx / 4) % PAL.size()]
	for p in sp:
		if String(p[0]) == "l":
			var prof: Array = []
			for q in p[1]:
				var r: float = float(q[0]) * rng.randf_range(0.94, 1.06)
				var y: float = float(q[1]) * rng.randf_range(0.97, 1.03)
				prof.append([r, y])
			p[1] = prof
			if not bool(p[3]):
				p[2] = c
	return sp

func _run_batch(n: int) -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	for i in range(n):
		for ch in root.get_children():
			ch.queue_free()
		await get_tree().process_frame
		root.add_child(_build(_variant(i)))
		await get_tree().process_frame
		await get_tree().process_frame
		await Shot.grab(self, "res://out/batch/%03d.png" % i)
	get_tree().quit()


const TIER_COL := [
	Color(0.62, 0.64, 0.68), Color(0.26, 0.58, 0.52), Color(0.28, 0.44, 0.78),
	Color(0.52, 0.34, 0.72), Color(0.86, 0.66, 0.26),
]
const ELEM := {
	"火": Color(0.72, 0.20, 0.14),
	"雷": Color(0.46, 0.30, 0.78),
	"水": Color(0.16, 0.42, 0.68),
	"木": Color(0.24, 0.56, 0.30),
	"金": Color(0.78, 0.70, 0.36),
}

func _deco(sp: Array, tier: int, elem: String) -> Array:
	var out := sp.duplicate(true)
	var tc: Color = TIER_COL[clampi(tier - 1, 0, 4)]
	var ec: Color = ELEM.get(elem, Color(0.72, 0.20, 0.14))
	var h := 0.30
	for i in range(tier):
		var y := 0.055 + h * float(i) / maxf(1.0, float(tier))
		out.append(["l", [[0.020, y], [0.0205, y + 0.0015], [0.020, y + 0.003]], tc, true])
	for i in range(tier):
		var a := TAU * float(i) / maxf(1.0, float(tier))
		out.append(["e", [0.19 * cos(a), 0.16 + 0.05 * float(i), 0.19 * sin(a)],
			[0.010, 0.010, 0.010], tc, true])
	for i in range(2):
		var y2 := 0.10 + 0.09 * float(i)
		out.append(["l", [[0.1185, y2], [0.1192, y2 + 0.002], [0.1185, y2 + 0.004]], ec, true])
	return out


const BEINGS := ["farmer", "scholar", "cultivator", "elder", "wolf", "tiger", "serpent", "bird"]

func _being(nm: String) -> Array:
	var skin := Color(0.72, 0.55, 0.42)
	var cloth := Color(0.34, 0.32, 0.30)
	var jade := Color(0.04, 0.42, 0.26)
	var gold := Color(0.70, 0.50, 0.12)
	var fur := Color(0.30, 0.26, 0.22)
	var fur2 := Color(0.46, 0.40, 0.32)
	match nm:
		"farmer":
			return [
				["l", [[0.0, 0.010], [0.070, 0.014], [0.066, 0.080], [0.052, 0.180], [0.046, 0.250], [0.0, 0.256]], Color(0.42, 0.36, 0.24), false],
				["l", [[0.0, 0.256], [0.048, 0.262], [0.042, 0.300], [0.030, 0.312], [0.0, 0.316]], Color(0.36, 0.33, 0.28), false],
				["e", [0.0, 0.348, 0.0], [0.038, 0.040, 0.038], skin, false],
				["l", [[0.0, 0.372], [0.040, 0.376], [0.030, 0.390], [0.0, 0.394]], Color(0.50, 0.42, 0.26), false],
				["c", [0.058, 0.238, 0.0], 0.014, 0.011, 0.090, Color(0.40, 0.35, 0.26), false],
				["c", [-0.058, 0.238, 0.0], 0.014, 0.011, 0.090, Color(0.40, 0.35, 0.26), false],
			]
		"scholar":
			return [
				["l", [[0.0, 0.010], [0.078, 0.014], [0.072, 0.090], [0.056, 0.190], [0.050, 0.252], [0.0, 0.258]], Color(0.20, 0.26, 0.40), false],
				["l", [[0.0, 0.258], [0.052, 0.264], [0.044, 0.302], [0.030, 0.314], [0.0, 0.318]], Color(0.86, 0.84, 0.78), false],
				["e", [0.0, 0.350, 0.0], [0.038, 0.040, 0.038], skin, false],
				["l", [[0.0, 0.386], [0.030, 0.390], [0.022, 0.400], [0.0, 0.404]], Color(0.12, 0.12, 0.14), false],
				["c", [0.060, 0.240, 0.0], 0.013, 0.010, 0.086, Color(0.20, 0.26, 0.40), false],
				["c", [-0.060, 0.240, 0.0], 0.013, 0.010, 0.086, Color(0.20, 0.26, 0.40), false],
			]
		"cultivator":
			return [
				["l", [[0.0, 0.010], [0.082, 0.016], [0.076, 0.092], [0.058, 0.194], [0.050, 0.254], [0.0, 0.260]], jade, false],
				["l", [[0.0, 0.260], [0.054, 0.266], [0.046, 0.304], [0.030, 0.316], [0.0, 0.320]], Color(0.90, 0.88, 0.80), false],
				["l", [[0.0, 0.150], [0.060, 0.154], [0.060, 0.164], [0.0, 0.168]], gold, true],
				["e", [0.0, 0.352, 0.0], [0.038, 0.042, 0.038], skin, false],
				["e", [0.0, 0.396, -0.006], [0.030, 0.024, 0.030], Color(0.10, 0.10, 0.12), false],
				["e", [0.0, 0.410, -0.010], [0.008, 0.010, 0.008], gold, true],
				["c", [0.062, 0.242, 0.0], 0.014, 0.010, 0.090, jade, false],
				["c", [-0.062, 0.242, 0.0], 0.014, 0.010, 0.090, jade, false],
			]
		"elder":
			return [
				["l", [[0.0, 0.010], [0.086, 0.016], [0.080, 0.096], [0.060, 0.200], [0.052, 0.256], [0.0, 0.262]], Color(0.62, 0.56, 0.50), false],
				["l", [[0.0, 0.262], [0.056, 0.268], [0.048, 0.306], [0.032, 0.318], [0.0, 0.322]], Color(0.94, 0.92, 0.86), false],
				["e", [0.0, 0.354, 0.0], [0.040, 0.044, 0.040], skin, false],
				["l", [[0.0, 0.330], [0.026, 0.334], [0.020, 0.352], [0.0, 0.356]], Color(0.92, 0.90, 0.86), false],
				["e", [0.0, 0.404, -0.004], [0.032, 0.020, 0.032], Color(0.86, 0.84, 0.80), false],
				["c", [0.064, 0.244, 0.0], 0.015, 0.011, 0.092, Color(0.62, 0.56, 0.50), false],
				["c", [-0.064, 0.244, 0.0], 0.015, 0.011, 0.092, Color(0.62, 0.56, 0.50), false],
			]
		"wolf":
			return [
				["e", [0.0, 0.170, 0.0], [0.058, 0.055, 0.115], fur, false],
				["e", [0.0, 0.200, -0.115], [0.042, 0.040, 0.055], fur2, false],
				["e", [0.0, 0.196, -0.160], [0.022, 0.018, 0.030], Color(0.18, 0.16, 0.15), false],
				["c", [0.040, 0.086, -0.070], 0.014, 0.012, 0.150, fur2, false],
				["c", [-0.040, 0.086, -0.070], 0.014, 0.012, 0.150, fur2, false],
				["c", [0.040, 0.086, 0.070], 0.016, 0.013, 0.150, fur2, false],
				["c", [-0.040, 0.086, 0.070], 0.016, 0.013, 0.150, fur2, false],
				["l", [[0.0, 0.150], [0.010, 0.176], [0.0, 0.200]], fur2, false],
				["e", [0.028, 0.238, -0.100], [0.010, 0.014, 0.010], fur2, false],
				["e", [-0.028, 0.238, -0.100], [0.010, 0.014, 0.010], fur2, false],
			]
		"tiger":
			return [
				["e", [0.0, 0.175, 0.0], [0.076, 0.065, 0.135], Color(0.62, 0.36, 0.14), false],
				["e", [0.0, 0.205, -0.135], [0.052, 0.048, 0.060], Color(0.70, 0.44, 0.18), false],
				["e", [0.0, 0.198, -0.188], [0.026, 0.022, 0.030], Color(0.90, 0.84, 0.70), false],
				["c", [0.050, 0.088, -0.080], 0.020, 0.017, 0.150, Color(0.58, 0.34, 0.14), false],
				["c", [-0.050, 0.088, -0.080], 0.020, 0.017, 0.150, Color(0.58, 0.34, 0.14), false],
				["c", [0.050, 0.088, 0.080], 0.022, 0.018, 0.150, Color(0.58, 0.34, 0.14), false],
				["c", [-0.050, 0.088, 0.080], 0.022, 0.018, 0.150, Color(0.58, 0.34, 0.14), false],
				["c", [0.0, 0.215, 0.100], 0.020, 0.012, 0.120, Color(0.62, 0.36, 0.14), false],
				["l", [[0.0, 0.230], [0.012, 0.262], [0.0, 0.290]], Color(0.86, 0.82, 0.72), false],
				["e", [0.034, 0.240, -0.128], [0.012, 0.014, 0.010], Color(0.12, 0.10, 0.10), false],
				["e", [-0.034, 0.240, -0.128], [0.012, 0.014, 0.010], Color(0.12, 0.10, 0.10), false],
			]
		"serpent":
			return [
				["e", [0.0, 0.110, 0.0], [0.050, 0.050, 0.100], Color(0.16, 0.42, 0.34), false],
				["e", [0.0, 0.135, -0.110], [0.036, 0.034, 0.050], Color(0.20, 0.48, 0.38), false],
				["c", [0.0, 0.030, 0.10], 0.030, 0.020, 0.070, Color(0.16, 0.42, 0.34), false],
				["l", [[0.0, 0.120], [0.014, 0.170], [0.0, 0.210]], Color(0.70, 0.20, 0.16), false],
				["e", [0.026, 0.148, -0.140], [0.009, 0.012, 0.009], Color(0.96, 0.78, 0.30), true],
				["e", [-0.026, 0.148, -0.140], [0.009, 0.012, 0.009], Color(0.96, 0.78, 0.30), true],
			]
		_:
			return [
				["e", [0.0, 0.150, 0.0], [0.055, 0.070, 0.095], Color(0.70, 0.66, 0.60), false],
				["e", [0.0, 0.215, -0.075], [0.034, 0.032, 0.045], Color(0.86, 0.84, 0.78), false],
				["c", [0.0, 0.205, -0.120], 0.008, 0.004, 0.045, Color(0.92, 0.74, 0.28), true],
				["c", [0.010, 0.090, -0.020], 0.006, 0.005, 0.070, Color(0.92, 0.74, 0.28), true],
				["c", [-0.010, 0.090, -0.020], 0.006, 0.005, 0.070, Color(0.92, 0.74, 0.28), true],
			]

func _run_beings() -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	for nm in BEINGS:
		for ch in root.get_children():
			ch.queue_free()
		await get_tree().process_frame
		var b: Node3D = _build(_being(nm))
		root.add_child(b)
		for a in range(3):
			b.rotation_degrees.y = 90.0 * float(a) - 30.0
			for f in 3:
				await get_tree().process_frame
			await Shot.grab(self, "res://out/beings/%s_%d.png" % [nm, a])
	get_tree().quit()


func _mat2(col: Color, metal: bool) -> ShaderMaterial:
	var m: ShaderMaterial = (mat_met if metal else mat_mat).duplicate()
	m.set_shader_parameter("tint", col)
	m.set_meta("base", col)
	m.set_shader_parameter("pat_mode", _pat)
	m.set_shader_parameter("pat_col", _pat_col)
	m.set_shader_parameter("spec_k", 0.9 if metal else 0.4)
	m.set_shader_parameter("rim_k", 0.45 if metal else 0.3)
	return m

func _seg(parent: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, col: Color, metal := false) -> void:
	var d := b - a
	var L := d.length()
	if L < 0.0001:
		return
	var cm := CylinderMesh.new()
	cm.top_radius = r1
	cm.bottom_radius = r0
	cm.height = L
	cm.radial_segments = 24
	cm.rings = 6
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = _mat2(col, metal)
	mi.position = (a + b) * 0.5
	var up := d.normalized()
	var q := Quaternion(Vector3.UP, up)
	mi.quaternion = q
	parent.add_child(mi)

func _ball(parent: Node3D, c: Vector3, r: Vector3, col: Color, metal := false) -> void:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 28
	sm.rings = 14
	var mi := MeshInstance3D.new()
	mi.mesh = sm
	mi.scale = r
	mi.position = c
	mi.material_override = _mat2(col, metal)
	parent.add_child(mi)

func _being2(nm: String) -> Node3D:
	var root2 := Node3D.new()
	var skin := Color(0.74, 0.57, 0.44)
	var robe := Color(0.34, 0.32, 0.30)
	var shoe := Color(0.16, 0.15, 0.16)
	match nm:
		"farmer": robe = Color(0.40, 0.34, 0.22)
		"scholar": robe = Color(0.20, 0.25, 0.38)
		"cultivator": robe = Color(0.03, 0.34, 0.22)
		"elder": robe = Color(0.60, 0.56, 0.50)
	if nm in ["wolf", "tiger", "serpent", "bird"]:
		return _beast(nm)
	# —— 人形骨架 ——
	var hip := Vector3(0, 0.150, 0)
	var chest := Vector3(0, 0.250, 0)
	var neck := Vector3(0, 0.300, 0)
	var head := Vector3(0, 0.330, 0)
	_seg(root2, hip, chest, 0.052, 0.056, robe)
	_seg(root2, chest, neck, 0.050, 0.034, robe)
	# 袍摆
	var skirt := CylinderMesh.new()
	skirt.top_radius = 0.054
	skirt.bottom_radius = 0.086
	skirt.height = 0.150
	skirt.radial_segments = 32
	var sk := MeshInstance3D.new()
	sk.mesh = skirt
	sk.position = Vector3(0, 0.075, 0)
	sk.material_override = _mat2(robe, false)
	root2.add_child(sk)
	# 头 + 五官
	_ball(root2, head + Vector3(0, 0.020, 0), Vector3(0.0305, 0.0365, 0.0295), skin)
	_ball(root2, head + Vector3(0.012, 0.026, -0.030), Vector3(0.007, 0.008, 0.006), Color(0.10, 0.10, 0.12))
	_ball(root2, head + Vector3(-0.012, 0.026, -0.030), Vector3(0.007, 0.008, 0.006), Color(0.10, 0.10, 0.12))
	# 眉
	_seg(root2, head + Vector3(-0.022, 0.034, -0.028), head + Vector3(-0.004, 0.036, -0.030), 0.0035, 0.0035, Color(0.10, 0.09, 0.09))
	_seg(root2, head + Vector3(0.004, 0.036, -0.030), head + Vector3(0.022, 0.034, -0.028), 0.0035, 0.0035, Color(0.10, 0.09, 0.09))
	# 嘴
	_seg(root2, head + Vector3(-0.008, 0.008, -0.031), head + Vector3(0.008, 0.008, -0.031), 0.003, 0.003, Color(0.42, 0.18, 0.16))
	# 手臂（肩→肘→手）
	for sgn in [-1.0, 1.0]:
		var sh := Vector3(0.050 * sgn, 0.288, 0)
		var el := Vector3(0.066 * sgn, 0.236, -0.006)
		var hd := Vector3(0.060 * sgn, 0.192, -0.020)
		_seg(root2, sh, el, 0.019, 0.015, robe)
		_seg(root2, el, hd, 0.014, 0.011, robe)
		_ball(root2, hd + Vector3(0, -0.010, 0), Vector3(0.013, 0.016, 0.010), skin)
		for f in range(4):
			var fx: float = hd.x + (-0.0075 + 0.005 * float(f)) * sgn
			_seg(root2, Vector3(fx, hd.y - 0.018, hd.z - 0.002), Vector3(fx, hd.y - 0.027, hd.z - 0.005), 0.0028, 0.0022, skin)
		_ball(root2, hd, Vector3(0.013, 0.013, 0.013), skin)
		# 腿（髋→膝→踝→脚）
		var hp := Vector3(0.028 * sgn, 0.148, 0)
		var kn := Vector3(0.030 * sgn, 0.078, 0)
		var an := Vector3(0.030 * sgn, 0.020, 0)
		_seg(root2, hp, kn, 0.024, 0.019, shoe)
		_seg(root2, kn, an, 0.018, 0.014, shoe)
		_seg(root2, an, an + Vector3(0, -0.004, -0.030), 0.016, 0.012, shoe)
	# 身份特征
	match nm:
		"farmer":
			var hat := CylinderMesh.new()
			hat.top_radius = 0.004
			hat.bottom_radius = 0.070
			hat.height = 0.030
			var hm := MeshInstance3D.new()
			hm.mesh = hat
			hm.position = head + Vector3(0, 0.050, 0)
			hm.material_override = _mat2(Color(0.62, 0.52, 0.30), false)
			root2.add_child(hm)
			_seg(root2, Vector3(0.075, 0.200, -0.04), Vector3(0.075, 0.020, -0.10), 0.006, 0.006, Color(0.45, 0.34, 0.18))
		"scholar":
			_ball(root2, head + Vector3(0, 0.052, 0.008), Vector3(0.030, 0.018, 0.028), Color(0.12, 0.12, 0.14))
			_seg(root2, Vector3(0.070, 0.190, -0.02), Vector3(0.092, 0.150, -0.05), 0.004, 0.003, Color(0.86, 0.84, 0.76))
		"cultivator":
			_seg(root2, Vector3(-0.055, 0.250, 0.030), Vector3(-0.085, 0.410, 0.055), 0.005, 0.003, Color(0.78, 0.78, 0.82))
			_ball(root2, head + Vector3(0, 0.048, 0), Vector3(0.020, 0.014, 0.020), Color(0.10, 0.10, 0.12))
			_ball(root2, head + Vector3(0, 0.056, 0), Vector3(0.007, 0.007, 0.007), Color(0.90, 0.72, 0.28), true)
			_seg(root2, Vector3(0, 0.176, 0), Vector3(0, 0.186, 0), 0.058, 0.058, Color(0.72, 0.54, 0.16), true)
		"elder":
			var wc := Color(0.93, 0.91, 0.87)
			var chin := head + Vector3(0, -0.014, -0.020)
			_seg(root2, chin + Vector3(-0.013, 0, 0), chin + Vector3(-0.016, -0.040, 0.004), 0.010, 0.003, wc)
			_seg(root2, chin + Vector3(0.013, 0, 0), chin + Vector3(0.016, -0.040, 0.004), 0.010, 0.003, wc)
			_seg(root2, chin + Vector3(0, 0.002, -0.002), chin + Vector3(0, -0.034, 0.002), 0.011, 0.003, wc)
			for sgn2 in [-1.0, 1.0]:
				_seg(root2, head + Vector3(0.020 * sgn2, 0.030, -0.024), head + Vector3(0.026 * sgn2, 0.006, -0.022), 0.004, 0.002, wc)
			_seg(root2, Vector3(0.078, 0.080, -0.03), Vector3(0.078, 0.240, -0.02), 0.006, 0.006, Color(0.42, 0.30, 0.18))
	_cloth_folds(root2, robe)
	return root2


func _cloth_folds(node: Node3D, robe: Color) -> void:
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var mat := mi.material_override
		if mat is ShaderMaterial and mat.has_meta("base"):
			var b: Color = mat.get_meta("base")
			if absf(b.r - robe.r) < 0.02 and absf(b.g - robe.g) < 0.02 and absf(b.b - robe.b) < 0.02:
				(mat as ShaderMaterial).set_shader_parameter("pat_mode", 4)
				(mat as ShaderMaterial).set_shader_parameter("pat_col", robe.darkened(0.42))
				(mat as ShaderMaterial).set_shader_parameter("pat_density", 1.0)

func _beast(nm: String) -> Node3D:
	if nm == "tiger":
		_pat = 1
		_pat_col = Color(0.12, 0.09, 0.06)
	elif nm == "serpent":
		_pat = 2
		_pat_col = Color(0.10, 0.30, 0.24)
	elif nm == "bird":
		_pat = 3
		_pat_col = Color(0.62, 0.56, 0.46)
	if nm == "serpent":
		var bs := _beast_serpent()
		_pat = 0
		return bs
	if nm == "bird":
		return _beast_bird()
	return _beast_quad(nm)

func _beast_quad(nm: String) -> Node3D:
	var r := Node3D.new()
	var tiger := nm == "tiger"
	var body := Color(0.66, 0.38, 0.14) if tiger else Color(0.34, 0.28, 0.22)
	var belly := Color(0.92, 0.86, 0.72) if tiger else Color(0.50, 0.44, 0.34)
	var hip_y := 0.105 if tiger else 0.125
	var neck_len := 0.075 if tiger else 0.100
	var body_h := 0.075 if tiger else 0.062
	var body_z := 0.105 if tiger else 0.095
	var torso := Vector3(0, hip_y + body_h, 0)
	_ball(r, torso, Vector3(0.070 if tiger else 0.058, body_h, body_z), body)
	_ball(r, torso + Vector3(0, -0.018, 0), Vector3(0.056 if tiger else 0.046, body_h * 0.62, body_z * 0.86), belly)
	var neck := torso + Vector3(0, 0.030, -body_z * 0.72)
	var hd := neck + Vector3(0, 0.012, -neck_len)
	_seg(r, torso + Vector3(0, 0.018, -body_z * 0.62), neck, 0.042 if tiger else 0.032, 0.034 if tiger else 0.026, body)
	_seg(r, neck, hd, 0.034 if tiger else 0.026, 0.030 if tiger else 0.023, body)
	_ball(r, hd + Vector3(0, 0.004, -0.016), Vector3(0.034 if tiger else 0.028, 0.030 if tiger else 0.026, 0.040 if tiger else 0.034), body)
	_ball(r, hd + Vector3(0, -0.006, -0.050), Vector3(0.020, 0.014, 0.020), belly)
	for sgn in [-1.0, 1.0]:
		_ball(r, hd + Vector3(0.021 * sgn, 0.018, -0.026), Vector3(0.006, 0.007, 0.006), Color(0.08, 0.08, 0.09))
		_seg(r, hd + Vector3(0.019 * sgn, 0.020, -0.014), hd + Vector3(0.026 * sgn, 0.050, -0.004), 0.011, 0.002, body)
		for pz in [-body_z * 0.55, body_z * 0.55]:
			var top := Vector3(0.046 * sgn, hip_y, pz)
			var knee := Vector3(0.050 * sgn, hip_y * 0.55, pz + 0.012)
			var foot := Vector3(0.050 * sgn, 0.006, pz - 0.004)
			_seg(r, top, knee, 0.019 if tiger else 0.016, 0.015, body)
			_seg(r, knee, foot, 0.015, 0.011, body)
			_seg(r, foot, foot + Vector3(0, -0.002, -0.024), 0.014, 0.009, body)
	_seg(r, torso + Vector3(0, 0.024, body_z * 0.92), torso + Vector3(0, 0.060, body_z * 1.55), 0.017, 0.005, body)
	if tiger:
		# 虎纹：身上数道深色细环
		for k in range(5):
			var z := -0.06 + 0.03 * float(k)
			var yy := torso.y + body_h * 0.86
			_seg(r, Vector3(-0.052, yy, z), Vector3(0.052, yy, z), 0.006, 0.006, Color(0.14, 0.10, 0.07))
	return r

func _beast_serpent() -> Node3D:
	var r := Node3D.new()
	var body := Color(0.14, 0.40, 0.32)
	var belly := Color(0.36, 0.62, 0.48)
	# 长身：六段首尾相接，沿 Z 微微起伏
	var pts: Array = []
	for k in range(7):
		var t := float(k) / 6.0
		pts.append(Vector3(0.030 * sin(t * 5.0), 0.085 + 0.020 * sin(t * 4.2), 0.170 - t * 0.360))
	for k in range(pts.size() - 1):
		var a: Vector3 = pts[k]
		var b: Vector3 = pts[k + 1]
		var rr := 0.042 - 0.020 * (float(k) / 6.0)
		_seg(r, a, b, rr, rr * 0.92, body)
	pts.reverse()
	var hd: Vector3 = pts[0]
	var head_c := hd + Vector3(0, 0.014, -0.046)
	# 上颅
	_ball(r, head_c + Vector3(0, 0.012, 0), Vector3(0.046, 0.030, 0.056), body)
	_ball(r, head_c + Vector3(0, 0.002, -0.062), Vector3(0.030, 0.019, 0.034), body)
	_ball(r, head_c + Vector3(0, -0.014, -0.060), Vector3(0.026, 0.010, 0.030), body.darkened(0.18))
	for sgn in [-1.0, 1.0]:
		_ball(r, head_c + Vector3(0.011 * sgn, 0.014, -0.088), Vector3(0.0035, 0.0035, 0.0035), Color(0.06, 0.07, 0.07))
	# 下颌（与上颅留一道口缝）
	_ball(r, head_c + Vector3(0, -0.020, -0.008), Vector3(0.040, 0.016, 0.050), body.darkened(0.18))
	_ball(r, head_c + Vector3(0, -0.002, -0.020), Vector3(0.036, 0.005, 0.044), Color(0.10, 0.08, 0.09))
	# 眼：贴在上颅侧表面外侧（x=0.050 > 半轴 0.046）
	for sgn in [-1.0, 1.0]:
		var eye := head_c + Vector3(0.050 * sgn, 0.020, -0.026)
		_ball(r, eye, Vector3(0.012, 0.012, 0.012), Color(0.86, 0.80, 0.28))
		_ball(r, eye + Vector3(0.008 * sgn, 0, -0.004), Vector3(0.006, 0.006, 0.006), Color(0.05, 0.05, 0.06))
	# 角：从颅顶长出
	_seg(r, head_c + Vector3(0, 0.036, 0.006), head_c + Vector3(0, 0.092, -0.014), 0.011, 0.002, Color(0.72, 0.20, 0.16))
	# 须
	for sgn in [-1.0, 1.0]:
		var w0 := head_c + Vector3(0.026 * sgn, -0.006, -0.050)
		var w1 := head_c + Vector3(0.060 * sgn, -0.020, -0.096)
		var w2 := head_c + Vector3(0.082 * sgn, 0.002, -0.128)
		_seg(r, w0, w1, 0.0040, 0.0026, Color(0.72, 0.80, 0.62))
		_seg(r, w1, w2, 0.0026, 0.0012, Color(0.72, 0.80, 0.62))
	# 背鳍
	for k in range(1, 6):
		var a: Vector3 = pts[k]
		_seg(r, a, a + Vector3(0, 0.030, 0), 0.002, 0.010, Color(0.22, 0.52, 0.44))
	return r

func _beast_bird() -> Node3D:
	var r := Node3D.new()
	var body := Color(0.88, 0.86, 0.80)
	var dark := Color(0.72, 0.66, 0.56)
	var torso := Vector3(0, 0.185, 0)
	_ball(r, torso, Vector3(0.056, 0.062, 0.082), body)
	_ball(r, torso + Vector3(0, -0.010, -0.010), Vector3(0.040, 0.044, 0.060), Color(0.96, 0.94, 0.88))
	var neck := torso + Vector3(0, 0.062, -0.030)
	var hd := neck + Vector3(0.004, 0.040, -0.028)
	_seg(r, torso + Vector3(0, 0.030, -0.020), neck, 0.026, 0.020, body)
	_seg(r, neck, hd, 0.020, 0.018, body)
	_ball(r, hd, Vector3(0.028, 0.026, 0.030), body)
	# 喙
	_seg(r, hd + Vector3(0, -0.002, -0.026), hd + Vector3(0, -0.006, -0.062), 0.014, 0.002, Color(0.86, 0.62, 0.20))
	for sgn in [-1.0, 1.0]:
		_ball(r, hd + Vector3(0.020 * sgn, 0.008, -0.012), Vector3(0.005, 0.005, 0.005), Color(0.08, 0.08, 0.09))
	# 双足
	for sgn in [-1.0, 1.0]:
		var hip := Vector3(0.030 * sgn, 0.130, 0.006)
		var knee := Vector3(0.034 * sgn, 0.072, -0.004)
		var foot := Vector3(0.034 * sgn, 0.010, -0.012)
		_seg(r, hip, knee, 0.020, 0.016, dark)
		_seg(r, knee, foot, 0.016, 0.012, dark)
		for t3 in [-1.0, 0.0, 1.0]:
			_seg(r, foot, foot + Vector3(0.016 * t3, 0.0, -0.026), 0.008, 0.003, dark)
	# 双翼
	for sgn in [-1.0, 1.0]:
		var a: Vector3 = torso + Vector3(0.045 * sgn, 0.020, 0.010)
		var b: Vector3 = torso + Vector3(0.150 * sgn, 0.070, 0.030)
		_seg(r, a, b, 0.030, 0.012, body)
		_seg(r, b, b + Vector3(0.070 * sgn, -0.030, 0.040), 0.012, 0.004, body)
	# 尾羽
	for sgn in [-1.0, 0.0, 1.0]:
		_seg(r, torso + Vector3(0.010 * sgn, 0.010, 0.070), torso + Vector3(0.030 * sgn, -0.030, 0.170), 0.014, 0.003, body)
	return r

func _run_beings2() -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	for nm in ["farmer", "scholar", "cultivator", "elder", "wolf", "tiger", "serpent", "bird"]:
		for ch in root.get_children():
			ch.queue_free()
		await get_tree().process_frame
		var b: Node3D = _being2(nm)
		root.add_child(b)
		for a in range(3):
			b.rotation_degrees.y = 90.0 * float(a) - 30.0
			for f in 3:
				await get_tree().process_frame
			await Shot.grab(self, "res://out/beings/%s_%d.png" % [nm, a])
	get_tree().quit()


func _run_giant() -> void:
	RenderingServer.set_default_clear_color(Color(0.72, 0.76, 0.78, 1.0))
	var env: Environment = null
	for c in get_children():
		if c is WorldEnvironment:
			env = (c as WorldEnvironment).environment
	if env != null:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.74, 0.78, 0.80)
		env.fog_enabled = true
		env.fog_density = 0.030
		env.fog_light_color = Color(0.80, 0.82, 0.84)
		env.fog_sun_scatter = 0.4
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.30, 0.32, 0.28)
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground.material_override = gm
	root.add_child(ground)
	var beast: Node3D = _being2("tiger")
	beast.scale = Vector3(9, 9, 9)
	beast.position = Vector3(-0.2, 0.0, 0.6)
	beast.rotation_degrees.y = 16.0
	root.add_child(beast)
	var man: Node3D = _being2("cultivator")
	man.position = Vector3(0.55, 0.0, -0.35)
	man.rotation_degrees.y = -28.0
	root.add_child(man)
	cam.fov = 44.0
	cam.position = Vector3(0.62, 0.10, -1.35)
	cam.look_at_from_position(cam.position, Vector3(-0.05, 0.62, 0.45), Vector3.UP)
	for i in range(20):
		await get_tree().process_frame
	await Shot.grab(self, "res://out/giant.png")
	get_tree().quit()


func _run_tiles() -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var tier := 2
	for a2 in OS.get_cmdline_user_args():
		if a2.begins_with("--tier="):
			tier = int(a2.split("=")[1])
	_tier = tier
	var item: Node3D = _build(_deco(_spec("bottle"), tier, "火"))
	root.add_child(item)
	var base_pos := cam.position
	var base_dir := Vector3(-0.05, 0.62, 0.45) - base_pos
	var dist := base_dir.length()
	var fov_r := deg_to_rad(cam.fov * 0.5)
	var view_h := 2.0 * dist * tan(fov_r)
	var view_w := view_h * 1.0
	for ai in range(4):
		item.rotation_degrees.y = 90.0 * float(ai)
		for iy in range(3):
			for ix in range(3):
				cam.h_offset = (float(ix) - 1.0) * view_w / 3.0
				cam.v_offset = (1.0 - float(iy)) * view_h / 3.0
				for f in 2:
					await get_tree().process_frame
				await Shot.grab(self, "res://out/tiles/%d_%d%d.png" % [ai, iy, ix])
	cam.h_offset = 0.0
	cam.v_offset = 0.0
	get_tree().quit()


func _run_four(res_tag: String) -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var item: Node3D = _build(_spec("bottle"))
	root.add_child(item)
	for a in range(4):
		item.rotation_degrees.y = 90.0 * float(a)
		for f in 4:
			await get_tree().process_frame
		await Shot.grab(self, "res://out/final/bottle_%s_%d.png" % [res_tag, a])
	get_tree().quit()


func _run_grid(tag: String, angles: int) -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var item: Node3D = _build(_spec("bottle"))
	root.add_child(item)
	var f0 := cam.fov
	var b0 := cam.global_transform.origin
	var right := cam.global_transform.basis.x
	var upv := cam.global_transform.basis.y
	var tgt := Vector3(0.0, 0.255, 0.0)
	var dd := (tgt - b0).length()
	var vieww := 2.0 * dd * tan(deg_to_rad(f0 * 0.5))
	cam.fov = f0 / 3.0
	for a in range(angles):
		item.rotation_degrees.y = 90.0 * float(a)
		for iy in range(3):
			for ix in range(3):
				cam.global_position = b0 + right * ((float(ix) - 1.0) * vieww / 3.0) + upv * ((1.0 - float(iy)) * vieww / 3.0)
				for f in 3:
					await get_tree().process_frame
				await Shot.grab(self, "res://out/grid/%s_%d_%d%d.png" % [tag, a, iy, ix])
	cam.frustum_offset = Vector2.ZERO
	cam.global_position = b0
	get_tree().quit()


func _run_expo(ev: float, out_name: String) -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var item: Node3D = _build(_spec("bottle"))
	root.add_child(item)
	for c in get_children():
		if c is WorldEnvironment:
			var e: Environment = (c as WorldEnvironment).environment
			e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
			e.tonemap_exposure = ev
	for f in 6:
		await get_tree().process_frame
	await Shot.grab(self, "res://out/hdr/%s.png" % out_name)
	get_tree().quit()


func _run_produce(tag: String, subject: String, tier: int) -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var item: Node3D = _build(_deco(_spec(subject), tier, "火"))
	root.add_child(item)
	var f0 := cam.fov
	var b0 := cam.global_transform.origin
	var right := cam.global_transform.basis.x
	var upv := cam.global_transform.basis.y
	var tgt := Vector3(0.0, 0.255, 0.0)
	var dd := (tgt - b0).length()
	var vieww := 2.0 * dd * tan(deg_to_rad(f0 * 0.5))
	for pass_i in range(tier):
		for a in range(4):
			item.rotation_degrees.y = 90.0 * float(a) + float(pass_i) * 1.7
			for iy in range(3):
				for ix in range(3):
					for f in 2:
						await get_tree().process_frame
					await Shot.grab(self, "res://out/prod/%s_p%d_a%d_%d%d.png" % [tag, pass_i, a, iy, ix])
	cam.frustum_offset = Vector2.ZERO
	cam.global_position = b0
	get_tree().quit()



func _fit_camera(node: Node3D) -> void:
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := Vector3(-1e9, -1e9, -1e9)
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		var bb: AABB = mi.global_transform * mi.mesh.get_aabb()
		lo = lo.min(bb.position)
		hi = hi.max(bb.position + bb.size)
	var c := (lo + hi) * 0.5
	var size := hi - lo
	cam.fov = 26.0
	var d := maxf(size.length() * 1.75, 0.30)
	cam.position = c + Vector3(size.x * 0.45, size.y * 0.55, -d)
	cam.look_at_from_position(cam.position, c, Vector3.UP)

func _run_roles(tag: String) -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var roles := ["farmer", "scholar", "cultivator", "elder", "wolf", "tiger", "serpent", "bird"]
	for r in roles:
		var b: Node3D = _being2(r)
		root.add_child(b)
		_fit_camera(b)
		for a in range(4):
			b.rotation_degrees.y = 90.0 * float(a)
			for f in 3:
				await get_tree().process_frame
			await Shot.grab(self, "res://out/roles/%s_%s_%d.png" % [tag, r, a])
		b.queue_free()
	get_tree().quit()

func _run_matrix() -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var elems := ["火", "雷", "水", "木", "金"]
	for tier in range(1, 6):
		for e in elems:
			for ch in root.get_children():
				ch.queue_free()
			await get_tree().process_frame
			_tier = tier
			root.add_child(_build(_deco(_spec("bottle"), tier, e)))
			await get_tree().process_frame
			await get_tree().process_frame
			await Shot.grab(self, "res://out/matrix/t%d_%s.png" % [tier, e])
	get_tree().quit()

func _run() -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var names := ["bottle", "burner", "pill"]
	for nm in names:
		for c in root.get_children():
			c.queue_free()
		await get_tree().process_frame
		var item: Node3D = _build(_spec(nm))
		root.add_child(item)
		for a in range(8):
			item.rotation_degrees.y = 45.0 * float(a)
			for f in 3:
				await get_tree().process_frame
			await Shot.grab(self, "res://out/angle/%s_%d.png" % [nm, a])
	get_tree().quit()

func _spec(nm: String) -> Array:
	var jade := Color(0.02, 0.34, 0.21)
	var jade_l := Color(0.04, 0.46, 0.29)
	var gold := Color(0.68, 0.49, 0.11)
	var gold_l := Color(0.92, 0.72, 0.20)
	var cinn := Color(0.62, 0.16, 0.13)
	match nm:
		"bottle":
			return [
				["l", [[0.0, 0.00], [0.088, 0.006], [0.098, 0.020], [0.104, 0.052], [0.110, 0.100], [0.113, 0.150], [0.112, 0.196], [0.104, 0.238], [0.090, 0.276], [0.074, 0.306], [0.060, 0.330], [0.048, 0.352], [0.038, 0.386], [0.034, 0.420], [0.031, 0.444], [0.032, 0.452], [0.036, 0.458], [0.034, 0.466], [0.0, 0.468]], jade, false],
				["l", [[0.1142, 0.150], [0.1152, 0.152], [0.1142, 0.154]], gold_l, true],
				["l", [[0.1152, 0.166], [0.1162, 0.168], [0.1152, 0.170]], gold_l, true],
				["l", [[0.1140, 0.182], [0.1150, 0.184], [0.1140, 0.186]], gold_l, true],
				["l", [[0.040, 0.398], [0.0435, 0.404], [0.0435, 0.414], [0.040, 0.420]], gold, true],
				["l", [[0.030, 0.470], [0.033, 0.476], [0.030, 0.482]], cinn, false],
				["g", [0.112, 0.120, 0.0], 12, 0.0062, gold_l],
				["g", [0.108, 0.212, 0.0], 12, 0.0050, gold_l],
				["l", [[0.034, 0.468], [0.035, 0.480], [0.035, 0.496], [0.031, 0.506], [0.0, 0.510]], Color(0.84, 0.79, 0.66), false],
				["l", [[0.0355, 0.486], [0.0365, 0.488], [0.0355, 0.490]], gold_l, true],
			]
		"burner":
			return [
				["l", [[0.0, 0.020], [0.046, 0.020], [0.052, 0.030], [0.055, 0.052], [0.068, 0.074], [0.086, 0.100], [0.100, 0.134], [0.108, 0.170], [0.111, 0.204], [0.108, 0.232], [0.104, 0.246]], gold, true],
				["l", [[0.104, 0.246], [0.116, 0.252], [0.126, 0.260], [0.124, 0.266], [0.112, 0.268]], gold_l, true],
				["l", [[0.0, 0.276], [0.086, 0.280], [0.092, 0.292], [0.082, 0.306], [0.062, 0.316], [0.034, 0.322], [0.0, 0.324]], gold_l, true],
				["l", [[0.0, 0.326], [0.020, 0.328], [0.024, 0.338], [0.018, 0.346], [0.0, 0.348]], gold, true],
				["c", [0.000, 0.016, 0.070], 0.014, 0.022, 0.0, gold, true],
				["c", [-0.062, 0.016, -0.034], 0.014, 0.022, 0.0, gold, true],
				["c", [0.062, 0.016, -0.034], 0.014, 0.022, 0.0, gold, true],
				["c", [0.118, 0.196, 0.0], 0.014, 0.011, 0.070, gold_l, true],
				["c", [-0.118, 0.196, 0.0], 0.014, 0.011, 0.070, gold_l, true],
				["c", [0.126, 0.231, 0.0], 0.020, 0.014, 0.010, gold_l, true],
				["c", [-0.126, 0.231, 0.0], 0.020, 0.014, 0.010, gold_l, true],
				["e", [0.030, 0.150, 0.104], [0.016, 0.020, 0.014], gold_l, true],
			]
		"vase":
			return [
				["l", [[0.0, 0.00], [0.052, 0.004], [0.062, 0.018], [0.070, 0.044], [0.078, 0.084], [0.082, 0.130], [0.080, 0.180], [0.070, 0.226], [0.054, 0.264], [0.042, 0.296], [0.036, 0.322], [0.040, 0.340], [0.046, 0.348], [0.044, 0.360], [0.0, 0.362]], jade_l, false],
				["l", [[0.072, 0.078], [0.074, 0.096], [0.072, 0.110]], gold_l, true],
				["l", [[0.040, 0.338], [0.043, 0.352], [0.041, 0.362]], gold, true],
			]
		_:
			return [
				["e", [0.0, 0.10, 0.0], [0.085, 0.080, 0.085], cinn, false],
				["e", [-0.030, 0.135, -0.045], [0.028, 0.018, 0.016], Color(0.95, 0.86, 0.72), false],
				["l", [[0.0, 0.006], [0.060, 0.010], [0.062, 0.020], [0.0, 0.024]], Color(0.45, 0.10, 0.09), false],
				["l", [[0.082, 0.092], [0.089, 0.098], [0.089, 0.104], [0.082, 0.110]], Color(0.92, 0.72, 0.30), true],
				["l", [[0.070, 0.132], [0.077, 0.138], [0.077, 0.144], [0.070, 0.150]], Color(0.92, 0.72, 0.30), true],
			]


func _mist(parent: Node3D, tier: int, col: Color) -> void:
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	for y in range(96):
		for x in range(96):
			var d := Vector2(float(x) - 48.0, float(y) - 48.0).length() / 48.0
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = pow(a, 2.4)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	var tex := ImageTexture.create_from_image(img)
	var n := 2 + tier
	var rng := RandomNumberGenerator.new()
	rng.seed = tier * 331
	for i in range(n):
		var q := QuadMesh.new()
		q.size = Vector2(0.30 + 0.05 * float(tier), 0.30 + 0.05 * float(tier))
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.position = Vector3(rng.randf_range(-0.12, 0.12), 0.08 + rng.randf_range(0.0, 0.26), rng.randf_range(-0.08, 0.08))
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_texture = tex
		m.albedo_color = Color(1, 1, 1, 0.075)
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mi.material_override = m
		parent.add_child(mi)

func _build(spec: Array) -> Node3D:
	var holder := Node3D.new()
	var buf_m := {}
	var buf_k := {}
	for p in spec:
		var t := String(p[0])
		if t == "l":
			_rev(p[1], p[2], bool(p[3]), buf_m if not bool(p[3]) else buf_k)
		elif t == "e":
			var cc: Array = p[1]
			var rr: Array = p[2]
			var m1: bool = bool(p[4])
			_ell(Vector3(cc[0], cc[1], cc[2]), Vector3(rr[0], rr[1], rr[2]), p[3], m1, buf_k if m1 else buf_m)
		elif t == "g":
			var gp: Array = p[1]
			var gy: float = float(gp[1])
			var gr: float = float(gp[0])
			var cnt: int = int(p[2])
			var sz: float = float(p[3])
			for i2 in range(cnt):
				var ang := TAU * float(i2) / float(cnt)
				_ell(Vector3((gr + sz * 0.55) * cos(ang), gy, (gr + sz * 0.55) * sin(ang)), Vector3(sz, sz, sz), p[4], true, buf_k)
		elif t == "c":
			var cp: Array = p[1]
			_cyl([cp[0], cp[1], cp[2]], float(p[2]), float(p[3]), float(p[4]), p[5], bool(p[6]), buf_k if bool(p[6]) else buf_m)
	_add_mesh(holder, buf_m, mat_mat)
	_add_mesh(holder, buf_k, mat_met)
	if _tier > 0:
		_mist(holder, _tier, TIER_COL[clampi(_tier - 1, 0, 4)])
	return holder

func _add_mesh(holder: Node3D, buf: Dictionary, mat: ShaderMaterial) -> void:
	if buf.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for key in buf.keys():
		st.set_color(buf[key][0])
		st.set_normal(buf[key][1])
		st.add_vertex(buf[key][2])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	holder.add_child(mi)

func _push(buf: Dictionary, col: Color, n: Vector3, p: Vector3) -> void:
	buf[Vector4(p.x, p.y, p.z, buf.size())] = [col, n.normalized(), p]


static func _smooth_prof(prof: Array, sub := 10) -> Array:
	if prof.size() < 3:
		return prof
	var pts: Array = []
	for i in range(prof.size()):
		pts.append(Vector2(float(prof[i][0]), float(prof[i][1])))
	var out: Array = []
	for i in range(pts.size() - 1):
		var p0: Vector2 = pts[maxi(0, i - 1)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(pts.size() - 1, i + 2)]
		for k in range(sub):
			var t := float(k) / float(sub)
			var t2 := t * t
			var t3 := t2 * t
			var q: Vector2 = 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
			out.append([maxf(0.0, q.x), q.y])
	out.append([pts[pts.size() - 1].x, pts[pts.size() - 1].y])
	return out

func _rev(prof: Array, col: Color, metal: bool, buf: Dictionary) -> void:
	prof = _smooth_prof(prof, 9)
	for i in range(prof.size() - 1):
		var r0: float = float(prof[i][0])
		var y0: float = float(prof[i][1])
		var r1: float = float(prof[i + 1][0])
		var y1: float = float(prof[i + 1][1])
		var dr := r1 - r0
		var dy := y1 - y0
		var nl := sqrt(dr * dr + dy * dy)
		if nl < 0.000001:
			continue
		var nr := dy / nl
		var ny := -dr / nl
		for j in range(SEG):
			var a0 := TAU * float(j) / float(SEG)
			var a1 := TAU * float(j + 1) / float(SEG)
			var c0 := cos(a0); var s0 := sin(a0)
			var c1 := cos(a1); var s1 := sin(a1)
			var p00 := Vector3(r0 * c0, y0, r0 * s0)
			var p01 := Vector3(r1 * c0, y1, r1 * s0)
			var p10 := Vector3(r0 * c1, y0, r0 * s1)
			var p11 := Vector3(r1 * c1, y1, r1 * s1)
			var n0 := Vector3(nr * c0, ny, nr * s0)
			var n1 := Vector3(nr * c1, ny, nr * s1)
			_push(buf, col, n0, p00)
			_push(buf, col, n1, p10)
			_push(buf, col, n1, p11)
			_push(buf, col, n0, p00)
			_push(buf, col, n1, p11)
			_push(buf, col, n0, p01)

func _ell(c: Vector3, r: Vector3, col: Color, metal: bool, buf: Dictionary) -> void:
	var rings := 20
	var segs := 40
	for i in range(rings):
		var t0 := PI * float(i) / float(rings)
		var t1 := PI * float(i + 1) / float(rings)
		for j in range(segs):
			var a0 := TAU * float(j) / float(segs)
			var a1 := TAU * float(j + 1) / float(segs)
			var v00 := Vector3(sin(t0) * cos(a0), cos(t0), sin(t0) * sin(a0))
			var v01 := Vector3(sin(t1) * cos(a0), cos(t1), sin(t1) * sin(a0))
			var v10 := Vector3(sin(t0) * cos(a1), cos(t0), sin(t0) * sin(a1))
			var v11 := Vector3(sin(t1) * cos(a1), cos(t1), sin(t1) * sin(a1))
			var q := [[v00, v10, v11], [v00, v11, v01]]
			for tri in q:
				for vv in tri:
					var nn := Vector3(vv.x / r.x, vv.y / r.y, vv.z / r.z)
					_push(buf, col, nn, c + Vector3(vv.x * r.x, vv.y * r.y, vv.z * r.z))

func _cyl(c: Array, r0: float, r1: float, h: float, col: Color, metal: bool, buf: Dictionary) -> void:
	var base := Vector3(c[0], c[1], c[2])
	var half := h * 0.5
	_rev([[r0, base.y - half], [r1, base.y + half]], col, metal, buf)
	_rev([[0.0, base.y + half], [r1, base.y + half]], col, metal, buf)
