extends RefCounted
## Original APK176 rev183: deterministic ecological succession, with accountable
## seeds and exposed bedrock. This class does not spawn material ex nihilo.
## Long-term tectonic orogeny is separate from replenishing a quarried rock.
const MAX_PLANTED := 24
const MATURITY_HOURS := 72
const NEW_TREE_WOOD := 12
const ROCK_SUBSURFACE_UNITS := 48
const ROCK_EXPOSURE_HOURS := 48
const CONSTRUCTION_EXCLUSION_RADIUS := 10.0
const UPLIFT_METERS_PER_YEAR := 0.0031
const EROSION_METERS_PER_YEAR := 0.00145
const RIDGE_ELEVATION_LIMIT := 9000.0
const GEOLOGY_YEAR_LIMIT := 6000000.0
var economy
var village_id: String = ""
var site_position := Vector3.ZERO
var warehouse_position := Vector3.ZERO
var trees: Dictionary = {}
var stone: Dictionary = {}
var awaiting_seed_delivery: Dictionary = {}
var planted_count: int = 0
var minted_seed_events: int = 0
var new_saplings: int = 0
var exposed_from_subsoil: int = 0
var absolute_hour: int = 0
var geology_years: float = 0.0
var geological_ridge_m: float = 0.0

func setup(sim, village: String, site: Vector3, depot: Vector3) -> void:
  economy = sim
  village_id = village
  site_position = site
  warehouse_position = depot

func register_tree(id: String) -> bool:
  if not economy.natural_nodes.has(id) or trees.has(id):
    return false
  if String(economy.natural_nodes[id]["kind"]) != "tree":
    return false
  trees[id] = {"id":id, "stage":"mature", "hours":0,
    "seed_awarded":false, "planted":false,
    "position":economy.resource_positions[id]}
  return true

func register_stone(id: String) -> bool:
  if not economy.natural_nodes.has(id) or stone.has(id):
    return false
  if String(economy.natural_nodes[id]["kind"]) != "stone":
    return false
  var position: Vector3 = economy.resource_positions[id]
  stone[id] = {"id":id, "position":position, "subsurface":ROCK_SUBSURFACE_UNITS,
    "initial_subsurface":ROCK_SUBSURFACE_UNITS, "hours":0,
    "stage":"stone_pile"}
  return true

func _far_from_building(position: Vector3) -> bool:
  var delta: Vector2 = Vector2(position.x-site_position.x, position.z-site_position.z)
  var from_warehouse := Vector2(position.x-warehouse_position.x,position.z-warehouse_position.z)
  return delta.length() >= CONSTRUCTION_EXCLUSION_RADIUS and from_warehouse.length() >= 6.0

func on_tree_cut_to_zero(actor: String, id: String) -> bool:
  if not trees.has(id) or not economy.natural_nodes.has(id):
    return false
  var profile: Dictionary = trees[id]
  if bool(profile["seed_awarded"]) or int(economy.natural_nodes[id]["remaining"]) != 0:
    return false
  # Exactly one actual seed exists with the feller, awaiting warehouse delivery.
  # It is NOT yet counted in village stock. Re-cutting a stump grants nothing.
  profile["seed_awarded"] = true
  profile["stage"] = "stump"
  awaiting_seed_delivery[actor] = int(awaiting_seed_delivery.get(actor, 0)) + 1
  minted_seed_events += 1
  return true

func delivered_seed_from_actor(actor: String) -> int:
  var count: int = int(awaiting_seed_delivery.get(actor, 0))
  if count == 0:
    return 0
  if not economy._add_stock(village_id, "tree_seed", count):
    return 0
  awaiting_seed_delivery.erase(actor)
  return count

func _valid_new_tree_location(position: Vector3) -> bool:
  if not _far_from_building(position):
    return false
  for data in trees.values():
    var occupied: Vector3 = data["position"]
    if occupied.distance_to(position) < 3.2:
      return false
  return true

func plant_one_seed(position: Vector3) -> String:
  if economy == null or planted_count >= MAX_PLANTED:
    return ""
  if not _valid_new_tree_location(position):
    return ""
  if not economy._spend(village_id, {"tree_seed":1}):
    return ""
  var id: String = "CL-TREE-0183-SEED-%03d" % (planted_count + 1)
  trees[id] = {"id":id,"stage":"seed","hours":0,
    "seed_awarded":false,"planted":true,"position":position}
  planted_count += 1
  return id

func plant_first_available() -> String:
  # Auto-replant a limited number of transported seeds outside buildings.
  # No spawner is allowed to create a seed or a full grown tree for free.
  if planted_count >= MAX_PLANTED:
    return ""
  # Keep newly planted groves entirely to the LEFT of the transport road.
  # A natural grove is planted in spaced cells; each tree still comes from an
  # actually harvested and withdrawn seed, never respawned ex nihilo.
  for i in range(28):
    var p := Vector3(-29.0 + float(i%7)*2.75,0,22.5 + float(int(i/7))*3.8)
    if _valid_new_tree_location(p) and p.x <= -11.0:
      return plant_one_seed(p)
  return ""

func _stone_stage(amount: int) -> String:
  if amount <= 0:
    return "empty_surface"
  if amount <= 2:
    return "pebbles"
  if amount <= 6:
    return "small_rock"
  if amount <= 16:
    return "rock_cluster"
  return "stone_pile"

func advance_ecology_hours(hours: int = 1) -> void:
  if hours <= 0 or hours > 168:
    return
  absolute_hour += hours
  for id in trees:
    var entry: Dictionary = trees[id]
    if not bool(entry["planted"]) or String(entry["stage"]) == "mature":
      continue
    entry["hours"] = int(entry["hours"]) + hours
    var age: int = int(entry["hours"])
    if age >= MATURITY_HOURS:
      # Only on maturity is actual harvestable wood created by biological
      # growth over time. The consumed seed has been removed from inventory.
      var registered: bool = economy.register_natural_node(id, village_id, "tree", NEW_TREE_WOOD)
      if registered:
        economy.register_resource_position(id, entry["position"])
        entry["stage"] = "mature"
    elif age >= 24:
      entry["stage"] = "young_tree"
    elif age >= 6:
      entry["stage"] = "sapling"
  for id in stone:
    var profile: Dictionary = stone[id]
    var node: Dictionary = economy.natural_nodes[id]
    var position: Vector3 = profile["position"]
    # No rock recovery in constructed areas. Environmental rules govern it.
    if not _far_from_building(position) or int(profile["subsurface"]) <= 0:
      continue
    if int(node["remaining"]) >= int(node["capacity"]):
      profile["hours"] = 0
      continue
    profile["hours"] = int(profile["hours"]) + hours
    while int(profile["hours"]) >= ROCK_EXPOSURE_HOURS and int(profile["subsurface"]) > 0 and int(node["remaining"]) < int(node["capacity"]):
      profile["hours"] = int(profile["hours"]) - ROCK_EXPOSURE_HOURS
      profile["subsurface"] = int(profile["subsurface"]) - 1
      node["remaining"] = int(node["remaining"]) + 1
      node["depleted"] = false
      exposed_from_subsoil += 1
    profile["stage"] = _stone_stage(int(node["remaining"]))

func advance_geological_years(years: float, convergent_plate_boundary: bool) -> bool:
  # Ordinary loose stones cannot grow into the Himalaya. Mountain-building is
  # caused by tectonic convergence lifting CRUST; erosion counteracts uplift.
  # This state models a far-world crustal tile, never buildings or quarry loot.
  if not convergent_plate_boundary or years <= 0 or years > 1000000:
    return false
  geology_years = minf(GEOLOGY_YEAR_LIMIT, geology_years + years)
  var net_uplift: float = maxf(0.0, UPLIFT_METERS_PER_YEAR - EROSION_METERS_PER_YEAR)
  geological_ridge_m = clampf(geology_years*net_uplift,0.0,RIDGE_ELEVATION_LIMIT)
  return true

func exported_state() -> Dictionary:
  return {"schema":183,"trees":trees.duplicate(true),"stones":stone.duplicate(true),
    "seeds_carried":awaiting_seed_delivery.duplicate(true),
    "planted":planted_count,"seed_events":minted_seed_events,
    "exposed_subsurface":exposed_from_subsoil,
    "geological_years":geology_years,"ridge_elevation_m":geological_ridge_m}

func geology_summary() -> String:
  if geological_ridge_m < 10.0:
    return "地层稳定"
  if geological_ridge_m < 500.0:
    return "丘陵抬升"
  if geological_ridge_m < 2500.0:
    return "山地形成"
  if geological_ridge_m < 7000.0:
    return "高山褶皱"
  return "造山带·喜马拉雅级海拔(远景逻辑)"
