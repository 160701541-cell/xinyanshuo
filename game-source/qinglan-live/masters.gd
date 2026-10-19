extends Node3D

var solid_mat: StandardMaterial3D
var emis_mat: StandardMaterial3D
var font: FontFile

func _ready() -> void:
	solid_mat = StandardMaterial3D.new()
	solid_mat.vertex_color_use_as_albedo = true
	solid_mat.roughness = 0.95
	solid_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	emis_mat = StandardMaterial3D.new()
	emis_mat.vertex_color_use_as_albedo = true
	emis_mat.emission_enabled = true
	emis_mat.emission = Color(1, 0.85, 0.55)
	emis_mat.emission_energy_multiplier = 1.8
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	_env()
	var spec_path := OS.get_environment("SPEC")
	if spec_path == "":
		spec_path = "res://masters.json"
	var specs: Array = JSON.parse_string(FileAccess.get_file_as_string(spec_path))
	var cols := int(OS.get_environment("COLS")) if OS.get_environment("COLS") != "" else 3
	var cell := 2.7
	if OS.get_environment("CELL") != "":
		cell = float(OS.get_environment("CELL"))
	for i in specs.size():
		var sp: Dictionary = specs[i]
		var holder := Node3D.new()
		holder.position = Vector3(float(i % cols) * cell - cell * (cols - 1) * 0.5, 0, -float(int(i / cols)) * 3.2)
		add_child(holder)
		holder.scale = Vector3.ONE * float(sp.get("scale", 1.0))
		holder.rotation_degrees.y = 180.0
		var built := _build(sp["kind"], sp["params"])
		for m in built:
			holder.add_child(m)
		var lab := Label3D.new()
		lab.text = str(sp["id"])
		lab.font = font
		lab.pixel_size = 0.0075
		lab.font_size = 96
		lab.modulate = Color(0.95, 0.92, 0.85)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.no_depth_test = true
		lab.position = Vector3(0, -2.2, 0)
		holder.add_child(lab)
	var cam := Camera3D.new()
	cam.position = Vector3(0, float(OS.get_environment("CAMY")) if OS.get_environment("CAMY") != "" else 9.5, float(OS.get_environment("CAMZ")) if OS.get_environment("CAMZ") != "" else 44)
	cam.fov = 42
	add_child(cam)
	cam.look_at(Vector3(0, float(OS.get_environment("LOOKY")) if OS.get_environment("LOOKY") != "" else 3.0, 0), Vector3.UP)

func _env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.09, 0.10, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.78)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -34, 0)
	sun.light_energy = 1.5
	sun.light_color = Color(1, 0.95, 0.86)
	add_child(sun)

func _mk(vb: VoxelBuilder) -> Array:
	return vb.build(solid_mat, emis_mat)

func _build(kind: String, p: Dictionary) -> Array:
	var vb = load("res://voxel.gd").new()
	var tg = load("res://trees.gd").new()
	tg.vb = vb
	var hg = load("res://human.gd").new()
	hg.vb = vb
	match kind:
		"person":
			_person(vb, p)
		"pine":
			tg.pine(int(p["h"]), Color(0.16,0.30,0.17))
		"cypress":
			tg.cypress(int(p["h"]), Color(0.14,0.26,0.15))
		"willow":
			tg.willow(int(p["h"]), Color(0.34,0.50,0.24))
		"bamboo":
			tg.bamboo(int(p["h"]), Color(0.36,0.56,0.26))
		"peach":
			tg.peach(int(p["h"]), Color(0.88,0.55,0.62))
		"dead":
			tg.dead(int(p["h"]))
		"broadleaf":
			tg.broadleaf(int(p["h"]), _c(p.get("leaf", [0.24,0.40,0.20])))
		"tree_stage":
			tg.broadleaf_stage(int(p["stage"]), _c(p.get("leaf", [0.24,0.40,0.20])))
		"gate":
			_gate(vb, p)
		"house":
			_house(vb, p)
		"pagoda":
			_pagoda(vb, p)
		"sword":
			_sword(vb, p)
		"pill":
			_pill(vb, p)
		"beast":
			_beast(vb, p)
		"field":
			_field(vb, p)
		"city":
			_city(vb, p)
		"human":
			hg.person(_c(p["robe"]), _c(p["hair"]), str(p.get("hat","none")), str(p.get("pose","idle")))
		"chicken":
			hg.chicken()
		"wolf":
			hg.wolf()
		"vine":
			hg.vine(Color(0.86, 0.72, 0.96))
		"tree_spirit":
			hg.tree_spirit()
	return _mk(vb)

func _c(a: Array) -> Color:
	return Color(a[0], a[1], a[2])

func _person(vb: VoxelBuilder, p: Dictionary) -> void:
	var robe := _c(p["robe"])
	var hair := _c(p["hair"])
	var skin := Color(0.96, 0.83, 0.72)
	vb.box(0,0,0, 3,1,3, Color(0.10,0.10,0.12))
	vb.box(0,1,0, 3,5,3, robe, 0.05)
	vb.box(0,3,0, 3,5,3, Color(0.82,0.66,0.32), 0.03)
	vb.box(0,5,0, 3,8,3, skin)
	vb.box(0,7,0, 3,8,3, hair, 0.04)
	vb.box(0,5,0, 3,8,1, hair, 0.04)
	var hat := str(p.get("hat","none"))
	if hat == "hairpin":
		vb.box(0,7,0, 3,9,3, hair, 0.04)
		vb.box(-1,8,1, 5,9,2, Color(0.86,0.74,0.42))
	elif hat == "crown":
		vb.box(0,8,0, 3,9,3, Color(0.78,0.66,0.30))
		vb.box(1,9,1, 2,10,2, Color(0.90,0.80,0.40))
	vb.box(0,5,3, 1,6,4, Color(0.08,0.09,0.14))
	vb.box(2,5,3, 3,6,4, Color(0.08,0.09,0.14))

func _pine(vb: VoxelBuilder, p: Dictionary) -> void:
	var h: int = int(p["h"])
	var leaf := _c(p["leaf"])
	vb.box(-1,0,-1, 2,h/2,2, Color(0.26,0.18,0.12))
	for i in 4:
		var y0 := h/2 + i * (h/8)
		var r := h/3 - i
		for x in range(-r, r):
			for z in range(-r, r):
				if abs(x) + abs(z) <= r:
					vb.put(x, y0, z, leaf.lightened(float(i) * 0.05))

func _broadleaf(vb: VoxelBuilder, p: Dictionary) -> void:
	var h: int = int(p["h"])
	var leaf := _c(p["leaf"])
	vb.box(-1,0,-1, 2,h/2,2, Color(0.28,0.20,0.13))
	vb.sphere(0, h/2 + 3, 0, float(h) / 3.4, leaf, 0.10)
	if bool(p.get("glow", false)):
		vb.box_e(1, h - 1, 1, 2, h, 2, Color(1, 0.92, 0.62))

func _gate(vb: VoxelBuilder, p: Dictionary) -> void:
	var w: int = int(p["w"])
	var h: int = int(p["h"])
	vb.box(-w/2, 0, -2, w/2, 1, 2, Color(0.82,0.80,0.74))
	for sx in [-1, 1]:
		var x: int = sx * (w/2 - 1)
		vb.box(x - 1, 1, -1, x + 1, h, 1, Color(0.66, 0.16, 0.14))
	vb.box(-w/2, h - 2, -2, w/2, h, 2, Color(0.44, 0.26, 0.16))
	for i in 3:
		vb.box(-w/2 - 2 + i, h + i, -3, w/2 + 2 - i, h + i + 1, 3, Color(0.16, 0.20, 0.28))
	vb.box(-3, h - 1, -3, 3, h, -2, Color(0.12, 0.10, 0.08))

func _house(vb: VoxelBuilder, p: Dictionary) -> void:
	var w: int = int(p["w"])
	var d: int = int(p["d"])
	var h: int = int(p["h"])
	var roof := _c(p["roof"])
	vb.box(-w/2 - 1, 0, -d/2 - 1, w/2 + 1, 1, d/2 + 1, Color(0.80,0.78,0.72))
	vb.box(-w/2, 1, -d/2, w/2, h, d/2, Color(0.86, 0.80, 0.68), 0.03)
	for sx in [-1, 1]:
		vb.box(sx * w/2 - 1, 1, -d/2, sx * w/2, h, d/2, Color(0.62, 0.16, 0.14))
	for i in 3:
		vb.box(-w/2 - 2 + i, h + i, -d/2 - 2 + i, w/2 + 2 - i, h + i + 1, d/2 + 2 - i, roof)
	vb.box_e(-2, 2, -d/2 - 1, 2, 4, -d/2, Color(1, 0.72, 0.36))

func _pagoda(vb: VoxelBuilder, p: Dictionary) -> void:
	var tiers: int = int(p["tiers"])
	var r: int = int(p["r"])
	for t in tiers:
		var rr: int = r - t
		var y0: int = t * 5
		vb.box(-rr, y0, -rr, rr, y0 + 3, rr, Color(0.84, 0.78, 0.66), 0.03)
		for sx in [-1, 1]:
			vb.box(sx * rr - 1, y0, -rr, sx * rr, y0 + 3, rr, Color(0.66, 0.16, 0.14))
		vb.box(-rr - 3, y0 + 3, -rr - 3, rr + 3, y0 + 4, rr + 3, Color(0.15, 0.19, 0.27))
		vb.box(-rr - 2, y0 + 4, -rr - 2, rr + 2, y0 + 5, rr + 2, Color(0.12, 0.16, 0.23))
	vb.box(-1, tiers * 5, -1, 1, tiers * 5 + 3, 1, Color(0.86, 0.72, 0.32))

func _sword(vb: VoxelBuilder, p: Dictionary) -> void:
	var len: int = int(p["len"])
	for i in len:
		vb.box(0, i, 0, 1, i + 1, 1, Color(0.78, 0.82, 0.86))
	vb.box(-3, len - 2, 0, 4, len - 1, 1, Color(0.72, 0.60, 0.28))
	vb.box(0, -5, 0, 1, len - 2, 1, Color(0.24, 0.20, 0.18))
	vb.box_e(0, 1, 0, 1, 2, 1, _c(p["gem"]))

func _pill(vb: VoxelBuilder, p: Dictionary) -> void:
	var c := _c(p["color"])
	vb.sphere(0, 3, 0, 3.2, c, 0.05)
	vb.box(-2, 0, -2, 2, 1, 2, Color(0.72, 0.66, 0.46))
	vb.box_e(-1, 3, -1, 1, 4, 1, c.lightened(0.4))

func _beast(vb: VoxelBuilder, p: Dictionary) -> void:
	var s: int = int(p["size"])
	var c := _c(p["color"])
	vb.box(0, 2, -s/2, 3, 2 + s/2, s/2, c, 0.04)
	vb.box(3, 2 + s/2 - 2, -2, 5, 2 + s/2 + 1, 2, c.lightened(0.08))
	for i in 4:
		var x: int = 0 if i < 2 else 3
		vb.box(x, 0, -s/2 + (0 if i % 2 == 0 else s - 1), x + 1, 2, -s/2 + (1 if i % 2 == 0 else s), Color(0.36,0.30,0.24))
	vb.box(4, 2 + s/2, -3, 5, 3 + s/2, -2, Color(0.92,0.86,0.70))
	vb.box(4, 2 + s/2, 2, 5, 3 + s/2, 3, Color(0.92,0.86,0.70))

func _field(vb: VoxelBuilder, p: Dictionary) -> void:
	var w: int = int(p["w"])
	var d: int = int(p["d"])
	var crop := _c(p["crop"])
	vb.box(-w/2, 0, -d/2, w/2, 1, d/2, Color(0.34, 0.26, 0.18))
	for x in range(-w/2 + 1, w/2, 3):
		vb.box(x, 1, -d/2 + 1, x + 2, 2, d/2 - 1, crop, 0.10)

func _city(vb: VoxelBuilder, p: Dictionary) -> void:
	var r: int = int(p["r"])
	vb.box(-r, 0, -r, r, 1, r, Color(0.66, 0.64, 0.60))
	vb.box(-r, 1, -r, r, 2, -r + 1, Color(0.54, 0.50, 0.46))
	vb.box(-r, 1, r - 1, r, 2, r, Color(0.54, 0.50, 0.46))
	vb.box(-r, 1, -r, -r + 1, 2, r, Color(0.54, 0.50, 0.46))
	vb.box(r - 1, 1, -r, r, 2, r, Color(0.54, 0.50, 0.46))
	for i in 5:
		var x: int = -r + 2 + i * (2 * r - 4) / 5
		vb.box(x, 1, -2, x + 2, 4 + (i % 2), 2, Color(0.86, 0.80, 0.68))
		vb.box(x - 1, 4 + (i % 2), -3, x + 3, 5 + (i % 2), 3, Color(0.20, 0.24, 0.32))
