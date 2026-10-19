extends Node3D

const GROUPS := ["头", "躯干", "左臂", "右臂", "左手", "右手", "左腿", "右腿", "足"]

func _group_of(bone: String) -> int:
	var b := bone.to_lower()
	var right := b.ends_with("_r") or b.contains("_r_")
	if b.contains("head") or b.contains("eye") or b.contains("jaw"):
		return 0
	if b.contains("neck") or b.contains("spine") or b.contains("pelvis") or b.contains("clavicle"):
		return 1
	if b.contains("hand") or b.contains("thumb") or b.contains("index") or b.contains("middle") or b.contains("pinky") or b.contains("ring"):
		return 5 if right else 4
	if b.contains("upperarm") or b.contains("lowerarm") or b.contains("forearm") or b.contains("arm"):
		return 3 if right else 2
	if b.contains("thigh") or b.contains("calf") or b.contains("shin") or b.contains("leg") or b.contains("knee"):
		return 7 if right else 6
	if b.contains("foot") or b.contains("ball") or b.contains("toe"):
		return 8
	return 1

func _ready() -> void:
	var path := "res://assets/cc0/character.glb"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--glb="): path = a.split("=")[1]
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(path, st) != OK:
		print("load fail"); get_tree().quit(); return
	var root: Node3D = doc.generate_scene(st)
	add_child(root)
	root.visible = false
	var skel: Skeleton3D = null
	for n in root.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	var mi: MeshInstance3D = null
	var best_v := -1
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var m := n as MeshInstance3D
		if m.mesh == null or m.mesh.get_surface_count() == 0:
			continue
		var am2 := m.mesh as ArrayMesh
		var a2: Array = am2.surface_get_arrays(0)
		var vc: int = (a2[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		if vc > best_v:
			best_v = vc
			mi = m
	print("pick ", mi.name if mi else "none", " verts=", best_v)
	if mi == null or skel == null:
		print("no skinned mesh"); get_tree().quit(); return
	var mesh: ArrayMesh = mi.mesh as ArrayMesh
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	print("verts=", verts.size(), " tris=", idx.size() / 3, " groups=", GROUPS.size())
	for b in range(skel.get_bone_count()):
		print("BONE ", b, " ", skel.get_bone_name(b))
	var buckets: Array = []
	for g in GROUPS:
		buckets.append({"v": PackedVector3Array(), "n": PackedVector3Array(), "i": PackedInt32Array()})
	var tri_group := PackedInt32Array()
	for t in range(idx.size() / 3):
		var acc := [0, 0, 0, 0, 0, 0, 0, 0, 0]
		for k in range(3):
			var vi: int = idx[t * 3 + k]
			var best := 0
			var bw := 0.0
			for j in range(4):
				var w: float = weights[vi * 4 + j]
				if w > bw:
					bw = w
					best = joints[vi * 4 + j]
			var bname := skel.get_bone_name(best)
			acc[_group_of(bname)] += 1
		var gsel := 1
		var bestn := -1
		for g in range(9):
			if acc[g] > bestn:
				bestn = acc[g]
				gsel = g
		tri_group.append(gsel)
		var bkt: Dictionary = buckets[gsel]
		var vv: PackedVector3Array = bkt["v"]
		var nn: PackedVector3Array = bkt["n"]
		var ii: PackedInt32Array = bkt["i"]
		for k in range(3):
			var vi2: int = idx[t * 3 + k]
			ii.append(vv.size())
			vv.append(verts[vi2])
			nn.append(norms[vi2])
		bkt["v"] = vv; bkt["n"] = nn; bkt["i"] = ii
	var only := -1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="): only = int(a.split("=")[1])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.62, 0.58)
	mat.roughness = 0.9
	for g in range(9):
		if only >= 0 and g != only:
			continue
		var bkt: Dictionary = buckets[g]
		var vv: PackedVector3Array = bkt["v"]
		if vv.is_empty(): continue
		var lo := Vector3(1e9, 1e9, 1e9)
		var hi := Vector3(-1e9, -1e9, -1e9)
		for v in vv:
			lo = lo.min(v); hi = hi.max(v)
		var ctr := (lo + hi) * 0.5
		print(GROUPS[g], " tris=", (bkt["i"] as PackedInt32Array).size() / 3, " aabb=", hi - lo)
		for k in range(vv.size()):
			vv[k] = vv[k] - ctr
		var am := ArrayMesh.new()
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = vv
		arr[Mesh.ARRAY_NORMAL] = bkt["n"]
		arr[Mesh.ARRAY_INDEX] = bkt["i"]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var node := MeshInstance3D.new()
		node.mesh = am
		node.material_override = mat
		var dim: Vector3 = hi - lo
		var mx: float = maxf(maxf(dim.x, dim.y), maxf(dim.z, 0.001))
		node.scale = Vector3.ONE * (0.78 / mx)
		var gx := 0.0
		var gy := 0.0
		if only < 0:
			gx = float(g % 3) - 1.0
			gy = 1.0 - float(g / 3)
		node.position = Vector3(gx * 1.45, gy * 1.45, 0)
		add_child(node)
		var lb := Label3D.new()
		lb.text = GROUPS[g]
		lb.font_size = 48
		lb.pixel_size = 0.0016
		lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lb.position = node.position + Vector3(0, -0.58, 0)
		lb.modulate = Color(0.1, 0.12, 0.14)
		add_child(lb)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.93, 0.91, 0.87)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.76, 0.80)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(38, 148, -12)
	key.light_energy = 1.6
	add_child(key)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.0, -6.4)
	cam.fov = 34.0
	add_child(cam)
	cam.look_at_from_position(cam.position, Vector3(0, 0.0, 0), Vector3.UP)
	for i in range(8): await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://out/parts.png")
	print("SHOT parts")
	get_tree().quit()
