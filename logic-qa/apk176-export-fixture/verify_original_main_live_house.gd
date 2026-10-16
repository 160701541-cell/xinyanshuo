extends SceneTree
## Independent strict QA: instantiate *actual APK176* compiled Main PackedScene,
## attach it to SceneTree, and verify the new world overlay/house gameplay.
## Uses only APK-exported assets and same-game UNSIGNED candidate resource PCK.
## This is NOT a signed Android release or a physical-device test.

const MAIN := "res://scenes/main.tscn"
const HOUSE_NODE := "HD2DArtAcceptance"
var _finished := false

func _fail(reason: String, code: int) -> void:
	printerr("FAIL_APK176_ACTUAL_MAIN_RUNTIME ", reason)
	_finished = true
	quit(code)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var candidate := OS.get_environment("CANGLAN_QA_PCK_PATH")
	if candidate.is_empty() or not FileAccess.file_exists(candidate):
		_fail("candidate_unsigned_pck_missing", 2)
		return
	if not ProjectSettings.load_resource_pack(candidate, true):
		_fail("candidate_failed_to_mount", 3)
		return
	var scene: PackedScene = load(MAIN)
	if scene == null:
		_fail("actual_original_main_scene_failed_to_load", 4)
		return
	var main: Node = scene.instantiate()
	if main == null:
		_fail("actual_original_main_scene_failed_to_instantiate", 5)
		return
	if not main.has_node(HOUSE_NODE):
		_fail("missing_same_game_overlay_after_instantiate", 6)
		return
	get_root().add_child(main)
	await process_frame
	await process_frame
	if _finished:
		return
	var overlay: Node = main.get_node_or_null(HOUSE_NODE)
	if overlay == null or overlay._house_portal == null:
		_fail("overlay_or_house_portal_not_live", 7)
		return
	var portal: Node = overlay._house_portal
	if portal.inside:
		_fail("house_initially_inside", 8)
		return
	if not portal._outside_image_present or not portal._inside_image_present:
		_fail("real_outdoor_or_indoor_art_not_loaded", 9)
		return
	# Previous real Godot screenshot exposed that the inside picture was
	# technically loaded but its ColorRect/TextureRect had a zero viewport.
	var room_art: TextureRect = portal._room.get_node("WorldXKolorsInteriorCandidate")
	if portal._room.size.x < 800 or portal._room.size.y < 480 or room_art.size.x < 800 or room_art.size.y < 480:
		_fail("loaded_house_art_not_actually_fullscreen_visible", 12)
		return
	var before: Vector2 = portal.current_spawn
	portal.enter_building()
	if not portal.inside or not portal._room.visible:
		_fail("live_original_main_enter_failed", 10)
		return
	portal.exit_building()
	if portal.inside or portal.current_spawn != before or not portal._outdoor_art.visible:
		_fail("live_original_main_exit_failed", 11)
		return
	print("OBSERVED_APK176_MAIN_INSTANCE_WITH_PORTAL_AND_IMAGES_PENDING_ENGINE_ERROR_AUDIT")
	_finished = true
	quit(0)
