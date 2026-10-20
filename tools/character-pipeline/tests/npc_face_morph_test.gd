extends SceneTree
## npc_face_morph.gd 的无头测试。
## 运行：godot --headless --path <project> --script res://tools/character-pipeline/tests/npc_face_morph_test.gd
## 金标准值来自 tests/npc_face_params_ref.py（Python 独立实现），两种语言必须一致。

const M = preload("res://tools/character-pipeline/src/npc_face_morph.gd")

const GOLDEN: Dictionary = {
	"npc_001": {
		"face_width": 0.349327, "jaw_width": -0.723681, "chin_length": 0.340687,
		"chin_forward": 0.157125, "cheek_bone": -0.424295, "brow_ridge": -0.430152,
		"eye_socket_depth": -0.209015, "nose_bridge": -0.095633, "nose_tip": 0.422111,
		"nose_width": -0.385699, "forehead": -0.199348,
	},
	"canglan_elder": {
		"face_width": 0.383166, "jaw_width": 0.679586, "chin_length": 0.492238,
		"chin_forward": -0.415714, "cheek_bone": -0.222885, "brow_ridge": -0.151123,
		"eye_socket_depth": -0.801531, "nose_bridge": -0.007180, "nose_tip": -0.463548,
		"nose_width": 0.019318, "forehead": -0.584433,
	},
}

var _fails: int = 0


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		printerr("FAIL: " + what)


func _init() -> void:
	# 1) 金标准：id → 参数
	for id in GOLDEN.keys():
		var got: Dictionary = M.params_from_id(id)
		for k in GOLDEN[id].keys():
			_check(absf(float(got[k]) - float(GOLDEN[id][k])) < 1e-5, "%s.%s 与 Python 参考不一致 (%s vs %s)" % [id, k, str(got[k]), str(GOLDEN[id][k])])

	# 2) 同 id 同脸、不同 id 不同脸
	_check(M.params_from_id("npc_001") == M.params_from_id("npc_001"), "同一 id 两次结果不同")
	_check(M.params_from_id("npc_001") != M.params_from_id("npc_002"), "不同 id 得到相同参数")

	# 3) 参数校验
	_check(M.validate(M.params_from_id("npc_001")).is_empty(), "合法参数被判不合法")
	_check(not M.validate({"nope": 0.1}).is_empty(), "未知参数没被拒绝")
	_check(not M.validate({"face_width": 2.0}).is_empty(), "越界参数没被拒绝")

	# 4) 位移场：零参数不动；下巴以下不动；左右镜像
	var all_one: Dictionary = {}
	for n in M.PARAM_NAMES:
		all_one[n] = 1.0
	var p: Vector3 = Vector3(0.03, 1.70, 0.08)
	_check(M.displace(p, {}).is_equal_approx(p), "零参数时顶点被移动")
	var low: Vector3 = Vector3(0.05, 1.40, 0.06)
	_check(M.displace(low, all_one) == low, "下巴以下（颈/身体）被移动")
	var a: Vector3 = M.displace(p, all_one)
	var b: Vector3 = M.displace(Vector3(-p.x, p.y, p.z), all_one)
	_check(absf(a.x + b.x) < 1e-9 and absf(a.y - b.y) < 1e-9 and absf(a.z - b.z) < 1e-9, "左右不镜像")
	_check(a.distance_to(p) < 0.03, "单点位移异常大（>3cm）")

	if _fails == 0:
		print("npc_face_morph_test: ALL PASS")
	quit(1 if _fails > 0 else 0)
