extends Node3D

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var path := "res://assets/cc0/character.glb"
	var out := "res://out/glb.png"
	for a in args:
		if a.begins_with("--glb="): path = a.split("=")[1]
		if a.begins_with("--out="): out = a.split("=")[1]
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.93, 0.91, 0.87)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.74, 0.80)
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, 148, -12)
	key.light_energy = 2.0
	key.light_color = Color(1.0, 0.96, 0.90)
	add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-10, 330, 0)
	rim.light_energy = 0.7
	rim.light_color = Color(0.70, 0.84, 0.92)
	add_child(rim)
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var err := doc.append_from_file(path, st)
	if err != OK:
		print("GLB_ERR ", err)
		get_tree().quit()
		return
	var inst: Node3D = doc.generate_scene(st)
	add_child(inst)
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := Vector3(-1e9, -1e9, -1e9)
	for m in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null: continue
		var bb: AABB = mi.global_transform * mi.mesh.get_aabb()
		lo = lo.min(bb.position); hi = hi.max(bb.position + bb.size)
	var c := (lo + hi) * 0.5
	var size := hi - lo
	var cam := Camera3D.new()
	cam.fov = 30.0
	add_child(cam)
	var d := maxf(size.length() * 1.6, 0.5)
	cam.position = c + Vector3(size.x * 0.25, size.y * 0.16, d)
	cam.look_at_from_position(cam.position, c, Vector3.UP)
	for i in range(10): await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("GLB ", out, " ", img.get_size(), " size=", size)
	get_tree().quit()
