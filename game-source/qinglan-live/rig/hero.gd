extends Node3D
# 主角定妆照：rig2 + 剑·劈落 + 剑气弧 + 碎芒
const Rig2 := preload("res://rig/rig2.gd")
const Stage := preload("res://rig/stage.gd")
const PoseLib := preload("res://rig/poselib.gd")

func _unshaded(c: Color, a := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(c.r, c.g, c.b, a)
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func arc(radius: float, span: float, thick: float, segs := 48) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var a: float = lerpf(-span * 0.5, span * 0.5, t)
		var w := thick * sin(PI * t) * (0.5 + 0.5 * t) + 0.01
		st.set_normal(Vector3(0, 0, 1)); st.add_vertex(Vector3(cos(a) * radius, sin(a) * radius, 0))
		st.set_normal(Vector3(0, 0, 1)); st.add_vertex(Vector3(cos(a) * (radius + w), sin(a) * (radius + w), 0))
	return st.commit()

func _ready() -> void:
	Stage.setup(self, Color(0.05, 0.06, 0.09), 0.55)
	Stage.grid_ground(self, 8.0, 0.5)
	var r: Node3D = Rig2.new(); r.build(true); add_child(r)
	r.rotation_degrees.y = 18.0
	var poses := PoseLib.load_all()
	r.pose(poses["剑·劈落"])
	r.express("坚毅")

	var g := Node3D.new(); add_child(g)
	g.position = Vector3(0.10, 1.02, -0.30)
	g.rotation_degrees = Vector3(0, 20, -42)
	var mi := MeshInstance3D.new(); mi.mesh = arc(0.86, 2.0, 0.30)
	mi.material_override = _unshaded(Color(0.55, 0.95, 1.0), 0.92)
	g.add_child(mi)
	var mi2 := MeshInstance3D.new(); mi2.mesh = arc(0.80, 1.85, 0.13); mi2.scale = Vector3(1, 1, 1)
	mi2.material_override = _unshaded(Color(0.95, 1.0, 1.0), 0.75)
	g.add_child(mi2)

	var par := CPUParticles3D.new()
	par.amount = 140; par.lifetime = 1.1
	par.position = Vector3(0.35, 1.15, -0.35)
	par.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	par.emission_sphere_radius = 0.55
	par.direction = Vector3(1, 0.1, 0); par.spread = 60.0
	par.initial_velocity_min = 1.5; par.initial_velocity_max = 4.0
	par.gravity = Vector3(0.2, -0.9, 0)
	par.scale_amount_min = 0.02; par.scale_amount_max = 0.07
	var bm := BoxMesh.new(); bm.size = Vector3(0.05, 0.05, 0.004)
	par.mesh = bm
	par.material_override = _unshaded(Color(0.65, 0.97, 1.0))
	add_child(par)

	Stage.camera(self, Vector3(2.30, 1.62, -3.55), Vector3(0.10, 1.06, 0), 38)
	for f in 40:
		await get_tree().process_frame
	await Shot.grab(self, "res://out/hero.png")
	get_tree().quit()
