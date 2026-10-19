extends Control

const TIERS := [
	{"n": "白 · 凡品", "c": Color(0.78, 0.78, 0.76), "b": 1, "glow": 0.0, "flow": 0.0, "icon": "sword"},
	{"n": "绿 · 下品", "c": Color(0.45, 0.80, 0.45), "b": 2, "glow": 0.0, "flow": 0.0, "icon": "herb"},
	{"n": "蓝 · 中品", "c": Color(0.40, 0.66, 0.94), "b": 2, "glow": 0.05, "flow": 0.0, "icon": "slip"},
	{"n": "紫 · 上品", "c": Color(0.66, 0.46, 0.90), "b": 2, "glow": 0.10, "flow": 0.0, "icon": "talis"},
	{"n": "金四 · 淡金", "c": Color(0.78, 0.68, 0.46), "b": 3, "glow": 0.12, "flow": 0.18, "icon": "ore"},
	{"n": "金三 · 赤金", "c": Color(0.86, 0.70, 0.36), "b": 3, "glow": 0.16, "flow": 0.28, "icon": "bell"},
	{"n": "金二 · 足金", "c": Color(0.95, 0.74, 0.26), "b": 3, "glow": 0.22, "flow": 0.40, "icon": "ring"},
	{"n": "金一 · 金黄", "c": Color(1.00, 0.78, 0.16), "b": 4, "glow": 0.30, "flow": 0.55, "icon": "gourd"},
	{"n": "红 · 极品", "c": Color(0.92, 0.32, 0.30), "b": 4, "glow": 0.34, "flow": 0.60, "icon": "pill"},
	{"n": "棱彩 · 绝世", "c": Color(0.86, 0.92, 1.00), "b": 5, "glow": 0.42, "flow": 0.85, "rainbow": true, "icon": "pearl"},
]

var font: FontFile
var t := 0.0
var flows: Array = []

func _ready() -> void:
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	_build()
	set_process(true)

func _lbl(txt: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.043, 0.05)
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var head := _lbl("品阶 · 十档", 34, Color(0.90, 0.86, 0.78))
	head.position = Vector2(64, 40)
	add_child(head)
	var sub := _lbl("金分四档（金四→金一），红之上为棱彩；金起有流动光，棱彩七彩流转并外发光", 22, Color(0.55, 0.55, 0.56))
	sub.position = Vector2(64, 92)
	add_child(sub)

	var cw := 336.0
	var ch := 420.0
	for i in TIERS.size():
		var d: Dictionary = TIERS[i]
		var col: Vector2 = Vector2(64 + (i % 5) * (cw + 24), 160 + int(i / 5) * (ch + 26))
		var card := Panel.new()
		card.position = col
		card.size = Vector2(cw, ch)
		card.add_theme_stylebox_override("panel", _box(Color(0.10, 0.11, 0.13), d["c"], float(d["b"]), 0.9 if d["glow"] == 0.0 else 1.0))
		add_child(card)

		# 内层发光
		if float(d["glow"]) > 0.0:
			var g := Panel.new()
			g.position = col + Vector2(-6, -6)
			g.size = Vector2(cw + 12, ch + 12)
			g.add_theme_stylebox_override("panel", _glow(d["c"], float(d["glow"])))
			g.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(g)
			move_child(g, card.get_index())

		# 图标
		var holder := Control.new()
		holder.position = col + Vector2(cw * 0.5 - 96, 34)
		holder.size = Vector2(192, 192)
		holder.clip_contents = true
		add_child(holder)
		var icon := TextureRect.new()
		icon.texture = load("res://icons/%s.png" % String(d["icon"]))
		icon.size = Vector2(192, 192)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		holder.add_child(icon)

		# 流动光带
		if float(d["flow"]) > 0.0:
			var flow := TextureRect.new()
			flow.texture = _gradient()
			flow.size = Vector2(30, 240)
			flow.rotation = -0.38
			flow.modulate = Color(1, 1, 1, float(d["flow"]) * 0.22)
			flow.position = Vector2(-90, -30)
			var mat := CanvasItemMaterial.new()
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			flow.material = mat
			holder.add_child(flow)
			flows.append({"node": flow, "speed": 0.35 + float(d["flow"]), "phase": float(i) * 0.37})

		if d.has("rainbow"):
			_rainbow_edges(col, Vector2(cw, ch))
			var halo := Panel.new()
			halo.position = col + Vector2(cw * 0.5 - 108, 22)
			halo.size = Vector2(216, 216)
			var hb := StyleBoxFlat.new()
			hb.bg_color = Color(0, 0, 0, 0)
			hb.border_color = Color(0.95, 0.98, 1.0, 0.75)
			hb.set_border_width_all(3)
			hb.set_corner_radius_all(108)
			hb.shadow_color = Color(0.75, 0.85, 1.0, 0.55)
			hb.shadow_size = 30
			halo.add_theme_stylebox_override("panel", hb)
			halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(halo)
		var nm := _lbl(String(d["n"]), 26, d["c"])
		nm.position = col + Vector2(22, 250)
		add_child(nm)
		var kk := _lbl("颜色强度 / 描边 %dpx / 流光 %d%%" % [int(d["b"]), int(float(d["flow"]) * 100.0)], 19,
				Color(0.55, 0.55, 0.57))
		kk.position = col + Vector2(22, 292)
		add_child(kk)
		var det := _lbl(_detail(i), 18, Color(0.62, 0.61, 0.60))
		det.position = col + Vector2(22, 326)
		det.size = Vector2(cw - 44, 80)
		det.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(det)

func _rainbow_edges(pos: Vector2, sz: Vector2) -> void:
	var cols := [Color(1,0.35,0.35), Color(1,0.75,0.30), Color(0.95,0.95,0.35), Color(0.40,0.92,0.55), Color(0.38,0.72,1.0), Color(0.72,0.45,1.0)]
	for i in 6:
		var strip := ColorRect.new()
		strip.color = cols[i]
		strip.position = pos + Vector2(sz.x / 6.0 * i, -5)
		strip.size = Vector2(sz.x / 6.0 + 1, 5)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(strip)
		var b := ColorRect.new()
		b.color = cols[5 - i]
		b.position = pos + Vector2(sz.x / 6.0 * i, sz.y)
		b.size = Vector2(sz.x / 6.0 + 1, 5)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(b)

func _detail(i: int) -> String:
	var d := [
		"铁匠铺里随手拿的，刃口有豁。",
		"山货，识货的人不多。",
		"坊市常见，修士入门配发。",
		"内门弟子才有的东西。",
		"泛金，远看像铜；城里人叫它“半金”。",
		"真金了，灯下会晃眼。",
		"压手，器物有分量。",
		"金得发烫，夜里能照亮一张桌子。",
		"血色，据说淬过妖丹。",
		"光在珠里流，看一眼要缓半天。",
	]
	return d[i]

func _box(fill: Color, border: Color, w: float, alpha: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = Color(border.r, border.g, border.b, alpha)
	sb.set_border_width_all(int(w))
	sb.set_corner_radius_all(6)
	return sb

func _glow(c: Color, a: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(c.r, c.g, c.b, a * 0.55)
	sb.set_border_width_all(10)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(c.r, c.g, c.b, a * 0.45)
	sb.shadow_size = 26
	return sb

func _gradient() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.5, Color(1, 1, 1, 1))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 128
	gt.height = 8
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	return gt

func _process(delta: float) -> void:
	t += delta
	for f in flows:
		var n: TextureRect = f["node"]
		var span := 460.0
		var x: float = fmod(t * float(f["speed"]) * 220.0 + float(f["phase"]) * span, span) - 160.0
		n.position = Vector2(x, -40)
