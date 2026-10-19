extends Node3D
const RigScript := preload("res://rig/rig.gd")
const EX := ["平静","微笑","大笑","愤怒","惊讶","悲伤","痛苦","坚毅"]

func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.03,0.035,0.045)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62,0.68,0.78); env.ambient_light_energy = 1.0
	we.environment = env; add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-32,-28,0); sun.light_energy = 1.4
	add_child(sun)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-10,150,0); fill.light_energy = 0.5
	add_child(fill)
	for i in EX.size():
		var r := RigScript.new(); r.build(); add_child(r)
		r.position = Vector3(-4.9 + float(i) * 1.4, 0, 0)
		r.rotation_degrees.y = 12
		r.pose({"sh_L":Vector3(0,0,8),"sh_R":Vector3(0,0,-8)})
		r.express(EX[i])
		var lab := Label3D.new(); lab.text = EX[i]; lab.font_size = 22; lab.pixel_size = 0.0035
		lab.position = Vector3(0, 1.62, 0); lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.modulate = Color(0.95,0.92,0.86); r.add_child(lab)
	var cam := Camera3D.new(); cam.position = Vector3(0, 1.42, 3.5); cam.fov = 40
	add_child(cam); cam.look_at(Vector3(0, 1.40, 0), Vector3.UP)
