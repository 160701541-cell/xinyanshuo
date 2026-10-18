extends RefCounted
## Original APK176 source-of-truth medicinal resource ledger.
## Physical positions are immutable CC0 models in the REAL Godot world.
## New worlds naturally MATERIALIZE resource nodes at generation.
## Wild resources also randomly appear during world time and naturally renew.
## This is a WORLD ecology rule, never a free backpack/warehouse credit.
const SAVE_PATH: String="user://canglan_spirit_resources_rev206.json"
const SCHEMA: int=206
# Additive saved-world extension; the original 13 licensed nodes remain
# byte-identical and their existing inventories/conservation are preserved.
const MAX_LOCAL_HERB_NODES: int=64
const WILD_HERB_SPREAD_HOURS: int=720
const WILD_HERB_PREFIX: String="CL-WILD-LINGCAO-R207-"
# REV208: supplement original 720h seed dispersal with faster spontaneous
# habitat-constrained growth. Mineral veins can ALSO newly appear; old ore
# deposits still refill through the existing original source ledger.
const WILD_NATURAL_HERB_PREFIX: String="CL-WILD-LINGCAO-R208-"
const WILD_NATURAL_ORE_PREFIX: String="CL-WILD-LINGSHI-R208-"
const WILD_HERB_APPEAR_HOURS: int=120
const WILD_ORE_APPEAR_HOURS: int=240
const MAX_LOCAL_ORE_NODES: int=16
const REGION_COORD_LIMIT: float=42.0
const RESOURCE_DEFS: Dictionary={
  "herb_wood":{"display":"青木灵草","prefab":"flower","max":4,
    "renew_hours":18,"color":"#32b95b","mana_required":0},
  "herb_fire":{"display":"赤焰灵花","prefab":"flower2","max":3,
    "renew_hours":24,"color":"#f46331","mana_required":0},
  "herb_water":{"display":"寒露灵花","prefab":"flower3","max":3,
    "renew_hours":24,"color":"#37b4e1","mana_required":0},
  "mushroom":{"display":"凝露灵芝","prefab":"mushroom","max":2,
    "renew_hours":36,"color":"#cb79da","mana_required":0},
  "spirit_stone":{"display":"下品灵石原矿","prefab":"rock1","max":3,
    "renew_hours":96,"color":"#34e1bd","mana_required":0}}
const WORLD_POSITIONS: Array=[
  {"id":"CL-LINGCAO-W-01","kind":"herb_wood","pos":Vector2(-11.4,-12.2)},
  {"id":"CL-LINGCAO-W-02","kind":"herb_wood","pos":Vector2(-14.3,19.7)},
  {"id":"CL-LINGCAO-W-03","kind":"herb_wood","pos":Vector2(-17.2,3.2)},
  {"id":"CL-LINGCAO-F-01","kind":"herb_fire","pos":Vector2(8.4,-25.9)},
  {"id":"CL-LINGCAO-F-02","kind":"herb_fire","pos":Vector2(15.2,-30.7)},
  {"id":"CL-LINGCAO-I-01","kind":"herb_water","pos":Vector2(-20.4,25.8)},
  {"id":"CL-LINGCAO-I-02","kind":"herb_water","pos":Vector2(-25.1,31.1)},
  {"id":"CL-LINGZHI-01","kind":"mushroom","pos":Vector2(-15.2,-28.3)},
  {"id":"CL-LINGZHI-02","kind":"mushroom","pos":Vector2(-26.2,-14.5)},
  {"id":"CL-LINGSHI-01","kind":"spirit_stone","pos":Vector2(25.2,-27.5)},
  {"id":"CL-LINGSHI-02","kind":"spirit_stone","pos":Vector2(26.4,26.8)},
  {"id":"CL-LINGSHI-03","kind":"spirit_stone","pos":Vector2(18.1,34.1)},
  {"id":"CL-LINGSHI-04","kind":"spirit_stone","pos":Vector2(30.2,3.8)}]
var nodes: Dictionary={}
var world_hours: int=0
var born_total: int=0
var grown_total: int=0
var harvested_total: int=0
var _save_writes: int=0
var _last_error: String=""
var habitat_check: Callable=Callable()
var wild_random_herb_births: int=0
var wild_random_ore_births: int=0
var _loaded: bool=false

func _default_row(template: Dictionary) -> Dictionary:
  var kind: String=String(template["kind"])
  return {"id":String(template["id"]),"kind":kind,
    "remaining":int(RESOURCE_DEFS[kind]["max"]),
    "hours_since_growth":0,"x":float(template["pos"].x),
    "z":float(template["pos"].y),
    "max":int(RESOURCE_DEFS[kind]["max"])}

func initialize() -> bool:
  if _loaded:
    return true
  nodes.clear()
  born_total=0
  for template in WORLD_POSITIONS:
    var row: Dictionary=_default_row(template)
    nodes[row["id"]]=row
    born_total+=int(row["remaining"])
  if FileAccess.file_exists(SAVE_PATH):
    var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
    if not (raw is Dictionary) or int(raw.get("schema",0))!=SCHEMA:
      _last_error="SPIRIT_RESOURCES_INVALID_SAVE_PRESERVE_FILE"
      return false
    var saved: Dictionary=raw.get("nodes",{})
    if not saved is Dictionary or saved.size()<nodes.size() or (
        saved.size()>MAX_LOCAL_HERB_NODES+MAX_LOCAL_ORE_NODES):
      _last_error="SPIRIT_RESOURCES_IDENTITY_SET_MISMATCH"
      return false
    # Preserve naturally self-seeded plants across boots. Existing rev206
    # installed saves have ONLY the 13 original rows and migrate unchanged.
    for extra_id in saved:
      if nodes.has(extra_id):
        continue
      var extra: Variant=saved[extra_id]
      var id_text: String=String(extra_id)
      var born_ore: bool=id_text.begins_with(WILD_NATURAL_ORE_PREFIX)
      var born_herb: bool=id_text.begins_with(WILD_HERB_PREFIX) or (
        id_text.begins_with(WILD_NATURAL_HERB_PREFIX))
      var extra_kind: String=String(extra.get("kind","")) if extra is Dictionary else ""
      if not (born_herb or born_ore) or (
          not extra is Dictionary) or not RESOURCE_DEFS.has(extra_kind) or (
          born_ore!=(extra_kind=="spirit_stone")) or (
          absf(float(extra.get("x",999.0)))>44.0) or (
          absf(float(extra.get("z",999.0)))>44.0) or (
          int(extra.get("max",0))!=(3 if born_ore else 2)): 
        _last_error="SPIRIT_RESOURCES_INVALID_NATIVE_SPREAD_NODE"
        return false
      nodes[extra_id]={
        "id":String(extra_id),"kind":String(extra["kind"]),
        "remaining":0,"hours_since_growth":0,
        "x":float(extra["x"]),"z":float(extra["z"]),
        "max":3 if born_ore else 2}
    var total: int=0
    for id in nodes:
      if not saved.has(id) or not saved[id] is Dictionary:
        _last_error="SPIRIT_RESOURCES_NODE_MISSING"
        return false
      var loaded_node: Dictionary=saved[id]
      var default_node: Dictionary=nodes[id]
      if String(loaded_node.get("kind",""))!=String(default_node["kind"]) or (
          int(loaded_node.get("remaining",-1))<0 or (
          int(loaded_node.get("remaining",-1))>int(default_node["max"]))):
        _last_error="SPIRIT_RESOURCES_INVALID_NODE_STOCK"
        return false
      default_node["remaining"]=int(loaded_node["remaining"])
      default_node["hours_since_growth"]=clampi(
        int(loaded_node.get("hours_since_growth",0)),0,100000)
      total+=int(default_node["remaining"])
    world_hours=maxi(0,int(raw.get("world_hours",0)))
    wild_random_herb_births=maxi(0,int(raw.get("wild_random_herb_births",0)))
    wild_random_ore_births=maxi(0,int(raw.get("wild_random_ore_births",0)))
    grown_total=maxi(0,int(raw.get("grown_total",0)))
    harvested_total=maxi(0,int(raw.get("harvested_total",0)))
    if total!=born_total+grown_total-harvested_total:
      _last_error="SPIRIT_RESOURCES_SAVE_CONSERVATION_CORRUPTED"
      return false
  _loaded=true
  return true

func _save() -> bool:
  if not _loaded:
    return false
  var payload: Dictionary={
    "schema":SCHEMA,"nodes":nodes,"world_hours":world_hours,
    "born_total":born_total,"grown_total":grown_total,
    "harvested_total":harvested_total,
    "wild_random_herb_births":wild_random_herb_births,
    "wild_random_ore_births":wild_random_ore_births}
  var writer:=FileAccess.open(SAVE_PATH+".tmp",FileAccess.WRITE)
  if writer==null:
    _last_error="SPIRIT_RESOURCES_WRITE_FAILED"
    return false
  writer.store_string(JSON.stringify(payload))
  writer.flush()
  writer.close()
  if DirAccess.rename_absolute(SAVE_PATH+".tmp",SAVE_PATH)!=OK:
    _last_error="SPIRIT_RESOURCES_ATOMIC_SAVE_FAILED"
    return false
  _save_writes+=1
  _last_error=""
  return true

func get_nearest_resource(at: Vector3,reach: float=3.0) -> Dictionary:
  if not _loaded:
    return {}
  var near: Dictionary={}
  var best: float=reach
  for id in nodes:
    var row: Dictionary=nodes[id]
    if int(row["remaining"])<=0:
      continue
    var dx: float=float(row["x"])-at.x
    var dz: float=float(row["z"])-at.z
    var dist: float=sqrt(dx*dx+dz*dz)
    if dist<best:
      best=dist
      near=row
  return near.duplicate(true)

func harvest(node_id: String,bag: RefCounted) -> Dictionary:
  if not _loaded or bag==null or not nodes.has(node_id):
    return {"ok":false,"reason":"NO_REAL_NODE"}
  var row: Dictionary=nodes[node_id]
  if int(row["remaining"])<=0:
    return {"ok":false,"reason":"DEPLETED_WAIT_WORLD_REGENERATION"}
  var kind: String=String(row["kind"])
  if not bool(bag.call("can_add",kind,1)):
    return {"ok":false,"reason":"BACKPACK_FULL_CANNOT_HARVEST"}
  # First persist physically spent node stock, THEN credit finite item
  # into the real saved bag. Failure rolls back ledger; never free items.
  row["remaining"]=int(row["remaining"])-1
  harvested_total+=1
  if not _save():
    row["remaining"]=int(row["remaining"])+1
    harvested_total-=1
    return {"ok":false,"reason":"NODE_SAVE_FAILED"}
  if not bool(bag.call("_add",kind,1)):
    row["remaining"]=int(row["remaining"])+1
    harvested_total-=1
    if not _save():
      _last_error="CRITICAL_PERSISTENCE_ROLLBACK_FAILED"
    return {"ok":false,"reason":"BAG_PERSISTENCE_FAILED_ROLLED_BACK"}
  return {"ok":true,"id":node_id,"kind":kind,
    "item_name":String(RESOURCE_DEFS[kind]["display"]),
    "remaining":int(row["remaining"]),
    "source_mesh":"Quaternius-CC0",
    "refill_after_world_hours":int(RESOURCE_DEFS[kind]["renew_hours"])}

func advance_world_hour() -> void:
  if not _loaded:
    return
  world_hours+=1
  var grown_this_hour: int=0
  for id in nodes:
    var row: Dictionary=nodes[id]
    var kind: String=String(row["kind"])
    var limit: int=int(row["max"])
    if int(row["remaining"])>=limit:
      row["hours_since_growth"]=0
      continue
    row["hours_since_growth"]=int(row["hours_since_growth"])+1
    if int(row["hours_since_growth"])>=int(
        RESOURCE_DEFS[kind]["renew_hours"]):
      row["remaining"]=int(row["remaining"])+1
      row["hours_since_growth"]=0
      grown_this_hour+=1
  grown_total+=grown_this_hour
  if world_hours%WILD_HERB_SPREAD_HOURS==0:
    _spread_living_herbs()
  # Naturally appearing NEW physical resource nodes. World-time-driven,
  # deterministic per-save cycle, not an NPC-task-spawn cheat.
  if world_hours%WILD_HERB_APPEAR_HOURS==0:
    _random_world_resource_appearance(false)
  if world_hours%WILD_ORE_APPEAR_HOURS==0:
    _random_world_resource_appearance(true)
  # Explicitly record every eventful regrowth and day boundary, not every
  # rendered frame; nodes continue counting while player is elsewhere.
  if grown_this_hour>0 or world_hours%24==0:
    _save()

# Deterministic wind/pollinator spread: an actual new GLB herb appears
# only after 30 world days, in untouched soil away from reserved housing,
# central roads, current nodes and the village worksite. No free loot or
# one-click resurrection. Source plant persists when its leaves are picked.
func set_habitat_check(check: Callable) -> void:
  # Original Main passes real Terrain3D water/road/house/rock exclusion.
  habitat_check=check

func _random_world_resource_appearance(ore: bool) -> void:
  # Hard cap protects phone FPS and save size, but ecological replenishment
  # continues by old living nodes' existing periodic regeneration. Future
  # large-world regions will maintain independent capped local populations.
  var kind: String="spirit_stone"
  var existing_herbs: int=0
  var existing_ores: int=0
  for node in nodes.values():
    if String(node["kind"])=="spirit_stone":
      existing_ores+=1
    else:
      existing_herbs+=1
  if ore:
    if existing_ores>=MAX_LOCAL_ORE_NODES:
      return
  elif existing_herbs>=MAX_LOCAL_HERB_NODES:
    return
  var cycle: int=world_hours/(WILD_ORE_APPEAR_HOURS if ore else WILD_HERB_APPEAR_HOURS)
  var id: String=(WILD_NATURAL_ORE_PREFIX if ore else WILD_NATURAL_HERB_PREFIX)+(
    "%06d" % cycle)
  if nodes.has(id):
    return
  # An additional natural node initially contains real ready-to-gather units,
  # created BY WORLD GENERATION instead of being debited from an inventory.
  # The existing conservation ledger records those newly born units as growth.
  var wild_kinds: Array[String]=["herb_wood","herb_fire","herb_water","mushroom"]
  if not ore:
    kind=wild_kinds[posmod(cycle*7+3,wild_kinds.size())]
  var rng:=RandomNumberGenerator.new()
  rng.seed=int(20261018)+int(cycle)*10319+(7183 if ore else 0)
  for attempt in range(64):
    var x: float
    var z: float
    if ore:
      x=rng.randf_range(16.0,REGION_COORD_LIMIT)
      z=rng.randf_range(-REGION_COORD_LIMIT,REGION_COORD_LIMIT)
    else:
      x=rng.randf_range(-REGION_COORD_LIMIT,REGION_COORD_LIMIT)
      z=rng.randf_range(-REGION_COORD_LIMIT,REGION_COORD_LIMIT)
    if absf(x)<9.0:
      continue
    var reserved: bool=false
    for site in [
        Vector2(-7.0,-18.0),Vector2(4.8,-24.0),
        Vector2(-5.0,25.0),Vector2(4.0,31.0),
        Vector2(-6.0,-31.0),Vector2(-2.0,37.0)]:
      if Vector2(x,z).distance_to(site)<8.0:
        reserved=true
        break
    if reserved:
      continue
    var near_other: bool=false
    for other in nodes.values():
      if Vector2(x-float(other["x"]),z-float(other["z"])).length()<4.0:
        near_other=true
        break
    if near_other:
      continue
    if habitat_check.is_valid() and not bool(
        habitat_check.call(kind,x,z)):
      continue
    var fresh: int=1 if not ore else rng.randi_range(1,2)
    nodes[id]={"id":id,"kind":kind,"remaining":fresh,
      "hours_since_growth":0,"x":x,"z":z,
      "max":3 if ore else 2}
    grown_total+=fresh
    if ore:
      wild_random_ore_births+=1
    else:
      wild_random_herb_births+=1
    return

func _spread_living_herbs() -> void:
  if nodes.size()>=MAX_LOCAL_HERB_NODES:
    return
  var kinds: Array[String]=["herb_wood","herb_water","herb_fire","mushroom"]
  var cycle: int=world_hours/WILD_HERB_SPREAD_HOURS
  var chosen_kind: String=kinds[cycle%kinds.size()]
  for attempt in range(48):
    var rank: int=cycle*61+attempt*29
    var x: float=-42.0+float(posmod(rank*23+101,840))/10.0
    var z: float=-42.0+float(posmod(rank*17+479,840))/10.0
    # Roads and a 7m construction buffer around each real house blueprint.
    if absf(x)<9.0 or absf(x)>44.0 or absf(z)>44.0:
      continue
    var on_building: bool=false
    for site in [
        Vector2(-7.0,-18.0),Vector2(4.8,-24.0),
        Vector2(-5.0,25.0),Vector2(4.0,31.0),
        Vector2(-6.0,-31.0),Vector2(-2.0,37.0)]:
      if Vector2(x,z).distance_to(site)<8.0:
        on_building=true
        break
    if on_building:
      continue
    var too_close: bool=false
    for existing in nodes.values():
      if Vector2(x-float(existing["x"]),z-float(existing["z"])).length()<3.2:
        too_close=true
        break
    if too_close:
      continue
    var id: String=WILD_HERB_PREFIX+("%04d" % cycle)
    if nodes.has(id):
      return
    nodes[id]={"id":id,"kind":chosen_kind,
      "remaining":1,"hours_since_growth":0,
      "x":x,"z":z,"max":2}
    # One living newborn plant creates one biological unit by actual growth
    # over 720h, not by a player tapping an empty inventory button.
    grown_total+=1
    return

func conservation_ok() -> bool:
  if not _loaded:
    return false
  var left: int=0
  for row in nodes.values():
    left+=int(row["remaining"])
    if int(row["remaining"])<0 or int(row["remaining"])>int(row["max"]):
      return false
  return left+harvested_total==born_total+grown_total

func stats() -> Dictionary:
  var alive: int=0
  var herb_count: int=0
  var stone_count: int=0
  for row in nodes.values():
    if int(row["remaining"])>0:
      alive+=1
    if String(row["kind"])=="spirit_stone":
      stone_count+=int(row["remaining"])
    else:
      herb_count+=int(row["remaining"])
  return {"schema":SCHEMA,"resource_nodes":nodes.size(),
    "active_nodes":alive,"live_herbs_units":herb_count,
    "live_spirit_stone_units":stone_count,"world_hours":world_hours,
    "initial_units":born_total,"renewed_units":grown_total,
    "harvested_units":harvested_total,"conserved":conservation_ok(),
    "rev208_naturally_appeared_herb_nodes":wild_random_herb_births,
    "rev208_naturally_appeared_ore_nodes":wild_random_ore_births,
    "source_license":"Quaternius-CC0","save_writes":_save_writes,
    "loaded":_loaded,"last_error":_last_error}
