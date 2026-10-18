extends Node

const WorldBuilder := preload("res://scripts/world.gd")
const UILayer := preload("res://scripts/ui.gd")

func _ready() -> void:
	var mode := "day"
	var user_args := OS.get_cmdline_user_args()
	for i in range(user_args.size()):
		if user_args[i] == "--mode" and i + 1 < user_args.size():
			mode = user_args[i + 1]
	var world := Node2D.new()
	world.name = "World"
	world.set_script(WorldBuilder)
	add_child(world)
	world.build(mode)

	_add_env()

	var ui := Control.new()
	ui.name = "Hud"
	ui.set_script(UILayer)
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	layer.add_child(ui)
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.build(mode)

func _add_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 1.0
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.92
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.02
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.16
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
