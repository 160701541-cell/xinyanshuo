extends Node2D
## CAC-PROC-001: no atlas/network. Actual code-built outdoor streets AND interiors.
## Public independent QA project; not the legacy signed Android game.
const City = preload("res://scripts/procedural_city.gd")
const Interior = preload("res://scripts/procedural_interior.gd")
const Paving = preload("res://scripts/stone_road.gd")
const WORLD_SIZE := Vector2(3960.0,2680.0)

var _camera: Camera2D
var _city: Node2D
var _interior: Node2D
var _status: Label
var _enter_button: Button
var _leave_button: Button
var _night: bool = false
var _season: int = 0
var _inside: bool = false
var _selected: Node2D
var _dragged: bool = false
var _pointer_start := Vector2.ZERO
var _return_position := Vector2.ZERO
var _return_zoom := Vector2.ONE

func _ready() -> void:
	_city = City.new()
	_city.name = "ProceduralCity"
	add_child(_city)
	_make_paving()
	_interior = Interior.new()
	_interior.name = "ProceduralInterior"
	_interior.position = Vector2(4650.0,720.0)
	_interior.visible = false
	add_child(_interior)
	_camera = Camera2D.new()
	_camera.name = "Camera2D"
	_camera.position = Vector2(1580.0,880.0)
	_camera.zoom = Vector2(0.85,0.85)
	add_child(_camera)
	_camera.make_current()
	_create_hud()
	_refresh_status()

func _make_paving() -> void:
	# Shared original 256px program texture, independent from any JPEG atlas.
	var road: Node2D = Node2D.new()
	road.name = "SeamlessStoneRoad"
	road.position = Vector2(1290,2010)
	_city.add_child(road)
	var tex: Texture2D = Paving.make_texture()
	for col in range(7):
		for row in range(2):
			var sprite: Sprite2D = Sprite2D.new()
			sprite.name = "Paving_%02d_%02d" % [col,row]
			sprite.centered = false
			sprite.texture = tex
			sprite.position = Vector2(float(col*Paving.SIZE),float(row*Paving.SIZE))
			road.add_child(sprite)

func _create_hud() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(15,14)
	layer.add_child(panel)
	var stack: VBoxContainer = VBoxContainer.new()
	panel.add_child(stack)
	var header: Label = Label.new()
	header.text = "苍岚 · 程序化 HD2D 城镇"
	stack.add_child(header)
	_status = Label.new()
	_status.text = "正在建立城镇……"
	stack.add_child(_status)
	var actions: HBoxContainer = HBoxContainer.new()
	stack.add_child(actions)
	var day_btn: Button = Button.new()
	day_btn.text = "昼夜"
	day_btn.pressed.connect(_toggle_night)
	actions.add_child(day_btn)
	var season_btn: Button = Button.new()
	season_btn.text = "四季"
	season_btn.pressed.connect(_cycle_season)
	actions.add_child(season_btn)
	var layout_btn: Button = Button.new()
	layout_btn.text = "新布局"
	layout_btn.pressed.connect(_regenerate)
	actions.add_child(layout_btn)
	var controls: HBoxContainer = HBoxContainer.new()
	stack.add_child(controls)
	_enter_button = Button.new()
	_enter_button.text = "开门进入"
	_enter_button.disabled = true
	_enter_button.pressed.connect(_enter_selected)
	controls.add_child(_enter_button)
	_leave_button = Button.new()
	_leave_button.text = "返回街道"
	_leave_button.visible = false
	_leave_button.pressed.connect(_leave_interior)
	controls.add_child(_leave_button)
	var damage_btn: Button = Button.new()
	damage_btn.text = "建筑受损测试"
	damage_btn.pressed.connect(_cycle_damage)
	controls.add_child(damage_btn)
	var help: Label = Label.new()
	help.text = "拖动移动视角 · 滚轮/双指缩放 · 点建筑选择"
	stack.add_child(help)

func _refresh_status() -> void:
	if _status == null:
		return
	if _inside:
		_status.text = "室内：" + String(_interior.get("source_building_id")) + " · 独立家具：" + str(_interior.get("furnishings").size())
		return
	var counts: Dictionary = _city.call("counts")
	var s: String = "%d院落 / %d建筑 / %d独立道具" % [int(counts["plots"]),int(counts["buildings"]),int(counts["props"])]
	if _selected != null:
		s += "\n选中：" + String(_selected.get("entity_id")) + " · " + String(_selected.get("kind"))
	_status.text = s

func _toggle_night() -> void:
	_night = not _night
	_city.call("set_night",_night)
	_city.modulate = Color("#8794ac") if _night else Color.WHITE
	if _inside and _selected != null:
		_interior.call("open_for",_selected,_night)
	_refresh_status()

func _cycle_season() -> void:
	_season = (_season+1)%4
	_city.call("set_season",_season)
	_refresh_status()

func _regenerate() -> void:
	if _inside:
		_leave_interior()
	_selected = null
	_enter_button.disabled = true
	var next_seed: int = int(_city.get("world_seed"))+1
	_city.call("generate",next_seed)
	_city.call("set_night",_night)
	_city.call("set_season",_season)
	_refresh_status()

func _cycle_damage() -> void:
	if _selected == null or _inside:
		return
	var next: int = (int(_selected.get("damage"))+1)%3
	_selected.call("set_damage",next)
	if next == 2:
		_enter_button.disabled = true
	else:
		_enter_button.disabled = false
	_refresh_status()

func _select_building(building: Node2D) -> void:
	_selected = building
	_city.call("set_selected",building)
	_enter_button.disabled = (building == null or int(building.get("damage")) == 2) if building != null else true
	_refresh_status()

func _try_tap(screen_point: Vector2) -> void:
	if _inside:
		return
	var at: Vector2 = get_canvas_transform().affine_inverse()*screen_point
	var hit: Node2D = _city.call("find_door",at,50.0)
	if hit == null:
		var all: Array[Node2D] = _city.get("buildings")
		for i in range(all.size()-1,-1,-1):
			var b: Node2D = all[i]
			var area: Rect2 = b.call("footprint")
			if area.has_point(at):
				hit = b
				break
	if hit != null:
		_select_building(hit)
		# First tap selects; deliberate button press opens room to avoid pan/tap collisions.
	else:
		_select_building(null)

func _enter_selected() -> void:
	if _selected == null or int(_selected.get("damage")) == 2 or _inside:
		return
	_selected.call("toggle_door")
	_return_position = _camera.position
	_return_zoom = _camera.zoom
	_interior.call("open_for",_selected,_night)
	_city.visible = false
	_interior.visible = true
	_inside = true
	_camera.position = _interior.position
	_camera.zoom = Vector2(0.92,0.92)
	_enter_button.visible = false
	_leave_button.visible = true
	_refresh_status()

func _leave_interior() -> void:
	if not _inside:
		return
	_city.visible = true
	_interior.visible = false
	_inside = false
	_camera.position = _return_position
	_camera.zoom = _return_zoom
	_enter_button.visible = true
	_enter_button.disabled = (_selected == null or int(_selected.get("damage")) == 2)
	_leave_button.visible = false
	_refresh_status()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_pointer_start = event.position
			_dragged = false
		elif not _dragged:
			_try_tap(event.position)
	elif event is InputEventScreenDrag and not _inside:
		_dragged = true
		_pan(event.relative)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pointer_start = event.position
				_dragged = false
			elif not _dragged:
				_try_tap(event.position)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.12)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0/1.12)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _inside:
		if event.position.distance_to(_pointer_start)>8.0:
			_dragged = true
		if _dragged:
			_pan(event.relative)
	elif event is InputEventMagnifyGesture:
		_zoom(event.factor)

func _pan(relative: Vector2) -> void:
	_camera.position -= relative / _camera.zoom.x
	_camera.position.x = clampf(_camera.position.x,0.0,WORLD_SIZE.x)
	_camera.position.y = clampf(_camera.position.y,0.0,WORLD_SIZE.y)

func _zoom(multiplier: float) -> void:
	var value: float = clampf(_camera.zoom.x*multiplier,0.48,1.65)
	_camera.zoom = Vector2(value,value)
