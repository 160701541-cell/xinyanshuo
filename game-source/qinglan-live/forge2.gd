extends Control

const GOLD := Color(0.86, 0.72, 0.44)
const TEXT := Color(0.92, 0.90, 0.85)
const DIM := Color(0.52, 0.52, 0.55)
const GREEN := Color(0.55, 0.82, 0.63)
const AMBER := Color(0.88, 0.70, 0.36)
const BLUE := Color(0.55, 0.72, 0.90)

var font: FontFile
var shapes := ["剑", "刀", "枪", "钟", "伞", "扇", "杖", "弓"]

func _ready() -> void:
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	var bg := ColorRect.new(); bg.color = Color(0.043, 0.047, 0.055); bg.size = Vector2(1920, 1080); add_child(bg)
	_t(38, "锻造台 · 第一次吞噬 = 唤醒器灵 + 定型", Vector2(56, 26), TEXT)
	_t(17, "器胚只有凡物一种；吞下第一份材料的同时，选一次武器形状，从此形状与器灵都不再改变", Vector2(56, 80), DIM)
	_panel_a()
	_panel_b()
	_rules()

func _t(sz: int, txt: String, pos: Vector2, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.text = txt; l.position = pos; add_child(l); return l

func _box(pos: Vector2, sz: Vector2, border: Color) -> Panel:
	var p := Panel.new(); p.position = pos; p.size = sz
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.075, 0.085, 0.95)
	sb.border_color = border; sb.set_border_width_all(2); sb.set_corner_radius_all(14)
	p.add_theme_stylebox_override("panel", sb); add_child(p); return p

func _panel_a() -> void:
	var p := _box(Vector2(56, 130), Vector2(880, 560), Color(0.45, 0.42, 0.36))
	p.add_child(_lbl(22, "① 尚未吞噬 · 只是一块铁胚", Color(0.86, 0.82, 0.70), Vector2(24, 16)))
	p.add_child(_lbl(17, "此时它只是一块凡物铁胚，没有器灵，也没有形状", DIM, Vector2(24, 52)))
	# 器胚槽
	var slot := Panel.new(); slot.position = Vector2(24, 92); slot.size = Vector2(150, 150)
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.11, 0.11, 0.13); sb.border_color = Color(0.45, 0.42, 0.36)
	sb.set_border_width_all(2); sb.set_corner_radius_all(8); slot.add_theme_stylebox_override("panel", sb)
	p.add_child(slot)
	p.add_child(_lbl(18, "凡物·铁胚", Color(0.78, 0.76, 0.70), Vector2(42, 200)))
	p.add_child(_lbl(17, "器灵：未唤醒", Color(0.70, 0.55, 0.52), Vector2(196, 96)))
	p.add_child(_lbl(17, "形态：无（吞噬时选定，只此一次）", AMBER, Vector2(196, 126)))
	p.add_child(_lbl(20, "选一个形状", GOLD, Vector2(24, 268)))
	for i in shapes.size():
		var b := Button.new(); b.text = shapes[i]
		b.position = Vector2(24 + (i % 8) * 100, 300); b.size = Vector2(88, 88)
		b.add_theme_font_override("font", font); b.add_theme_font_size_override("font_size", 26)
		p.add_child(b)
	p.add_child(_lbl(17, "选定后不可改：这把武器一辈子就是这个样子", DIM, Vector2(24, 404)))
	var btn := Button.new(); btn.text = "  吞噬 · 唤醒器灵  "
	btn.position = Vector2(24, 446); btn.size = Vector2(300, 56)
	btn.add_theme_font_override("font", font); btn.add_theme_font_size_override("font_size", 20)
	p.add_child(btn)
	p.add_child(_lbl(16, "成功率 65%（凡物→灵品）· 失败则材料尽失、器胚跌回凡物，器灵不灭", DIM, Vector2(24, 514)))

func _panel_b() -> void:
	var p := _box(Vector2(984, 130), Vector2(880, 560), Color(0.55, 0.62, 0.78))
	p.add_child(_lbl(22, "② 吞噬之后 · 器灵已醒，形态已定", BLUE, Vector2(24, 16)))
	p.add_child(_lbl(17, "之后再吞任何材料都只抬品阶，改不了形状", DIM, Vector2(24, 52)))
	var slot := Panel.new(); slot.position = Vector2(24, 92); slot.size = Vector2(150, 150)
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.11, 0.13, 0.16); sb.border_color = Color(0.55, 0.62, 0.78)
	sb.set_border_width_all(2); sb.set_corner_radius_all(8); slot.add_theme_stylebox_override("panel", sb)
	p.add_child(slot)
	p.add_child(_lbl(18, "剑 · 灵品·蕴灵", Color(0.86, 0.84, 0.76), Vector2(30, 200)))
	p.add_child(_lbl(17, "器灵：初醒（无名）", GREEN, Vector2(196, 96)))
	p.add_child(_lbl(17, "形态：剑（已锁）", TEXT, Vector2(196, 126)))
	p.add_child(_lbl(18, "器灵随阶成长：", GOLD, Vector2(24, 268)))
	var rows := [["凡物→灵品", "初醒 · 可吐一字"], ["玄品", "能言语 · 认主"], ["地品", "可自主择招"], ["天品", "化形 · 离体而战"], ["仙品 / 红·极", "有名 · 记入器谱"]]
	for i in rows.size():
		p.add_child(_lbl(17, rows[i][0], DIM, Vector2(24, 300 + i * 34)))
		p.add_child(_lbl(17, rows[i][1], TEXT, Vector2(210, 300 + i * 34)))
	var btn := Button.new(); btn.text = "  继续吞噬（只升阶）  "
	btn.position = Vector2(24, 486); btn.size = Vector2(300, 56)
	btn.add_theme_font_override("font", font); btn.add_theme_font_size_override("font_size", 20)
	p.add_child(btn)

func _rules() -> void:
	var p := _box(Vector2(56, 716), Vector2(1808, 132), Color(0.35, 0.33, 0.30))
	p.add_child(_lbl(19, "规则", GOLD, Vector2(24, 12)))
	p.add_child(_lbl(17, "① 器胚只有「凡物·铁胚」一种　② 第一次吞噬同时做两件事：唤醒器灵、锁定武器形状（剑/刀/枪/钟/伞/扇/杖/弓，只选一次）", TEXT, Vector2(24, 46)))
	p.add_child(_lbl(17, "③ 此后每次吞噬只抬半阶，形状与器灵不可改　④ 失败材料尽失、器胚跌回凡物，但器灵不灭、形状不变　⑤ 红·极封顶，棱彩不可造", TEXT, Vector2(24, 80)))

func _lbl(sz: int, txt: String, col: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.text = txt; l.position = pos; return l
