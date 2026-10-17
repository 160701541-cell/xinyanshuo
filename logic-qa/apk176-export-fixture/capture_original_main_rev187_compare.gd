extends SceneTree
## GENUINE original APK176 compiled Main + rev187 REAL unsigned PCK framebuffer.
## Capture near the original user's worksite positions. A CPU/Vulkan GitHub
## Linux rendering snapshot is NOT a fake phone screenshot or concept art.
const OUT_ENV: String="CANGLAN_SCREENSHOT_DIR"
const PACK_ENV: String="CANGLAN_QA_PCK_PATH"
var base: Node
var room: Node
var view: SubViewport
var camera: Camera3D

func _initialize() -> void:
  call_deferred("_capture")

func _fail(why: String) -> void:
  printerr("FAIL_REV187_REAL_GAME_SCREENSHOT_",why)
  quit(5)

func _save(file_name: String) -> bool:
  var out: String=OS.get_environment(OUT_ENV)
  var image: Image=get_root().get_texture().get_image()
  if image==null or image.is_empty() or image.get_width()<900 or image.get_height()<500:
    return false
  var bins: Dictionary={}
  for y in range(30,image.get_height()-30,23):
    for x in range(30,image.get_width()-30,23):
      var c: Color=image.get_pixel(x,y)
      bins[int(c.r8/18)*220+int(c.g8/18)*15+int(c.b8/18)]=true
  if bins.size()<28:
    return false
  if image.save_png(out.path_join(file_name))!=OK:
    return false
  print("PASS_REV187_REAL_ORIGINAL_MAIN_VISUAL_FRAME ",file_name,
    " ",image.get_width(),"x",image.get_height(),
    " colors=",bins.size()," actual_camera=",camera.position)
  return true

# REV191: the earlier "successful" Godot screenshots had a completely
# INVISIBLE terrain mesh. At x=340..920, y=425..590, 83% of pixels were
# exactly the SKY background. Fail REAL framebuffer acceptance on that.
func _audit_visible_ground() -> bool:
  var screenshot: Image=get_root().get_texture().get_image()
  if screenshot==null or screenshot.get_width()<900 or screenshot.get_height()<600:
    return false
  var w: float=float(screenshot.get_width())/1280.0
  var h: float=float(screenshot.get_height())/720.0
  var sky: Color=screenshot.get_pixel(roundi(640*w),roundi(140*h))
  var sky_like: int=0
  var total: int=0
  for yi in range(425,590,17):
    for xi in range(340,920,17):
      var c: Color=screenshot.get_pixel(roundi(float(xi)*w),roundi(float(yi)*h))
      var delta: float=maxf(absf(c.r-sky.r),
        maxf(absf(c.g-sky.g),absf(c.b-sky.b)))
      if delta<0.051:
        sky_like+=1
      total+=1
  var ratio: float=float(sky_like)/maxf(1.0,float(total))
  print("REV191_REAL_RENDER_SOIL_VS_SKY_BLUE_VOID_PIXEL_RATIO ",ratio)
  if ratio>0.48:
    printerr("FAIL_REV191_GROUND_IS_STILL_INVISIBLE_SKY_BLUE_VOID ",ratio)
    return false
  return true

func _assert_rendered_character_pixels(label: String) -> bool:
  # The original QA only inspected the scene tree and projected a headpoint.
  # Those tests PASSED WHILE THE ACTUAL HERO WAS 100% TRANSPARENT.
  # The photo below must contain dark-colored Knight armor in a true 3D
  # framebuffer rectangle around the player; empty light soil is a failure.
  var frame: Image=get_root().get_texture().get_image()
  if frame==null or frame.is_empty() or frame.get_width()<900:
    return false
  var dark_samples: int=0
  var palette: Dictionary={}
  for yy in range(290,445,3):
    for xx in range(578,704,3):
      var sample: Color=frame.get_pixel(xx,yy)
      if sample.get_luminance()<0.50:
        dark_samples+=1
      palette[sample.to_html(false)]=true
  print("REV198_GENUINE_SCREEN_RENDERED_PLAYER_PIXEL_AUDIT ",label,
    " opaque_dark_samples=",dark_samples," color_variety=",palette.size())
  if dark_samples<34 or palette.size()<45:
    printerr("FAIL_REV198_RENDERED_PLAYER_IS_STILL_INVISIBLE_NOT_MERE_SCENE_NODE ",label,
      " dark=",dark_samples," distinct=",palette.size())
    return false
  return true

func _capture() -> void:
  var out: String=OS.get_environment(OUT_ENV)
  var pack: String=OS.get_environment(PACK_ENV)
  if out.is_empty() or pack.is_empty() or not FileAccess.file_exists(pack):
    _fail("PCK_OR_OUTPUT_MISSING")
    return
  if not ProjectSettings.load_resource_pack(pack,true):
    _fail("REAL_APK176_PCK_FAILED_TO_MOUNT")
    return
  var scene: PackedScene=load("res://scenes/main.tscn")
  if scene==null:
    _fail("REAL_APK176_MAIN_MISSING")
    return
  base=scene.instantiate()
  get_root().add_child(base)
  await process_frame
  await process_frame
  room=base.get_node_or_null("CanglanAutonomousEcologyWorldRev187")
  if room==null:
    _fail("NEW_REAL_SCENE_NOT_ACTIVE")
    return
  var state: Dictionary=room.call("stats")
  if int(state["revision"])!=187:
    _fail("NOT_REV187_RUNTIME_SCENE")
    return
  view=room.get("view")
  camera=room.get("camera")
  var player: Node=room.get("controls")
  player.call("_set_mode","fly")
  # Same original rev184/rev186 worksite: exterior slightly elevated look
  # toward stage construction, with road and trees around it.
  player.set("_flight_position",Vector3(16,9,22))
  player.set("_yaw",0.55)
  player.set("_pitch",-0.22)
  player.call("update_camera")
  for i in range(90):
    room.call("_process",0.70)
    await process_frame
  # After worksite progresses, restore exact camera for stable comparison.
  player.set("_flight_position",Vector3(16,9,22))
  player.call("update_camera")
  for i in range(6):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _audit_visible_ground():
    _fail("REV191_REAL_PHYSICAL_SOIL_IS_INVISIBLE_OR_BLUE_SKY_VOID")
    return
  if not _save("real_apk176_rev187_worksite_same_position_wide.png"):
    _fail("WIDE_FRAME_TOO_MONOCHROMATIC_OR_SAVE_FAIL")
    return
  player.set("_flight_position",Vector3(9,5.7,6))
  player.set("_yaw",0.77)
  player.set("_pitch",-0.1)
  player.call("update_camera")
  for i in range(6):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev187_worksite_same_position_close.png"):
    _fail("CLOSE_FRAME_RENDER_FAIL")
    return
  # REV197: actual original APK176 license-backed CHARACTER is in the
  # camera frame in third person and follows a fixed 45-degree iso orbit.
  # Screenshots are Mesa/Linux Godot frames, NEVER user Adreno phone photos.
  player.call("_set_mode","third")
  player.set("_yaw",0.65)
  player.set("_pitch",0.41)
  player.set("_distance",5.2)
  player.call("update_camera")
  for i in range(7):
    await process_frame
  await RenderingServer.frame_post_draw
  var avatar: Node3D=player.get("actor")
  var head_point: Vector3=avatar.position+Vector3.UP*1.0
  var actual_bounds: Vector2=room.call("_visible_bounds",avatar)
  print("REV197_PLAYER_ACTUAL_CAMERA_RENDER_DIAG actor=",avatar.position,
    " bounds=",actual_bounds," meshes=",avatar.find_children(
    "*","MeshInstance3D",true,false).size()," camera=",camera.position,
    " pixel_head=",camera.unproject_position(head_point),
    " camera_cull=",camera.cull_mask)
  for mesh_node in avatar.find_children("*","MeshInstance3D",true,false):
    var mesh_part: MeshInstance3D=mesh_node as MeshInstance3D
    var has_material: String=""
    if mesh_part.mesh!=null and mesh_part.mesh.get_surface_count()>0:
      var material: Material=mesh_part.get_active_material(0)
      has_material=str(material)
      if material is StandardMaterial3D:
        var std: StandardMaterial3D=material
        has_material+=" color="+str(std.albedo_color)+" transparency="+str(std.transparency)
    print("REV197_PLAYER_MESH_DIAG name=",mesh_part.name,
      " visible=",mesh_part.visible," visible_in_tree=",mesh_part.is_visible_in_tree(),
      " local_aabb=",mesh_part.get_aabb()," glob_origin=",mesh_part.global_position,
      " mat=",has_material)
  if not avatar.visible or camera.is_position_behind(head_point):
    _fail("REV197_THIRD_PERSON_AVATAR_ACTUALLY_INVISIBLE_IN_RENDERING_CAMERA")
    return
  if not _save("real_apk176_rev197_licensed_player_visible_close.png"):
    _fail("REV197_ACTUAL_THIRD_PERSON_FRAME_NOT_CAPTURED")
    return
  if not _assert_rendered_character_pixels("third_close"):
    _fail("REV198_TRUE_OPAQUE_CHARACTER_PIXELS_MISSING_FROM_THIRD_VIEW")
    return
  player.call("toggle_iso45")
  player.call("update_camera")
  for i in range(8):
    await process_frame
  await RenderingServer.frame_post_draw
  if player.get("camera_mode")!="iso" or absf(float(player.get("_pitch"))-PI/4.0)>0.002:
    _fail("REV197_ACTUAL_45DEG_FOLLOW_CAMERA_NOT_45DEG")
    return
  if not _save("real_apk176_rev197_follow_player_45deg_view.png"):
    _fail("REV197_REAL_45DEG_FRAME_NOT_CAPTURED")
    return
  if not _assert_rendered_character_pixels("follow_45deg"):
    _fail("REV198_TRUE_OPAQUE_CHARACTER_PIXELS_MISSING_FROM_45DEG_VIEW")
    return
  print("PASS_REV198_ACTUAL_OPAQUE_AVATAR_PIXELS_RENDER_IN_REAL_3D_THIRD_PERSON_AND_45DEG")
  # rev200: original screenshot QA previously failed to show a user the
  # NEW air animation/sword/wind and mistook hair UNDER the torso for hair
  # on the head. Capture a real engine airborne view before OTA signing.
  var head_hair: MeshInstance3D=player.get("actor").get_node_or_null(
    "ActualCC0QuaterniusHairLongNOTArtificialHelmet")
  if head_hair==null:
    _fail("REV200_NO_HAIR_ON_REAL_RENDERED_AVATAR")
    return
  var hair_bounds: Vector2=room.call("_visible_bounds",head_hair)
  var target_y: float=float(player.get("actor").position.y)+float(
    player.get("actor").get_meta("actor_visual_height_m",0.0))
  if hair_bounds.y<target_y-0.10 or hair_bounds.x<target_y-0.55:
    _fail("REV200_SOURCES_HAIR_HIDDEN_IN_CHEST_WHILE_FACE_STILL_BARE_"+str(hair_bounds))
    return
  player.call("toggle_iso45")
  player.call("toggle_avatar_flight")
  player.set("_distance",6.5)
  for i in range(12):
    player.call("step",0.085)
    await process_frame
  player.call("update_camera")
  for i in range(9):
    await process_frame
  await RenderingServer.frame_post_draw
  var flying: Dictionary=player.call("stats")
  if not bool(flying.get("actual_licensed_3d_flying_sword_visible",false)) or (
      not bool(flying.get("actual_wind_particles_emitting",false))):
    _fail("REV200_FLYING_GODOT_IMAGE_NOT_AN_ACTUAL_REAL_SWORD_AND_WIND_SCENE")
    return
  if not _save("real_apk176_rev200_actual_licensed_sword_soaring_visible_ground_altitude.png"):
    _fail("REV200_GODOT_SKY_TRAVEL_RENDERED_FRAME_FAILURE")
    return
  print("PASS_REV200_ORIGINAL_REAL_GODOT_AIRBORNE_SWORD_WIND_HAIR_HEIGHT_UI_FRAME")
  # Rev203 actual rendered turning frame: licensed blade follows the player's
  # physical airborne bank; no still image or faked image-space rotation.
  var banking_avatar: Node3D=player.get("actor")
  banking_avatar.rotation.y=1.25
  player.set("_yaw",0.25)
  player.set("_joystick",Vector2(0.0,-1.0))
  player.call("step",0.16)
  player.set("_joystick",Vector2.ZERO)
  var licensed_blade: Node3D=room.get("world").get_node_or_null(
    "ActualQuaterniusKnightCC0FlyingSwordUnderPlayerFeet")
  if absf(banking_avatar.rotation.z)<0.003 or licensed_blade==null or (
      absf(licensed_blade.rotation.z-banking_avatar.rotation.z)>0.005):
    _fail("REV203_REAL_PLAYER_AND_LICENSED_SWORD_NOT_BANKING_IN_GODOT")
    return
  for i in range(6):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev203_actual_bank_sword_ground_reference.png"):
    _fail("REV203_REAL_TURNING_SWORD_GAME_FRAME_NOT_VISIBLE")
    return
  print("PASS_REV203_REAL_GODOT_RENDERED_LICENCED_SWORD_BANK_AND_GROUND_REFERENCE")
  player.call("toggle_avatar_flight")
  # The screenshot worksite may lie over a solid building occluder. Move
  # the QA camera/hero to the exact known open 29m practice site BEFORE
  # the real physical landing tick; do not bypass any flight collisions or
  # make the game appear to support landing through blocked roofs.
  var training_ground: Node3D=player.get("actor")
  var physical_ground_y: float=float(room.get("terrain_world").call(
    "height_at",29.0,29.0))
  training_ground.position=Vector3(29.0,physical_ground_y+
    float(training_ground.get_meta("actor_ground_offset_y",0.0))+
    float(player.get("_soar_altitude")),29.0)
  var physical_descent_frames: int=0
  for i in range(20):
    player.call("step",0.12)
    physical_descent_frames+=1
    if String(player.get("camera_mode"))=="third":
      break
  if String(player.get("camera_mode"))!="third":
    _fail("REV204_PHYSICAL_LANDING_AT_DRY_OPEN_PRACTICE_SITE_FAILED height="+
      str(player.get("_soar_altitude"))+" frames="+str(physical_descent_frames)+
      " blocked="+str(player.get("_blocked_wall_steps")))
    return
  # Capture the actual original game's martial duel target HUD and **world**
  # HP/MP overhead bars, then the physically moving spiritual projectile.
  # Engine photos are clearly labeled Linux/Mesa, NEVER phone images.
  var fighter: Node3D=player.get("actor")
  fighter.position=Vector3(29,float(room.get("terrain_world").call(
    "height_at",29.0,29.0))+float(fighter.get_meta(
      "actor_ground_offset_y",0.0)),29)
  player.set("_yaw",0.0)
  player.call("update_camera")
  var training: Dictionary=player.call("practice_action")
  if not bool(training.get("ok",false)):
    _fail("REV204_REAL_PRACTICE_OPPONENT_NOT_AVAILABLE_FOR_ENGINE_SNAPSHOT_"+str(training))
    return
  var opponent_ui: PanelContainer=player.get("_target_panel")
  var head_label: Label3D=player.get("_spar_opponent_tag")
  if opponent_ui==null or not opponent_ui.visible or head_label==null:
    _fail("REV204_REAL_TARGET_HEALTH_MANA_MISSING_FROM_ENGINE_FRAME")
    return
  # Let the mobile third-person duel camera ease from the original 9.5m
  # walk distance to an immersive 6.4m focus while preserving user zoom.
  for i in range(12):
    player.call("step",0.105)
  if float(player.get("_combat_camera_pull"))>-1.5:
    _fail("REV204_REAL_DUEL_CAMERA_STILL_TOO_FAR_TO_SEE_ACTUAL_MAGIC")
    return
  var before_hp: int=int(player.get("_spar_enemy_health"))
  if not bool(player.call("sword_attack")) or (
      int(player.get("_spar_enemy_health"))>=before_hp):
    _fail("REV204_REAL_SWORD_3D_IMPACT_OR_HEALTH_LEDGER_NOT_WORKING")
    return
  for i in range(2):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev204_opponent_realm_hp_mp_sword_sparks.png"):
    _fail("REV204_REAL_COMBAT_VITALS_AND_MORTAL_SWORD_SCREENSHOT_MISSING")
    return
  print("PASS_REV204_REAL_GODOT_RENDERED_OPPONENT_OVERHEAD_HP_MP_AND_SWORD_IMPACT")
  # Only screenshot QA uses a documented, reversible level-1 art fixture.
  # Mechanics+finite-mana authority are independently checked in real Main
  # QA using actual root examination and Qi-paid breakthrough.
  var arts: RefCounted=room.get("cultivation")
  var saved: Dictionary=arts.get("player_data").duplicate(true)
  var trial: Dictionary=arts.get("player_data")
  trial["tested"]=true
  trial["root_kind"]="木灵根"
  trial["method"]="CL-TECH-NAYUAN-BREATHING-V1"
  trial["layer"]=1
  trial["realm"]="炼气"
  trial["mana"]=12
  trial["known_arts"]=["CL-ART-SPIRIT-BOLT-V1"]
  var spell: Dictionary=player.call("cast_spirit_bolt")
  if not bool(spell.get("ok",false)) or not bool(spell.has("projectile")):
    _fail("REV204_REAL_MANA_PAID_QI_PROJECTILE_NOT_SPAWNED_IN_ENGINE")
    return
  player.call("_step_spell_projectiles",0.050)
  var active_bolts: Array=player.get("_spell_projectiles")
  if active_bolts.size()!=1 or (not is_instance_valid(active_bolts[0]["node"])):
    _fail("REV204_MAGIC_PROJECTILE_DISAPPEARED_BEFORE_TRUE_MIDAIR_CAPTURE")
    return
  var impact_health_before: int=int(player.get("_spar_enemy_health"))
  # Freeze only the controllable hero for TWO renderer frames to capture a
  # real spatial bolt in transit (Godot engine frame, no Photoshop composite).
  # Restore simulation immediately afterward and check actual damage.
  player.set("_enabled",false)
  for i in range(2):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev204_mana_paid_qi_bolt_midair.png"):
    _fail("REV204_REAL_QI_PROJECTILE_3D_MIDFLIGHT_SCREENSHOT_MISSING")
    return
  player.set("_enabled",true)
  player.call("_step_spell_projectiles",0.18)
  if int(player.get("_spar_enemy_health"))>=impact_health_before:
    _fail("REV204_MIDFLIGHT_BOLT_FAILED_TO_DEAL_ACTUAL_MANA_PAID_HIT_DAMAGE")
    return
  for i in range(2):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev204_qi_bolt_real_impact_damage.png"):
    _fail("REV204_QI_BOLT_REAL_IMPACT_AND_DAMAGE_FRAME_MISSING")
    return
  print("PASS_REV204_REAL_GODOT_RENDERED_MANA_PAID_SPIRIT_BOLT_IN_FLIGHT")
  print("PASS_REV204_REAL_GODOT_MIDFLIGHT_AND_IMPACT_FINITE_MANA_REAL_HP_DAMAGE_FRAMES")
  player.call("stop_practice")
  arts.set("player_data",saved)
  arts.call("save_state")
  player.call("_set_mode","third")
  var real_person: Node3D=arts.get("npc_visuals")["CL-XIUXIAN-001"]["actor"]
  var source_hero_pos: Vector3=fighter.position
  fighter.position=real_person.position+Vector3(2.7,0,0.8)
  player.call("toggle_target_lock")
  for i in range(8):
    player.call("step",0.10)
    await process_frame
  if player.get("_locked_target")==null or not (
      player.get("_locked_target_label") as Label).visible:
    _fail("REV205_TARGET_LOCK_ICON_CAMERA_AND_REALM_NOT_REACHABLE_IN_REAL_RENDER")
    return
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev205_genuine_open_source_hud_target_lock.png"):
    _fail("REV205_GENUINE_LUCIDE_TARGET_LOCK_ENGINE_FRAME_MISSING")
    return
  player.call("toggle_target_lock")
  # Real physical forest harvest, not test-instantiated bag freebies.
  var econ=room.get("sim")
  var resource_id: String=""
  for id in econ.natural_nodes:
    # A photography QA session must still harvest a TRUE finite tree,
    # but must NOT fell any of the three unchanged mature species before
    # taking the same-session physical 8-9m tree-vs-avatar comparisons.
    if room.get("hq_mature_tree_visuals").has(id):
      continue
    if String(econ.natural_nodes[id].get("kind",""))=="tree" and int(
        econ.natural_nodes[id].get("remaining",0))>=3:
      resource_id=String(id)
      break
  if resource_id=="":
    _fail("REV205_REAL_LICENSED_FOREST_RESOURCE_NOT_PRESENT_FOR_BAG_FRAME")
    return
  fighter.position=econ.resource_positions[resource_id]
  player.set("_auto_resource_id",resource_id)
  econ.citizens["CL-PLAYER-0184-0001"]["energy"]=100
  var harvested: Dictionary=player.call("interact")
  if not bool(harvested.get("ok",false)):
    _fail("REV205_REAL_RESOURCE_NOT_RECEIVED_IN_PERSONAL_BAG_"+str(harvested))
    return
  player.call("_open_game_menu","inventory")
  for i in range(3):
    await process_frame
  await RenderingServer.frame_post_draw
  var actual_bag_list: ItemList=player.get("_inventory_list")
  if actual_bag_list==null or not actual_bag_list.visible or actual_bag_list.item_count==0:
    _fail("REV205_SOURCE_BASED_BACKPACK_GRID_NOT_VISIBLE_IN_REAL_GODOT_SCREENSHOT")
    return
  if not _save("real_apk176_rev205_real_backpack_lucide_equipment.png"):
    _fail("REV205_REAL_INVENTORY_AND_EQUIPMENT_ENGINE_FRAME_MISSING")
    return
  player.call("_open_game_menu","inventory")
  fighter.position=source_hero_pos
  print("PASS_REV205_GENUINE_GODOT_1280X720_LUCIDE_UI_TARGET_LOCK_AND_FINITE_BACKPACK_FRAMES")
  # REV207 ART - 100% real original APK176 / Godot4.4 scene frames.
  # Render the vendor-prefabricated house with actual 512px PBR roof/wall/
  # wood maps and the real physical shader-textured meadow from TWO distances.
  # No generated composite / concept illustration / fake phone screenshot.
  var painter: RefCounted=room.get("vivid_materials")
  if painter==null or int(painter.call("summary").get("material_maps_loaded",0))!=9:
    _fail("REV207_REAL_VENDOR_TEXTURES_WERE_NOT_BOUND_TO_RUNTIME_PBR")
    return
  # 2026-10-18 user rejected 6 houses magically placed for free.
  # This QA frame shows a REAL construction cycle funded ONLY by actually
  # exhausting registered 5-wood trees / 10-stone boulders and waiting 8
  # world hours with a worker. It does not depict the startup village as
  # already constructed, and no debug inventory cheat grants free material.
  var economic=room.get("sim")
  var actor_id: String="CL-PLAYER-0184-0001"
  var stock: Dictionary=economic.villages["CL-REV186-HX-VILLAGE"]["stock"]
  var registered_resources: Array=economic.natural_nodes.keys()
  registered_resources.sort()
  for resource in registered_resources:
    var role: String=String(economic.natural_nodes[resource]["kind"])
    if role=="tree" and int(stock["wood"])>=200:
      continue
    if role=="stone" and int(stock["stone"])>=150:
      continue
    var attempts: int=0
    while int(economic.natural_nodes[resource]["remaining"])>0 and (
        attempts<5):
      economic.citizens[actor_id]["energy"]=100
      if not economic.gather_to_actor(actor_id,String(resource)):
        _fail("REV208_REAL_SOURCE_TREE_ORE_FINITE_GATHER_FAILED_"+String(resource))
        return
      if not economic.deliver_carried(actor_id):
        _fail("REV208_REAL_RESOURCE_LOADED_NOT_ACTUALLY_PAID_INTO_STOCK")
        return
      attempts+=1
  if int(stock["wood"])<200 or int(stock["stone"])<150:
    _fail("REV208_MINIMUM_40_TREES_AND_15_STONES_NOT_GENUINELY_AVAILABLE")
    return
  var fund: Dictionary=room.call(
    "quote_and_fund_near_house",Vector3(-7.0,0.0,-18.0))
  if not bool(fund.get("ok",false)) or int(fund.get(
      "spent_wood",0))!=200 or int(fund.get("spent_stone",0))!=150:
    _fail("REV208_200WOOD150STONE_HOUSE_COULD_NOT_BE_PAID_"+str(fund))
    return
  var ledger: RefCounted=room.get("housing")
  for hour in range(8):
    economic.tick()
    var completed: Array=ledger.call("advance_one_world_hour",1)
    for id in completed:
      room.call("_materialize_paid_house",String(id))
  var house: Node3D=room.get("finished_prefabs").get("CL-HOME-V206-001",null)
  if house==null or not is_instance_valid(house) or not (
      bool(ledger.get("sites")["CL-HOME-V206-001"]["completed"])):
    _fail("REV208_PAID_REAL_HOUSE_NOT_VISIBLE_AFTER_NPC_WORK_HOURS")
    return
  print("PASS_REV208_REAL_GODOT_HOUSE_COST_40_TREES_15_PILES_200WOOD_150STONE_8_WORK_HOURS")

  var real_ground: Node3D=room.get("terrain_world")
  player.call("_set_mode","third")
  var art_target: Vector3=house.position
  var art_y: float=float(real_ground.call(
    "height_at",art_target.x,art_target.z+9.0))
  fighter.position=Vector3(art_target.x,art_y+
    float(fighter.get_meta("actor_ground_offset_y",0.0)),art_target.z+9.0)
  player.set("_yaw",0.0)
  player.set("_pitch",0.44)
  player.set("_distance",12.2)
  player.call("update_camera")
  for i in range(4):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev207_vivid_cc0_texture_forest_wide.png"):
    _fail("REV207_REAL_GODOT_RICH_FOREST_CC0_MATERIAL_WIDE_FRAME_MISSING")
    return
  player.set("_distance",5.9)
  fighter.position=Vector3(art_target.x,
    float(real_ground.call("height_at",art_target.x,art_target.z+5.0))+
    float(fighter.get_meta("actor_ground_offset_y",0.0)),
    art_target.z+5.0)
  player.call("update_camera")
  for i in range(3):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev207_dense_tiny_pixel_cc0_pbr_house_close.png"):
    _fail("REV207_REAL_CC0_WALL_ROOF_NORMAL_MICROTEXELS_MISSING_CLOSE_FRAME")
    return
  var frame: Image=get_root().get_texture().get_image()
  var avg_saturation: float=0.0
  var sample_count: int=0
  var actual_colors: Dictionary={}
  for y in range(370,630,12):
    for x in range(240,1050,12):
      var sample: Color=frame.get_pixel(x,y)
      avg_saturation+=sample.s
      actual_colors[sample.to_html(false)]=true
      sample_count+=1
  avg_saturation/=maxf(1.0,float(sample_count))
  print("REV207_ACTUAL_GODOT_FOREGROUND_SATURATION=",avg_saturation,
    " unique_12px_rgb_samples=",actual_colors.size(),
    " material=",painter.call("summary"))
  if avg_saturation<0.225 or actual_colors.size()<80:
    _fail("REV207_TRUE_GODOT_FOREGROUND_STILL_GREY_LOW_SAT_OR_FLAT_TEXEL"+
      " saturation="+str(avg_saturation)+
      " samples="+str(actual_colors.size()))
    return
  # rev206 genuine Godot4.4.1 physical flower/ore screen pixels,
  # not generated scene illustrations or unlicensed rebuilt models.
  var source_medicines: Dictionary=room.get("spirit_resource_visuals")
  if source_medicines.size()!=13:
    _fail("REV206_REAL_LICENSED_HERBAL_3D_OBJECTS_MISSING")
    return
  for scene_point in [
      {"id":"CL-LINGCAO-W-01","x":-11.4,"z":-12.2,
       "file":"real_apk176_rev206_spirit_herbs_original_quaternius.png"},
      {"id":"CL-LINGSHI-01","x":25.2,"z":-27.5,
       "file":"real_apk176_rev206_luminous_spirit_ore_true_3d.png"}]:
    var id: String=String(scene_point["id"])
    var original: Node3D=source_medicines[id]["model"]
    if original==null or not original.visible or (
        original.find_children("*","MeshInstance3D",true,false).is_empty()):
      _fail("REV206_ORIGINAL_SPIRIT_PLANTS_OR_ORE_NOT_ACTUALLY_3D_RENDERED_"+id)
      return
    var x: float=float(scene_point["x"])
    var z: float=float(scene_point["z"])
    var foot_y: float=float(real_ground.call("height_at",x,z+4.6))
    fighter.position=Vector3(x,foot_y+float(fighter.get_meta(
      "actor_ground_offset_y",0.0)),z+4.6)
    player.call("_set_mode","third")
    player.set("_yaw",0.0)
    player.set("_pitch",0.41)
    player.set("_distance",8.8)
    room.call("_sync_spirit_resource_visuals",fighter)
    player.call("update_camera")
    for rev206_frame in range(4):
      await process_frame
    await RenderingServer.frame_post_draw
    if not _save(String(scene_point["file"])):
      _fail("REV206_ACTUAL_GODOT_REAL_PLANT_ORE_TEXTURE_FRAME_MISSING_"+id)
      return
  print("PASS_REV206_GODOT_REAL_3D_WILD_MEDICINAL_HERB_AND_LUMINOUS_ORE_VIEW")
  # P0 HQ-ECOLOGY: exactly three CC0 originally authored mature trees
  # are photographed INSIDE THE ORIGINAL APK176 Main at human scale,
  # not via a fake Blender model viewer or WorldX concept image.
  var hq_species: Dictionary=room.get("hq_mature_tree_visuals")
  for species_frame in [
      {"id":"CL-TREE-0184-000","species":"oak",
       "file":"real_godot_rev208_mature_oak_8m_vs_avatar.png"},
      {"id":"CL-TREE-0184-001","species":"maple",
       "file":"real_godot_rev208_mature_maple_9m_vs_avatar.png"},
      {"id":"CL-TREE-0184-002","species":"linden",
       "file":"real_godot_rev208_mature_linden_8m_vs_avatar.png"}]:
    var tree_id: String=String(species_frame["id"])
    var mature_tree: Node3D=hq_species.get(tree_id,null)
    if mature_tree==null or not mature_tree.visible or (
        not bool(mature_tree.get_meta("hq_rev208_mature_tree",false))):
      _fail("REV208_MATURE_FOREST_ACTUAL_MAIN_SOURCE_NOT_VISIBLE_"+tree_id)
      return
    var original_human_scale: Vector2=room.call("_visible_bounds",mature_tree)
    if original_human_scale.y-original_human_scale.x<7.5:
      _fail("REV208_HIGH_DETAIL_REAL_TREE_SHORTER_THAN_7_5M_"+tree_id)
      return
    var facing: Vector3=mature_tree.position
    var foot_y: float=float(real_ground.call(
      "height_at",facing.x,facing.z+7.0))
    fighter.position=Vector3(facing.x,foot_y+float(
      fighter.get_meta("actor_ground_offset_y",0.0)),facing.z+7.0)
    player.call("_set_mode","third")
    player.set("_yaw",0.0)
    player.set("_pitch",0.24)
    player.set("_distance",14.0)
    player.call("update_camera")
    for hq_render_frame in range(5):
      await process_frame
    await RenderingServer.frame_post_draw
    if not _save(String(species_frame["file"])):
      _fail("REV208_MAIN_GENUINE_PBR_MATURE_TREE_IMAGE_MISSING_"+tree_id)
      return
  print("PASS_REV208_THREE_TRUE_8_9M_PBR_TREE_GODOT441_ORIGINAL_MAIN_RENDERED_SCREENSHOTS")
  # P0 041 evidence: show the actual licensed original Main cultivator
  # fallen IN THE WORLD after real HP=0 and real 5000-census death debit.
  # Screenshot will NEVER substitute a photo of a model or concept art.
  var cult: RefCounted=room.get("cultivation")
  var society: RefCounted=room.get("world_society")
  var death_id: String="CL-XIUXIAN-002"
  var victim: Node3D=cult.get("npc_visuals")[death_id]["actor"]
  var body: StaticBody3D=cult.get("npc_colliders")[death_id]
  var death_start_pop: int=int(society.call("population"))
  var death_saved_npc: Dictionary=cult.get("npc_data")[death_id].duplicate(true)
  var death_saved_regions: Dictionary=society.get("regions").duplicate(true)
  var death_saved_journal: Dictionary=society.get("named_deaths").duplicate(true)
  var death_old_total: int=int(society.get("died_total"))
  var true_death: Dictionary=cult.call(
    "apply_npc_damage",death_id,999,"QA_CAMERA_REAL_DEATH")
  if not bool(true_death.get("ok",false)) or not bool(
      true_death.get("dead",false)) or not bool(true_death.get("persisted",false)) or (
      int(society.call("population"))!=death_start_pop-1) or (
      body.collision_layer!=0) or (
      not bool(victim.get_meta("actually_dead",false))):
    _fail("REV208_DEATH_IMAGE_MUST_FOLLOW_ACTUAL_CULTIVATOR_HP_AND_POP_DEBIT")
    return
  player.call("_set_mode","third")
  fighter.position=Vector3(victim.position.x,
    float(real_ground.call("height_at",victim.position.x,victim.position.z+4.2))+
    float(fighter.get_meta("actor_ground_offset_y",0.0)),victim.position.z+4.2)
  player.set("_yaw",0.0)
  player.set("_pitch",0.31)
  player.set("_distance",7.4)
  player.call("update_camera")
  for death_frame in range(6):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_godot_rev208_npc_death_state.png"):
    _fail("REV208_REQUIRED_REAL_GODOT_NPC_DEATH_SCREENSHOT_MISSING")
    return
  print("PASS_REV208_REAL_GODOT_CAMERA_CORPSE_FRAME_TRUE_MORTALITY_POPULATION_MINUS_ONE")
  # Render QA never commits a test-only death into the actual world files.
  cult.get("npc_data")[death_id]=death_saved_npc
  victim.rotation.x=0.0
  victim.set_meta("actually_dead",false)
  body.collision_layer=2
  society.set("regions",death_saved_regions)
  society.set("named_deaths",death_saved_journal)
  society.set("died_total",death_old_total)
  if not bool(society.call("force_save")) or not bool(
      cult.call("save_state")):
    _fail("REV208_DEATH_SCREENSHOT_TEST_STATE_ROLLBACK_FAILED")
    return
  print("PASS_REV207_ORIGINAL_APK176_GODOT_REAL_COLOR_512PBR_64TEXELS_IMAGES")
  print("PASS_REV197_ORIGINAL_GODOT_ENGINE_VISIBLE_ANIMATED_PLAYER_CLOSE_AND_45DEG_REAL_FRAMES")
  print("PASS_REV187_TWO_GENUINE_ENGINE_RENDERED_WORKSITE_FRAMES_NOT_PHONE_TESTS")
  base.queue_free()
  await process_frame
  quit(0)
