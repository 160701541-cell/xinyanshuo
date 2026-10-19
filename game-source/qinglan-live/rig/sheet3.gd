extends Node3D
# 角色多视图出图：正面 / 3-4 / 侧面 / 背面 / 脸部特写

const Char3 := preload("res://rig/char3.gd")

var char: Node3D
var cam: Camera3D

func _ready() -> void:
	_setup_world()
	char = Node3D.new()
	add_child(char)
	Char3.new().build(char)
	cam = Camera3D.new()
	cam.fov = 28.0
	cam.near = 0.02
	add_child(cam)
	cam.current = true

	var shots := [
		["front", 0.0, Vector3(0.0, 0.94, -4.0), Vector3(0.0, 0.90, 0.0)],
		["three", -42.0, Vector3(0.0, 0.94, -4.0), Vector3(0.0, 0.90, 0.0)],
		["side", -90.0, Vector3(0.0, 0.94, -4.0), Vector3(0.0, 0.90, 0.0)],
		["back", -180.0, Vector3(0.0, 0.94, -4.0), Vector3(0.0, 0.90, 0.0)],
	]
	for s in shots:
		char.rotation_degrees.y = s[1]
		cam.position = s[2]
		cam.look_at(s[3], Vector3.UP)
		await Shot.grab(self, "res://out/c3_%s.png" % s[0], 3)
	# 特写：正面 / 3-4
	for s in [["face_front", 0.0], ["face_three", -34.0]]:
		char.rotation_degrees.y = s[1]
		cam.position = Vector3(0.0, 1.560, -0.66)
		cam.look_at(Vector3(0.0, 1.548, 0.0), Vector3.UP)
		await Shot.grab(self, "res://out/c3_%s.png" % s[0], 3)
	get_tree().quit()

func _setup_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.07, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.46, 0.54, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	we.environment = env
	add_child(we)

	# 背景板
	var bd := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(9, 9)
	bd.mesh = q
	var bm := StandardMaterial3D.new()
	var bgtex := load("res://art/bg_v.png")
	if bgtex: bm.albedo_texture = bgtex
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	bd.material_override = bm
	bd.position = Vector3(0, 1.2, 2.2)
	bd.rotation_degrees = Vector3(0, 180, 0)
	add_child(bd)

	# 脚下投影
	var sh := MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(1.5, 0.85)
	sh.mesh = sq
	var sm := StandardMaterial3D.new()
	var stex := load("res://art/shadow.png")
	if stex: sm.albedo_texture = stex
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	sm.no_depth_test = false
	sh.material_override = sm
	sh.position = Vector3(0, 0.004, 0.0)
	sh.rotation_degrees = Vector3(-90, 0, 0)
	add_child(sh)

	# 主光：左前上
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-46, 198, 0)
	key.light_color = Color(1.0, 0.96, 0.90)
	key.light_energy = 1.55
	key.shadow_enabled = false
	add_child(key)
	# 补光：右前，冷
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-8, 128, 0)
	fill.light_color = Color(0.62, 0.76, 1.0)
	fill.light_energy = 0.55
	add_child(fill)
	# 轮廓光：后方
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-24, 8, 0)
	rim.light_color = Color(0.66, 0.94, 1.0)
	rim.light_energy = 1.1
	add_child(rim)
