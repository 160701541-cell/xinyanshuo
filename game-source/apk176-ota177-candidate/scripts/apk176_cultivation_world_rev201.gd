extends RefCounted
## Original installed APK176/PCK rev201: authority-backed cultivation slice.
## A public world seed deterministically generates sect wanderers, spirit-root
## probabilities and spiritual geography; it does NOT erase existing excavated
## terrain saves or spawn free items. Both player and cultivators live on the
## SAME world-hour clock (including the existing 1x/5x/20x/100x button).
##
## No LLM is pretended: native CanglanLocalLLM is absent from original APK176.
## No sword or human 3D assets fabricated; use the game's licensed GLBs.
const SAVE_PATH: String="user://canglan_original_cultivation_seed_v1.json"
const SCHEMA: int=1
const NPC_COUNT: int=12
# These are actual learned arts, not dummy buttons that give mortals free mana.
const ART_SPIRIT_BOLT: String="CL-ART-SPIRIT-BOLT-V1"
const ART_SPIRIT_WARD: String="CL-ART-SPIRIT-WARD-V1"
const ELEMENTS: Array[String]=["金","木","水","火","土"]
const CULT_NAMES: Array[String]=[
  "陆青篁","宁照月","许寒渡","裴长川","秦映竹","叶孤棠",
  "沈雁回","顾逐风","纪松云","白栖迟","林知鹤","商玄微"]
const CULT_JOBS: Array[String]=[
  "游方散修","采药修士","外门弟子","护山巡修","丹道学徒","剑道散修",
  "采药修士","隐修客","外门弟子","炼器学徒","游方散修","问道客"]
const VILLAGE_CENTER: Vector3=Vector3(12.0,0.0,7.0)
var room: Node
var sim
var terrain: Node3D
var world: Node3D
var world_seed: int=0
var player_data: Dictionary={}
var npc_data: Dictionary={}
var npc_visuals: Dictionary={}
var npc_labels: Dictionary={}
var npc_vitals_bars: Dictionary={}
var npc_colliders: Dictionary={}
var altar: Node3D
var altar_marker: MeshInstance3D
var altar_caption: Label3D
var total_hours: int=0
var _save_writes: int=0
var _npc_ai_real_loaded: bool=false
var _save_error: String=""

func initialize(active_room: Node) -> void:
  room=active_room
  world=room.get("world")
  terrain=room.get("terrain_world")
  sim=room.get("sim")
  _load_or_initialize()
  _build_existing_stone_exam_altar()
  _generate_actual_visible_cultivators()

func _default_player() -> Dictionary:
  return {"tested":false,"root_kind":"","root_weights":[],
    "realm":"凡人","layer":0,"qi":0,"mana":0,
    "stress":0,"method":"","known_arts":[],"meditating":false,
    "practice_hours":0,"breakthrough_count":0}

func _load_or_initialize() -> void:
  var parsed: Variant=null
  if FileAccess.file_exists(SAVE_PATH):
    var file:=FileAccess.open(SAVE_PATH,FileAccess.READ)
    if file!=null:
      parsed=JSON.parse_string(file.get_as_text())
      file.close()
  if parsed is Dictionary and int(parsed.get("schema",-1))==SCHEMA and (
      int(parsed.get("world_seed",0))>0):
    world_seed=int(parsed["world_seed"])
    player_data=parsed.get("player",_default_player())
    npc_data=parsed.get("npcs",{})
    total_hours=int(parsed.get("whole_world_cultivation_hours",0))
  else:
    # A fixed seed is accepted by QA ONLY; real first-time installations get
    # a random reproducible seed, written ONCE to user:// and never rerolled
    # on merely relaunching the app. Preserve prior geology/terrain saves.
    var qa_seed: String=OS.get_environment("CANGLAN_CULTIVATION_WORLD_SEED_QA")
    world_seed=clampi(int(qa_seed),1,2147483000) if not qa_seed.is_empty() else (
      randi_range(100000000,2147483000))
    player_data=_default_player()
    npc_data={}
    total_hours=0
  # Backward compatible: preserve a rev201 save and learn the arts from
  # already-reached milestones instead of resetting progress on hot update.
  if not player_data.has("known_arts"):
    player_data["known_arts"]=[]
  var known: Array=player_data["known_arts"]
  if int(player_data.get("layer",0))>=1 and not String(
      player_data.get("method","")).is_empty() and not known.has(ART_SPIRIT_BOLT):
    known.append(ART_SPIRIT_BOLT)
  if int(player_data.get("layer",0))>=2 and not String(
      player_data.get("method","")).is_empty() and not known.has(ART_SPIRIT_WARD):
    known.append(ART_SPIRIT_WARD)
  for i in range(NPC_COUNT):
    var id: String="CL-XIUXIAN-%03d" % (i+1)
    if npc_data.has(id):
      # Existing citizens retain their real age, root, Qi and schedule.
      # Their newly added vitals are initialized only once per saved identity.
      var old: Dictionary=npc_data[id]
      var layer: int=int(old.get("layer",0))
      var hpmax: int=110+layer*12
      var mpmax: int=12+layer*9 if String(old.get("realm",""))=="炼气" else 0
      if not old.has("max_health"):
        old["max_health"]=hpmax
      if not old.has("health"):
        old["health"]=int(old["max_health"])
      if not old.has("max_mana"):
        old["max_mana"]=mpmax
      if not old.has("mana"):
        old["mana"]=int(old["max_mana"])
      continue
    var rng:=_entity_rng(id)
    npc_data[id]={
      "entity_id":id,"name":CULT_NAMES[i],"occupation":CULT_JOBS[i],
      "realm":"炼气" if i%4!=3 else "凡人武者",
      "layer":rng.randi_range(1,4) if i%4!=3 else 0,
      "root_element":ELEMENTS[rng.randi_range(0,ELEMENTS.size()-1)],
      "age":rng.randi_range(18,70),"hunger":rng.randi_range(8,36),
      "energy":rng.randi_range(45,90),"qi":rng.randi_range(0,60),
      "schedule":"歇息","life_hours":0,
      "hostility":0,"sect":"行云散修会" if i%3==0 else "独行"}
    var original: Dictionary=npc_data[id]
    var layer: int=int(original["layer"])
    original["max_health"]=110+layer*12
    original["health"]=int(original["max_health"])
    original["max_mana"]=12+layer*9 if String(original["realm"])=="炼气" else 0
    original["mana"]=int(original["max_mana"])
  save_state()

func _entity_rng(code: String) -> RandomNumberGenerator:
  var state: int=world_seed
  for i in range(code.length()):
    state=((state*1664525)+code.unicode_at(i)+1013904223)&0x7fffffff
  var rng:=RandomNumberGenerator.new()
  rng.seed=state
  return rng

func _build_existing_stone_exam_altar() -> void:
  # One actual licensed Kenney stone stair/rock fixture representing an
  # ancient relic discovered at generation, not a newly minted NPC house.
  var p:=Vector3(VILLAGE_CENTER.x,
    float(terrain.call("height_at",VILLAGE_CENTER.x,VILLAGE_CENTER.z)),
    VILLAGE_CENTER.z)
  altar=room.call("_place_asset","steps","CL-ANCIENT-SPIRIT-ROOT-TEST-ALTAR",
    p,1.05)
  if altar==null:
    push_error("CULTIVATION_P0_NO_LICENSED_SPIRIT_ALTAR_GLTF")
    return
  altar.set_meta("entity_id","CL-ANCIENT-SPIRIT-ROOT-TEST-ALTAR")
  altar.set_meta("spiritual_artifact","root_exam_only")
  altar_marker=MeshInstance3D.new()
  altar_marker.name="SpiritualRootStationActualInteractiveWorldMarker"
  var halo:=TorusMesh.new()
  halo.inner_radius=1.16
  halo.outer_radius=1.25
  halo.rings=32
  halo.ring_segments=8
  var gold:=StandardMaterial3D.new()
  gold.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  gold.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  gold.albedo_color=Color("#a8f6ee",0.76)
  gold.emission_enabled=true
  gold.emission=Color("#68d1cd")
  gold.emission_energy_multiplier=1.2
  halo.material=gold
  altar_marker.mesh=halo
  altar_marker.position=p+Vector3.UP*0.12
  altar_marker.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  world.add_child(altar_marker)
  altar_caption=Label3D.new()
  altar_caption.name="AncientSpiritualRootExamStationNearbyWorldLabel"
  altar_caption.text="灵根检测台  ·  靠近点击检测"
  altar_caption.font_size=25
  altar_caption.pixel_size=0.0046
  altar_caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED
  altar_caption.no_depth_test=false
  altar_caption.position=p+Vector3.UP*2.6
  world.add_child(altar_caption)

func _generate_actual_visible_cultivators() -> void:
  for i in range(NPC_COUNT):
    var code: String="CL-XIUXIAN-%03d" % (i+1)
    var rng:=_entity_rng(code)
    var a: float=float(i)*TAU/float(NPC_COUNT)+rng.randf_range(-0.15,0.15)
    var radius: float=8.5+rng.randf_range(0.0,7.0)
    var x: float=VILLAGE_CENTER.x+sin(a)*radius
    var z: float=VILLAGE_CENTER.z+cos(a)*radius
    if bool(terrain.call("is_water",x,z)):
      z=VILLAGE_CENTER.z+7.0
    var p:=Vector3(x,0,z)
    var character: Node3D=room.call("_place_asset","worker",code,p,1.0)
    if character==null:
      continue
    room.call("_normalize_worker_height",character)
    if room.get("licensed_long_hair_source")!=null:
      room.call("_attach_real_cc0_long_hair",character,i%3)
    # Visual individuality on the SAME approved GLB's existing armor
    # materials. Never regenerate a humanoid or accidentally tint its face.
    var cloth_palette: Array[Color]=[
      Color("#254d43"),Color("#31566b"),Color("#513e67"),Color("#654536"),
      Color("#36455e"),Color("#527042"),Color("#5d4864"),Color("#304f58")]
    for mesh_node in character.find_children("*","MeshInstance3D",true,false):
      var mesh_visual: MeshInstance3D=mesh_node as MeshInstance3D
      if mesh_visual.mesh==null or mesh_visual.name.contains("Hair"):
        continue
      for surf in range(mesh_visual.mesh.get_surface_count()):
        var oldmat: Material=mesh_visual.get_active_material(surf)
        if oldmat is StandardMaterial3D and (
            String(oldmat.resource_name).to_lower().contains("armor") or surf==0):
          var armor: StandardMaterial3D=(oldmat as StandardMaterial3D).duplicate(true)
          armor.albedo_color=cloth_palette[i%cloth_palette.size()]
          armor.albedo_color.a=1.0
          armor.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
          mesh_visual.set_surface_override_material(surf,armor)
    character.set_meta("entity_id",code)
    character.set_meta("npc_cultivator",true)
    character.set_meta("npc_name",String(npc_data[code]["name"]))
    character.position.y=float(terrain.call("height_at",x,z))+float(
      character.get_meta("actor_ground_offset_y",0.0))
    var anim: AnimationPlayer=null
    var idle_clip: String=""
    var walk_clip: String=""
    for node in character.find_children("*","AnimationPlayer",true,false):
      var aplayer: AnimationPlayer=node as AnimationPlayer
      for clip in aplayer.get_animation_list():
        var lower: String=String(clip).to_lower()
        if idle_clip.is_empty() and lower.contains("idle"):
          idle_clip=String(clip)
          anim=aplayer
        if walk_clip.is_empty() and (lower.contains("walking") or lower.contains("run")):
          walk_clip=String(clip)
          anim=aplayer
    if anim!=null and not idle_clip.is_empty():
      anim.play(idle_clip)
    npc_visuals[code]={
      "actor":character,"anchor":Vector3(x,0,z),
      "animation":anim,"idle":idle_clip,"walk":walk_clip,
      "wander_angle":a,"index":i}
    # Cultivators are physical people. Merely showing a mesh without
    # capsule collision led to previous phone reports of walk-through NPC.
    var body:=StaticBody3D.new()
    body.name="PhysicalCultivatorCitizenCollider_"+code
    body.collision_layer=2
    body.collision_mask=0
    var capsule:=CollisionShape3D.new()
    capsule.name="ActuallySolidHumanCitizensBody"
    var source:=CapsuleShape3D.new()
    source.radius=0.30
    source.height=1.65
    capsule.shape=source
    body.add_child(capsule)
    body.position=character.position+Vector3.UP*0.84
    body.set_meta("npc_entity_id",code)
    world.add_child(body)
    npc_colliders[code]=body
    var label:=Label3D.new()
    label.name="ActualCultivatorIdentity_"+code
    label.text="%s · %s" % [npc_data[code]["name"],
      npc_data[code]["occupation"]]
    label.font_size=23
    label.pixel_size=0.0040
    label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    label.visibility_range_end=23.0
    label.position=character.position+Vector3.UP*2.1
    world.add_child(label)
    npc_labels[code]=label
    # Billboard meters are WORLD-SPACE UI over real existing GLB bodies.
    # These are the authoritative persisted HP/MP values, not random art.
    var meter: Dictionary={}
    for meter_type in ["hp","mana"]:
      var tint: Color=Color("#d3695c") if meter_type=="hp" else Color("#55b5cd")
      var backdrop: MeshInstance3D=_new_npc_meter(code+"_"+meter_type+"_back",Color("#101923"))
      var fill: MeshInstance3D=_new_npc_meter(code+"_"+meter_type+"_fill",tint)
      meter[meter_type+"_back"]=backdrop
      meter[meter_type+"_fill"]=fill
    npc_vitals_bars[code]=meter
    _sync_npc_status_bar(code)

func _new_npc_meter(tag: String,tint: Color) -> MeshInstance3D:
  var bar:=MeshInstance3D.new()
  bar.name="ActualCultivatorVitals_"+tag
  var mesh:=QuadMesh.new()
  mesh.size=Vector2(0.82,0.075)
  var paint:=StandardMaterial3D.new()
  paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  paint.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
  paint.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
  paint.cull_mode=BaseMaterial3D.CULL_DISABLED
  paint.albedo_color=tint
  mesh.material=paint
  bar.mesh=mesh
  bar.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  bar.visibility_range_end=19.0
  world.add_child(bar)
  return bar

func _sync_npc_status_bar(id: String) -> void:
  if not npc_vitals_bars.has(id) or not npc_visuals.has(id):
    return
  var state: Dictionary=npc_data[id]
  var entity: Node3D=npc_visuals[id]["actor"]
  var bars: Dictionary=npc_vitals_bars[id]
  for kind in ["hp","mana"]:
    var current: int=int(state.get("health",0)) if kind=="hp" else int(
      state.get("mana",0))
    var maximum: int=maxi(0,int(state.get("max_health",0))) if kind=="hp" else maxi(
      0,int(state.get("max_mana",0)))
    var ratio: float=clampf(float(current)/float(maxi(1,maximum)),0.0,1.0)
    var y: float=1.91 if kind=="hp" else 1.80
    var background: MeshInstance3D=bars[kind+"_back"]
    var foreground: MeshInstance3D=bars[kind+"_fill"]
    background.position=entity.position+Vector3(0,y,0.01)
    foreground.position=entity.position+Vector3(-0.41*(1.0-ratio),y,0.025)
    foreground.scale.x=maxf(0.001,ratio)
    foreground.visible=ratio>0.001 and maximum>0

func at_altar(max_distance: float=3.4) -> bool:
  if altar==null or room.get("controls")==null:
    return false
  var hero: Node3D=room.get("controls").get("actor")
  if hero==null:
    return false
  return Vector2(hero.position.x-altar.position.x,
    hero.position.z-altar.position.z).length()<=max_distance

func _roll_player_roots() -> Dictionary:
  var rng:=_entity_rng("CL-PLAYER-0184-0001-SPIRITROOT-LOCKED")
  var no_root: bool=rng.randi_range(0,99)<12
  var weights: Array=[]
  for i in range(ELEMENTS.size()):
    weights.append(rng.randi_range(5,98))
  var dominant: int=0
  for i in range(ELEMENTS.size()):
    if int(weights[i])>int(weights[dominant]):
      dominant=i
  return {"kind":"无灵根" if no_root else ELEMENTS[dominant]+"灵根",
    "weights":weights if not no_root else []}

func examine_player_root() -> Dictionary:
  if not at_altar():
    return {"ok":false,"message":"请靠近地图中的【灵根检测台】，距离必须小于3.4米"}
  if not bool(player_data.get("tested",false)):
    var result: Dictionary=_roll_player_roots()
    player_data["tested"]=true
    player_data["root_kind"]=result["kind"]
    player_data["root_weights"]=result["weights"]
    if result["kind"]!="无灵根":
      # Technique knowledge, not a physical inventory item or paid relic.
      player_data["method"]="CL-TECH-NAYUAN-BREATHING-V1"
    save_state()
  var kind: String=String(player_data["root_kind"])
  return {"ok":true,"tested":true,"root_kind":kind,
    "can_cultivate":kind!="无灵根",
    "method":String(player_data.get("method","")),
    "message":"检测结果："+kind+"；检测台石刻传下《纳元吐息法》" if kind!="无灵根"
      else "检测结果：无灵根；可以继续修行凡人武学，不能凭空释放仙法"}

func toggle_player_meditation() -> Dictionary:
  if not bool(player_data.get("tested",false)):
    return {"ok":false,"message":"请先前往灵根检测台确认灵根"}
  if String(player_data.get("root_kind",""))=="无灵根":
    return {"ok":false,"message":"无灵根不能吸纳灵气；凡人武学仍可提升"}
  if bool(player_data.get("meditating",false)):
    player_data["meditating"]=false
    save_state()
    return {"ok":true,"meditating":false,"message":"结束吐纳，世界依然继续运行"}
  if String(player_data.get("method","")).is_empty():
    return {"ok":false,"message":"尚未得到功法：不能无凭空修炼"}
  if int(player_data.get("stress",0))>=92:
    return {"ok":false,"message":"经脉负荷太高，请停止修炼休息"}
  player_data["meditating"]=true
  save_state()
  return {"ok":true,"meditating":true,"message":"开始运行《纳元吐息法》；每一世界时辰真实增长修为"}

func player_breakthrough() -> Dictionary:
  if not bool(player_data.get("tested",false)) or String(player_data.get(
      "root_kind",""))=="无灵根":
    return {"ok":false,"message":"未获灵根不能突破炼气"}
  var current: int=int(player_data.get("layer",0))
  if current>=13:
    return {"ok":false,"message":"炼气十三层已满；筑基丹、根基与筑基关口尚未开放"}
  var cost: int=60+current*70
  if int(player_data.get("qi",0))<cost:
    return {"ok":false,"message":"修为不足：突破需要%d灵气，当前%d" % [
      cost,int(player_data.get("qi",0))]}
  if int(player_data.get("stress",0))>70:
    return {"ok":false,"message":"经脉负荷过高；请休息，突破不可跳过损伤风险"}
  player_data["qi"]=int(player_data["qi"])-cost
  player_data["layer"]=current+1
  player_data["realm"]="炼气"
  player_data["mana"]=int(player_data.get("mana",0))+12
  var known_arts: Array=player_data.get("known_arts",[])
  if current+1==1 and not known_arts.has(ART_SPIRIT_BOLT):
    known_arts.append(ART_SPIRIT_BOLT)
  if current+1==2 and not known_arts.has(ART_SPIRIT_WARD):
    known_arts.append(ART_SPIRIT_WARD)
  player_data["known_arts"]=known_arts
  player_data["stress"]=int(player_data.get("stress",0))+14
  player_data["breakthrough_count"]=int(player_data["breakthrough_count"])+1
  save_state()
  return {"ok":true,"layer":int(player_data["layer"]),
    "message":"突破成功：炼气第%d层！消耗%d修为，法力容量得到提升" % [
      current+1,cost]}

func advance_world_hour() -> void:
  total_hours+=1
  # This is the same sim.tick() hour already advanced by the original world
  # clock. No second phantom clock can advance qi without economic time.
  if bool(player_data.get("meditating",false)) and (
      String(player_data.get("method",""))!="" ):
    var energy_person: Dictionary=sim.citizens.get(
      "CL-PLAYER-0184-0001",{})
    if int(energy_person.get("energy",0))<4:
      player_data["meditating"]=false
    else:
      energy_person["energy"]=int(energy_person["energy"])-4
      var weights: Array=player_data.get("root_weights",[])
      var resonance: int=0
      for w in weights:
        resonance=maxi(resonance,int(w))
      # Real geography: training nearer the ancient spirit-altar is richer,
      # and the whole-world seed changes the region's spiritual strength.
      var vein: int=12+world_seed%7
      var proximity: int=7 if at_altar(11.0) else 0
      var gain: int=10+int(float(resonance)/18.0)+vein/4+proximity
      player_data["qi"]=mini(2000,int(player_data["qi"])+gain)
      # Spiritual mana is NOT free on button press. It recovers only during
      # an actual world-hour meditation that consumed finite human energy.
      var max_mana: int=int(player_data.get("layer",0))*12
      player_data["mana"]=mini(max_mana,int(player_data.get("mana",0))+3)
      player_data["stress"]=mini(100,int(player_data["stress"])+6)
      player_data["practice_hours"]=int(player_data["practice_hours"])+1
      if int(player_data["stress"])>=93:
        player_data["meditating"]=false
  else:
    player_data["stress"]=maxi(0,int(player_data.get("stress",0))-5)
  for id in npc_data:
    var npc: Dictionary=npc_data[id]
    npc["life_hours"]=int(npc["life_hours"])+1
    if int(npc["life_hours"])%8760==0:
      npc["age"]=int(npc["age"])+1
    # Rule-based behavior remains honest while native AI is unavailable:
    # no invented Qwen thoughts, no minted potions, ore, housing or money.
    var phase: int=(total_hours+int(id.right(3)))%12
    var schedule: String="练气" if phase<5 else (
      "采药探路" if phase<8 else ("巡山" if phase<10 else "打坐休息"))
    npc["schedule"]=schedule
    if schedule=="练气" and npc["realm"]=="炼气":
      npc["qi"]=mini(500,int(npc["qi"])+2)
      npc["energy"]=maxi(0,int(npc["energy"])-3)
      npc["mana"]=mini(int(npc.get("max_mana",0)),int(npc.get("mana",0))+2)
    elif schedule=="打坐休息":
      npc["energy"]=mini(100,int(npc["energy"])+7)
    npc["hunger"]=mini(100,int(npc["hunger"])+2)
    # They can run low on food; no phantom meal appears for free.
    if int(npc["energy"])==0:
      npc["schedule"]="疲惫休息"
  if total_hours%6==0 or bool(player_data.get("meditating",false)):
    save_state()

func update_visible_npcs(delta: float) -> void:
  if room==null:
    return
  for id in npc_visuals:
    var v: Dictionary=npc_visuals[id]
    var node: Node3D=v["actor"]
    if not is_instance_valid(node):
      continue
    var index: int=int(v["index"])
    var state: Dictionary=npc_data[id]
    var is_walking: bool=String(state["schedule"]) in ["采药探路","巡山"]
    var anchor: Vector3=v["anchor"]
    if is_walking:
      var angle: float=float(v["wander_angle"])+float(total_hours)*0.24
      var radius: float=2.5+float(index%3)
      var wanted:=anchor+Vector3(sin(angle)*radius,0,cos(angle)*radius)
      var direction: Vector3=wanted-node.position
      direction.y=0
      if direction.length()>0.2:
        var distance: float=minf(direction.length(),
          1.4*minf(delta,0.25))
        var candidate: Vector3=node.position+direction.normalized()*distance
        if not bool(terrain.call("is_water",candidate.x,candidate.z)) and (
            bool(terrain.call("stream_contains_physical_chunk",candidate.x,candidate.z))):
          node.position.x=candidate.x
          node.position.z=candidate.z
          node.rotation.y=atan2(direction.x,direction.z)
    node.position.y=float(terrain.call("height_at",node.position.x,node.position.z))+float(
      node.get_meta("actor_ground_offset_y",0))
    if npc_colliders.has(id):
      var solid: StaticBody3D=npc_colliders[id]
      if is_instance_valid(solid):
        solid.position=node.position+Vector3.UP*0.84
    var ap: AnimationPlayer=v["animation"]
    if ap!=null:
      var chosen: String=String(v["walk"]) if is_walking else String(v["idle"])
      if chosen!="" and ap.current_animation!=chosen:
        ap.play(chosen)
    var label: Label3D=npc_labels[id]
    if is_instance_valid(label):
      label.position=node.position+Vector3.UP*2.23
      label.text="%s · %s\n生命 %d/%d  法力 %d/%d" % [
        String(state["name"]),
        "炼气%d层" % int(state["layer"]) if state["realm"]=="炼气" else "凡人武者",
        int(state.get("health",0)),int(state.get("max_health",0)),
        int(state.get("mana",0)),int(state.get("max_mana",0))]
    _sync_npc_status_bar(id)

func available_player_arts() -> Array[Dictionary]:
  var known: Array=player_data.get("known_arts",[])
  var result: Array[Dictionary]=[]
  for id in [ART_SPIRIT_BOLT,ART_SPIRIT_WARD]:
    result.append({
      "id":id,"name":"灵息弹" if id==ART_SPIRIT_BOLT else "护体灵障",
      "unlock_layer":1 if id==ART_SPIRIT_BOLT else 2,
      "mana_cost":4 if id==ART_SPIRIT_BOLT else 6,
      "learned":known.has(id)})
  return result

func spend_player_mana_for_art(art: String) -> Dictionary:
  # Authority validates learned power, true spirit root and the persistent
  # mana ledger. The controller checks target, LOS and cooldown BEFORE this.
  var valid: bool=art in [ART_SPIRIT_BOLT,ART_SPIRIT_WARD]
  if not valid:
    return {"ok":false,"reason":"UNKNOWN_ART"}
  if not bool(player_data.get("tested",false)) or String(
      player_data.get("root_kind",""))=="无灵根":
    return {"ok":false,"reason":"NO_SPIRIT_ROOT"}
  var required_layer: int=1 if art==ART_SPIRIT_BOLT else 2
  if int(player_data.get("layer",0))<required_layer or not (
      player_data.get("known_arts",[]) as Array).has(art):
    return {"ok":false,"reason":"ART_NOT_LEARNED"}
  var cost: int=4 if art==ART_SPIRIT_BOLT else 6
  if int(player_data.get("mana",0))<cost:
    return {"ok":false,"reason":"MANA_INSUFFICIENT","cost":cost}
  player_data["mana"]=int(player_data["mana"])-cost
  if not save_state():
    player_data["mana"]=int(player_data["mana"])+cost
    return {"ok":false,"reason":"SAVE_FAILED_REVERTED"}
  return {"ok":true,"spent":cost,"mana":int(player_data["mana"]),"art":art}

func public_player_status() -> Dictionary:
  var safe: Dictionary=player_data.duplicate(true)
  if not bool(safe.get("tested",false)):
    safe.erase("root_kind")
    safe.erase("root_weights")
  return safe

func stats() -> Dictionary:
  return {"world_seed":world_seed,
    "seed_is_persistent":FileAccess.file_exists(SAVE_PATH),
    "cultivator_count":npc_visuals.size(),
    "cultivator_identity_count":npc_data.size(),
    "physical_cultivator_colliders":npc_colliders.size(),
    "altar_is_real_licensed_stone":altar!=null,
    "root_tested":bool(player_data.get("tested",false)),
    "root_hidden_before_exam":not bool(player_data.get("tested",false)),
    "player_realm":String(player_data.get("realm","凡人")),
    "player_layer":int(player_data.get("layer",0)),
    "world_cultivation_hours":total_hours,
    "local_llm_is_loaded":_npc_ai_real_loaded,
    "npc_rules_actually_advance_with_world":true,
    "save_writes":_save_writes,"save_error":_save_error}

func save_state() -> bool:
  if world_seed<=0:
    return false
  var data: Dictionary={"schema":SCHEMA,"world_seed":world_seed,
    "player":player_data,"npcs":npc_data,
    "whole_world_cultivation_hours":total_hours}
  var json: String=JSON.stringify(data)
  var temp: String=SAVE_PATH+".tmp"
  var stream:=FileAccess.open(temp,FileAccess.WRITE)
  if stream==null:
    _save_error="CULTIVATION_STATE_WRITE_FAILED"
    return false
  stream.store_string(json)
  stream.flush()
  stream.close()
  var status: Error=DirAccess.rename_absolute(
    ProjectSettings.globalize_path(temp),ProjectSettings.globalize_path(SAVE_PATH))
  if status!=OK:
    _save_error="CULTIVATION_ATOMIC_RENAME_FAILED_"+str(status)
    return false
  _save_error=""
  _save_writes+=1
  return true
