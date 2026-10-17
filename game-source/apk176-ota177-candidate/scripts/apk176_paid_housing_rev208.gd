extends RefCounted
## 2026-10-18 P0: no material-free CC0 prefab houses. An intact licensed
## GLB is only the FINAL representation of a real finite-cost building.
## Default there are ONLY survey stake/blueprints and zero free new houses.
## Construction MUST spend the original village finite stock ledger.
const SAVE_PATH: String="user://canglan_paid_house_sites_rev208.json"
const SCHEMA: int=208
const HOUSE_WOOD: int=200
const HOUSE_STONE: int=150
const HOUSE_CAPACITY: int=5
const SITES: Array=[
  {"id":"CL-HOME-V206-001","kind":"house_1","wood":200,"stone":150,"hours":8},
  {"id":"CL-HOME-V206-002","kind":"house_2","wood":200,"stone":150,"hours":8},
  {"id":"CL-HOME-V206-003","kind":"house_3","wood":200,"stone":150,"hours":8},
  {"id":"CL-HOME-V206-004","kind":"house_4","wood":200,"stone":150,"hours":8},
  {"id":"CL-INN-V206-001","kind":"inn","wood":480,"stone":320,"hours":18},
  {"id":"CL-GAZEBO-V206-001","kind":"gazebo","wood":95,"stone":80,"hours":6}]
var sites: Dictionary={}
var build_completed: int=0
var _save_writes: int=0
var _last_error: String=""
var _loaded: bool=false

func initialize() -> bool:
  if _loaded:
    return true
  sites.clear()
  for spec in SITES:
    sites[String(spec["id"])]={
      "id":String(spec["id"]),"kind":String(spec["kind"]),
      "wood":int(spec["wood"]),"stone":int(spec["stone"]),
      "hours_required":int(spec["hours"]),
      "worked_hours":0,"paid":false,"completed":false,
      "construction_stage":"surveyed_unpaid",
      "real_resident_capacity":HOUSE_CAPACITY if String(
        spec["kind"]).begins_with("house") else (
        14 if String(spec["kind"])=="inn" else 0),
      "residents":[]}
  if FileAccess.file_exists(SAVE_PATH):
    var json: Variant=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
    if not (json is Dictionary) or int(json.get("schema",0))!=SCHEMA:
      _last_error="INVALID_BUILDING_SAVE_MUST_NOT_SPAWN_FREE"
      return false
    var old: Dictionary=json.get("sites",{})
    if not (old is Dictionary) or old.size()!=sites.size():
      _last_error="INCONSISTENT_BUILDING_SITE_COUNT"
      return false
    for id in sites:
      if not old.has(id) or not (old[id] is Dictionary):
        _last_error="MISSING_SAVED_BUILDING_ID"
        return false
      var newer: Dictionary=sites[id]
      var persisted: Dictionary=old[id]
      if String(persisted.get("kind",""))!=String(newer["kind"]):
        _last_error="CHANGED_SOURCE_LICENSED_BUILDING_KIND"
        return false
      var paid: bool=bool(persisted.get("paid",false))
      var completed: bool=bool(persisted.get("completed",false))
      var hours: int=int(persisted.get("worked_hours",0))
      if (completed and not paid) or hours<0 or (
          hours>int(newer["hours_required"])) or (
          not paid and hours>0):
        _last_error="FORGED_OR_CORRUPTED_FREE_BUILDING"
        return false
      newer["paid"]=paid
      newer["completed"]=completed
      newer["worked_hours"]=hours
      newer["construction_stage"]=(
        "occupied" if completed else (
        "paid_working" if paid else "surveyed_unpaid"))
      var residents: Variant=persisted.get("residents",[])
      if not (residents is Array) or residents.size()>int(
          newer["real_resident_capacity"]) or (
          not completed and residents.size()>0):
        _last_error="INVALID_HOUSE_OCCUPANCY_SAVE"
        return false
      newer["residents"]=residents.duplicate()
  for row in sites.values():
    if bool(row["completed"]):
      build_completed+=1
  _loaded=true
  return true

func _save() -> bool:
  if not _loaded:
    return false
  var payload: Dictionary={"schema":SCHEMA,"sites":sites}
  var stream:=FileAccess.open(SAVE_PATH+".tmp",FileAccess.WRITE)
  if stream==null:
    _last_error="PAID_HOUSE_WRITE_FAILED"
    return false
  stream.store_string(JSON.stringify(payload))
  stream.flush()
  stream.close()
  if DirAccess.rename_absolute(SAVE_PATH+".tmp",SAVE_PATH)!=OK:
    _last_error="PAID_HOUSE_ATOMIC_SAVE_FAILED"
    return false
  _save_writes+=1
  _last_error=""
  return true

func quote(id: String,stock: Dictionary={}) -> Dictionary:
  if not sites.has(id):
    return {"ok":false,"reason":"NO_REGISTERED_LICENSED_BUILDING_PLAN"}
  var s: Dictionary=sites[id]
  return {"ok":true,"id":id,"kind":s["kind"],
    "need_wood":int(s["wood"]),"need_stone":int(s["stone"]),
    "stock_wood":int(stock.get("wood",0)),"stock_stone":int(stock.get("stone",0)),
    "still_need_wood":maxi(0,int(s["wood"])-int(stock.get("wood",0))),
    "still_need_stone":maxi(0,int(s["stone"])-int(stock.get("stone",0))),
    "paid":bool(s["paid"]),"completed":bool(s["completed"]),
    "hours_completed":int(s["worked_hours"]),
    "hours_total":int(s["hours_required"]),
    "housing_capacity":int(s["real_resident_capacity"])}

func try_fund(id: String,sim: RefCounted,town: String) -> Dictionary:
  if not _loaded or not sites.has(id):
    return {"ok":false,"reason":"NO_REAL_FOUNDATION_BLUEPRINT"}
  var row: Dictionary=sites[id]
  if bool(row["paid"]):
    return {"ok":false,"reason":"ALREADY_FUNDED_ONE_TIME_ONLY"}
  if sim==null or not sim.get("villages").has(town):
    return {"ok":false,"reason":"NO_ACTUAL_VILLAGE_ECONOMY"}
  var stock: Dictionary=sim.get("villages")[town]["stock"]
  var wood: int=int(row["wood"])
  var stone: int=int(row["stone"])
  if int(stock.get("wood",0))<wood or int(stock.get("stone",0))<stone:
    var q: Dictionary=quote(id,stock)
    q["ok"]=false
    q["reason"]="MISSING_ACTUAL_WOOD_OR_STONE"
    return q
  # One authoritative atomic economic transaction; no separate UI ledger
  # invents resources or marks prefabs ready without a debit.
  if not bool(sim.call("_spend",town,{"wood":wood,"stone":stone})):
    return {"ok":false,"reason":"ORIGINAL_WORLD_STOCK_DEBIT_REFUSED"}
  row["paid"]=true
  row["construction_stage"]="paid_working"
  if not _save():
    row["paid"]=false
    row["construction_stage"]="surveyed_unpaid"
    assert(bool(sim.call("_add_stock",town,"wood",wood)))
    assert(bool(sim.call("_add_stock",town,"stone",stone)))
    return {"ok":false,"reason":"BUILD_SITE_SAVE_FAILED_LEDGER_ROLLED_BACK"}
  return {"ok":true,"id":id,"spent_wood":wood,
    "spent_stone":stone,"hours_until_house":int(row["hours_required"]),
    "finished":false,"resident_capacity":int(row["real_resident_capacity"])}

func advance_one_world_hour(workers_present: int=1) -> Array[String]:
  var arrived: Array[String]=[]
  if not _loaded or workers_present<=0:
    return arrived
  var changed: bool=false
  for id in sites:
    var row: Dictionary=sites[id]
    if not bool(row["paid"]) or bool(row["completed"]):
      continue
    row["worked_hours"]=mini(int(row["hours_required"]),
      int(row["worked_hours"])+workers_present)
    changed=true
    if int(row["worked_hours"])>=int(row["hours_required"]):
      row["completed"]=true
      row["construction_stage"]="occupied"
      build_completed+=1
      arrived.append(String(id))
  if changed and not _save():
    _last_error="CONSTRUCTION_HOURS_NOT_PERSISTED"
    # Never let unsigned, unpaid and failed-save houses show up as built:
    return []
  return arrived

func allocate_bed(id: String,person: String) -> bool:
  if not sites.has(id) or not bool(sites[id]["completed"]) or person.is_empty():
    return false
  var row: Dictionary=sites[id]
  var beds: Array=row["residents"]
  if beds.has(person):
    return true
  if beds.size()>=int(row["real_resident_capacity"]):
    return false
  beds.append(person)
  if not _save():
    beds.erase(person)
    return false
  return true

func stats() -> Dictionary:
  var paid: int=0
  var unbuilt: int=0
  var beds: int=0
  var assigned: int=0
  for row in sites.values():
    if bool(row["paid"]):
      paid+=1
    else:
      unbuilt+=1
    if bool(row["completed"]):
      beds+=int(row["real_resident_capacity"])
      assigned+=(row["residents"] as Array).size()
  return {"schema":SCHEMA,"site_count":sites.size(),
    "unpaid_blueprints":unbuilt,"paid_blueprints":paid,
    "actually_completed_houses":build_completed,
    "resident_beds_built":beds,"assigned_residents":assigned,
    "standard_house_wood":HOUSE_WOOD,"standard_house_stone":HOUSE_STONE,
    "standard_house_capacity":HOUSE_CAPACITY,
    "no_free_published_prefabs":true,"saved":_loaded,
    "last_error":_last_error,"save_writes":_save_writes}
