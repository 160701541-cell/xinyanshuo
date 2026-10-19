extends Node3D
# 剪影检查：纯品红背景，能量身比例
const Char3 := preload("res://rig/char3.gd")
func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(1, 0, 1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1,1,1); env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment = env; add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, 200, 0); key.light_energy = 1.3
	add_child(key)
	var c := Node3D.new(); add_child(c); Char3.new().build(c)
	var cam := Camera3D.new(); cam.fov = 28.0; cam.position = Vector3(0, 0.94, -4.0)
	add_child(cam); cam.look_at(Vector3(0, 0.90, 0), Vector3.UP); cam.current = true
	await Shot.grab(self, "res://out/sil_front.png", 3)
	c.rotation_degrees.y = -90
	await Shot.grab(self, "res://out/sil_side.png", 3)
	get_tree().quit()
