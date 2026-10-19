extends Node3D
# 四视图转盘：正面 / 3-4 侧 / 侧面 / 背面
const Rig2 := preload("res://rig/rig2.gd")
const Stage := preload("res://rig/stage.gd")

func _ready() -> void:
	Stage.setup(self, Color(0.10, 0.11, 0.13), 0.62)
	Stage.grid_ground(self, 8.0, 0.5)
	var rots := [0.0, 45.0, 90.0, 180.0]
	var names := ["正面", "3/4 侧", "侧面", "背面"]
	for i in 4:
		var r: Node3D = Rig2.new(); r.build(true); add_child(r)
		r.position = Vector3(-1.62 + i * 1.08, 0, 0)
		r.rotation_degrees.y = rots[i]
		Stage.label(self, names[i], Vector3(-1.62 + i * 1.08, 0.02, -0.55), 30)
	Stage.camera(self, Vector3(-1.62, 1.35, -6.0), Vector3(-0.0, 0.95, 0), 26)
	await Shot.grab(self, "res://out/turn.png")
	get_tree().quit()
