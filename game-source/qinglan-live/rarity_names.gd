extends Control

var font: FontFile
var data: Dictionary
var t := 0.0
var glows: Array = []
var rainbow_chips: Array = []

func _ready() -> void:
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/rarity.json"))
	_build()
	set_process(true)

func _lbl(txt: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _tint(c: Color, i: int) -> Color:
	var v: float = [0.55, 0.70, 0.85, 1.0][i]
	return Color(min(1.0, c.r * v + 0.06), min(1.0, c.g * v + 0.06), min(1.0, c.b * v + 0.06))

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.038, 0.041, 0.048)
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	add_child(_face("品阶命名总表 · 七阶 × 四档", 34, Color(0.92, 0.88, 0.80), Vector2(60, 34)))
	add_child(_face("最高一档都叫「极品」；其余三档每阶各有专名。不写颜色字，只写「凡物·良造」这样的阶名 + 档名。", 21,
			Color(0.55, 0.55, 0.57), Vector2(60, 84)))

	var y := 140.0
	for gi in data["grades"].size():
		var g: Dictionary = data["grades"][gi]
		var c: Color = Color(g["color"][0], g["color"][1], g["color"][2])
		# 大阶名
		var nm := _face(String(g["name"]), 30, c, Vector2(60, y + 18))
		add_child(nm)
		add_child(_face("基础 ×%.2f" % float(g["base"]), 18, Color(0.52, 0.52, 0.54), Vector2(60, y + 58)))
		# 四档
		for ti in 4:
			var x := 320.0 + ti * 388.0
			var col := _tint(c, ti)
			var chip := Panel.new()
			chip.position = Vector2(x, y)
			chip.size = Vector2(364, 92)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.10, 0.105, 0.12)
			sb.border_color = col
			sb.set_border_width_all(1 + ti)
			sb.set_corner_radius_all(6)
			chip.add_theme_stylebox_override("panel", sb)
			add_child(chip)
			var txt: String = String(g["name"]) + "·" + String(g["tiers"][ti])
			chip.add_child(_face(txt, 26, col, Vector2(20, 16)))
			chip.add_child(_face("词条 ×%.2f" % float([1.00,1.18,1.40,1.70][ti]), 17,
					Color(0.55, 0.54, 0.53), Vector2(20, 56)))
			if gi == 6:
				rainbow_chips.append({"p": chip, "i": gi, "t": ti})
				for k in 6:
					var strip := ColorRect.new()
					strip.color = Color.from_hsv(k / 6.0, 0.72, 1.0)
					strip.position = Vector2(364.0 / 6.0 * k, 90)
					strip.size = Vector2(364.0 / 6.0 + 1, 4)
					strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
					chip.add_child(strip)
			if gi >= 2:
				var sweep := TextureRect.new()
				sweep.texture = _grad()
				sweep.size = Vector2(26, 92)
				sweep.modulate = Color(1, 1, 1, 0.0 if gi == 2 else (0.14 + 0.06 * ti))
				sweep.position = Vector2(-40, 0)
				var m := CanvasItemMaterial.new()
				m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
				sweep.material = m
				chip.add_child(sweep)
				glows.append({"n": sweep, "speed": 0.5 + 0.22 * float(gi), "ph": float(gi) * 1.7 + float(ti) * 0.6})
		y += 106.0

	# 底部：身份与动效
	var by := y + 14.0
	add_child(_face("万物品阶 · 身份", 26, Color(0.86, 0.72, 0.44), Vector2(60, by)))
	add_child(_face("皇子皇孙 最差 地品·载物（古人以紫为贵）　　帝王 最低 天品·天成，昏君靠国运加持，国衰跌阶　　宗门长老 玄品·通玄　　街边小贩 凡物·粗制",
			20, Color(0.78, 0.76, 0.72), Vector2(60, by + 38)))
	add_child(_face("动效 · 凡物/灵品 静态　　玄品 呼吸描边　　地品 单色流光　　天品 金光流动 + 外发光　　仙品 血光 + 粒子　　棱彩 七彩环流 + 光晕 + 粒子",
			20, Color(0.60, 0.59, 0.57), Vector2(60, by + 76)))
	add_child(_face("气运不可见；须修「堪舆 / 观气」类功法神通才开元素视野 —— 凡人所见止于风水地貌，看不见人身上的气数。",
			20, Color(0.52, 0.62, 0.58), Vector2(60, by + 112)))

func _face(txt: String, size: int, col: Color, pos: Vector2) -> Label:
	var l := _lbl(txt, size, col)
	l.position = pos
	return l

func _grad() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.5, Color(1, 1, 1, 1))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 64
	gt.height = 4
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	return gt

func _process(delta: float) -> void:
	t += delta
	var hue := fmod(t * 0.13, 1.0)
	for rc in rainbow_chips:
		var chip: Panel = rc["p"]
		var sb2: StyleBoxFlat = chip.get_theme_stylebox("panel").duplicate()
		var c := Color.from_hsv(fmod(hue + 0.22 * float(rc["t"]), 1.0), 0.72, 1.0)
		sb2.border_color = c
		sb2.shadow_color = Color(c.r, c.g, c.b, 0.45)
		sb2.shadow_size = 16
		chip.add_theme_stylebox_override("panel", sb2)
	for f in glows:
		var n: TextureRect = f["n"]
		var span := 420.0
		n.position = Vector2(fmod(t * float(f["speed"]) * 190.0 + float(f["ph"]) * 120.0, span) - 40.0, 0)
