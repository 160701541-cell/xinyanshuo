extends Control

const GRADE_COL := {
	"common": Color(0.80, 0.80, 0.78), "spirit": Color(0.46, 0.82, 0.46),
	"mystic": Color(0.42, 0.68, 0.96), "earth": Color(0.70, 0.48, 0.94),
	"heaven": Color(0.98, 0.76, 0.28), "immortal": Color(0.94, 0.34, 0.32),
	"divine": Color(0.92, 0.90, 1.00)
}
const AFFIX_MULT := [1.00, 1.18, 1.40, 1.70]
const GRADE := {
	"common": {"n": "凡物", "base": 1.00, "tiers": ["粗制", "精工", "良造", "极品"]},
	"spirit": {"n": "灵品", "base": 1.35, "tiers": ["蕴灵", "凝灵", "通灵", "极品"]},
	"mystic": {"n": "玄品", "base": 1.80, "tiers": ["铭玄", "玄铸", "通玄", "极品"]},
	"earth": {"n": "地品", "base": 2.40, "tiers": ["镇岳", "载物", "地藏", "极品"]},
	"heaven": {"n": "天品", "base": 3.20, "tiers": ["天工", "造化", "天成", "极品"]},
	"immortal": {"n": "仙品", "base": 4.20, "tiers": ["蜕凡", "登仙", "谪仙", "极品"]},
	"divine": {"n": "棱彩", "base": 5.60, "tiers": ["初彩", "华彩", "炫彩", "极品"]}
}

var font: FontFile

func _ready() -> void:
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	_build()

func _lbl(txt: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _at(txt: String, size: int, col: Color, pos: Vector2) -> Label:
	var l := _lbl(txt, size, col)
	l.position = pos
	return l

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.038, 0.041, 0.048)
	bg.size = Vector2(1920, 1080)
	add_child(bg)
	add_child(_at("物品卡 · 同一词条「锋锐」，三个品阶", 32, Color(0.92, 0.88, 0.80), Vector2(56, 30)))
	add_child(_at("基础 = 基数 × 阶系数；词条 = 基数 × 档系数。凡物·极品的词条能压过灵品·通灵，但基础攻击仍被阶锁住。",
			20, Color(0.55, 0.55, 0.57), Vector2(56, 76)))

	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items_v2.json"))
	var items: Array = data["items"]
	for i in items.size():
		_card(items[i], Vector2(56 + i * 616, 132))

func _card(it: Dictionary, pos: Vector2) -> void:
	var g: Dictionary = GRADE[String(it["grade"])]
	var c: Color = GRADE_COL[String(it["grade"])]
	var ti: int = int(it["tier"])
	var base_mul: float = float(g["base"])
	var aff_mul: float = AFFIX_MULT[ti]
	var tier_name: String = g["tiers"][ti]

	var card := Panel.new()
	card.position = pos
	card.size = Vector2(584, 880)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.095, 0.10, 0.115)
	sb.border_color = c
	sb.set_border_width_all(2 + ti)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(c.r, c.g, c.b, 0.35 if ti >= 3 else 0.10)
	sb.shadow_size = 22 if ti >= 3 else 10
	card.add_theme_stylebox_override("panel", sb)
	add_child(card)

	# 图标（立绘位）
	var icon := TextureRect.new()
	icon.texture = load("res://icons/%s.png" % String(it["icon"]))
	icon.position = Vector2(180, 26)
	icon.size = Vector2(224, 224)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(icon)

	card.add_child(_at(String(it["name"]), 40, c, Vector2(28, 258)))
	card.add_child(_at(String(g["n"]) + "·" + tier_name, 24, c, Vector2(28, 308)))
	card.add_child(_at(String(it["type"]), 19, Color(0.55, 0.55, 0.57), Vector2(28, 342)))
	card.add_child(_at(String(it["desc"]), 19, Color(0.72, 0.71, 0.68), Vector2(28, 376)))

	var y := 418.0
	card.add_child(_at("基础", 22, Color(0.86, 0.72, 0.44), Vector2(28, y)))
	y += 34.0
	for k in it["base"].keys():
		var raw: float = float(it["base"][k])
		var fin: float = round(raw * base_mul)
		card.add_child(_at(String(k), 20, Color(0.70, 0.69, 0.66), Vector2(36, y)))
		card.add_child(_at("%d → %d" % [int(raw), int(fin)], 20, Color(0.92, 0.90, 0.86), Vector2(200, y)))
		card.add_child(_at("×%.2f" % base_mul, 17, Color(0.48, 0.48, 0.50), Vector2(340, y)))
		y += 32.0

	y += 10.0
	card.add_child(_at("词条", 22, Color(0.86, 0.72, 0.44), Vector2(28, y)))
	y += 34.0
	for a in it["affixes"]:
		var raw2: float = float(a["v"])
		var fin2: float = round(raw2 * aff_mul)
		var txt: String = String(a["d"]).replace("%%", "%").replace("{v}", str(int(fin2)))
		card.add_child(_at(String(a["k"]), 20, Color(0.52, 0.80, 0.74), Vector2(36, y)))
		card.add_child(_at("%d → %d" % [int(raw2), int(fin2)], 20, Color(0.92, 0.90, 0.86), Vector2(200, y)))
		card.add_child(_at(txt, 17, Color(0.60, 0.72, 0.70), Vector2(340, y)))
		y += 32.0

	y += 12.0
	card.add_child(_at("来历", 22, Color(0.86, 0.72, 0.44), Vector2(28, y)))
	card.add_child(_at(String(it["origin"]), 19, Color(0.74, 0.73, 0.70), Vector2(36, y + 34)))
	y += 74.0
	var cr: Dictionary = it["craft"]
	card.add_child(_at("制作", 22, Color(0.86, 0.72, 0.44), Vector2(28, y)))
	card.add_child(_at("%s · %s" % [cr["by"], cr["year"]], 18, Color(0.74, 0.73, 0.70), Vector2(36, y + 32)))
	card.add_child(_at("材料 " + ", ".join(PackedStringArray(cr["mats"])), 18, Color(0.66, 0.65, 0.62), Vector2(36, y + 60)))
	var note := _at(String(cr["note"]), 17, Color(0.60, 0.59, 0.56), Vector2(36, y + 88))
	note.size = Vector2(512, 80)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(note)
