extends CanvasLayer
# 横屏手游 HUD：虚拟摇杆改成点地移动，界面尽量薄

# 严格取 ART_DIRECTION.md 调色板
const GOLD := Color(0.910, 0.702, 0.231)   # #E8B33B
const TEXT := Color(0.937, 0.914, 0.863)   # #EFE9DC 宣纸
const INK  := Color(0.078, 0.086, 0.102)   # #14161A
const PAPER := Color(0.937, 0.914, 0.863)
const CINNABAR := Color(0.753, 0.224, 0.169)
const DIM := Color(0.35, 0.35, 0.36)
const JADE := Color(0.341, 0.780, 0.639)   # #57C7A3

var font: FontFile
var root: Control
var world: Node3D
var hint: Label
var modal: Control

func setup(w: Node3D) -> void:
	world = w
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_avatar_card()
	_minimap()
	_actions()
	hint = _lbl("点地面移动 · 双击屏幕御剑", 24, DIM)
	hint.position = Vector2(760, 1012)
	root.add_child(hint)
	var t := create_tween()
	t.tween_interval(4.0)
	t.tween_property(hint, "modulate:a", 0.0, 1.2)

func _lbl(t: String, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

func _round_panel(pos: Vector2, size: Vector2, col: Color, radius: int) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(mini(radius, 4))
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.75)
	p.add_theme_stylebox_override("panel", sb)
	return p

func _avatar_card() -> void:
	var p := _round_panel(Vector2(28, 24), Vector2(384, 96), PAPER, 2)
	root.add_child(p)
	var face := _round_panel(Vector2(10, 10), Vector2(76, 76), Color(0.106, 0.369, 0.388), 2)
	p.add_child(face)
	var n := _lbl("陆青崖", 30, INK)
	n.position = Vector2(100, 8)
	p.add_child(n)
	var r := _lbl("炼气七层 · 青岚宗外门", 20, DIM)
	r.position = Vector2(100, 46)
	p.add_child(r)
	var bar_bg := _round_panel(Vector2(100, 70), Vector2(264, 10), Color(0.2, 0.2, 0.22, 0.9), 5)
	p.add_child(bar_bg)
	var bar := _round_panel(Vector2(100, 70), Vector2(168, 10), JADE, 5)
	p.add_child(bar)

func _minimap() -> void:
	var mm := MiniMap.new()
	mm.world = world
	mm.size = Vector2(190, 190)
	mm.position = Vector2(1702, 24)
	mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mm.font = font
	root.add_child(mm)

func _actions() -> void:
	var labels := ["御剑", "打坐", "地图"]
	var i := 0
	for t in labels:
		var b := Button.new()
		b.text = str(t)
		b.add_theme_font_override("font", font)
		b.add_theme_font_size_override("font_size", 26)
		b.add_theme_color_override("font_color", INK)
		var sb := StyleBoxFlat.new()
		sb.bg_color = PAPER
		sb.set_corner_radius_all(3)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.86, 0.73, 0.45, 0.5)
		b.add_theme_stylebox_override("normal", sb)
		var sb2: StyleBoxFlat = sb.duplicate()
		sb2.bg_color = CINNABAR
		b.add_theme_stylebox_override("pressed", sb2)
		b.size = Vector2(88, 88)
		b.position = Vector2(1760, 700 + i * 100)
		if str(t) == "御剑":
			b.pressed.connect(func(): world.toggle_fly(); _say("御剑 · 起" if world.flying else "落地"))
		elif str(t) == "打坐":
			b.pressed.connect(func(): _say("打坐：灵力恢复 +2/秒"))
		else:
			b.pressed.connect(func(): _say("打开地图（M1）"))
		root.add_child(b)
		i += 1

func _say(msg: String) -> void:
	hint.text = msg
	hint.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.6)
	t.tween_property(hint, "modulate:a", 0.0, 0.8)

class MiniMap:
	extends Control
	var world: Node3D
	var font: FontFile
	func _draw() -> void:
		if world == null:
			return
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		draw_circle(c, r, Color(0.05, 0.07, 0.09, 0.78))
		draw_arc(c, r - 1, 0, TAU, 64, Color(0.86, 0.73, 0.45, 0.65), 2.0)
		var px: float = world.player.position.x
		var pz: float = world.player.position.z
		var scale := 190.0 / 2600.0
		for p in world.PEAKS:
			var dx: float = (float(p[0]) - px) * scale
			var dz: float = (float(p[1]) - pz) * scale
			if Vector2(dx, dz).length() > r - 12.0:
				continue
			draw_circle(c + Vector2(dx, dz), 5.0, Color(0.86, 0.73, 0.45, 0.9))
		draw_circle(c, 5.0, Color(0.55, 0.95, 0.85))
