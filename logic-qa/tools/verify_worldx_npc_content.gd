extends SceneTree
## Validate WorldX game content INSIDE the exact PCK, without needing the APK's
## private compiled game class registry. This test is independent of 3D main QA.
func _initialize() -> void:
	var pck := OS.get_environment("CANGLAN_QA_PCK_PATH")
	if pck.is_empty() or not FileAccess.file_exists(pck):
		printerr("FAIL_WORLDX_CONTENT: no candidate PCK")
		quit(2)
		return
	if not ProjectSettings.load_resource_pack(pck, true):
		printerr("FAIL_WORLDX_CONTENT: cannot mount real PCK")
		quit(3)
		return
	var maps := 0
	for index in range(8):
		var name := "res://hd2d/worldx/worldx_%03d.png" % index
		if not FileAccess.file_exists(name):
			continue
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(name)) != OK:
			printerr("FAIL_WORLDX_CONTENT: raster PNG invalid ",name)
			quit(4)
			return
		if image.get_width() < 256 or image.get_height() < 256:
			printerr("FAIL_WORLDX_CONTENT: raster too small ",name)
			quit(5)
			return
		maps += 1
	var manifest_path := "res://hd2d/worldx/npcs/npcs.json"
	if not FileAccess.file_exists(manifest_path):
		printerr("FAIL_WORLDX_CONTENT: no 6-NPC metadata")
		quit(6)
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not (data is Dictionary):
		printerr("FAIL_WORLDX_CONTENT: malformed NPC metadata")
		quit(7)
		return
	var characters: Array = data.get("characters",[])
	if characters.size() < 5:
		printerr("FAIL_WORLDX_CONTENT: NPC sprite batch incomplete")
		quit(8)
		return
	var npc_script: Script = load("res://scripts/hd2d_worldx_npcs.gd")
	if npc_script == null:
		printerr("FAIL_WORLDX_CONTENT: NPC runtime script invalid")
		quit(9)
		return
	var controller: Node2D = npc_script.new()
	get_root().add_child(controller)
	await process_frame
	if controller.actors.size() < 5:
		printerr("FAIL_WORLDX_CONTENT: sprites did not instantiate")
		quit(10)
		return
	var total_frames := 0
	for actor in controller.actors:
		if not actor.sprite_frames.has_animation("walk-down"):
			printerr("FAIL_WORLDX_CONTENT: walk-down missing")
			quit(11)
			return
		if actor.sprite_frames.get_frame_count("walk-down") != 6:
			printerr("FAIL_WORLDX_CONTENT: walk-down not 6 frames")
			quit(12)
			return
		total_frames += actor.sprite_frames.get_frame_count("walk-down")
	if maps < 2:
		printerr("FAIL_WORLDX_CONTENT: 2 real maps required")
		quit(13)
		return
	var overlay_script: Script = load("res://scripts/hd2d_original_overlay_ota177.gd")
	if overlay_script == null:
		printerr("FAIL_WORLDX_CONTENT: main HD2D world script cannot compile")
		quit(14)
		return
	var overlay: CanvasLayer = overlay_script.new()
	get_root().add_child(overlay)
	await process_frame
	if overlay.worldx_map_sprite == null or overlay.worldx_hotspots.size() < 1:
		printerr("FAIL_WORLDX_CONTENT: WorldX map and clickable shops did not appear")
		quit(15)
		return
	overlay._toggle_worldx_map()
	if not overlay.alt_map:
		printerr("FAIL_WORLDX_CONTENT: second map switch failed")
		quit(16)
		return
	print("PASS_WORLDX_REAL_GAME_ASSETS maps=",maps," NPCs=",controller.actors.size(),
		" walk_frames=",total_frames," clickable_hotspots=",overlay.worldx_hotspots.size())
	quit(0)
