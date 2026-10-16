extends SceneTree
## Strict engine-level gameplay QA against actual (unsigned) APK176 PCK.
## No mocking: the same portal script is included in the real candidate pack.
func _initialize() -> void:
	call_deferred("_test")

func _fail(message: String, code: int) -> void:
	printerr("FAIL_CANG LAN_HOUSE_PORTAL_".replace(" ", "") + message)
	quit(code)

func _test() -> void:
	var pack_path := OS.get_environment("CANGLAN_QA_PCK_PATH")
	if pack_path.is_empty() or not FileAccess.file_exists(pack_path):
		_fail("NO_ACTUAL_PACK", 2)
		return
	if not ProjectSettings.load_resource_pack(pack_path, true):
		_fail("CANNOT_MOUNT_PACK", 3)
		return
	var class_script: Script = load("res://scripts/hd2d_house_portal.gd")
	if class_script == null:
		_fail("NO_BUILDING_CONTROLLER", 4)
		return
	var host := Control.new()
	host.name = "GameOverlayHost"
	get_root().add_child(host)
	host.size = Vector2(1280, 720)
	var outside := Node2D.new()
	host.add_child(outside)
	var status := Label.new()
	host.add_child(status)
	var portal: Variant = class_script.new()
	host.add_child(portal)
	portal.install(outside, status)
	await process_frame
	if portal.inside or portal.transition_count != 0:
		_fail("INITIAL_STATE_WRONG", 5)
		return
	if not outside.has_node("CanglanBuilding_CL_HOUSE_0001"):
		_fail("EXTERIOR_NOT_RENDERED", 6)
		return
	if portal._open_button == null or portal._exit_button == null:
		_fail("MISSING_ENTER_EXIT_BUTTONS", 7)
		return
	if not portal._room.has_node("InteriorHUD"):
		_fail("MISSING_INTERIOR_HUD", 8)
		return
	var original_spawn: Vector2 = portal.current_spawn
	portal.enter_building()
	if not portal.inside or not portal._room.visible or portal._outdoor_art.visible or portal._open_button.visible:
		_fail("ENTER_STATE_BAD", 9)
		return
	if portal.current_spawn != portal.inside_spawn:
		_fail("INDOOR_SPAWN_WRONG", 10)
		return
	portal.enter_building()
	if portal.transition_count != 1:
		_fail("DUPLICATE_ENTER", 11)
		return
	portal.exit_building()
	if portal.inside or portal._room.visible or not portal._outdoor_art.visible or not portal._open_button.visible:
		_fail("EXIT_STATE_BAD", 12)
		return
	if portal.current_spawn != original_spawn:
		_fail("OUTDOOR_SPAWN_NOT_RESTORED", 13)
		return
	portal.exit_building()
	if portal.transition_count != 2:
		_fail("DUPLICATE_EXIT", 14)
		return
	portal.set_overlay_visible(false)
	if portal.visible:
		_fail("ORIGINAL_WORLD_SWITCH_DID_NOT_HIDE", 15)
		return
	portal.set_overlay_visible(true)
	if not portal.visible or portal.transition_count != 2:
		_fail("ORIGINAL_WORLD_SWITCH_CHANGED_STATE", 16)
		return
	var outer := FileAccess.file_exists("res://hd2d/courtyard/main_house_v3_source.png")
	var inner := FileAccess.file_exists("res://hd2d/courtyard/main_house_interior.png")
	if outer != portal._outside_image_present or inner != portal._inside_image_present:
		_fail("IMAGE_LOADER_STATUS_INCONSISTENT", 17)
		return
	print("PASS_CANG LAN_HOUSE_PORTAL_ENTER_EXIT_RESET_GUARD".replace(" ", ""),
		" building=", portal.BUILDING_ID,
		" transitions=", portal.transition_count,
		" exterior_art=", outer, " interior_art=", inner)
	quit(0)
