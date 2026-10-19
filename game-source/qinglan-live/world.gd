extends Node3D
# 太行式山脉 + 点地移动 + 御剑飞行（原型）

const CELL := 1.0
var cam: Camera3D
var sun: DirectionalLight3D
var player: Node3D
var hud: CanvasLayer
var target := Vector3.ZERO
var has_target := false
var flying := false
var fly_h := 0.0
var speed := 11.0
var shot_mode := false
var elapsed := 0.0
var grabbed := false

# —— 山脊参数：[x, z, 长度, 宽, 高, 朝向角] ——
const RIDGES := [
	[0.0, -260.0, 2600.0, 420.0, 760.0, 8.0],
	[1500.0, -900.0, 2000.0, 380.0, 980.0, 22.0],
	[-1800.0, -300.0, 2400.0, 460.0, 880.0, -14.0],
	[600.0, 1400.0, 1800.0, 520.0, 620.0, 30.0],
	[-900.0, 1600.0, 1600.0, 500.0, 700.0, -25.0],
]
const PEAKS := [
	[0.0, -260.0, 820.0, 300.0],
	[1500.0, -900.0, 980.0, 260.0],
	[-1800.0, -300.0, 880.0, 280.0],
	[620.0, 1420.0, 640.0, 320.0],
]

var hm: Image
var H_LO := 1017.6
var H_HI := 1775.0
const SPAN_X := 12590.0
const SPAN_Z := 14470.0

func _h(x: float, z: float) -> float:
	if hm == null:
		return 0.0
	var u := (x + SPAN_X * 0.5) / SPAN_X
	var v := (z + SPAN_Z * 0.5) / SPAN_Z
	if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
		return H_LO
	var px := int(clampf(u, 0.0, 0.999) * float(hm.get_width() - 1))
	var py := int(clampf(v, 0.0, 0.999) * float(hm.get_height() - 1))
	var base: float = H_LO + hm.get_pixel(px, py).r * (H_HI - H_LO)
	# 太行式断层：把高程按阶地量化，用 smoothstep 做陡坎（不是圆包）
	var step := 46.0
	var q: float = floor(base / step) * step
	var fr: float = (base - q) / step
	var terraced: float = q + step * smoothstep(0.58, 0.88, fr)
	# 山脊：脊状噪声，制造刀刃状山脊线
	var r1: float = 1.0 - absf(_vnoise(x * 0.0045, z * 0.0045) * 2.0 - 1.0)
	var r2: float = 1.0 - absf(_vnoise(x * 0.0125 + 7.3, z * 0.0125 - 3.1) * 2.0 - 1.0)
	var ridge: float = (r1 * 0.75 + r2 * 0.25) * 64.0
	# 高频台阶/碎石：只有近场网格才采样得到
	var r3: float = 1.0 - absf(_vnoise(x * 0.042, z * 0.042) * 2.0 - 1.0)
	var r4: float = 1.0 - absf(_vnoise(x * 0.105 + 3.7, z * 0.105 + 9.2) * 2.0 - 1.0)
	return terraced + ridge + r3 * 11.0 + r4 * 4.0

func _vh(ix: int, iz: int) -> float:
	var h := sin(float(ix) * 127.1 + float(iz) * 311.7) * 43758.5453
	return h - floor(h)

func _vnoise(x: float, z: float) -> float:
	var xi: int = int(floor(x))
	var zi: int = int(floor(z))
	var xf: float = x - floor(x)
	var zf: float = z - floor(z)
	var u: float = xf * xf * (3.0 - 2.0 * xf)
	var v: float = zf * zf * (3.0 - 2.0 * zf)
	var a: float = lerpf(_vh(xi, zi), _vh(xi + 1, zi), u)
	var b: float = lerpf(_vh(xi, zi + 1), _vh(xi + 1, zi + 1), u)
	return lerpf(a, b, v)

var near_mesh: MeshInstance3D
var near_center := Vector3(1e6, 0, 1e6)

var grass_mm: MultiMeshInstance3D
var rock_mm: MultiMeshInstance3D

func _make_detail() -> void:
	var blade := QuadMesh.new()
	blade.size = Vector2(0.34, 0.42)
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.vertex_color_use_as_albedo = true
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var gmi := MultiMesh.new()
	gmi.transform_format = MultiMesh.TRANSFORM_3D
	gmi.use_colors = true
	gmi.mesh = blade
	grass_mm = MultiMeshInstance3D.new()
	grass_mm.multimesh = gmi
	grass_mm.material_override = gm
	grass_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grass_mm)

	var rk := SphereMesh.new()
	rk.radius = 0.30
	rk.height = 0.42
	rk.radial_segments = 6
	rk.rings = 3
	rk.is_hemisphere = true
	var rmi := MultiMesh.new()
	rmi.transform_format = MultiMesh.TRANSFORM_3D
	rmi.use_colors = true
	rmi.mesh = rk
	rock_mm = MultiMeshInstance3D.new()
	rock_mm.multimesh = rmi
	rock_mm.material_override = gm
	add_child(rock_mm)
	_rebuild_detail()

func _rebuild_detail() -> void:
	if grass_mm == null or player == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	var ng := 1400
	grass_mm.multimesh.instance_count = ng
	for i in range(ng):
		var a: float = rng.randf() * TAU
		var r: float = sqrt(rng.randf()) * 55.0
		var x: float = player.position.x + cos(a) * r
		var z: float = player.position.z + sin(a) * r
		var y: float = _h(x, z)
		var sc: float = 0.55 + rng.randf() * 0.9
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc, sc, sc))
		grass_mm.multimesh.set_instance_transform(i, Transform3D(b, Vector3(x, y + 0.18 * sc, z)))
		var tint: float = 0.75 + rng.randf() * 0.5
		grass_mm.multimesh.set_instance_color(i, Color(0.16 * tint, 0.34 * tint, 0.29 * tint))
	var nr := 260
	rock_mm.multimesh.instance_count = nr
	for i in range(nr):
		var a2: float = rng.randf() * TAU
		var r2: float = 4.0 + sqrt(rng.randf()) * 50.0
		var x2: float = player.position.x + cos(a2) * r2
		var z2: float = player.position.z + sin(a2) * r2
		var y2: float = _h(x2, z2)
		var s2: float = 0.4 + rng.randf() * 1.6
		var b2 := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s2, s2 * 0.7, s2))
		rock_mm.multimesh.set_instance_transform(i, Transform3D(b2, Vector3(x2, y2 - 0.05, z2)))
		rock_mm.multimesh.set_instance_color(i, Color(0.34, 0.35, 0.40).lerp(Color(0.20, 0.24, 0.24), rng.randf()))

func _make_sky_dome() -> void:
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 3000.0
	sm.height = 6000.0
	sm.radial_segments = 32
	sm.rings = 16
	dome.mesh = sm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://rig/sky.gdshader")
	dome.material_override = mat
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dome)

func _make_near() -> void:
	near_mesh = MeshInstance3D.new()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	near_mesh.material_override = m
	add_child(near_mesh)
	_rebuild_near()

func _rebuild_near() -> void:
	if player == null:
		return
	near_center = player.position
	var N := 96
	var span := 480.0
	var half := span * 0.5
	var hs: Array = []
	for j in range(N + 1):
		var row := PackedFloat32Array()
		for i in range(N + 1):
			row.append(_h(near_center.x - half + float(i) * span / float(N),
				near_center.z - half + float(j) * span / float(N)))
		hs.append(row)
	var lo := 1e9
	var hi := -1e9
	for row in hs:
		for hh in row:
			lo = minf(lo, hh); hi = maxf(hi, hh)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sh := Color(0.165, 0.169, 0.227)
	for j in range(N):
		for i in range(N):
			var h00: float = hs[j][i]
			var h10: float = hs[j][i + 1]
			var h01: float = hs[j + 1][i]
			var x0: float = near_center.x - half + float(i) * span / float(N)
			var z0: float = near_center.z - half + float(j) * span / float(N)
			var x1: float = x0 + span / float(N)
			var z1: float = z0 + span / float(N)
			var p00 := Vector3(x0, h00 + 1.0, z0)
			var p10 := Vector3(x1, h10 + 1.0, z0)
			var p01 := Vector3(x0, h01 + 1.0, z1)
			var h11: float = hs[j + 1][i + 1]
			var p11 := Vector3(x1, h11 + 1.0, z1)
			var n := (p10 - p00).cross(p01 - p00).normalized()
			var d := clampf(1.0 - absf(n.y), 0.0, 1.0)
			var c := _band_color((h00 + h10 + h01 + h11) * 0.25, lo, hi)
			c = c.lerp(sh, clampf(d * 1.7, 0.0, 0.72))
			if d > 0.22:
				var hm2: float = (h00 + h10 + h01 + h11) * 0.25
				var band: float = sin(hm2 * 0.55) * 0.5 + 0.5
				c = c.lerp(Color(0.30, 0.30, 0.36), 0.10 + band * 0.16)
			st.set_color(c)
			for v in [p00, p10, p11, p00, p11, p01]:
				st.set_color(c)
				st.add_vertex(v)
	near_mesh.mesh = st.commit()

func _ready() -> void:
	shot_mode = "--shot" in OS.get_cmdline_user_args()
	_make_materials()
	_make_light()
	_make_env()
	_make_terrain()
	_make_vegetation()
	_make_player()
	_make_near()
	_make_sky_dome()
	_make_detail()
	_make_camera()
	var h = preload("res://hud.gd").new()
	add_child(h)
	h.setup(self)
	hud = h

var mat_solid: StandardMaterial3D

func _make_materials() -> void:
	mat_solid = StandardMaterial3D.new()
	mat_solid.roughness = 0.95

func _make_light() -> void:
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.7
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.shadow_enabled = false
	add_child(sun)

func _band_color(y: float, lo := 1017.6, hi := 1775.0) -> Color:
	var t := clampf((y - lo) / maxf(1.0, hi - lo), 0.0, 1.0)
	if t < 0.22:
		return Color(0.180, 0.290, 0.270)
	elif t < 0.42:
		return Color(0.220, 0.340, 0.330)
	elif t < 0.60:
		return Color(0.320, 0.380, 0.420)
	elif t < 0.74:
		return Color(0.420, 0.430, 0.470)
	elif t < 0.86:
		return Color(0.480, 0.500, 0.560)
	return Color(0.937, 0.914, 0.863)

func _make_env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.90, 0.90, 0.86)
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.34, 0.48, 0.70)
	sm.sky_horizon_color = Color(0.80, 0.84, 0.88)
	sm.ground_bottom_color = Color(0.30, 0.31, 0.30)
	sm.ground_horizon_color = Color(0.66, 0.70, 0.72)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.30
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_light_color = Color(0.76, 0.82, 0.90)
	env.fog_density = 0.00004
	we.environment = env
	add_child(we)

func _make_terrain() -> void:
	hm = Image.load_from_file("/root/game/height8.png")
	if hm == null:
		var tex := load("res://height8.png") as Texture2D
		if tex != null:
			hm = tex.get_image()
	if hm == null:
		push_error("height8.png 读取失败")
		return
	var n0 := 64
	var tlo := 1e9
	var thi := -1e9
	for i in range(n0 + 1):
		for j in range(n0 + 1):
			var hh := _h(-SPAN_X * 0.5 + i * SPAN_X / n0, -SPAN_Z * 0.5 + j * SPAN_Z / n0)
			tlo = minf(tlo, hh); thi = maxf(thi, hh)
	print("ELEV ", tlo, " .. ", thi)
	var light := Vector3(0.42, 0.78, -0.46).normalized()
	var groups := {}
	var n := 255
	var sx := SPAN_X / float(n)
	var sz := SPAN_Z / float(n)
	for ix in range(n):
		for iz in range(n):
			var xa := -SPAN_X * 0.5 + ix * sx
			var za := -SPAN_Z * 0.5 + iz * sz
			var xb := xa + sx
			var zb := za + sz
			var p00 := Vector3(xa, _h(xa, za), za)
			var p10 := Vector3(xb, _h(xb, za), za)
			var p11 := Vector3(xb, _h(xb, zb), zb)
			var p01 := Vector3(xa, _h(xa, zb), zb)
			var nn: Vector3 = (p01 - p00).cross(p10 - p00).normalized()
			if nn.y < 0.0:
				nn = -nn
			var mid: float = (p00.y + p01.y + p10.y + p11.y) * 0.25
			var hb := int(clampf((mid - 1000.0) / 130.0, 0.0, 5.0))
			var slope := 0
			if nn.y < 0.62:
				slope = 2
			elif nn.y < 0.86:
				slope = 1
			var d := clampf(nn.dot(light), 0.0, 1.0)
			var sb := 0
			if d > 0.75:
				sb = 2
			elif d > 0.40:
				sb = 1
			var key := hb
			if not groups.has(key):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				groups[key] = st
			var st2: SurfaceTool = groups[key]
			for tri in [[p00, p11, p01], [p00, p10, p11]]:
				for v in tri:
					st2.set_normal(nn)
					st2.add_vertex(v)
	for key in groups.keys():
		var mesh: ArrayMesh = groups[key].commit()
		if mesh == null:
			continue
		var hb := int(key)
		var slope := 0
		var sb := 2
		var c := _band_color(1000.0 + float(hb) * 130.0 + 65.0, tlo, thi)
		if slope == 1:
			c = c.lerp(Color(0.44, 0.42, 0.38), 0.45)
		elif slope == 2:
			c = c.lerp(Color(0.50, 0.47, 0.43), 0.80)
		var mul: float = [0.55, 0.78, 1.0][sb]
		var sh := Color(0.165, 0.169, 0.227)   # #2A2B3A
		var k: float = 0.55 if sb == 0 else (0.30 if sb == 1 else 0.0)
		c = Color(lerpf(c.r * mul, sh.r, k), lerpf(c.g * mul, sh.g, k), lerpf(c.b * mul, sh.b, k))
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = c
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		add_child(mi)

func _add_terrain_layer(half: float, step: float, hole: float) -> void:
	var bands := {}
	var n := int(half * 2.0 / step)
	for ix in range(n):
		for iz in range(n):
			var xa := -half + ix * step
			var za := -half + iz * step
			if hole > 0.0 and absf(xa) < hole and absf(za) < hole:
				continue
			var xb := xa + step
			var zb := za + step
			var p00 := Vector3(xa, _h(xa, za), za)
			var p10 := Vector3(xb, _h(xb, za), za)
			var p11 := Vector3(xb, _h(xb, zb), zb)
			var p01 := Vector3(xa, _h(xa, zb), zb)
			var nn: Vector3 = (p01 - p00).cross(p10 - p00).normalized()
			nn.y = absf(nn.y)
			nn = nn.normalized()
			var flip := false
			var mid: float = (p00.y + p11.y) * 0.5
			var slope := 0
			if nn.y < 0.55:
				slope = 2
			elif nn.y < 0.82:
				slope = 1
			var key := int(mid / 160.0) * 3 + slope
			if not bands.has(key):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				bands[key] = st
			var st2: SurfaceTool = bands[key]
			var quads := [[p00, p11, p01], [p00, p10, p11]]
			if flip:
				quads = [[p00, p01, p11], [p00, p11, p10]]
			for tri in quads:
				for v in tri:
					st2.set_normal(nn)
					st2.add_vertex(v)
	for key in bands.keys():
		var mesh: ArrayMesh = bands[key].commit()
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var hb := float(int(key) / 3) * 160.0 + 80.0
		var sc := int(key) % 3
		var c := _band_color(hb)
		if sc == 1:
			c = c.lerp(Color(0.42, 0.40, 0.36), 0.45)
		elif sc == 2:
			c = c.lerp(Color(0.50, 0.47, 0.43), 0.85)
		var m := mat_solid.duplicate()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = c
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		add_child(mi)

func _make_vegetation() -> void:
	print("HEIGHTMAP ", hm != null, " size ", hm.get_size() if hm else Vector2i.ZERO)
	var vg = load("res://vegetation.gd").new()
	add_child(vg)
	vg.build(self)

var avatar: Node3D

func _make_player() -> void:
	player = Node3D.new()
	add_child(player)
	avatar = load("res://char.gd").new()
	player.add_child(avatar)
	player.position = Vector3(0, _h(0, 0) + 0.1, 0)
	target = player.position

func _make_camera() -> void:
	cam = Camera3D.new()
	cam.fov = 55.0
	add_child(cam)
	cam.current = true
	_update_camera(true)

func _update_camera(instant := false) -> void:
	var back := Vector3(0, 26.0, 46.0)
	if shot_mode:
		back = Vector3(2.2, 2.3, 4.9)
	if "--aerial" in OS.get_cmdline_user_args():
		back = Vector3(0, 300, 420)
	var want := player.position + back
	if instant:
		cam.position = want
	else:
		cam.position = cam.position.lerp(want, 0.12)
	cam.look_at(player.position + Vector3(0, 10.0, -60.0), Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J and avatar:
			avatar.set_state("攻击")
			_slash()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tap(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_tap(event.position)

func _tap(pos: Vector2) -> void:
	var from := cam.project_ray_origin(pos)
	var dir := cam.project_ray_normal(pos)
	var t := 4.0
	while t < 900.0:
		var p := from + dir * t
		var hh := _h(p.x, p.z)
		if p.y <= hh:
			target = Vector3(p.x, hh + 0.1, p.z)
			has_target = true
			fly_h = 0.0 if not flying else fly_h
			return
		t += maxf(1.0, t * 0.02)

func _slash() -> void:
	var v: Node3D = load("res://rig/vfx3.gd").new()
	add_child(v)
	v.global_position = player.position + Vector3(0, 1.15, 0)
	v.rotation_degrees.y = avatar.rotation_degrees.y + 90.0
	v.build_slash(v)
	var tw := create_tween()
	tw.tween_property(v, "scale", Vector3(1.35, 1.35, 1.35), 0.35)
	tw.tween_callback(v.queue_free)

func _process(delta: float) -> void:
	elapsed += delta
	if near_mesh != null and player != null:
		if Vector2(player.position.x - near_center.x, player.position.z - near_center.z).length() > 60.0:
			_rebuild_near()
			_rebuild_detail()
	if shot_mode and not grabbed and elapsed > 3.0:
		grabbed = true
		var out := "res://out/world_aerial.png" if "--aerial" in OS.get_cmdline_user_args() else "res://out/world_ingame.png"
		await Shot.grab(self, out)
		get_tree().quit()
		return
	if has_target:
		var flat := Vector3(target.x, player.position.y, target.z)
		var to := target - player.position
		var dist := Vector2(to.x, to.z).length()
		if dist > 0.6:
			var sp := speed * (3.0 if flying else 1.0)
			if avatar and avatar.state != "攻击":
				avatar.set_state("御剑" if flying else "奔跑")
			var step := minf(dist, sp * delta)
			var dirn := Vector3(to.x, 0, to.z).normalized()
			player.position += dirn * step
			player.rotation.y = atan2(dirn.x, dirn.z)
			if flying:
				player.position.y = lerp(player.position.y, _h(player.position.x, player.position.z) + fly_h, 0.15)
			else:
				player.position.y = _h(player.position.x, player.position.z) + 0.1
		elif avatar and avatar.state != "攻击":
			avatar.set_state("待机")
	_update_camera()

func toggle_fly() -> void:
	flying = not flying
	fly_h = 18.0 if flying else 0.0
