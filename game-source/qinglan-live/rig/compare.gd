extends Node3D
const RigScript := preload("res://rig/rig.gd")
func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.055,0.065,0.085)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.66,0.72,0.82); env.ambient_light_energy = 0.9
	we.environment = env; add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-38,-30,0); sun.light_energy = 1.5
	add_child(sun)
	var a := RigScript.new(); a.use_cel = false; a.build(); add_child(a)
	a.position = Vector3(-1.5, 0, 0); a.rotation_degrees.y = 180
	a.pose({"sh_L":Vector3(0,0,8),"sh_R":Vector3(0,0,-8)}); a.express("坚毅")
	var b := RigScript.new(); b.use_cel = true; b.build(); add_child(b)
	b.position = Vector3(1.5, 0, 0); b.rotation_degrees.y = 180
	b.pose({"sh_L":Vector3(0,0,8),"sh_R":Vector3(0,0,-8)}); b.express("坚毅")
	for pair in [[a,"低多边形 · 旧",-1.6],[b,"赛璐璐 + 描边 · 新",1.6]]:
		var l := Label3D.new(); l.text = pair[1]; l.font_size = 26; l.pixel_size = 0.0038
		l.position = Vector3(pair[2], 2.55, 0); l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.modulate = Color(0.95,0.92,0.86); add_child(l)
	var cam := Camera3D.new(); cam.position = Vector3(0, 1.5, 5.0); cam.fov = 32
	add_child(cam); cam.look_at(Vector3(0, 1.15, 0), Vector3.UP)
