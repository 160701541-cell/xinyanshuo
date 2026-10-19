extends Control

const GOLD := Color(0.85, 0.72, 0.44)
const JADE := Color(0.45, 0.80, 0.73)
const RED  := Color(0.82, 0.38, 0.34)
const TXT  := Color(0.90, 0.88, 0.82)
const DIM  := Color(0.62, 0.62, 0.66)
const INK  := Color(0.07, 0.08, 0.10)

var font: FontFile
var items: Array
var player: Dictionary
var detail: VBoxContainer
var selected := 0

func _ready() -> void:
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	items = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))
	player = JSON.parse_string(FileAccess.get_file_as_string("res://data/player.json"))
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.60, 0.62)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_left()
	_right()
	_show_item(0)

func _panel(r: Rect2, a := 0.92, border := true) -> Panel:
	var p := Panel.new()
	p.position = r.position
	p.size = r.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.11, a)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	if border:
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.85, 0.72, 0.44, 0.45)
	p.add_theme_stylebox_override("panel", sb)
	add_child(p)
	return p

func _text(parent: Node, s: String, pos: Vector2, size := 22, color := TXT) -> Label:
	var l := Label.new()
	l.text = s
	l.position = pos
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func _bar(parent: Node, pos: Vector2, w: float, v: float, mx: float, c: Color, label: String) -> void:
	var track := _panel(Rect2(pos.x, pos.y, w, 14), 0.55, false)
	track.get_theme_stylebox("panel").bg_color = Color(0.16, 0.17, 0.20, 0.9)
	var fill := ColorRect.new()
	fill.position = Vector2(0, 0)
	fill.size = Vector2(w * clampf(v / mx, 0.0, 1.0), 14)
	fill.color = c
	track.add_child(fill)
	_text(parent, label, pos + Vector2(0, -26), 18, DIM)

func _left() -> void:
	_panel(Rect2(48, 40, 700, 1000))
	var t := _text(self, player["name"], Vector2(84, 74), 40, GOLD)
	_text(self, "%s · 青岚村猎户之子 · %d 岁" % [player["realm"], int(player["age"])], Vector2(86, 128), 19, DIM)
	# 修为
	_text(self, "修为 %d / %d" % [int(player["xp"]), int(player["xp_need"])], Vector2(86, 168), 17, DIM)
	_bar(self, Vector2(86, 200), 620, float(player["xp"]), float(player["xp_need"]), GOLD, "")
	# 资源
	_text(self, "气血   %d / %d" % [int(player["hp"]), int(player["hp_max"])], Vector2(86, 268), 19, TXT)
	_bar(self, Vector2(86, 300), 620, float(player["hp"]), float(player["hp_max"]), RED, "")
	_text(self, "灵力   %d / %d" % [int(player["mp"]), int(player["mp_max"])], Vector2(86, 348), 19, TXT)
	_bar(self, Vector2(86, 380), 620, float(player["mp"]), float(player["mp_max"]), JADE, "")
	_text(self, "饱食   %d / 100" % int(player["state"]["饱食"]), Vector2(86, 428), 19, TXT)
	_bar(self, Vector2(86, 460), 620, float(player["state"]["饱食"]), 100.0, Color(0.72, 0.62, 0.36), "")
	# 六维
	_text(self, "根骨天资", Vector2(86, 520), 22, GOLD)
	var keys := ["神识", "体魄", "身法", "悟性", "根骨", "机缘"]
	var i := 0
	for k in keys:
		var v := int(player["attrs"][k])
		_text(self, k, Vector2(86, 574 + i * 46), 19, TXT)
		_text(self, str(v), Vector2(180, 574 + i * 46), 19, GOLD)
		_bar(self, Vector2(230, 586 + i * 46), 470, float(v), 10.0, Color(0.60, 0.72, 0.85), "")
		i += 1
	# 世俗
	_text(self, "世俗", Vector2(86, 868), 22, GOLD)
	var m: Dictionary = player["mortal"]
	_text(self, "银钱 %d 贯 %d 文" % [int(m["银钱"]["贯"]), int(m["银钱"]["文"])], Vector2(86, 912), 19, TXT)
	_text(self, "声望 %d" % int(m["声望"]), Vector2(330, 912), 19, TXT)
	_text(self, "农艺 %d" % int(m["农艺"]), Vector2(500, 912), 19, TXT)
	_text(self, "医术 %d" % int(m["医术"]), Vector2(660, 912), 19, TXT)
	var st: Dictionary = player["state"]
	_text(self, "疲劳 %d   伤势 %d   心境 · %s" % [int(st["疲劳"]), int(st["伤势"]), str(st["心境"])], Vector2(86, 956), 18, DIM)

const SLOT := 92.0
const COLS := 8

func _right() -> void:
	_panel(Rect2(780, 40, 1090, 620))
	_text(self, "行囊", Vector2(816, 62), 26, GOLD)
	_text(self, "%d / 48 格" % items.size(), Vector2(1700, 70), 18, DIM)
	for i in items.size():
		var col := i % COLS
		var row := int(i / COLS)
		var x := 816 + col * (SLOT + 8)
		var y := 120 + row * (SLOT + 8)
		var cell := _panel(Rect2(x, y, SLOT, SLOT), 0.7)
		var nm := str(items[i]["name"])
		var l := _text(cell, nm.substr(0, 4), Vector2(8, 10), 16, TXT)
		var grade := str(items[i]["grade"])
		var gc := GOLD
		if grade == "中品":
			gc = Color(0.55, 0.85, 0.90)
		elif grade == "凡品":
			gc = Color(0.70, 0.70, 0.70)
		_text(cell, grade, Vector2(8, SLOT - 28), 14, gc)
		var n := int(items[i]["stack"])
		if n > 1:
			_text(cell, "×%d" % n, Vector2(SLOT - 34, SLOT - 28), 14, DIM)
		var btn := Button.new()
		btn.flat = true
		btn.position = Vector2(0, 0)
		btn.size = Vector2(SLOT, SLOT)
		var idx := i
		btn.pressed.connect(func(): _show_item(idx))
		cell.add_child(btn)
	_panel(Rect2(780, 692, 1090, 348))
	detail = VBoxContainer.new()
	detail.position = Vector2(816, 716)
	detail.custom_minimum_size = Vector2(1020, 0)
	add_child(detail)

func _show_item(i: int) -> void:
	selected = i
	for c in detail.get_children():
		c.queue_free()
	var it: Dictionary = items[i]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	detail.add_child(head)
	var n := Label.new()
	n.text = str(it["name"])
	n.add_theme_font_override("font", font)
	n.add_theme_font_size_override("font_size", 34)
	n.add_theme_color_override("font_color", GOLD)
	head.add_child(n)
	var g := Label.new()
	g.text = "%s · %s" % [str(it["grade"]), str(it["type"])]
	g.add_theme_font_override("font", font)
	g.add_theme_font_size_override("font_size", 20)
	g.add_theme_color_override("font_color", DIM)
	head.add_child(g)
	var eff := ""
	for k in it["effect"].keys():
		eff += "%s +%d    " % [k, int(it["effect"][k])]
	if eff == "":
		eff = "（无直接属性加成）"
	_row("功效", eff.strip_edges(), JADE)
	_row("条件", str(it["cond"]), TXT)
	_row("说明", str(it["desc"]), TXT)
	_row("来处", str(it["from"]), DIM)
	_row("价值", "%d 文" % int(it["price"]), GOLD)

func _row(k: String, v: String, c: Color) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	detail.add_child(h)
	var kl := Label.new()
	kl.text = k
	kl.custom_minimum_size = Vector2(88, 0)
	kl.add_theme_font_override("font", font)
	kl.add_theme_font_size_override("font_size", 20)
	kl.add_theme_color_override("font_color", DIM)
	h.add_child(kl)
	var vl := Label.new()
	vl.text = v
	vl.add_theme_font_override("font", font)
	vl.add_theme_font_size_override("font_size", 20)
	vl.add_theme_color_override("font_color", c)
	h.add_child(vl)
