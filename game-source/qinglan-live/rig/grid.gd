extends Node3D
const RigScript := preload("res://rig/rig.gd")
const SHOW := ["待机","行走 A","奔跑 A","御剑·悬停","剑·劈起","画符","炼丹·守炉","舞·3"]
const FACES := [["平静","平静"],["大笑","大笑"],["愤怒","愤怒"],["惊讶","惊讶"],["悲伤","悲伤"]]

func _ready() -> void:
	var f := FileAccess.open("res://rig/data_poses.json", FileAccess.READ)
	var P: Dictionary = JSON.parse_string(f.get_as_text())
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.035,0.04,0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58,0.64,0.74); env.ambient_light_energy = 0.85
	we.environment = env; add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40,-34,0); sun.light_energy = 1.6
	add_child(sun)
	for i in SHOW.size():
		var name: String = SHOW[i]
		var r := RigScript.new(); r.build(); add_child(r)
		r.position = Vector3(-10.5 + float(i) * 3.0, 0, 0.0)
		r.rotation_degrees.y = 16
		var d: Dictionary = P.get(name, {})
		var out := {}
		for k in d.keys(): out[k] = Vector3(d[k][0], d[k][1], d[k][2])
		r.pose(out)
		var ex := "平静"
		if name == "呐喊": ex = "愤怒"
		elif name == "捧腹大笑": ex = "大笑"
		elif name == "御剑·悬停": ex = "坚毅"
		r.express(ex)
		var lab := Label3D.new(); lab.text = name; lab.font_size = 26; lab.pixel_size = 0.0085
		lab.position = Vector3(0, 2.75, 0); lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.modulate = Color(0.92,0.9,0.86); r.add_child(lab)
	# （表情半身像单独一场景渲染，避免与全身动作挤在同一张图上）
	var cam := Camera3D.new(); cam.position = Vector3(0, 2.5, 12.4); cam.fov = 40
	add_child(cam); cam.look_at(Vector3(0, 1.05, 0.0), Vector3.UP)
