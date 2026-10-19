extends Node2D

const ICONS := [
	["a_xuantian", "玄天斩", Color(0.55, 0.85, 1.0)],
	["b_zhenyue", "镇岳印", Color(1.0, 0.86, 0.62)],
	["c_wujiu", "无咎钟", Color(1.0, 0.80, 0.45)],
	["d_zhaodan", "照胆镜", Color(0.65, 1.0, 0.95)],
	["e_qingnang", "青囊灯", Color(1.0, 0.88, 0.55)],
	["f_jiuyou", "九幽伞", Color(0.72, 0.55, 1.0)],
	["g_gumu", "蛊母鼎", Color(0.62, 1.0, 0.60)],
	["h_chunqiu", "春秋笔", Color(0.90, 0.88, 1.0)],
	["i_jieyu", "解语琴", Color(1.0, 0.72, 0.85)],
	["j_buxizhou", "不系舟", Color(0.60, 0.85, 1.0)],
]

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.04, 0.055)
	bg.size = Vector2(1920, 1080)
	add_child(bg)
	var title := Label.new()
	title.text = "棱彩十件 · 84×84 像素 + 实时扫光/边缘辉光（Godot 着色器，非预渲染）"
	title.position = Vector2(52, 30)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88))
	add_child(title)
	var sh := load("res://relicfx.gdshader") as Shader
	for i in ICONS.size():
		var x := 92.0 + float(i % 5) * 360.0
		var y := 170.0 + float(int(i / 5)) * 430.0
		var holder := Node2D.new()
		holder.position = Vector2(x, y)
		add_child(holder)
		# 外圈辉光：同一张图放大 + 叠加混合
		var halo := Sprite2D.new()
		halo.texture = load("res://icons_relic84/%s.png" % ICONS[i][0])
		halo.scale = Vector2(1.22, 1.22)
		halo.position = Vector2(150, 150)
		var hm := CanvasItemMaterial.new()
		hm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		halo.material = hm
		halo.modulate = Color(ICONS[i][2].r, ICONS[i][2].g, ICONS[i][2].b, 0.16)
		holder.add_child(halo)
		# 主体
		var sp := Sprite2D.new()
		sp.texture = load("res://icons_relic84/%s.png" % ICONS[i][0])
		sp.scale = Vector2(3.4, 3.4)
		sp.position = Vector2(150, 150)
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("glow_color", Vector4(ICONS[i][2].r, ICONS[i][2].g, ICONS[i][2].b, 1.0))
		m.set_shader_parameter("sweep_speed", 0.30 + 0.03 * float(i))
		sp.material = m
		holder.add_child(sp)
		# 边框
		var frame := ColorRect.new()
		frame.color = Color(ICONS[i][2].r, ICONS[i][2].g, ICONS[i][2].b, 0.55)
		frame.position = Vector2(6, 6)
		frame.size = Vector2(300, 300)
		frame.show_behind_parent = true
		holder.add_child(frame)
		var inner := ColorRect.new()
		inner.color = Color(0.05, 0.055, 0.07)
		inner.position = Vector2(5, 5)
		inner.size = Vector2(290, 290)
		holder.add_child(inner)
		holder.move_child(frame, 0)
		holder.move_child(inner, 1)
		var nm := Label.new()
		nm.text = ICONS[i][1]
		nm.position = Vector2(6, 312)
		nm.add_theme_font_size_override("font_size", 30)
		nm.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86))
		holder.add_child(nm)
