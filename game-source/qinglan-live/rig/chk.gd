extends Node3D
const Rig2 := preload("res://rig/rig2.gd")
const Stage := preload("res://rig/stage.gd")
func _ready() -> void:
	Stage.setup(self, Color(0.10, 0.11, 0.13), 0.66)
	var r: Node3D = Rig2.new(); r.build(true); add_child(r)
	Stage.label(self, "rot0", Vector3(0, 0.02, -0.4), 40)
	Stage.camera(self, Vector3(0, 1.05, -2.2), Vector3(0, 0.95, 0), 34)
	await Shot.grab(self, "res://out/chk.png")
	get_tree().quit()
