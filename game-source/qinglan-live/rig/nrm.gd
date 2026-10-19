extends SceneTree
const Char3 := preload("res://rig/char3.gd")
func _initialize() -> void:
	var root := Node3D.new(); var ch = Char3.new(); ch.build(root)
	var want := [[0.960,1.400],[0.115,1.100],[1.436,1.669]]
	for n in root.get_children():
		if not (n is MeshInstance3D): continue
		var ab: AABB = n.get_aabb()
		var tag := ""
		for w in want:
			if absf(ab.position.y - w[0]) < 0.002 and absf(ab.end.y - w[1]) < 0.002: tag = str(w)
		if tag == "": continue
		var arr: Array = n.mesh.surface_get_arrays(0)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		# 前向（-Z）区域的平均法线
		var acc := Vector3.ZERO; var cnt := 0
		for i in vs.size():
			if vs[i].z < -0.02:
				acc += ns[i]; cnt += 1
		print("%s  front-normals avg=%s  count=%d  mat=%s" % [tag, acc / maxf(cnt,1), cnt, str(n.material_override)])
	quit()
