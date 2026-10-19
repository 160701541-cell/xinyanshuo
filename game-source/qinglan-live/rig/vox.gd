extends Node3D
# 体素角色四视图
const VoxChar := preload("res://rig/voxchar.gd")
const Stage := preload("res://rig/stage.gd")

func _ready() -> void:
	Stage.setup(self, Color(0.03, 0.045, 0.062), 0.30)
	var t0 := Time.get_ticks_msec()
	var vc = VoxChar.new()
	var mesh: ArrayMesh = vc.build_mesh()
	print("build ms: ", Time.get_ticks_msec() - t0)
	var mat := VoxChar.make_material()
	var rots := [0.0, 40.0, 90.0, 180.0]
	var names := ["正面", "3/4 侧", "侧面", "背面"]
	var xs := [1.55, 0.52, -0.52, -1.55]
	for i in 4:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = Vector3(float(xs[i]), 0.0, 0.0)
		mi.rotation_degrees.y = float(rots[i])
		add_child(mi)
		Stage.label(self, str(names[i]), Vector3(float(xs[i]), -0.10, -0.30), 26)
	Stage.camera(self, Vector3(0.0, 1.05, -6.4), Vector3(0.0, 1.02, 0.0), 20)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	for f in 6:
		await get_tree().process_frame
	await Shot.grab(self, "res://out/vox_turn.png")
	get_tree().quit()
