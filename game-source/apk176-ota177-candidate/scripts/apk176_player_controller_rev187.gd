extends Node
## APK176 rev187: real player entity in the original compiled app's physical
## Godot world. Multitouch separation: left move, right look, pinch zoom;
## first/third-person, actual nearby NPC/resource interactions and excavation.
const PLAYER_ID := "CL-PLAYER-0184-0001"
const MOVE_SPEED: float = 4.6
const RUN_SPEED: float = 6.5
var room: Node
var world: Node3D
var camera: Camera3D
var terrain: Node3D
var actor: Node3D
var animator: AnimationPlayer
var walking: String = ""
var idle: String = ""
var hud: Control
var thumb_panel: Panel
var joystick_ring: Panel
var buttons: Dictionary = {}
var notice: Label
var is_first_person: bool = false
var camera_mode: String = "third" # third / first / god / fly
var _god_focus: Vector3 = Vector3(0,0,-3)
var _flight_position: Vector3 = Vector3(0,12,15)
var _camera_collision_hits: int = 0
var _vertical_input: float = 0.0
var _god_distance: float = 32.0
var _god_rotation: float = 0.0
var _flight_m: float = 0.0
var _view_pitch_reversed: bool = true
var _yaw: float = 0.43
var _pitch: float = 0.38
var _distance: float = 12.0
var _joystick := Vector2.ZERO
var _joystick_touch: int = -1
var _look_touch: int = -1
var _right_touches: Dictionary = {}
var _last_pinch: float = -1.0
var _follow_npc: bool = false
var _interaction_count: int = 0
var _dig_count: int = 0
var _movement_m: float = 0.0
var _enabled: bool = true
var _look_zone: Control
var _left_world_zone: Control
var _gui_input_events: int = 0
var _touch_started: Dictionary = {}
var _auto_target: Vector3 = Vector3.ZERO
var _auto_resource_id: String = ""
var _auto_npc_id: String = ""
var _auto_walking: bool = false
var _touch_tap_count: int = 0
var _hud_flash: float = 0.0
var _game_status: Label
var _game_sheet: PanelContainer
var _game_sheet_title: Label
var _game_sheet_body: Label
var _game_sheet_mode: String = ""
var _player_health: int = 100
var _health_bar: ProgressBar
var _energy_bar: ProgressBar
var _spirit_notice: Label
var _game_actions: Dictionary = {}
var _dash_cd: float = 0.0
var _gather_cd: float = 0.0
var _fall_damage_cd: float = 0.0
var _quality_sheet_button: Button
var _developer_sheet_button: Button

func initialize(active_room: Node) -> void:
  room = active_room
  world = room.get("world")
  camera = room.get("camera")
  terrain = room.get("terrain_world")
  name = "PlayerActualTouchAndPerspectiveController"
  _spawn_player()
  _create_hud()
  update_camera()
  set_meta("original_apk176_interactive_player",true)

func _spawn_player() -> void:
  var assets: Dictionary = room.get("asset_sources")
  if not assets.has("worker"):
    push_error("P0: Missing licensed animated third-person player GLB")
    return
  actor = (assets["worker"] as Node3D).duplicate()
  actor.name = "CL_PLAYER_0184_ACTUAL_WALKING_WORLD_ENTITY"
  actor.position = Vector3(1.5,0,7.0)
  world.add_child(actor)
  room.call("_normalize_worker_height",actor)
  actor.position.y = float(terrain.call("height_at",actor.position.x,actor.position.z)) + float(actor.get_meta("actor_ground_offset_y",0.0))
  actor.set_meta("entity_id",PLAYER_ID)
  actor.set_meta("controllable",true)
  var possible: Array[Node] = actor.find_children("*","AnimationPlayer",true,false)
  for item in possible:
    var player: AnimationPlayer = item as AnimationPlayer
    for anim in player.get_animation_list():
      var lower: String = String(anim).to_lower()
      if walking.is_empty() and (lower.contains("walk") or lower.contains("run")):
        walking = String(anim)
        animator = player
      if idle.is_empty() and (lower.contains("idle") or lower.contains("stand")):
        idle = String(anim)
  if animator != null and not idle.is_empty():
    animator.play(idle)

func _rounded(color: Color, radius: int) -> StyleBoxFlat:
  var s := StyleBoxFlat.new()
  s.bg_color = color
  s.corner_radius_top_left = radius
  s.corner_radius_top_right = radius
  s.corner_radius_bottom_left = radius
  s.corner_radius_bottom_right = radius
  return s

func _new_button(key: String, label: String, width: float, action: Callable) -> Button:
  var button := Button.new()
  button.name = key
  button.text = label
  button.custom_minimum_size = Vector2(width,54)
  button.size = Vector2(width,54)
  button.mouse_filter = Control.MOUSE_FILTER_STOP
  button.add_theme_font_size_override("font_size",21)
  button.pressed.connect(action)
  hud.add_child(button)
  buttons[key] = button
  return button

func _create_hud() -> void:
  hud = Control.new()
  hud.name = "MobileControllablePlayerUI"
  hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
  hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  room.get("ui").add_child(hud)
  joystick_ring = Panel.new()
  joystick_ring.name = "RealAnalogLeftJoystick"
  joystick_ring.size = Vector2(146,146)
  joystick_ring.mouse_filter = Control.MOUSE_FILTER_STOP
  joystick_ring.gui_input.connect(_on_joystick_gui)
  joystick_ring.add_theme_stylebox_override("panel",_rounded(Color(0.10,0.17,0.15,0.44),75))
  # Actual GUI hit testing must receive mobile touch input. The original
  # CanvasLayer _input() was not reliably reached after the main game's UI
  # consumed the touch, leaving a decorative but dead joystick.
  _look_zone = Control.new()
  _look_zone.name = "RightFingerLookAndTapWorld"
  _look_zone.mouse_filter = Control.MOUSE_FILTER_STOP
  _look_zone.anchor_left = 0.42
  _look_zone.anchor_right = 1.0
  _look_zone.anchor_top = 0.22
  _look_zone.anchor_bottom = 1.0
  _look_zone.gui_input.connect(_on_right_world_gui)
  hud.add_child(_look_zone)
  # Left-hand trees were impossible to click in rev185 because only the
  # right look zone captured taps. Capture left-world taps as well, while
  # keeping the joystick as a higher-priority GUI child.
  _left_world_zone = Control.new()
  _left_world_zone.name = "LeftFingerWorldEntityTapExceptJoystick"
  _left_world_zone.mouse_filter = Control.MOUSE_FILTER_STOP
  _left_world_zone.anchor_left = 0.0
  _left_world_zone.anchor_right = 0.42
  _left_world_zone.anchor_top = 0.22
  _left_world_zone.anchor_bottom = 1.0
  _left_world_zone.gui_input.connect(_on_left_world_gui)
  hud.add_child(_left_world_zone)
  hud.add_child(joystick_ring)
  thumb_panel = Panel.new()
  thumb_panel.name = "AnalogThumb"
  thumb_panel.size = Vector2(64,64)
  thumb_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
  thumb_panel.add_theme_stylebox_override("panel",_rounded(Color(0.83,0.90,0.77,0.74),34))
  joystick_ring.add_child(thumb_panel)
  thumb_panel.position = Vector2(41,41)
  _new_button("PerspectiveButton","第一视角",146,Callable(self,"toggle_perspective"))
  _new_button("GodViewButton","上帝视角",146,Callable(self,"toggle_god_view"))
  _new_button("FlyViewButton","自由飞行",146,Callable(self,"toggle_fly_view"))
  _new_button("FlyUpButton","升高 ↑",116,Callable(self,"fly_up"))
  _new_button("FlyDownButton","降低 ↓",116,Callable(self,"fly_down"))
  _new_button("ResetViewButton","重置镜头",146,Callable(self,"reset_camera"))
  _new_button("ZoomInButton","视野 ＋",128,Callable(self,"zoom_in"))
  _new_button("ZoomOutButton","视野 －",128,Callable(self,"zoom_out"))
  _new_button("InteractButton","互动",132,Callable(self,"interact"))
  _new_button("DigButton","挖地层",132,Callable(self,"dig"))
  var caption := Label.new()
  caption.name = "InteractionResultLiveHUD"
  caption.add_theme_font_size_override("font_size",18)
  caption.text = "左摇杆走路 · 右边滑动看世界 · 双指缩放 · 可切第一视角"
  hud.add_child(caption)
  notice = caption
  _build_game_hud()
  _layout_hud()


# rev188 candidate: never fabricate HP, MP or skill state before combat exists.
func _game_menu_button(label: String, x: float, mode: String) -> void:
  var b := Button.new()
  b.name = "GameMenu_" + label
  b.text = label
  b.position = Vector2(x, 98)
  b.size = Vector2(96, 42)
  b.add_theme_font_size_override("font_size",18)
  b.pressed.connect(func(): _open_game_menu(mode))
  hud.add_child(b)

func _build_game_hud() -> void:
  var bg := PanelContainer.new()
  bg.name = "LiveGameVitalsRev188"
  bg.position = Vector2(16, 12)
  bg.custom_minimum_size = Vector2(330, 78)
  bg.add_theme_stylebox_override("panel",_rounded(Color(0.05,0.10,0.12,0.87),12))
  hud.add_child(bg)
  var margin := MarginContainer.new()
  margin.add_theme_constant_override("margin_left",12)
  margin.add_theme_constant_override("margin_right",12)
  margin.add_theme_constant_override("margin_top",8)
  margin.add_theme_constant_override("margin_bottom",8)
  bg.add_child(margin)
  _game_status=Label.new()
  _game_status.add_theme_font_size_override("font_size",17)
  _game_status.text="心魇说 · 凡人\n体力载入中 · 生命/灵力未实现"
  margin.add_child(_game_status)
  _game_menu_button("角色",16,"character")
  _game_menu_button("背包",119,"inventory")
  _game_menu_button("修炼",222,"cultivation")
  _game_sheet=PanelContainer.new()
  _game_sheet.name="Rev188CharacterInventoryCultivationMenu"
  _game_sheet.position=Vector2(16,150)
  _game_sheet.custom_minimum_size=Vector2(355,220)
  _game_sheet.visible=false
  _game_sheet.add_theme_stylebox_override("panel",_rounded(Color(0.06,0.11,0.13,0.95),12))
  hud.add_child(_game_sheet)
  var v:=VBoxContainer.new()
  v.add_theme_constant_override("separation",9)
  _game_sheet.add_child(v)
  _game_sheet_title=Label.new()
  _game_sheet_title.add_theme_font_size_override("font_size",22)
  v.add_child(_game_sheet_title)
  _game_sheet_body=Label.new()
  _game_sheet_body.add_theme_font_size_override("font_size",17)
  v.add_child(_game_sheet_body)
  var close:=Button.new()
  close.text="关闭"
  close.pressed.connect(func(): _game_sheet.visible=false)
  v.add_child(close)
  _refresh_game_hud()

func _open_game_menu(mode: String) -> void:
  if _game_sheet_mode==mode and _game_sheet.visible:
    _game_sheet.visible=false
    return
  _game_sheet_mode=mode
  _game_sheet.visible=true
  _refresh_game_hud()

func _refresh_game_hud() -> void:
  if _game_status==null or room==null:
    return
  var sim = room.get("sim")
  if sim==null:
    return
  var persons: Dictionary=sim.get("citizens")
  var person: Dictionary=persons.get(PLAYER_ID,{})
  var energy: int=int(person.get("energy",0))
  _game_status.text="心魇说 · 凡人  |  体力 "+str(energy)+"\n生命：未接入    灵力：未觉醒"
  if _game_sheet==null or not _game_sheet.visible:
    return
  if _game_sheet_mode=="character":
    _game_sheet_title.text="角色 · 当前状态"
    _game_sheet_body.text="体力："+str(energy)+"\n身份：村庄居民\n生命／灵力／装备：尚未实现"
  elif _game_sheet_mode=="inventory":
    _game_sheet_title.text="背包 · 真实采集物资"
    var carried: Dictionary=sim.get("carried_by_actor")
    if carried.has(PLAYER_ID):
      var item: Dictionary=carried[PLAYER_ID]
      _game_sheet_body.text="携带："+String(item.get("kind","未知"))+" ×"+str(item.get("amount",0))+"\n回仓库点击「互动」交付"
    else:
      _game_sheet_body.text="随身背包空\n靠近树木、石块点击「互动」采集"
  else:
    _game_sheet_title.text="修炼 · 凡人"
    _game_sheet_body.text="灵根检测：未开放\n功法／招式／灵力：尚未接入\n没有虚构的技能数值"

func _layout_hud() -> void:
  if hud == null:
    return
  var size: Vector2 = room.get_viewport().get_visible_rect().size
  joystick_ring.position = Vector2(27,maxf(150.0,size.y-178.0))
  (buttons["PerspectiveButton"] as Button).position = Vector2(size.x-165,18)
  (buttons["GodViewButton"] as Button).position = Vector2(size.x-165,79)
  (buttons["FlyViewButton"] as Button).position = Vector2(size.x-165,139)
  (buttons["FlyUpButton"] as Button).position = Vector2(size.x-168,maxf(235,size.y-299))
  (buttons["FlyDownButton"] as Button).position = Vector2(size.x-168,maxf(296,size.y-238))
  (buttons["ResetViewButton"] as Button).position = Vector2(size.x-330,18)
  (buttons["FlyUpButton"] as Button).visible = camera_mode=="fly"
  (buttons["FlyDownButton"] as Button).visible = camera_mode=="fly"
  (buttons["ZoomInButton"] as Button).position = Vector2(size.x-303,maxf(95,size.y-190))
  (buttons["ZoomOutButton"] as Button).position = Vector2(size.x-303,maxf(155,size.y-128))
  (buttons["InteractButton"] as Button).position = Vector2(size.x-159,maxf(95,size.y-190))
  (buttons["DigButton"] as Button).position = Vector2(size.x-159,maxf(155,size.y-128))
  notice.position = Vector2(minf(315,size.x*0.25),maxf(210,size.y-56))

func _ui_button_at(p: Vector2) -> bool:
  for node in buttons.values():
    var button: Button = node
    if button.visible and button.get_global_rect().has_point(p):
      return true
  return false

func _on_joystick_gui(event: InputEvent) -> void:
  if not _enabled:
    return
  if event is InputEventScreenTouch:
    _gui_input_events += 1
    if event.pressed:
      if _joystick_touch < 0:
        _joystick_touch = event.index
        _move_joystick_local(event.position)
    elif event.index == _joystick_touch:
      _release_stick()
    joystick_ring.accept_event()
  elif event is InputEventScreenDrag and event.index == _joystick_touch:
    _gui_input_events += 1
    _move_joystick_local(event.position)
    joystick_ring.accept_event()
  elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
    _gui_input_events += 1
    if event.pressed:
      _joystick_touch = -2
      _move_joystick_local(event.position)
    elif _joystick_touch == -2:
      _release_stick()
    joystick_ring.accept_event()
  elif event is InputEventMouseMotion and _joystick_touch == -2:
    _move_joystick_local(event.position)
    joystick_ring.accept_event()

func _move_joystick_local(local_pos: Vector2) -> void:
  # GUI events use CONTROL-LOCAL coordinates. rev184 subtracted the
  # viewport-global thumb center from this local event, producing zero
  # movement or wrong axis on scaled Android screens.
  var axis: Vector2 = (local_pos-Vector2(73,73))/60.0
  _joystick = axis.limit_length(1.0)
  thumb_panel.position = Vector2(41,41)+_joystick*42.0
  _auto_walking = false
  _follow_npc = false
  room.set("_follow_builder",false)

func _on_left_world_gui(event: InputEvent) -> void:
  if not _enabled:
    return
  if event is InputEventScreenTouch:
    _gui_input_events += 1
    if event.pressed:
      _touch_started[event.index] = event.position
    else:
      if _touch_started.has(event.index):
        if event.position.distance_to(_touch_started[event.index]) < 24.0:
          tap_world(event.position+_left_world_zone.global_position)
      _touch_started.erase(event.index)
    _left_world_zone.accept_event()
  elif event is InputEventScreenDrag:
    # Left-area finger is *not* the look finger; no camera collision.
    _gui_input_events += 1
    _left_world_zone.accept_event()
  elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
    if event.pressed:
      _touch_started[-3] = event.position
    else:
      if _touch_started.has(-3) and event.position.distance_to(_touch_started[-3])<24:
        tap_world(event.position+_left_world_zone.global_position)
      _touch_started.erase(-3)
    _left_world_zone.accept_event()

func _on_right_world_gui(event: InputEvent) -> void:
  if not _enabled:
    return
  if event is InputEventScreenTouch:
    _gui_input_events += 1
    if event.pressed:
      _right_touches[event.index] = event.position
      _touch_started[event.index] = event.position
      if _look_touch < 0:
        _look_touch = event.index
    else:
      if _touch_started.has(event.index):
        var travel: float = (event.position as Vector2).distance_to(_touch_started[event.index])
        if travel < 19.0 and _right_touches.size() == 1:
          tap_world(event.position + _look_zone.global_position)
      _right_touches.erase(event.index)
      _touch_started.erase(event.index)
      if _look_touch == event.index:
        _look_touch = -1
        for touch_id in _right_touches:
          _look_touch = int(touch_id)
          break
      _last_pinch = -1.0
    _look_zone.accept_event()
  elif event is InputEventScreenDrag and _right_touches.has(event.index):
    _gui_input_events += 1
    _right_touches[event.index] = event.position
    if _right_touches.size() >= 2:
      var positions: Array = _right_touches.values()
      var pinch_distance: float = (positions[0] as Vector2).distance_to(positions[1] as Vector2)
      if _last_pinch>1.0:
        zoom_ratio(pinch_distance/_last_pinch)
      _last_pinch = pinch_distance
    elif event.index == _look_touch:
      turn_view(event.relative)
    _look_zone.accept_event()
  elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
    _gui_input_events += 1
    if event.pressed:
      _touch_started[-2] = event.position
    else:
      if _touch_started.has(-2) and event.position.distance_to(_touch_started[-2]) < 19:
        tap_world(event.position + _look_zone.global_position)
      _touch_started.erase(-2)
    _look_zone.accept_event()
  elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
    turn_view(event.relative)
    _look_zone.accept_event()

func tap_world(screen_position: Vector2) -> Dictionary:
  if actor == null or camera == null:
    return {"ok":false,"reason":"NOT_IN_WORLD"}
  # Meshes batched in MultiMesh carry authoritative per-object positions,
  # therefore Godot physics raycast on a mesh collider cannot identify the
  # clicked tree's unique system ID. Project real entity world positions,
  # select nearest pixel-correct object and approach it via player movement.
  var display: Vector2 = room.get_viewport().get_visible_rect().size
  var view: SubViewport = room.get("view")
  var source_size: Vector2 = Vector2(view.size)
  var rx: float = source_size.x/maxf(1.0,display.x)
  var ry: float = source_size.y/maxf(1.0,display.y)
  var touch_pixel: Vector2 = Vector2(screen_position.x*rx,screen_position.y*ry)
  var simulation = room.get("sim")
  var possible: Dictionary = simulation.get("resource_positions")
  var nearest: float = 53.0*maxf(rx,ry)
  var best_id: String = ""
  var best_pos: Vector3 = Vector3.ZERO
  var worker_id: String = ""
  for id in possible:
    var n: Dictionary = simulation.get("natural_nodes").get(id,{})
    if n.is_empty() or int(n.get("remaining",0)) <= 0:
      continue
    var actual_position: Vector3 = possible[id]
    if camera.is_position_behind(actual_position+Vector3(0,0.9,0)):
      continue
    var pixels: Vector2 = camera.unproject_position(actual_position+Vector3(0,0.9,0))
    var distance: float = touch_pixel.distance_to(pixels)
    if distance < nearest:
      nearest = distance
      best_id = String(id)
      best_pos = actual_position
  for id in room.get("workers"):
    var member: Dictionary = room.get("workers")[id]
    var other: Node3D = member["node"]
    if camera.is_position_behind(other.position+Vector3(0,1.0,0)):
      continue
    var d: float = touch_pixel.distance_to(camera.unproject_position(other.position+Vector3(0,1.0,0)))
    if d < nearest:
      nearest=d
      best_id = ""
      worker_id=String(id)
      best_pos=other.position
  if best_id.is_empty() and worker_id.is_empty():
    return {"ok":false,"reason":"NO_TARGET_UNDER_FINGER"}
  _touch_tap_count += 1
  _auto_resource_id = best_id
  _auto_npc_id = worker_id
  _auto_target = best_pos
  _auto_walking = true
  if Vector2(actor.position.x-best_pos.x,actor.position.z-best_pos.z).length() < 3.0:
    _auto_walking = false
    return interact()
  say("已选择实体，正在走近：" + (worker_id if not worker_id.is_empty() else best_id))
  return {"ok":true,"action":"approach_target","entity_id":worker_id if not worker_id.is_empty() else best_id}

func _stick_center() -> Vector2:
  return joystick_ring.global_position + Vector2(73,73)

func _move_joystick(touch: Vector2) -> void:
  var v: Vector2 = (touch-_stick_center())/60.0
  _joystick = v.limit_length(1.0)
  thumb_panel.position = Vector2(41,41) + _joystick*42.0
  _follow_npc = false
  room.set("_follow_builder",false)

func _release_stick() -> void:
  _joystick_touch = -1
  _joystick = Vector2.ZERO
  if thumb_panel != null:
    thumb_panel.position = Vector2(41,41)

func handle_input(event: InputEvent) -> void:
  if not _enabled:
    return
  # All Android touchscreen touch/drags go through TRUE GUI hit-test zones.
  # Global input is only keyboard/mouse wheel and controller fallback.
  if event is InputEventMagnifyGesture:
    zoom_ratio(event.factor)
  elif event is InputEventMouseButton and event.pressed:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP:
      zoom_in()
    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
      zoom_out()
  elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
    turn_view(event.relative)
  elif event is InputEventKey and event.pressed and not event.echo:
    if event.keycode == KEY_C:
      toggle_perspective()
    elif event.keycode == KEY_E:
      interact()
    elif event.keycode == KEY_F:
      dig()
    elif event.keycode == KEY_EQUAL:
      zoom_in()
    elif event.keycode == KEY_MINUS:
      zoom_out()

func turn_view(movement: Vector2) -> void:
  _follow_npc = false
  room.set("_follow_builder",false)
  _yaw -= movement.x*0.0050
  # User phone feedback: drag DOWN must look DOWN, NEVER up.
  # Reverse rev186 vertical sense across first/third/god/fly.
  if camera_mode=="first" or camera_mode=="fly":
    _pitch=clampf(_pitch-movement.y*0.0029,-1.30,1.24)
  elif camera_mode=="god":
    _pitch=clampf(_pitch-movement.y*0.0029,0.65,1.52)
  else:
    _pitch=clampf(_pitch-movement.y*0.0029,0.08,1.20)
  update_camera()

func zoom_ratio(factor: float) -> void:
  if factor<=0.0 or camera_mode=="first":
    return
  if camera_mode=="god":
    _god_distance=clampf(_god_distance/maxf(factor,0.08),8.0,175.0)
  elif camera_mode=="fly":
    _flight_position += Vector3(0,clampf((factor-1.0)*2.0,-4.0,4.0),0)
  else:
    _distance=clampf(_distance/maxf(factor,0.08),2.3,65.0)
    room.set("_camera_distance",_distance)
  update_camera()

func zoom_in() -> void:
  zoom_ratio(1.28)

func zoom_out() -> void:
  zoom_ratio(0.78)

func toggle_perspective() -> void:
  _set_mode("third" if camera_mode=="first" else "first")

func toggle_god_view() -> void:
  _set_mode("third" if camera_mode=="god" else "god")

func toggle_fly_view() -> void:
  _set_mode("third" if camera_mode=="fly" else "fly")

func _set_mode(mode: String) -> void:
  if not ["first","third","god","fly"].has(mode):
    return
  camera_mode=mode
  is_first_person=mode=="first"
  _auto_walking=false
  room.set("_follow_builder",false)
  _follow_npc=false
  if actor!=null:
    actor.visible=not is_first_person
  if mode=="god":
    _god_focus=actor.position if actor!=null else Vector3.ZERO
    _god_distance=maxf(_god_distance,23.0)
    _pitch=1.31
    say("上帝视角：左摇杆平移地图 · 双指缩放 · 右侧旋转")
  elif mode=="fly":
    _flight_position=camera.position if camera!=null else Vector3(1,12,7)
    _flight_position.y=maxf(_flight_position.y,4.5)
    _pitch=0.0
    say("自由飞行：左摇杆前后左右 · 升高/降低自由穿行")
  elif mode=="first":
    _pitch=0.0
    say("第一视角：手指向下滑=向下看，向上滑=抬头")
  else:
    _pitch=0.38
    say("第三视角：镜头自动避开建材和墙壁")
  (buttons["PerspectiveButton"] as Button).text="第三视角" if mode=="first" else "第一视角"
  (buttons["GodViewButton"] as Button).text="退出上帝" if mode=="god" else "上帝视角"
  (buttons["FlyViewButton"] as Button).text="退出飞行" if mode=="fly" else "自由飞行"
  update_camera()
  _layout_hud()

func fly_up() -> void:
  if camera_mode=="fly":
    _flight_position.y=minf(130.0,_flight_position.y+2.5)
    _flight_m+=2.5
    update_camera()

func fly_down() -> void:
  if camera_mode=="fly":
    _flight_position.y=maxf(1.0,_flight_position.y-2.5)
    _flight_m+=2.5
    update_camera()

func reset_camera() -> void:
  _yaw=0.43
  _pitch=0.38
  _distance=14.0
  room.set("_follow_builder",false)
  _auto_walking=false
  _set_mode("third")
  say("镜头已复位：你没有被固定在建筑或镜头里面")

func _forward() -> Vector3:
  return Vector3(-sin(_yaw),0,-cos(_yaw))

func _right() -> Vector3:
  return Vector3(cos(_yaw),0,-sin(_yaw))

func _keyboard_axis() -> Vector2:
  var result := Vector2.ZERO
  if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
    result.x -= 1.0
  if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
    result.x += 1.0
  if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
    result.y -= 1.0
  if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
    result.y += 1.0
  return result.limit_length(1.0)

func step(delta: float) -> void:
  if not _enabled or actor == null:
    return
  var input_axis: Vector2 = _joystick
  var keys: Vector2 = _keyboard_axis()
  if keys.length() > 0.01:
    input_axis = keys
  if input_axis.length() <= 0.08 and _auto_walking:
    var to_target: Vector3 = _auto_target - actor.position
    to_target.y = 0.0
    if to_target.length()<=2.7:
      _auto_walking = false
      interact()
    else:
      var auto_motion: Vector3 = to_target.normalized()
      input_axis = Vector2(auto_motion.dot(_right()),-auto_motion.dot(_forward()))
  if input_axis.length()>0.08 and camera_mode=="god":
    var pan: Vector3=(_right()*input_axis.x+_forward()*(-input_axis.y)).normalized()
    _god_focus+=pan*maxf(7.0,_god_distance*0.55)*delta
    _god_focus.x=clampf(_god_focus.x,-285,285)
    _god_focus.z=clampf(_god_focus.z,-285,285)
    _flight_m+=pan.length()*delta
    _set_movement_animation(false)
  elif input_axis.length()>0.08 and camera_mode=="fly":
    var flight_dir: Vector3=(_right()*input_axis.x+_forward()*(-input_axis.y)).normalized()
    _flight_position+=flight_dir*clampf(9.5+(_flight_position.y*0.15),9.5,22.0)*delta
    _flight_position.x=clampf(_flight_position.x,-300,300)
    _flight_position.z=clampf(_flight_position.z,-300,300)
    _flight_m+=flight_dir.length()*delta
    _set_movement_animation(false)
  elif input_axis.length()>0.08:
    _follow_npc = false
    room.set("_follow_builder",false)
    var motion: Vector3 = (_right()*input_axis.x + _forward()*(-input_axis.y)).normalized()
    var velocity: float = MOVE_SPEED
    var candidate: Vector3 = actor.position + motion*velocity*delta
    var nearby_height: float = float(terrain.call("height_at",candidate.x,candidate.z))
    var current_height: float = float(terrain.call("height_at",actor.position.x,actor.position.z))
    if absf(candidate.x) < 42.0 and absf(candidate.z)<42.0 and not bool(terrain.call("is_water",candidate.x,candidate.z)):
      if nearby_height-current_height <= 0.85:
        actor.position.x = candidate.x
        actor.position.z = candidate.z
        _movement_m += velocity*delta
    actor.rotation.y = atan2(motion.x,motion.z)
    _set_movement_animation(true)
  else:
    _set_movement_animation(false)
  # Character visual standing on actual physical surface, not a 2D painted
  # panel. Re-snap to the currently excavated triangle beneath the feet.
  actor.position.y = float(terrain.call("height_at",actor.position.x,actor.position.z)) + float(actor.get_meta("actor_ground_offset_y",0.0))
  if not bool(room.get("_follow_builder")):
    update_camera()
  if _hud_flash>0.0:
    _hud_flash = maxf(0,_hud_flash-delta)
    if _hud_flash<=0:
      notice.text = "左摇杆移动 | 右侧看世界 | 双指缩放 | 互动/挖掘"
  _refresh_game_hud()
  _layout_hud()

func _set_movement_animation(moving: bool) -> void:
  if animator == null:
    return
  var animation: String = walking if moving else idle
  if not animation.is_empty() and animator.current_animation != animation:
    animator.play(animation)

func _safe_camera_position(target: Vector3, desired: Vector3) -> Vector3:
  if world==null or world.get_world_3d()==null:
    return desired
  # Original art had no PhysicsBody3D -> add them to stage props in scene.
  # Cast from player head to desired camera. Stop before the first wall.
  var ray: PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(
    target,desired,3)
  ray.collide_with_areas=false
  var hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(ray)
  if hit.is_empty():
    return desired
  var hit_position: Vector3=hit["position"]
  _camera_collision_hits+=1
  var step: Vector3=(desired-target).normalized()
  var safe_distance: float=maxf(0.65,target.distance_to(hit_position)-0.38)
  return target+step*safe_distance

func update_camera() -> void:
  if camera==null or actor==null:
    return
  camera.near=0.08
  if camera_mode=="fly":
    camera.position=_flight_position
    camera.look_at(camera.position+Vector3(-sin(_yaw)*cos(_pitch),
      sin(_pitch),-cos(_yaw)*cos(_pitch)),Vector3.UP)
    return
  if camera_mode=="god":
    var origin: Vector3=_god_focus+Vector3(0,1.5,0)
    var orbit:=Vector3(sin(_yaw)*cos(_pitch),
      sin(_pitch),cos(_yaw)*cos(_pitch))
    var desired: Vector3=origin+orbit*_god_distance
    camera.position=_safe_camera_position(origin,desired)
    camera.look_at(origin,Vector3.UP)
    return
  if bool(room.get("_follow_builder")):
    var target: Vector3=room.get("_camera_focus")
    _distance=clampf(float(room.get("_camera_distance")),3.1,38.0)
    var projected: Vector3=target+Vector3(
      sin(_yaw)*cos(_pitch)*_distance,sin(_pitch)*_distance,
      cos(_yaw)*cos(_pitch)*_distance)
    camera.position=_safe_camera_position(target,projected)
    camera.look_at(target,Vector3.UP)
    return
  if is_first_person:
    camera.position=Vector3(actor.position.x,
      float(terrain.call("height_at",actor.position.x,actor.position.z))+1.65,
      actor.position.z)
    camera.look_at(camera.position+Vector3(-sin(_yaw)*cos(_pitch),
      sin(_pitch),-cos(_yaw)*cos(_pitch)),Vector3.UP)
  else:
    var target: Vector3=Vector3(actor.position.x,
      float(terrain.call("height_at",actor.position.x,actor.position.z))+1.35,
      actor.position.z)
    var offset:=Vector3(sin(_yaw)*cos(_pitch),
      sin(_pitch),cos(_yaw)*cos(_pitch))
    var desired: Vector3=target+offset*_distance
    desired.y=maxf(desired.y,float(terrain.call("height_at",desired.x,desired.z))+0.7)
    camera.position=_safe_camera_position(target,desired)
    camera.look_at(target,Vector3.UP)

func say(message: String) -> void:
  if notice != null:
    notice.text = message
    _hud_flash = 5.5

func interact() -> Dictionary:
  if actor == null:
    return {"ok":false,"reason":"PLAYER_NOT_SPAWNED"}
  var point: Vector3 = actor.position
  var sim = room.get("sim")
  var eco = room.get("eco")
  # The unique player/world/entity system IDs stay in the authoritative
  # simulation ledger. Do not display them as giant in-world labels.
  var depot := Vector3(0,0,10)
  if point.distance_to(depot)<3.8:
    var delivered: bool = sim.deliver_carried(PLAYER_ID)
    if delivered:
      var seed_amount: int = eco.delivered_seed_from_actor(PLAYER_ID)
      say("木石真实入库！种子入库 " + str(seed_amount))
      _interaction_count += 1
      return {"ok":true,"action":"warehouse_delivery"}
    say("仓库：靠近树石互动采集，再带物资回来交付")
    _interaction_count += 1
    return {"ok":true,"action":"warehouse_information"}
  var best_id: String = ""
  var best_distance: float = 3.3
  var nodes: Dictionary = sim.get("natural_nodes")
  for id in nodes:
    var node: Dictionary = nodes[id]
    if int(node["remaining"])<=0:
      continue
    var positions: Dictionary = sim.get("resource_positions")
    var resource: Vector3 = positions[id]
    var distance: float = Vector2(resource.x-point.x,resource.z-point.z).length()
    if distance<best_distance:
      best_distance = distance
      best_id = String(id)
  # A directly tapped object takes precedence over merely nearby objects.
  if not _auto_resource_id.is_empty():
    var selected_nodes: Dictionary = sim.get("natural_nodes")
    if selected_nodes.has(_auto_resource_id) and int(selected_nodes[_auto_resource_id]["remaining"])>0:
      best_id = _auto_resource_id
    _auto_resource_id = ""
  if not best_id.is_empty():
    if sim.get("carried_by_actor").has(PLAYER_ID):
      say("背包已装材料！回到仓库交付才能再采集")
      return {"ok":false,"reason":"PLAYER_CARRYING"}
    if not sim.gather_to_actor(PLAYER_ID,best_id):
      say("暂无体力或物资被占用")
      return {"ok":false,"reason":"HARVEST_GATE"}
    var target: Dictionary = nodes[best_id]
    if String(target["kind"])=="tree" and int(target["remaining"])==0:
      eco.on_tree_cut_to_zero(PLAYER_ID,best_id)
    if room.get("natural_meshes").has(best_id) and int(target["remaining"])<=0:
      (room.get("natural_meshes")[best_id] as Node3D).visible = false
    _interaction_count += 1
    say("你采集了 " + best_id + "，材料在随身背包，必须送仓库")
    return {"ok":true,"action":"gather","entity_id":best_id}
  for npc_id in room.get("workers"):
    if not _auto_npc_id.is_empty() and npc_id != _auto_npc_id:
      continue
    var npc: Dictionary = room.get("workers")[npc_id]
    var target: Node3D = npc["node"]
    if target.position.distance_to(point)<3.3:
      _interaction_count += 1
      say("交谈：" + npc_id + " · 职业=" + String(npc["kind"]) + " · 工作=" + String(npc["phase"]))
      return {"ok":true,"action":"npc_dialogue","entity_id":npc_id}
  _auto_npc_id = ""
  if bool(terrain.call("is_water",point.x,point.z-3.0)):
    _interaction_count += 1
    say("浅水池：真实挖出河床地形，水不允许凭空变成石块")
    return {"ok":true,"action":"water"}
  say("走近树木、石块、工人或仓库后再点「互动」")
  return {"ok":false,"reason":"NOT_IN_REACH"}

func dig() -> Dictionary:
  if actor == null:
    return {"ok":false,"reason":"PLAYER_NOT_SPAWNED"}
  var target: Vector3 = actor.position + _forward()*1.65
  var result: Dictionary = terrain.call("excavate_at",target,PLAYER_ID)
  if not bool(result.get("ok",false)):
    say("此处不可挖：可能是道路、仓库、河水或已到坚硬基岩")
    return result
  _dig_count += 1
  # Excavated 2x2m cells yield a finite ledger entry from the exact
  # removed subsurface layer, not free raw resources from an interaction.
  say("挖出" + String(result["kind"]) + "×1 / 深" + str(result["depth_m"]) + "米；露出真实土层")
  return result

func set_enabled(value: bool) -> void:
  _enabled = value
  if hud != null:
    hud.visible = value
  if not value:
    _auto_walking = false
    _release_stick()
    _right_touches.clear()
    _look_touch = -1

func stats() -> Dictionary:
  return {"player_exists":actor!=null and is_instance_valid(actor),
    "player_entity_id":PLAYER_ID,
    "third_person":not is_first_person,
    "first_person_available":true,
    "joystick_exists":joystick_ring!=null,
    "touch_look":true,
    "pinch_zoom":true,
    "zoom_buttons":2,
    "interaction_count":_interaction_count,
    "dig_count":_dig_count,
    "movement_m":_movement_m,
    "gui_input_events_seen":_gui_input_events,
    "click_to_select_count":_touch_tap_count,
    "left_half_world_tap_zone":_left_world_zone!=null,
    "left_zone_joystick_conflict_free":_left_world_zone!=null and joystick_ring.mouse_filter==Control.MOUSE_FILTER_STOP,
    "auto_approach_active":_auto_walking,
    "system_entity_identity_hidden_from_world_text":true,
    "camera_distance":_distance,
    "position":actor.position if actor!=null else Vector3.ZERO,
    "current_foot_height":float(terrain.call("height_at",actor.position.x,actor.position.z)) if actor!=null else 0.0,
    "camera_mode":camera_mode,"god_view_available":true,"free_flight_available":true,
    "vertical_drag_inverted_for_phone":_view_pitch_reversed,
    "camera_collision_avoidance_hits":_camera_collision_hits,
    "flight_distance":_flight_m}
