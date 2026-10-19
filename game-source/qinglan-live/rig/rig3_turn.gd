extends Node3D
# rig3 四视图：严格按美术纪律布光（暖主光 2.2 / 冷天光 0.45 / 轮廓光 1.2）
const Rig3 := preload("res://rig/rig3.gd")

func _ready() -> void:
	var bg := Color(0.078, 0.086, 0.102)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.42, 0.55)
	env.ambient_light_energy = 0.30
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 0.85
	we.environment = env
	add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, 138, -12)
	key.light_energy = 1.15
	key.light_color = Color(1.0, 0.88, 0.72)
	add_child(key)
	var sky := DirectionalLight3D.new()
	sky.rotation_degrees = Vector3(-68, 20, 0)
	sky.light_energy = 0.30
	sky.light_color = Color(0.60, 0.75, 1.0)
	add_child(sky)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-16, -60, 0)
	rim.light_energy = 0.70
	var back := DirectionalLight3D.new()
	back.light_energy = 0.50
	back.light_color = Color(0.74, 0.82, 0.88)
	back.rotation_degrees = Vector3(-24, 196, 0)
	add_child(back)
	rim.light_color = Color(1.0, 0.95, 0.86)
	add_child(rim)

	get_viewport().transparent_bg = true
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(14, 14)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.11, 0.10, 0.11)
	gm.roughness = 0.9
	ground.material_override = gm
	# 地面不参与出图（透明背景，主体只留角色）
	ground.visible = false

	var xs := [-2.10, -0.70, 0.70, 2.10]
	var rots := [0.0, 40.0, 90.0, 180.0]
	for i in range(4):
		var r: Node3D = Rig3.new()
		r.build(true, true)
		add_child(r)
		r.position = Vector3(xs[i], 0, 0)
		r.rotation_degrees.y = rots[i]

	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.02, -7.6)
	cam.fov = 24.0
	add_child(cam)
	cam.look_at(Vector3(0, 0.98, 0), Vector3.UP)
	for f in 6:
		await get_tree().process_frame
	await Shot.grab(self, "res://out/rig3_turn.png")
	get_tree().quit()
