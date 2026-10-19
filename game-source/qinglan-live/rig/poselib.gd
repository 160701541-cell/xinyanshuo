extends RefCounted
# 姿势库：读 data_poses.json，做关节角度插值
# 约定：未列出的关节 = 零旋转（与 rig.pose() 一致）

static func load_all(path := "res://rig/data_poses.json") -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("poses not found: " + path)
		return {}
	var raw = JSON.parse_string(f.get_as_text())
	var out := {}
	for k in raw.keys():
		var d := {}
		for j in raw[k].keys():
			var v: Array = raw[k][j]
			d[j] = Vector3(float(v[0]), float(v[1]), float(v[2]))
		out[k] = d
	return out

# 两帧之间按 t∈[0,1] 线性插值（缺省关节补零）
static func blend(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out := {}
	for k in a.keys():
		out[k] = (a[k] as Vector3).lerp(b.get(k, Vector3.ZERO), t)
	for k in b.keys():
		if not out.has(k):
			out[k] = Vector3.ZERO.lerp(b[k], t)
	return out

# 时间轴求值：keys = [{"p": 姿势名, "d": 时长}]，循环
static func eval(poses: Dictionary, keys: Array, t: float) -> Dictionary:
	var total := 0.0
	for k in keys:
		total += float(k["d"])
	if total <= 0.0:
		return poses.get(keys[0]["p"], {})
	t = fmod(t, total)
	var acc := 0.0
	for i in keys.size():
		var d: float = float(keys[i]["d"])
		if t < acc + d or i == keys.size() - 1:
			var u: float = clamp((t - acc) / max(d, 0.0001), 0.0, 1.0)
			var a: Dictionary = poses.get(keys[i]["p"], {})
			var b: Dictionary = poses.get(keys[(i + 1) % keys.size()]["p"], {})
			return blend(a, b, u)
		acc += d
	return poses.get(keys[0]["p"], {})

# 某个时刻处在哪一段（给连拍打标签）
static func seg_name(keys: Array, t: float) -> String:
	var total := 0.0
	for k in keys:
		total += float(k["d"])
	if total <= 0.0:
		return String(keys[0]["p"])
	t = fmod(t, total)
	var acc := 0.0
	for k in keys:
		acc += float(k["d"])
		if t < acc:
			return String(k["p"])
	return String(keys[keys.size() - 1]["p"])
