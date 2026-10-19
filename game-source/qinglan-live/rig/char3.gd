extends RefCounted
# 修仙者 v3：程序化多边形 + 贴图脸 + 分层道袍 + 束发
# 坐标：脚底 y=0，面朝 -Z。全身约 1.72m

const SKIN   := Color("f3d6c1")
const SKIN_S := Color("e2b79f")
const HAIR   := Color("16161f")
const HAIR_H := Color("2f3044")
const ROBE   := Color("1d6f7a")
const ROBE_D := Color("155663")
const ROBE_L := Color("2a8d99")
const WHITE  := Color("f6f8f6")
const GOLD   := Color("e8c46e")
const GOLDD  := Color("b8934a")
const RED    := Color("a83c46")
const JADE   := Color("4fd6b4")
const BOOT   := Color("2b303c")

var mat_cache := {}
const CEL := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 shade_tint : source_color = vec4(0.46, 0.54, 0.72, 1.0);
uniform float bands = 3.0;
void fragment(){ ALBEDO = albedo.rgb; ROUGHNESS = 0.94; }
void light(){
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	float q = clamp(floor(ndl * bands + 0.5) / bands, 0.0, 1.0);
	vec3 lit = LIGHT_COLOR * ATTENUATION * q;
	vec3 sh = shade_tint.rgb * 0.55 * (1.0 - q);
	DIFFUSE_LIGHT += (lit + sh) / PI;
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	DIFFUSE_LIGHT += LIGHT_COLOR * f * 0.030;
}
"""

const CEL_TEX := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D tex : source_color;
uniform vec4 shade_tint : source_color = vec4(0.46, 0.54, 0.72, 1.0);
uniform float bands = 3.0;
void fragment(){ ALBEDO = texture(tex, UV).rgb; ROUGHNESS = 0.94; }
void light(){
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	float q = clamp(floor(ndl * bands + 0.5) / bands, 0.0, 1.0);
	vec3 lit = LIGHT_COLOR * ATTENUATION * q;
	vec3 sh = shade_tint.rgb * 0.55 * (1.0 - q);
	DIFFUSE_LIGHT += (lit + sh) / PI;
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	DIFFUSE_LIGHT += LIGHT_COLOR * f * 0.030;
}
"""


const OUTLINE := """
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
uniform float width = 0.0026;
uniform vec4 ink : source_color = vec4(0.055, 0.05, 0.075, 1.0);
void vertex(){ VERTEX += NORMAL * width; }
void fragment(){ ALBEDO = ink.rgb; }
"""

var _outline_mat: ShaderMaterial

func outline_mat() -> ShaderMaterial:
	if _outline_mat == null:
		var sh := Shader.new()
		sh.code = OUTLINE
		_outline_mat = ShaderMaterial.new()
		_outline_mat.shader = sh
	return _outline_mat

func mat(c: Color) -> ShaderMaterial:
	var k := c.to_html()
	if mat_cache.has(k): return mat_cache[k]
	var sh := Shader.new()
	sh.code = CEL
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("albedo", c)
	m.next_pass = outline_mat()
	mat_cache[k] = m
	return m

# 绕向修正：让三角形法线与顶点法线同向（Godot 前面是顺时针）
func orient(m: ArrayMesh) -> ArrayMesh:
	var arr: Array = m.surface_get_arrays(0)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	if idx.is_empty(): return m
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var fixed := idx.duplicate()
	var flips := 0
	var t := 0
	while t + 2 < idx.size():
		var a := idx[t]; var b := idx[t + 1]; var c := idx[t + 2]
		var gn := (vs[b] - vs[a]).cross(vs[c] - vs[a])
		var vn := ns[a] + ns[b] + ns[c]
		if gn.dot(vn) > 0.0:  # 与外法线同向 -> 需反向（Godot 前面为顺时针）
			fixed[t + 1] = c; fixed[t + 2] = b; flips += 1
		t += 3
	if flips == 0: return m
	arr[Mesh.ARRAY_INDEX] = fixed
	var m2 := ArrayMesh.new()
	m2.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m2

func add(parent: Node3D, m: Mesh, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if m is ArrayMesh: mi.mesh = orient(m)
	else: mi.mesh = m
	mi.material_override = mat(c)
	parent.add_child(mi)
	return mi

# ── 放样：sections = [{y, rx, rz, cx, cz}] ────────────────────
func loft(sections: Array, seg := 32, a0 := -PI, a1 := PI) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var closed := absf((a1 - a0) - TAU) < 0.001
	var vc := seg + 1 if closed else seg + 1
	var n := sections.size()
	for k in n:
		var s: Dictionary = sections[k]
		var rx: float = s.get("rx", 0.1)
		var rz: float = s.get("rz", rx)
		var cx: float = s.get("cx", 0.0)
		var cz: float = s.get("cz", 0.0)
		var yv: float = s.get("y", 0.0)
		for i in vc:
			var a: float = a0 + (a1 - a0) * float(i) / float(seg)
			st.set_normal(Vector3(cos(a) / maxf(rx, 1e-4), 0.0, sin(a) / maxf(rz, 1e-4)).normalized())
			st.add_vertex(Vector3(cos(a) * rx + cx, yv, sin(a) * rz + cz))
	for k in n - 1:
		for i in seg:
			var b0 := k * vc
			var b1 := (k + 1) * vc
			st.add_index(b0 + i); st.add_index(b1 + i); st.add_index(b1 + i + 1)
			st.add_index(b0 + i); st.add_index(b1 + i + 1); st.add_index(b0 + i + 1)
	return st.commit()

# ── 锥形管（发丝/四肢/袖） ──────────────────────────────────
func tube(path: PackedVector3Array, radii: PackedFloat32Array, sides := 12, squash := 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := path.size()
	var prev := Vector3.ZERO
	for i in n:
		var p: Vector3 = path[i]
		var t: Vector3 = path[mini(i + 1, n - 1)] - path[maxi(i - 1, 0)]
		if t.length() < 1e-6: t = Vector3(0, -1, 0)
		t = t.normalized()
		var up := Vector3(0, 0, 1) if absf(t.z) < 0.9 else Vector3(1, 0, 0)
		var side := t.cross(up).normalized()
		var up2 := side.cross(t).normalized()
		if i > 0 and side.dot(prev) < 0.0: side = -side
		prev = side
		for j in sides:
			var a := TAU * float(j) / float(sides)
			var dir := (side * cos(a) + up2 * sin(a) * squash)
			st.set_normal(dir.normalized())
			st.add_vertex(p + dir * radii[i])
	for i in n - 1:
		for j in sides:
			var j2 := (j + 1) % sides
			var b0 := i * sides
			var b1 := (i + 1) * sides
			st.add_index(b0 + j); st.add_index(b1 + j); st.add_index(b1 + j2)
			st.add_index(b0 + j); st.add_index(b1 + j2); st.add_index(b0 + j2)
	return st.commit()

func ellipsoid(c: Vector3, r: Vector3, seg := 20, rings := 10) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rings + 1:
		var th := PI * float(i) / float(rings)
		for j in seg:
			var ph := TAU * float(j) / float(seg)
			var d := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
			st.set_normal(d)
			st.add_vertex(c + Vector3(d.x * r.x, d.y * r.y, d.z * r.z))
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			var b0 := i * seg
			var b1 := (i + 1) * seg
			st.add_index(b0 + j); st.add_index(b1 + j); st.add_index(b1 + j2)
			st.add_index(b0 + j); st.add_index(b1 + j2); st.add_index(b0 + j2)
	return st.commit()

# ── 躯干剖面 ────────────────────────────────────────────────
var sec := [
	{"y": 0.96, "rx": 0.124, "rz": 0.092},
	{"y": 1.10, "rx": 0.142, "rz": 0.100},
	{"y": 1.22, "rx": 0.158, "rz": 0.106},
	{"y": 1.32, "rx": 0.168, "rz": 0.108},
	{"y": 1.40, "rx": 0.142, "rz": 0.094},
]
func prof(y: float, key: String) -> float:
	if y <= sec[0].y: return sec[0][key]
	for i in sec.size() - 1:
		var a: Dictionary = sec[i]
		var b: Dictionary = sec[i + 1]
		if y <= b.y:
			return lerp(a[key], b[key], (y - a.y) / (b.y - a.y))
	return sec[-1][key]
func chest_z(x: float, y: float) -> float:
	var rx := prof(y, "rx")
	var rz := prof(y, "rz")
	var k := clampf(absf(x) / maxf(rx, 1e-3), 0.0, 0.985)
	return -rz * sqrt(1.0 - k * k) - 0.003

# 在躯干正面铺带（交领/衣襟）
func band(parent: Node3D, pts: Array, width: float, c: Color, lift := 0.0) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	var half := width * 0.5
	for i in n:
		var p: Vector2 = pts[i]
		var pa: Vector2 = pts[mini(i + 1, n - 1)]
		var pb: Vector2 = pts[maxi(i - 1, 0)]
		var d2: Vector2 = pa - pb
		if d2.length() < 1e-6: d2 = Vector2(0, -1)
		d2 = d2.normalized()
		var perp := Vector2(-d2.y, d2.x)
		var a: Vector2 = p + perp * half
		var b: Vector2 = p - perp * half
		st.set_normal(Vector3(0, 0, -1))
		st.add_vertex(Vector3(a.x, a.y, chest_z(a.x, a.y) - lift))
		st.add_vertex(Vector3(b.x, b.y, chest_z(b.x, b.y) - lift))
	for i in n - 1:
		var b0 := i * 2
		var b1 := (i + 1) * 2
		st.add_index(b0); st.add_index(b1); st.add_index(b1 + 1)
		st.add_index(b0); st.add_index(b1 + 1); st.add_index(b0 + 1)
	add(parent, st.commit(), c)

# ── 组装 ───────────────────────────────────────────────────
func build(root: Node3D) -> void:
	build_legs(root)
	build_robe(root)
	build_head(root)
	build_face(root)
	build_hair(root)
	build_props(root)

func build_legs(root: Node3D) -> void:
	for s in [-1.0, 1.0]:
		add(root, tube(PackedVector3Array([Vector3(0.074 * s, 0.92, 0.0), Vector3(0.078 * s, 0.52, 0.004), Vector3(0.080 * s, 0.16, 0.0)]), PackedFloat32Array([0.062, 0.050, 0.040]), 12), SKIN_S)
		add(root, tube(PackedVector3Array([Vector3(0.080 * s, 0.19, 0.0), Vector3(0.080 * s, 0.075, 0.0), Vector3(0.080 * s, 0.045, -0.02)]), PackedFloat32Array([0.049, 0.051, 0.047]), 12), BOOT)
		add(root, ellipsoid(Vector3(0.080 * s, 0.038, -0.070), Vector3(0.048, 0.036, 0.092), 16, 8), BOOT)
		add(root, loft([{"y": 0.052, "rx": 0.050, "rz": 0.096, "cx": 0.080 * s, "cz": -0.066},
		                {"y": 0.028, "rx": 0.052, "rz": 0.100, "cx": 0.080 * s, "cz": -0.066},
		                {"y": 0.010, "rx": 0.046, "rz": 0.094, "cx": 0.080 * s, "cz": -0.066}], 16), Color("1d2129"))

func build_robe(root: Node3D) -> void:
	var ys := [1.10, 0.99, 0.86, 0.68, 0.46, 0.24, 0.115]
	var rxs := [0.126, 0.140, 0.164, 0.208, 0.256, 0.296, 0.310]
	var rzs := [0.094, 0.106, 0.126, 0.158, 0.194, 0.226, 0.238]
	var sk := []
	for i in ys.size(): sk.append({"y": ys[i], "rx": rxs[i], "rz": rzs[i]})
	add(root, loft(sk, 40), ROBE)
	# 下摆金边
	add(root, loft([{"y": 0.132, "rx": 0.314, "rz": 0.242}, {"y": 0.108, "rx": 0.310, "rz": 0.238}, {"y": 0.090, "rx": 0.292, "rz": 0.224}], 40), GOLD)
	# 躯干
	add(root, loft(sec, 36), ROBE_L)
	# 腰带
	add(root, loft([{"y": 0.945, "rx": 0.138, "rz": 0.102}, {"y": 0.985, "rx": 0.144, "rz": 0.107},
	                {"y": 1.040, "rx": 0.142, "rz": 0.105}, {"y": 1.070, "rx": 0.136, "rz": 0.100}], 36), RED)
	add(root, loft([{"y": 0.938, "rx": 0.140, "rz": 0.104}, {"y": 0.952, "rx": 0.144, "rz": 0.107}], 36), GOLD)
	add(root, loft([{"y": 1.058, "rx": 0.138, "rz": 0.102}, {"y": 1.070, "rx": 0.134, "rz": 0.099}], 36), GOLD)
	add(root, ellipsoid(Vector3(0.0, 1.004, -0.104), Vector3(0.032, 0.028, 0.020), 14, 8), GOLD)
	add(root, tube(PackedVector3Array([Vector3(-0.014, 0.985, -0.104), Vector3(-0.020, 0.90, -0.116), Vector3(-0.026, 0.79, -0.124)]), PackedFloat32Array([0.013, 0.012, 0.010]), 8, 0.42), RED)
	add(root, tube(PackedVector3Array([Vector3(0.014, 0.985, -0.104), Vector3(0.021, 0.91, -0.114), Vector3(0.028, 0.83, -0.120)]), PackedFloat32Array([0.011, 0.010, 0.008]), 8, 0.42), RED)
	add(root, ellipsoid(Vector3(0.0, 0.900, -0.118), Vector3(0.017, 0.021, 0.010), 12, 8), JADE)

	# 交领右衽：白内衫 + 金边
	var li := []
	var ri := []
	for i in 15:
		var t := float(i) / 14.0
		var y: float = lerp(1.392, 1.030, t)
		var x: float = lerp(0.086, 0.002, t * t)
		li.append(Vector2(-x, y))
		ri.append(Vector2(x, y))
	band(root, li, 0.032, WHITE, 0.0)
	band(root, ri, 0.036, WHITE, 0.0008)
	var le := []
	var re := []
	for i in 15:
		var t := float(i) / 14.0
		var y: float = lerp(1.392, 1.030, t)
		var x: float = lerp(0.086, 0.002, t * t)
		le.append(Vector2(-x - 0.024, y))
		re.append(Vector2(x + 0.027, y))
	band(root, le, 0.008, GOLD, 0.001)
	band(root, re, 0.009, GOLD, 0.0016)

	# 肩头 + 斜垂窄袖 + 金翻边 + 露手
	for s in [-1.0, 1.0]:
		add(root, ellipsoid(Vector3(0.152 * s, 1.344, -0.004), Vector3(0.064, 0.058, 0.062), 18, 10), ROBE_L)
		var p := PackedVector3Array([
			Vector3(0.156 * s, 1.330, -0.004),
			Vector3(0.196 * s, 1.212, -0.008),
			Vector3(0.222 * s, 1.086, -0.012),
			Vector3(0.234 * s, 0.978, -0.014)])
		add(root, tube(p, PackedFloat32Array([0.056, 0.054, 0.062, 0.074]), 16, 0.86), ROBE_L)
		add(root, tube(PackedVector3Array([Vector3(0.234 * s, 0.988, -0.014), Vector3(0.234 * s, 0.958, -0.014)]),
			PackedFloat32Array([0.077, 0.071]), 16, 0.86), GOLD)
		# 袖口内衬（深色）
		add(root, loft([{"y": 0.960, "rx": 0.062, "rz": 0.054, "cx": 0.234 * s, "cz": -0.014},
		                {"y": 0.944, "rx": 0.056, "rz": 0.048, "cx": 0.234 * s, "cz": -0.014}], 16), ROBE_D)
		add(root, ellipsoid(Vector3(0.234 * s, 0.918, -0.012), Vector3(0.026, 0.040, 0.022), 14, 8), SKIN)

const HEAD_PROF := [
	{"y": 1.436, "rx": 0.024, "rz": 0.030},
	{"y": 1.450, "rx": 0.040, "rz": 0.046},
	{"y": 1.470, "rx": 0.054, "rz": 0.058},
	{"y": 1.496, "rx": 0.066, "rz": 0.070},
	{"y": 1.526, "rx": 0.075, "rz": 0.081},
	{"y": 1.558, "rx": 0.080, "rz": 0.087},
	{"y": 1.590, "rx": 0.080, "rz": 0.088},
	{"y": 1.620, "rx": 0.075, "rz": 0.085},
	{"y": 1.646, "rx": 0.063, "rz": 0.073},
	{"y": 1.662, "rx": 0.041, "rz": 0.049},
	{"y": 1.669, "rx": 0.015, "rz": 0.019},
]

func head_at(y: float) -> Vector2:
	if y <= HEAD_PROF[0].y: return Vector2(HEAD_PROF[0].rx, HEAD_PROF[0].rz)
	for i in HEAD_PROF.size() - 1:
		var a: Dictionary = HEAD_PROF[i]
		var b: Dictionary = HEAD_PROF[i + 1]
		if y <= b.y:
			var t: float = (y - a.y) / (b.y - a.y)
			return Vector2(lerpf(a.rx, b.rx, t), lerpf(a.rz, b.rz, t))
	return Vector2(HEAD_PROF[-1].rx, HEAD_PROF[-1].rz)

func build_head(root: Node3D) -> void:
	var head := [
		{"y": 1.436, "rx": 0.024, "rz": 0.030},
		{"y": 1.450, "rx": 0.040, "rz": 0.046},
		{"y": 1.470, "rx": 0.054, "rz": 0.058},
		{"y": 1.496, "rx": 0.066, "rz": 0.070},
		{"y": 1.526, "rx": 0.075, "rz": 0.081},
		{"y": 1.558, "rx": 0.080, "rz": 0.087},
		{"y": 1.590, "rx": 0.080, "rz": 0.088},
		{"y": 1.620, "rx": 0.075, "rz": 0.085},
		{"y": 1.646, "rx": 0.063, "rz": 0.073},
		{"y": 1.662, "rx": 0.041, "rz": 0.049},
		{"y": 1.669, "rx": 0.015, "rz": 0.019},
	]
	add(root, loft(HEAD_PROF, 32), SKIN)
	add(root, tube(PackedVector3Array([Vector3(0, 1.355, 0.008), Vector3(0, 1.448, 0.004)]), PackedFloat32Array([0.043, 0.039]), 14), SKIN_S)
	for s in [-1.0, 1.0]:
		add(root, ellipsoid(Vector3(0.079 * s, 1.543, 0.008), Vector3(0.011, 0.025, 0.016), 12, 8), SKIN_S)

# 贴图脸：贴合前脸的曲面片
# 贴图脸：沿头颅椭球面贴合，u/v 与 art/face_tex.png 的生成比例一致
func build_face(root: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 24
	var ny := 40
	var ytop := 1.645
	var ybot := 1.440
	for j in ny + 1:
		var v := float(j) / float(ny)
		var y: float = lerpf(ytop, ybot, v)
		var hr := head_at(y)
		for i in nx + 1:
			var u := float(i) / float(nx)
			var s2 := u * 2.0 - 1.0
			var ang := s2 * 1.716          # ±98°，包到耳前
			var d := Vector3(sin(ang), 0.0, -cos(ang))
			var p := Vector3(d.x * hr.x * 1.006, y, d.z * hr.y * 1.006)
			st.set_normal(Vector3(d.x / maxf(hr.x, 1e-4), 0.0, d.z / maxf(hr.y, 1e-4)).normalized())
			st.set_uv(Vector2(u, v))
			st.add_vertex(p)
	for j in ny:
		for i in nx:
			var b0 := j * (nx + 1) + i
			var b1 := (j + 1) * (nx + 1) + i
			st.add_index(b0); st.add_index(b1); st.add_index(b1 + 1)
			st.add_index(b0); st.add_index(b1 + 1); st.add_index(b0 + 1)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = CEL_TEX
	m.shader = sh
	var tex := load("res://art/face_tex.png")
	if tex: m.set_shader_parameter("tex", tex)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)

# 头发：后脑罩 + 鬓发 + 刘海 + 发髻 + 簪
func build_hair(root: Node3D) -> void:
	# 后脑罩（比头大一圈，前脸留空）
	var cap := [
		{"y": 1.480, "rx": 0.080, "rz": 0.090, "cz": 0.006},
		{"y": 1.530, "rx": 0.086, "rz": 0.096, "cz": 0.008},
		{"y": 1.575, "rx": 0.088, "rz": 0.098, "cz": 0.008},
		{"y": 1.618, "rx": 0.084, "rz": 0.094, "cz": 0.008},
		{"y": 1.652, "rx": 0.072, "rz": 0.082, "cz": 0.008},
		{"y": 1.678, "rx": 0.048, "rz": 0.056, "cz": 0.006},
		{"y": 1.692, "rx": 0.016, "rz": 0.020, "cz": 0.004},
	]
	add(root, loft(cap, 28, -PI * 0.55, PI * 1.55), HAIR)
	# 发际线：把罩子前脸切掉的效果 —— 用一块额前发覆盖
	var fringe := [
		{"y": 1.648, "rx": 0.074, "rz": 0.083, "cz": 0.0},
		{"y": 1.660, "rx": 0.068, "rz": 0.078, "cz": 0.0},
		{"y": 1.672, "rx": 0.052, "rz": 0.062, "cz": 0.0},
	]
	add(root, loft(fringe, 32), HAIR)
	# 鬓发（两侧垂到下颌）
	for s in [-1.0, 1.0]:
		add(root, tube(PackedVector3Array([
			Vector3(0.074 * s, 1.596, -0.030),
			Vector3(0.082 * s, 1.540, -0.034),
			Vector3(0.084 * s, 1.470, -0.030),
			Vector3(0.080 * s, 1.420, -0.020)]),
			PackedFloat32Array([0.016, 0.019, 0.017, 0.011]), 8, 0.55), HAIR)
	# 刘海：几缕
	var locks := [
		[Vector3(-0.052, 1.662, -0.062), Vector3(-0.062, 1.620, -0.070), Vector3(-0.066, 1.578, -0.066)],
		[Vector3(-0.014, 1.668, -0.070), Vector3(-0.020, 1.624, -0.078), Vector3(-0.026, 1.586, -0.074)],
		[Vector3(0.026, 1.666, -0.070), Vector3(0.034, 1.626, -0.077), Vector3(0.042, 1.592, -0.072)],
		[Vector3(0.058, 1.660, -0.058), Vector3(0.068, 1.618, -0.066), Vector3(0.074, 1.580, -0.060)],
	]
	for l in locks:
		add(root, tube(PackedVector3Array(l), PackedFloat32Array([0.024, 0.019, 0.010]), 8, 0.5), HAIR)
	# 长发垂背
	add(root, loft([
		{"y": 1.646, "rx": 0.078, "rz": 0.084, "cz": 0.010},
		{"y": 1.560, "rx": 0.086, "rz": 0.092, "cz": 0.014},
		{"y": 1.470, "rx": 0.092, "rz": 0.088, "cz": 0.026},
		{"y": 1.360, "rx": 0.098, "rz": 0.072, "cz": 0.044},
		{"y": 1.240, "rx": 0.104, "rz": 0.060, "cz": 0.060},
		{"y": 1.120, "rx": 0.106, "rz": 0.050, "cz": 0.072},
		{"y": 1.040, "rx": 0.098, "rz": 0.044, "cz": 0.078},
		{"y": 1.002, "rx": 0.072, "rz": 0.036, "cz": 0.080}], 28), HAIR)
	# 发髻
	add(root, ellipsoid(Vector3(0.0, 1.726, 0.030), Vector3(0.042, 0.040, 0.040), 18, 10), HAIR)
	add(root, ellipsoid(Vector3(0.0, 1.762, 0.030), Vector3(0.028, 0.026, 0.027), 14, 8), HAIR_H)
	# 发带
	add(root, loft([{"y": 1.700, "rx": 0.030, "rz": 0.030, "cz": 0.030}, {"y": 1.712, "rx": 0.032, "rz": 0.032, "cz": 0.030}], 20), RED)
	# 玉簪
	add(root, tube(PackedVector3Array([Vector3(-0.070, 1.744, 0.024), Vector3(0.0, 1.730, 0.030), Vector3(0.068, 1.746, 0.036)]), PackedFloat32Array([0.005, 0.006, 0.005]), 8), GOLD)
	add(root, ellipsoid(Vector3(0.076, 1.748, 0.037), Vector3(0.014, 0.014, 0.012), 12, 8), JADE)

func build_props(root: Node3D) -> void:
	# 背后佩剑
	var p := PackedVector3Array([Vector3(-0.10, 1.30, 0.14), Vector3(0.06, 0.95, 0.19), Vector3(0.22, 0.58, 0.24)])
	add(root, tube(p, PackedFloat32Array([0.016, 0.015, 0.013]), 8), Color("1b2430"))
	add(root, tube(PackedVector3Array([Vector3(-0.112, 1.328, 0.135), Vector3(-0.086, 1.272, 0.146)]), PackedFloat32Array([0.014, 0.016]), 8), GOLDD)
