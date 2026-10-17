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
var _distance: float = 9.5
var _joystick := Vector2.ZERO
var _joystick_touch: int = -1
var _look_touch: int = -1
# P0 rev197: actual camera/player locomotion and viewport touch ownership.
var _camera_angle_locked: bool = false
var _touches_global: Dictionary = {}
var _pinch_zoom_events: int = 0
var _first_fov: float = 57.0
var _jump_height: float = 0.0
var _jump_velocity: float = 0.0
var _jump_count: int = 0
var _landing_count: int = 0
var _soar_altitude: float = 0.0
# Rev199: flight is a real actor movement state, with stable altitude/speed,
# actual licensed Knight sword-pose animations, grounded depth cues, and
# lightweight ambient wind VFX. There is NO actual blade GLB yet.
var _soar_target_altitude: float=0.0
var _soar_landing: bool=false
var _air_velocity: Vector3=Vector3.ZERO
var _air_display_speed: float=0.0
# rev203: real player turn bank and camera depth, not camera roll or fake motion.
var _soar_bank_angle: float=0.0
var _soar_camera_extra: float=0.0
var _soar_hold_axis: float=0.0
var _soar_hold_seconds: float=0.0
var _fly_last_anim: String=""
var _flight_sword: Node3D
var _flight_rune: MeshInstance3D
var _flight_shadow: MeshInstance3D
var _flight_altitude_beam: MeshInstance3D
var _flight_wind_particles: GPUParticles3D
var _living_clock_label: Label
var _living_seed_label: Label
var _living_speed_button: Button
var _root_exam_button: Button
var _meditate_button: Button
var _breakthrough_button: Button
var _local_ai_status_label: Label
var _flight_altitude_label: Label
var _soar_distance_m: float = 0.0
var _blocked_wall_steps: int = 0
var _collision_probe: CapsuleShape3D
var _camera_sphere: SphereShape3D
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
var _mana_bar: ProgressBar
var _target_panel: PanelContainer
var _target_status: Label
var _target_health_bar: ProgressBar
var _target_mana_bar: ProgressBar
var _spirit_notice: Label
var _game_actions: Dictionary = {}
var _dash_cd: float = 0.0
var _gather_cd: float = 0.0
var _fall_damage_cd: float = 0.0
# rev196: VOLUNTARY mortal sparring using the existing licensed animated
# knight. A real timed attack damages player HP unless guard/dodge succeeds.
# No spiritual powers, scripted rewards, resource minting or civilian injury.
var _spar_partner: Node3D
var _spar_collision: StaticBody3D
var _spar_telegraph: MeshInstance3D
var _spar_stage: String = "inactive" # inactive / windup / recover
var _spar_timer: float = 0.0
var _guard_time: float = 0.0
var _guard_cd: float = 0.0
var _dodge_time: float = 0.0
var _dodge_cd: float = 0.0
var _dodge_origin: Vector3 = Vector3.ZERO
var _spar_attacks: int = 0
var _spar_perfect_guards: int = 0
var _spar_normal_guards: int = 0
var _spar_perfect_dodges: int = 0
var _spar_normal_dodges: int = 0
var _spar_hits: int = 0
var _spar_misses: int = 0
var _spar_last_outcome: String = "inactive"
# rev204: the practice opponent has a real finite HP ledger and a *truthful*
# MP=0 mortal realm; the 12 seeded cultivators display persisted living MP.
var _spar_enemy_health: int=110
var _spar_enemy_health_max: int=110
var _spar_enemy_mana: int=0
var _spar_enemy_mana_max: int=0
var _spar_opponent_tag: Label3D
var _spar_meters: Dictionary={}
var _sword_cd: float=0.0
var _bolt_cd: float=0.0
var _ward_cd: float=0.0
var _ward_seconds: float=0.0
var _ward_visual: MeshInstance3D
var _spell_projectiles: Array[Dictionary]=[]
var _combat_hit_count: int=0
var _spirit_bolt_impact_count: int=0
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
  _collision_probe=CapsuleShape3D.new()
  _collision_probe.radius=0.28
  _collision_probe.height=1.58
  _camera_sphere=SphereShape3D.new()
  _camera_sphere.radius=0.24
  _load_pad_options()
  _create_hud()
  if not Input.joy_connection_changed.is_connected(_on_pad_hotplug):
    Input.joy_connection_changed.connect(_on_pad_hotplug)
  _detect_pad()
  _create_flight_environment_vfx()
  update_camera()
  set_meta("original_apk176_interactive_player",true)

# rev199: Visuals are inexpensive Godot particle/mesh effects, NOT a
# hand-built character/weapon/structure. This is an honest mortal test-flight
# "御风" preview until actual spirit root, relic ownership and sword GLB exist.
func _create_flight_environment_vfx() -> void:
  var authentic: Node3D=room.get("licensed_flying_sword_source")
  if authentic!=null:
    _flight_sword=authentic.duplicate() as Node3D
    _flight_sword.name="ActualQuaterniusKnightCC0FlyingSwordUnderPlayerFeet"
    _flight_sword.visible=false
    _flight_sword.scale=Vector3.ONE*0.63
    world.add_child(_flight_sword)
  var jade:=StandardMaterial3D.new()
  jade.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  jade.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  jade.albedo_color=Color("#73efdd",0.82)
  jade.emission_enabled=true
  jade.emission=Color("#67c8ed")
  jade.emission_energy_multiplier=1.55
  jade.cull_mode=BaseMaterial3D.CULL_DISABLED
  _flight_rune=MeshInstance3D.new()
  _flight_rune.name="ActualSoaringFootWindRuneNotFakeSword"
  var foot_ring:=TorusMesh.new()
  foot_ring.inner_radius=0.57
  foot_ring.outer_radius=0.64
  foot_ring.rings=24
  foot_ring.ring_segments=8
  foot_ring.material=jade
  _flight_rune.mesh=foot_ring
  _flight_rune.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  _flight_rune.visible=false
  world.add_child(_flight_rune)
  _flight_shadow=MeshInstance3D.new()
  _flight_shadow.name="ActualGroundShadowAltitudeReferenceFromPhysicalTerrain"
  var ground_ring:=TorusMesh.new()
  ground_ring.inner_radius=0.81
  ground_ring.outer_radius=0.89
  ground_ring.rings=32
  ground_ring.ring_segments=8
  var marker:=StandardMaterial3D.new()
  marker.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  marker.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  marker.albedo_color=Color("#234654",0.67)
  marker.cull_mode=BaseMaterial3D.CULL_DISABLED
  ground_ring.material=marker
  _flight_shadow.mesh=ground_ring
  _flight_shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  _flight_shadow.visible=false
  world.add_child(_flight_shadow)
  _flight_altitude_beam=MeshInstance3D.new()
  _flight_altitude_beam.name="ContinuousAirToGroundAltitudeReferenceLine"
  var beam:=CylinderMesh.new()
  beam.top_radius=0.025
  beam.bottom_radius=0.025
  beam.height=1.0
  beam.radial_segments=6
  var thin:=StandardMaterial3D.new()
  thin.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  thin.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  thin.cull_mode=BaseMaterial3D.CULL_DISABLED
  thin.albedo_color=Color("#a5eadd",0.28)
  thin.emission_enabled=true
  thin.emission=Color("#bcecf9")
  thin.emission_energy_multiplier=0.7
  beam.material=thin
  _flight_altitude_beam.mesh=beam
  _flight_altitude_beam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  _flight_altitude_beam.visible=false
  world.add_child(_flight_altitude_beam)
  _flight_wind_particles=GPUParticles3D.new()
  _flight_wind_particles.name="ActuallyEmittingMobileWindTrailWhileAvatarSoars"
  _flight_wind_particles.amount=32
  _flight_wind_particles.lifetime=0.55
  _flight_wind_particles.one_shot=false
  _flight_wind_particles.local_coords=false
  _flight_wind_particles.explosiveness=0.0
  _flight_wind_particles.emitting=false
  var motion:=ParticleProcessMaterial.new()
  motion.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
  motion.emission_box_extents=Vector3(0.38,0.07,0.25)
  motion.direction=Vector3(0.0,-1.0,0.0)
  motion.gravity=Vector3(0,-0.75,0)
  motion.initial_velocity_min=0.6
  motion.initial_velocity_max=1.7
  motion.damping_min=0.3
  motion.damping_max=1.6
  _flight_wind_particles.process_material=motion
  var shard:=QuadMesh.new()
  shard.size=Vector2(0.105,0.024)
  var shard_material:=StandardMaterial3D.new()
  shard_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  shard_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  shard_material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
  shard_material.cull_mode=BaseMaterial3D.CULL_DISABLED
  shard_material.albedo_color=Color("#b8eaff",0.83)
  shard_material.emission_enabled=true
  shard_material.emission=Color("#90dadd")
  shard_material.emission_energy_multiplier=1.15
  shard.material=shard_material
  _flight_wind_particles.draw_pass_1=shard
  world.add_child(_flight_wind_particles)

func _sync_flight_world_cues(delta: float) -> void:
  var soaring: bool=camera_mode=="soar"
  for node in [_flight_sword,_flight_rune,_flight_shadow,_flight_altitude_beam]:
    if node!=null:
      node.visible=soaring
  if _flight_wind_particles!=null:
    _flight_wind_particles.emitting=soaring
  if not soaring:
    return
  var ground_y: float=_ground_surface_y(actor.position.x,actor.position.z)
  var foot_y: float=actor.position.y+0.13
  if _flight_sword!=null:
    # Authentic sword originally points along local +Y. Rest it flat with
    # the tip projecting in front of the REAL feet, not glued to camera.
    # Bank blade and body together; it is the actual licensed blade GLB.
    _flight_sword.rotation=Vector3(PI/2.0,actor.rotation.y,_soar_bank_angle)
    var blade_dir: Vector3=Vector3(sin(actor.rotation.y),0,cos(actor.rotation.y))
    _flight_sword.position=Vector3(actor.position.x,foot_y-0.20,
      actor.position.z)-blade_dir*0.96
  _flight_rune.position=Vector3(actor.position.x,foot_y,actor.position.z)
  _flight_rune.rotation.y+=delta*1.5
  _flight_shadow.position=Vector3(actor.position.x,ground_y+0.095,actor.position.z)
  var scale_shadow: float=clampf(0.95+_soar_altitude*0.092,0.95,5.0)
  _flight_shadow.scale=Vector3(scale_shadow,1,scale_shadow)
  _flight_altitude_beam.position=Vector3(actor.position.x,
    ground_y+_soar_altitude*0.5+0.13,actor.position.z)
  _flight_altitude_beam.scale.y=maxf(0.1,_soar_altitude)
  _flight_wind_particles.position=Vector3(actor.position.x,
    actor.position.y+0.18,actor.position.z)

func _knight_clip(fragment: String) -> String:
  if animator==null:
    return ""
  for clip in animator.get_animation_list():
    if String(clip).to_lower().ends_with(fragment.to_lower()):
      return String(clip)
  return ""

func _step_soar_altitude(delta: float) -> void:
  if camera_mode!="soar":
    return
  var prev: float=_soar_altitude
  var proposal: float=move_toward(prev,_soar_target_altitude,
    minf(7.0,4.2+absf(_soar_target_altitude-prev)*0.18)*delta)
  var new_y: float=_ground_surface_y(actor.position.x,actor.position.z)+proposal
  if _can_actor_move_to(actor.position,new_y):
    _soar_altitude=proposal
  # A real landing descends physically and then switches to the walk
  # state. No instantaneous 90m fall on pressing "降落".
  if _soar_landing and _soar_altitude<=0.045:
    _soar_altitude=0.0
    _soar_target_altitude=0.0
    _soar_landing=false
    _set_mode("third")
    say("御风试飞已平稳落地；飞剑仍需修仙功法与法器")

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
  room.call("_attach_real_cc0_long_hair",actor,0)
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
  var lift_button: Button=_new_button("FlyUpButton","升高 ↑",116,Callable(self,"fly_up"))
  var lower_button: Button=_new_button("FlyDownButton","降低 ↓",116,Callable(self,"fly_down"))
  # Press grants one precise 2.5m step; holding >0.25s then climbs/descends
  # continuously. Button-up never repeats pressed in ACTION_MODE_BUTTON_PRESS.
  # Gamepad DPAD retains the same explicit 2.5m step callbacks.
  for lift in [lift_button,lower_button]:
    lift.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS
  lift_button.button_down.connect(Callable(self,"_begin_soar_hold").bind(1.0))
  lift_button.button_up.connect(Callable(self,"_end_soar_hold").bind(1.0))
  lower_button.button_down.connect(Callable(self,"_begin_soar_hold").bind(-1.0))
  lower_button.button_up.connect(Callable(self,"_end_soar_hold").bind(-1.0))
  _new_button("ResetViewButton","重置镜头",146,Callable(self,"reset_camera"))
  _new_button("ZoomInButton","视野 ＋",128,Callable(self,"zoom_in"))
  _new_button("ZoomOutButton","视野 －",128,Callable(self,"zoom_out"))
  _new_button("InteractButton","互动",132,Callable(self,"interact"))
  _new_button("DigButton","挖地层",132,Callable(self,"dig"))
  # These are actual ALWAYS-VISIBLE phone controls, never hidden under
  # the previous development-panel toggle.
  _new_button("Iso45Button","俯视45°",103,Callable(self,"toggle_iso45"))
  _new_button("GodShortcutButton","上帝",103,Callable(self,"toggle_god_view"))
  _new_button("SoarAvatarButton","飞行",103,Callable(self,"toggle_avatar_flight"))
  _new_button("RealJumpButton","跳跃",103,Callable(self,"jump_action"))
  _new_button("CameraLockButton","锁视角",103,Callable(self,"toggle_camera_lock"))
  _new_button("PhoneZoomInButton","放大＋",103,Callable(self,"zoom_in"))
  _new_button("PhoneZoomOutButton","缩小－",103,Callable(self,"zoom_out"))
  var caption := Label.new()
  caption.name = "InteractionResultLiveHUD"
  caption.add_theme_font_size_override("font_size",18)
  caption.text = "左侧移动｜右侧旋转｜双指缩放｜俯视45°｜跳跃／飞行"
  hud.add_child(caption)
  notice = caption
  _build_game_hud()
  _create_living_clock_and_flight_hud()
  _create_cultivation_action_buttons()
  _layout_hud()


# rev188 candidate: never fabricate HP, MP or skill state before combat exists.
func _create_living_clock_and_flight_hud() -> void:
  _living_clock_label=Label.new()
  _living_clock_label.name="ActualAuthoritativeWorldDayHourAndAcceleration"
  _living_clock_label.add_theme_font_size_override("font_size",16)
  _living_clock_label.add_theme_color_override("font_color",Color("#eff9ff"))
  _living_clock_label.add_theme_color_override("font_shadow_color",Color("#142f40"))
  _living_clock_label.add_theme_constant_override("shadow_offset_x",1)
  _living_clock_label.add_theme_constant_override("shadow_offset_y",1)
  _living_clock_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  hud.add_child(_living_clock_label)
  _living_speed_button=Button.new()
  _living_speed_button.name="RealFullWorldAccelerationTimes1_5_20_100"
  _living_speed_button.size=Vector2(98,42)
  _living_speed_button.add_theme_font_size_override("font_size",17)
  _living_speed_button.add_theme_stylebox_override("normal",
    _rounded(Color("#213c47",0.94),9))
  _living_speed_button.pressed.connect(func():
    room.call("cycle_world_time_scale")
    _refresh_game_hud())
  hud.add_child(_living_speed_button)
  _local_ai_status_label=Label.new()
  _local_ai_status_label.name="RealOfflineNPCNativeRuntimeStatusNotFakeLLM"
  _local_ai_status_label.add_theme_font_size_override("font_size",13)
  _local_ai_status_label.add_theme_color_override("font_color",Color("#dfd7aa"))
  _local_ai_status_label.add_theme_color_override("font_shadow_color",Color("#172a35"))
  _local_ai_status_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  hud.add_child(_local_ai_status_label)
  _flight_altitude_label=Label.new()
  _flight_altitude_label.name="ActualAltitudeAGLVerticalSpeedAndWorldGroundReference"
  _flight_altitude_label.add_theme_font_size_override("font_size",23)
  _flight_altitude_label.add_theme_color_override("font_color",Color("#f5eed0"))
  _flight_altitude_label.add_theme_color_override("font_shadow_color",Color("#0b212d"))
  _flight_altitude_label.add_theme_constant_override("shadow_offset_x",2)
  _flight_altitude_label.add_theme_constant_override("shadow_offset_y",2)
  _flight_altitude_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  hud.add_child(_flight_altitude_label)

func _create_cultivation_action_buttons() -> void:
  # 3 usable Android touch actions; never require console commands or
  # reading hidden root weights in the character-creation panel.
  _root_exam_button=Button.new()
  _root_exam_button.name="LiveActualSpiritRootAltarExamTouchAction"
  _root_exam_button.text="检测灵根"
  _root_exam_button.size=Vector2(105,49)
  _root_exam_button.pressed.connect(func(): _try_root_examination())
  hud.add_child(_root_exam_button)
  _meditate_button=Button.new()
  _meditate_button.name="LiveOriginalWorldMeditationRealHourTouchAction"
  _meditate_button.text="吐纳修炼"
  _meditate_button.size=Vector2(105,49)
  _meditate_button.pressed.connect(func(): _try_meditation())
  hud.add_child(_meditate_button)
  _breakthrough_button=Button.new()
  _breakthrough_button.name="LiveActualQiPaidBreakthroughTouchAction"
  _breakthrough_button.text="突破"
  _breakthrough_button.size=Vector2(105,49)
  _breakthrough_button.pressed.connect(func(): _try_breakthrough())
  hud.add_child(_breakthrough_button)
  _living_seed_label=Label.new()
  _living_seed_label.name="ActuallyPersistentSpiritualWorldGenerationSeedVisible"
  _living_seed_label.add_theme_font_size_override("font_size",15)
  _living_seed_label.add_theme_color_override("font_color",Color("#def1e1"))
  _living_seed_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  hud.add_child(_living_seed_label)

func _try_root_examination() -> Dictionary:
  var system: RefCounted=room.get("cultivation")
  if system==null:
    return {"ok":false,"message":"灵根检测系统还未加载"}
  var answer: Dictionary=system.call("examine_player_root")
  say(String(answer.get("message","灵根检测失败")))
  _refresh_game_hud()
  return answer

func _try_meditation() -> Dictionary:
  var system: RefCounted=room.get("cultivation")
  if system==null:
    return {"ok":false,"message":"灵气修行系统还未加载"}
  var answer: Dictionary=system.call("toggle_player_meditation")
  say(String(answer.get("message","吐纳失败")))
  _refresh_game_hud()
  return answer

func _try_breakthrough() -> Dictionary:
  var system: RefCounted=room.get("cultivation")
  if system==null:
    return {"ok":false,"message":"修炼系统未加载"}
  var answer: Dictionary=system.call("player_breakthrough")
  say(String(answer.get("message","突破失败")))
  _refresh_game_hud()
  return answer

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
  bg.custom_minimum_size = Vector2(347, 147)
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
  var mana_row:=HBoxContainer.new()
  meters.add_child(mana_row)
  var mana_caption:=Label.new()
  mana_caption.text="法力  "
  mana_row.add_child(mana_caption)
  _mana_bar=ProgressBar.new()
  _mana_bar.name="RealSpiritManaFromCultivationLedgerNotFaked"
  _mana_bar.max_value=12
  _mana_bar.value=0
  _mana_bar.show_percentage=false
  _mana_bar.custom_minimum_size=Vector2(242,13)
  _mana_bar.add_theme_stylebox_override("background",_rounded(Color("#243133"),5))
  _mana_bar.add_theme_stylebox_override("fill",_rounded(Color("#4aadc7"),5))
  mana_row.add_child(_mana_bar)
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
  # Martial footwork remains available to mortals. Spiritual arts require
  # an actually detected root, an earned layer and mana from the save ledger.
  _add_game_action("LockedArt","切磋",Callable(self,"practice_action"))
  _add_game_action("GuardAction","格挡",Callable(self,"guard_action"))
  _add_game_action("EvadeAction","闪避",Callable(self,"evade_action"))
  _add_game_action("SwordAttack","剑击",Callable(self,"sword_attack"))
  _add_game_action("SpiritBolt","灵息弹",Callable(self,"cast_spirit_bolt"))
  _add_game_action("SpiritWard","护体灵障",Callable(self,"cast_spirit_ward"))
  _create_opponent_target_hud()
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

func _create_opponent_target_hud() -> void:
  # Fixed screen HUD confirms who was selected. World-space head bars still
  # follow the true target; this panel avoids unrecognizable microscopic bars.
  _target_panel=PanelContainer.new()
  _target_panel.name="ActualCombatTargetRealmHPMP"
  _target_panel.custom_minimum_size=Vector2(275,99)
  _target_panel.add_theme_stylebox_override("panel",_rounded(Color(0.06,0.10,0.15,0.87),11))
  _target_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var margin:=MarginContainer.new()
  margin.add_theme_constant_override("margin_left",10)
  margin.add_theme_constant_override("margin_right",10)
  margin.add_theme_constant_override("margin_top",7)
  margin.add_theme_constant_override("margin_bottom",7)
  _target_panel.add_child(margin)
  var column:=VBoxContainer.new()
  column.add_theme_constant_override("separation",3)
  margin.add_child(column)
  _target_status=Label.new()
  _target_status.add_theme_font_size_override("font_size",17)
  column.add_child(_target_status)
  for kind in ["health","mana"]:
    var row:=HBoxContainer.new()
    column.add_child(row)
    var caption:=Label.new()
    caption.text="生命  " if kind=="health" else "法力  "
    row.add_child(caption)
    var meter:=ProgressBar.new()
    meter.name="LiveEnemyHealthNotCosmetic" if kind=="health" else "LiveEnemyManaNotCosmetic"
    meter.show_percentage=false
    meter.custom_minimum_size=Vector2(193,10)
    meter.add_theme_stylebox_override("background",_rounded(Color("#1a282b"),4))
    meter.add_theme_stylebox_override("fill",_rounded(
      Color("#c66b62") if kind=="health" else Color("#55b5cd"),4))
    row.add_child(meter)
    if kind=="health":
      _target_health_bar=meter
    else:
      _target_mana_bar=meter
  hud.add_child(_target_panel)
  _target_panel.visible=false

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
  var spiritual: RefCounted=room.get("cultivation")
  var record: Dictionary=spiritual.call("public_player_status") if spiritual!=null else {}
  var realm: String=String(record.get("realm","凡人"))
  var level: int=int(record.get("layer",0))
  var mana_now: int=int(record.get("mana",0))
  _mana_bar.max_value=maxi(1,level*12)
  _mana_bar.value=mana_now
  _game_status.text="心魇说 · %s%s  %d/100" % [
    realm,(" 第%d层" % level) if level>0 else "",_player_health]
  (_game_actions["DashAction"] as Button).disabled=_dash_cd>0.0 or energy<8
  (_game_actions["DashAction"] as Button).text="疾步 "+str(ceili(_dash_cd))+"秒" if _dash_cd>0.0 else "疾步"
  (_game_actions["GatherAction"] as Button).disabled=_gather_cd>0.0
  (_game_actions["GatherAction"] as Button).text="采集 "+str(ceili(_gather_cd))+"秒" if _gather_cd>0.0 else "采集"
  (_game_actions["LockedArt"] as Button).text="结束切磋" if _spar_stage!="inactive" else "切磋"
  (_game_actions["GuardAction"] as Button).disabled=_spar_stage=="inactive" or _guard_cd>0 or energy<5
  (_game_actions["EvadeAction"] as Button).disabled=_spar_stage=="inactive" or _dodge_cd>0 or energy<7
  (_game_actions["GuardAction"] as Button).text="防御中" if _guard_time>0 else "格挡"
  (_game_actions["EvadeAction"] as Button).text="闪避中" if _dodge_time>0 else "闪避"
  (_game_actions["SwordAttack"] as Button).disabled=_spar_stage=="inactive" or _sword_cd>0.0 or energy<6
  (_game_actions["SwordAttack"] as Button).text=("剑击 %d" % ceili(_sword_cd)) if _sword_cd>0.0 else "剑击"
  var known: Array=record.get("known_arts",[])
  var bolt_learned: bool=known.has("CL-ART-SPIRIT-BOLT-V1")
  var ward_learned: bool=known.has("CL-ART-SPIRIT-WARD-V1")
  (_game_actions["SpiritBolt"] as Button).disabled=(
    _spar_stage=="inactive" or _bolt_cd>0.0 or not bolt_learned or mana_now<4)
  (_game_actions["SpiritBolt"] as Button).text=(
    "灵息弹 %d" % ceili(_bolt_cd) if _bolt_cd>0.0 else ("灵息弹" if bolt_learned else "灵息弹·未学"))
  (_game_actions["SpiritWard"] as Button).disabled=(
    _ward_cd>0.0 or not ward_learned or mana_now<6 or _ward_seconds>0.0)
  (_game_actions["SpiritWard"] as Button).text=(
    "灵障 %d" % ceili(_ward_cd) if _ward_cd>0.0 else ("护体灵障" if ward_learned else "灵障·未学"))
  if _target_panel!=null:
    _target_panel.visible=_spar_stage!="inactive"
    if _spar_stage!="inactive":
      _target_status.text="演武教习 · 凡人武者   %d/%d" % [
        _spar_enemy_health,_spar_enemy_health_max]
      _target_health_bar.max_value=_spar_enemy_health_max
      _target_health_bar.value=_spar_enemy_health
      _target_mana_bar.max_value=maxi(1,_spar_enemy_mana_max)
      _target_mana_bar.value=_spar_enemy_mana
      if _spar_opponent_tag!=null and is_instance_valid(_spar_opponent_tag):
        _spar_opponent_tag.text="演武教习 · 凡人武者\n生命 %d/%d · 法力 %d/%d" % [
          _spar_enemy_health,_spar_enemy_health_max,_spar_enemy_mana,_spar_enemy_mana_max]
      _sync_spar_meters()
  if spiritual!=null and _root_exam_button!=null:
    var tested: bool=bool(record.get("tested",false))
    _root_exam_button.text="复查灵根" if tested else "检测灵根"
    _meditate_button.text="停止吐纳" if bool(record.get("meditating",false)) else "吐纳修炼"
    _breakthrough_button.text="突破炼气"
    _living_seed_label.text="世界灵脉种子：%d · 修士 %d人" % [
      int(spiritual.get("world_seed")),int(spiritual.call("stats").get("cultivator_count",0))]
    if tested:
      var root: String=String(record.get("root_kind",""))
      var level: int=int(record.get("layer",0))
      _spirit_notice.text="%s  %s · %s  修为%d  经脉%d" % [
        root,String(record.get("realm","凡人")),
        "第%d层" % level if level>0 else "未入炼气",
        int(record.get("qi",0)),int(record.get("stress",0))]
    else:
      _spirit_notice.text="灵根：未检测 · 请寻找青色灵根检测台"
  (buttons["RealJumpButton"] as Button).disabled=_jump_height>0.0 or camera_mode in ["fly","god","soar"] or energy<4
  (buttons["CameraLockButton"] as Button).text="解锁视角" if _camera_angle_locked else "锁视角"
  (buttons["Iso45Button"] as Button).text="第三人称" if camera_mode=="iso" else "俯视45°"
  (buttons["SoarAvatarButton"] as Button).text=(
    "着陆中" if _soar_landing else ("降落" if camera_mode=="soar" else "飞行"))
  (buttons["GodShortcutButton"] as Button).text="退出上帝" if camera_mode=="god" else "上帝"
  if _living_clock_label!=null:
    var clock: Dictionary=room.call("get_living_clock")
    _living_clock_label.text="世界 第%d天 %02d:%02d · 全世界 ×%d" % [
      int(clock["day"]),int(clock["hour"]),int(clock["minutes"]),
      int(clock["speed_multiplier"])]
    _living_speed_button.text="时间 ×%d" % int(clock["speed_multiplier"])
    _local_ai_status_label.text="NPC：规则自治运行｜离线Qwen：不可用（原APK缺原生推理库）"
    if camera_mode=="soar":
      var ground_m: float=_ground_surface_y(actor.position.x,actor.position.z)
      _flight_altitude_label.visible=true
      _flight_altitude_label.text="御剑外观测试 · 离地 %.1f m  ▴ %.1f m/s\n地面 %.1f m  航速 %.1f m/s" % [
        _soar_altitude,(_soar_target_altitude-_soar_altitude)*3.2,
        ground_m,_air_display_speed]
    else:
      _flight_altitude_label.visible=false
  if _spar_stage!="inactive":
    _spirit_notice.text="切磋 %s · %s  法力%d/%d" % [
      _spar_stage,_spar_last_outcome,mana_now,level*12]
  elif spiritual==null:
    _spirit_notice.text="灵根：未检测（检测台尚未装载）"
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
    _game_sheet_title.text="修炼 · 灵根与境界"
    if spiritual==null:
      _game_sheet_body.text="修仙系统未加载"
    else:
      var r: Dictionary=spiritual.call("public_player_status")
      if not bool(r.get("tested",false)):
        _game_sheet_body.text="灵根：尚未检测（检测前严格隐藏）\n请前往青色古石检测台，点击【检测灵根】\n凡人阶段仍可切磋、行走与御风测试"
      else:
        var arts: Array=r.get("known_arts",[])
        var unlocked: String=("灵息弹" if arts.has("CL-ART-SPIRIT-BOLT-V1") else "炼气一层领悟灵息弹")
        unlocked+=", "+("护体灵障" if arts.has("CL-ART-SPIRIT-WARD-V1") else "炼气二层领悟护体灵障")
        _game_sheet_body.text="灵根：%s\n境界：%s %d层\n功法：%s\n灵气：%d  法力：%d/%d  经脉负荷：%d\n法术：%s\n真实世界时辰吐纳回复法力；法术消耗真实法力并有冷却。" % [
          String(r.get("root_kind","未知")),String(r.get("realm","凡人")),
          int(r.get("layer",0)),String(r.get("method","无")),
          int(r.get("qi",0)),int(r.get("mana",0)),
          int(r.get("layer",0))*12,int(r.get("stress",0)),unlocked]
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

# REV195 combat-reference learning implemented ONLY for the actual mortal
# movement already in game. No spiritual swords/phantom enemies are
# fabricated. A successful stamina-paid 2m dash emits one-shot motion shards.
# The sparring partner is a duplicate of the original licensed animated
# worker asset, NOT a handcrafted/unlicensed opponent model.
func practice_action() -> Dictionary:
  if _spar_stage!="inactive":
    stop_practice()
    say("切磋结束，没有对村民施加伤害")
    return {"ok":true,"active":false}
  if actor==null or _player_health<=0 or camera_mode in ["fly","god"]:
    return {"ok":false,"reason":"NOT_AVAILABLE"}
  var sources: Dictionary=room.get("asset_sources")
  if not sources.has("worker"):
    return {"ok":false,"reason":"MISSING_LICENSED_ANIMATED_OPPONENT"}
  var target: Vector3=actor.position+_forward()*2.45
  if not bool(terrain.call("stream_contains_physical_chunk",target.x,target.z)) or bool(terrain.call("is_water",target.x,target.z)):
    say("请到平坦干燥的空地切磋")
    return {"ok":false,"reason":"NO_DRY_WALKABLE_PRACTICE_SITE"}
  var h: float=float(terrain.call("height_at",target.x,target.z))
  var old_h: float=float(terrain.call("height_at",actor.position.x,actor.position.z))
  if absf(h-old_h)>0.4:
    return {"ok":false,"reason":"SPARRING_SLOPE_TOO_STEEP"}
  # Reject real building/obstacle ray intersection on camera blockers layer.
  var q:=PhysicsRayQueryParameters3D.create(
    actor.position+Vector3.UP*0.85,target+Vector3.UP*0.85)
  q.collision_mask=2
  if not world.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
    return {"ok":false,"reason":"SPARRING_SPACE_OCCUPIED"}
  _spar_partner=(sources["worker"] as Node3D).duplicate()
  _spar_partner.name="VoluntaryMortalPracticePartnerLicensedAnimatedKnight"
  _spar_partner.position=Vector3(target.x,0.0,target.z)
  world.add_child(_spar_partner)
  room.call("_normalize_worker_height",_spar_partner)
  # normalize_worker_height reads physical soil; its foot marker stays valid.
  _spar_partner.position.y=h+float(_spar_partner.get_meta("actor_ground_offset_y",0))
  _spar_partner.rotation.y=atan2(
    actor.position.x-target.x,actor.position.z-target.z)
  var animations: Array[Node]=_spar_partner.find_children("*","AnimationPlayer",true,false)
  for node in animations:
    var ap: AnimationPlayer=node as AnimationPlayer
    for anim in ap.get_animation_list():
      if String(anim).to_lower().contains("idle"):
        ap.play(String(anim))
        break
  _spar_collision=StaticBody3D.new()
  _spar_collision.name="MortalPracticeOpponentTangibleCollisionNoLoot"
  _spar_collision.collision_layer=2
  _spar_collision.collision_mask=0
  _spar_collision.position=Vector3(target.x,h+0.82,target.z)
  var shape:=CollisionShape3D.new()
  shape.name="RealMortalOpponentCapsule"
  var capsule:=CapsuleShape3D.new()
  capsule.radius=0.35
  capsule.height=1.64
  shape.shape=capsule
  _spar_collision.add_child(shape)
  world.add_child(_spar_collision)
  _spar_telegraph=MeshInstance3D.new()
  _spar_telegraph.name="MortalSwordPracticeAttackWarningNOTActualSpiritualSkill"
  var disc:=CylinderMesh.new()
  disc.top_radius=1.12
  disc.bottom_radius=1.12
  disc.height=0.028
  var light:=StandardMaterial3D.new()
  light.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  light.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  light.albedo_color=Color("#ec7151",0.27)
  light.emission_enabled=true
  light.emission=Color("#ed794e")
  light.emission_energy_multiplier=1.0
  disc.material=light
  _spar_telegraph.mesh=disc
  _spar_telegraph.position=Vector3(target.x,h+0.055,target.z)
  _spar_telegraph.visible=false
  world.add_child(_spar_telegraph)
  _spar_stage="recover"
  _spar_timer=0.82
  _guard_time=0.0
  _dodge_time=0.0
  _spar_last_outcome="预备"
  say("切磋开始：红圈蓄势时格挡或闪避；失误会扣真实生命")
  _refresh_game_hud()
  return {"ok":true,"active":true,"opponent":_spar_partner.name}

func stop_practice() -> void:
  for node in [_spar_partner,_spar_collision,_spar_telegraph]:
    if node!=null and is_instance_valid(node):
      node.queue_free()
  _spar_partner=null
  _spar_collision=null
  _spar_telegraph=null
  _spar_stage="inactive"
  _spar_timer=0
  _guard_time=0
  _dodge_time=0
  _spar_last_outcome="inactive"
  _refresh_game_hud()

func guard_action() -> bool:
  if _spar_stage=="inactive" or _guard_cd>0.0 or _player_health<=0:
    return false
  var sim=room.get("sim")
  var person: Dictionary=sim.citizens.get(PLAYER_ID,{})
  if int(person.get("energy",0))<5:
    say("格挡需要5点体力")
    return false
  person["energy"]=int(person["energy"])-5
  _guard_time=0.56
  _guard_cd=0.90
  _dodge_time=0.0
  _refresh_game_hud()
  return true

func evade_action() -> bool:
  if _spar_stage=="inactive" or _dodge_cd>0 or _player_health<=0:
    return false
  var sim=room.get("sim")
  var person: Dictionary=sim.citizens.get(PLAYER_ID,{})
  if int(person.get("energy",0))<7:
    say("闪避需要7点体力")
    return false
  var target: Vector3=actor.position-_forward()*1.65
  if not bool(terrain.call("stream_contains_physical_chunk",target.x,target.z)) or bool(terrain.call("is_water",target.x,target.z)):
    return false
  var surface: float=float(terrain.call("height_at",target.x,target.z))
  var original: float=float(terrain.call("height_at",actor.position.x,actor.position.z))
  if absf(surface-original)>0.65:
    return false
  var ray:=PhysicsRayQueryParameters3D.create(
    actor.position+Vector3.UP*0.8,target+Vector3.UP*0.8)
  ray.collision_mask=2
  if not world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
    return false
  _dodge_origin=actor.position
  person["energy"]=int(person["energy"])-7
  actor.position=Vector3(target.x,surface+float(
    actor.get_meta("actor_ground_offset_y",0.0)),target.z)
  _movement_m+=1.65
  _guard_time=0.0
  _dodge_time=0.31
  _dodge_cd=1.10
  _spawn_real_dash_trail(_dodge_origin,actor.position)
  terrain.call("stream_around",actor.position)
  update_camera()
  _refresh_game_hud()
  return true

func _spar_feedback(tint: Color) -> void:
  # Bounded one-shot actual impact, no per-particle dynamic light.
  if _spar_partner==null or not is_instance_valid(_spar_partner):
    return
  var puff:=GPUParticles3D.new()
  puff.name="ActualTimedGuardDodgeImpactFeedback"
  puff.one_shot=true
  puff.amount=12
  puff.lifetime=0.24
  puff.explosiveness=1.0
  puff.position=actor.position+Vector3.UP*1.05
  var proc:=ParticleProcessMaterial.new()
  proc.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
  proc.emission_sphere_radius=0.18
  proc.gravity=Vector3.ZERO
  proc.initial_velocity_min=0.55
  proc.initial_velocity_max=1.3
  puff.process_material=proc
  var slice:=QuadMesh.new()
  slice.size=Vector2(0.10,0.06)
  var material:=StandardMaterial3D.new()
  material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
  material.albedo_color=tint
  material.emission_enabled=true
  material.emission=tint
  material.emission_energy_multiplier=1.3
  slice.material=material
  puff.draw_pass_1=slice
  world.add_child(puff)
  puff.emitting=true
  get_tree().create_timer(0.55).timeout.connect(func():
    if is_instance_valid(puff):
      puff.queue_free())

func _spar_resolve_hit() -> void:
  if _spar_partner==null or not is_instance_valid(_spar_partner):
    return
  _spar_attacks+=1
  var enemy: Vector3=_spar_partner.position
  var player_d: float=Vector2(actor.position.x-enemy.x,
    actor.position.z-enemy.z).length()
  var former_d: float=Vector2(_dodge_origin.x-enemy.x,
    _dodge_origin.z-enemy.z).length()
  var facing: Vector3=(_spar_partner.position-actor.position)
  facing.y=0.0
  var front: bool=facing.length()>0.001 and _forward().dot(
    facing.normalized())>0.10
  if _dodge_time>0.0 and former_d<=3.10:
    if _dodge_time>=0.18:
      _spar_perfect_dodges+=1
      _spar_last_outcome="完美闪避"
      say("完美闪避！抓住攻击瞬间，完全避伤")
      _spar_feedback(Color("#9ce7ff"))
    else:
      _spar_normal_dodges+=1
      _spar_last_outcome="闪避成功"
      say("闪避成功，真实移动躲开这一击")
  elif player_d>3.10:
    _spar_misses+=1
    _spar_last_outcome="攻击落空"
  elif _guard_time>0.0 and front:
    if _guard_time>=0.43:
      _spar_perfect_guards+=1
      _spar_last_outcome="完美格挡"
      _spar_timer=1.25 # stagger after true perfect-timing block
      say("完美格挡！没有受到伤害，打断对方节奏")
      _spar_feedback(Color("#d9f5e5"))
    else:
      _spar_normal_guards+=1
      _spar_last_outcome="格挡"
      apply_player_damage(3)
      say("普通格挡：受到3点冲击伤害")
      _spar_feedback(Color("#f5d6a0"))
    _guard_time=0.0
  else:
    _spar_hits+=1
    _spar_last_outcome="受击"
    apply_player_damage(12)
    _spar_feedback(Color("#f29d84"))
    say("切磋失误：实际扣除12点生命")
  if _player_health<=0:
    stop_practice()

func _spar_tick(delta: float) -> void:
  _guard_time=maxf(0.0,_guard_time-delta)
  _guard_cd=maxf(0.0,_guard_cd-delta)
  _dodge_time=maxf(0.0,_dodge_time-delta)
  _dodge_cd=maxf(0.0,_dodge_cd-delta)
  if _spar_stage=="inactive" or _spar_partner==null:
    return
  if not is_instance_valid(_spar_partner):
    stop_practice()
    return
  var d: float=Vector2(actor.position.x-_spar_partner.position.x,
    actor.position.z-_spar_partner.position.z).length()
  if d>6.5:
    stop_practice()
    say("离开训练范围，切磋自动结束")
    return
  _spar_timer=maxf(0.0,_spar_timer-delta)
  if _spar_timer>0:
    return
  if _spar_stage=="recover":
    _spar_stage="windup"
    _spar_timer=0.68
    if is_instance_valid(_spar_telegraph):
      _spar_telegraph.visible=true
    _spar_last_outcome="敌人蓄势"
  else:
    if is_instance_valid(_spar_telegraph):
      _spar_telegraph.visible=false
    _spar_stage="recover"
    _spar_timer=1.40
    _spar_resolve_hit()

func _spawn_real_dash_trail(start_point: Vector3,end_point: Vector3) -> void:
  if world==null or room==null:
    return
  var quality: RefCounted=room.get("quality")
  var tier: String="普通" if quality==null else String(quality.get("selected"))
  var speed_pixels: int=22 if tier=="极致画质" else (14 if tier=="高档" else 7)
  var burst:=GPUParticles3D.new()
  burst.name="ActualMortalDashFootworkMotionShards"
  burst.one_shot=true
  burst.amount=speed_pixels
  burst.lifetime=0.30
  burst.explosiveness=1.0
  burst.position=(start_point+end_point)*0.5+Vector3.UP*0.34
  var physics:=ParticleProcessMaterial.new()
  physics.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
  physics.emission_box_extents=Vector3(0.75,0.14,0.75)
  physics.gravity=Vector3(0.0,-0.4,0.0)
  physics.initial_velocity_min=0.12
  physics.initial_velocity_max=0.62
  physics.damping_min=1.2
  physics.damping_max=2.8
  burst.process_material=physics
  var tiny:=QuadMesh.new()
  tiny.size=Vector2(0.14,0.048)
  var mat:=StandardMaterial3D.new()
  mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  mat.albedo_color=Color("#e1d9b3",0.83)
  mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
  mat.cull_mode=BaseMaterial3D.CULL_DISABLED
  mat.emission_enabled=true
  mat.emission=Color("#c4e5d9")
  mat.emission_energy_multiplier=1.18 if tier!="普通" else 0.65
  tiny.material=mat
  burst.draw_pass_1=tiny
  world.add_child(burst)
  burst.emitting=true
  get_tree().create_timer(0.65).timeout.connect(func():
    if is_instance_valid(burst):
      burst.queue_free())

func dash_action() -> bool:
  if actor==null or _dash_cd>0.0 or camera_mode in ["god","fly"]:
    return false
  var sim=room.get("sim")
  var person: Dictionary=sim.citizens.get(PLAYER_ID,{})
  if int(person.get("energy",0))<8:
    say("体力不足，无法疾步")
    return false
  var target: Vector3=actor.position+_forward()*2.0
  if not bool(terrain.call("stream_contains_physical_chunk",target.x,target.z)) or bool(terrain.call("is_water",target.x,target.z)):
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
  var dash_start: Vector3=actor.position
  person["energy"]=int(person["energy"])-8
  actor.position=Vector3(target.x,surface_y+float(actor.get_meta("actor_ground_offset_y",0.0)),target.z)
  _movement_m+=2.0
  # VFX only after the physical move succeeds and actual stamina was paid.
  _spawn_real_dash_trail(dash_start,actor.position)
  _dash_cd=3.0
  terrain.call("stream_around",actor.position)
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
  (buttons["FlyUpButton"] as Button).visible=camera_mode in ["fly","soar"] and not _soar_landing
  (buttons["FlyDownButton"] as Button).visible=camera_mode in ["fly","soar"] and not _soar_landing
  # Top-right first row remains original account/menu HUD; the second row
  # is permanently usable on touch devices even with dev UI turned OFF.
  var quick_keys: Array[String]=["Iso45Button","GodShortcutButton",
    "SoarAvatarButton","RealJumpButton","CameraLockButton",
    "PhoneZoomInButton","PhoneZoomOutButton"]
  var quick_start: float=maxf(454.0,size.x-float(quick_keys.size())*108.0-18.0)
  for i in range(quick_keys.size()):
    var quick: Button=buttons[quick_keys[i]]
    quick.position=Vector2(quick_start+float(i)*108.0,81)
    quick.size=Vector2(103,45)
    quick.visible=true
  # Keep flight Up/Down separately accessible beneath the right-side strip.
  (buttons["FlyUpButton"] as Button).position=Vector2(size.x-145,152)
  (buttons["FlyDownButton"] as Button).position=Vector2(size.x-145,208)
  # Original always-on game HUD is not a developer-only QA control.
  # Five compact top-right tabs, not ten QA buttons scattered over scenery.
  var menu_names:=["角色","背包","修炼","菜单"]
  var menu_x: float=maxf(365.0,size.x-4.0*104.0-22.0)
  for idx in range(menu_names.size()):
    var tab: Button=hud.get_node("GameMenu_"+menu_names[idx]) as Button
    tab.position=Vector2(menu_x+float(idx)*104.0,16)
    tab.size=Vector2(96,44)
  var action_keys:=["GatherAction","DashAction","DigAction","InteractAction",
    "ViewAction","LockedArt","GuardAction","EvadeAction",
    "SwordAttack","SpiritBolt","SpiritWard"]
  for idx in range(action_keys.size()):
    var col: int=idx%4
    var row: int=int(idx/4)
    (_game_actions[action_keys[idx]] as Button).position=Vector2(
      size.x-392.0+float(col)*94.0,size.y-207.0+float(row)*66.0)
  if _target_panel!=null:
    _target_panel.position=Vector2(maxf(370.0,size.x*0.5-137.0),15.0)
  notice.position=Vector2(minf(370.0,size.x*0.27),maxf(210.0,size.y-47.0))
  if _pad_hint!=null:
    _pad_hint.position=Vector2(16,139)
  if _root_exam_button!=null:
    var width: float=size.x
    _root_exam_button.position=Vector2(width-392.0,size.y-271.0)
    _meditate_button.position=Vector2(width-280.0,size.y-271.0)
    _breakthrough_button.position=Vector2(width-168.0,size.y-271.0)
  if _living_seed_label!=null:
    _living_seed_label.position=Vector2(19,263)
  if _living_clock_label!=null:
    _living_clock_label.position=Vector2(19,172)
    _living_speed_button.position=Vector2(19,209)
    _local_ai_status_label.position=Vector2(127,217)
    _flight_altitude_label.position=Vector2(
      clampf(size.x*0.45,480.0,size.x-445.0),145)


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
  # Quality/FPS popup belongs to the original CanvasLayer, not to the
  # player menu: focus its REAL native Godot Buttons while that popup is open.
  var menu_root: Control=_game_sheet
  var quality_popup: Control=room.get("quality_menu") as Control
  if quality_popup!=null and quality_popup.visible:
    menu_root=quality_popup
  for node in menu_root.find_children("*","Button",true,false):
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
    if _game_sheet.visible and bool(room.get("quality_menu_visible")):
      room.call("_toggle_quality_settings")
      _pad_close_menu()
    else:
      _open_game_menu("settings")
    return
  if button==JOY_BUTTON_BACK:
    if bool(room.get("quality_menu_visible")):
      room.call("_toggle_quality_settings")
      _pad_focus_menu(0)
    elif _game_sheet.visible:
      _pad_close_menu()
    else:
      _open_game_menu("character")
    return
  if _game_sheet.visible:
    if button==JOY_BUTTON_B:
      if bool(room.get("quality_menu_visible")):
        room.call("_toggle_quality_settings")
        _pad_focus_menu(0)
      else:
        _pad_close_menu()
    elif button==JOY_BUTTON_DPAD_UP:
      _pad_focus_menu(_pad_menu_index-1)
    elif button==JOY_BUTTON_DPAD_DOWN:
      _pad_focus_menu(_pad_menu_index+1)
    elif button==JOY_BUTTON_A:
      if _pad_menu_options.is_empty():
        _pad_focus_menu(0)
      if not _pad_menu_options.is_empty():
        var was_quality: bool=bool(room.get("quality_menu_visible"))
        _pad_menu_options[_pad_menu_index].pressed.emit()
        if was_quality!=bool(room.get("quality_menu_visible")):
          _pad_focus_menu(0)
    elif button==JOY_BUTTON_RIGHT_SHOULDER:
      _open_game_menu("inventory")
    elif button==JOY_BUTTON_LEFT_SHOULDER:
      _open_game_menu("character")
    return
  match button:
    JOY_BUTTON_A:
      if _spar_stage=="inactive":
        jump_action()
      else:
        interact()
    JOY_BUTTON_X:
      gather_action()
    JOY_BUTTON_Y:
      dig()
    JOY_BUTTON_B:
      if _spar_stage!="inactive":
        evade_action()
      else:
        dash_action()
    JOY_BUTTON_LEFT_SHOULDER:
      toggle_perspective()
    JOY_BUTTON_RIGHT_SHOULDER:
      if _spar_stage!="inactive":
        guard_action()
      else:
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
      toggle_iso45()
    JOY_BUTTON_DPAD_RIGHT:
      toggle_avatar_flight()

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
    _right_touches[event.index]=event.position
    # Global _input handles the pinch BEFORE native GUI hit-testing. A
    # gesture can now straddle left and right screen zones; never double zoom.
    if _touches_global.size()<2 and event.index==_look_touch:
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
  if event is InputEventScreenTouch or event is InputEventScreenDrag:
    _track_global_touch(event)
    return
  if event is InputEventJoypadButton:
    if event.pressed and not event.is_echo() and event.device==_pad_device:
      _pad_press_button(int(event.button_index))
      # Consume standardized gamepad actions once: Godot's default ui_accept
      # may otherwise also activate a focused button on the same frame.
      room.get_viewport().set_input_as_handled()
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
    elif event.keycode == KEY_R:
      guard_action()
    elif event.keycode == KEY_SPACE:
      if _spar_stage!="inactive":
        evade_action()
      else:
        jump_action()
    elif event.keycode == KEY_T:
      practice_action()
    elif event.keycode == KEY_EQUAL:
      zoom_in()
    elif event.keycode == KEY_MINUS:
      zoom_out()

func turn_view(movement: Vector2) -> void:
  if _camera_angle_locked:
    return
  _follow_npc = false
  room.set("_follow_builder",false)
  _yaw -= movement.x*0.0050
  # User phone feedback: drag DOWN must look DOWN, NEVER up.
  # Reverse rev186 vertical sense across first/third/god/fly.
  if camera_mode=="first" or camera_mode=="fly":
    _pitch=clampf(_pitch-movement.y*0.0029,-1.30,1.24)
  elif camera_mode=="god":
    _pitch=clampf(_pitch-movement.y*0.0029,0.65,1.52)
  elif camera_mode=="iso":
    _pitch=PI/4.0
  else:
    _pitch=clampf(_pitch-movement.y*0.0029,0.08,1.20)
  update_camera()

func zoom_ratio(factor: float) -> void:
  if factor<=0.0:
    return
  if camera_mode=="first":
    _first_fov=clampf(_first_fov/maxf(factor,0.08),33.0,78.0)
    camera.fov=_first_fov
    update_camera()
    return
  if camera_mode=="god":
    _god_distance=clampf(_god_distance/maxf(factor,0.08),8.0,175.0)
  elif camera_mode=="fly":
    _flight_position += Vector3(0,clampf((factor-1.0)*2.0,-4.0,4.0),0)
  else:
    _distance=clampf(_distance/maxf(factor,0.08),3.3,86.0)
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
  # Diagnostic free-camera remains available from developer controls.
  _set_mode("third" if camera_mode=="fly" else "fly")

func _set_mode(mode: String) -> void:
  if not ["first","third","god","fly","iso","soar"].has(mode):
    return
  if camera_mode=="soar" and mode!="soar" and _soar_altitude>0.045:
    _soar_landing=true
    _soar_hold_axis=0.0
    _soar_hold_seconds=0.0
    _soar_target_altitude=0.0
    say("请先平稳降落，再切换视角")
    _layout_hud() # Hide both lift controls immediately, not on the next physics frame.
    return
  if camera_mode=="soar" and mode!="soar":
    _soar_hold_axis=0.0
    _soar_hold_seconds=0.0
    _soar_camera_extra=0.0
    _soar_bank_angle=0.0
    if actor!=null:
      actor.rotation.z=0.0
    _soar_altitude=0.0
    _soar_target_altitude=0.0
    _soar_landing=false
    _air_velocity=Vector3.ZERO
    _air_display_speed=0.0
  camera_mode=mode
  is_first_person=mode=="first"
  _first_fov=57.0 if mode!="first" else _first_fov
  if camera!=null:
    camera.fov=_first_fov if mode=="first" else 57.0
  _auto_walking=false
  room.set("_follow_builder",false)
  _follow_npc=false
  if actor!=null:
    # The whole rig was hidden in first-person, leaving neither arms nor
    # legs; keep the licensed character mesh alive in every camera mode.
    actor.visible=true
  if mode=="god":
    _god_focus=actor.position if actor!=null else Vector3.ZERO
    _god_distance=maxf(_god_distance,23.0)
    _pitch=1.31
    say("上帝视角：左摇杆平移地图 · 双指缩放 · 右侧旋转")
  elif mode=="fly":
    _flight_position=camera.position if camera!=null else Vector3(1,12,7)
    _flight_position.y=maxf(_flight_position.y,4.5)
    _pitch=0.0
    say("摄影机飞行：玩家留在世界原位，升高／降低自由看")
  elif mode=="soar":
    # Gradual takeoff instead of instant camera-height teleport.
    _soar_altitude=0.0
    _soar_target_altitude=3.0
    _soar_landing=false
    _soar_hold_axis=0.0
    _soar_hold_seconds=0.0
    _soar_camera_extra=0.0
    _soar_bank_angle=0.0
    _air_velocity=Vector3.ZERO
    _pitch=0.70
    _distance=11.0
    say("御剑外观试飞：真CC0飞剑和高度参照，功法法力未解锁")
  elif mode=="iso":
    _yaw=PI/4.0
    _pitch=PI/4.0
    _distance=16.0
    say("45°俯视：玩家可见、跟随移动，仍可缩放")
  elif mode=="first":
    _pitch=0.0
    say("第一视角：手指向下滑=向下看，向上滑=抬头")
  else:
    _pitch=0.38
    _distance=9.5
    say("第三视角：角色可见、左右移动、相机防穿墙")
  (buttons["PerspectiveButton"] as Button).text="第三视角" if mode=="first" else "第一视角"
  (buttons["GodViewButton"] as Button).text="退出上帝" if mode=="god" else "上帝视角"
  (buttons["FlyViewButton"] as Button).text="退出摄影机飞行" if mode=="fly" else "自由摄影机"
  update_camera()
  _layout_hud()

func _begin_soar_hold(axis: float) -> void:
  if camera_mode=="soar" and not _soar_landing and (
      _game_sheet==null or not _game_sheet.visible):
    _soar_hold_axis=clampf(axis,-1.0,1.0)
    _soar_hold_seconds=0.0

func _end_soar_hold(axis: float) -> void:
  if is_equal_approx(_soar_hold_axis,axis):
    _soar_hold_axis=0.0
    _soar_hold_seconds=0.0

func _step_soar_hold(delta: float) -> void:
  if camera_mode!="soar" or _soar_landing or (
      _game_sheet!=null and _game_sheet.visible):
    _soar_hold_axis=0.0
    _soar_hold_seconds=0.0
    return
  if absf(_soar_hold_axis)<0.1:
    return
  _soar_hold_seconds+=delta
  if _soar_hold_seconds<=0.25:
    return
  # A thumb can stay on the button without 20 repeated taps.
  # Input motion uses real seconds even when the simulated WORLD clock runs 100x.
  _soar_target_altitude=clampf(
    _soar_target_altitude+_soar_hold_axis*6.0*delta,0.85,90.0)

func fly_up() -> void:
  if camera_mode=="fly":
    _flight_position.y=minf(130.0,_flight_position.y+2.5)
    _flight_m+=2.5
  elif camera_mode=="soar" and not _soar_landing:
    _soar_target_altitude=minf(90.0,maxf(_soar_target_altitude,_soar_altitude)+2.5)
  update_camera()

func fly_down() -> void:
  if camera_mode=="fly":
    _flight_position.y=maxf(1.0,_flight_position.y-2.5)
    _flight_m+=2.5
  elif camera_mode=="soar" and not _soar_landing:
    _soar_target_altitude=maxf(0.85,_soar_target_altitude-2.5)
  update_camera()

func reset_camera() -> void:
  _camera_angle_locked=false
  _yaw=0.43
  _pitch=0.38
  _distance=14.0
  room.set("_follow_builder",false)
  _auto_walking=false
  _set_mode("third")
  say("镜头已复位：你没有被固定在建筑或镜头里面")

# rev197 camera/locomotion: 45-degree is a FOLLOWING player camera;
# god view is a separate map camera, while avatar flight moves real character.
func toggle_iso45() -> void:
  _set_mode("third" if camera_mode=="iso" else "iso")

func toggle_camera_lock() -> void:
  _camera_angle_locked=not _camera_angle_locked
  say("镜头方向已锁定，移动和双指缩放仍可操作" if _camera_angle_locked
    else "镜头方向已解锁，右手可以转动")
  _refresh_game_hud()

func toggle_avatar_flight() -> void:
  if camera_mode=="soar":
    if _soar_landing:
      return
    _soar_landing=true
    _soar_target_altitude=0.0
    _soar_hold_axis=0.0
    _soar_hold_seconds=0.0
    # Keep current air velocity; step() eases horizontal motion to rest.
    # Clearing this vector here causes a sudden midair braking jolt.
    _layout_hud()
    say("正在平稳降落，观察脚下的地面投影")
  else:
    _set_mode("soar")

func _ground_surface_y(x: float,z: float) -> float:
  var normal: float=float(terrain.call("height_at",x,z))
  # Stair ramp bodies live on walkable-only layer 3 (bit 4). They must
  # contribute to feet height without blocking the player's capsule.
  var query:=PhysicsRayQueryParameters3D.create(
    Vector3(x,normal+2.1,z),Vector3(x,normal-0.35,z),4)
  var stair: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(query)
  if not stair.is_empty() and (stair["normal"] as Vector3).y>0.50:
    return maxf(normal,float((stair["position"] as Vector3).y))
  return normal

func _can_actor_move_to(target: Vector3,override_y: float=INF) -> bool:
  if not bool(terrain.call("stream_contains_physical_chunk",target.x,target.z)):
    return false
  if _collision_probe==null or world==null:
    return false
  var expected_height: float=_ground_surface_y(target.x,target.z)
  var at_y: float=expected_height+_jump_height+_soar_altitude if not is_finite(override_y) else override_y
  var current_ground: float=_ground_surface_y(actor.position.x,actor.position.z)
  var current_y: float=current_ground+_jump_height+_soar_altitude
  var q:=PhysicsShapeQueryParameters3D.new()
  q.shape=_collision_probe
  q.collision_mask=2 # real construction walls / NPCs, NOT earth or stairs
  q.margin=0.015
  q.transform=Transform3D(Basis(),Vector3(actor.position.x,current_y+0.84,actor.position.z))
  var space:=world.get_world_3d().direct_space_state
  var end_query:=PhysicsShapeQueryParameters3D.new()
  end_query.shape=_collision_probe
  end_query.collision_mask=2
  end_query.margin=0.015
  end_query.transform=Transform3D(Basis(),Vector3(target.x,at_y+0.84,target.z))
  if not space.intersect_shape(end_query,1).is_empty():
    _blocked_wall_steps+=1
    return false
  q.motion=Vector3(target.x-actor.position.x,at_y-current_y,target.z-actor.position.z)
  var allowed: PackedFloat32Array=space.cast_motion(q)
  if allowed.size()>0 and allowed[0]<0.97:
    _blocked_wall_steps+=1
    return false
  return true

func jump_action() -> bool:
  if actor==null or _jump_height>0.0 or _jump_velocity>0.0 or camera_mode in ["god","fly","soar"]:
    return false
  var sim=room.get("sim")
  var person: Dictionary=sim.citizens.get(PLAYER_ID,{})
  if int(person.get("energy",0))<4:
    say("跳跃需要4点体力")
    return false
  # Prevent head/hat clipping through a low roof before jumping.
  var h: float=_ground_surface_y(actor.position.x,actor.position.z)
  var probe:=PhysicsRayQueryParameters3D.create(
    Vector3(actor.position.x,h+1.72,actor.position.z),
    Vector3(actor.position.x,h+2.90,actor.position.z),2)
  if not world.get_world_3d().direct_space_state.intersect_ray(probe).is_empty():
    say("头顶有障碍，不能跳进屋顶")
    return false
  person["energy"]=int(person["energy"])-4
  _jump_velocity=5.4
  _jump_count+=1
  say("已起跳：可在空中用左摇杆调整落点")
  return true

func _step_jump(delta: float) -> void:
  if _jump_velocity<=0.0 and _jump_height<=0.0:
    return
  var last_height: float=_jump_height
  _jump_velocity-=15.0*delta
  _jump_height=maxf(0.0,_jump_height+_jump_velocity*delta)
  if _jump_height>last_height:
    var h: float=_ground_surface_y(actor.position.x,actor.position.z)
    var roof:=PhysicsRayQueryParameters3D.create(
      Vector3(actor.position.x,h+last_height+1.69,actor.position.z),
      Vector3(actor.position.x,h+_jump_height+1.81,actor.position.z),2)
    if not world.get_world_3d().direct_space_state.intersect_ray(roof).is_empty():
      _jump_height=last_height
      _jump_velocity=0.0
  if _jump_height<=0.0:
    _jump_height=0.0
    _jump_velocity=0.0
    _landing_count+=1

func _touch_is_world(p: Vector2) -> bool:
  # Never count joystick, tabs, sheets or game-action buttons as pinch.
  if joystick_ring!=null and joystick_ring.get_global_rect().has_point(p):
    return false
  if _game_sheet!=null and _game_sheet.visible and _game_sheet.get_global_rect().has_point(p):
    return false
  for node in buttons.values():
    var b: Button=node
    if b.visible and b.get_global_rect().has_point(p):
      return false
  for node in _game_actions.values():
    var action: Button=node
    if action.visible and action.get_global_rect().has_point(p):
      return false
  for tab in ["角色","背包","修炼","菜单"]:
    var menu: Button=hud.get_node_or_null("GameMenu_"+tab)
    if menu!=null and menu.get_global_rect().has_point(p):
      return false
  return true

func _track_global_touch(event: InputEvent) -> void:
  if event is InputEventScreenTouch:
    if event.pressed:
      if _touch_is_world(event.position):
        _touches_global[event.index]=event.position
    else:
      _touches_global.erase(event.index)
    _last_pinch=-1.0
    if _touches_global.size()>=2:
      var pair: Array=_touches_global.values()
      _last_pinch=(pair[0] as Vector2).distance_to(pair[1] as Vector2)
  elif event is InputEventScreenDrag and _touches_global.has(event.index):
    _touches_global[event.index]=event.position
    if _touches_global.size()>=2:
      var pair: Array=_touches_global.values()
      var distance_now: float=(pair[0] as Vector2).distance_to(pair[1] as Vector2)
      if _last_pinch>8.0 and distance_now>8.0:
        var ratio: float=clampf(distance_now/_last_pinch,0.75,1.33)
        if absf(ratio-1.0)>0.001:
          zoom_ratio(ratio)
          _pinch_zoom_events+=1
      _last_pinch=distance_now

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
  _spar_tick(delta)
  terrain.call("stream_around",actor.position)
  _step_jump(delta)
  _step_soar_altitude(delta)
  _step_soar_hold(delta)
  # A little more terrain in frame at altitude gives real spatial context;
  # the eased offset adds to, never replaces, player-controlled pinch zoom.
  _soar_camera_extra=lerpf(_soar_camera_extra,
    clampf(_soar_altitude*0.10,0.0,6.5) if camera_mode=="soar" else 0.0,
    clampf(delta*2.6,0.0,1.0))
  var previous_ground_y: float=_ground_surface_y(actor.position.x,actor.position.z)
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
    _flight_position.y=maxf(1.4,_flight_position.y)
    _flight_m+=flight_dir.length()*delta
    _set_movement_animation(false)
  elif camera_mode=="soar":
    # Airborne movement accelerates/decays smoothly; never make the
    # horizon flip or teleport by snapping the camera's own position.
    var fly_vector: Vector3=Vector3.ZERO
    if input_axis.length()>0.08 and not _soar_landing:
      fly_vector=(_right()*input_axis.x+_forward()*(-input_axis.y)).normalized()
    var speed: float=clampf(8.0+_soar_altitude*0.13,8.0,17.5)
    _air_velocity=_air_velocity.lerp(fly_vector*speed,clampf(delta*4.4,0.0,1.0))
    if _air_velocity.length()<0.05:
      _air_velocity=Vector3.ZERO
    _air_display_speed=_air_velocity.length()
    var flying_target: Vector3=actor.position+_air_velocity*delta
    if _air_velocity.length()>0.01 and _can_actor_move_to(flying_target,
        _ground_surface_y(flying_target.x,flying_target.z)+_soar_altitude):
      var moved_m: float=Vector2(flying_target.x-actor.position.x,
        flying_target.z-actor.position.z).length()
      actor.position.x=flying_target.x
      actor.position.z=flying_target.z
      _soar_distance_m+=moved_m
      _flight_m+=moved_m
    else:
      _air_velocity=Vector3.ZERO
      _air_display_speed=0.0
    var bank_target: float=0.0
    if fly_vector.length()>0.01:
      var wanted_yaw: float=atan2(fly_vector.x,fly_vector.z)
      var yaw_error: float=wrapf(wanted_yaw-actor.rotation.y,-PI,PI)
      bank_target=clampf(-yaw_error*0.28,-0.16,0.16)*clampf(
        _air_display_speed/8.0,0.0,1.0)
      actor.rotation.y=lerp_angle(actor.rotation.y,wanted_yaw,clampf(delta*6,0,1))
    _soar_bank_angle=lerpf(_soar_bank_angle,bank_target,clampf(delta*4.0,0,1))
    actor.rotation.z=_soar_bank_angle
    _set_movement_animation(_air_display_speed>0.35)
  elif input_axis.length()>0.08:
    _follow_npc=false
    room.set("_follow_builder",false)
    var motion: Vector3=(_right()*input_axis.x+_forward()*(-input_axis.y)).normalized()
    var actual_move: float=MOVE_SPEED*delta
    var candidate: Vector3=actor.position+motion*actual_move
    var previous_pos: Vector3=actor.position
    var current_height: float=_ground_surface_y(previous_pos.x,previous_pos.z)
    # Validate a swept full-height human capsule against real structures.
    # If a corner blocks both axes, try each independently for wall sliding.
    for place in [candidate,Vector3(candidate.x,actor.position.y,previous_pos.z),
        Vector3(previous_pos.x,actor.position.y,candidate.z)]:
      var possible: Vector3=place
      if not bool(terrain.call("is_water",possible.x,possible.z)):
        var height: float=_ground_surface_y(possible.x,possible.z)
        var diff: float=height-current_height
        if diff <= (1.05 if _jump_height>0 else 0.46) and diff>=-1.10 and (
            _can_actor_move_to(possible)):
          actor.position.x=possible.x
          actor.position.z=possible.z
          _movement_m+=Vector2(possible.x-previous_pos.x,possible.z-previous_pos.z).length()
          break
    actor.rotation.y=atan2(motion.x,motion.z)
    _set_movement_animation(actor.position.distance_squared_to(previous_pos)>0.00001)
  else:
    _set_movement_animation(false)
  # Ground, walkable-stair ramps, true jump parabola and voluntary avatar
  # flight share ONE player height. No per-frame snapping away real jumping.
  var new_ground_y: float=_ground_surface_y(actor.position.x,actor.position.z)
  actor.position.y=new_ground_y+float(actor.get_meta("actor_ground_offset_y",0.0))+_jump_height+_soar_altitude
  if previous_ground_y-new_ground_y>2.3 and _fall_damage_cd<=0.0 and _jump_height<=0.0 and _soar_altitude<=0.0:
    apply_player_damage(roundi((previous_ground_y-new_ground_y-2.0)*10.0))
    _fall_damage_cd=0.8
  _sync_flight_world_cues(delta)
  if not bool(room.get("_follow_builder")):
    update_camera()
  if _hud_flash>0.0:
    _hud_flash = maxf(0,_hud_flash-delta)
    if _hud_flash<=0:
      notice.text = "左摇杆移动 | 右侧看世界 | 双指缩放 | 互动/挖掘"
  _refresh_game_hud()
  _layout_hud()

func _set_movement_animation(moving: bool) -> void:
  if animator==null:
    return
  var clip: String=walking if moving else idle
  if camera_mode=="soar":
    # Real prebound aerial Jump/swordAttackJump clip, no road-running in air.
    clip=_knight_clip("|swordAttackJump") if moving else _knight_clip("|Jump")
    if clip.is_empty():
      clip=_knight_clip("|Idle_swordRight")
    animator.speed_scale=0.75
  elif _jump_height>0.05:
    clip=_knight_clip("|Jump")
    animator.speed_scale=1.0
  else:
    animator.speed_scale=1.0
  if not clip.is_empty() and animator.current_animation!=clip:
    animator.play(clip)

func _safe_camera_position(target: Vector3, desired: Vector3) -> Vector3:
  if world==null or world.get_world_3d()==null:
    return desired
  var travel: Vector3=desired-target
  if travel.length()<0.20:
    return target+Vector3.UP*0.5
  var space:=world.get_world_3d().direct_space_state
  var direction: Vector3=travel.normalized()
  var adjusted: Vector3=desired
  # Use a real swept sphere, not only a thin zero-width ray. The actual
  # camera has a near plane; a center-line ray previously let walls intrude.
  var cast:=PhysicsShapeQueryParameters3D.new()
  cast.shape=_camera_sphere
  cast.transform=Transform3D(Basis(),target)
  cast.collision_mask=2
  cast.motion=travel
  cast.margin=0.02
  var safe: PackedFloat32Array=space.cast_motion(cast)
  if safe.size()>0 and safe[0]<0.999:
    var travel_fraction: float=maxf(0.01,float(safe[0])-0.045)
    adjusted=target+travel*travel_fraction
    _camera_collision_hits+=1
  else:
    var ray:=PhysicsRayQueryParameters3D.create(target,desired,2)
    var hit: Dictionary=space.intersect_ray(ray)
    if not hit.is_empty():
      adjusted=target+direction*maxf(0.68,target.distance_to(hit["position"])-0.42)
      _camera_collision_hits+=1
  if bool(terrain.call("stream_contains_physical_chunk",adjusted.x,adjusted.z)):
    adjusted.y=maxf(adjusted.y,_ground_surface_y(adjusted.x,adjusted.z)+0.54)
  return adjusted

func update_camera() -> void:
  if camera==null or actor==null:
    return
  camera.near=0.14 # Near clip should not cut through the character
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
    # Keep the real character rig visible; the lens sits in front of the
    # face, allowing arms/legs on downward look without looking into a head.
    camera.position=actor.position+Vector3.UP*1.58+_forward()*0.36
    camera.look_at(camera.position+Vector3(-sin(_yaw)*cos(_pitch),
      sin(_pitch),-cos(_yaw)*cos(_pitch)),Vector3.UP)
  else:
    var target: Vector3=actor.position+Vector3.UP*1.19
    var offset:=Vector3(sin(_yaw)*cos(_pitch),
      sin(_pitch),cos(_yaw)*cos(_pitch))
    var chase_distance: float=_distance+_soar_camera_extra if camera_mode=="soar" else _distance
    var desired: Vector3=target+offset*chase_distance
    if camera_mode=="iso":
      _pitch=PI/4.0
    desired.y=maxf(desired.y,_ground_surface_y(desired.x,desired.z)+0.7)
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
    _touches_global.clear()
    _last_pinch=-1.0
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
    "pinch_events_real_input":_pinch_zoom_events,
    "visible_camera_shortcuts":7,
    "camera_angle_locked":_camera_angle_locked,
    "iso45_follow_camera":camera_mode=="iso" and absf(_pitch-PI/4.0)<0.001,
    "third_person_avatar_visible":actor!=null and actor.visible,
    "jump_count":_jump_count,
    "landing_count":_landing_count,
    "jump_height_m":_jump_height,
    "actual_avatar_flight":camera_mode=="soar",
    "avatar_soar_altitude_m":_soar_altitude,
    "avatar_soar_target_altitude_m":_soar_target_altitude,
    "avatar_soar_current_speed_mps":_air_display_speed,
    "avatar_soar_landing":_soar_landing,
    "actual_wind_particles_emitting":_flight_wind_particles!=null and _flight_wind_particles.emitting,
    "flight_altitude_world_reference":_flight_altitude_beam!=null,
    "actual_licensed_3d_flying_sword_visible":_flight_sword!=null and _flight_sword.visible,
    "flight_ground_shadow_real_height":_flight_shadow!=null,
    "actual_knight_bone_animation":animator.current_animation if animator!=null else "",
    "avatar_soar_distance_m":_soar_distance_m,
    "blocked_real_wall_steps":_blocked_wall_steps,
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
    "gamepad_menu_navigation":true,
    "real_spirit_exam_altar_button":_root_exam_button!=null,
    "real_meditation_button":_meditate_button!=null,
    "real_breakthrough_button":_breakthrough_button!=null,
    "real_mortal_sparring":_spar_stage!="inactive",
    "practice_stage":_spar_stage,"practice_attack_count":_spar_attacks,
    "perfect_guards":_spar_perfect_guards,
    "normal_guards":_spar_normal_guards,
    "perfect_dodges":_spar_perfect_dodges,
    "normal_dodges":_spar_normal_dodges,
    "sparring_real_hits":_spar_hits,"sparring_misses":_spar_misses,
    "practice_last_outcome":_spar_last_outcome}
