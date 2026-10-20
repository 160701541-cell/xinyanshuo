extends Node3D

const ROBE := Color(0.145, 0.400, 0.395)
const ROBE_D := Color(0.075, 0.235, 0.240)
const ROBE_IN := Color(0.80, 0.78, 0.72)
const GOLD := Color(0.86, 0.66, 0.26)
const SKIN := Color(0.86, 0.72, 0.56)

var rig: Node3D
var verts: PackedVector3Array
var idx: PackedInt32Array
var bones: PackedInt32Array
var weights: PackedFloat32Array
var bone_names: Array[String] = []
var waist_y := 0.0
var head_c := Vector3(0, 1.60, 0)
var head_r := Vector3(0.10, 0.12, 0.10)
var pivot: Node3D

func _ready() -> void:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	doc.append_from_file("res://assets/cc0/character_ea.glb", st)
	var root: Node3D = doc.generate_scene(st)
	add_child(root)
	root.visible = false
	pivot = Node3D.new()
	add_child(pivot)
	_grab(root)
	_build()
	if "--measure" in OS.get_cmdline_user_args():
		_measure_dump()
	_setup_world()
	_shot()

func _grab(root: Node3D) -> void:
	var sk: Skeleton3D = null
	var mi: MeshInstance3D = null
	var best := -1
	for n in root.find_children("*", "Skeleton3D", true, false):
		sk = n
	if sk:
		for b in range(sk.get_bone_count()):
			bone_names.append(sk.get_bone_name(b))
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var m := n as MeshInstance3D
		if m.mesh == null:
			continue
		var am := m.mesh as ArrayMesh
		if am == null:
			continue
		var arr: Array = am.surface_get_arrays(0)
		var vc: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		if vc > best:
			best = vc
			mi = m
			verts = arr[Mesh.ARRAY_VERTEX]
			idx = arr[Mesh.ARRAY_INDEX]
			bones = arr[Mesh.ARRAY_BONES] if arr[Mesh.ARRAY_BONES] != null else PackedInt32Array()
			weights = arr[Mesh.ARRAY_WEIGHTS] if arr[Mesh.ARRAY_WEIGHTS] != null else PackedFloat32Array()
	print("PICK ", mi.name if mi else "none", " verts=", verts.size(), " tris=", idx.size() / 3)

func _group_of_tri(t: int) -> int:
	var best := 0
	var bw := 0.0
	for k in range(3):
		var vi := idx[t * 3 + k]
		for j in range(4):
			var w := weights[vi * 4 + j]
			if w > bw:
				bw = w
				best = bones[vi * 4 + j]
	return _group_of_bone(best)

func _group_of_bone(b: int) -> int:
	var nm := bone_names[b].to_lower() if b < bone_names.size() else ""
	if nm.contains("head") or nm.contains("neck"):
		return 0
	if nm.contains("hand") or nm.contains("finger") or nm.contains("thumb") or nm.contains("index") or nm.contains("middle"):
		return 3
	if nm.contains("foot") or nm.contains("toe") or nm.contains("ankle"):
		return 4
	if nm.contains("shoulder") or nm.contains("upperarm") or nm.contains("forearm") or nm.contains("lowerarm") or nm.contains("arm"):
		return 1
	if nm.contains("thigh") or nm.contains("shin") or nm.contains("calf") or nm.contains("leg"):
		return 2
	return 5

func _shell(group: int, thick: float, col: Color, colorize := false, ymin := -1e9) -> MeshInstance3D:
	var vv := PackedVector3Array()
	var nn := PackedVector3Array()
	var cc := PackedColorArray()
	var ii := PackedInt32Array()
	var acc := {}
	var tri_ok: Array[int] = []
	for t in range(idx.size() / 3):
		if _group_of_tri(t) != group:
			continue
		var skip := false
		var nrm := Vector3.ZERO
		var p0 := verts[idx[t * 3]]
		var p1 := verts[idx[t * 3 + 1]]
		var p2 := verts[idx[t * 3 + 2]]
		nrm = (p1 - p0).cross(p2 - p0).normalized()
		for k in range(3):
			if verts[idx[t * 3 + k]].y < ymin:
				skip = true
		if skip:
			continue
		for k in range(3):
			var vi := idx[t * 3 + k]
			var p := verts[vi]
			acc[vi] = acc.get(vi, Vector3.ZERO) + (p1 - p0).cross(p2 - p0)
		tri_ok.append(t)
	if tri_ok.is_empty():
		return null
	for t in tri_ok:
		for k in range(3):
			var vi := idx[t * 3 + k]
			var nv: Vector3 = acc[vi]
			if nv.length() < 1e-9:
				nv = Vector3.UP
			ii.append(vv.size())
			vv.append(verts[vi] + nv.normalized() * thick)
			nn.append(nv.normalized())
			cc.append(col)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(vv.size()):
		st.set_normal(nn[k])
		st.set_color(cc[k])
		st.add_vertex(vv[k])
	for k in ii:
		st.add_index(k)
	var am: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	pivot.add_child(mi)
	return mi

func _waist_ring() -> Dictionary:
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := Vector3(-1e9, -1e9, -1e9)
	for t in range(idx.size() / 3):
		var g := _group_of_tri(t)
		if g != 2:
			continue
		for k in range(3):
			var v := verts[idx[t * 3 + k]]
			lo = lo.min(v)
			hi = hi.max(v)
	var yw := lo.y + (hi.y - lo.y) * 0.78
	var bucket := PackedFloat32Array()
	bucket.resize(32)
	for i in range(32):
		bucket[i] = 0.0
	for v in verts:
		if absf(v.y - yw) > 0.045:
			continue
		var ang := atan2(v.z, v.x)
		var bi := int(fposmod(ang / TAU, 1.0) * 32.0) % 32
		var r := sqrt(v.x * v.x + v.z * v.z)
		bucket[bi] = maxf(bucket[bi], r)
	var sum := 0.0
	var cnt := 0
	for i in range(32):
		if bucket[i] > 0.02:
			sum += bucket[i]
			cnt += 1
	return {"y": yw, "r": bucket, "avg": sum / maxf(1.0, float(cnt))}

func _skirt(ring: Dictionary) -> void:
	var vv := PackedVector3Array()
	var nn := PackedVector3Array()
	var cc := PackedColorArray()
	var ii := PackedInt32Array()
	var seg := 32
	var rows := 7
	var yw: float = float(ring["y"])
	var hem := 0.40
	for row in range(rows):
		var tt := float(row) / float(rows - 1)
		var y: float = lerpf(yw - 0.01, hem, tt)
		for i in range(seg):
			var a0 := TAU * float(i) / float(seg)
			var base: float = ring["r"][i % 32]
			if base < 0.02:
				base = float(ring["avg"])
			var r: float = base * (1.0 + 0.55 * tt)
			vv.append(Vector3(cos(a0) * r, y, sin(a0) * r))
			nn.append(Vector3(cos(a0), 0.0, sin(a0)))
			var d := acos(clampf(cos(a0 - PI * 0.5), -1.0, 1.0))
			var col := ROBE_D
			if tt > 0.02:
				if d < 0.170:
					col = Color(0.035, 0.130, 0.138)
				elif d < 0.200:
					col = GOLD
			cc.append(col)
	for row in range(rows - 1):
		for i in range(seg):
			var a0 := TAU * float(i) / float(seg)
			# 两侧开衩：接近 ±x 方向的格子不生成
			var a := row * seg + i
			var b := row * seg + (i + 1) % seg
			var c := (row + 1) * seg + i
			var d2 := (row + 1) * seg + (i + 1) % seg
			ii.append_array([a, b, c, b, d2, c])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(vv.size()):
		st.set_normal(nn[k])
		st.set_color(cc[k])
		st.add_vertex(vv[k])
	for k in ii:
		st.add_index(k)
	var am: ArrayMesh = st.commit()
	if "--static" in OS.get_cmdline_user_args():
		var mi2 := MeshInstance3D.new()
		mi2.mesh = am
		var mm := StandardMaterial3D.new()
		mm.vertex_color_use_as_albedo = true
		mm.roughness = 0.95
		mm.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi2.material_override = mm
		pivot.add_child(mi2)
		return
	var sb := SoftBody3D.new()
	sb.mesh = am
	sb.total_mass = 2.2
	sb.linear_stiffness = 0.88
	sb.pressure_coefficient = 0.9
	sb.damping_coefficient = 0.06
	pivot.add_child(sb)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = mat
	sb.add_child(mi)
	for i in range(seg):
		sb.set_point_pinned(i, true)
	for sx in [-0.095, 0.095]:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.108
		cap.height = 0.95
		cs.shape = cap
		body.add_child(cs)
		body.position = Vector3(sx, 0.50, 0.0)
		add_child(body)

func _sash(ring: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = float(ring["avg"]) * 1.03
	cm.bottom_radius = float(ring["avg"]) * 1.03
	cm.height = 0.075
	cm.radial_segments = 48
	mi.mesh = cm
	mi.position = Vector3(0, float(ring["y"]) + 0.01, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.17, 0.15)
	mat.roughness = 0.85
	mi.material_override = mat
	pivot.add_child(mi)


func _loft_ell(rings: Array, seg := 40, collar := false) -> void:
	var vv := PackedVector3Array()
	var nn := PackedVector3Array()
	var cc := PackedColorArray()
	var ii := PackedInt32Array()
	var tp := _trim_params()          # R2：每帧只读一次，避免逐顶点解析 JSON
	for k in range(rings.size()):
		var r: Dictionary = rings[k]
		var slope := 0.0
		if k > 0 and k < rings.size() - 1:
			var r0: Dictionary = rings[k - 1]
			var r1: Dictionary = rings[k + 1]
			var dy := float(r1["y"]) - float(r0["y"])
			var dr := (float(r1["rx"]) + float(r1["rz"])) * 0.5 - (float(r0["rx"]) + float(r0["rz"])) * 0.5
			if absf(dy) > 1e-6:
				slope = dr / dy
		for i in range(seg):
			var a := TAU * float(i) / float(seg)
			vv.append(Vector3(cos(a) * float(r["rx"]), float(r["y"]), sin(a) * float(r["rz"])))
			nn.append(Vector3(cos(a), -slope, sin(a)).normalized())
			var base_c: Color = r["c"] if r.has("c") else Color(0.085, 0.255, 0.250)
			if collar and float(r["y"]) > 1.10:
				var d := acos(clampf(sin(a), -1.0, 1.0))   # 与 +z 的夹角
				var yv: float = float(r["y"])
				# 交领：中心角随高度外扩 → 形成 V（领口宽、胸前收）
				var ctr := 0.05 + 0.72 * clampf(yv - 1.16, 0.0, 0.28)
				if d > ctr - float(tp["w_in"]) and d < ctr + float(tp["w_out"]):
					base_c = Color(float(tp["gold_r"]), float(tp["gold_g"]), float(tp["gold_b"]))    # 金边（两条斜线）
				elif d < ctr - float(tp["w_in"]):
					base_c = Color(float(tp["inner_r"]), float(tp["inner_g"]), float(tp["inner_b"]))  # 内衫
			cc.append(base_c)
	for row in range(rings.size() - 1):
		for i in range(seg):
			var a := row * seg + i
			var b := row * seg + (i + 1) % seg
			var c := (row + 1) * seg + i
			var d := (row + 1) * seg + (i + 1) % seg
			ii.append_array([a, c, b, b, c, d])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(ii.size()):
		var vi := ii[k]
		st.set_color(cc[vi])
		st.add_vertex(vv[vi])
	st.generate_normals()
	var am: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.93
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mi.material_override = mat
	pivot.add_child(mi)

func _body_env(y0: float, half: float = 0.135, band: float = 0.012) -> Vector2:
	# 第 4 轮（R2 参数化）：按身体顶点求该高度的椭圆柱包络半轴 (rx, rz)，
	# 保证 |x|<=half 带内所有离 y0 不超过 band 的顶点都落在椭圆内。
	# 只覆盖躯干中轴带（排除肩峰/手臂），与量测仪器 MEAS BREACH 的口径一致。
	var ax := 0.0
	var az := 0.0
	for v in verts:
		if absf(v.x) > half:
			continue
		if absf(v.y - y0) > band:
			continue
		ax = maxf(ax, absf(v.x))
		az = maxf(az, absf(v.z))
	if ax <= 0.0 or az <= 0.0:
		return Vector2(-1.0, -1.0)
	var m := 1.0
	for v in verts:
		if absf(v.x) > half:
			continue
		if absf(v.y - y0) > band:
			continue
		m = maxf(m, sqrt((v.x / ax) * (v.x / ax) + (v.z / az) * (v.z / az)))
	return Vector2(ax * m, az * m)

func _robe_rings() -> Array:
	# R2 参数化：领口环带由 rig/neck_params.json 驱动（mid_y<=0 表示不插中间环）
	var R := Color(0.085, 0.255, 0.250)     # 外袍
	var D := Color(0.045, 0.150, 0.155)     # 下摆
	var np := _neck_params()
	var arr: Array = []
	if float(np["fit_enable"]) > 0.5:
		# 第 4 轮：颈–肩–领三环不再手调，改为按身体顶点椭圆柱包络数据求解
		# （fit_rings 个环 × fit_margin 余量），消除分轴手调漏掉的残留穿插
		var n: int = maxi(2, int(np["fit_rings"]))
		var mg: float = float(np["fit_margin"])
		for i in range(n):
			var t := float(i) / float(n - 1)
			var yf: float = lerpf(float(np["collar_y"]), float(np["shoulder_y"]), t)
			var e := _body_env(yf)
			if e.x <= 0.0:
				continue
			arr.append({"y": yf, "rx": e.x * mg, "rz": e.y * mg, "c": R})
	else:
		arr.append({"y": np["collar_y"], "rx": np["collar_rx"], "rz": np["collar_rz"], "c": R})       # 领口贴颈
		if float(np["mid_y"]) > 0.0:
			arr.append({"y": np["mid_y"], "rx": np["mid_rx"], "rz": np["mid_rz"], "c": R})    # 领口下沿（斜方肌）
		arr.append({"y": np["shoulder_y"], "rx": np["shoulder_rx"], "rz": np["shoulder_rz"], "c": R})
	arr.append_array([
		{"y": 1.44, "rx": 0.210, "rz": np["ring2_rz"], "c": R},   # 肩
		{"y": 1.34, "rx": 0.215, "rz": np["ring3_rz"], "c": R},
		{"y": 1.24, "rx": 0.200, "rz": np["ring4_rz"], "c": R},
		{"y": 1.16, "rx": 0.150, "rz": np["ring5_rz"], "c": R},   # 腰
		{"y": 1.10, "rx": 0.170, "rz": 0.120, "c": D},
		{"y": 0.92, "rx": 0.240, "rz": 0.165, "c": D},
		{"y": 0.72, "rx": 0.330, "rz": 0.225, "c": D},
		{"y": 0.52, "rx": 0.400, "rz": 0.280, "c": D},
		{"y": 0.40, "rx": 0.425, "rz": 0.300, "c": D},   # 摆口
	])
	return arr

func _robe(ring: Dictionary) -> void:
	var yw: float = float(ring["y"])
	var rings := _robe_rings()
	_loft_ell(rings, 96, true)


func _drop(p: Vector3, side: float) -> Vector3:
	# 把 T-pose 的手臂放到 A-pose（下垂 52°），绕肩点旋转
	var pivot := Vector3(0.10 * side, 1.42, 0.0)
	var ang := deg_to_rad(-42.0) * side
	var d: Vector3 = p - pivot
	var ca := cos(ang)
	var sa := sin(ang)
	var rx := d.x * ca - d.y * sa
	var ry := d.x * sa + d.y * ca
	return pivot + Vector3(rx, ry, d.z)

func _sleeve(side: float) -> void:
	var vv := PackedVector3Array()
	var nn := PackedVector3Array()
	var cc := PackedColorArray()
	var ii := PackedInt32Array()
	var R := Color(0.085, 0.255, 0.250)
	var seg := 20
	var prof := [[0.10, 0.100], [0.24, 0.100], [0.38, 0.100], [0.52, 0.100], [0.65, 0.100]]
	for k in range(prof.size() - 1):
		var x0: float = float(prof[k][0]) * side
		var r0: float = float(prof[k][1])
		var x1: float = float(prof[k + 1][0]) * side
		var r1: float = float(prof[k + 1][1])
		for i in range(seg):
			var a := TAU * float(i) / float(seg)
			var a2 := TAU * float(i + 1) / float(seg)
			var y0: float = 1.42 - 0.10 * float(k) / 4.0
			var y1: float = 1.42 - 0.10 * float(k + 1) / 4.0
			var p0 := _drop(Vector3(x0, y0 + cos(a) * r0, sin(a) * r0), side)
			var p1 := _drop(Vector3(x1, y1 + cos(a) * r1, sin(a) * r1), side)
			var p2 := _drop(Vector3(x0, y0 + cos(a2) * r0, sin(a2) * r0), side)
			var p3 := _drop(Vector3(x1, y1 + cos(a2) * r1, sin(a2) * r1), side)
			var n0 := Vector3(0.0, cos(a), sin(a))
			var n1 := Vector3(0.0, cos(a2), sin(a2))
			var base := vv.size()
			for v in [p0, p2, p1, p1, p2, p3]:
				vv.append(v)
			for n in [n0, n0, n0, n1, n1, n1]:
				nn.append(n)
			for q in range(6):
				cc.append(R)
			ii.append_array([base, base + 2, base + 1, base + 3, base + 5, base + 4])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(vv.size()):
		st.set_normal(nn[k])
		st.set_color(cc[k])
		st.add_vertex(vv[k])
	for k in ii:
		st.add_index(k)
	var am: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.93
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mi.material_override = mat
	pivot.add_child(mi)


func _sleeve_cap(side: float) -> void:
	var seg := 20
	var x: float = 0.65 * side
	var r: float = 0.138
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ctr := _drop(Vector3(x, 1.32, 0.0), side)
	for i in range(seg):
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var p0 := _drop(Vector3(x, 1.32 + cos(a0) * r, sin(a0) * r), side)
		var p1 := _drop(Vector3(x, 1.32 + cos(a1) * r, sin(a1) * r), side)
		st.set_color(Color(0.05, 0.06, 0.06))
		st.add_vertex(ctr)
		st.set_color(Color(0.05, 0.06, 0.06))
		st.add_vertex(p0)
		st.set_color(Color(0.05, 0.06, 0.06))
		st.add_vertex(p1)
	var am: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	pivot.add_child(mi)

func _trim() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gold := Color(0.86, 0.66, 0.26)
	var inner := Color(0.80, 0.78, 0.72)
	# 交领：两条从领口斜向下的金边 + 中间内衫
	var quads := [
		[Vector3(-0.115, 1.415, 0.158), Vector3(0.010, 1.415, 0.162), Vector3(0.055, 1.18, 0.150), Vector3(-0.020, 1.18, 0.146)],
		[Vector3(0.115, 1.415, 0.158), Vector3(-0.010, 1.415, 0.162), Vector3(-0.055, 1.18, 0.150), Vector3(0.020, 1.18, 0.146)],
	]
	for q in quads:
		var a: Vector3 = q[0]
		var b: Vector3 = q[1]
		var c: Vector3 = q[2]
		var d: Vector3 = q[3]
		var nx := (b - a).cross(c - a).normalized()
		for v in [a, b, c, a, c, d]:
			st.set_color(inner)
			st.set_normal(nx)
			st.add_vertex(v)
	var am: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.88
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	pivot.add_child(mi)


func _sash_tails(ring: Dictionary) -> void:
	var yw: float = float(ring["y"])
	for sx in [-0.048, 0.048]:
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.010
		cm.bottom_radius = 0.010
		cm.height = 0.40
		cm.radial_segments = 8
		mi.mesh = cm
		mi.position = Vector3(sx * 1.5, yw - 0.21, 0.285)
		mi.rotation_degrees = Vector3(6, 0, 4 if sx > 0 else -4)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.16, 0.14)
		mat.roughness = 0.9
		mi.material_override = mat
		pivot.add_child(mi)

func _robe_ring_at(rings: Array, y: float, key: String) -> float:
	# 在袍身环列上按高度线性插值取 rx/rz（环列按 y 递减）
	if rings.size() < 2:
		return 0.0
	for i in range(rings.size() - 1):
		var y0 := float(rings[i]["y"])
		var y1 := float(rings[i + 1]["y"])
		if y >= minf(y0, y1) and y <= maxf(y0, y1):
			var t := 0.0 if absf(y1 - y0) < 1e-6 else (y - y0) / (y1 - y0)
			return lerpf(float(rings[i][key]), float(rings[i + 1][key]), clampf(t, 0.0, 1.0))
	return 0.0


func _trim_params() -> Dictionary:
	# R2 参数化：金边宽度/颜色 + 领口金边环带，由 res://rig/trim_params.json 驱动（缺文件=基线）
	var d := {
		"w_in": 0.050, "w_out": 0.010,
		"gold_r": 0.40, "gold_g": 0.30, "gold_b": 0.11,
		"inner_r": 0.52, "inner_g": 0.50, "inner_b": 0.45,
		"band_h": 0.0, "band_margin": 0.004,
	}
	var f := FileAccess.open("res://rig/trim_params.json", FileAccess.READ)
	if f != null:
		var j: Variant = JSON.parse_string(f.get_as_text())
		if typeof(j) == TYPE_DICTIONARY:
			for k in d.keys():
				if (j as Dictionary).has(k):
					d[k] = float((j as Dictionary)[k])
			print("TRIM_PARAMS loaded")
	return d


func _studio_params() -> Dictionary:
	# R3 量测台：影棚背景色，由 res://rig/studio_params.json 驱动（缺文件=基线暖灰）
	var d := {"bg_r": 0.945, "bg_g": 0.918, "bg_b": 0.870,
		"ambient_energy": 0.55, "key_energy": 1.15, "fill_energy": 0.5, "exposure": 1.0}
	var f := FileAccess.open("res://rig/studio_params.json", FileAccess.READ)
	if f != null:
		var j: Variant = JSON.parse_string(f.get_as_text())
		if typeof(j) == TYPE_DICTIONARY:
			for k in d.keys():
				if (j as Dictionary).has(k):
					d[k] = float((j as Dictionary)[k])
			print("STUDIO_PARAMS loaded")
	return d


func _collar_trim() -> void:
	# R2 本轮唯一变量族：领口金边环带（贴着领口外表面、留 band_margin 余量）
	# 第 4 轮起半径来源统一：金边跟随 **实际袍环** `_robe_rings()`，不再读 legacy 的
	# collar_rx/mid_rx —— 否则环带一改成数据求解，金边就会落进袍面里而消失（实测 gold 5.45%→0.46%）
	var tp := _trim_params()
	var h := float(tp["band_h"])
	if h <= 0.0:
		return
	var rr := _robe_rings()
	var cy: float = float(rr[0]["y"])
	var m := float(tp["band_margin"])
	var gold := Color(float(tp["gold_r"]), float(tp["gold_g"]), float(tp["gold_b"]))
	var rings: Array = []
	for i in range(2):
		var y: float = cy - h * float(i)
		var rx := _robe_ring_at(rr, y, "rx")
		var rz := _robe_ring_at(rr, y, "rz")
		if rx <= 0.0 or rz <= 0.0:
			continue
		rings.append({"y": y, "rx": rx + m, "rz": rz + m, "c": gold})
	_loft_ell(rings, 48, false)


func _build() -> void:
	var ring := _waist_ring()
	waist_y = float(ring["y"])
	# 内衫壳去掉：白片会从袍身缺口里露出来，改由交领刷色表现
	_shell(2, 0.008, Color(0.16, 0.17, 0.18))
	_robe(ring)
	_collar_trim()
	_sleeve(-1.0)
	_sleeve(1.0)
	_sleeve_cap(-1.0)
	_sleeve_cap(1.0)
	_sash(ring)
	_sash_tails(ring)
	_shell(0, 0.0, SKIN)
	_head_bounds()
	_head_shader()
	_hair()
	_hair_back()
	_boots()
	_decals()


func _hair() -> void:
	# 发帽：以头顶为球心，按纬度切片；背面额外下垂到颈后
	var hc := head_c
	var rx: float = head_r.x * 1.06
	var ry: float = head_r.y * 1.06
	var rz: float = head_r.z * 1.06
	var hair := Color(0.055, 0.050, 0.052)
	var rings: Array = []
	for i in range(9):
		var t: float = -0.10 + 1.10 * float(i) / 8.0
		var k: float = sqrt(maxf(0.0, 1.0 - t * t))
		rings.append({"y": hc.y + t * ry, "rx": rx * k, "rz": rz * k, "c": hair})
	_loft_ell(rings, 48, false)
	# 后脑垂发
	var back: Array = []
	for i in range(6):
		var t: float = -0.95 + 0.85 * float(i) / 5.0
		var k: float = sqrt(maxf(0.0, 1.0 - t * t))
		back.append({"y": hc.y + t * ry, "rx": rx * k * 0.98, "rz": rz * k * 0.98, "c": hair})
	# 发髻
	var knot := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = head_r.x * 0.30
	sm.height = head_r.y * 0.55
	knot.mesh = sm
	knot.position = hc + Vector3(0, ry * 0.92, -rz * 0.10)
	var km := StandardMaterial3D.new()
	km.albedo_color = hair
	km.roughness = 0.55
	knot.material_override = km
	pivot.add_child(knot)


func _hair_back() -> void:
	# 后脑半圈发片：只取 z>0 的半个圆周，向下垂到颈后
	var hc := head_c
	var rx: float = head_r.x * 1.06
	var ry: float = head_r.y * 1.06
	var rz: float = head_r.z * 1.06
	var hair := Color(0.055, 0.050, 0.052)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := 7
	var seg := 24
	var pts: Array = []
	for i in range(rows):
		var t: float = -0.78 + 0.72 * float(i) / float(rows - 1)
		var k: float = sqrt(maxf(0.04, 1.0 - t * t))
		var row: Array = []
		for j in range(seg + 1):
			var a: float = PI + PI * float(j) / float(seg)   # 从 -x 经 -z 转到 +x（后脑半圈；模型正面是 +Z）
			row.append(Vector3(hc.x + cos(a) * rx * k, hc.y + t * ry, hc.z + sin(a) * rz * k))
		pts.append(row)
	for i in range(rows - 1):
		for j in range(seg):
			var p0: Vector3 = pts[i][j]
			var p1: Vector3 = pts[i + 1][j]
			var p2: Vector3 = pts[i][j + 1]
			var p3: Vector3 = pts[i + 1][j + 1]
			for v in [p0, p2, p1, p1, p2, p3]:
				st.set_color(hair)
				st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.55
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	pivot.add_child(mi)

func _boots() -> void:
	for sx in [-0.095, 0.095]:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.115, 0.135, 0.245)
		b.mesh = bm
		b.position = Vector3(sx, 0.068, -0.035)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.085, 0.085, 0.095)
		m.roughness = 0.75
		b.material_override = m
		pivot.add_child(b)

func _head_bounds() -> void:
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := Vector3(-1e9, -1e9, -1e9)
	for v in verts:
		if v.y > 1.55 and absf(v.x) < 0.13 and absf(v.z) < 0.16:
			lo = lo.min(v)
			hi = hi.max(v)
	head_c = (lo + hi) * 0.5
	head_r = (hi - lo) * 0.5
	print("HEAD c=", head_c, " r=", head_r)

func _head_shader() -> void:
	for c in get_children():
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			if mi.mesh and mi.mesh.surface_get_array_len(0) < 3000:
				continue
	print("head shader skipped (flat skin)")

func _decals() -> void:
	var sc: Shader = load("res://rig/face_decal.gdshader")
	var specs := [
		[0, -1.0, Vector2(0.56, 0.26), Vector2(-0.32, -0.020), 0.0],
		[0, 1.0, Vector2(0.56, 0.26), Vector2(0.32, 0.015), 0.0],
		[1, -1.0, Vector2(0.50, 0.12), Vector2(-0.31, 0.150), -0.20],
		[1, 1.0, Vector2(0.50, 0.12), Vector2(0.31, 0.185), 0.20],
		[2, 1.0, Vector2(0.36, 0.17), Vector2(0.0, -0.640), 0.0],
	]
	for sp in specs:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(head_r.x * float(sp[2].x), head_r.y * float(sp[2].y))
		q.mesh = qm
		var off: Vector2 = sp[3]
		q.position = Vector3(head_c.x + off.x * head_r.x, head_c.y + off.y * head_r.y, head_c.z + head_r.z * 1.02)
		q.rotation_degrees = Vector3(0.0, 0.0, rad_to_deg(float(sp[4])))
		var m := ShaderMaterial.new()
		m.shader = sc
		m.set_shader_parameter("mode", int(sp[0]))
		m.set_shader_parameter("side", float(sp[1]))
		q.material_override = m
		pivot.add_child(q)

func _neck_params() -> Dictionary:
	# R2 参数化：颈部/领口两环由 rig/neck_params.json 驱动（缺文件则用下列默认值=基线）
	var d := {
		"collar_y": 1.52, "collar_rx": 0.075, "collar_rz": 0.072,
		"shoulder_y": 1.47, "shoulder_rx": 0.130, "shoulder_rz": 0.100,
		"ring2_rz": 0.130, "ring3_rz": 0.132, "ring4_rz": 0.125, "ring5_rz": 0.110,
		"mid_y": 0.0, "mid_rx": 0.0, "mid_rz": 0.0,
		"fit_enable": 0.0, "fit_rings": 5.0, "fit_margin": 1.08,
	}
	var f := FileAccess.open("res://rig/neck_params.json", FileAccess.READ)
	if f != null:
		var j: Variant = JSON.parse_string(f.get_as_text())
		if typeof(j) == TYPE_DICTIONARY:
			for k in d.keys():
				if (j as Dictionary).has(k):
					d[k] = float((j as Dictionary)[k])
			print("NECK_PARAMS loaded")
	return d

func _dom_bone(t: int) -> int:
	var best := 0
	var bw := 0.0
	for k in range(3):
		var vi := idx[t * 3 + k]
		for j in range(4):
			var w := weights[vi * 4 + j]
			if w > bw:
				bw = w
				best = bones[vi * 4 + j]
	return best

func _measure_dump() -> void:
	# R4 量测探针：只读数、不改几何
	var grp := {}
	for t in range(idx.size() / 3):
		var g := _group_of_tri(t)
		for k in range(3):
			var v := verts[idx[t * 3 + k]]
			var rec: Array = grp.get(g, [Vector3(1e9, 1e9, 1e9), Vector3(-1e9, -1e9, -1e9)])
			rec[0] = (rec[0] as Vector3).min(v)
			rec[1] = (rec[1] as Vector3).max(v)
			grp[g] = rec
	var gm := ["head", "arm", "leg", "hand", "foot", "other"]
	for g in range(6):
		if not grp.has(g):
			continue
		var lo: Vector3 = grp[g][0]
		var hi: Vector3 = grp[g][1]
		print("MEAS PART %d %s y=%.3f..%.3f size=(%.3f,%.3f,%.3f)" % [g, gm[g], lo.y, hi.y, hi.x - lo.x, hi.y - lo.y, hi.z - lo.z])
	for yb in [1.48, 1.50, 1.52, 1.54, 1.56, 1.58]:
		var rn := 0.0
		var rh := 0.0
		for t in range(idx.size() / 3):
			var dom := _dom_bone(t)
			var nm := bone_names[dom].to_lower() if dom < bone_names.size() else ""
			for k in range(3):
				var v := verts[idx[t * 3 + k]]
				if absf(v.y - float(yb)) > 0.012:
					continue
				var rr := sqrt(v.x * v.x + v.z * v.z)
				if nm.contains("neck"):
					rn = maxf(rn, rr)
				elif nm.contains("head"):
					rh = maxf(rh, rr)
		print("MEAS NECK y=%.2f r_neckbone=%.4f r_headbone=%.4f" % [float(yb), rn, rh])
	for yb in [1.16, 1.24, 1.30, 1.34, 1.38, 1.40, 1.44, 1.48, 1.50, 1.52, 1.54, 1.56, 1.58, 1.60]:
		var rb := 0.0
		var rbx := 0.0
		var rbz := 0.0
		for v in verts:
			if absf(v.x) > 0.135:
				continue
			if absf(v.y - float(yb)) > 0.012:
				continue
			rb = maxf(rb, sqrt(v.x * v.x + v.z * v.z))
			rbx = maxf(rbx, absf(v.x))
			rbz = maxf(rbz, absf(v.z))
		print("MEAS BODY y=%.2f r_centerline=%.4f rx=%.4f rz=%.4f" % [float(yb), rb, rbx, rbz])
	# R4 几何量测：领口带由 neck_params 的 shoulder_y..collar_y 定义（与环数无关）
	var rr2 := _robe_rings()
	var npb := _neck_params()
	var y_lo: float = minf(float(npb["shoulder_y"]), float(npb["collar_y"]))
	var y_hi: float = maxf(float(npb["shoulder_y"]), float(npb["collar_y"]))
	var min_clr := 1e9
	var clr_at := ""
	var ncs: int = 7
	for k in range(ncs):
		var yc: float = lerpf(y_hi, y_lo, float(k) / float(ncs - 1))
		var rxc := _robe_ring_at(rr2, yc, "rx")
		var rzc := _robe_ring_at(rr2, yc, "rz")
		var bx := 0.0
		var bz := 0.0
		for v in verts:
			if absf(v.x) > 0.135:
				continue
			if absf(v.y - yc) > 0.008:
				continue
			bx = maxf(bx, absf(v.x))
			bz = maxf(bz, absf(v.z))
		var cx := rxc - bx
		var cz := rzc - bz
		if minf(cx, cz) < min_clr:
			min_clr = minf(cx, cz)
			clr_at = "y=%.3f" % yc
		print("MEAS COLLAR y=%.3f robe_rx=%.3f robe_rz=%.3f body_rx=%.3f body_rz=%.3f clr_x=%+.4f clr_z=%+.4f" % [yc, rxc, rzc, bx, bz, cx, cz])
	print("MEAS COLLAR_MIN clearance=%.4f at %s" % [min_clr, clr_at])
	# R4 工具层换层（第 3 轮）：颈部门槛改由几何口径判定 ——
	# 统计袍身领口带内身体顶点（|x|<=0.135）穿出袍面的数量，椭圆柱判据 (x/rx)^2+(z/rz)^2 > 1
	var breach := 0
	var worst := 0.0
	var worst_at := Vector3.ZERO
	for v in verts:
		if absf(v.x) > 0.135:
			continue
		if v.y < y_lo - 0.02 or v.y > y_hi + 0.02:
			continue
		var rx_b := _robe_ring_at(rr2, v.y, "rx")
		var rz_b := _robe_ring_at(rr2, v.y, "rz")
		if rx_b <= 0.0 or rz_b <= 0.0:
			continue
		var q := (v.x / rx_b) * (v.x / rx_b) + (v.z / rz_b) * (v.z / rz_b)
		if q > worst:
			worst = q
			worst_at = v
		if q > 1.0:
			breach += 1
	print("MEAS BREACH verts=%d band=%.3f..%.3f worst_q=%.4f at(%.3f,%.3f,%.3f)" % [breach, y_lo, y_hi, worst, worst_at.x, worst_at.y, worst_at.z])
	var tot := idx.size() / 3
	for c in pivot.get_children():
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			if mi.mesh != null:
				tot += mi.mesh.get_faces().size() / 3
	print("MEAS TRIS total=%d base=%d" % [tot, idx.size() / 3])
	print("MEAS HEAD c=(%.3f,%.3f,%.3f) r=(%.4f,%.4f,%.4f)" % [head_c.x, head_c.y, head_c.z, head_r.x, head_r.y, head_r.z])
	var np := _neck_params()
	print("MEAS NECKCFG collar_y=%.3f collar_rx=%.4f collar_rz=%.4f shoulder_y=%.3f shoulder_rx=%.4f shoulder_rz=%.4f" % [float(np["collar_y"]), float(np["collar_rx"]), float(np["collar_rz"]), float(np["shoulder_y"]), float(np["shoulder_rx"]), float(np["shoulder_rz"])])

func _setup_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	var bp := _studio_params()
	env.background_color = Color(float(bp["bg_r"]), float(bp["bg_g"]), float(bp["bg_b"]))
	env.tonemap_exposure = float(bp["exposure"])
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.80, 0.78, 0.74)
	env.ambient_light_energy = float(bp["ambient_energy"])
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, 148, -12)
	key.light_energy = float(bp["key_energy"])
	key.light_color = Color(1.0, 0.96, 0.90)
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-8, 320, 0)
	fill.light_energy = float(bp["fill_energy"])
	fill.light_color = Color(0.68, 0.80, 0.90)
	add_child(fill)

func _shot() -> void:
	var yaw := 0.0
	var head := "--head" in OS.get_cmdline_user_args()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--yaw="):
			yaw = float(a.split("=")[1])
	pivot.rotation_degrees.y = 180.0 + yaw
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.62, -0.95) if head else Vector3(0, 1.02, -4.35)
	cam.fov = 16.0 if head else 24.0
	add_child(cam)
	cam.look_at_from_position(cam.position, Vector3(0, 1.63, 0) if head else Vector3(0, 0.95, 0), Vector3.UP)
	cam.current = true
	for f in 150:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var nm := "head%d" % int(yaw) if head else "%d" % int(yaw)
	img.save_png("res://out/cloth_%s.png" % nm)
	print("SHOT cloth_", nm)
	get_tree().quit()
