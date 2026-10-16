extends CanvasLayer
## Authentic original-APK176 additive real-3D CC0 viewing room.
## This is a reversible LOOK-ONLY visual prototype, not full WorldBox integration.
## GLB is parsed at runtime so the installed original game needs no new native ABI.
const TREE := "res://canglan_rev179/kenney_tree_oak.glb"
const ROCK := "res://canglan_rev179/kenney_rocks_small.glb"
var preview: SubViewport
var models_loaded: int = 0
var view_root: Node3D
var view_camera: Camera3D
var _angle: float = 0.0
var _enabled: bool = true
var _notice: Label
var _model_errors: Array[String] = []

func _ready() -> void:
	layer = 70
	name = "CanglanAPK176Actual3DPreview"
	var ui := Control.new()
	ui.name = "CC0PreviewInterface"
	# Transparent parent MUST NOT intercept touch after preview is closed.
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	var backdrop := ColorRect.new()
	backdrop.name = "SkyBorder"
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color("#293e47")
	ui.add_child(backdrop)
	var view_frame := SubViewportContainer.new()
	view_frame.name = "ActualReal3DViewportContainer"
	view_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view_frame.stretch = true
	view_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(view_frame)
	preview = SubViewport.new()
	preview.name = "Actual3DRenderingViewport"
	preview.size = Vector2i(1280, 720)
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview.own_world_3d = true
	preview.transparent_bg = false
	view_frame.add_child(preview)
	view_root = Node3D.new()
	view_root.name = "LicensedKenneyWorld"
	preview.add_child(view_root)
	_create_visual_stage()
	var hud := VBoxContainer.new()
	hud.name = "PreviewHUD"
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.position = Vector2(18.0, 18.0)
	ui.add_child(hud)
	var title := Label.new()
	title.text = "苍岚 · 原版APK176内的真实3D素材预览"
	title.add_theme_font_size_override("font_size", 23)
	hud.add_child(title)
	_notice = Label.new()
	_notice.text = "Kenney CC0实物模型 / 仅供快速看画面，不写入旧存档"
	hud.add_child(_notice)
	var exit_button := Button.new()
	exit_button.name = "Exit3DPreview"
	exit_button.mouse_filter = Control.MOUSE_FILTER_STOP
	exit_button.text = "返回原游戏"
	exit_button.custom_minimum_size = Vector2(180.0, 56.0)
	exit_button.pressed.connect(_close_preview)
	hud.add_child(exit_button)
	var reopen := Button.new()
	reopen.name = "Reopen3DPreview"
	reopen.mouse_filter = Control.MOUSE_FILTER_STOP
	reopen.text = "再次查看3D"
	reopen.custom_minimum_size = Vector2(180.0, 56.0)
	reopen.visible = false
	reopen.pressed.connect(_open_preview)
	ui.add_child(reopen)
	reopen.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	reopen.position = Vector2(-205.0, 16.0)
	set_meta("cc0_tree_and_rock_count", models_loaded)
	set_meta("gameplay_save_untouched", true)
	set_meta("preview_only", true)

func _parse_cc0_asset(path: String) -> Node3D:
	if not FileAccess.file_exists(path):
		_model_errors.append("MISSING_CC0_FILE:" + path)
		return null
	var data := FileAccess.get_file_as_bytes(path)
	if data.size() < 256:
		_model_errors.append("EMPTY_CC0_MODEL:" + path)
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_buffer(data, "", state) != OK:
		_model_errors.append("INVALID_CC0_GLTF:" + path)
		return null
	var mesh: Node3D = doc.generate_scene(state)
	if mesh == null:
		_model_errors.append("GLTF_SCENE_NOT_GENERATED:" + path)
	return mesh

func _create_visual_stage() -> void:
	var env := WorldEnvironment.new()
	env.name = "PreviewLighting"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#8ea5ae")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b6c8c8")
	environment.ambient_light_energy = 0.8
	env.environment = environment
	view_root.add_child(env)
	var sunlight := DirectionalLight3D.new()
	sunlight.name = "AutumnSunlight"
	sunlight.rotation_degrees = Vector3(-48, -28, 0)
	sunlight.light_energy = 1.3
	view_root.add_child(sunlight)
	var floor := MeshInstance3D.new()
	floor.name = "PreviewGroundNotResource"
	var ground := PlaneMesh.new()
	ground.size = Vector2(95, 95)
	floor.mesh = ground
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color("#6b8664")
	ground_mat.roughness = 1.0
	floor.material_override = ground_mat
	view_root.add_child(floor)
	var tree_source: Node3D = _parse_cc0_asset(TREE)
	var stone_source: Node3D = _parse_cc0_asset(ROCK)
	if tree_source != null:
		tree_source.name = "LicensedCC0Oak_0000"
		tree_source.position = Vector3(-16, 0, -8)
		view_root.add_child(tree_source)
		models_loaded += 1
		for i in range(1, 16):
			var duplicate: Node3D = tree_source.duplicate()
			duplicate.name = "LicensedCC0Oak_%04d" % i
			duplicate.position = Vector3(-22 + (i % 8) * 5, 0, -9 + int(i / 8) * 13)
			duplicate.set_meta("source", "KENNEY_CC0")
			view_root.add_child(duplicate)
			models_loaded += 1
	if stone_source != null:
		stone_source.name = "LicensedCC0Rocks_0000"
		stone_source.position = Vector3(12, 0, 4)
		view_root.add_child(stone_source)
		models_loaded += 1
		for i in range(1, 10):
			var duplicate: Node3D = stone_source.duplicate()
			duplicate.name = "LicensedCC0Rocks_%04d" % i
			duplicate.position = Vector3(11 + (i % 5) * 3, 0, 4 + int(i / 5) * 5)
			duplicate.set_meta("source", "KENNEY_CC0")
			view_root.add_child(duplicate)
			models_loaded += 1
	if tree_source == null or stone_source == null:
		push_error("BLOCKED_APK176_3D_PREVIEW_MISSING_LICENSED_GLTF")
	view_camera = Camera3D.new()
	view_camera.name = "Mobile3DPreviewCamera"
	view_camera.current = true
	view_camera.fov = 65.0
	view_root.add_child(view_camera)
	_update_camera()

func _update_camera() -> void:
	if view_camera == null:
		return
	view_camera.position = Vector3(sin(_angle) * 37, 23, cos(_angle) * 37)
	view_camera.look_at(Vector3(0, 1.5, 0), Vector3.UP)

func _process(delta: float) -> void:
	if _enabled:
		_angle += delta * 0.07
		_update_camera()

func _close_preview() -> void:
	_enabled = false
	var ui: Control = get_node("CC0PreviewInterface")
	ui.get_node("ActualReal3DViewportContainer").visible = false
	ui.get_node("SkyBorder").visible = false
	ui.get_node("PreviewHUD").visible = false
	ui.get_node("Reopen3DPreview").visible = true

func _open_preview() -> void:
	_enabled = true
	var ui: Control = get_node("CC0PreviewInterface")
	ui.get_node("ActualReal3DViewportContainer").visible = true
	ui.get_node("SkyBorder").visible = true
	ui.get_node("PreviewHUD").visible = true
	ui.get_node("Reopen3DPreview").visible = false

func stats() -> Dictionary:
	return {"cc0_mesh_instances": models_loaded, "missing_assets": _model_errors.duplicate(),
		"original_app_preview": true, "actual_3d_viewport": preview != null,
		"save_unchanged": true}
