extends Node2D
## Independent HD2D test inside the PUBLIC xinyanshuo repository only.
## These are QA candidates downloaded from the already public art library.
## No coupling to the inaccessible/private legacy game, APK, or signing keys.

const ATLAS_URL := "https://160701541-cell.github.io/xinyanshuo/art-source/hd2d/batch-20261016/01_village_props_atlas_preview.jpg"
const WORLD_SIZE := Vector2(1600.0, 1000.0)
const OBJECTS := [
	{"name": "村落建筑候选", "x": 300.0, "y": 240.0, "col": 0, "row": 0},
	{"name": "村口建筑候选", "x": 830.0, "y": 240.0, "col": 1, "row": 0},
	{"name": "村落井台候选", "x": 420.0, "y": 700.0, "col": 0, "row": 1},
	{"name": "村落设施候选", "x": 900.0, "y": 700.0, "col": 1, "row": 1}
]

var _camera: Camera2D
var _status: Label
var _night := false

func _ready() -> void:
	_camera = Camera2D.new()
	_camera.position = WORLD_SIZE * 0.5
	_camera.zoom = Vector2(0.8, 0.8)
	add_child(_camera)
	_camera.make_current()
	_create_scene()
	_create_hud()
	_download_atlas()

func _create_scene() -> void:
	var ground := Polygon2D.new()
	ground.color = Color("#628059")
	ground.polygon = PackedVector2Array([
		Vector2.ZERO, Vector2(WORLD_SIZE.x, 0.0), WORLD_SIZE,
		Vector2(0.0, WORLD_SIZE.y)
	])
	add_child(ground)
	var road := Polygon2D.new()
	road.color = Color("#a99c88")
	road.polygon = PackedVector2Array([
		Vector2(0.0, 520.0), Vector2(1600.0, 520.0),
		Vector2(1600.0, 660.0), Vector2(0.0, 660.0)
	])
	add_child(road)

func _create_hud() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var column := VBoxContainer.new()
	column.position = Vector2(18.0, 16.0)
	ui.add_child(column)
	var header := Label.new()
	header.text = "苍岚 · 公开HD2D场景验收"
	column.add_child(header)
	_status = Label.new()
	_status.text = "正在读取公开候选素材……"
	column.add_child(_status)
	var toggle := Button.new()
	toggle.text = "昼夜切换"
	toggle.pressed.connect(func() -> void:
		_night = not _night
		modulate = Color("#617196") if _night else Color.WHITE
	)
	column.add_child(toggle)
	var note := Label.new()
	note.text = "旧图集候选 · 尚未通过独立PNG质量验收 / 尚未发布APK"
	column.add_child(note)

func _download_atlas() -> void:
	var request := HTTPRequest.new()
	request.timeout = 20.0
	request.body_size_limit = 3000000
	add_child(request)
	request.request_completed.connect(_on_atlas_loaded)
	if request.request(ATLAS_URL) != OK:
		_status.text = "图集下载请求失败"

func _on_atlas_loaded(result: int, code: int, _headers: PackedStringArray, bytes: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or bytes.size() > 3000000:
		_status.text = "图集下载失败：请检查网络"
		return
	var image := Image.new()
	if image.load_jpg_from_buffer(bytes) != OK:
		_status.text = "图集解码失败"
		return
	var tex := ImageTexture.create_from_image(image)
	var cell_width: int = image.get_width() / 4
	var cell_height: int = image.get_height() / 5
	for entry in OBJECTS:
		var region := AtlasTexture.new()
		region.atlas = tex
		region.region = Rect2(
			int(entry["col"]) * cell_width, int(entry["row"]) * cell_height,
			cell_width, cell_height
		)
		var sprite := Sprite2D.new()
		sprite.texture = region
		sprite.position = Vector2(float(entry["x"]), float(entry["y"]))
		sprite.scale = Vector2(1.6, 1.6)
		add_child(sprite)
		var caption := Label.new()
		caption.text = String(entry["name"])
		caption.position = sprite.position + Vector2(-65.0, float(cell_height))
		add_child(caption)
	_status.text = "已显示 %d 个候选资源；仍需替换为独立游戏贴图" % OBJECTS.size()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		_camera.position -= event.relative / _camera.zoom.x
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_camera.position -= event.relative / _camera.zoom.x
	elif event is InputEventMagnifyGesture:
		_zoom(event.factor)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 / 1.1)

func _zoom(multiplier: float) -> void:
	var value := clampf(_camera.zoom.x * multiplier, 0.45, 1.8)
	_camera.zoom = Vector2(value, value)
