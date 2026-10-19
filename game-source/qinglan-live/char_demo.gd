extends Node3D
# 角色实机演示：游戏自己渲染（Godot 引擎），鼠标转视角 / WASD 走 / J 攻击

const CHAR := preload("res://char.gd")
var ch: Node3D
var cam: Camera3D
var yaw := 3.62
var pitch := 0.22
var dist := 4.3
var dragging := false
var hud: Label
var want_fly := false
var move := Vector3.ZERO
var t_total := 0.0
var shot_mode := false

func _ready() -> void:
	shot_mode = "--shot" in OS.get_cmdline_user_args()
	_make_env()
	_make_ground()
	ch = CHAR.new()
	ch.position = Vector3.ZERO
	add_child(ch)
	_make_camera()
	_make_hud()
	if shot_mode:
		ch.set_state("行走")

func _make_env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.10, 0.16, 0.28)
	sm.sky_horizon_color = Color(0.55, 0.50, 0.48)
	sm.ground_bottom_color = Color(0.06, 0.07, 0.09)
	sm.ground_horizon_color = Color(0.30, 0.28, 0.26)
	sm.sun_angle_max = 8.0
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.32
	env.glow_bloom = 0.12
	env.fog_enabled = true
	env.fog_light_color = Color(0.55, 0.50, 0.52)
	env.fog_density = 0.0022
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 128, 0)
	sun.light_energy = 1.55
	sun.light_color = Color(1.0, 0.88, 0.72)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 30.0
	add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-14, -40, 0)
	rim.light_energy = 0.55
	rim.light_color = Color(0.55, 0.75, 1.0)
	add_child(rim)

func _make_ground() -> void:
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	plane.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.13, 0.12, 0.13)
	m.roughness = 0.92
	plane.material_override = m
	add_child(plane)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(Color(1, 1, 1, 1))
	for i in range(-20, 21):
		var p := float(i)
		im.surface_add_vertex(Vector3(p, 0.01, -20))
		im.surface_add_vertex(Vector3(p, 0.01, 20))
		im.surface_add_vertex(Vector3(-20, 0.01, p))
		im.surface_add_vertex(Vector3(20, 0.01, p))
	im.surface_end()
	var lines := MeshInstance3D.new()
	lines.mesh = im
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0.30, 0.34, 0.40, 1)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.vertex_color_use_as_albedo = true
	lines.material_override = lm
	add_child(lines)

func _make_camera() -> void:
	cam = Camera3D.new()
	cam.fov = 42.0
	add_child(cam)
	cam.current = true
	_update_cam()

func _make_hud() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	hud = Label.new()
	hud.position = Vector2(24, 20)
	hud.add_theme_font_size_override("font_size", 20)
	hud.add_theme_color_override("font_color", Color(0.92, 0.90, 0.82))
	cl.add_child(hud)

func _update_cam() -> void:
	var focus := Vector3(0, 1.02, 0)
	var off := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.position = focus + off
	cam.look_at(focus, Vector3.UP)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			dist = maxf(1.4, dist - 0.3)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			dist = minf(12.0, dist + 0.3)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			dragging = e.pressed
		_update_cam()
	elif e is InputEventMouseMotion and dragging:
		yaw -= e.relative.x * 0.008
		pitch = clampf(pitch + e.relative.y * 0.006, 0.05, 1.5)
		_update_cam()

func _input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed or e.echo:
		return
	match e.keycode:
		KEY_1: ch.set_state("待机")
		KEY_2: ch.set_state("行走")
		KEY_3: ch.set_state("奔跑")
		KEY_4: ch.set_state("御剑")
		KEY_J, KEY_SPACE: ch.set_state("攻击")
		KEY_ESCAPE: get_tree().quit()

func _process(dt: float) -> void:
	t_total += dt
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): dir.z -= 1
	if Input.is_key_pressed(KEY_S): dir.z += 1
	if Input.is_key_pressed(KEY_A): dir.x -= 1
	if Input.is_key_pressed(KEY_D): dir.x += 1
	if dir.length() > 0.0 and ch.state != "攻击":
		dir = dir.normalized()
		move += dir * dt * 2.5
		move.x = clampf(move.x, -8.0, 8.0)
		move.z = clampf(move.z, -8.0, 8.0)
		ch.position = move
		ch.rotation.y = atan2(dir.x, dir.z) + PI
		if ch.state != "行走":
			ch.set_state("行走")
	elif ch.state == "行走":
		ch.set_state("待机")
	if shot_mode:
		ch.position.z = -0.6 + sin(t_total * 0.7) * 0.9
		ch.rotation.y = -0.05 + sin(t_total * 0.5) * 0.18
	if hud:
		hud.text = "状态 %s   位置 %.1f, %.1f   FPS %d" % [ch.state, ch.position.x, ch.position.z, Engine.get_frames_per_second()]
	if shot_mode and t_total > 2.6:
		await Shot.grab(self, "res://out/demo_ingame.png")
		get_tree().quit()
