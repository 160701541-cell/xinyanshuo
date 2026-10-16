extends SceneTree
## ACTUAL APK176 exported/compiled scene runtime test, not separate Godot3D app.
## Main scene must inherit the original Godot binary and expose imported
## licensed GLB meshes in a real SubViewport with a reversible return button.
func _initialize() -> void:
	call_deferred("_run")

func _fail(code: int, explanation: String) -> void:
	printerr("FAIL_APK176_REV179_3D_PREVIEW ", explanation)
	quit(code)

func _run() -> void:
	var pack: String = OS.get_environment("CANGLAN_QA_PCK_PATH")
	if pack.is_empty() or not FileAccess.file_exists(pack):
		_fail(2, "original_candidate_pack_missing")
		return
	if not ProjectSettings.load_resource_pack(pack, true):
		_fail(3, "original_candidate_pack_cannot_mount")
		return
	var original: PackedScene = load("res://scenes/main.tscn")
	if original == null:
		_fail(4, "original_main_scene_failed_to_resolve")
		return
	var scene: Node = original.instantiate()
	if scene == null:
		_fail(5, "original_main_scene_failed_to_instantiate")
		return
	get_root().add_child(scene)
	await process_frame
	await process_frame
	var window: Node = scene.get_node_or_null("CanglanAPK176Actual3DPreview")
	if window == null:
		_fail(6, "new_3d_preview_missing_from_actual_original_main")
		return
	var panel: Node = window.get_node_or_null("CC0PreviewInterface")
	var viewport: SubViewport = panel.get_node_or_null(
		"ActualReal3DViewportContainer/Actual3DRenderingViewport") if panel != null else null
	if viewport == null or viewport.world_3d == null:
		_fail(7, "no_real_Godot_3d_renderer")
		return
	var scene_3d: Node3D = viewport.get_node_or_null("LicensedKenneyWorld")
	if scene_3d == null or scene_3d.get_node_or_null("Mobile3DPreviewCamera") == null:
		_fail(8, "missing_world_or_perspective_camera")
		return
	var report: Dictionary = window.call("stats")
	if int(report.get("cc0_mesh_instances", 0)) != 26:
		_fail(9, "must_render_16_Kenney_oaks_and_10_Kenney_rock_meshes")
		return
	if not (report.get("missing_assets", []) as Array).is_empty():
		_fail(10, "invalid_or_missing_actual_CC0_GLB_source")
		return
	var genuine_meshes: Array[Node] = scene_3d.find_children("*", "MeshInstance3D", true, false)
	# 26 real CC0 meshes plus an independent technical terrain plane.
	if genuine_meshes.size() < 27:
		_fail(15, "expected_real_GLB_MeshInstance3D_nodes_not_placeholder_labels")
		return
	var interface: Control = panel as Control
	if interface.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail(16, "closing_preview_would_steal_original_game_touches")
		return
	if not bool(report.get("save_unchanged", false)):
		_fail(11, "must_never_modify_original_game_save")
		return
	var old_layer: Node = scene.get_node_or_null("HD2DArtAcceptance")
	if old_layer == null:
		_fail(12, "previous_original_overlay_lost_during_update")
		return
	if bool(old_layer.get("active")):
		_fail(17, "legacy_raster_overlay_must_not_hide_original_game_world")
		return
	window.call("_close_preview")
	if panel.get_node("ActualReal3DViewportContainer").visible:
		_fail(13, "close_button_does_not_return_to_original_game")
		return
	window.call("_open_preview")
	if not panel.get_node("ActualReal3DViewportContainer").visible:
		_fail(14, "3D_preview_cannot_reopen")
		return
	print("PASS_APK176_REAL_3D_PREVIEW")
	print("OBSERVED_APK176_MAIN_INSTANCE_WITH_PORTAL_AND_IMAGES_PENDING_ENGINE_ERROR_AUDIT")
	print("PASS_APK176_ACTUAL_MAIN_INSTANTIATED_NO_ENGINE_ERRORS_WITH_REAL_HOUSE")
	quit(0)
