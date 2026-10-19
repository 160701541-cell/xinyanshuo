extends Node3D
# 无骨骼蒙皮的程序化人形：关节 = Node3D 层级，动作 = 关节旋转数据叠加混合
const VOX := 0.30
var bones := {}
var face := {}
var cel_mat: ShaderMaterial
var line_mat: ShaderMaterial
var use_cel := true
var mat: StandardMaterial3D

func _box(parent: Node3D, size: Vector3, off: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.position = off
	if use_cel:
		if cel_mat == null:
			cel_mat = ShaderMaterial.new(); cel_mat.shader = load("res://rig/cel.gdshader")
		if line_mat == null:
			line_mat = ShaderMaterial.new(); line_mat.shader = load("res://rig/outline.gdshader")
		var cm: ShaderMaterial = cel_mat.duplicate()
		cm.set_shader_parameter("albedo", c)
		mi.material_override = cm
		parent.add_child(mi)
		var ol := MeshInstance3D.new()
		ol.mesh = bm; ol.position = off
		ol.material_override = line_mat
		parent.add_child(ol)
		return mi
	var m := StandardMaterial3D.new()
	m.albedo_color = c; m.roughness = 0.85
	mi.material_override = m
	parent.add_child(mi)
	return mi

func _joint(name: String, parent: Node3D, off: Vector3) -> Node3D:
	var n := Node3D.new(); n.name = name; n.position = off
	parent.add_child(n); bones[name] = n
	return n

func build(robe := Color(0.26,0.42,0.42), skin := Color(0.94,0.80,0.70), hair := Color(0.14,0.13,0.15), sword := false) -> void:
	var root := Node3D.new(); add_child(root)
	var pelvis := _joint("pelvis", root, Vector3(0, 0.95, 0))
	_box(pelvis, Vector3(0.42,0.24,0.26), Vector3.ZERO, robe)
	var spine := _joint("spine", pelvis, Vector3(0, 0.14, 0))
	_box(spine, Vector3(0.44,0.42,0.26), Vector3(0,0.18,0), robe)
	var chest := _joint("chest", spine, Vector3(0, 0.40, 0))
	_box(chest, Vector3(0.52,0.30,0.28), Vector3(0,0.10,0), robe)
	var neck := _joint("neck", chest, Vector3(0, 0.26, 0))
	_box(neck, Vector3(0.14,0.10,0.14), Vector3(0,0.05,0), skin)
	var head := _joint("head", neck, Vector3(0, 0.10, 0))
	_box(head, Vector3(0.30,0.34,0.30), Vector3(0,0.16,0), skin)
	_box(head, Vector3(0.34,0.10,0.34), Vector3(0,0.32,0), hair)
	_box(head, Vector3(0.10,0.12,0.10), Vector3(0,0.40,0), hair)
	# —— 五官（表情用缩放/旋转驱动）——
	face["brow_L"] = _box(head, Vector3(0.082,0.015,0.02), Vector3(-0.062,0.215,-0.153), Color(0.16,0.14,0.16))
	face["brow_R"] = _box(head, Vector3(0.082,0.015,0.02), Vector3( 0.062,0.215,-0.153), Color(0.16,0.14,0.16))
	face["eye_L"] = _box(head, Vector3(0.082,0.058,0.02), Vector3(-0.062,0.155,-0.152), Color(0.97,0.96,0.94))
	face["eye_R"] = _box(head, Vector3(0.082,0.058,0.02), Vector3( 0.062,0.155,-0.152), Color(0.97,0.96,0.94))
	face["pup_L"] = _box(head, Vector3(0.034,0.050,0.02), Vector3(-0.060,0.153,-0.158), Color(0.13,0.15,0.20))
	face["pup_R"] = _box(head, Vector3(0.034,0.050,0.02), Vector3( 0.060,0.153,-0.158), Color(0.13,0.15,0.20))
	face["nose"] = _box(head, Vector3(0.030,0.048,0.03), Vector3(0,0.115,-0.158), skin.darkened(0.12))
	face["mouth"] = _box(head, Vector3(0.095,0.016,0.02), Vector3(0,0.058,-0.152), Color(0.55,0.26,0.26))
	for side in [-1,1]:
		var s := "L" if side < 0 else "R"
		var sh := _joint("sh_"+s, chest, Vector3(0.28*side, 0.16, 0))
		_box(sh, Vector3(0.16,0.34,0.18), Vector3(0,-0.16,0), robe)
		var el := _joint("el_"+s, sh, Vector3(0,-0.34,0))
		_box(el, Vector3(0.14,0.30,0.16), Vector3(0,-0.15,0), robe)
		var ha := _joint("ha_"+s, el, Vector3(0,-0.30,0))
		_box(ha, Vector3(0.12,0.14,0.12), Vector3(0,-0.07,0), skin)
		if sword and s == "R":
			# 右手持剑：握把 → 护手 → 剑身，沿 -Y 延伸（手臂抬起时剑尖朝上）
			var grip := Color(0.20,0.16,0.15)
			var gold := Color(0.72,0.56,0.24)
			var steel := Color(0.80,0.82,0.86)
			_box(ha, Vector3(0.055,0.18,0.055), Vector3(0,-0.11,0), grip)
			_box(ha, Vector3(0.17,0.035,0.07), Vector3(0,-0.205,0), gold)
			_box(ha, Vector3(0.052,0.62,0.016), Vector3(0,-0.535,0), steel)
			_box(ha, Vector3(0.030,0.07,0.016), Vector3(0,-0.865,0), steel.lightened(0.1))
		var hip := _joint("hip_"+s, pelvis, Vector3(0.12*side, -0.10, 0))
		_box(hip, Vector3(0.18,0.42,0.20), Vector3(0,-0.21,0), robe.darkened(0.15))
		var kn := _joint("kn_"+s, hip, Vector3(0,-0.42,0))
		_box(kn, Vector3(0.16,0.40,0.18), Vector3(0,-0.20,0), robe.darkened(0.25))
		var fo := _joint("fo_"+s, kn, Vector3(0,-0.40,0))
		_box(fo, Vector3(0.17,0.10,0.26), Vector3(0,-0.05,0.04), Color(0.14,0.14,0.16))

# 表情 = 眉/眼/嘴的缩放与位移
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
		face[k].rotation_degrees = Vector3(0,0, e["brow"] * (1 if k.ends_with("R") else -1))
	for k in ["eye_L","eye_R"]:
		face[k].scale = Vector3(1.0, e["eye"], 1.0)
	for k in ["pup_L","pup_R"]:
		face[k].scale = Vector3(1.0, e["eye"], 1.0)
	face["mouth"].scale = Vector3(e["mouth"], 1.0 + e["open"], 1.0)

# 动作 = 关节 -> (x,y,z) 度；未列出的关节归零
func pose(d: Dictionary) -> void:
	for k in bones.keys():
		bones[k].rotation_degrees = Vector3.ZERO
	for k in d.keys():
		if bones.has(k):
			var v: Vector3 = d[k]
			bones[k].rotation_degrees = v
