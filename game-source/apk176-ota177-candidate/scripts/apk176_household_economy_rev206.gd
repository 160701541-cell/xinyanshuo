extends RefCounted
## Real ancestral-home construction ledger in the ORIGINAL APK176 world.
## Only verified licensed Chinese architectural GLBs are accepted as houses;
## foreign "medieval house_1" meshes CANNOT be passed off as xianxia homes.
## A site becomes a built/occupied home only after finite stock 200/150
## was taken from the authoritative old town economy and WORLD time passed.
const SCHEMA: int=206
const SAVE_PATH: String="user://canglan_household_rev206.json"
const REQUIRED_WOOD: int=200
const REQUIRED_STONE: int=150
const CAPACITY: int=5
const BUILD_HOURS: int=3
const SITES: Dictionary={
  "CL-XIANJIA-ZHAI-01":{"position":[-24.0,-17.0],"prefab":"ancestral_house"},
  "CL-XIANJIA-ZHAI-02":{"position":[-25.0,16.0],"prefab":"ancestral_house"},
  "CL-XIANJIA-ZHAI-03":{"position":[24.0,-22.0],"prefab":"ancestral_house"},
  "CL-XIANJIA-ZHAI-04":{"position":[25.0,21.0],"prefab":"ancestral_house"}}
var houses: Dictionary={}
var _clock_hour: int=0
var _save_writes: int=0
var error: String=""

func initialize() -> bool:
  if not FileAccess.file_exists(SAVE_PATH):
    return true
  var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
  if not (raw is Dictionary) or int(raw.get("schema",0))!=SCHEMA:
    error="BAD_HOUSING_SAVE_SCHEMA"
    return false
  var loaded: Dictionary=raw.get("houses",{})
  if loaded.size()>SITES.size():
    error="OVERSIZED_HOUSING_SAVE"
    return false
  for code in loaded:
    if not SITES.has(code):
      error="UNKNOWN_HOUSING_SITE"
      return false
    var record: Dictionary=loaded[code]
    if record.get("phase","") not in ["building","complete"]:
      error="INVALID_HOUSE_PHASE"
      return false
    if int(record.get("paid_wood",-1))!=REQUIRED_WOOD or int(
        record.get("paid_stone",-1))!=REQUIRED_STONE:
      error="FREE_HOUSE_EXPLOIT_BLOCKED"
      return false
    if (record.get("residents",[]) as Array).size()>CAPACITY:
      error="OVERFILLED_HOUSE"
      return false
  houses=loaded.duplicate(true)
  _clock_hour=maxi(0,int(raw.get("clock_hour",0)))
  return true

func _save() -> bool:
  var payload: Dictionary={"schema":SCHEMA,"houses":houses,
    "clock_hour":_clock_hour}
  var tmp: String=SAVE_PATH+".tmp"
  var file:=FileAccess.open(tmp,FileAccess.WRITE)
  if file==null:
    error="HOUSE_WRITE_FAILED"
    return false
  file.store_string(JSON.stringify(payload))
  file.flush()
  file.close()
  var err: Error=DirAccess.rename_absolute(tmp,SAVE_PATH)
  if err!=OK:
    error="HOUSE_ATOMIC_RENAME_FAILED"
    return false
  _save_writes+=1
  error=""
  return true

func affordable(stock: Dictionary) -> bool:
  return int(stock.get("wood",0))>=REQUIRED_WOOD and int(
    stock.get("stone",0))>=REQUIRED_STONE

func get_next_site() -> String:
  var available: Array=SITES.keys()
  available.sort()
  for site in available:
    if not houses.has(site):
      return String(site)
  return ""

func start(site: String,town: RefCounted,village_id: String,
    prefab_ready: bool) -> Dictionary:
  if not SITES.has(site) or houses.has(site):
    return {"ok":false,"reason":"SITE_OCCUPIED_OR_INVALID"}
  if town==null or not town.get("villages").has(village_id):
    return {"ok":false,"reason":"NO_VILLAGE"}
  if not prefab_ready:
    return {"ok":false,"reason":"LICENSED_CHINESE_HOUSE_MESH_NOT_VERIFIED"}
  var stock: Dictionary=town.get("villages")[village_id]["stock"]
  if not affordable(stock):
    return {"ok":false,"reason":"NOT_ENOUGH_REAL_WOOD_STONE",
      "have_wood":int(stock.get("wood",0)),
      "have_stone":int(stock.get("stone",0)),
      "need_wood":REQUIRED_WOOD,"need_stone":REQUIRED_STONE}
  # One authoritative sim transaction, 200 logs and 150 mined stones.
  if not bool(town.call("request_construction",village_id,"home")):
    return {"ok":false,"reason":"WAREHOUSE_DEBIT_FAILED"}
  houses[site]={"site":site,"phase":"building",
    "paid_wood":REQUIRED_WOOD,"paid_stone":REQUIRED_STONE,
    "hours_remaining":BUILD_HOURS,"capacity":CAPACITY,
    "residents":[],"prefab":String(SITES[site]["prefab"]),
    "entry_enabled":false,"started_at_hour":_clock_hour}
  if not _save():
    houses.erase(site)
    # Strict no-charge-on-failed-ledger write; refund the same warehouse.
    town.call("_add_stock",village_id,"wood",REQUIRED_WOOD)
    town.call("_add_stock",village_id,"stone",REQUIRED_STONE)
    town.get("villages")[village_id]["construction"]["home"]=maxi(0,int(
      town.get("villages")[village_id]["construction"].get("home",0))-1)
    return {"ok":false,"reason":"HOUSE_SAVE_FAILED_REFUNDED"}
  return {"ok":true,"site":site,"phase":"building",
    "materials_spent":{"wood":REQUIRED_WOOD,"stone":REQUIRED_STONE},
    "hours_remaining":BUILD_HOURS}

func advance_world_hour() -> Array[String]:
  # One tick per real world hour: offline speed-up still pays actual hours.
  _clock_hour+=1
  var completed: Array[String]=[]
  for code in houses:
    var row: Dictionary=houses[code]
    if row["phase"]!="building":
      continue
    row["hours_remaining"]=maxi(0,int(row["hours_remaining"])-1)
    if int(row["hours_remaining"])==0:
      row["phase"]="complete"
      row["entry_enabled"]=true
      completed.append(String(code))
  if not _save():
    # Callers must not spawn architecture from unsaved paid records.
    error="HOUSING_WORLD_TICK_PERSIST_FAILED"
    return []
  return completed

func assign_resident(site: String,entity_id: String) -> Dictionary:
  if not houses.has(site) or entity_id.is_empty():
    return {"ok":false,"reason":"HOME_UNAVAILABLE"}
  var row: Dictionary=houses[site]
  if String(row["phase"])!="complete":
    return {"ok":false,"reason":"HOME_NOT_BUILT"}
  for home in houses.values():
    if (home.get("residents",[]) as Array).has(entity_id):
      return {"ok":false,"reason":"RESIDENT_ALREADY_ASSIGNED"}
  var residents: Array=row["residents"]
  if residents.size()>=CAPACITY:
    return {"ok":false,"reason":"HOUSE_5_PERSON_CAP"}
  residents.append(entity_id)
  if not _save():
    residents.erase(entity_id)
    return {"ok":false,"reason":"ASSIGNMENT_SAVE_FAILED"}
  return {"ok":true,"site":site,"occupants":residents.size(),
    "max_occupants":CAPACITY}

func stats() -> Dictionary:
  var ready: int=0
  var under_construction: int=0
  var sheltered: int=0
  for house in houses.values():
    if house["phase"]=="complete":
      ready+=1
      sheltered+=(house.get("residents",[]) as Array).size()
    else:
      under_construction+=1
  return {"schema":SCHEMA,"build_wood":REQUIRED_WOOD,
    "build_stone":REQUIRED_STONE,"residents_per_house":CAPACITY,
    "houses_finished":ready,"sites_pending":under_construction,
    "housing_capacity":ready*CAPACITY,
    "residents_assigned":sheltered,"no_house_without_material":true,
    "prefab_style_must_be_chinese":true,
    "save_writes":_save_writes,"entries":houses.duplicate(true)}
