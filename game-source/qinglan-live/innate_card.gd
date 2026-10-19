extends Control

const GOLD := Color(0.86, 0.72, 0.44)
const TEXT := Color(0.92, 0.90, 0.85)
const DIM := Color(0.52, 0.52, 0.55)
const GREEN := Color(0.55, 0.82, 0.63)
const AMBER := Color(0.86, 0.70, 0.38)

var font: FontFile

func _ready() -> void:
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	var bg := ColorRect.new(); bg.color = Color(0.043, 0.047, 0.055); bg.size = Vector2(1920, 1080); add_child(bg)
	_t(38, "物品详情 · 先天加成（一次性）", Vector2(56, 26), TEXT)
	_t(17, "同一件物品对同一项先天只能生效一次；再吃只给临时增益——所以稀缺物永远有人抢", Vector2(56, 80), DIM)
	_card(Vector2(90, 140), false)
	_card(Vector2(1010, 140), true)

func _t(sz: int, txt: String, pos: Vector2, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.text = txt; l.position = pos
	add_child(l)
	return l

func _card(pos: Vector2, used: bool) -> void:
	var p := Panel.new(); p.position = pos; p.size = Vector2(820, 780)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.075, 0.085, 0.95)
	sb.border_color = Color(0.42, 0.36, 0.24) if not used else Color(0.30, 0.30, 0.32)
	sb.set_border_width_all(2); sb.set_corner_radius_all(14)
	p.add_theme_stylebox_override("panel", sb); add_child(p)

	var icon := Panel.new(); icon.position = Vector2(28, 24); icon.size = Vector2(120, 120)
	var ib := StyleBoxFlat.new(); ib.bg_color = Color(0.13, 0.14, 0.16)
	ib.border_color = Color(0.62, 0.60, 0.55); ib.set_border_width_all(2); ib.set_corner_radius_all(8)
	icon.add_theme_stylebox_override("panel", ib)
	var leaf := ColorRect.new(); leaf.color = Color(0.36, 0.62, 0.36)
	leaf.position = Vector2(34, 42); leaf.size = Vector2(52, 36); icon.add_child(leaf)
	p.add_child(icon)

	var n := _lbl(30, "仙茶 · 云雾芽", Color(0.58, 0.86, 0.58)); n.position = Vector2(170, 30); p.add_child(n)
	var g := _lbl(18, "灵品 · 通灵 · 灵植", DIM); g.position = Vector2(172, 74); p.add_child(g)
	var s := _lbl(18, "已服过 3 次" if used else "从未服过", AMBER if used else GREEN); s.position = Vector2(172, 104); p.add_child(s)

	var l1 := _lbl(20, "功效", GOLD); l1.position = Vector2(28, 168); p.add_child(l1)
	var l1v := _lbl(18, "服下后神识清明十二时辰；每株只结三叶，百年一采。", TEXT); l1v.position = Vector2(28, 200); p.add_child(l1v)

	# 先天加成块
	var box := Panel.new(); box.position = Vector2(28, 250); box.size = Vector2(764, 210)
	var bb := StyleBoxFlat.new()
	bb.bg_color = Color(0.09, 0.10, 0.11)
	bb.border_color = GREEN if not used else Color(0.32, 0.32, 0.34)
	bb.set_border_width_all(2); bb.set_corner_radius_all(10)
	box.add_theme_stylebox_override("panel", bb); p.add_child(box)

	var t1 := _lbl(19, "先天加成", GOLD); t1.position = Vector2(20, 14); box.add_child(t1)
	if not used:
		var a := _lbl(22, "神识 +2（永久）", GREEN); a.position = Vector2(20, 52); box.add_child(a)
		var b := _lbl(16, "首服生效 · 用后此项标记为已取，同一物品再吃无效", DIM); b.position = Vector2(20, 86); box.add_child(b)
		var c := _lbl(16, "取后状态：本人物先天池 神识 2/10", Color(0.70, 0.70, 0.66)); c.position = Vector2(20, 116); box.add_child(c)
	else:
		var a := _lbl(22, "神识 +2　已取", Color(0.45, 0.45, 0.48)); a.position = Vector2(20, 52); box.add_child(a)
		var st := ColorRect.new(); st.color = Color(0.30, 0.30, 0.32); st.position = Vector2(200, 60); st.size = Vector2(340, 3); box.add_child(st)
		var b := _lbl(16, "该项先天已满，再服只给下面的临时增益", DIM); b.position = Vector2(20, 86); box.add_child(b)
		var c := _lbl(18, "本次可得：神清 · 6 时辰内悟性 +1", AMBER); c.position = Vector2(20, 120); box.add_child(c)
		var d := _lbl(15, "临时增益可叠同类，但不累加先天", DIM); d.position = Vector2(20, 152); box.add_child(d)

	var l4 := _lbl(20, "来处 / 价值", GOLD); l4.position = Vector2(28, 484); p.add_child(l4)
	var l4v := _lbl(18, "青岚宗后山茶园（百年一采）· 市价 120 灵石/叶", TEXT); l4v.position = Vector2(28, 516); p.add_child(l4v)

	var l5 := _lbl(18, "提示：先天池共六项 —— 根骨 / 神识 / 悟性 / 气运 / 寿元 / 灵根亲和", DIM)
	l5.position = Vector2(28, 570); p.add_child(l5)
	var tag := _lbl(17, "此物对你的先天：未取" if not used else "此物对你的先天：已取（只剩临时）",
		GREEN if not used else AMBER)
	tag.position = Vector2(28, 612); p.add_child(tag)

	var btn := Button.new(); btn.text = "  服  下  "; btn.position = Vector2(28, 668); btn.size = Vector2(190, 52)
	btn.add_theme_font_override("font", font); btn.add_theme_font_size_override("font_size", 22)
	p.add_child(btn)

func _lbl(sz: int, txt: String, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.text = txt
	return l
