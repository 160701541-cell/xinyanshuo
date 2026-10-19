extends Node3D
# 游戏内角色：骨架 rig2 + 149 条动作 + 状态机混合
# 用法：new() → add_child() → set_state("待机"/"行走"/"奔跑"/"御剑"/"攻击")

const Rig2 := preload("res://rig/rig3.gd")
const PoseLib := preload("res://rig/poselib.gd")
const BLEND := 0.12

var rig: Node3D
var poses: Dictionary = {}
var cur: Dictionary = {}
var state := "待机"
var phase := 0.0
var attack_t := -1.0

func _ready() -> void:
	poses = PoseLib.load_all()
	rig = Rig2.new()
	rig.build(true)
	add_child(rig)
	cur = poses["待机"].duplicate()
	rig.pose(cur)
	rig.express("平静")

func set_state(s: String) -> void:
	if s == state:
		return
	if s == "攻击":
		attack_t = 0.0
	state = s
	if s == "待机":
		rig.express("平静")
	elif s == "攻击":
		rig.express("坚毅")

func _goal(dt: float) -> Dictionary:
	if state == "攻击":
		attack_t += dt
		if attack_t < 0.34:
			return poses["剑·劈起"]
		elif attack_t < 0.72:
			return poses["剑·劈落"]
		state = "待机"
		return poses["待机"]
	elif state == "行走":
		phase += dt * 2.0
		var seq: Array = ["行走 A", "行走 B", "行走 C", "行走 D"]
		return poses[seq[int(phase) % 4]]
	elif state == "奔跑":
		phase += dt * 3.4
		var seq2: Array = ["奔跑 A", "奔跑 B"]
		return poses[seq2[int(phase) % 2]]
	elif state == "御剑":
		phase += dt
		return poses["御剑·悬停"]
	return poses["待机"]

func _process(dt: float) -> void:
	var goal := _goal(dt)
	var k := clampf(dt / BLEND, 0.0, 1.0)
	for key in goal.keys():
		if not cur.has(key):
			cur[key] = Vector3.ZERO
		cur[key] = (cur[key] as Vector3).lerp(goal[key] as Vector3, k)
	rig.pose(cur)
