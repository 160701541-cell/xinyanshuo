extends Control
# 卷轴 + 玉简 风格的 HUD：绢纸面板、1px 金线、刻度尺数值条、印章按钮
const PAPER   := Color("EFE9DC")
const PAPER_D := Color("E3DAC7")
const INK     := Color("14161A")
const INK_2   := Color("2A2B3A")
const GOLD    := Color("E8B33B")
const CINNABAR:= Color("C0392B")
const JADE    := Color("57C7A3")

var hp := 0.82
var qi := 0.61
var stam := 0.94

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette()
	_card(Vector2(32, 30), Vector2(320, 118))
	_title(Vector2(56, 48), "陆青崖", 26, INK)
	_seal(Vector2(206, 50), "筑基三层")
	_ticks(Vector2(56, 92), 244, hp, CINNABAR, "气血")
	_ticks(Vector2(56, 118), 244, qi, JADE.darkened(0.22), "灵力")
	# 右下技能栏：四枚印章
	var base := Vector2(1180, 520)
	_slot(base + Vector2(0, 0), "剑", true)
	_slot(base + Vector2(74, 0), "御", true)
	_slot(base + Vector2(148, 0), "符", false)
	_slot(base + Vector2(222, 0), "遁", false)
	_hint(Vector2(1180, 604), "点地面移动 · 双击屏幕御剑")

func _vignette() -> void:
	var v := ColorRect.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.color = Color(0, 0, 0, 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)

func _card(pos: Vector2, size: Vector2) -> void:
	var p := Panel.new()
	p.position = pos
	p.size = size
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_color = GOLD
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	sb.shadow_color = Color(0.08, 0.09, 0.11, 0.10)
	sb.shadow_size = 6
	p.add_theme_stylebox_override("panel", sb)
	add_child(p)

func _title(pos: Vector2, txt: String, size: int, col: Color) -> void:
	var l := Label.new()
	l.position = pos
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 0)
	add_child(l)

func _seal(pos: Vector2, txt: String) -> void:
	var w := Panel.new()
	w.position = pos
	w.size = Vector2(86, 24)
	var sb := StyleBoxFlat.new()
	sb.bg_color = CINNABAR
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	w.add_theme_stylebox_override("panel", sb)
	add_child(w)
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(1, 0.96, 0.90))
	w.add_child(l)

func _ticks(pos: Vector2, w: float, val: float, col: Color, name_cn: String) -> void:
	var cap := Label.new()
	cap.position = pos + Vector2(0, -2)
	cap.text = name_cn
	cap.add_theme_font_size_override("font_size", 13)
	cap.add_theme_color_override("font_color", INK_2)
	add_child(cap)
	var n := 18
	var gap := w / float(n)
	var filled := int(round(val * n))
	for i in range(n):
		var t := ColorRect.new()
		t.position = pos + Vector2(46 + gap * i, 0)
		t.size = Vector2(gap - 2, 11)
		t.color = col if i < filled else Color(PAPER_D.r, PAPER_D.g, PAPER_D.b, 0.85)
		add_child(t)

func _slot(pos: Vector2, txt: String, on: bool) -> void:
	var p := Panel.new()
	p.position = pos
	p.size = Vector2(62, 62)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER if on else Color(PAPER.r, PAPER.g, PAPER.b, 0.55)
	sb.border_color = GOLD if on else Color(INK.r, INK.g, INK.b, 0.30)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	sb.shadow_color = Color(0.08, 0.09, 0.11, 0.10)
	sb.shadow_size = 4
	p.add_theme_stylebox_override("panel", sb)
	add_child(p)
	var l := Label.new()
	l.text = txt
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.offset_top = -8
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", INK if on else Color(INK.r, INK.g, INK.b, 0.30))
	p.add_child(l)
	# 短刻线：冷却条也是刻度
	for i in range(6):
		var t := ColorRect.new()
		t.position = Vector2(pos.x + 6 + i * 9, pos.y + 50)
		t.size = Vector2(6, 3)
		if i < 3 and on:
			t.color = GOLD
		else:
			t.color = Color(INK.r, INK.g, INK.b, 0.22)
		add_child(t)

func _hint(pos: Vector2, txt: String) -> void:
	var l := Label.new()
	l.position = pos
	l.text = txt
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.94, 0.92, 0.87, 0.92))
	l.add_theme_color_override("font_shadow_color", Color(0.05, 0.05, 0.07, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	add_child(l)
