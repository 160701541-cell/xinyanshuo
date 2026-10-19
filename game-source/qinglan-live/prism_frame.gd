extends Control

var phase := 0.0
var speed := 0.16

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _process(delta: float) -> void:
	phase = fmod(phase + delta * speed, 1.0)
	queue_redraw()

func _pts(rect: Rect2, radius: float, seg: int = 12) -> PackedVector2Array:
	var out := PackedVector2Array()
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var centers: Array[Vector2] = [
		Vector2(rect.position.x + r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r)]
	var a0: Array[float] = [PI, PI * 1.5, 0.0, PI * 0.5]
	var a1: Array[float] = [PI * 1.5, TAU, PI * 0.5, PI]
	var edges: Array[Vector2] = [Vector2(rect.end.x - r, rect.position.y), Vector2(rect.end.x, rect.end.y - r), Vector2(rect.position.x + r, rect.end.y), Vector2(rect.position.x, rect.position.y + r)]
	var edges2: Array[Vector2] = [Vector2(rect.position.x + r, rect.position.y), Vector2(rect.end.x, rect.position.y + r), Vector2(rect.end.x - r, rect.end.y), Vector2(rect.position.x, rect.end.y - r)]
	for i in 4:
		for k in seg:
			var a: float = a0[i] + (a1[i] - a0[i]) * float(k) / float(seg)
			out.append(centers[i] + Vector2(cos(a), sin(a)) * r)
		for k in 4:
			out.append(edges2[i].lerp(edges[i], float(k) / 4.0))
	return out

func _col(mode: String, t: float, bright: float) -> Color:
	match mode:
		"gold":
			# 金黄渐变：明暗在两档黄金之间来回
			var k: float = 0.5 + 0.5 * sin((phase + t) * TAU)
			return Color(1.0, 0.72 + 0.20 * k, 0.22 + 0.30 * k) * bright
		"metal":
			# 金属渐变：赤铜 → 冷银 → 赤铜，像抛光金属反光
			var k2: float = 0.5 + 0.5 * sin((phase + t) * TAU)
			var c1 := Color(1.0, 0.35, 0.28)
			var c2 := Color(0.95, 0.80, 0.72)
			return c1.lerp(c2, k2) * bright
		_:
			return Color.from_hsv(fmod(phase + t, 1.0), 0.72, 1.0) * bright

func _frame(rect: Rect2, radius: float, width: float, mode: String, bright: float) -> void:
	var pts := _pts(rect, radius)
	var n := pts.size()
	var seg := PackedVector2Array()
	var cols := PackedColorArray()
	for i in n:
		seg.append(pts[i]); seg.append(pts[(i + 1) % n])
		cols.append(_col(mode, float(i) / float(n), bright))
	for g in 3:
		var gc := PackedColorArray()
		for c in cols:
			gc.append(Color(c.r, c.g, c.b, 0.10 + 0.06 * float(g)))
		draw_multiline_colors(seg, gc, width + 6.0 * (3 - g), true)
	draw_multiline_colors(seg, cols, width, true)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.045, 0.055))
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(48, 50), "品阶边框 · 从金色开始流转", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.95,0.93,0.88))
	draw_string(f, Vector2(48, 82), "金四→金一：金黄渐变；红：金属渐变；棱彩：七彩环流。转速与亮度随档位递增", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.62,0.62,0.66))
	var rects: Array[Rect2] = [Rect2(60, 130, 280, 190), Rect2(370, 130, 280, 190), Rect2(680, 130, 280, 190), Rect2(990, 130, 280, 190), Rect2(1300, 130, 280, 190), Rect2(1610, 130, 280, 190)]
	var names := ["金·四（淡金）", "金·三（赤金）", "金·二（足金）", "金·一（金黄）", "红（极）", "棱彩"]
	var modes := ["gold", "gold", "gold", "gold", "metal", "prism"]
	var widths := PackedFloat32Array([2.5, 3.0, 3.5, 4.0, 4.5, 5.0])
	var bris := PackedFloat32Array([0.62, 0.74, 0.86, 1.00, 1.00, 1.00])
	for i in 6:
		var r: Rect2 = rects[i]
		_frame(r, 16.0, widths[i], String(modes[i]), bris[i])
		draw_string(f, Vector2(r.position.x + 18, r.position.y + 40), String(names[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.94,0.92,0.86))
	draw_string(f, Vector2(60, 380), "转速：金四 0.05 圈/秒 → 金一 0.10 → 红 0.14 → 棱彩 0.16（6 秒一圈）", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.66,0.66,0.70))

	# 十件：无品阶，只有名字
	draw_string(f, Vector2(60, 450), "十件：没有品阶，只有名字", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.96,0.94,0.88))
	draw_string(f, Vector2(60, 486), "它们不是「某个品阶的东西」，而是十个独一无二的名号；边框是它们的外显，不是等级标签", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.62,0.62,0.66))
	var nm := ["玄天斩", "镇岳印", "无咎钟", "照胆镜", "青囊灯", "九幽伞", "蛊母鼎", "春秋笔", "解语琴", "不系舟"]
	for i in 10:
		var rr := Rect2(60 + (i % 5) * 360, 520 + int(i / 5) * 150, 330, 130)
		_frame(rr, 14.0, 4.0, "prism", 0.95)
		draw_string(f, Vector2(rr.position.x + 18, rr.position.y + 62), String(nm[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.95,0.93,0.87))
		draw_string(f, Vector2(rr.position.x + 18, rr.position.y + 92), "无阶 · 唯一", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.60,0.60,0.64))
