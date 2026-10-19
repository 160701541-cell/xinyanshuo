extends Node3D
const Char3 := preload("res://rig/char3.gd")
func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(1,0,1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1,1,1); env.ambient_light_energy = 1.0
	we.environment = env; add_child(we)
	var root := Node3D.new(); add_child(root)
	var c = Char3.new()
	# 只建脸
	c.build_face(root)
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 0.24
	cam.position = Vector3(0,1.545,-1.0)
	add_child(cam); cam.look_at(Vector3(0,1.545,0), Vector3.UP); cam.current = true
	await Shot.grab(self, "res://out/dbg_faceonly.png", 4)
	get_tree().quit()
