extends Node3D
const Rig2 := preload("res://rig/rig2.gd")
const Stage := preload("res://rig/stage.gd")
func _ready() -> void:
	Stage.setup(self, Color(0.10, 0.11, 0.13), 0.66)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-12, 180, 0); fill.light_energy = 0.75
	fill.light_color = Color(1.0, 0.95, 0.92); add_child(fill)
	var r: Node3D = Rig2.new(); r.build(true); add_child(r)
	r.rotation_degrees.y = 10.0
	Stage.camera(self, Vector3(0.16, 1.60, -1.30), Vector3(0, 1.58, 0), 30)
	await Shot.grab(self, "res://out/face2.png")
	get_tree().quit()
