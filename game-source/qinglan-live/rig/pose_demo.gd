extends Node3D
const RigScript := preload("res://rig/rig.gd")

var POSES := {
 "待机": {"sh_L":Vector3(0,0,6),"sh_R":Vector3(0,0,-6),"el_L":Vector3(-8,0,0),"el_R":Vector3(-8,0,0)},
 "行走 A": {"hip_L":Vector3(26,0,0),"hip_R":Vector3(-22,0,0),"kn_L":Vector3(-14,0,0),"kn_R":Vector3(30,0,0),
            "sh_L":Vector3(-24,0,8),"sh_R":Vector3(24,0,-8),"el_L":Vector3(-20,0,0),"el_R":Vector3(-14,0,0),"spine":Vector3(4,0,0)},
 "行走 B": {"hip_L":Vector3(-22,0,0),"hip_R":Vector3(26,0,0),"kn_L":Vector3(30,0,0),"kn_R":Vector3(-14,0,0),
            "sh_L":Vector3(24,0,8),"sh_R":Vector3(-24,0,-8),"el_L":Vector3(-14,0,0),"el_R":Vector3(-20,0,0),"spine":Vector3(4,0,0)},
 "奔跑": {"hip_L":Vector3(56,0,0),"hip_R":Vector3(-38,0,0),"kn_L":Vector3(-46,0,0),"kn_R":Vector3(74,0,0),
          "sh_L":Vector3(-64,0,12),"sh_R":Vector3(52,0,-12),"el_L":Vector3(-70,0,0),"el_R":Vector3(-40,0,0),"spine":Vector3(16,0,0)},
 "御剑飞行": {"hip_L":Vector3(-6,0,3),"hip_R":Vector3(-6,0,-3),"kn_L":Vector3(10,0,0),"kn_R":Vector3(10,0,0),
          "sh_L":Vector3(148,0,-18),"sh_R":Vector3(148,0,18),"el_L":Vector3(-96,0,0),"el_R":Vector3(-96,0,0),"spine":Vector3(-6,0,0),"head":Vector3(-8,0,0)},
 "拔剑": {"sh_R":Vector3(-96,0,-28),"el_R":Vector3(-30,0,0),"sh_L":Vector3(-20,0,20),"hip_L":Vector3(12,0,0),"spine":Vector3(6,10,0)},
 "劈砍": {"sh_R":Vector3(-150,0,-10),"el_R":Vector3(-20,0,0),"sh_L":Vector3(-40,0,26),"spine":Vector3(20,-14,0),
          "hip_L":Vector3(30,0,0),"hip_R":Vector3(-16,0,0),"kn_L":Vector3(-24,0,0)},
 "格挡": {"sh_L":Vector3(-120,0,40),"el_L":Vector3(-100,0,0),"sh_R":Vector3(-40,0,-20),"el_R":Vector3(-70,0,0),
          "spine":Vector3(-8,0,0),"hip_L":Vector3(16,0,0),"kn_L":Vector3(-10,0,0)},
 "打坐": {"hip_L":Vector3(90,0,26),"hip_R":Vector3(90,0,-26),"kn_L":Vector3(0,0,90),"kn_R":Vector3(0,0,-90),
          "sh_L":Vector3(0,0,54),"sh_R":Vector3(0,0,-54),"el_L":Vector3(-70,0,0),"el_R":Vector3(-70,0,0),"spine":Vector3(-4,0,0)},
 "锄地": {"spine":Vector3(34,0,0),"sh_L":Vector3(-60,0,10),"sh_R":Vector3(-60,0,-10),"el_L":Vector3(-40,0,0),"el_R":Vector3(-40,0,0),
          "hip_L":Vector3(18,0,0),"hip_R":Vector3(-10,0,0),"kn_R":Vector3(24,0,0),"head":Vector3(16,0,0)},
 "挑水": {"sh_L":Vector3(-20,0,64),"sh_R":Vector3(-20,0,-64),"el_L":Vector3(-90,0,0),"el_R":Vector3(-90,0,0),
          "spine":Vector3(-4,0,0),"hip_L":Vector3(10,0,0),"hip_R":Vector3(-8,0,0)},
 "倒地": {"pelvis":Vector3(0,0,88),"spine":Vector3(-10,0,0),"sh_L":Vector3(-40,0,30),"sh_R":Vector3(-30,0,-40),
          "hip_L":Vector3(-20,0,10),"hip_R":Vector3(-14,0,-8),"kn_L":Vector3(24,0,0)}
}

func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.035,0.04,0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55,0.62,0.72); env.ambient_light_energy = 0.75
	we.environment = env; add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-42,-32,0); sun.light_energy = 1.5
	add_child(sun)
	var cam := Camera3D.new(); cam.position = Vector3(0, 2.4, 10.2); cam.fov = 46
	add_child(cam); cam.look_at(Vector3(0, 1.0, -1.7), Vector3.UP)
	var keys := POSES.keys(); var i := 0
	for k in keys:
		var r := RigScript.new()
		r.build()
		add_child(r)
		r.position = Vector3(-4.8 + float(i % 6) * 1.95, 0, -float(i / 6) * 3.4)
		r.rotation_degrees.y = 18
		r.pose(POSES[k])
		var lab := Label3D.new(); lab.text = k; lab.font_size = 30; lab.pixel_size = 0.007
		lab.position = Vector3(0, 2.25, 0); lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		r.add_child(lab)
		i += 1
