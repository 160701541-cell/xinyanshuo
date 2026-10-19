extends Node3D
const Char3 := preload("res://rig/char3.gd")
func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(1,0,1)
	we.environment = env; add_child(we)
	var c := Node3D.new(); add_child(c); var ch = Char3.new(); ch.build(c)
	var pal := [Color("ff0000"),Color("00ff00"),Color("0000ff"),Color("ffff00"),Color("00ffff"),Color("ff00ff"),Color("ffffff"),Color("808080"),Color("ff8800"),Color("8800ff")]
	var i := 0
	for n in _walk(c):
		if n is MeshInstance3D:
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = pal[i % pal.size()]
			n.material_override = m
			print("%s -> %s  y[%.2f..%.2f]" % [n.name, pal[i % pal.size()], n.get_aabb().position.y, n.get_aabb().end.y])
			i += 1
	var cam := Camera3D.new(); cam.fov = 26.0; cam.position = Vector3(0,0.95,-4.6)
	add_child(cam); cam.look_at(Vector3(0,0.95,0)); cam.current = true
	await Shot.grab(self, "res://out/flat.png", 3)
	get_tree().quit()
func _walk(n: Node) -> Array:
	var o := [n]
	for ch in n.get_children(): o.append_array(_walk(ch))
	return o
