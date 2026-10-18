extends Control

## 苍岚 HD-2D 模板 · 界面层（暗檀金边 · 参考实机 HUD 语汇）
## 左上角色牌 / 右上小地图 / 底部道具栏 / 右侧技能 / 左下对话

const PANEL := Color(0.078, 0.061, 0.047)
const PANEL2 := Color(0.132, 0.102, 0.075)
const GOLD := Color(0.788, 0.643, 0.286)
const GOLD_DIM := Color(0.494, 0.388, 0.176)
const TEXT := Color(0.910, 0.863, 0.741)
const TEXT_DIM := Color(0.706, 0.655, 0.541)
const BLOOD := Color(0.729, 0.227, 0.180)
const JADE := Color(0.196, 0.549, 0.463)
const EARTH := Color(0.678, 0.514, 0.243)

var font_regular: Font
var font_bold: Font
var portrait: Texture2D
var mode := "day"

func build(render_mode: String = "day") -> void:
	mode = render_mode
	font_regular = load("res://assets/fonts/serif.ttc")
	font_bold = load("res://assets/fonts/serif_bold.ttc")
	portrait = load("res://assets/sprite/portrait_npc3.png")
	queue_redraw()

func _a(c: Color, alpha: float) -> Color:
	return Color(c.r, c.g, c.b, alpha)

func _diamond(c: Vector2, s: float) -> PackedVector2Array:
	return PackedVector2Array([
		c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)
	])

func _panel(r: Rect2, alpha: float = 0.92) -> void:
	draw_rect(r, _a(PANEL, alpha), true)
	draw_rect(r, _a(GOLD_DIM, 0.95), false, 1.3)
	draw_rect(Rect2(r.position + Vector2(3, 3), r.size - Vector2(6, 6)), _a(GOLD, 0.30), false, 1.0)
	for p in [r.position + Vector2(3, 3), Vector2(r.end.x - 3, r.position.y + 3), Vector2(r.position.x + 3, r.end.y - 3), r.end - Vector2(3, 3)]:
		draw_colored_polygon(_diamond(p, 4.2), GOLD)

func _text(pos: Vector2, s: String, size: int, col: Color, bold: bool = false) -> void:
	var f: Font = font_bold if bold else font_regular
	if f == null:
		return
	draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _tw(s: String, size: int, bold: bool = false) -> float:
	var f: Font = font_bold if bold else font_regular
	if f == null:
		return 0.0
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

func _tc(cx: float, baseline: float, s: String, size: int, col: Color, bold: bool = false) -> void:
	_text(Vector2(cx - _tw(s, size, bold) * 0.5, baseline), s, size, col, bold)

func _tr(rx: float, baseline: float, s: String, size: int, col: Color, bold: bool = false) -> void:
	_text(Vector2(rx - _tw(s, size, bold), baseline), s, size, col, bold)

func _tvert(cx: float, top: float, s: String, size: int, col: Color, bold: bool = false) -> void:
	var y := top
	for i in range(s.length()):
		_tc(cx, y + size, s.substr(i, 1), size, col, bold)
		y += size + 3.0

func _bar(o: Vector2, w: float, ratio: float, col: Color, label: String, val: String) -> void:
	var h := 7.0
	_text(o + Vector2(-13, 6.5), label, 11, _a(TEXT_DIM, 0.95))
	draw_rect(Rect2(o + Vector2(-1, -1), Vector2(w + 2, h + 2)), _a(Color(0, 0, 0), 0.55), true)
	draw_rect(Rect2(o, Vector2(w, h)), _a(Color(0.22, 0.17, 0.13), 0.95), true)
	var fw: float = maxf(3.0, w * clampf(ratio, 0.0, 1.0))
	draw_rect(Rect2(o, Vector2(fw, h)), col, true)
	draw_rect(Rect2(o + Vector2(0, 0.8), Vector2(fw, 2.0)), _a(Color(1, 1, 1), 0.28), true)
	draw_rect(Rect2(o + Vector2(0, h - 1.6), Vector2(fw, 1.6)), _a(Color(0, 0, 0), 0.35), true)
	draw_rect(Rect2(o + Vector2(-1, -1), Vector2(w + 2, h + 2)), _a(GOLD_DIM, 0.75), false, 1.0)
	_tr(o.x + w + 22.0, o.y + 7.0, val, 10, _a(TEXT_DIM, 0.9))

func _draw() -> void:
	_character_card()
	_quest_chip()
	_minimap()
	_time_chip()
	_hotbar()
	_skills()
	_dialog()
	_corners()

func _character_card() -> void:
	var r := Rect2(Vector2(16, 14), Vector2(330, 128))
	_panel(r, 0.93)
	# 头像
	var pr := Rect2(Vector2(26, 24), Vector2(76, 92))
	draw_rect(pr, _a(Color(0.05, 0.04, 0.03), 0.9), true)
	if portrait != null:
		draw_texture_rect(portrait, Rect2(pr.position, Vector2(76, 92)), false, Color(1, 1, 1, 0.98))
	draw_rect(pr, _a(GOLD, 0.85), false, 1.6)
	draw_rect(Rect2(pr.position - Vector2(2, 2), pr.size + Vector2(4, 4)), _a(GOLD_DIM, 0.55), false, 1.0)
	# 名号
	_text(Vector2(114, 46), "陆青崖", 20, TEXT, true)
	_text(Vector2(186, 46), "· 炼气一层", 12, _a(GOLD, 0.95))
	_text(Vector2(114, 64), "水木土杂灵根", 11, _a(TEXT_DIM, 0.9))
	_bar(Vector2(126, 76), 186, 0.78, BLOOD, "血", "78")
	_bar(Vector2(126, 94), 186, 0.70, JADE, "元", "42")
	_bar(Vector2(126, 112), 186, 0.66, EARTH, "体", "66")

func _quest_chip() -> void:
	var r := Rect2(Vector2(16, 138), Vector2(238, 50))
	_panel(r, 0.86)
	draw_colored_polygon(_diamond(Vector2(32, 163), 5.0), _a(GOLD, 0.9))
	_text(Vector2(46, 158), "山门未开", 13, TEXT, true)
	_text(Vector2(46, 178), "交命牌以入内", 11, _a(TEXT_DIM, 0.95))

func _minimap() -> void:
	var c := Vector2(1192, 104)
	var r := 64.0
	draw_circle(c, r + 3.0, _a(Color(0.04, 0.03, 0.02), 0.75))
	draw_circle(c, r, _a(PANEL2, 0.92))
	draw_arc(c, r, 0.0, TAU, 72, _a(GOLD, 0.92), 2.2, true)
	draw_arc(c, r - 7.0, 0.0, TAU, 72, _a(GOLD_DIM, 0.55), 1.0, true)
	# 地形示意：广场 + 山门 + 土路
	draw_rect(Rect2(c + Vector2(-27, -20), Vector2(54, 42)), _a(Color(0.38, 0.35, 0.28), 0.95), true)
	draw_rect(Rect2(c + Vector2(-27, -20), Vector2(54, 42)), _a(GOLD_DIM, 0.55), false, 1.0)
	for gx in range(3):
		draw_line(c + Vector2(-27 + 18 * (gx + 1), -20), c + Vector2(-27 + 18 * (gx + 1), 22), _a(Color(0.26, 0.24, 0.19), 0.7), 1.0)
	draw_rect(Rect2(c + Vector2(-16, -29), Vector2(32, 9)), _a(Color(0.20, 0.14, 0.10), 0.98), true)
	draw_rect(Rect2(c + Vector2(-16, -29), Vector2(32, 9)), _a(GOLD, 0.55), false, 1.0)
	draw_line(c + Vector2(6, 22), c + Vector2(-18, 52), _a(Color(0.52, 0.40, 0.24), 0.85), 7.0)
	for i in range(8):
		var ang := TAU * float(i) / 8.0
		var d := Vector2(cos(ang), sin(ang))
		draw_line(c + d * (r - 6.0), c + d * (r - 1.0), _a(GOLD, 0.8), 1.6, true)
	# 标记
	draw_circle(c + Vector2(0, 6.0), 4.2, _a(Color(1, 1, 1), 0.95))
	draw_circle(c + Vector2(0, 6.0), 2.0, _a(BLOOD, 0.95))
	draw_circle(c + Vector2(14, -6.0), 3.0, _a(Color(0.95, 0.72, 0.25), 0.95))
	draw_circle(c + Vector2(-16, 2.0), 3.0, _a(BLOOD, 0.9))
	_tc(c.x, c.y - r - 8.0, "北", 11, _a(GOLD, 0.95), true)
	_tc(c.x, c.y + r + 20.0, "青岚宗 · 山门广场", 11, _a(TEXT, 0.92))

func _time_chip() -> void:
	var cx := 640.0
	var y := 34.0
	var label := "辰时 · 晴 · 入山第三日"
	var w := _tw(label, 13, true)
	draw_line(Vector2(cx - w * 0.5 - 76, y), Vector2(cx - w * 0.5 - 14, y), _a(GOLD, 0.5), 1.0)
	draw_line(Vector2(cx + w * 0.5 + 14, y), Vector2(cx + w * 0.5 + 76, y), _a(GOLD, 0.5), 1.0)
	draw_colored_polygon(_diamond(Vector2(cx - w * 0.5 - 82, y), 3.4), _a(GOLD, 0.9))
	draw_colored_polygon(_diamond(Vector2(cx + w * 0.5 + 82, y), 3.4), _a(GOLD, 0.9))
	_tc(cx, y + 5.0, label, 13, _a(TEXT, 0.95), true)

func _slot(o: Vector2, s: float, glyph: String, count: String, filled: bool = true) -> void:
	var r := Rect2(o, Vector2(s, s))
	draw_rect(r, _a(Color(0.10, 0.08, 0.06), 0.95), true)
	draw_rect(r, _a(GOLD_DIM, 0.85), false, 1.3)
	draw_rect(Rect2(r.position + Vector2(2.5, 2.5), r.size - Vector2(5, 5)), _a(GOLD, 0.16), false, 1.0)
	if filled:
		if glyph == "丹":
			draw_circle(o + Vector2(s * 0.5, s * 0.52), s * 0.22, _a(Color(0.78, 0.32, 0.20), 0.95))
			draw_circle(o + Vector2(s * 0.44, s * 0.46), s * 0.07, _a(Color(1, 0.85, 0.6), 0.55))
		elif glyph == "剑":
			draw_line(o + Vector2(s * 0.28, s * 0.72), o + Vector2(s * 0.72, s * 0.30), _a(Color(0.80, 0.83, 0.87), 0.95), 3.0, true)
			draw_line(o + Vector2(s * 0.30, s * 0.46), o + Vector2(s * 0.50, s * 0.66), _a(GOLD, 0.95), 2.4, true)
		elif glyph == "符":
			draw_rect(Rect2(o + Vector2(s * 0.36, s * 0.26), Vector2(s * 0.28, s * 0.48)), _a(Color(0.86, 0.78, 0.58), 0.95), true)
			draw_line(o + Vector2(s * 0.44, s * 0.34), o + Vector2(s * 0.56, s * 0.34), _a(BLOOD, 0.9), 2.0)
			draw_line(o + Vector2(s * 0.50, s * 0.34), o + Vector2(s * 0.50, s * 0.64), _a(BLOOD, 0.9), 2.0)
		else:
			_tc(o.x + s * 0.5, o.y + s * 0.66, glyph, 18, _a(GOLD, 0.92), true)
	if count != "":
		_tr(o.x + s - 4.0, o.y + s - 4.0, count, 10, _a(TEXT, 0.95))

func _hotbar() -> void:
	var s := 52.0
	var gap := 8.0
	var total := s * 8.0 + gap * 7.0
	var x0 := 640.0 - total * 0.5
	var y0 := 640.0
	_panel(Rect2(Vector2(x0 - 10, y0 - 10), Vector2(total + 20, s + 20)), 0.90)
	var items := [["丹", "9"], ["剑", ""], ["符", "3"], ["食", "12"], ["矿", ""], ["木", "24"], ["骨", "5"], ["" as String, ""]]
	for i in range(8):
		var item: Array = items[i]
		_slot(Vector2(x0 + float(i) * (s + gap), y0), s, String(item[0]), String(item[1]), String(item[0]) != "")
	# 铜钱
	var coin := Vector2(x0 + total + 56.0, y0 + s * 0.5)
	draw_circle(coin, 15.0, _a(Color(0.78, 0.62, 0.28), 0.95))
	draw_circle(coin, 15.0, _a(Color(0.35, 0.26, 0.12), 0.9), false, 1.6)
	draw_rect(Rect2(coin + Vector2(-4, -4), Vector2(8, 8)), _a(PANEL, 0.9), true)
	_text(Vector2(coin.x + 22.0, coin.y + 5.0), "1,284", 12, _a(TEXT, 0.95))

func _skill(c: Vector2, r: float, glyph: String, ready: bool, size: int) -> void:
	draw_circle(c + Vector2(0, 2.0), r, _a(Color(0, 0, 0), 0.45))
	draw_circle(c, r, _a(PANEL2, 0.94))
	draw_arc(c, r, 0.0, TAU, 56, _a(GOLD, 0.9), 1.8, true)
	draw_arc(c, r - 5.0, 0.0, TAU, 56, _a(GOLD_DIM, 0.5), 1.0, true)
	if ready:
		_tc(c.x, c.y + size * 0.35, glyph, size, _a(TEXT, 0.98), true)

func _skills() -> void:
	_skill(Vector2(1232, 566), 42.0, "击", true, 27)
	draw_arc(Vector2(1232, 566), 47.0, deg_to_rad(-90), deg_to_rad(120), 40, _a(BLOOD, 0.8), 2.4, true)
	_skill(Vector2(1232, 478), 27.0, "疾", true, 17)
	_skill(Vector2(1232, 414), 27.0, "坐", true, 17)
	_tr(1252.0, 636.0, "体力 66/100", 10, _a(TEXT_DIM, 0.9))

func _dialog() -> void:
	var r := Rect2(Vector2(18, 466), Vector2(500, 96))
	_panel(r, 0.90)
	# 名签
	var tag := Rect2(Vector2(30, 480), Vector2(28, 66))
	draw_rect(tag, _a(Color(0.45, 0.14, 0.11), 0.96), true)
	draw_rect(tag, _a(GOLD, 0.75), false, 1.2)
	_tvert(44.0, 486.0, "守山", 13, _a(TEXT, 0.96), true)
	_text(Vector2(74, 500), "山门未开，天色将晚。", 16, TEXT, true)
	_text(Vector2(74, 528), "道友若要入内，须先交命牌，由执事验明来路。", 15, _a(TEXT, 0.92))
	
	_tr(r.end.x - 14.0, r.end.y - 10.0, "继续 ▸", 11, _a(GOLD, 0.9), true)

func _corners() -> void:
	# 画面四角的金线角花
	for corner in [Vector2(0, 0), Vector2(1280, 0), Vector2(0, 720), Vector2(1280, 720)]:
		var cv: Vector2 = corner
		var sx := 1.0 if cv.x < 640 else -1.0
		var sy := 1.0 if cv.y < 360 else -1.0
		var o: Vector2 = (corner as Vector2) + Vector2(18 * sx, 18 * sy)
		draw_line(o, o + Vector2(54 * sx, 0), _a(GOLD, 0.32), 1.2)
		draw_line(o, o + Vector2(0, 54 * sy), _a(GOLD, 0.32), 1.2)
		draw_colored_polygon(_diamond(o + Vector2(9 * sx, 9 * sy), 3.2), _a(GOLD, 0.5))
