extends RefCounted
## rev206: one CITY has 10,000..250,000 mortal residents. "Mortal" means
## not yet cultivated, not "no spirit root". Aggregate cohorts are NOT
## hundreds of thousands of rendered or ticking Godot nodes.
const SCHEMA: int=206
const MIN_CITY_POPULATION: int=10000
const MAX_CITY_POPULATION: int=250000
const DAYS_PER_YEAR: int=360
var cities: Dictionary={}
var notable_npcs: Dictionary={}
var root_catalog: RefCounted
var current_day: int=1
var report_count: int=0
var spawned_visual_nodes: int=0

func initialize(catalog: RefCounted) -> bool:
  if catalog==null:
    return false
  root_catalog=catalog
  return true

func create_city(city_id: String,world_seed: int,
    requested_population: int) -> Dictionary:
  if root_catalog==null or city_id=="" or cities.has(city_id) or (
      requested_population<MIN_CITY_POPULATION or
      requested_population>MAX_CITY_POPULATION):
    return {"ok":false,"reason":"INVALID_CITY_POPULATION_OR_ID"}
  var rng:=RandomNumberGenerator.new()
  rng.seed=(world_seed+String(city_id).hash())&0x7fffffff
  var count: int=requested_population
  # Only family/occupation/count data per district is persisted. Social
  # caste is not conflated with spiritual ability or ancestry.
  var districts: Dictionary={
    "inner_wards":int(count*0.18),"markets":int(count*0.22),
    "crafts":int(count*0.16),"farms":int(count*0.34)}
  districts["suburbs"]=count-(int(districts["inner_wards"])+
    int(districts["markets"])+int(districts["crafts"])+
    int(districts["farms"]))
  var recruitable: int=roundi(float(count)*0.012)
  var cohorts: Dictionary={
    "children":int(count*0.24),
    "adults":int(count*0.57),
    "elders":0}
  cohorts["elders"]=count-int(cohorts["children"])-int(cohorts["adults"])
  cities[city_id]={
    "city_id":city_id,"schema":SCHEMA,"seed":world_seed,
    "population":count,"mortal_population":count,
    "districts":districts,"age_cohorts":cohorts,
    "recruitable_labor_pool":recruitable,
    "bonded_labor_population":0,"labor_without_root_count":0,
    "ordinary_people_all_have_roots":true,
    "annual_taxation_units":count*3,"food_requirement_per_day":count,
    "housing_capacity":maxi(count,count+rng.randi_range(200,1800)),
    "markets":maxi(1,count/4500),"temple_courtyards":maxi(1,count/18000),
    "cohort_day":current_day,"born_total":0,"died_total":0,
    "migrated_total":0,"residents_simulated_only":count,
    "live_physical_scene_nodes":0,
    "known_named_npc_ids":[]}
  return {"ok":true,"city_id":city_id,"population":count,
    "instantiated_npcs":0}

func register_named_person(city_id: String,entity_id: String,
    role: String="merchant") -> Dictionary:
  if root_catalog==null or not cities.has(city_id) or (
      entity_id=="" or notable_npcs.has(entity_id)):
    return {"ok":false,"reason":"INVALID_PERSON_OR_CITY"}
  var city: Dictionary=cities[city_id]
  var actual_role: String=role
  var permitted_exception: bool=role in [
    "bonded_labor","enslaved_labor","recruitable_servant"]
  var status: Dictionary=root_catalog.call("generate",
    int(city["seed"]),entity_id,actual_role)
  # Normal NPCs and the player do not ever roll 'no root'.
  if not permitted_exception and not bool(status.get("has_root",false)):
    return {"ok":false,"reason":"NORMAL_CHARACTER_ROOT_MISSING"}
  var person: Dictionary={
    "id":entity_id,"city_id":city_id,"role":role,
    "is_named":true,"root":status,"realm":"凡人",
    "cultivation_layer":0,"occupation":role,
    "recruitable":permitted_exception,"working":true,
    "stamina":100,"hunger":0,"health":100,
    "rights_status":"bonded" if permitted_exception else "ordinary",
    "bonded_recruitment_consequence":(
      "声望下降/劳工出逃/官府与宗门态度变化" if permitted_exception else ""),
    "visual_node_spawned":false}
  notable_npcs[entity_id]=person
  (city["known_named_npc_ids"] as Array).append(entity_id)
  return {"ok":true,"id":entity_id,
    "has_root":bool(status.get("has_root",false)),
    "root_kind":String(status.get("kind","")),
    "visual_node_spawned":false}

func recruit_bonded_worker(city_id: String,entity_id: String) -> Dictionary:
  if not cities.has(city_id):
    return {"ok":false,"reason":"UNKNOWN_CITY"}
  var city: Dictionary=cities[city_id]
  if int(city["recruitable_labor_pool"])<=0:
    return {"ok":false,"reason":"NO_RECRUITABLE_LABOR"}
  var response: Dictionary=register_named_person(
    city_id,entity_id,"bonded_labor")
  if bool(response.get("ok",false)):
    city["recruitable_labor_pool"]=int(city["recruitable_labor_pool"])-1
    city["bonded_labor_population"]=int(city["bonded_labor_population"])+1
    if not bool(response.get("has_root",false)):
      city["labor_without_root_count"]=int(city["labor_without_root_count"])+1
  return response

func advance_city_day(city_id: String) -> Dictionary:
  if not cities.has(city_id):
    return {"ok":false,"reason":"UNKNOWN_CITY"}
  var city: Dictionary=cities[city_id]
  var count: int=int(city["population"])
  # Slow deterministic demographic tick. Never pretend each resident has
  # a separate active AI or economy inventory. Migration can be negative.
  var year_phase: int=int(city["cohort_day"])%DAYS_PER_YEAR
  var birth_count: int=1 if year_phase%3==0 else 0
  birth_count+=count/30000
  var deaths: int=1 if year_phase%7==0 else 0
  deaths+=count/58000
  var migration: int=(-1 if year_phase%11==0 else (
    2 if year_phase%13==0 else 0))
  var new_total: int=clampi(count+birth_count-deaths+migration,
    MIN_CITY_POPULATION,MAX_CITY_POPULATION)
  var actual_delta: int=new_total-count
  city["population"]=new_total
  city["mortal_population"]=new_total
  city["residents_simulated_only"]=new_total
  city["food_requirement_per_day"]=new_total
  city["cohort_day"]=int(city["cohort_day"])+1
  # Keep all aggregated dimensions conserved after births, deaths and
  # migration. No virtual person is individually instantiated.
  var districts: Dictionary=city["districts"]
  districts["suburbs"]=int(districts["suburbs"])+actual_delta
  var cohort: Dictionary=city["age_cohorts"]
  cohort["children"]=int(new_total*0.24)
  cohort["adults"]=int(new_total*0.57)
  cohort["elders"]=new_total-int(cohort["children"])-int(cohort["adults"])
  if actual_delta>=0:
    city["born_total"]=int(city["born_total"])+actual_delta
  else:
    city["died_total"]=int(city["died_total"])-actual_delta
  city["migrated_total"]=int(city["migrated_total"])+migration
  report_count+=1
  return {"ok":true,"before":count,"after":new_total,
    "delta":actual_delta,"cohort_day":city["cohort_day"],
    "rendered_npcs":spawned_visual_nodes}

func describe_city(city_id: String) -> Dictionary:
  if not cities.has(city_id):
    return {}
  var row: Dictionary=cities[city_id].duplicate(true)
  row["named_npcs"]=0
  for person in notable_npcs.values():
    if String(person.get("city_id",""))==city_id:
      row["named_npcs"]=int(row["named_npcs"])+1
  row["spawned_visual_nodes"]=spawned_visual_nodes
  return row

func assert_city_bounds(city_id: String) -> bool:
  if not cities.has(city_id):
    return false
  var city: Dictionary=cities[city_id]
  var pop: int=int(city["population"])
  if pop<MIN_CITY_POPULATION or pop>MAX_CITY_POPULATION:
    return false
  var sum: int=0
  for value in (city["districts"] as Dictionary).values():
    sum+=int(value)
  var cohorts: Dictionary=city["age_cohorts"]
  var actual_cohort_total: int=0
  for value in cohorts.values():
    actual_cohort_total+=int(value)
  return sum==pop and actual_cohort_total==pop
