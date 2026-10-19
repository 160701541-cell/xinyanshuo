extends Node3D
const V := preload("res://rig/vfx3.gd")
var vfx: Node3D
func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("14161A")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("39415A")
	e.ambient_light_energy = 0.5
	env.environment = e
	add_child(env)
	vfx = V.new()
	add_child(vfx)
	for spec in [["slash", -1.75], ["ward", 0.0], ["basin", 1.75]]:
		var root := Node3D.new()
		root.position = Vector3(spec[1], 0.0, 0.0)
		add_child(root)
		match spec[0]:
			"slash": vfx.build_slash(root)
			"ward": vfx.build_ward(root)
			"basin": vfx.build_basin(root)
	var cam := Camera3D.new()
	cam.fov = 34.0
	cam.position = Vector3(0, 0.55, 4.4)
	add_child(cam)
	cam.look_at(Vector3(0, 0.42, 0), Vector3.UP)
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://out/vfx3.png")
	print("SHOT res://out/vfx3.png ", img.get_width(), "x", img.get_height())
	get_tree().quit()
