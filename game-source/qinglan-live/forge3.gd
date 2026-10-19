extends Control

const GOLD := Color(0.86, 0.72, 0.44)
const TEXT := Color(0.92, 0.90, 0.85)
const DIM := Color(0.52, 0.52, 0.55)
const GREEN := Color(0.55, 0.84, 0.60)
const BLUE := Color(0.48, 0.70, 0.95)
const PURPLE := Color(0.72, 0.55, 0.92)
const AMBER := Color(0.90, 0.74, 0.34)

var font: FontFile
var shapes := ["剑", "刀", "枪", "钟", "伞", "扇", "杖", "弓"]
var lv := 17
var in_battle := false

func _ready() -> void:
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	var bg := ColorRect.new(); bg.color = Color(0.043, 0.047, 0.055); bg.size = Vector2(1920, 1080); add_child(bg)
	_t(38, "锻造台 · 器灵（不会失败，只需喂）", Vector2(56, 24), TEXT)
	_t(17, "吞噬＝吃东西，必定成功；每吞一次 +1 级。每阶 4 段 × 10 级 = 40 级，满 40 级才进下一阶", Vector2(56, 76), DIM)
	_card()
	_shapes()
	_feed()
	_rules()

func _t(sz: int, txt: String, pos: Vector2, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.text = txt; l.position = pos; add_child(l); return l

func _lbl(sz: int, txt: String, col: Color, pos: Vector2) -> Label:
	var l := _t(sz, txt, pos, col); remove_child(l); return l

func _box(pos: Vector2, sz: Vector2, border: Color) -> Panel:
	var p := Panel.new(); p.position = pos; p.size = sz
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.075, 0.085, 0.95)
	sb.border_color = border; sb.set_border_width_all(2); sb.set_corner_radius_all(14)
	p.add_theme_stylebox_override("panel", sb); add_child(p); return p

func _card() -> void:
	var p := _box(Vector2(56, 116), Vector2(620, 520), GREEN)
	p.add_child(_lbl(20, "器灵 · 未名", GOLD, Vector2(24, 16)))
	p.add_child(_lbl(26, "· 剑", TEXT, Vector2(24, 52)))
	p.add_child(_lbl(19, "灵品 · 精工 · Lv.%d / 40" % lv, GREEN, Vector2(24, 92)))
	# 40 格进度
	for i in 40:
		var seg := ColorRect.new()
		seg.color = GREEN if i < lv else Color(0.16, 0.17, 0.19)
		seg.position = Vector2(24 + (i % 20) * 27, 128 + int(i / 20) * 14)
		seg.size = Vector2(24, 10)
		p.add_child(seg)
	p.add_child(_lbl(16, "每阶 4 段（粗制/精工/良造/极品）各 10 级 · 满 40 级自动进阶", DIM, Vector2(24, 172)))
	p.add_child(_lbl(18, "当前形态：剑", TEXT, Vector2(24, 214)))
	p.add_child(_lbl(18, "战力加成：攻击 +1.35 倍（灵品系数）", TEXT, Vector2(24, 246)))
	p.add_child(_lbl(18, "器灵能力：初醒 · 可吐一字", GREEN, Vector2(24, 278)))
	p.add_child(_lbl(18, "距离进阶：还需 %d 级（吞 %d 次）" % [40 - lv, 40 - lv], AMBER, Vector2(24, 310)))
	p.add_child(_lbl(16, "进阶后：灵品→玄品，系数 1.35→1.80，颜色转蓝", DIM, Vector2(24, 342)))

func _shapes() -> void:
	var p := _box(Vector2(700, 116), Vector2(620, 520), Color(0.45, 0.42, 0.36))
	p.add_child(_lbl(20, "化形（唯一优待）", GOLD, Vector2(24, 16)))
	p.add_child(_lbl(16, "战斗外可随意换形；战斗中锁定，不能换", DIM, Vector2(24, 52)))
	for i in shapes.size():
		var b := Button.new(); b.text = shapes[i]
		b.position = Vector2(24 + (i % 4) * 145, 88 + int(i / 4) * 96); b.size = Vector2(130, 84)
		b.add_theme_font_override("font", font); b.add_theme_font_size_override("font_size", 28)
		if i == 0: b.modulate = Color(1.0, 1.0, 1.0, 1.0)
		p.add_child(b)
	p.add_child(_lbl(17, "剑↔刀↔枪随时换，器灵不换、阶不变", TEXT, Vector2(24, 296)))
	p.add_child(_lbl(17, "战斗中：形态锁定，直到脱战", Color(0.86, 0.62, 0.55), Vector2(24, 328)))
	p.add_child(_lbl(16, "换形不改词条与系数，只改招式动作与外观", DIM, Vector2(24, 360)))

func _feed() -> void:
	var p := _box(Vector2(1344, 116), Vector2(520, 520), Color(0.45, 0.42, 0.36))
	p.add_child(_lbl(20, "吞噬", GOLD, Vector2(24, 16)))
	p.add_child(_lbl(18, "投入材料", TEXT, Vector2(24, 56)))
	p.add_child(_lbl(17, "灵材·下品 ×1", DIM, Vector2(24, 86)))
	p.add_child(_lbl(17, "器胚吃掉即升 1 级，必定成功", GREEN, Vector2(24, 120)))
	p.add_child(_lbl(18, "本次投入可得", TEXT, Vector2(24, 164)))
	p.add_child(_lbl(17, "灵品·精工 Lv.17 → Lv.18", AMBER, Vector2(24, 196)))
	var btn := Button.new(); btn.text = "  喂  下  "
	btn.position = Vector2(24, 236); btn.size = Vector2(220, 56)
	btn.add_theme_font_override("font", font); btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func(): lv = mini(lv + 1, 40); _refresh())
	p.add_child(btn)
	p.add_child(_lbl(16, "没有失败率、没有爆装：它只是饿。", DIM, Vector2(24, 310)))

func _rules() -> void:
	var p := _box(Vector2(56, 676), Vector2(1808, 148), Color(0.35, 0.33, 0.30))
	p.add_child(_lbl(19, "规则", GOLD, Vector2(24, 12)))
	p.add_child(_lbl(17, "① 器胚只有凡物一种；首次吞噬即唤醒器灵，从此有身份　② 吞噬必定成功，每次 +1 级；失败率、爆装、匠人火候一律没有", TEXT, Vector2(24, 46)))
	p.add_child(_lbl(17, "③ 每阶 4 段 × 10 级 = 40 级，凡品→灵品要喂满 40 次；阶越高，每次所需的材料阶也越高　④ 形态是玩家唯一优待：脱战可换，入战锁定", TEXT, Vector2(24, 82)))
	p.add_child(_lbl(17, "⑤ 红·极封顶；棱彩不可造，只能易主", TEXT, Vector2(24, 118)))

func _refresh() -> void:
	for c in get_children():
		c.queue_free()
	_ready()
