extends RefCounted
## Original APK176 source-of-truth medicinal resource ledger.
## Physical positions are immutable CC0 models in the REAL Godot world.
## Nothing from "herb" or "spirit_stone" materializes on button click.
## Minable finite 3D ore and living herbs regenerate from WORLD TIME alone.
const SAVE_PATH: String="user://canglan_spirit_resources_rev206.json"
const SCHEMA: int=206
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
    if not (saved is Dictionary) or saved.size()!=nodes.size():
      _last_error="SPIRIT_RESOURCES_IDENTITY_SET_MISMATCH"
      return false
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
    "harvested_total":harvested_total}
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
    var limit: int=int(RESOURCE_DEFS[kind]["max"])
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
  # Explicitly record every eventful regrowth and day boundary, not every
  # rendered frame; nodes continue counting while player is elsewhere.
  if grown_this_hour>0 or world_hours%24==0:
    _save()

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
    "source_license":"Quaternius-CC0","save_writes":_save_writes,
    "loaded":_loaded,"last_error":_last_error}
