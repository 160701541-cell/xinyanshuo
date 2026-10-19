extends Node3D
# 体素角色头部特写
const VoxChar := preload("res://rig/voxchar.gd")
const Stage := preload("res://rig/stage.gd")

func _ready() -> void:
	Stage.setup(self, Color(0.03, 0.045, 0.062), 0.30)
	var vc = VoxChar.new()
	var mesh: ArrayMesh = vc.build_mesh()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = VoxChar.make_material()
	mi.rotation_degrees.y = 14.0
	add_child(mi)
	Stage.camera(self, Vector3(0.10, 1.62, -0.78), Vector3(0.0, 1.60, 0.0), 30)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	for f in 6:
		await get_tree().process_frame
	await Shot.grab(self, "res://out/vox_face.png")
	get_tree().quit()
