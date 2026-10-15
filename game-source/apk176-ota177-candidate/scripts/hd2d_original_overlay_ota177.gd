extends CanvasLayer
## APK176 same-game HD2D candidate: a reversible 2D field test over the
## genuine world root, NOT a standalone APK, and never changes player saves.
## Revisions must be signed by the permanent original APK RSA key.
const TILE_PATH := "res://hd2d/atlas_village_ota177.jpg"
var panel: Control
var art_world: Node2D
var cam_offset := Vector2(0.0, 0.0)
var zoom := 0.7
var active := true
var dragging := false
var touches: Dictionary = {}
var _background: ColorRect
var _status: Label

func _ready() -> void:
	layer = 61
	_build_visual()
	_set_visible(true)

func _build_visual() -> void:
	panel = Control.new()
	panel.name = "HD2DPlaytest"
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
	_update_art_transform()

func _add_road() -> void:
	var grass := Polygon2D.new()
	grass.color = Color("#68835a")
	grass.polygon = PackedVector2Array([Vector2(-400,-400),Vector2(2400,-400),Vector2(2400,1500),Vector2(-400,1500)])
	art_world.add_child(grass)
	var stone := Polygon2D.new()
	stone.color = Color("#b4a991")
	stone.polygon = PackedVector2Array([Vector2(-200,540),Vector2(2000,540),Vector2(2000,760),Vector2(-200,760)])
	art_world.add_child(stone)
	for i in range(34):
		var line := Line2D.new()
		line.default_color = Color("#716d60", 0.42)
		line.width = 3.0
		var x := -120.0 + float(i)*66.0
		line.points = PackedVector2Array([Vector2(x,540),Vector2(x-38,760)])
		art_world.add_child(line)

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

func _set_visible(show: bool) -> void:
	active = show
	_background.visible = show
	art_world.visible = show
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
