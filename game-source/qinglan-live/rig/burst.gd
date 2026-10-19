extends Node3D
# 插值连拍：待机 → 走 → 跑 → 冲刺 → 劈砍，每 0.1s 一帧
# 运行：godot --rendering-driver opengl3 --resolution 480x540 res://rig/burst.tscn
const RigScript := preload("res://rig/rig.gd")
const PoseLib := preload("res://rig/poselib.gd")
const Stage := preload("res://rig/stage.gd")
const DT := 0.1

# 时间轴（秒）：每段 = 该关键帧的持续时间
const KEYS := [
	{"p": "待机", "d": 0.5},
	{"p": "行走 A", "d": 0.22}, {"p": "行走 B", "d": 0.22},
	{"p": "行走 C", "d": 0.22}, {"p": "行走 D", "d": 0.22},
	{"p": "奔跑 A", "d": 0.16}, {"p": "奔跑 B", "d": 0.16},
	{"p": "奔跑 A", "d": 0.16}, {"p": "奔跑 B", "d": 0.16},
	{"p": "冲刺", "d": 0.28},
	{"p": "剑·劈起", "d": 0.30},
	{"p": "剑·劈落", "d": 0.26},
	{"p": "剑·收起", "d": 0.30},
]

func total() -> float:
	var s := 0.0
	for k in KEYS: s += float(k["d"])
	return s

func _ready() -> void:
	Stage.setup(self)
	Stage.grid_ground(self, 6.0, 0.5)
	var poses := PoseLib.load_all()
	var r: Node3D = RigScript.new(); r.build(Color(0.26,0.42,0.42), Color(0.94,0.80,0.70), Color(0.14,0.13,0.15), true); add_child(r)
	r.rotation_degrees.y = 46.0   # 更侧身，前后腿摆动才读得出来
	Stage.camera(self, Vector3(3.35, 1.62, -4.10), Vector3(0, 1.10, 0), 34)

	var outdir := "res://out/burst"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(outdir))
	var t := 0.0
	var i := 0
	var log_lines := PackedStringArray()
	while t < total() - 0.001:
		var p: Dictionary = PoseLib.eval(poses, KEYS, t)
		r.pose(p)
		await Shot.grab(self, "%s/f_%03d.png" % [outdir, i])
		log_lines.append("%03d  t=%.2fs  %s" % [i, t, PoseLib.seg_name(KEYS, t)])
		t += DT
		i += 1
	var lf := FileAccess.open("res://out/burst/frames.txt", FileAccess.WRITE)
	lf.store_string("\n".join(log_lines))
	lf.close()
	print("FRAMES ", i)
	get_tree().quit()
