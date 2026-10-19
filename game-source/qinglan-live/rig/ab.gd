extends SceneTree
func _init() -> void:
	var c = load("res://rig/char3.gd").new()
	var root := Node3D.new()
	get_root().add_child(root)
	c.build(root)
	for ch in root.get_children():
		if ch is MeshInstance3D:
			var ab: AABB = ch.mesh.get_aabb()
			print("AABB pos=", ab.position, " size=", ab.size)
	quit()
