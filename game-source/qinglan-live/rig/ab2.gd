extends SceneTree
func _init() -> void:
	var c = load("res://rig/char3.gd").new()
	var root := Node3D.new()
	get_root().add_child(root)
	c.build(root)
	var i := 0
	for ch in root.get_children():
		if ch is MeshInstance3D:
			var ab: AABB = ch.mesh.get_aabb()
			if ab.position.y > 1.2 or ab.size.length() > 1.0:
				print(i, " y=", snappedf(ab.position.y,0.001), " sy=", snappedf(ab.size.y,0.001), " sz=", snappedf(ab.size.z,0.001), " ", ch.mesh.get_surface_count())
		i += 1
	quit()
