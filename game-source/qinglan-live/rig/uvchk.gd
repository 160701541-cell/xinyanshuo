extends SceneTree
func _init() -> void:
	var c = load("res://rig/char3.gd").new()
	var root := Node3D.new()
	get_root().add_child(root)
	c.build(root)
	for ch in root.get_children():
		if ch is MeshInstance3D and ch.material_override is StandardMaterial3D:
			var arr = ch.mesh.surface_get_arrays(0)
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			print("N=", uv.size())
			for i in [0,1,2,16,17,18,34,35,36, 300, 301, 302, 320, 590]:
				if i < uv.size(): print(i, " uv=", uv[i], " v=", v[i])
			break
	quit()
