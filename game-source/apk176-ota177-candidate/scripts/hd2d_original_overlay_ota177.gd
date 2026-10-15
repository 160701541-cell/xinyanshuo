extends CanvasLayer
## APK176 same-game HD2D candidate: a reversible 2D field test over the
## genuine world root, NOT a standalone APK, and never changes player saves.
## Revisions must be signed by the permanent original APK RSA key.
const TILE_PATH := "res://hd2d/atlas_village_ota177.jpg"
const WORLDX_TERRAIN := "res://hd2d/worldx/worldx_000.png"
const WORLDX_TERRAIN_ALT := "res://hd2d/worldx/worldx_001.png"
var worldx_map_sprite: Sprite2D
var alt_map := false
var panel: Control
var art_world: Node2D
var cam_offset := Vector2(0.0, 0.0)
var zoom := 0.7
var active := true
var dragging := false
var touches: Dictionary = {}
var _background: ColorRect
var _status: Label
var _day_tint: ColorRect
var _is_night := false

func _ready() -> void:
	layer = 61
	_build_visual()
	_set_visible(true)

func _build_visual() -> void:
	panel = Control.new()
	panel.name = "HD2DInGameVillage"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(panel)
	_background = ColorRect.new()
	_background.color = Color("#49634a")
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_background)
	art_world = Node2D.new()
	art_world.name = "HD2DArtwork"
	panel.add_child(art_world)
	_add_worldx_surface()
	_add_road()
	var gui := VBoxContainer.new()
	gui.position = Vector2(18.0, 16.0)
	panel.add_child(gui)
	var header := Label.new()
	header.text = "苍岚 · APK176原游戏HD2D场景测试"
	header.add_theme_font_size_override("font_size", 23)
	gui.add_child(header)
	_status = Label.new()
	_status.text = "读取资源补丁中的村镇贴图……"
	gui.add_child(_status)
	var switch := Button.new()
	switch.text = "返回原世界 / 重新打开 HD2D"
	switch.pressed.connect(func(): _set_visible(not active))
	gui.add_child(switch)
	var note := Label.new()
	note.text = "这是游戏内临时对照场景，原世界仍在运行，存档不变"
	gui.add_child(note)
	_load_atlas()
	_add_worldx_npcs()
	var worldx_switch := Button.new()
	worldx_switch.text = "切换 WorldX 地图区"
	worldx_switch.pressed.connect(_toggle_worldx_map)
	gui.add_child(worldx_switch)
	_day_tint = ColorRect.new()
	_day_tint.name = "DayNightLighting"
	_day_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_day_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_day_tint.color = Color(0.08,0.14,0.28,0.0)
	panel.add_child(_day_tint)
	var lighting := Button.new()
	lighting.text = "昼夜切换"
	lighting.pressed.connect(_toggle_day_night)
	gui.add_child(lighting)
	_update_art_transform()

func _add_worldx_surface() -> void:
	# Reuse ACTUAL raster images from the MIT WorldX sample world.
	# Never pretend this texture is independently authored Godot content.
	if not FileAccess.file_exists(WORLDX_TERRAIN):
		push_warning("WorldX raster absent: original landscape fallback")
		return
	var image := Image.new()
	if image.load_png_from_buffer(FileAccess.get_file_as_bytes(WORLDX_TERRAIN)) != OK:
		push_error("WorldX terrain image decode error")
		return
	var tex := ImageTexture.create_from_image(image)
	if tex == null:
		return
	var tile := Sprite2D.new()
	tile.name = "WorldXImportedWorldRaster"
	tile.centered = false
	tile.texture = tex
	tile.position = Vector2(120.0, 70.0)
	tile.scale = Vector2(1.25, 1.25)
	art_world.add_child(tile)
	worldx_map_sprite = tile

func _toggle_worldx_map() -> void:
	var path := WORLDX_TERRAIN_ALT if not alt_map else WORLDX_TERRAIN
	if not FileAccess.file_exists(path):
		return
	var im := Image.new()
	if im.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
		return
	worldx_map_sprite.texture = ImageTexture.create_from_image(im)
	alt_map = not alt_map

func _add_worldx_npcs() -> void:
	if not FileAccess.file_exists("res://hd2d/worldx/npcs/npcs.json"):
		return
	var npc_class: Script = load("res://scripts/hd2d_worldx_npcs.gd")
	if npc_class == null:
		push_error("WorldX NPC animation controller could not load")
		return
	var npc_layer := Node2D.new()
	npc_layer.name = "WorldXInWorldNPCs"
	npc_layer.set_script(npc_class)
	art_world.add_child(npc_layer)

func _add_road() -> void:
	# Reuse the native 256px seamless paving generator inside the ORIGINAL
	# APK176 overlay. This replaces the flat mock road and diagonal lines.
	var paving = load("res://scripts/hd2d_stone_road.gd")
	if paving == null:
		push_error("HD2D paving generator unavailable")
		return
	var road_texture: Texture2D = paving.make_texture()
	var road := Node2D.new()
	road.name = "StoneRoad_14Tiles"
	art_world.add_child(road)
	for col in range(7):
		for row in range(2):
			var tile := Sprite2D.new()
			tile.name = "Stone_%02d_%02d" % [col,row]
			tile.texture = road_texture
			tile.centered = false
			tile.position = Vector2(-120.0 + float(col * 256), 500.0 + float(row * 256))
			road.add_child(tile)

func _load_atlas() -> void:
	if not FileAccess.file_exists(TILE_PATH):
		_status.text = "候选纹理缺失，已保留安全背景"
		return
	var bytes := FileAccess.get_file_as_bytes(TILE_PATH)
	var img := Image.new()
	if img.load_jpg_from_buffer(bytes) != OK:
		_status.text = "候选纹理解码失败"
		return
	var texture := ImageTexture.create_from_image(img)
	var cw: int = img.get_width()/4
	var ch: int = img.get_height()/5
	var spots := [
		{"x":250.0,"y":210.0,"col":0,"row":0},
		{"x":790.0,"y":215.0,"col":1,"row":0},
		{"x":1300.0,"y":240.0,"col":2,"row":0},
		{"x":440.0,"y":780.0,"col":0,"row":1},
		{"x":1080.0,"y":765.0,"col":1,"row":1}
	]
	for spot in spots:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(int(spot["col"])*cw, int(spot["row"])*ch, cw, ch)
		var sprite := Sprite2D.new()
		sprite.texture = atlas
		sprite.position = Vector2(float(spot["x"]),float(spot["y"]))
		sprite.scale = Vector2(1.5,1.5)
		art_world.add_child(sprite)
	_status.text = "已在原游戏资源包中显示村镇素材；拖动移动，双指缩放"

func _toggle_day_night() -> void:
	_is_night = not _is_night
	_day_tint.color = Color(0.08,0.14,0.28,0.48 if _is_night else 0.0)
	_status.text = "夜间" if _is_night else "白天"

func _set_visible(show: bool) -> void:
	active = show
	_background.visible = show
	art_world.visible = show
	_day_tint.visible = show
	# Preserve an always-available return/re-open action without intercepting
	# touches on the original 3D game when HD2D is hidden.
	panel.mouse_filter = Control.MOUSE_FILTER_PASS if show else Control.MOUSE_FILTER_IGNORE
	_status.text = "HD2D已打开" if show else "原游戏运行中"
	for child in panel.get_children():
		if child is VBoxContainer:
			for widget in child.get_children():
				if widget is Button:
					widget.text = "返回原世界" if show else "重新打开HD2D"

func _update_art_transform() -> void:
	if art_world == null:
		return
	art_world.scale = Vector2(zoom,zoom)
	art_world.position = get_viewport().get_visible_rect().size/2 - Vector2(850.0,480.0)*zoom + cam_offset

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenDrag:
		cam_offset += event.relative
		_update_art_transform()
	elif event is InputEventMagnifyGesture:
		zoom = clampf(zoom*event.factor,0.3,1.6)
		_update_art_transform()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		cam_offset += event.relative
		_update_art_transform()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom*1.1,0.3,1.6)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom/1.1,0.3,1.6)
		_update_art_transform()
