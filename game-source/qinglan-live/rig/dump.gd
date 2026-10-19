extends SceneTree
const Char3 := preload("res://rig/char3.gd")
func _initialize() -> void:
	var root := Node3D.new()
	var ch = Char3.new()
	ch.build(root)
	for n in root.get_children():
		if n is MeshInstance3D:
			var ab: AABB = n.get_aabb()
			var m = n.mesh.surface_get_material(0)
			var col = "-"
			if m is ShaderMaterial: col = str(m.get_shader_parameter("albedo"))
			print("MESH y[%.3f..%.3f] x[%.3f..%.3f] z[%.3f..%.3f] %s" % [ab.position.y, ab.end.y, ab.position.x, ab.end.x, ab.position.z, ab.end.z, col])
	quit()
