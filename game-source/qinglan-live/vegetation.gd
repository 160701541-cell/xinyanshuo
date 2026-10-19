extends Node3D
# 植被散布：按高程/坡度规则，用 MultiMesh 只画两次（树干 + 树冠）

var world: Node3D

func build(w: Node3D) -> void:
	world = w
	_make_trunks()
	_make_canopies()

func _ok(x: float, z: float) -> bool:
	var h: float = world._h(x, z)
	if h < 1130.0 or h > 1560.0:
		return false
	var d := 30.0
	var hx: float = world._h(x + d, z) - world._h(x - d, z)
	var hz: float = world._h(x, z + d) - world._h(x, z - d)
	var slope: float = sqrt(hx * hx + hz * hz) / (2.0 * d)
	return slope < 0.55

func _make_trunks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261019
	var pts: Array[Vector3] = []
	var tries := 0
	while pts.size() < 2600 and tries < 60000:
		tries += 1
		var x := rng.randf_range(-1700.0, 1700.0)
		var z := rng.randf_range(-2300.0, 1200.0)
		if _ok(x, z):
			pts.append(Vector3(x, world._h(x, z), z))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = CylinderMesh.new()
	(mm.mesh as CylinderMesh).top_radius = 0.9
	(mm.mesh as CylinderMesh).bottom_radius = 1.4
	(mm.mesh as CylinderMesh).height = 9.0
	(mm.mesh as CylinderMesh).radial_segments = 5
	(mm.mesh as CylinderMesh).rings = 1
	mm.instance_count = pts.size()
	for i in pts.size():
		var s := rng.randf_range(0.8, 1.6)
		var b := Basis().scaled(Vector3(s, s, s))
		mm.set_instance_transform(i, Transform3D(b, pts[i] + Vector3(0, 4.5 * s, 0)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.24, 0.18, 0.13)
	m.roughness = 1.0
	mi.material_override = m
	add_child(mi)
	_make_canopies(pts, mm)

var _pts_cache: Array[Vector3] = []

func _make_canopies(pts: Array[Vector3] = [], _t: MultiMesh = null) -> void:
	if pts.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = SphereMesh.new()
	(mm.mesh as SphereMesh).radius = 3.4
	(mm.mesh as SphereMesh).height = 6.0
	(mm.mesh as SphereMesh).radial_segments = 6
	(mm.mesh as SphereMesh).rings = 3
	mm.instance_count = pts.size()
	for i in pts.size():
		var s := rng.randf_range(0.8, 1.5)
		var b := Basis().scaled(Vector3(s, s * 0.85, s))
		mm.set_instance_transform(i, Transform3D(b, pts[i] + Vector3(0, 11.0 * s, 0)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.20, 0.31, 0.17)
	m.roughness = 1.0
	mi.material_override = m
	add_child(mi)
	_pts_cache = pts
