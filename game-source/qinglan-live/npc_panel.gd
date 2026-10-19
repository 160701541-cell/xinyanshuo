extends Control

const GOLD := Color(0.86, 0.72, 0.44)
const JADE := Color(0.52, 0.82, 0.74)
const RED := Color(0.80, 0.42, 0.36)
const INK := Color(0.06, 0.07, 0.09)
const PANEL := Color(0.10, 0.11, 0.14, 0.94)
const LINE := Color(0.28, 0.26, 0.22)
const TEXT := Color(0.90, 0.88, 0.83)
const DIM := Color(0.46, 0.45, 0.44)

var font: FontFile
var tier := 0   # 0 陌路 1 相识 2 相熟 3 知己 4 生死之交
var beheld := true
var chips: Array = []

# 档案：按交情分层解锁
const TIERS := ["陌路", "相识", "相熟", "知己", "生死之交"]
const NPC := {
	"name": "裴青玄", "title": "云游剑修 · 无门无派", "rank": "筑基三层",
	"basics": ["生辰 元祐十七年 霜降", "籍贯 北境·雁回镇", "现居 青岚宗外门客舍"],
	"look": "青衫负剑，左手小指缺一截。",
	"persona": ["寡言，答话短", "极守时辰，卯时必在溪边练剑", "厌恶别人碰他的剑鞘"],
	"roots": "五行杂灵根，土灵根略强（外显）",
	"real_roots": "实为剑骨·先天剑胚，被测灵石掩了",
	"timeline": [
		"元祐十七年 生于雁回镇铁匠家",
		"元祐二十九年 镇毁于妖潮，独活",
		"元祐三十一年 拾得断剑「霜行」",
		"元祐三十四年 入筑基，拒三门招揽",
		"元祐三十六年 至青岚宗，挂客籍",
	],
	"gear": ["霜行（断剑·法宝，缺锋）", "青布直裰（凡品）", "剑穗（旧，母亲所缝）", "—", "—", "—"],
	"stats": [["神识", 7], ["体魄", 6], ["身法", 9], ["悟性", 8], ["根骨", 7], ["机缘", 9]],
	"art": "《回风照雪》残篇 三式",
	"secret": "他在找当年引妖潮入镇的人，怀疑与青岚宗内门有关。",
	"observed": ["剑招《回风照雪·第二式》", "法宝「霜行」· 断锋", "土灵根·护体罡气"],
	"bond": "师徒 · 你受他指点过三式（记名，未行拜师礼）",
}

func _ready() -> void:
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	_build()

func _label(t: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _face(t: String, size: int, col: Color, pos: Vector2, dim := false) -> Label:
	var l := _label(t, size, col if not dim else DIM)
	l.position = pos
	if dim:
		l.modulate.a = 0.45
	return l

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.038, 0.045)
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	# 左：人物卡
	var left := Panel.new()
	left.position = Vector2(48, 48)
	left.size = Vector2(520, 984)
	left.add_theme_stylebox_override("panel", _style(PANEL, LINE))
	add_child(left)
	left.add_child(_face("人物志", 30, GOLD, Vector2(32, 26)))
	left.add_child(_face(NPC["name"], 52, TEXT, Vector2(32, 66)))
	left.add_child(_face(NPC["title"], 22, DIM, Vector2(32, 132)))
	left.add_child(_face("境界  " + NPC["rank"], 24, JADE, Vector2(32, 172)))

	var av := ColorRect.new()
	av.color = Color(0.16, 0.18, 0.22)
	av.position = Vector2(32, 216)
	av.size = Vector2(140, 170)
	left.add_child(av)
	left.add_child(_face("立绘", 22, DIM, Vector2(76, 288)))

	for i in 3:
		left.add_child(_face(NPC["basics"][i], 24, TEXT if tier >= 1 else DIM, Vector2(196, 224 + i * 40), tier < 1))
	left.add_child(_face("相貌  " + String(NPC["look"]), 22, DIM, Vector2(32, 404), tier < 1))
	left.add_child(_face("灵根  " + String(NPC["roots"]), 22, TEXT if tier >= 2 else DIM, Vector2(32, 446), tier < 2))

	# 交情条
	left.add_child(_face("交情 · " + TIERS[tier], 26, GOLD, Vector2(32, 520)))
	var bar := ColorRect.new()
	bar.color = Color(0.18, 0.17, 0.16)
	bar.position = Vector2(32, 560)
	bar.size = Vector2(456, 10)
	left.add_child(bar)
	var fill := ColorRect.new()
	fill.color = JADE
	fill.position = Vector2(32, 560)
	fill.size = Vector2(456.0 * (float(tier) + 1.0) / 5.0, 10)
	left.add_child(fill)
	left.add_child(_face("你与他相处 11 日 · 同饮 2 次 · 未曾并肩", 20, DIM, Vector2(32, 582)))

	# 交情切换（验收用）
	for i in 5:
		var b := Button.new()
		b.text = TIERS[i]
		b.position = Vector2(32 + i * 92, 640)
		b.size = Vector2(84, 48)
		b.add_theme_font_override("font", font)
		b.add_theme_font_size_override("font_size", 20)
		b.toggle_mode = true
		b.button_pressed = (i == tier)
		b.pressed.connect(_set_tier.bind(i))
		left.add_child(b)

	# 中：生平
	var mid := Panel.new()
	mid.position = Vector2(600, 48)
	mid.size = Vector2(700, 984)
	mid.add_theme_stylebox_override("panel", _style(PANEL, LINE))
	add_child(mid)
	mid.add_child(_face("生平", 30, GOLD, Vector2(32, 24)))
	var y := 84.0
	for i in NPC["timeline"].size():
		var show: bool = tier >= (1 if i < 2 else (2 if i < 4 else 4))
		mid.add_child(_face(String(NPC["timeline"][i]), 24, TEXT, Vector2(32, y), not show))
		y += 46.0
	# 战中所见：不靠交情，打出来的
	if beheld:
		mid.add_child(_face("战中所见", 26, JADE, Vector2(32, y + 16)))
		mid.add_child(_face("你与他交过手，这些是他自己亮出来的", 18, DIM, Vector2(32, y + 52)))
		var yy := y + 82.0
		for o in NPC["observed"]:
			mid.add_child(_face("· " + String(o), 22, TEXT, Vector2(40, yy)))
			yy += 36.0
		y = yy + 10.0
	# 缘法：师徒 / 主仆 / 道侣 / 仇
	mid.add_child(_face("缘法", 26, GOLD, Vector2(32, y + 16)))
	mid.add_child(_face(String(NPC["bond"]), 22, TEXT, Vector2(40, y + 56)))
	y += 104.0
	if tier >= 3:
		mid.add_child(_face("旁人评价", 26, GOLD, Vector2(32, y + 16)))
		y += 66.0
		for p in NPC["persona"]:
			mid.add_child(_face("· " + String(p), 22, TEXT, Vector2(40, y)))
			y += 38.0
	if tier >= 4:
		mid.add_child(_face("知其隐", 26, RED, Vector2(32, y + 16)))
		mid.add_child(_face(String(NPC["secret"]), 22, TEXT, Vector2(40, y + 56)))
		mid.add_child(_face("真灵根  " + String(NPC["real_roots"]), 22, TEXT, Vector2(40, y + 100)))

	# 右：装备与数值
	var right := Panel.new()
	right.position = Vector2(1320, 48)
	right.size = Vector2(552, 984)
	right.add_theme_stylebox_override("panel", _style(PANEL, LINE))
	add_child(right)
	right.add_child(_face("随身", 30, GOLD, Vector2(28, 24)))
	var gy := 88.0
	for i in NPC["gear"].size():
		var slot := Panel.new()
		slot.position = Vector2(28, gy)
		slot.size = Vector2(496, 56)
		slot.add_theme_stylebox_override("panel", _style(Color(0.13, 0.14, 0.17, 1), LINE))
		right.add_child(slot)
		var known: bool = tier >= 3 or String(NPC["gear"][i]) == "—"
		slot.add_child(_face(String(NPC["gear"][i]), 22, TEXT if known else DIM, Vector2(16, 14), not known))
		gy += 68.0

	right.add_child(_face("资质", 30, GOLD, Vector2(28, gy + 12)))
	gy += 66.0
	for i in NPC["stats"].size():
		var row: Array = NPC["stats"][i]
		right.add_child(_face(String(row[0]), 22, TEXT, Vector2(28, gy)))
		var track := ColorRect.new()
		track.color = Color(0.17, 0.17, 0.18)
		track.position = Vector2(120, gy + 8)
		track.size = Vector2(300, 12)
		right.add_child(track)
		var val := ColorRect.new()
		val.color = Color(0.42, 0.62, 0.86)
		val.position = Vector2(120, gy + 8)
		val.size = Vector2(300.0 * float(row[1]) / 10.0, 12)
		right.add_child(val)
		right.add_child(_face(str(row[1]), 22, GOLD, Vector2(436, gy)))
		gy += 44.0
	right.add_child(_face("功法  " + String(NPC["art"]), 22, TEXT, Vector2(28, gy + 18), tier < 3))

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	return sb

func _set_tier(i: int) -> void:
	tier = i
	for c in get_children():
		c.queue_free()
	_build()
