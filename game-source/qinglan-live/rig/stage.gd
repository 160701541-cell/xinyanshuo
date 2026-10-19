extends RefCounted
# 演示场景公用舞台：环境光 + 主光 + 地面网格 + 相机

static func setup(world: Node3D, bg := Color(0.045, 0.05, 0.062), ambient := 0.5) -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.65, 0.80)
	env.ambient_light_energy = ambient
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, 150, -18)
	key.light_energy = 1.7
	key.light_color = Color(1.0, 0.96, 0.90)
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-12, 215, 20)
	fill.light_energy = 0.45
	fill.light_color = Color(0.70, 0.80, 1.0)
	world.add_child(fill)

# 地面：一块暗色平面 + 0.5m 间隔的网格线（给脚底一个参照）
static func grid_ground(world: Node3D, extent := 6.0, step := 0.5) -> void:
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(extent * 2.0, extent * 2.0)
	plane.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.10, 0.115, 0.135)
	m.roughness = 0.95
	plane.material_override = m
	world.add_child(plane)

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(Color(1, 1, 1, 1))
	var n := int(extent / step)
	for i in range(-n, n + 1):
		var p := float(i) * step
		im.surface_add_vertex(Vector3(p, 0.002, -extent))
		im.surface_add_vertex(Vector3(p, 0.002, extent))
		im.surface_add_vertex(Vector3(-extent, 0.002, p))
		im.surface_add_vertex(Vector3(extent, 0.002, p))
	im.surface_end()
	var lines := MeshInstance3D.new()
	lines.mesh = im
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0.26, 0.30, 0.36, 1.0)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.vertex_color_use_as_albedo = true
	lines.material_override = lm
	world.add_child(lines)

static func camera(world: Node3D, pos: Vector3, target: Vector3, fov := 32.0) -> Camera3D:
	var cam := Camera3D.new()
	cam.position = pos
	cam.fov = fov
	world.add_child(cam)
	cam.look_at(target, Vector3.UP)
	return cam

static func label(world: Node3D, text: String, pos: Vector3, size := 26) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.0032
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.95, 0.92, 0.86)
	world.add_child(l)
	return l
