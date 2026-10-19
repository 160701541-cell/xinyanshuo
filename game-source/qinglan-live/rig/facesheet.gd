extends Node3D
# 表情特写表：8 张半身像，逐张截图（相机固定，只换表情）
# 运行：godot --rendering-driver opengl3 --resolution 480x540 res://rig/facesheet.tscn

const RigScript := preload("res://rig/rig.gd")
const EX := ["平静","微笑","大笑","愤怒","惊讶","悲伤","痛苦","坚毅"]

func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.045, 0.05, 0.062)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.76)
	env.ambient_light_energy = 0.38
	we.environment = env; add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-34, 158, -16)
	key.light_energy = 1.9; key.light_color = Color(1.0, 0.96, 0.90)
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-8, 210, 18)
	fill.light_energy = 0.55; fill.light_color = Color(0.72, 0.80, 1.0)
	add_child(fill)

	var r: Node3D = RigScript.new(); r.build(); add_child(r)
	r.rotation_degrees.y = -8.0
	var cam := Camera3D.new()
	cam.position = Vector3(0.10, 1.93, -1.62)
	cam.fov = 26
	add_child(cam)
	cam.look_at(Vector3(0.02, 1.92, 0), Vector3.UP)

	var outdir := "res://out/faces"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(outdir))
	for i in EX.size():
		r.express(EX[i])
		await Shot.grab(self, "%s/%02d.png" % [outdir, i])
	get_tree().quit()
