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
	_add_grade(mode)

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
	env.glow_intensity = 0.20
	env.glow_strength = 1.0
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.10
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.02
	env.adjustment_saturation = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _add_grade(mode: String) -> void:
	var sh: Shader = load("res://assets/shaders/grade.gdshader")
	if sh == null:
		return
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = sh
	if mode == "night":
		mat.set_shader_parameter("shadow_cool", 0.55)
		mat.set_shader_parameter("light_warm", 0.10)
		mat.set_shader_parameter("sat", 0.96)
	else:
		mat.set_shader_parameter("shadow_cool", 0.34)
		mat.set_shader_parameter("light_warm", 0.14)
		mat.set_shader_parameter("sat", 1.02)
	rect.material = mat
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	layer.add_child(rect)
