extends RefCounted
## REV208: Natural trees and ordinary stone OUTCROPS are born by the WORLD.
## Spawned nodes go through the existing authoritative Economy/ Ecological
## registers, NEVER directly to NPC/player bags or village stock.
## Separate additive save: original 52 trees / 20 stones and their IDs stay.
const SCHEMA: int=208
const DEFAULT_SAVE: String="user://canglan_natural_births_rev208.json"
const TREE_PERIOD: int=120
const STONE_PERIOD: int=240
const MAX_LOCAL_NEW_TREES: int=20
const MAX_LOCAL_NEW_STONES: int=10
const TREE_ID_PREFIX: String="CL-WILD-TREE-R208-"
const STONE_ID_PREFIX: String="CL-WILD-STONE-R208-"
var save_path: String=DEFAULT_SAVE
var world_seed: int=20261018
var world_hours: int=0
var records: Dictionary={}
var spawn_tree_events: int=0
var spawn_stone_events: int=0
var _economy: RefCounted
var _ecology: RefCounted
var _terrain: Node3D
var _quality: RefCounted
var _houses: Dictionary={}
var _spiritual_resources: RefCounted
var _loaded: bool=false
var last_error: String=""

func initialize(economy: RefCounted,ecology: RefCounted,
    terrain: Node3D,quality: RefCounted,houses: Dictionary,
    spirit: RefCounted) -> bool:
  if _loaded:
    return true
  _economy=economy
  _ecology=ecology
  _terrain=terrain
  _quality=quality
  _houses=houses
  _spiritual_resources=spirit
  if _economy==null or _ecology==null or _terrain==null or _quality==null:
    last_error="REV208_NATURAL_BIRTH_NO_REAL_WORLD_DEPENDENCIES"
    return false
  if FileAccess.file_exists(save_path):
    var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(save_path))
    if not parsed is Dictionary or int(parsed.get("schema",0))!=SCHEMA:
      last_error="REV208_NATURAL_BIRTH_SAVE_INVALID_PRESERVE_ORIGINAL"
      return false
    var saved: Variant=parsed.get("records",{})
    if not saved is Dictionary or saved.size()>MAX_LOCAL_NEW_TREES+MAX_LOCAL_NEW_STONES:
      last_error="REV208_NATURAL_BIRTH_TOO_MANY_SAVED_NODES"
      return false
    var expected_trees: int=0
    var expected_stones: int=0
    for id in saved:
      var entry: Variant=saved[id]
      var role: String=String(entry.get("kind","")) if entry is Dictionary else ""
      if not entry is Dictionary or (
          not _valid_record(String(id),entry)):
        last_error="REV208_NATURAL_BIRTH_UNTRUSTED_SAVED_NODE_"+String(id)
        return false
      if role=="tree":
        expected_trees+=1
      else:
        expected_stones+=1
    if expected_trees>MAX_LOCAL_NEW_TREES or expected_stones>MAX_LOCAL_NEW_STONES:
      last_error="REV208_NATURAL_BIRTH_SAVED_SPECIES_OVER_CAP"
      return false
    world_hours=clampi(int(parsed.get("world_hours",0)),0,2000000000)
    world_seed=int(parsed.get("world_seed",world_seed))
    records=saved.duplicate(true)
    spawn_tree_events=expected_trees
    spawn_stone_events=expected_stones
    for id in records:
      if not _register_saved_record(String(id),records[id]):
        last_error="REV208_NATURAL_BIRTH_CANNOT_REGISTER_SAVED_"+String(id)
        return false
  _loaded=true
  return true

func _valid_record(id: String,row: Dictionary) -> bool:
  var kind: String=String(row.get("kind",""))
  if kind=="tree":
    if not id.begins_with(TREE_ID_PREFIX):
      return false
  elif kind=="stone":
    if not id.begins_with(STONE_ID_PREFIX):
      return false
  else:
    return false
  var x: float=float(row.get("x",1000.0))
  var z: float=float(row.get("z",1000.0))
  var max_units: int=int(row.get("capacity",0))
  var remaining: int=int(row.get("remaining",-1))
  return absf(x)<=42.5 and absf(z)<=42.5 and (
    (x<=-11.0 and kind=="tree") or (x>=12.0 and kind=="stone")) and (
    max_units>=2 and max_units<=16 and remaining>=0 and remaining<=max_units)

# Only rollback resources created by THIS rev208 world spawner. Never erase
# one of the 52 historic trees, 20 stone veins, village inventory or a
# separate agent's content. Called before public birth notification/render.
func _rollback_uncommitted_wild_node(id: String,kind: String) -> void:
  if kind=="tree" and not id.begins_with(TREE_ID_PREFIX):
    return
  if kind=="stone" and not id.begins_with(STONE_ID_PREFIX):
    return
  if kind not in ["tree","stone"]:
    return
  records.erase(id)
  if _ecology!=null:
    if kind=="tree":
      _ecology.trees.erase(id)
    else:
      _ecology.stone.erase(id)
  if _economy!=null:
    _economy.resource_positions.erase(id)
    _economy.natural_nodes.erase(id)

func _register_saved_record(id: String,row: Dictionary) -> bool:
  if _economy.natural_nodes.has(id):
    return false
  var kind: String=String(row["kind"])
  var position:=Vector3(float(row["x"]),float(
    _terrain.call("height_at",float(row["x"]),float(row["z"]))),
    float(row["z"]))
  var created: bool=bool(_economy.register_natural_node(
    id,"CL-REV186-HX-VILLAGE",kind,int(row["capacity"])))
  if not created:
    return false
  if not bool(_economy.register_resource_position(id,position)):
    _economy.natural_nodes.erase(id)
    return false
  var ecological: bool=bool(_ecology.register_tree(id)) if kind=="tree" else (
    bool(_ecology.register_stone(id)))
  if not ecological:
    _economy.resource_positions.erase(id)
    _economy.natural_nodes.erase(id)
    return false
  var original: Dictionary=_economy.natural_nodes[id]
  original["remaining"]=int(row["remaining"])
  original["depleted"]=int(row["remaining"])==0
  # Wild trees regenerate on ecological time, rather than disappearing
  # forever on the first cut. Ordinary geology exposes new stone over time.
  var interval: int=72 if kind=="tree" else 240
  if not bool(_economy.configure_resource_recovery(
      id,int(row["capacity"]),1,interval,48 if kind=="tree" else 120)):
    # The economy node and ecology tree/stone had already been registered.
    # Previous code returned false without undoing either, creating an
    # invisible but harvestable ghost ID on a rejected recovery profile.
    _rollback_uncommitted_wild_node(id,kind)
    last_error="REV208_WILD_RECOVERY_REJECTED_AND_ROLLED_BACK_"+id
    return false
  original["next_regen_hour"]=int(row.get("next_regen_hour",-1))
  return true

func _possible(kind: String,x: float,z: float) -> bool:
  if not bool(_quality.call("_natural_plantable",x,z)):
    return false
  var pos:=Vector2(x,z)
  for house in _houses.values():
    var origin: Vector3=house["at"]
    if pos.distance_to(Vector2(origin.x,origin.z))<7.2:
      return false
  for field in _economy.resource_positions.values():
    var occupied: Vector3=field
    if pos.distance_to(Vector2(occupied.x,occupied.z))<(
        3.5 if kind=="tree" else 3.0):
      return false
  if _spiritual_resources!=null:
    for herb in (_spiritual_resources.get("nodes") as Dictionary).values():
      if pos.distance_to(Vector2(float(herb["x"]),float(herb["z"])))<2.2:
        return false
  return true

func _birth(kind: String) -> String:
  var existing_count: int=0
  for row in records.values():
    if String(row["kind"])==kind:
      existing_count+=1
  if existing_count>=(
      MAX_LOCAL_NEW_TREES if kind=="tree" else MAX_LOCAL_NEW_STONES):
    return ""
  var cycle: int=world_hours/(TREE_PERIOD if kind=="tree" else STONE_PERIOD)
  var id: String=(TREE_ID_PREFIX if kind=="tree" else STONE_ID_PREFIX)+(
    "%06d" % cycle)
  if records.has(id) or _economy.natural_nodes.has(id):
    return ""
  var rng:=RandomNumberGenerator.new()
  rng.seed=world_seed+cycle*18373+(2701 if kind=="tree" else 8123)
  for attempt in range(80):
    var x: float=rng.randf_range(-41.8,-11.3) if kind=="tree" else (
      rng.randf_range(12.3,41.8))
    var z: float=rng.randf_range(-41.8,41.8)
    if not _possible(kind,x,z):
      continue
    var size: int=rng.randi_range(3,8) if kind=="tree" else (
      rng.randi_range(4,12))
    var row: Dictionary={"kind":kind,"x":x,"z":z,
      "capacity":size,"remaining":size,"next_regen_hour":-1}
    if not _register_saved_record(id,row):
      last_error="REV208_NATURAL_BIRTH_REGISTER_FAILED_"+id
      return ""
    records[id]=row
    if kind=="tree":
      spawn_tree_events+=1
    else:
      spawn_stone_events+=1
    if not save_state():
      # Atomicity invariant: no ecological or gatherable node may become
      # player-visible until its unique ID and starting quantity survive
      # a real disk write. Without rollback, Android force-close after
      # gathering could reappear as new stock or orphaned harvest state.
      var previous_save_error: String=last_error
      _rollback_uncommitted_wild_node(id,kind)
      if kind=="tree":
        spawn_tree_events=maxi(0,spawn_tree_events-1)
      else:
        spawn_stone_events=maxi(0,spawn_stone_events-1)
      last_error="REV208_NATURAL_BIRTH_NOT_PERSISTED_ROLLED_BACK_"+id+(
        "_"+previous_save_error)
      return ""
    return id
  return ""

func advance_world_hour() -> Array[String]:
  var born: Array[String]=[]
  if not _loaded:
    return born
  world_hours+=1
  if world_hours%TREE_PERIOD==0:
    var new_tree: String=_birth("tree")
    if not new_tree.is_empty():
      born.append(new_tree)
  if world_hours%STONE_PERIOD==0:
    var new_stone: String=_birth("stone")
    if not new_stone.is_empty():
      born.append(new_stone)
  if world_hours%24==0:
    save_state()
  return born

func save_state() -> bool:
  if not _loaded:
    return false
  # Prepare a separate snapshot: failed writes MUST NOT acknowledge a
  # harvested quantity as durable. Otherwise save_if_authoritative_amount_changed
  # would stop retrying and Android force-close could duplicate harvested loot.
  var candidate_records: Dictionary=records.duplicate(true)
  for id in candidate_records:
    if not _economy.natural_nodes.has(id):
      last_error="REV208_NATURAL_BIRTH_AUTHORITATIVE_ID_LOST_"+String(id)
      return false
    var row: Dictionary=candidate_records[id]
    var economy_row: Dictionary=_economy.natural_nodes[id]
    row["remaining"]=int(economy_row["remaining"])
    row["next_regen_hour"]=int(economy_row.get("next_regen_hour",-1))
  var save: Dictionary={"schema":SCHEMA,"world_seed":world_seed,
    "world_hours":world_hours,"records":candidate_records}
  var output:=FileAccess.open(save_path+".tmp",FileAccess.WRITE)
  if output==null:
    last_error="REV208_NATURAL_BIRTH_CANNOT_WRITE_FILE"
    return false
  output.store_string(JSON.stringify(save))
  output.flush()
  output.close()
  if DirAccess.rename_absolute(save_path+".tmp",save_path)!=OK:
    last_error="REV208_NATURAL_BIRTH_CANNOT_ATOMICALLY_COMMIT"
    return false
  # Commit the in-memory saved baseline only AFTER the atomic rename.
  records=candidate_records
  last_error=""
  return true

func save_if_authoritative_amount_changed() -> bool:
  # A player can close the Android app just after harvesting a randomly
  # appeared tree. Persist promptly instead of silently resurrecting loot
  # from the previous day's save. This does NO writes if nothing changed.
  if not _loaded:
    return false
  for id in records:
    if not _economy.natural_nodes.has(id):
      last_error="REV208_AUTHORITY_NODE_DISAPPEARED_BEFORE_SAVE"
      return false
    var saved: Dictionary=records[id]
    var real: Dictionary=_economy.natural_nodes[id]
    if int(saved["remaining"])!=int(real["remaining"]) or (
        int(saved.get("next_regen_hour",-1))!=int(
          real.get("next_regen_hour",-1))):
      return save_state()
  return true

func stats() -> Dictionary:
  return {"loaded":_loaded,"world_hours":world_hours,
    "source_generated_trees":spawn_tree_events,
    "source_generated_stones":spawn_stone_events,
    "wild_nodes":records.size(),
    "physical_source_models_required":true,
    "inventory_credited_directly":false,
    "save_path":save_path,"last_error":last_error}
