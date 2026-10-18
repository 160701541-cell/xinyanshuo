extends Node2D

## 苍岚 2.5D 模板 · 世界层
## 结构：手绘场景底板（带 tilt-shift 景深）+ 前景虚化带 + 体积光/加湿光斑 + 精灵角色 + 落叶浮尘

const PLATE_DIR := "res://assets/plate/"
const SPRITE_DIR := "res://assets/sprite/"

const CANVAS_H := 260.0
const CHAR_H := 236.0
const FEET_IN_CANVAS := 252.0

var plate_tex: Texture2D
var plate_sprite: Sprite2D
var mode_now := "day"

func build(mode: String) -> void:
	mode_now = mode
	var file := _plate_file(mode)
	plate_tex = _load_tex(file)
	if plate_tex == null:
		plate_tex = _fallback_plate(mode)
	_add_plate()
	if mode == "day":
		_plaque()
	_add_glow(mode)
	_ground_props(mode)
	_add_shadows()
	_add_actors(mode)
	_add_fx(mode)

func _plate_file(mode: String) -> String:
	if mode == "night":
		return PLATE_DIR + "plate03_night_lantern_street.png"
	if mode == "bamboo":
		return PLATE_DIR + "plate02_bamboo_dusk.png"
	return PLATE_DIR + "plate01_shanmen_day.png"

func _load_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null:
		return tex
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _fallback_plate(mode: String) -> Texture2D:
	var g := Gradient.new()
	if mode == "night":
		g.colors = PackedColorArray([Color(0.05, 0.08, 0.16), Color(0.10, 0.14, 0.22), Color(0.16, 0.14, 0.12)])
	else:
		g.colors = PackedColorArray([Color(0.55, 0.68, 0.74), Color(0.78, 0.80, 0.66), Color(0.52, 0.45, 0.30)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_LINEAR
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 1024
	gt.height = 576
	return gt

func _add_plate() -> void:
	plate_sprite = Sprite2D.new()
	plate_sprite.name = "Plate"
	plate_sprite.texture = plate_tex
	plate_sprite.centered = true
	plate_sprite.position = Vector2(640, 360)
	var tw := float(plate_tex.get_width())
	var th := float(plate_tex.get_height())
	var s := maxf(1280.0 / tw, 720.0 / th) * 1.02
	plate_sprite.scale = Vector2(s, s)
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float focus_y = 0.60;
uniform float focus_half = 0.20;
uniform float near_band = 0.34;
uniform float max_lod = 3.0;
void fragment() {
	vec2 uv = UV;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		COLOR = texture(TEXTURE, uv);
	} else {
		float d = abs(uv.y - focus_y);
		float far_blur = smoothstep(focus_half, focus_half + 0.26, d) ;
		float near = 1.0 - smoothstep(near_band, 1.0, uv.y);
		float blur = clamp(max(far_blur * 1.6, near * 1.9), 0.0, max_lod);
		vec4 c = texture(TEXTURE, uv, blur);
		COLOR = c;
	}
}
"""
	mat.shader = sh
	plate_sprite.material = mat
	add_child(plate_sprite)

func _plaque() -> void:
	var outer := ColorRect.new()
	outer.color = Color(0.62, 0.48, 0.22, 0.92)
	outer.position = Vector2(566, 44)
	outer.size = Vector2(140, 46)
	outer.z_index = 12
	add_child(outer)
	var rect := ColorRect.new()
	rect.color = Color(0.102, 0.078, 0.056, 0.96)
	rect.position = Vector2(570, 48)
	rect.size = Vector2(132, 38)
	rect.z_index = 13
	add_child(rect)
	var lbl := Label.new()
	lbl.text = "青岚宗"
	var f: Font = load("res://assets/fonts/serif_bold.ttc")
	if f != null:
		lbl.add_theme_font_override("font", f)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(0.93, 0.80, 0.46))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = rect.position + Vector2(0, 1)
	lbl.size = rect.size
	lbl.z_index = 14
	add_child(lbl)

func _radial_tex(inner: Color, outer: Color) -> Texture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([inner, outer])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 256
	gt.height = 256
	return gt

func _glow_at(pos: Vector2, radius: float, col: Color) -> void:
	var s := Sprite2D.new()
	s.texture = _radial_tex(Color(col.r, col.g, col.b, 0.30), Color(col.r, col.g, col.b, 0.0))
	s.position = pos
	s.scale = Vector2(radius / 128.0, radius / 128.0)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = m
	s.z_index = 5
	add_child(s)

func _add_glow(mode: String) -> void:
	if mode == "night":
		_glow_at(Vector2(320, 300), 260, Color(1.0, 0.55, 0.22))
		_glow_at(Vector2(980, 250), 220, Color(1.0, 0.48, 0.18))
		_glow_at(Vector2(660, 560), 300, Color(0.85, 0.35, 0.15))
	else:
		_glow_at(Vector2(300, 120), 420, Color(1.0, 0.82, 0.52))
		_glow_at(Vector2(980, 180), 300, Color(1.0, 0.74, 0.42))
		_glow_at(Vector2(640, 470), 380, Color(0.95, 0.78, 0.48))

func _ground_props(mode: String) -> void:
	# 道具层：等自产道具到货后按真实坐标摆放；缺失时不画。
	var props := [
		{"file": "prop02_market_stall", "pos": Vector2(196, 470), "scale": 0.34},
		{"file": "prop03_incense_burner", "pos": Vector2(1046, 512), "scale": 0.24},
		{"file": "prop01_stone_lantern", "pos": Vector2(392, 552), "scale": 0.30},
	]
	for p in props:
		var path: String = PLATE_DIR + String(p["file"]) + ".png"
		var tex := _load_tex(path)
		if tex == null:
			continue
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.position = p["pos"]
		var sc: float = p["scale"]
		s.scale = Vector2(sc, sc)
		add_child(s)

func _frames_for(npc: int) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	sf.add_animation("idle")
	sf.set_animation_speed("idle", 8.0)
	sf.set_animation_loop("idle", true)
	for i in range(6):
		var p := SPRITE_DIR + "npc%d_canvas_c%d.png" % [npc, i]
		if ResourceLoader.exists(p):
			sf.add_frame("idle", load(p))
	return sf

var _shadow_tex: Texture2D

func _shadow() -> Sprite2D:
	if _shadow_tex == null:
		_shadow_tex = _radial_tex(Color(0.0, 0.0, 0.0, 0.55), Color(0.0, 0.0, 0.0, 0.0))
	var s := Sprite2D.new()
	s.texture = _shadow_tex
	return s

func _add_shadows() -> void:
	var spots := [Vector2(1000, 464), Vector2(846, 504), Vector2(520, 602), Vector2(646, 648)]
	for p in spots:
		var sh := _shadow()
		sh.position = p
		sh.scale = Vector2(0.34, 0.11)
		sh.z_index = 2
		add_child(sh)

func _add_actors(mode: String) -> void:
	var cast := [
		{"npc": 0, "feet": Vector2(1000, 462), "scale": 0.19},
		{"npc": 1, "feet": Vector2(846, 500), "scale": 0.24},
		{"npc": 3, "feet": Vector2(520, 596), "scale": 0.36},
		{"npc": 4, "feet": Vector2(646, 640), "scale": 0.42},
	]
	var sort_root := Node2D.new()
	sort_root.name = "Actors"
	sort_root.y_sort_enabled = true
	add_child(sort_root)
	for c in cast:
		var a := AnimatedSprite2D.new()
		a.sprite_frames = _frames_for(int(c["npc"]))
		a.animation = "idle"
		var sc: float = c["scale"]
		a.scale = Vector2(sc, sc)
		var feet: Vector2 = c["feet"]
		a.position = Vector2(feet.x, feet.y - (CANVAS_H * 0.5 - (CANVAS_H - FEET_IN_CANVAS)) * sc)
		a.play("idle")
		a.z_index = 6
		a.modulate = Color(1.14, 1.06, 0.96)
		sort_root.add_child(a)

func _add_fx(mode: String) -> void:
	var leaves := CPUParticles2D.new()
	leaves.name = "Leaves"
	leaves.amount = 26
	leaves.lifetime = 7.0
	leaves.preprocess = 4.0
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.emission_rect_extents = Vector2(700, 40)
	leaves.position = Vector2(640, 30)
	leaves.direction = Vector2(0.35, 1.0)
	leaves.spread = 18.0
	leaves.gravity = Vector2(14, 26)
	leaves.initial_velocity_min = 18.0
	leaves.initial_velocity_max = 42.0
	leaves.angular_velocity_min = -90.0
	leaves.angular_velocity_max = 90.0
	leaves.scale_amount_min = 0.035
	leaves.scale_amount_max = 0.075
	leaves.color = Color(0.96, 0.72, 0.26, 0.92) if mode != "night" else Color(0.85, 0.55, 0.25, 0.7)
	var leaf_tex := _radial_tex(Color(1, 1, 1, 1), Color(1, 1, 1, 0.0))
	leaves.texture = leaf_tex
	leaves.z_index = 9
	add_child(leaves)

	var dust := CPUParticles2D.new()
	dust.name = "Dust"
	dust.amount = 70
	dust.lifetime = 9.0
	dust.preprocess = 6.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(660, 300)
	dust.position = Vector2(640, 420)
	dust.direction = Vector2(0.15, -1.0)
	dust.spread = 40.0
	dust.gravity = Vector2(2, -3)
	dust.initial_velocity_min = 3.0
	dust.initial_velocity_max = 12.0
	dust.scale_amount_min = 0.012
	dust.scale_amount_max = 0.03
	dust.color = Color(1.0, 0.94, 0.78, 0.35)
	dust.texture = _radial_tex(Color(1, 1, 1, 1), Color(1, 1, 1, 0.0))
	dust.z_index = 10
	var dm := CanvasItemMaterial.new()
	dm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	dust.material = dm
	add_child(dust)
