extends Node3D
# 修仙者 v2：圆润体块 + 层叠道袍 + 长发 + 束带，取代 v1 的方块人
# 关节层级与 rig.gd 完全一致，所以 data_poses.json 的 149 条动作直接可用
var bones := {}
var face := {}
var cel_mat: ShaderMaterial
var line_mat: ShaderMaterial
var use_cel := true

const SKIN := Color(0.95, 0.83, 0.74)
const HAIR := Color(0.10, 0.09, 0.11)
const ROBE_OUT := Color(0.30, 0.47, 0.52)
const ROBE_IN := Color(0.90, 0.92, 0.94)
const TRIM := Color(0.78, 0.66, 0.34)
const SASH := Color(0.62, 0.26, 0.26)
const BOOT := Color(0.16, 0.15, 0.18)
const STEEL := Color(0.82, 0.84, 0.88)

func _mat(c: Color) -> ShaderMaterial:
	if cel_mat == null:
		cel_mat = ShaderMaterial.new(); cel_mat.shader = load("res://rig/cel.gdshader")
	if line_mat == null:
		line_mat = ShaderMaterial.new(); line_mat.shader = load("res://rig/outline.gdshader")
	var m: ShaderMaterial = cel_mat.duplicate()
	m.set_shader_parameter("albedo", c)
	return m

func _finish(parent: Node3D, mi: MeshInstance3D, c: Color, outline := true) -> MeshInstance3D:
	mi.material_override = _mat(c)
	parent.add_child(mi)
	if use_cel and outline:
		var ol := MeshInstance3D.new()
		ol.mesh = mi.mesh
		ol.transform = mi.transform
		ol.material_override = line_mat
		parent.add_child(ol)
	return mi

func _box(parent: Node3D, size: Vector3, off: Vector3, c: Color, rot := Vector3.ZERO, outline := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.position = off; mi.rotation_degrees = rot
	return _finish(parent, mi, c, outline)

func _sphere(parent: Node3D, r: float, off: Vector3, c: Color, scale := Vector3.ONE, outline := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = r; sm.height = r * 2.0; sm.radial_segments = 16; sm.rings = 8
	mi.mesh = sm; mi.position = off; mi.scale = scale
	return _finish(parent, mi, c, outline)

func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, off: Vector3, c: Color, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top_r; cm.bottom_radius = bot_r; cm.height = h
	cm.radial_segments = 14; cm.rings = 1
	mi.mesh = cm; mi.position = off; mi.rotation_degrees = rot
	return _finish(parent, mi, c)

func _torus(parent: Node3D, inner: float, outer: float, off: Vector3, c: Color, rot := Vector3(90,0,0)) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new(); tm.inner_radius = inner; tm.outer_radius = outer; tm.rings = 20; tm.ring_segments = 8
	mi.mesh = tm; mi.position = off; mi.rotation_degrees = rot
	return _finish(parent, mi, c)

func _joint(name: String, parent: Node3D, off: Vector3) -> Node3D:
	var n := Node3D.new(); n.name = name; n.position = off
	parent.add_child(n); bones[name] = n
	return n

func build(sword := true, long_hair := true) -> void:
	var root := Node3D.new(); add_child(root)

	var pelvis := _joint("pelvis", root, Vector3(0, 0.92, 0))
	for side in [-1.0, 1.0]:
		var s: String = "L" if side < 0.0 else "R"
		var x: float = 0.085 * side
		var hip := _joint("hip_" + s, pelvis, Vector3(x, -0.06, 0))
		_cyl(hip, 0.078, 0.062, 0.40, Vector3(0, -0.20, 0), ROBE_OUT.darkened(0.22))
		var kn := _joint("kn_" + s, hip, Vector3(0, -0.40, 0))
		_cyl(kn, 0.060, 0.046, 0.38, Vector3(0, -0.19, 0), ROBE_OUT.darkened(0.30))
		var fo := _joint("fo_" + s, kn, Vector3(0, -0.38, 0))
		_cyl(fo, 0.062, 0.052, 0.10, Vector3(0, -0.03, 0), BOOT)
		_box(fo, Vector3(0.115, 0.075, 0.235), Vector3(0, -0.085, -0.035), BOOT)

	_cyl(pelvis, 0.135, 0.125, 0.20, Vector3(0, 0.04, 0), ROBE_OUT)
	var spine := _joint("spine", pelvis, Vector3(0, 0.12, 0))
	_cyl(spine, 0.155, 0.135, 0.30, Vector3(0, 0.14, 0), ROBE_OUT)
	var chest := _joint("chest", spine, Vector3(0, 0.30, 0))
	_cyl(chest, 0.185, 0.150, 0.26, Vector3(0, 0.10, 0), ROBE_OUT)

	_box(chest, Vector3(0.072, 0.26, 0.014), Vector3(0.042, 0.10, -0.140), ROBE_IN, Vector3(0, 0, 16), false)
	_box(chest, Vector3(0.072, 0.26, 0.014), Vector3(-0.042, 0.10, -0.140), ROBE_IN, Vector3(0, 0, -16), false)
	_box(chest, Vector3(0.016, 0.26, 0.010), Vector3(0.075, 0.10, -0.146), TRIM, Vector3(0, 0, 16), false)
	_box(chest, Vector3(0.016, 0.26, 0.010), Vector3(-0.075, 0.10, -0.146), TRIM, Vector3(0, 0, -16), false)

	_torus(pelvis, 0.120, 0.150, Vector3(0, 0.10, 0), SASH, Vector3(0, 0, 0))
	_sphere(pelvis, 0.030, Vector3(0.0, 0.055, -0.135), Color(0.55, 0.82, 0.75))

	_box(pelvis, Vector3(0.055, 0.78, 0.035), Vector3(-0.16, 0.10, 0.16), Color(0.30, 0.26, 0.22), Vector3(0, 0, 18))
	_box(pelvis, Vector3(0.045, 0.14, 0.03), Vector3(0.054, 0.47, 0.16), TRIM, Vector3(0, 0, 18))
	_cyl(pelvis, 0.150, 0.260, 0.34, Vector3(0, -0.14, 0), ROBE_OUT)
	_cyl(pelvis, 0.255, 0.275, 0.22, Vector3(0, -0.40, 0), ROBE_IN)
	_cyl(pelvis, 0.273, 0.288, 0.045, Vector3(0, -0.525, 0), TRIM)
	_box(pelvis, Vector3(0.028, 0.50, 0.02), Vector3(0, -0.26, -0.240), TRIM)

	for side in [-1.0, 1.0]:
		var s: String = "L" if side < 0.0 else "R"
		var sh := _joint("sh_" + s, chest, Vector3(0.175 * side, 0.14, 0))
		_cyl(sh, 0.085, 0.105, 0.34, Vector3(0, -0.17, 0), ROBE_OUT)
		_torus(sh, 0.098, 0.112, Vector3(0, -0.33, 0), TRIM, Vector3(0, 0, 0))
		var el := _joint("el_" + s, sh, Vector3(0, -0.36, 0))
		_cyl(el, 0.052, 0.060, 0.30, Vector3(0, -0.15, 0), ROBE_IN)
		var ha := _joint("ha_" + s, el, Vector3(0, -0.30, 0))
		_sphere(ha, 0.052, Vector3(0, -0.045, 0), SKIN, Vector3(0.85, 1.15, 0.7))
		if sword and s == "R":
			_box(ha, Vector3(0.045, 0.17, 0.045), Vector3(0, -0.16, 0), Color(0.18, 0.14, 0.13))
			_box(ha, Vector3(0.16, 0.028, 0.06), Vector3(0, -0.245, 0), TRIM)
			_box(ha, Vector3(0.048, 0.60, 0.014), Vector3(0, -0.56, 0), STEEL)
			_box(ha, Vector3(0.026, 0.075, 0.014), Vector3(0, -0.885, 0), STEEL.lightened(0.12))

	var neck := _joint("neck", chest, Vector3(0, 0.24, 0))
	_cyl(neck, 0.045, 0.052, 0.075, Vector3(0, 0.025, 0), SKIN.darkened(0.06), Vector3.ZERO)
	var head := _joint("head", neck, Vector3(0, 0.09, 0))
	_sphere(head, 0.108, Vector3(0, 0.098, 0), SKIN, Vector3(0.94, 1.12, 0.96))
	

	face["brow_L"] = _box(head, Vector3(0.050, 0.009, 0.010), Vector3(-0.041, 0.145, -0.099), HAIR, Vector3.ZERO, false)
	face["brow_R"] = _box(head, Vector3(0.050, 0.009, 0.010), Vector3(0.041, 0.145, -0.099), HAIR, Vector3.ZERO, false)
	face["eye_L"] = _sphere(head, 0.024, Vector3(-0.041, 0.113, -0.093), Color(0.97, 0.97, 0.96), Vector3(1.42, 0.92, 0.42), false)
	face["eye_R"] = _sphere(head, 0.024, Vector3(0.041, 0.113, -0.093), Color(0.97, 0.97, 0.96), Vector3(1.42, 0.92, 0.42), false)
	face["pup_L"] = _sphere(head, 0.0135, Vector3(-0.041, 0.112, -0.100), Color(0.10, 0.12, 0.16), Vector3(1.0, 1.25, 0.5), false)
	face["pup_R"] = _sphere(head, 0.0135, Vector3(0.041, 0.112, -0.100), Color(0.10, 0.12, 0.16), Vector3(1.0, 1.25, 0.5), false)
	_box(head, Vector3(0.052, 0.008, 0.008), Vector3(-0.041, 0.130, -0.099), Color(0.14, 0.12, 0.14), Vector3.ZERO, false)
	_box(head, Vector3(0.052, 0.008, 0.008), Vector3(0.041, 0.130, -0.099), Color(0.14, 0.12, 0.14), Vector3.ZERO, false)
	_box(head, Vector3(0.013, 0.026, 0.014), Vector3(0, 0.082, -0.100), SKIN.darkened(0.10), Vector3.ZERO, false)
	face["mouth"] = _box(head, Vector3(0.034, 0.008, 0.008), Vector3(0, 0.050, -0.099), Color(0.62, 0.34, 0.33), Vector3.ZERO, false)

	# 发：一个贴合的头壳 + 发带 + 两缕鬓发 + 马尾（内部件不描边，避免黑块堆叠）
	_sphere(head, 0.118, Vector3(0, 0.118, 0.040), HAIR, Vector3(1.0, 1.06, 1.0), false)
	_torus(head, 0.112, 0.126, Vector3(0, 0.182, 0.006), Color(0.26, 0.34, 0.46), Vector3(0, 0, 0))
	_sphere(head, 0.030, Vector3(0, 0.268, 0.010), HAIR, Vector3.ONE, false)
	_box(head, Vector3(0.030, 0.115, 0.028), Vector3(-0.100, 0.135, -0.045), HAIR, Vector3(0, 0, 10), false)
	_box(head, Vector3(0.030, 0.115, 0.028), Vector3(0.100, 0.135, -0.045), HAIR, Vector3(0, 0, -10), false)
	if long_hair:
		_cyl(head, 0.030, 0.042, 0.24, Vector3(0, 0.06, 0.132), HAIR, Vector3(-14, 0, 0))
		_cyl(head, 0.022, 0.030, 0.26, Vector3(0, -0.16, 0.172), HAIR, Vector3(-6, 0, 0))
		_cyl(head, 0.010, 0.022, 0.22, Vector3(0, -0.39, 0.185), HAIR, Vector3(0, 0, 0))

func express(name: String) -> void:
	var E := {
		"平静": {"brow":0.0,"eye":1.0,"mouth":1.0,"open":0.0},
		"微笑": {"brow":-6.0,"eye":0.86,"mouth":1.25,"open":0.3},
		"大笑": {"brow":-12.0,"eye":0.55,"mouth":1.9,"open":1.4},
		"愤怒": {"brow":22.0,"eye":0.90,"mouth":1.1,"open":0.5},
		"惊讶": {"brow":-24.0,"eye":1.20,"mouth":1.2,"open":1.7},
		"悲伤": {"brow":14.0,"eye":0.75,"mouth":0.8,"open":0.1},
		"痛苦": {"brow":16.0,"eye":0.30,"mouth":1.0,"open":0.9},
		"坚毅": {"brow":-8.0,"eye":0.80,"mouth":0.9,"open":0.0},
	}
	var e: Dictionary = E.get(name, E["平静"])
	for k in ["brow_L","brow_R"]:
		face[k].rotation_degrees = Vector3(0, 0, e["brow"] * (1 if k.ends_with("R") else -1))
	for k in ["eye_L","eye_R"]:
		face[k].scale = Vector3(1.35, 0.85 * e["eye"], 0.5)
	for k in ["pup_L","pup_R"]:
		face[k].scale = Vector3(1.0, 1.15 * e["eye"], 0.5)
	face["mouth"].scale = Vector3(e["mouth"], 1.0 + e["open"], 1.0)

func pose(d: Dictionary) -> void:
	for k in bones.keys():
		bones[k].rotation_degrees = Vector3.ZERO
	for k in d.keys():
		if bones.has(k):
			var v: Vector3 = d[k]
			bones[k].rotation_degrees = v
