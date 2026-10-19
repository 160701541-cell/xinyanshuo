extends Node3D
const Char3 := preload("res://rig/char3.gd")
func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(1,0,1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1,1,1); env.ambient_light_energy = 1.0
	we.environment = env; add_child(we)
	var k := DirectionalLight3D.new(); k.rotation_degrees = Vector3(-20,180,0); k.light_energy = 1.0
	add_child(k)
	var c := Node3D.new(); add_child(c); var ch = Char3.new(); ch.build(c)
	var cam := Camera3D.new(); cam.fov = 30.0; cam.position = Vector3(0,1.55,-0.55)
	add_child(cam); cam.look_at(Vector3(0,1.55,0)); cam.current = true
	await Shot.grab(self, "res://out/head_ol.png", 3)
	var n := 0
	for m in _walk(c):
		if m is MeshInstance3D and m.material_override is ShaderMaterial:
			m.material_override.next_pass = null; n += 1
	print("cleared ", n)
	await Shot.grab(self, "res://out/head_nool.png", 3)
	get_tree().quit()
func _walk(n: Node) -> Array:
	var o := [n]
	for ch in n.get_children(): o.append_array(_walk(ch))
	return o
