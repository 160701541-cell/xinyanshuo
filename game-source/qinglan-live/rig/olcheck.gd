extends Node3D
const Char3 := preload("res://rig/char3.gd")
func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(1,0,1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1,1,1); env.ambient_light_energy = 0.5
	we.environment = env; add_child(we)
	var k := DirectionalLight3D.new(); k.rotation_degrees = Vector3(-35,200,0); k.shadow_enabled = false; add_child(k)
	var c := Node3D.new(); add_child(c); var ch = Char3.new(); ch.build(c)
	var cam := Camera3D.new(); cam.fov = 26.0; cam.position = Vector3(0,1.05,-4.6)
	add_child(cam); cam.look_at(Vector3(0,1.05,0)); cam.current = true
	await Shot.grab(self, "res://out/ol_on.png", 3)
	for m in _all_mats(c):
		if m is ShaderMaterial: m.next_pass = null
	await Shot.grab(self, "res://out/ol_off.png", 3)
	get_tree().quit()
func _all_mats(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D: out.append(n.mesh.surface_get_material(0))
	for c in n.get_children(): out.append_array(_all_mats(c))
	return out
