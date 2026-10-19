extends Node3D
# 修仙者 v2：圆润体块 + 层叠道袍 + 长发 + 束带，取代 v1 的方块人
# 关节层级与 rig.gd 完全一致，所以 data_poses.json 的 149 条动作直接可用
var bones := {}
var face := {}
var cel_mat: ShaderMaterial
var line_mat: ShaderMaterial
var use_cel := true
var use_outline := true

# 调色板严格取自 ART_DIRECTION.md
const SKIN := Color(0.910, 0.769, 0.659)     # #E8C4A8
const SKIN_SH := Color(0.725, 0.541, 0.447)  # #B98A72
const HAIR := Color(0.078, 0.086, 0.102)     # #14161A
const ROBE_OUT := Color(0.180, 0.545, 0.545)# #2E8B8B 青碧
const ROBE_DEEP := Color(0.106, 0.369, 0.388)# #1B5E63 深青
const ROBE_IN := Color(0.937, 0.914, 0.863)  # #EFE9DC 宣纸
const TRIM := Color(0.910, 0.702, 0.231)     # #E8B33B 金
const TRIM_DK := Color(0.612, 0.455, 0.125)  # #9C7420
const SASH := Color(0.753, 0.224, 0.169)     # #C0392B 朱砂
const BOOT := Color(0.078, 0.086, 0.102)     # 墨
const STEEL := Color(0.725, 0.776, 0.824)
const JADE := Color(0.341, 0.780, 0.639)     # #57C7A3 玉
const SHADOW := Color(0.165, 0.169, 0.227)   # #2A2B3A 冷紫灰

var _wind_mats: Array[ShaderMaterial] = []
var _gust := 0.85
var _gv := 0.0
var _tt := 0.0

func _process(delta: float) -> void:
	# 阵风 = 阻尼弹簧追一个慢噪声目标（物理，但不是软体布）
	_tt += delta
	var target: float = 0.55 + 0.45 * sin(_tt * 1.13) * sin(_tt * 0.37 + 1.7)
	var k: float = 7.0
	var c: float = 2.6
	_gv += (-k * (_gust - target) - c * _gv) * delta
	_gust += _gv * delta
	for m in _wind_mats:
		m.set_shader_parameter("wind_gust", _gust)

func _wind(mi: MeshInstance3D, amp: float, phase: float) -> MeshInstance3D:
	var m := mi.material_override as ShaderMaterial
	if m != null:
		m.set_shader_parameter("wind_amp", amp)
		m.set_shader_parameter("wind_phase", phase)
		m.set_shader_parameter("wind_gust", _gust)
		_wind_mats.append(m)
	return mi

func _sync_outline() -> void:
	if line_mat == null:
		line_mat = ShaderMaterial.new(); line_mat.shader = load("res://rig/sso.gdshader")
	var vp := Vector2(1920.0, 1080.0)
	if is_inside_tree() and get_viewport() != null:
		vp = get_viewport().get_visible_rect().size
	line_mat.set_shader_parameter("viewport", vp)
	line_mat.set_shader_parameter("px", 1.3)

func _mat(c: Color) -> ShaderMaterial:
	if cel_mat == null:
		cel_mat = ShaderMaterial.new(); cel_mat.shader = load("res://rig/toon.gdshader")
	if line_mat == null:
		line_mat = ShaderMaterial.new(); line_mat.shader = load("res://rig/sso.gdshader")
		line_mat.set_shader_parameter("px", 1.3)
	var m: ShaderMaterial = cel_mat.duplicate()
	m.set_shader_parameter("albedo", c)
	# 材质纪律（第 4 节）
	if c.is_equal_approx(TRIM) or c.is_equal_approx(TRIM_DK):
		m.set_shader_parameter("roughness", 0.38); m.set_shader_parameter("metallic", 0.70)
		m.set_shader_parameter("rim_strength", 0.22)
	elif c.is_equal_approx(STEEL):
		m.set_shader_parameter("roughness", 0.30); m.set_shader_parameter("metallic", 0.85)
	elif c.is_equal_approx(JADE):
		m.set_shader_parameter("roughness", 0.15); m.set_shader_parameter("metallic", 0.0)
		m.set_shader_parameter("rim_strength", 0.30)
	elif c.is_equal_approx(SKIN) or c.is_equal_approx(SKIN_SH):
		m.set_shader_parameter("roughness", 0.62); m.set_shader_parameter("metallic", 0.0)
	elif c.is_equal_approx(HAIR) or c.is_equal_approx(BOOT):
		m.set_shader_parameter("roughness", 0.62); m.set_shader_parameter("metallic", 0.0)
		m.set_shader_parameter("rim_strength", 0.18)
	elif c.is_equal_approx(ROBE_IN):
		m.set_shader_parameter("roughness", 0.55); m.set_shader_parameter("metallic", 0.0)  # 丝
	else:
		m.set_shader_parameter("roughness", 0.85); m.set_shader_parameter("metallic", 0.0)  # 布
	return m

func _finish(parent: Node3D, mi: MeshInstance3D, c: Color, outline := true) -> MeshInstance3D:
	mi.material_override = _mat(c)
	parent.add_child(mi)
	if use_cel and outline and use_outline:
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


# 放样体：按横截面（超椭圆）堆出躯干/裙摆，替代圆柱
# prof = [{"y":局部y, "hw":半宽, "hd":半厚, "z":前后偏移, "k":方度}]
func _loft(parent: Node3D, prof: Array, c: Color, seg := 28, outline := true) -> MeshInstance3D:
	# 保证截面从下往上排，否则法线朝内、整块渲成黑的
	if prof.size() > 1 and float(prof[0]["y"]) > float(prof[prof.size() - 1]["y"]):
		prof = prof.duplicate()
		prof.reverse()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := []
	for item in prof:
		var ring := PackedVector3Array()
		var k: float = item.get("k", 2.6)
		for i in range(seg):
			var t := TAU * float(i) / float(seg)
			var ct := cos(t); var sn := sin(t)
			var px: float = item["hw"] * signf(ct) * pow(absf(ct), 2.0 / k)
			var pz: float = item["hd"] * signf(sn) * pow(absf(sn), 2.0 / k)
			ring.append(Vector3(px + item.get("x", 0.0), item["y"], pz + item.get("z", 0.0)))
		rings.append(ring)
	for r in range(rings.size() - 1):
		var a: PackedVector3Array = rings[r]
		var b: PackedVector3Array = rings[r + 1]
		for i in range(seg):
			var j := (i + 1) % seg
			for v in [a[i], a[j], b[j], a[i], b[j], b[i]]:
				st.add_vertex(v)
	# 上下封口
	for pair in [[rings[0], true], [rings[rings.size() - 1], false]]:
		var arr: PackedVector3Array = pair[0]
		var flip: bool = pair[1]
		var cy: float = arr[0].y
		var cz: float = 0.0
		for v in arr: cz += v.z
		cz /= float(seg)
		var ctr := Vector3(float(prof[0].get("x", 0.0)), cy, cz)
		for i in range(seg):
			var j := (i + 1) % seg
			if flip:
				st.add_vertex(ctr); st.add_vertex(arr[i]); st.add_vertex(arr[j])
			else:
				st.add_vertex(ctr); st.add_vertex(arr[j]); st.add_vertex(arr[i])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	return _finish(parent, mi, c, outline)

func _joint(name: String, parent: Node3D, off: Vector3) -> Node3D:
	var n := Node3D.new(); n.name = name; n.position = off
	parent.add_child(n); bones[name] = n
	return n

func build(sword := true, long_hair := true) -> void:
	_sync_outline()
	var root := Node3D.new(); add_child(root)

	var pelvis := _joint("pelvis", root, Vector3(0, 0.92, 0))
	for side in [-1.0, 1.0]:
		var s: String = "L" if side < 0.0 else "R"
		var x: float = 0.085 * side
		var hip := _joint("hip_" + s, pelvis, Vector3(x, -0.06, 0))
		_cyl(hip, 0.082, 0.058, 0.40, Vector3(0, -0.20, 0), ROBE_OUT.darkened(0.22))
		var kn := _joint("kn_" + s, hip, Vector3(0, -0.40, 0))
		_sphere(kn, 0.058, Vector3.ZERO, ROBE_OUT.darkened(0.26), Vector3(1.0, 0.9, 1.0), false)
		_cyl(kn, 0.056, 0.038, 0.38, Vector3(0, -0.19, 0), ROBE_OUT.darkened(0.30))
		var fo := _joint("fo_" + s, kn, Vector3(0, -0.38, 0))
		_cyl(fo, 0.062, 0.052, 0.10, Vector3(0, -0.03, 0), BOOT)
		_box(fo, Vector3(0.115, 0.075, 0.235), Vector3(0, -0.085, -0.035), BOOT)

	var spine := _joint("spine", pelvis, Vector3(0, 0.12, 0))
	# 腰腹：腰最细、往下放，符合人体而不是直筒
	_loft(spine, [
		{"y": -0.12, "hw": 0.150, "hd": 0.112, "k": 2.8},
		{"y": -0.02, "hw": 0.132, "hd": 0.100, "k": 2.8},
		{"y": 0.10, "hw": 0.140, "hd": 0.104, "k": 2.6},
		{"y": 0.22, "hw": 0.156, "hd": 0.110, "k": 2.6},
	], ROBE_OUT)
	var chest := _joint("chest", spine, Vector3(0, 0.30, 0))
	# 胸肩：肩最宽、往上收，肩头用肩线倒角
	_loft(chest, [
		{"y": -0.10, "hw": 0.158, "hd": 0.112, "k": 2.6},
		{"y": 0.02, "hw": 0.172, "hd": 0.118, "k": 2.5},
		{"y": 0.10, "hw": 0.180, "hd": 0.114, "k": 2.4},
		{"y": 0.15, "hw": 0.176, "hd": 0.108, "k": 2.3},
		{"y": 0.205, "hw": 0.140, "hd": 0.094, "k": 2.0},
	], ROBE_OUT)

	# 交领：右衽在上（z 更靠外 0.004），两片都压进胸口表面，顶端塞进立领里
	_box(chest, Vector3(0.066, 0.26, 0.007), Vector3(-0.028, 0.10, -0.136), ROBE_IN, Vector3(0, 0, -26), false)
	_box(chest, Vector3(0.070, 0.28, 0.007), Vector3(0.030, 0.095, -0.140), ROBE_IN, Vector3(0, 0, 26), false)
	_box(chest, Vector3(0.010, 0.26, 0.006), Vector3(0.056, 0.10, -0.145), TRIM, Vector3(0, 0, 26), false)
	_box(chest, Vector3(0.012, 0.30, 0.006), Vector3(0.066, 0.08, -0.156), TRIM, Vector3(0, 0, 19), false)
	_box(chest, Vector3(0.012, 0.30, 0.006), Vector3(-0.066, 0.08, -0.156), TRIM, Vector3(0, 0, -19), false)

	_torus(pelvis, 0.120, 0.150, Vector3(0, 0.10, 0), SASH, Vector3(0, 0, 0))
	_sphere(pelvis, 0.028, Vector3(0.0, 0.052, -0.140), JADE, Vector3(1.0, 1.1, 0.7))

	# 剑鞘：鞘身 + 鞘口 + 鞘尾 + 两道缠绳 + 剑穗
	var SHEATH := Color(0.235, 0.205, 0.180)
	_box(pelvis, Vector3(0.052, 0.76, 0.032), Vector3(-0.16, 0.10, 0.16), SHEATH, Vector3(0, 0, 18), false)
	_box(pelvis, Vector3(0.064, 0.055, 0.044), Vector3(-0.16, 0.485, 0.16), TRIM_DK, Vector3(0, 0, 18), false)   # 鞘口
	_box(pelvis, Vector3(0.050, 0.052, 0.038), Vector3(-0.16, -0.285, 0.16), TRIM_DK, Vector3(0, 0, 18), false)  # 鞘尾
	_torus(pelvis, 0.026, 0.034, Vector3(-0.152, 0.30, 0.155), TRIM, Vector3(90, 0, 18))
	_torus(pelvis, 0.026, 0.034, Vector3(-0.176, -0.10, 0.168), TRIM, Vector3(90, 0, 18))
	_cyl(pelvis, 0.010, 0.004, 0.11, Vector3(-0.175, -0.345, 0.170), SASH, Vector3(0, 0, 8))
	_box(pelvis, Vector3(0.045, 0.14, 0.03), Vector3(0.054, 0.47, 0.16), TRIM, Vector3(0, 0, 18))
	# 三层下摆：外袍 / 中衣 / 衬摆。三层用同一套风参数，只改半径，
	# 保证摆动时不会互相穿插（否则会出现"撕裂"的锯齿洞）
	var WIND := Vector2(0.040, 0.0)
	_wind(_loft(pelvis, [
		{"y": 0.02, "hw": 0.150, "hd": 0.112, "k": 2.8},
		{"y": -0.12, "hw": 0.158, "hd": 0.118, "k": 2.8},
		{"y": -0.30, "hw": 0.166, "hd": 0.124, "k": 2.7},
		{"y": -0.50, "hw": 0.174, "hd": 0.130, "k": 2.6},
		{"y": -0.62, "hw": 0.194, "hd": 0.145, "k": 2.5},
	], ROBE_OUT, 30), WIND.x, WIND.y)
	_wind(_loft(pelvis, [
		{"y": -0.58, "hw": 0.184, "hd": 0.138, "k": 2.5},
		{"y": -0.68, "hw": 0.192, "hd": 0.145, "k": 2.4},
	], ROBE_DEEP, 30), WIND.x, WIND.y)
	_wind(_loft(pelvis, [
		{"y": -0.64, "hw": 0.178, "hd": 0.134, "k": 2.5},
		{"y": -0.73, "hw": 0.196, "hd": 0.148, "k": 2.4},
	], ROBE_IN, 30), WIND.x, WIND.y)
	# 蔽膝：身前垂下的窄幅大带饰，到下 Alembic 小腿
	_box(pelvis, Vector3(0.090, 0.36, 0.012), Vector3(0, -0.20, -0.152), ROBE_OUT.darkened(0.06), Vector3.ZERO, true)
	_box(pelvis, Vector3(0.010, 0.36, 0.013), Vector3(-0.048, -0.20, -0.153), TRIM, Vector3.ZERO, true)
	_box(pelvis, Vector3(0.010, 0.36, 0.013), Vector3(0.048, -0.20, -0.153), TRIM, Vector3.ZERO, true)
	_box(pelvis, Vector3(0.098, 0.016, 0.014), Vector3(0, -0.382, -0.150), TRIM, Vector3.ZERO, true)
	# 侧缝金线
	_box(pelvis, Vector3(0.010, 0.58, 0.010), Vector3(-0.168, -0.26, 0.0), TRIM, Vector3.ZERO, true)
	_box(pelvis, Vector3(0.010, 0.58, 0.010), Vector3(0.168, -0.26, 0.0), TRIM, Vector3.ZERO, true)
	_loft(pelvis, [
		{"y": -0.705, "hw": 0.198, "hd": 0.150, "k": 2.4},
		{"y": -0.725, "hw": 0.202, "hd": 0.153, "k": 2.4},
	], TRIM, 30)
	# 外袍前襟两片，带 C 形分缝
	_box(pelvis, Vector3(0.010, 0.38, 0.014), Vector3(-0.050, -0.28, -0.140), TRIM, Vector3(0, 0, 2), false)
	_box(pelvis, Vector3(0.010, 0.38, 0.014), Vector3(0.050, -0.28, -0.140), TRIM, Vector3(0, 0, -2), false)

	for side in [-1.0, 1.0]:
		var s: String = "L" if side < 0.0 else "R"
		var sh := _joint("sh_" + s, chest, Vector3(0.132 * side, 0.112, 0))
		_sphere(chest, 0.066, Vector3(0.138 * side, 0.146, 0), ROBE_OUT, Vector3(1.0, 0.92, 1.0), false)
		# 广袖：从肩一直垂到手腕，袖口收拢把掌露出来（不再让小臂从袖口下方捅出来）
		_wind(_loft(sh, [
			{"y": 0.075, "hw": 0.042, "hd": 0.042, "x": 0.0, "k": 2.6},
			{"y": -0.06, "hw": 0.060, "hd": 0.058, "x": 0.008 * side, "k": 2.6},
			{"y": -0.22, "hw": 0.078, "hd": 0.072, "x": 0.020 * side, "k": 2.7},
			{"y": -0.40, "hw": 0.094, "hd": 0.084, "x": 0.030 * side, "k": 2.7},
			{"y": -0.56, "hw": 0.089, "hd": 0.078, "x": 0.034 * side, "k": 2.8},
			{"y": -0.64, "hw": 0.052, "hd": 0.048, "x": 0.036 * side, "k": 2.4},
		], ROBE_OUT, 32), 0.028, 0.6)
		_torus(sh, 0.054, 0.062, Vector3(0.036 * side, -0.632, 0), TRIM, Vector3(0, 0, 0))
		var el := _joint("el_" + s, sh, Vector3(0, -0.36, 0))
		_cyl(el, 0.040, 0.044, 0.24, Vector3(0, -0.12, 0), SKIN.darkened(0.04))
		_torus(el, 0.046, 0.054, Vector3(0, -0.235, 0), TRIM, Vector3(0, 0, 0))
		var ha := _joint("ha_" + s, el, Vector3(0, -0.30, 0))
		_box(ha, Vector3(0.056, 0.078, 0.034), Vector3(0, -0.040, 0), SKIN, Vector3.ZERO, false)     # 掌
		for fi in range(4):
			_box(ha, Vector3(0.011, 0.040, 0.020), Vector3(-0.019 + 0.013 * float(fi), -0.092, 0.0), SKIN, Vector3(0, 0, 3.0 * float(fi) - 4.5), false)
		_box(ha, Vector3(0.013, 0.034, 0.020), Vector3(0.030, -0.052, 0.006), SKIN, Vector3(0, 0, -34), false)  # 拇指
		if sword and s == "R":
			_box(ha, Vector3(0.045, 0.17, 0.045), Vector3(0, -0.16, 0), Color(0.18, 0.14, 0.13))
			_box(ha, Vector3(0.16, 0.028, 0.06), Vector3(0, -0.245, 0), TRIM)
			_box(ha, Vector3(0.048, 0.60, 0.014), Vector3(0, -0.56, 0), STEEL)
			_box(ha, Vector3(0.026, 0.075, 0.014), Vector3(0, -0.885, 0), STEEL.lightened(0.12))

	# 立领：把脖子根部裹进衣领，脖子露出的长度从 7cm 降到 4cm
	_cyl(chest, 0.070, 0.062, 0.075, Vector3(0, 0.168, 0), ROBE_IN, Vector3.ZERO)
	_torus(chest, 0.066, 0.078, Vector3(0, 0.203, 0), TRIM, Vector3(0, 0, 0))
	var neck := _joint("neck", chest, Vector3(0, 0.205, 0))
	_cyl(neck, 0.058, 0.064, 0.046, Vector3(0, 0.014, 0), SKIN.darkened(0.06), Vector3.ZERO)
	var head := _joint("head", neck, Vector3(0, 0.058, 0))
	_sphere(head, 0.108, Vector3(0, 0.098, 0), SKIN, Vector3(0.95, 1.14, 0.84))
	

	face["brow_L"] = _box(head, Vector3(0.044, 0.007, 0.010), Vector3(-0.038, 0.143, -0.099), HAIR, Vector3.ZERO, false)
	face["brow_R"] = _box(head, Vector3(0.044, 0.007, 0.010), Vector3(0.038, 0.143, -0.099), HAIR, Vector3.ZERO, false)
	face["eye_L"] = _sphere(head, 0.019, Vector3(-0.038, 0.112, -0.093), Color(0.97, 0.97, 0.96), Vector3(1.70, 0.62, 0.40), false)
	face["eye_R"] = _sphere(head, 0.019, Vector3(0.038, 0.112, -0.093), Color(0.97, 0.97, 0.96), Vector3(1.70, 0.62, 0.40), false)
	face["pup_L"] = _sphere(head, 0.0105, Vector3(-0.038, 0.111, -0.099), Color(0.10, 0.12, 0.16), Vector3(0.95, 0.95, 0.5), false)
	face["pup_R"] = _sphere(head, 0.0105, Vector3(0.038, 0.111, -0.099), Color(0.10, 0.12, 0.16), Vector3(0.95, 0.95, 0.5), false)
	_box(head, Vector3(0.052, 0.008, 0.008), Vector3(-0.041, 0.130, -0.099), Color(0.14, 0.12, 0.14), Vector3.ZERO, false)
	_box(head, Vector3(0.052, 0.008, 0.008), Vector3(0.041, 0.130, -0.099), Color(0.14, 0.12, 0.14), Vector3.ZERO, false)
	_box(head, Vector3(0.013, 0.026, 0.014), Vector3(0, 0.082, -0.100), SKIN.darkened(0.10), Vector3.ZERO, false)
	face["mouth"] = _box(head, Vector3(0.034, 0.008, 0.008), Vector3(0, 0.050, -0.099), Color(0.62, 0.34, 0.33), Vector3.ZERO, false)

	# 发：一个贴合的头壳 + 发带 + 两缕鬓发 + 马尾（内部件不描边，避免黑块堆叠）
	_sphere(head, 0.118, Vector3(0, 0.118, 0.040), HAIR, Vector3(1.0, 1.06, 1.0), false)
	_torus(head, 0.112, 0.126, Vector3(0, 0.182, 0.006), Color(0.26, 0.34, 0.46), Vector3(0, 0, 0))
	_sphere(head, 0.030, Vector3(0, 0.268, 0.010), HAIR, Vector3.ONE, false)
	_box(head, Vector3(0.026, 0.075, 0.026), Vector3(-0.100, 0.148, -0.010), HAIR, Vector3(0, 0, 8), false)
	_box(head, Vector3(0.026, 0.075, 0.026), Vector3(0.100, 0.148, -0.010), HAIR, Vector3(0, 0, -8), false)
	if long_hair:
		_cyl(head, 0.030, 0.042, 0.24, Vector3(0, 0.06, 0.132), HAIR, Vector3(-14, 0, 0))
		_cyl(head, 0.022, 0.030, 0.26, Vector3(0, -0.16, 0.172), HAIR, Vector3(-6, 0, 0))
		_cyl(head, 0.010, 0.022, 0.22, Vector3(0, -0.39, 0.185), HAIR, Vector3(0, 0, 0))
		# 发丝：细于主体的发绺，制造"有发丝"的层次而不是一整块黑
		for i in range(7):
			var u := (float(i) - 3.0) / 3.0
			var ax := 0.082 * u
			var az := 0.088 + 0.020 * (1.0 - u * u)
			_cyl(head, 0.016, 0.011, 0.24 + 0.05 * (1.0 - absf(u)), Vector3(ax, -0.05, az + 0.006), HAIR.darkened(0.10), Vector3(-8.0, 0, 6.0 * u))
			_cyl(head, 0.011, 0.006, 0.17, Vector3(ax * 1.05, -0.24, az + 0.016), HAIR.lightened(0.10), Vector3(-2.0, 0, 4.0 * u))

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
