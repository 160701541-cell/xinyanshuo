extends RefCounted
## rev205 original APK176 multi-stack personal backpack. Never materializes
## a free resource. A harvested physical-world cargo is moved atomically from
## the finite sim ledger to this persistent bag; crafting consumes real stacks.
const SAVE_PATH: String="user://canglan_player_backpack_rev205.json"
const MAX_SLOTS: int=24
const MAX_STACK: int=999
const RECIPES: Dictionary={
  "rough_wood_sword":{"cost":{"wood":3},"slot":"weapon","name":"粗木剑"},
  "stone_pick":{"cost":{"wood":2,"stone":2},"slot":"tool","name":"石镐"},
}
const NAMES: Dictionary={
  "wood":"原木","stone":"石块","clay":"黏土","grain":"粮食",
  "topsoil":"泥土","sand":"细沙","bedrock":"基岩碎片",
  "herb":"草药","spirit_stone":"灵石",
  "rough_wood_sword":"粗木剑","stone_pick":"石镐",
}
var items: Dictionary={}
var equipment: Dictionary={"weapon":"","tool":"","armor":"","ring":""}
var last_error: String=""
var save_count: int=0

func _init() -> void:
  load_state()

func load_state() -> bool:
  if not FileAccess.file_exists(SAVE_PATH):
    return true
  var json: Variant=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
  if not (json is Dictionary) or int(json.get("schema",0))!=1:
    last_error="BAD_BACKPACK_SAVE"
    return false
  var persisted: Dictionary=json.get("items",{})
  if not (persisted is Dictionary) or persisted.size()>MAX_SLOTS:
    last_error="BAD_BACKPACK_SLOTS"
    return false
  for key in persisted:
    if int(persisted[key])<0 or int(persisted[key])>MAX_STACK:
      last_error="INVALID_ITEM_STACK"
      return false
  var loaded_equipment: Dictionary=json.get("equipment",{})
  if not (loaded_equipment is Dictionary):
    return false
  items=persisted.duplicate(true)
  for slot in equipment:
    var kind: String=String(loaded_equipment.get(slot,""))
    if kind=="" or (RECIPES.has(kind) and String(RECIPES[kind]["slot"])==slot):
      equipment[slot]=kind
  return true

func _save() -> bool:
  var payload: Dictionary={"schema":1,"items":items,"equipment":equipment}
  var writer: FileAccess=FileAccess.open(SAVE_PATH+".tmp",FileAccess.WRITE)
  if writer==null:
    last_error="BACKPACK_WRITE_FAILED"
    return false
  writer.store_string(JSON.stringify(payload))
  writer.flush()
  writer.close()
  var err: Error=DirAccess.rename_absolute(SAVE_PATH+".tmp",SAVE_PATH)
  if err!=OK:
    last_error="BACKPACK_ATOMIC_SAVE_FAILED_"+str(err)
    return false
  save_count+=1
  last_error=""
  return true

func display_name(kind: String) -> String:
  return String(NAMES.get(kind,kind))

func amount(kind: String) -> int:
  return int(items.get(kind,0))

func can_add(kind: String,count: int=1) -> bool:
  if kind.is_empty() or count<=0:
    return false
  return amount(kind)+count<=MAX_STACK and (
    items.has(kind) or items.size()<MAX_SLOTS)

func _add(kind: String,count: int) -> bool:
  if not can_add(kind,count):
    return false
  var old: Dictionary=items.duplicate(true)
  items[kind]=amount(kind)+count
  if not _save():
    items=old
    return false
  return true

func absorb_carried(sim: RefCounted,actor_id: String) -> Dictionary:
  var carried: Dictionary=sim.get("carried_by_actor")
  if not carried.has(actor_id):
    return {"ok":false,"reason":"NOT_CARRYING"}
  var load: Dictionary=carried[actor_id]
  var kind: String=String(load.get("kind",""))
  var count: int=int(load.get("amount",0))
  if not _add(kind,count):
    return {"ok":false,"reason":last_error if last_error!="" else "BAG_FULL"}
  # No duplicate in the village depot: inventory OR carry, never both.
  carried.erase(actor_id)
  return {"ok":true,"kind":kind,"amount":count}

func deposit_at_warehouse(sim: RefCounted,actor_id: String) -> Dictionary:
  if not sim.get("citizens").has(actor_id):
    return {"ok":false,"reason":"CITIZEN_NOT_FOUND"}
  var citizen: Dictionary=sim.get("citizens")[actor_id]
  var town_id: String=String(citizen["village_id"])
  var stock: Dictionary=sim.get("villages")[town_id]["stock"]
  var transferable: Dictionary={}
  for kind in items:
    if stock.has(kind) and int(items[kind])>0:
      transferable[kind]=int(items[kind])
  if transferable.is_empty():
    return {"ok":false,"reason":"NO_DEPOT_COMPATIBLE_RESOURCES"}
  var previous: Dictionary=items.duplicate(true)
  for kind in transferable:
    items.erase(kind)
  if not _save():
    items=previous
    return {"ok":false,"reason":last_error}
  # Exact-value transfer into the original economy ledger after persistence.
  # The simulator defines a finite stock and cannot accept unknown types.
  for kind in transferable:
    assert(sim.call("_add_stock",town_id,kind,int(transferable[kind])))
  return {"ok":true,"deposited":transferable}

func craft(recipe_id: String) -> Dictionary:
  if not RECIPES.has(recipe_id):
    return {"ok":false,"reason":"NO_RECIPE"}
  var recipe: Dictionary=RECIPES[recipe_id]
  var cost: Dictionary=recipe["cost"]
  for kind in cost:
    if amount(kind)<int(cost[kind]):
      return {"ok":false,"reason":"MISSING_"+String(kind)}
  if not can_add(recipe_id,1):
    return {"ok":false,"reason":"BAG_FULL"}
  var old: Dictionary=items.duplicate(true)
  for kind in cost:
    items[kind]=amount(kind)-int(cost[kind])
    if int(items[kind])==0:
      items.erase(kind)
  items[recipe_id]=amount(recipe_id)+1
  if not _save():
    items=old
    return {"ok":false,"reason":last_error}
  return {"ok":true,"recipe":recipe_id,"spent":cost}

func equip(kind: String) -> Dictionary:
  if not RECIPES.has(kind) or amount(kind)<=0:
    return {"ok":false,"reason":"NO_CRAFTED_GEAR_IN_BAG"}
  var slot: String=String(RECIPES[kind]["slot"])
  var old: Dictionary=equipment.duplicate(true)
  equipment[slot]=kind
  if not _save():
    equipment=old
    return {"ok":false,"reason":last_error}
  return {"ok":true,"slot":slot,"item":kind}

func unequip(slot: String) -> bool:
  if not equipment.has(slot):
    return false
  var previous: Dictionary=equipment.duplicate(true)
  equipment[slot]=""
  if not _save():
    equipment=previous
    return false
  return true

func describe() -> String:
  var lines: Array[String]=[]
  lines.append("随身背包 %d/%d格 · 真物资账本" % [items.size(),MAX_SLOTS])
  if items.is_empty():
    lines.append("空：靠近树木/石矿采集，材料将进入背包。")
  else:
    var keys: Array=items.keys()
    keys.sort()
    for kind in keys:
      lines.append("%s ×%d" % [String(NAMES.get(kind,kind)),int(items[kind])])
  lines.append("装备：武器%s / 工具%s / 防具%s / 饰品%s" % [
    String(NAMES.get(String(equipment["weapon"]),"无")) if equipment["weapon"]!="" else "无",
    String(NAMES.get(String(equipment["tool"]),"无")) if equipment["tool"]!="" else "无",
    String(NAMES.get(String(equipment["armor"]),"无")) if equipment["armor"]!="" else "无",
    String(NAMES.get(String(equipment["ring"]),"无")) if equipment["ring"]!="" else "无"])
  lines.append("图纸：粗木剑（3木） / 石镐（2木+2石）")
  return "\n".join(lines)

func snapshot() -> Dictionary:
  return {"schema":1,"items":items.duplicate(true),
    "equipment":equipment.duplicate(true),"save_count":save_count,
    "last_error":last_error}
