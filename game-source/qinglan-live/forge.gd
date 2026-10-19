extends Control

const GOLD := Color(0.86, 0.72, 0.44)
const TEXT := Color(0.91, 0.89, 0.84)
const DIM := Color(0.55, 0.55, 0.58)
const GREEN := Color(0.55, 0.80, 0.62)

var font: FontFile
var stage := 0          # 0=凡物 1=灵品 ... 5=仙品 6=红·极
var rates := [0.65, 0.45, 0.30, 0.18, 0.09, 0.04]
var names := ["凡物", "灵品", "玄品", "地品", "天品", "仙品", "红·极"]
var mats := ["灵材·下品 ×3", "灵材·中品 ×5", "地脉石 ×2 + 灵材·上品 ×4", "天外陨铁 / 蛟骨", "仙材 ×1（百年一遇）", "仙材 ×3 + 同阶器胚"]

func _ready() -> void:
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	var bg := ColorRect.new()
	bg.color = Color(0.043, 0.047, 0.055)
	bg.size = Vector2(1920, 1080)
	add_child(bg)
	_title("锻造台 · 器胚吞噬进阶", "器胚只能是凡物起步；每吞一次更高阶材料抬半阶，失败则材料尽失、器胚跌回凡物")
	_embryo()
	_chain()
	_footer()
	queue_redraw()

func _f(sz: int, c: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", c)
	return l

func _title(t: String, sub: String) -> void:
	var a := _f(40, TEXT); a.text = t; a.position = Vector2(56, 28); add_child(a)
	var b := _f(17, DIM); b.text = sub; b.position = Vector2(56, 84); add_child(b)

func _panel(pos: Vector2, sz: Vector2, border: Color) -> Panel:
	var p := Panel.new(); p.position = pos; p.size = sz
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.075, 0.085, 0.94)
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	p.add_theme_stylebox_override("panel", sb)
	add_child(p)
	return p

func _embryo() -> void:
	var p := _panel(Vector2(56, 130), Vector2(760, 470), Color(0.45, 0.42, 0.36))
	var t := _f(22, GOLD); t.text = "器胚"; t.position = Vector2(24, 18); p.add_child(t)
	var slot := Panel.new(); slot.position = Vector2(24, 66); slot.size = Vector2(150, 148)
	var sbs := StyleBoxFlat.new()
	sbs.bg_color = Color(0.10, 0.10, 0.12)
	sbs.border_color = Color(0.50, 0.47, 0.40)
	sbs.set_border_width_all(2); sbs.set_corner_radius_all(8)
	slot.add_theme_stylebox_override("panel", sbs)
	p.add_child(slot)
	var icon := Panel.new(); icon.position = Vector2(35, 16); icon.size = Vector2(80, 84)
	var ib := StyleBoxFlat.new(); ib.bg_color = Color(0.16, 0.16, 0.18)
	ib.border_color = Color(0.62, 0.60, 0.55); ib.set_border_width_all(2); ib.set_corner_radius_all(6)
	icon.add_theme_stylebox_override("panel", ib); slot.add_child(icon)
	var n := _f(18, TEXT); n.text = "凡物·粗制"; n.position = Vector2(24, 114); slot.add_child(n)
	var d := _f(16, DIM); d.text = "新器胚只能从这里开始"; d.position = Vector2(200, 66); p.add_child(d)
	var cur := _f(18, TEXT)
	cur.text = "当前：%s" % names[stage]
	cur.position = Vector2(200, 98); p.add_child(cur)
	var arrow := _f(18, GREEN)
	arrow.text = ("→ %s   成功率 %d%%" % [names[stage + 1], int(rates[stage] * 100)]) if stage < 6 else "已是红·极，棱彩不可造"
	arrow.position = Vector2(200, 130); p.add_child(arrow)
	var bar := ColorRect.new(); bar.color = Color(0.13, 0.14, 0.16)
	bar.position = Vector2(200, 168); bar.size = Vector2(420, 18); p.add_child(bar)
	var fill := ColorRect.new()
	fill.color = Color(0.72, 0.58, 0.28) if stage < 2 else (Color(0.78, 0.45, 0.35) if stage >= 4 else Color(0.60, 0.74, 0.66))
	fill.position = Vector2(200, 168); fill.size = Vector2(420 * (rates[stage] if stage < 6 else 0.0), 18); p.add_child(fill)
	var mt := _f(17, DIM); mt.text = "所需材料"; mt.position = Vector2(24, 236); p.add_child(mt)
	var mv := _f(18, TEXT); mv.text = mats[stage] if stage < 6 else "无（不可造）"; mv.position = Vector2(24, 266); p.add_child(mv)
	var rt := _f(17, DIM); rt.text = "失败后果"; rt.position = Vector2(24, 314); p.add_child(rt)
	var rv := _f(18, Color(0.86, 0.55, 0.50)); rv.text = "材料尽失，器胚跌回凡物，词条随机掉一条"; rv.position = Vector2(24, 344); p.add_child(rv)
	var btn := Button.new(); btn.text = "  吞  噬  "
	btn.position = Vector2(24, 396); btn.size = Vector2(200, 54)
	btn.add_theme_font_override("font", font); btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(_try_refine)
	p.add_child(btn)

func _slot_icon(pos: Vector2) -> Panel:
	var s := Panel.new(); s.position = pos; s.size = Vector2(80, 92)
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.16, 0.16, 0.18)
	sb.border_color = Color(0.62, 0.60, 0.55); sb.set_border_width_all(2); sb.set_corner_radius_all(6)
	s.add_theme_stylebox_override("panel", sb)
	return s

func _chain() -> void:
	var p := _panel(Vector2(840, 130), Vector2(1024, 470), Color(0.45, 0.42, 0.36))
	var t := _f(22, GOLD); t.text = "进阶链（越往上越难）"; t.position = Vector2(24, 18); p.add_child(t)
	for i in 7:
		var x := 24 + i * 140
		var done := i <= stage
		var c := Color(0.72, 0.60, 0.30) if done else Color(0.28, 0.29, 0.32)
		var box := ColorRect.new(); box.color = c; box.position = Vector2(x, 70); box.size = Vector2(110, 8); p.add_child(box)
		var nm := _f(17, TEXT if done else DIM); nm.text = names[i]; nm.position = Vector2(x, 88); p.add_child(nm)
		if i < 6:
			var r := _f(15, GREEN if i <= stage else DIM)
			r.text = "%d%%" % int(rates[i] * 100); r.position = Vector2(x + 30, 118); p.add_child(r)
	var note := _f(17, DIM)
	note.text = "红·极 之上没有下一档：十件棱彩恒定，不可打造，只能易主"
	note.position = Vector2(24, 170); p.add_child(note)
	var t2 := _f(20, GOLD); t2.text = "十件棱彩 · 无阶 · 唯一"; t2.position = Vector2(24, 224); p.add_child(t2)
	var list := "玄天斩　镇岳印　无咎钟　照胆镜　青囊灯　九幽伞　蛊母鼎　春秋笔　解语琴　不系舟"
	var li := _f(19, TEXT); li.text = list; li.position = Vector2(24, 262); p.add_child(li)
	var t3 := _f(16, Color(0.80, 0.62, 0.42))
	t3.text = "持有上限 9 人：第 10 人出现时，最弱者被顶掉"
	t3.position = Vector2(24, 306); p.add_child(t3)

func _footer() -> void:
	var p := _panel(Vector2(56, 626), Vector2(1808, 150), Color(0.35, 0.33, 0.30))
	var t := _f(19, GOLD); t.text = "规则"; t.position = Vector2(24, 14); p.add_child(t)
	var a := _f(17, TEXT)
	a.text = "① 器胚只能从凡物起步，不能直接买高阶胚　② 每次吞噬只抬半阶，失败跌回凡物　③ 词条随阶提升，但数量不变　④ 仙品以上需要「同阶器胚」作引，失败两者俱毁"
	a.position = Vector2(24, 50); p.add_child(a)
	var b := _f(17, TEXT)
	b.text = "⑤ 红·极是打造上限；棱彩不可造，只能从前任持有者手里夺"
	b.position = Vector2(24, 86); p.add_child(b)

func _try_refine() -> void:
	if stage >= 6:
		return
	if randf() < rates[stage]:
		stage += 1
	else:
		stage = 0
	_refresh()

func _refresh() -> void:
	for c in get_children():
		c.queue_free()
	_ready()
