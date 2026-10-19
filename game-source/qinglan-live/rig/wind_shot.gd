extends Node3D
const Rig3 := preload("res://rig/rig3.gd")
func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("14161A")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("39415A")
	e.ambient_light_energy = 0.45
	env.environment = e
	add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30, 150, 0)
	key.light_energy = 1.5
	key.light_color = Color(1.0, 0.9, 0.78)
	add_child(key)
	var r: Node3D = Rig3.new()
	r.build(true, true)
	add_child(r)
	var cam := Camera3D.new()
	cam.position = Vector3(0.35, 0.75, -2.5)
	cam.fov = 30.0
	add_child(cam)
	cam.look_at(Vector3(0, 0.55, 0), Vector3.UP)
	for i in range(4):
		await get_tree().create_timer(0.42).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://out/wind_%d.png" % i)
	print("WIND 3 frames")
	get_tree().quit()
