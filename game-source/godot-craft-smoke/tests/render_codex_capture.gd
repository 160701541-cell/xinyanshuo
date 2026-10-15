extends SceneTree
const CodexUI = preload("res://scripts/craft_codex_panel.gd")
func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	call_deferred("_capture")
func _capture() -> void:
	# Script-only launch can create a root Window without a texture target.
	# A dedicated 1280x720 SubViewport forces an actual GPU draw framebuffer.
	var frame_viewport := SubViewport.new()
	frame_viewport.name = "RealCraftCodexReviewViewport"
	frame_viewport.size = Vector2i(1280, 720)
	frame_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	frame_viewport.disable_3d = true
	root.add_child(frame_viewport)
	var ui: Control = CodexUI.new()
	ui.source_path = "res://data/material_graph.v1.json"
	frame_viewport.add_child(ui)
	ui.select_item("qing_roof_tile")
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var frame: Image = frame_viewport.get_texture().get_image()
	print("REAL_WINDOW_SIZE=",root.size, " VIEWPORT_SIZE=",frame_viewport.size,
		" CAPTURED_IMAGE_SIZE=",Vector2i(frame.get_width(),frame.get_height()) if frame != null else Vector2i.ZERO)
	if frame == null or frame.get_width() != 1280 or frame.get_height() != 720:
		printerr("BAD_GODOT_FRAME")
		quit(4)
		return
	var result: Error = frame.save_png("res://godot-craft-real-frame.png")
	if result != OK:
		printerr("FRAME_NOT_SAVED")
		quit(5)
		return
	print("GODOT_FRAME_REAL_1280_720_CAPTURED_DESKTOP_ONLY")
	ui.queue_free()
	quit(0)
