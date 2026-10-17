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
var _rest_sheet_button: Button
# REV189: Godot 4.4 standard SDL-mapped Xbox/PS/Nintendo/USB/Bluetooth pad.
# Android hardware behavior remains subject to real device HID mapping QA.
const PAD_DEFAULT_DEADZONE: float = 0.19
const PAD_LOOK_PIXELS_PER_SECOND: float = 205.0
var _pad_device: int = -1
var _pad_device_name: String = ""
var _pad_deadzone: float = PAD_DEFAULT_DEADZONE
var _pad_sensitivity: float = 1.0
var _pad_invert_y: bool = false
var _pad_trigger_left_latched: bool = false
var _pad_trigger_right_latched: bool = false
var _pad_hint: Label
var _pad_setting_speed: Button
var _pad_setting_invert: Button
var _pad_setting_deadzone: Button
var _pad_menu_index: int = 0
var _pad_menu_options: Array[Button] = []
var _pad_button_event_count: int = 0
var _pad_last_move: Vector2 = Vector2.ZERO
var _pad_last_look: Vector2 = Vector2.ZERO
var _pad_status: String = "未连接"

func initialize(active_room: Node) -> void:
  room = active_room
  world = room.get("world")
  camera = room.get("camera")
  terrain = room.get("terrain_world")
  name = "PlayerActualTouchAndPerspectiveController"
  _spawn_player()
  _load_pad_options()
  _create_hud()
  if not Input.joy_connection_changed.is_connected(_on_pad_hotplug):
    Input.joy_connection_changed.connect(_on_pad_hotplug)
  _detect_pad()
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
  actor.set_meta("health",_player_health)
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
  bg.custom_minimum_size = Vector2(347, 122)
  bg.add_theme_stylebox_override("panel",_rounded(Color(0.05,0.10,0.12,0.87),12))
  hud.add_child(bg)
  var margin := MarginContainer.new()
  margin.add_theme_constant_override("margin_left",12)
  margin.add_theme_constant_override("margin_right",12)
  margin.add_theme_constant_override("margin_top",8)
  margin.add_theme_constant_override("margin_bottom",8)
  bg.add_child(margin)
  var meters := VBoxContainer.new()
  meters.add_theme_constant_override("separation",4)
  margin.add_child(meters)
  _game_status=Label.new()
  _game_status.add_theme_font_size_override("font_size",17)
  _game_status.text="心魇说 · 凡人"
  meters.add_child(_game_status)
  var hp_row:=HBoxContainer.new()
  meters.add_child(hp_row)
  var hp_caption:=Label.new()
  hp_caption.text="生命  "
  hp_row.add_child(hp_caption)
  _health_bar=ProgressBar.new()
  _health_bar.name="RealHealthFromFallDamageAndFood"
  _health_bar.max_value=100
  _health_bar.value=100
  _health_bar.show_percentage=false
  _health_bar.custom_minimum_size=Vector2(242,13)
  _health_bar.add_theme_stylebox_override("background",_rounded(Color("#243133"),5))
  _health_bar.add_theme_stylebox_override("fill",_rounded(Color("#b95f59"),5))
  hp_row.add_child(_health_bar)
  var stamina_row:=HBoxContainer.new()
  meters.add_child(stamina_row)
  var energy_caption:=Label.new()
  energy_caption.text="体力  "
  stamina_row.add_child(energy_caption)
  _energy_bar=ProgressBar.new()
  _energy_bar.name="ActualWorldCitizenEnergy"
  _energy_bar.max_value=100
  _energy_bar.value=100
  _energy_bar.show_percentage=false
  _energy_bar.custom_minimum_size=Vector2(242,13)
  _energy_bar.add_theme_stylebox_override("background",_rounded(Color("#243133"),5))
  _energy_bar.add_theme_stylebox_override("fill",_rounded(Color("#a8bc68"),5))
  stamina_row.add_child(_energy_bar)
  _spirit_notice=Label.new()
  _spirit_notice.text="灵力：未检测灵根（未解锁）"
  _spirit_notice.add_theme_font_size_override("font_size",14)
  _spirit_notice.add_theme_color_override("font_color",Color("#aec5d1"))
  meters.add_child(_spirit_notice)
  _game_menu_button("角色",16,"character")
  _game_menu_button("背包",119,"inventory")
  _game_menu_button("修炼",222,"cultivation")
  _game_menu_button("菜单",325,"settings")
  _game_sheet=PanelContainer.new()
  _game_sheet.name="Rev188CharacterInventoryCultivationMenu"
  _game_sheet.position=Vector2(16,150)
  _game_sheet.custom_minimum_size=Vector2(405,245)
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
  _quality_sheet_button=Button.new()
  _quality_sheet_button.name="QualitySettingsFromGameMenu"
  _quality_sheet_button.text="画质 / 帧率"
  _quality_sheet_button.pressed.connect(func(): room.call("_toggle_quality_settings"))
  v.add_child(_quality_sheet_button)
  _developer_sheet_button=Button.new()
  _developer_sheet_button.name="OptionalDeveloperTools"
  _developer_sheet_button.text="开发工具（默认关闭）"
  _developer_sheet_button.pressed.connect(func(): room.call("_set_dev_ui_visible",not bool(room.get("developer_ui_visible"))))
  v.add_child(_developer_sheet_button)
  _rest_sheet_button=Button.new()
  _rest_sheet_button.name="EatRealWarehouseFoodToRest"
  _rest_sheet_button.text="在仓库消耗食物休整"
  _rest_sheet_button.pressed.connect(Callable(self,"rest_and_eat"))
  v.add_child(_rest_sheet_button)
  _add_game_action("GatherAction","采集",Callable(self,"gather_action"))
  _add_game_action("DashAction","疾步",Callable(self,"dash_action"))
  _add_game_action("DigAction","挖掘",Callable(self,"dig"))
  _add_game_action("InteractAction","互动",Callable(self,"interact"))
  _add_game_action("ViewAction","视角",Callable(self,"toggle_perspective"))
  _add_game_action("LockedArt","招式锁定",func(): _open_game_menu("cultivation"))
  (_game_actions["LockedArt"] as Button).disabled=true
  _pad_hint=Label.new()
  _pad_hint.name="AndroidGamepadHotplugAndMappings"
  _pad_hint.position=Vector2(16,139)
  _pad_hint.add_theme_font_size_override("font_size",14)
  _pad_hint.add_theme_color_override("font_color",Color("#e0edd4"))
  _pad_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
  hud.add_child(_pad_hint)
  _pad_setting_speed=Button.new()
  _pad_setting_speed.name="PadRightStickSpeedSetting"
  _pad_setting_speed.pressed.connect(_cycle_pad_sensitivity)
  v.add_child(_pad_setting_speed)
  _pad_setting_invert=Button.new()
  _pad_setting_invert.name="PadRightStickInvertSetting"
  _pad_setting_invert.pressed.connect(_toggle_pad_invert)
  v.add_child(_pad_setting_invert)
  _pad_setting_deadzone=Button.new()
  _pad_setting_deadzone.name="PadStickDeadzoneSetting"
  _pad_setting_deadzone.pressed.connect(_cycle_pad_deadzone)
  v.add_child(_pad_setting_deadzone)
  _refresh_pad_option_labels()
  _refresh_game_hud()

func _add_game_action(key: String, label: String, callback: Callable) -> void:
  var button:=Button.new()
  button.name="MobileGameplay_"+key
  button.text=label
  button.size=Vector2(89,57)
  button.add_theme_font_size_override("font_size",18)
  button.add_theme_stylebox_override("normal",_rounded(Color(0.09,0.21,0.19,0.86),11))
  button.add_theme_stylebox_override("disabled",_rounded(Color(0.14,0.17,0.18,0.70),11))
  button.pressed.connect(callback)
  hud.add_child(button)
  _game_actions[key]=button

func _open_game_menu(mode: String) -> void:
  if _game_sheet_mode==mode and _game_sheet.visible:
    _game_sheet.visible=false
    return
  _game_sheet_mode=mode
  _game_sheet.visible=true
  _refresh_game_hud()
  if _pad_device>=0:
    _pad_focus_menu(0)

func _refresh_game_hud() -> void:
  if _game_status==null or room==null:
    return
  var sim = room.get("sim")
  if sim==null:
    return
  var persons: Dictionary=sim.get("citizens")
  var person: Dictionary=persons.get(PLAYER_ID,{})
  var energy: int=int(person.get("energy",0))
  _health_bar.value=_player_health
  _energy_bar.value=energy
  _game_status.text="心魇说 · 凡人   "+str(_player_health)+"/100"
  (_game_actions["DashAction"] as Button).disabled=_dash_cd>0.0 or energy<8
  (_game_actions["DashAction"] as Button).text="疾步 "+str(ceili(_dash_cd))+"秒" if _dash_cd>0.0 else "疾步"
  (_game_actions["GatherAction"] as Button).disabled=_gather_cd>0.0
  (_game_actions["GatherAction"] as Button).text="采集 "+str(ceili(_gather_cd))+"秒" if _gather_cd>0.0 else "采集"
  _quality_sheet_button.visible=_game_sheet!=null and _game_sheet.visible and _game_sheet_mode=="settings"
  _developer_sheet_button.visible=_quality_sheet_button.visible
  _rest_sheet_button.visible=_game_sheet.visible and _game_sheet_mode=="character"
  _pad_setting_speed.visible=_game_sheet.visible and _game_sheet_mode=="settings"
  _pad_setting_invert.visible=_pad_setting_speed.visible
  _pad_setting_deadzone.visible=_pad_setting_speed.visible
  _pad_hint.visible=_pad_device>=0 and not _game_sheet.visible
  if _game_sheet==null or not _game_sheet.visible:
    return
  if _game_sheet_mode=="character":
    _game_sheet_title.text="角色 · 当前状态"
    _game_sheet_body.text="生命："+str(_player_health)+"/100  体力："+str(energy)+"/100\n饥饿："+str(person.get("hunger",0))+"  年龄："+str(person.get("age",21))+"\n身份：凡人旅者  灵根尚未鉴定\n当前生命可受跌落伤害、消耗食物恢复"
  elif _game_sheet_mode=="inventory":
    _game_sheet_title.text="背包 · 真实采集物资"
    var carried: Dictionary=sim.get("carried_by_actor")
    if carried.has(PLAYER_ID):
      var item: Dictionary=carried[PLAYER_ID]
      _game_sheet_body.text="携带："+String(item.get("kind","未知"))+" ×"+str(item.get("amount",0))+"\n回仓库点击「互动」交付"
    else:
      _game_sheet_body.text="随身背包空\n靠近树木、石块点击「互动」采集"
  elif _game_sheet_mode=="cultivation":
    _game_sheet_title.text="修炼 · 凡人"
    _game_sheet_body.text="灵根检测：尚未开放\n境界：凡人  法力：未解锁\n采集/疾步属于凡人生存动作，不冒充修仙法术"
  else:
    _game_sheet_title.text="菜单 · 系统设置"
    _game_sheet_body.text="横屏触控：左侧走路，右侧旋转\n视角按键：切第一/第三视角\n画质帧率和研发工具在下方设置"

# Real mortal actions, consuming the same finite-resource ledger as NPCs.
func gather_action() -> Dictionary:
  if _gather_cd>0.0:
    return {"ok":false,"reason":"COOLDOWN"}
  var result: Dictionary=interact()
  if bool(result.get("ok",false)) and String(result.get("action",""))=="gather":
    _gather_cd=1.0
  return result

func dash_action() -> bool:
  if actor==null or _dash_cd>0.0 or camera_mode in ["god","fly"]:
    return false
  var sim=room.get("sim")
  var person: Dictionary=sim.citizens.get(PLAYER_ID,{})
  if int(person.get("energy",0))<8:
    say("体力不足，无法疾步")
    return false
  var target: Vector3=actor.position+_forward()*2.0
  if absf(target.x)>=41.0 or absf(target.z)>=41.0 or bool(terrain.call("is_water",target.x,target.z)):
    say("前方地形无法通行")
    return false
  var surface_y: float=float(terrain.call("height_at",target.x,target.z))
  var origin_y: float=float(terrain.call("height_at",actor.position.x,actor.position.z))
  if absf(surface_y-origin_y)>0.65:
    say("前方坡面过陡")
    return false
  var ray:=PhysicsRayQueryParameters3D.create(actor.position+Vector3.UP*0.8,target+Vector3.UP*0.8)
  ray.collision_mask=2
  if not world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
    say("前方有障碍，无法穿模")
    return false
  person["energy"]=int(person["energy"])-8
  actor.position=Vector3(target.x,surface_y+float(actor.get_meta("actor_ground_offset_y",0.0)),target.z)
  _movement_m+=2.0
  _dash_cd=3.0
  _set_movement_animation(true)
  update_camera()
  _refresh_game_hud()
  return true

func apply_player_damage(amount: int) -> int:
  _player_health=maxi(0,_player_health-maxi(0,amount))
  if actor!=null:
    actor.set_meta("health",_player_health)
  if _player_health==0:
    say("重伤：请到仓库休整")
  _refresh_game_hud()
  return _player_health

func rest_and_eat() -> bool:
  if actor==null or Vector2(actor.position.x,actor.position.z-10.0).length()>4.0:
    say("靠近村庄仓库才能休整")
    return false
  var sim=room.get("sim")
  if not sim.feed_citizen(PLAYER_ID):
    say("没有可消耗的真实食物")
    return false
  _player_health=mini(100,_player_health+12)
  actor.set_meta("health",_player_health)
  say("消耗村庄食物×1，恢复12生命和4体力")
  _refresh_game_hud()
  return true

func _layout_hud() -> void:
  if hud==null:
    return
  var size: Vector2=room.get_viewport().get_visible_rect().size
  joystick_ring.position=Vector2(27,maxf(150.0,size.y-178.0))
  var dev: bool=bool(room.get("developer_ui_visible"))
  var debug_places: Dictionary={
    "PerspectiveButton":Vector2(size.x-165,18),
    "GodViewButton":Vector2(size.x-165,79),
    "FlyViewButton":Vector2(size.x-165,139),
    "ResetViewButton":Vector2(size.x-330,18),
    "ZoomInButton":Vector2(size.x-303,maxf(95,size.y-190)),
    "ZoomOutButton":Vector2(size.x-303,maxf(155,size.y-128)),
    "InteractButton":Vector2(size.x-159,maxf(95,size.y-190)),
    "DigButton":Vector2(size.x-159,maxf(155,size.y-128))}
  for key in debug_places:
    (buttons[key] as Button).position=debug_places[key]
    (buttons[key] as Button).visible=dev
  (buttons["FlyUpButton"] as Button).position=Vector2(size.x-145,maxf(215,size.y-310))
  (buttons["FlyDownButton"] as Button).position=Vector2(size.x-145,maxf(275,size.y-250))
  (buttons["FlyUpButton"] as Button).visible=camera_mode=="fly"
  (buttons["FlyDownButton"] as Button).visible=camera_mode=="fly"
  # Five compact top-right tabs, not ten QA buttons scattered over scenery.
  var menu_names:=["角色","背包","修炼","菜单"]
  var menu_x: float=maxf(365.0,size.x-4.0*104.0-22.0)
  for idx in range(menu_names.size()):
    var tab: Button=hud.get_node("GameMenu_"+menu_names[idx]) as Button
    tab.position=Vector2(menu_x+float(idx)*104.0,16)
    tab.size=Vector2(96,44)
  var action_keys:=["GatherAction","DashAction","DigAction","InteractAction","ViewAction","LockedArt"]
  for idx in range(action_keys.size()):
    var col: int=idx%3
    var row: int=int(idx/3)
    (_game_actions[action_keys[idx]] as Button).position=Vector2(
      size.x-295.0+float(col)*94.0,size.y-152.0+float(row)*66.0)
  notice.position=Vector2(minf(370.0,size.x*0.27),maxf(210.0,size.y-47.0))
  if _pad_hint!=null:
    _pad_hint.position=Vector2(16,139)


# REV189: Bluetooth/USB HID pads use Godot 4.4's normalized SDL JoyButton/
# JoyAxis layout. This is not a phone-keyboard emulation layer.
func _load_pad_options() -> void:
  var cfg:=ConfigFile.new()
  if cfg.load("user://canglan_controller_v1.cfg")!=OK:
    return
  _pad_deadzone=clampf(float(cfg.get_value("pad","deadzone",PAD_DEFAULT_DEADZONE)),0.12,0.35)
  _pad_sensitivity=clampf(float(cfg.get_value("pad","look_sensitivity",1.0)),0.7,1.6)
  _pad_invert_y=bool(cfg.get_value("pad","invert_y",false))

func _save_pad_options() -> void:
  var cfg:=ConfigFile.new()
  cfg.set_value("pad","deadzone",_pad_deadzone)
  cfg.set_value("pad","look_sensitivity",_pad_sensitivity)
  cfg.set_value("pad","invert_y",_pad_invert_y)
  if cfg.save("user://canglan_controller_v1.cfg")!=OK:
    push_warning("手柄设置无法写入本机存储")

func _refresh_pad_option_labels() -> void:
  if _pad_setting_speed==null:
    return
  _pad_setting_speed.text="右摇杆速度："+str(_pad_sensitivity)+"倍"
  _pad_setting_invert.text="右摇杆上下反转："+("开启" if _pad_invert_y else "关闭")
  _pad_setting_deadzone.text="双摇杆死区："+str(_pad_deadzone)

func _cycle_pad_sensitivity() -> void:
  var values: Array[float]=[0.7,1.0,1.3,1.6]
  var idx: int=values.find(_pad_sensitivity)
  _pad_sensitivity=values[(idx+1)%values.size()]
  _save_pad_options()
  _refresh_pad_option_labels()

func _toggle_pad_invert() -> void:
  _pad_invert_y=not _pad_invert_y
  _save_pad_options()
  _refresh_pad_option_labels()

func _cycle_pad_deadzone() -> void:
  var values: Array[float]=[0.12,0.19,0.27,0.35]
  var idx: int=values.find(_pad_deadzone)
  _pad_deadzone=values[(idx+1)%values.size()]
  _save_pad_options()
  _refresh_pad_option_labels()

func _on_pad_hotplug(device: int, connected: bool) -> void:
  # Keep first active controller; auto-switch if that controller disappears.
  if connected and _pad_device<0:
    _detect_pad()
  elif not connected and device==_pad_device:
    _pad_device=-1
    _pad_last_move=Vector2.ZERO
    _pad_last_look=Vector2.ZERO
    _pad_trigger_left_latched=false
    _pad_trigger_right_latched=false
    _detect_pad()

func _detect_pad() -> void:
  var devices: Array[int]=Input.get_connected_joypads()
  if devices.has(_pad_device):
    return
  _pad_device=-1
  _pad_device_name=""
  if not devices.is_empty():
    _pad_device=devices[0]
    _pad_device_name=Input.get_joy_name(_pad_device)
    _pad_status="已连接"
  else:
    _pad_status="未连接"
    _pad_menu_options.clear()
    _pad_trigger_left_latched=false
    _pad_trigger_right_latched=false
    _pad_last_move=Vector2.ZERO
    _pad_last_look=Vector2.ZERO
  if _pad_hint!=null:
    _pad_hint.text=("手柄："+_pad_device_name+
      "  A互动 X采集 Y挖掘 B疾步 · LB视角 RB背包 · Start设置" if _pad_device>=0 else "")
    _pad_hint.visible=_pad_device>=0 and not _game_sheet.visible

# Radial deadzone: no drifting after releasing either stick; preserve diagonal
# speed with a single magnitude clamp instead of independent X/Y thresholds.
func _pad_axis_deadzone(raw: Vector2) -> Vector2:
  var length: float=raw.length()
  if length<=_pad_deadzone:
    return Vector2.ZERO
  return raw.normalized()*clampf((length-_pad_deadzone)/(1.0-_pad_deadzone),0.0,1.0)

func _pad_read_stick(axis_x: int, axis_y: int) -> Vector2:
  if _pad_device<0 or not Input.get_connected_joypads().has(_pad_device):
    return Vector2.ZERO
  return _pad_axis_deadzone(Vector2(
    Input.get_joy_axis(_pad_device,axis_x),
    Input.get_joy_axis(_pad_device,axis_y)))

func _pad_apply_look(right_axis: Vector2, delta: float) -> void:
  var stick: Vector2=_pad_axis_deadzone(right_axis)
  _pad_last_look=stick
  if stick.length()<0.001 or _look_touch>=0 or _game_sheet.visible:
    return
  var y: float=-stick.y if _pad_invert_y else stick.y
  turn_view(Vector2(stick.x,y)*PAD_LOOK_PIXELS_PER_SECOND*_pad_sensitivity*delta)

func _pad_poll_triggers() -> void:
  if _pad_device<0 or not Input.get_connected_joypads().has(_pad_device) or _game_sheet.visible:
    return
  var lt: float=Input.get_joy_axis(_pad_device,JOY_AXIS_TRIGGER_LEFT)
  var rt: float=Input.get_joy_axis(_pad_device,JOY_AXIS_TRIGGER_RIGHT)
  if lt>0.65 and not _pad_trigger_left_latched:
    _pad_trigger_left_latched=true
    interact()
  elif lt<0.35:
    _pad_trigger_left_latched=false
  if rt>0.65 and not _pad_trigger_right_latched:
    _pad_trigger_right_latched=true
    gather_action()
  elif rt<0.35:
    _pad_trigger_right_latched=false

func _pad_focus_menu(index: int) -> void:
  _pad_menu_options.clear()
  if _game_sheet==null or not _game_sheet.visible:
    return
  for node in _game_sheet.find_children("*","Button",true,false):
    var button: Button=node as Button
    if button.is_visible_in_tree() and not button.disabled:
      _pad_menu_options.append(button)
  if _pad_menu_options.is_empty():
    return
  _pad_menu_index=posmod(index,_pad_menu_options.size())
  _pad_menu_options[_pad_menu_index].grab_focus()

func _pad_close_menu() -> void:
  if _game_sheet!=null:
    _game_sheet.hide()
  _pad_menu_options.clear()
  var focused: Control=room.get_viewport().gui_get_focus_owner()
  if focused!=null:
    focused.release_focus()

# Single route for real InputEventJoypadButton and injected QA button tests.
# Never modify existing touchscreen/keyboard paths to masquerade as HID.
func _pad_press_button(button: int) -> void:
  if not _enabled:
    return
  _pad_button_event_count+=1
  if button==JOY_BUTTON_START:
    _open_game_menu("settings")
    return
  if button==JOY_BUTTON_BACK:
    if _game_sheet.visible:
      _pad_close_menu()
    else:
      _open_game_menu("character")
    return
  if _game_sheet.visible:
    if button==JOY_BUTTON_B:
      _pad_close_menu()
    elif button==JOY_BUTTON_DPAD_UP:
      _pad_focus_menu(_pad_menu_index-1)
    elif button==JOY_BUTTON_DPAD_DOWN:
      _pad_focus_menu(_pad_menu_index+1)
    elif button==JOY_BUTTON_A:
      if _pad_menu_options.is_empty():
        _pad_focus_menu(0)
      if not _pad_menu_options.is_empty():
        _pad_menu_options[_pad_menu_index].pressed.emit()
    elif button==JOY_BUTTON_RIGHT_SHOULDER:
      _open_game_menu("inventory")
    elif button==JOY_BUTTON_LEFT_SHOULDER:
      _open_game_menu("character")
    return
  match button:
    JOY_BUTTON_A:
      interact()
    JOY_BUTTON_X:
      gather_action()
    JOY_BUTTON_Y:
      dig()
    JOY_BUTTON_B:
      dash_action()
    JOY_BUTTON_LEFT_SHOULDER:
      toggle_perspective()
    JOY_BUTTON_RIGHT_SHOULDER:
      _open_game_menu("inventory")
    JOY_BUTTON_LEFT_STICK:
      dash_action()
    JOY_BUTTON_RIGHT_STICK:
      reset_camera()
    JOY_BUTTON_DPAD_UP:
      if camera_mode=="fly":
        fly_up()
      else:
        zoom_in()
    JOY_BUTTON_DPAD_DOWN:
      if camera_mode=="fly":
        fly_down()
      else:
        zoom_out()
    JOY_BUTTON_DPAD_LEFT:
      _open_game_menu("character")
    JOY_BUTTON_DPAD_RIGHT:
      _open_game_menu("cultivation")

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
  if event is InputEventJoypadButton:
    if event.pressed and not event.is_echo() and event.device==_pad_device:
      _pad_press_button(int(event.button_index))
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
  _dash_cd=maxf(0.0,_dash_cd-delta)
  _gather_cd=maxf(0.0,_gather_cd-delta)
  _fall_damage_cd=maxf(0.0,_fall_damage_cd-delta)
  var previous_ground_y: float=float(terrain.call("height_at",actor.position.x,actor.position.z))
  var input_axis: Vector2 = _joystick
  # Touch joystick wins while a finger is actually manipulating it.
  if _joystick_touch<0 and _pad_device>=0:
    var pad_axis: Vector2=_pad_read_stick(JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y)
    _pad_last_move=pad_axis
    if pad_axis.length()>0.005:
      input_axis=pad_axis
  var keys: Vector2 = _keyboard_axis()
  if keys.length() > 0.01:
    input_axis = keys
  if _pad_device>=0:
    if not _game_sheet.visible:
      var right_axis: Vector2=_pad_read_stick(JOY_AXIS_RIGHT_X,JOY_AXIS_RIGHT_Y)
      # Pass the unprocessed hardware axis; filter it once inside look tick.
      var raw_look:=Vector2(Input.get_joy_axis(_pad_device,JOY_AXIS_RIGHT_X),
        Input.get_joy_axis(_pad_device,JOY_AXIS_RIGHT_Y))
      if Input.get_connected_joypads().has(_pad_device):
        _pad_apply_look(raw_look,delta)
      _pad_poll_triggers()
    elif _joystick_touch<0 and keys.length()<=0.01:
      input_axis=Vector2.ZERO
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
  var new_ground_y: float=float(terrain.call("height_at",actor.position.x,actor.position.z))
  actor.position.y = new_ground_y + float(actor.get_meta("actor_ground_offset_y",0.0))
  if previous_ground_y-new_ground_y>2.3 and _fall_damage_cd<=0.0:
    apply_player_damage(roundi((previous_ground_y-new_ground_y-2.0)*10.0))
    _fall_damage_cd=0.8
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
    "flight_distance":_flight_m,
    "gamepad_connected":_pad_device>=0,
    "gamepad_name":_pad_device_name,
    "gamepad_deadzone":_pad_deadzone,
    "gamepad_look_sensitivity":_pad_sensitivity,
    "gamepad_invert_y":_pad_invert_y,
    "gamepad_button_events":_pad_button_event_count,
    "gamepad_move_filtered":_pad_last_move,
    "gamepad_look_filtered":_pad_last_look,
    "gamepad_touch_fallback":true,
    "gamepad_hotplug_support":true,
    "gamepad_menu_navigation":true}
