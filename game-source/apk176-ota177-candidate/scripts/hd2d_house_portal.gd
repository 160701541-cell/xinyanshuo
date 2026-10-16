extends Control
## Enterable building candidate: the exterior uses a real 523x553 source-pixel
## alpha crop, never paste a WATERMARKED 1024x1024 courtyard rectangle over
## a different 2D WorldX city map. Indoor artwork uses viewport cover crop.
## Exterior and interior are separate render spaces with a shared persistent
## building ID. Does not touch saves, global quest state or the original scene.
signal building_entered(building_id: String)
signal building_exited(building_id: String)

const BUILDING_ID := "CL-HOUSE-0001"
const EXTERIOR := "res://hd2d/courtyard/main_house_isolated_edge04.png"
const INTERIOR := "res://hd2d/courtyard/main_house_interior.png"

var inside := false
var transition_count := 0
var outside_spawn := Vector2(703.0, 622.0)
var inside_spawn := Vector2(600.0, 680.0)
var current_spawn := Vector2.ZERO
var _world: Node2D
var _room: Control
var _room_sprite: Sprite2D
var _open_button: Button
var _exit_button: Button
var _status: Label
var _outdoor_art: Node2D
var _player_marker: Node2D
var _outside_image_present := false
var _inside_image_present := false

func _full_screen_area() -> Vector2:
	# Layout can start before viewport sizing in exported/headless APK fixtures.
	# The parent HD2D panel carries the usable gameplay display bounds.
	var owner: Control = get_parent() as Control
	if owner != null and owner.size.x >= 800.0 and owner.size.y >= 480.0:
		return owner.size
	var viewport_area: Vector2 = get_viewport().get_visible_rect().size
	if viewport_area.x >= 800.0 and viewport_area.y >= 480.0:
		return viewport_area
	return Vector2(1280.0, 720.0) # QA/headless landscape safety fallback.

func _process(_delta: float) -> void:
	# Do not allow an anchor-layout notification to squash the displayed
	# indoor art to 0x0 after it has successfully been loaded.
	var desired := _full_screen_area()
	if size.distance_squared_to(desired) > 1.0:
		size = desired
		if _room != null:
			_room.size = desired
			for part in _room.get_children():
				if part is TextureRect or part is ColorRect:
					part.size = desired
		_sync_room_sprite()

func install(world: Node2D, status: Label) -> void:
	_world = world
	_status = status
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = _full_screen_area()
	_build_exterior()
	_build_interior()
	_build_entrance_controls()
	current_spawn = outside_spawn

func _sync_room_sprite() -> void:
	if _room_sprite == null or _room_sprite.texture == null or _room == null:
		return
	var tex_size: Vector2 = _room_sprite.texture.get_size()
	if tex_size.x < 1.0 or tex_size.y < 1.0:
		return
	var room_size: Vector2 = _room.size
	if room_size.x < 1.0 or room_size.y < 1.0:
		return
	# Scale the original image uniformly: no clipping, invisible furniture,
	# distorted 2D geometry, or implicit TextureRect stretch surprises.
	var s := maxf(room_size.x / tex_size.x, room_size.y / tex_size.y)
	_room_sprite.scale = Vector2(s, s)
	_room_sprite.position = room_size * 0.5

func _read_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	if image.load_png_from_buffer(bytes) != OK:
		push_warning("Invalid building PNG at " + path)
		return null
	return ImageTexture.create_from_image(image)

func _build_exterior() -> void:
	_outdoor_art = Node2D.new()
	_outdoor_art.name = "CanglanBuilding_CL_HOUSE_0001"
	_world.add_child(_outdoor_art)
	var tex := _read_texture(EXTERIOR)
	if tex != null:
		var facade := Sprite2D.new()
		facade.name = "CourtyardExteriorArtCandidate"
		facade.texture = tex
		facade.centered = false
		facade.position = Vector2(572.0, 118.0)
		facade.scale = Vector2(0.70, 0.70)
		_outdoor_art.add_child(facade)
		_outside_image_present = true
	else:
		# Honest fallback when a CI candidate pack does not yet contain the art.
		var silhouette := Polygon2D.new()
		silhouette.name = "MissingExteriorArtFallback"
		silhouette.polygon = PackedVector2Array([
			Vector2(505, 330), Vector2(735, 330),
			Vector2(780, 525), Vector2(460, 525)
		])
		silhouette.color = Color("#7c7669")
		_outdoor_art.add_child(silhouette)
	var entry := Button.new()
	entry.name = "ExteriorHouseDoor"
	entry.text = "正房门 · 进入"
	entry.position = Vector2(675.0, 475.0)
	entry.size = Vector2(160.0, 50.0)
	entry.pressed.connect(enter_building)
	_outdoor_art.add_child(entry)
	_player_marker = Node2D.new()
	_player_marker.name = "PlayerOutsideLocation"
	_player_marker.position = outside_spawn
	_outdoor_art.add_child(_player_marker)
	var indicator := Polygon2D.new()
	indicator.color = Color("#e8d6a2")
	indicator.polygon = PackedVector2Array([
			Vector2(0,-13), Vector2(9,1), Vector2(0,12), Vector2(-9,1)
	])
	_player_marker.add_child(indicator)

func _build_interior() -> void:
	_room = Control.new()
	_room.name = "CL_HOUSE_0001_InteriorScene"
	# Do not inherit a shifted Control transform from the overlay; source of
	# half-screen blank bronze in actual Godot rendered verification frames.
	_room.top_level = true
	# Original WorldX NPCs use z_index=6 and were painted over the
	# interior background. The interior must be a separate topmost scene.
	_room.z_index = 40
	_room.position = Vector2.ZERO
	add_child(_room)
	_room.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_room.size = size
	_room.mouse_filter = Control.MOUSE_FILTER_STOP
	var floor := ColorRect.new()
	floor.name = "FallbackWoodFloor"
	floor.color = Color("#977d61")
	_room.add_child(floor)
	floor.set_anchors_preset(Control.PRESET_TOP_LEFT)
	floor.size = _room.size
	var tex := _read_texture(INTERIOR)
	if tex != null:
		_room_sprite = Sprite2D.new()
		_room_sprite.name = "WorldXKolorsInteriorCandidate"
		_room_sprite.texture = tex
		_room_sprite.centered = true
		_room_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_room.add_child(_room_sprite)
		_sync_room_sprite()
		_inside_image_present = true
	else:
		# Functional, deliberately marked placeholder, never considered art QA.
		var top_wall := ColorRect.new()
		top_wall.name = "FallbackInteriorWall"
		top_wall.color = Color("#d5c6a9")
		top_wall.anchor_right = 1.0
		top_wall.offset_bottom = 125.0
		_room.add_child(top_wall)
		for spec in [
			{"name":"TablePlaceholder","rect":Rect2(480,285,180,85),"color":"#5f402d"},
			{"name":"BedPlaceholder","rect":Rect2(140,260,180,100),"color":"#725444"},
			{"name":"CabinetPlaceholder","rect":Rect2(850,180,105,175),"color":"#624430"}
		]:
			var item := ColorRect.new()
			item.name = str(spec["name"])
			item.position = spec["rect"].position
			item.size = spec["rect"].size
			item.color = Color(str(spec["color"]))
			_room.add_child(item)
	var top_bar := HBoxContainer.new()
	top_bar.name = "InteriorHUD"
	top_bar.position = Vector2(18.0, 18.0)
	_room.add_child(top_bar)
	var label := Label.new()
	label.text = "苍岚 · 正房内 | 建筑ID " + BUILDING_ID
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("#fcefd1"))
	label.add_theme_color_override("font_shadow_color", Color("#1b1715"))
	top_bar.add_child(label)
	_exit_button = Button.new()
	_exit_button.name = "ExitToOriginalCourtyard"
	_exit_button.text = "离开正房 · 返回院落"
	_exit_button.custom_minimum_size = Vector2(185.0, 54.0)
	_exit_button.pressed.connect(exit_building)
	top_bar.add_child(_exit_button)
	var bottom := Label.new()
	bottom.name = "InteriorVisualStatus"
	bottom.text = "室内：WorldX/Kolors候选原图（单张布景，家具交互待拆分）" if _inside_image_present else "室内：可进出功能已接通；美术图未载入，当前显示占位家具"
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom.offset_left = 22.0
	bottom.offset_top = -65.0
	bottom.offset_right = 780.0
	bottom.offset_bottom = -20.0
	_room.add_child(bottom)
	_room.visible = false

func _build_entrance_controls() -> void:
	_open_button = Button.new()
	_open_button.name = "EnterHouseFixedHUD"
	_open_button.text = "进入正房"
	_open_button.custom_minimum_size = Vector2(150.0, 58.0)
	_open_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_open_button.offset_left = -182.0
	_open_button.offset_top = -94.0
	_open_button.offset_right = -20.0
	_open_button.offset_bottom = -28.0
	_open_button.pressed.connect(enter_building)
	add_child(_open_button)

func enter_building() -> void:
	if inside:
		return
	inside = true
	transition_count += 1
	current_spawn = inside_spawn
	_outdoor_art.visible = false
	_world.visible = false # Do not show outdoor NPCs through the room.
	_room.visible = true
	_open_button.visible = false
	if _status != null:
		_status.text = "已进入 " + BUILDING_ID + "；可点击「离开正房」回到原室外位置"
	building_entered.emit(BUILDING_ID)

func exit_building() -> void:
	if not inside:
		return
	inside = false
	transition_count += 1
	current_spawn = outside_spawn
	_outdoor_art.visible = true
	_world.visible = true
	_room.visible = false
	_open_button.visible = true
	_player_marker.position = outside_spawn
	if _status != null:
		_status.text = "已离开正房，返回原院落门前；原游戏状态未重置"
	building_exited.emit(BUILDING_ID)

func set_overlay_visible(active: bool) -> void:
	visible = active
	if _world != null:
		_world.visible = active and not inside
	# Keep interior state while temporarily viewing the original world.
