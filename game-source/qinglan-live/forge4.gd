extends Control

const GOLD := Color(0.86, 0.72, 0.44)
const TEXT := Color(0.92, 0.90, 0.85)
const DIM := Color(0.52, 0.52, 0.55)
const GREEN := Color(0.55, 0.84, 0.60)
const AMBER := Color(0.90, 0.74, 0.34)

var font: FontFile
var lv := 32

func _ready() -> void:
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	var bg := ColorRect.new(); bg.color = Color(0.043, 0.047, 0.055); bg.size = Vector2(1920, 1080); add_child(bg)
	_t(36, "器灵 · 有名字、有立绘、有台词", Vector2(56, 24), TEXT)
	_t(16, "材料一激活，器灵就醒了；名字可改一次，立绘与台词随阶解锁", Vector2(56, 72), DIM)
	_portrait()
	_info()
	if OS.get_environment("SHOW_CONFIRM") == "1":
		_confirm()

func _t(sz: int, txt: String, pos: Vector2, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.text = txt; l.position = pos; add_child(l); return l

func _lbl(sz: int, txt: String, col: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.text = txt; l.position = pos; return l

func _box(pos: Vector2, sz: Vector2, border: Color) -> Panel:
	var p := Panel.new(); p.position = pos; p.size = sz
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.075, 0.085, 0.95)
	sb.border_color = border; sb.set_border_width_all(2); sb.set_corner_radius_all(14)
	p.add_theme_stylebox_override("panel", sb); add_child(p); return p

func _portrait() -> void:
	var p := _box(Vector2(56, 112), Vector2(760, 700), GREEN)
	# 立绘位
	var art := Panel.new(); art.position = Vector2(24, 24); art.size = Vector2(712, 430)
	var ab := StyleBoxFlat.new()
	ab.bg_color = Color(0.10, 0.12, 0.13); ab.border_color = Color(0.34, 0.40, 0.36)
	ab.set_border_width_all(1); ab.set_corner_radius_all(10)
	art.add_theme_stylebox_override("panel", ab); p.add_child(art)
	art.add_child(_lbl(20, "立  绘", Color(0.35, 0.40, 0.38), Vector2(330, 200)))
	for i in 9:
		var g := ColorRect.new(); g.color = Color(0.30, 0.52, 0.36, 0.35)
		g.position = Vector2(300 + i * 14, 120 + i * 22); g.size = Vector2(6, 190)
		art.add_child(g)
	# 名字栏
	p.add_child(_lbl(18, "器名", DIM, Vector2(24, 476)))
	var nm := Panel.new(); nm.position = Vector2(80, 468); nm.size = Vector2(300, 46)
	var nb := StyleBoxFlat.new(); nb.bg_color = Color(0.12, 0.13, 0.15)
	nb.border_color = Color(0.52, 0.62, 0.52); nb.set_border_width_all(1); nb.set_corner_radius_all(6)
	nm.add_theme_stylebox_override("panel", nb); p.add_child(nm)
	nm.add_child(_lbl(22, "青羽", Color(0.80, 0.90, 0.82), Vector2(14, 8)))
	p.add_child(_lbl(15, "（可改一次，改名后永不再变）", DIM, Vector2(392, 480)))
	# 台词
	var say := Panel.new(); say.position = Vector2(24, 528); say.size = Vector2(712, 146)
	var sb2 := StyleBoxFlat.new(); sb2.bg_color = Color(0.10, 0.11, 0.13)
	sb2.border_color = Color(0.45, 0.42, 0.36); sb2.set_border_width_all(1); sb2.set_corner_radius_all(10)
	say.add_theme_stylebox_override("panel", sb2); p.add_child(say)
	say.add_child(_lbl(16, "器灵台词 · 随阶解锁", DIM, Vector2(16, 10)))
	say.add_child(_lbl(19, "「这一剑我替你记着，下次别躲。」", Color(0.86, 0.88, 0.84), Vector2(16, 40)))
	say.add_child(_lbl(16, "—— 法器·上品解锁（当前境界 Lv.%d/40）" % lv, DIM, Vector2(16, 78)))
	say.add_child(_lbl(16, "下一句：法宝·下品解锁", Color(0.70, 0.66, 0.58), Vector2(16, 106)))

func _info() -> void:
	var p := _box(Vector2(840, 112), Vector2(1024, 700), Color(0.45, 0.42, 0.36))
	p.add_child(_lbl(20, "当前", GOLD, Vector2(24, 16)))
	p.add_child(_lbl(28, "法器 · 上品", GREEN, Vector2(24, 48)))
	p.add_child(_lbl(18, "等级 Lv.%d / 40　·　攻击 1.35 倍" % lv, TEXT, Vector2(24, 92)))
	for i in 40:
		var seg := ColorRect.new()
		seg.color = GREEN if i < lv else Color(0.16, 0.17, 0.19)
		seg.position = Vector2(24 + (i % 20) * 49, 128 + int(i / 20) * 18)
		seg.size = Vector2(44, 12)
		p.add_child(seg)
	p.add_child(_lbl(16, "每阶 4 段（下品/中品/上品/极品）各 10 级；满 40 级可选破阶", DIM, Vector2(24, 180)))
	p.add_child(_lbl(20, "破阶", GOLD, Vector2(24, 226)))
	p.add_child(_lbl(18, "法器·极品 → 法宝·下品", TEXT, Vector2(24, 262)))
	p.add_child(_lbl(17, "材料：灵材·中品 ×5 + 一脉灵泉", DIM, Vector2(24, 296)))
	p.add_child(_lbl(17, "破阶不可撤销；器灵保留、形态保留、名字保留", AMBER, Vector2(24, 330)))
	var btn := Button.new(); btn.text = "  破阶（需确认）  "
	btn.position = Vector2(24, 376); btn.size = Vector2(280, 56)
	btn.add_theme_font_override("font", font); btn.add_theme_font_size_override("font_size", 20)
	btn.disabled = lv < 40
	p.add_child(btn)
	p.add_child(_lbl(15, "未满 40 级时按钮置灰——不会自动跳阶", DIM, Vector2(24, 444)))
	p.add_child(_lbl(20, "普通物品", GOLD, Vector2(24, 500)))
	p.add_child(_lbl(17, "只能升级，不能升阶；唯一例外是极罕见特殊材料，失败只耗尽材料、不毁器", TEXT, Vector2(24, 534)))

func _confirm() -> void:
	var veil := ColorRect.new(); veil.color = Color(0, 0, 0, 0.62); veil.size = Vector2(1920, 1080); add_child(veil)
	var p := _box(Vector2(560, 330), Vector2(800, 420), Color(0.70, 0.56, 0.30))
	p.add_child(_lbl(26, "确认破阶？", Color(0.94, 0.86, 0.66), Vector2(28, 24)))
	p.add_child(_lbl(19, "法器·极品 → 法宝·下品", TEXT, Vector2(28, 76)))
	p.add_child(_lbl(17, "消耗：灵材·中品 ×5、一脉灵泉 ×1", DIM, Vector2(28, 116)))
	p.add_child(_lbl(17, "器灵与形态保留，名字不变；破阶后不可退回", Color(0.86, 0.70, 0.45), Vector2(28, 148)))
	var no := Button.new(); no.text = "  再想想  "; no.position = Vector2(28, 208); no.size = Vector2(200, 58)
	no.add_theme_font_override("font", font); no.add_theme_font_size_override("font_size", 20); p.add_child(no)
	var yes := Button.new(); yes.text = "  确认破阶  "; yes.position = Vector2(252, 208); yes.size = Vector2(220, 58)
	yes.add_theme_font_override("font", font); yes.add_theme_font_size_override("font_size", 20); p.add_child(yes)
