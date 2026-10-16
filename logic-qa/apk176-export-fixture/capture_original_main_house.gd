extends SceneTree
## Genuine Godot-rendered visual evidence from the original APK176 Main
## plus its exact same-game rev177 candidate PCK. Not a phone screenshot.
var scene: Node

func _fail(reason: String, code: int) -> void:
	printerr("FAIL_REAL_APK176_SCENE_CAPTURE ", reason)
	quit(code)

func _initialize() -> void:
	call_deferred("_capture")

func _save_frame(filename: String) -> bool:
	var dir := OS.get_environment("CANGLAN_SCREENSHOT_DIR")
	if dir.is_empty():
		return false
	var image := get_root().get_texture().get_image()
	if image == null or image.is_empty():
		return false
	if image.get_width() < 800 or image.get_height() < 480:
		printerr("Screenshot viewport too small ", image.get_size())
		return false
	var outpath := dir.path_join(filename)
	var error: Error = image.save_png(outpath)
	if error != OK:
		printerr("PNG capture failed ", outpath, " error=", error)
		return false
	print("CANG LAN_GENUINE_GODOT_FRAME ".replace(" ", ""), filename,
		" size=", image.get_width(), "x",image.get_height())
	return true

func _capture() -> void:
	var output := OS.get_environment("CANGLAN_SCREENSHOT_DIR")
	var candidate := OS.get_environment("CANGLAN_QA_PCK_PATH")
	if output.is_empty() or candidate.is_empty() or not FileAccess.file_exists(candidate):
		_fail("missing_output_or_candidate", 2)
		return
	if not ProjectSettings.load_resource_pack(candidate, true):
		_fail("candidate_did_not_mount", 3)
		return
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_fail("real_main_failed_to_load", 4)
		return
	scene = packed.instantiate()
	get_root().add_child(scene)
	var overlay: Node = scene.get_node_or_null("HD2DArtAcceptance")
	if overlay == null or overlay._house_portal == null:
		_fail("real_game_house_controller_not_instantiated", 5)
		return
	if not overlay._house_portal._outside_image_present or not overlay._house_portal._inside_image_present:
		_fail("real_game_missing_worldx_room_art", 6)
		return
	for i in range(10):
		await process_frame
	if not _save_frame("real_original_apk176_courtyard_outside.png"):
		_fail("outdoor_screenshot_failed", 7)
		return
	overlay._house_portal.enter_building()
	if overlay.art_world.visible:
		_fail("outdoor_world_and_NPCs_visible_while_indoors", 10)
		return
	if not overlay._house_portal._room.visible:
		_fail("indoor_scene_not_visible_after_entry", 11)
		return
	for i in range(10):
		await process_frame
	if not _save_frame("real_original_apk176_house_inside.png"):
		_fail("indoor_screenshot_failed", 8)
		return
	overlay._house_portal.exit_building()
	if overlay._house_portal.inside:
		_fail("failed_to_return_to_original_world", 9)
		return
	print("PASS_REAL_APK176_WORLDX_GAMEPLAY_SCREENSHOTS_RENDERED")
	quit(0)
