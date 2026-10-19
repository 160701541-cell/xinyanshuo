extends Control
func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("5C6674")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var hud: Control = load("res://ui/hud.gd").new()
	add_child(hud)
	await get_tree().create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://out/ui_hud.png")
	print("SHOT res://out/ui_hud.png ", img.get_width(), "x", img.get_height())
	get_tree().quit()
