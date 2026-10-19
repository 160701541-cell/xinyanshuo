extends Node3D

const Mat := preload("res://voxel.gd")
const Trees := preload("res://trees.gd")

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.055, 0.06, 0.07)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.60, 0.70)
	e.ambient_light_energy = 1.15
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -34, 0)
	sun.light_energy = 1.55
	sun.light_color = Color(1.0, 0.95, 0.88)
	add_child(sun)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 4.6, 18.5)
	cam.fov = 40
	add_child(cam)
	cam.look_at(Vector3(0, 2.4, 0), Vector3.UP)

	var specs := [
		{"name": "① 幼苗 · 0 年", "stage": 0, "x": -9.0},
		{"name": "② 幼树 · 1 年", "stage": 1, "x": -3.0},
		{"name": "③ 成树 · 20 年", "stage": 2, "x": 3.0},
		{"name": "④ 参天 · 百年", "stage": 3, "x": 9.0},
	]
	for sp in specs:
		var tg := Trees.new()
		tg.vb = Mat.new()
		tg.broadleaf_stage(int(sp["stage"]), Color(0.26, 0.44, 0.22))
		var sm := StandardMaterial3D.new()
		sm.vertex_color_use_as_albedo = true
		sm.roughness = 0.9
		var em := StandardMaterial3D.new()
		em.vertex_color_use_as_albedo = true
		em.emission_enabled = true
		em.emission = Color(1, 0.9, 0.6)
		em.emission_energy_multiplier = 0.8
		var meshes: Array = tg.vb.build(sm, em)
		for mi in meshes:
			add_child(mi)
			mi.position = Vector3(float(sp["x"]), 0, 0)
			mi.scale = Vector3.ONE * 0.175
		var lab := Label3D.new()
		lab.text = String(sp["name"])
		lab.font = load("res://cjk.ttc")
		lab.font_size = 48
		lab.pixel_size = 0.0075
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.no_depth_test = true
		lab.modulate = Color(0.93, 0.90, 0.84)
		add_child(lab)
		lab.position = Vector3(float(sp["x"]), -1.6, 0)
