extends RefCounted
## REV207: finite, off-screen, deterministic 50,000 km² living world.
## The installed APK176 renders only streamed nearby regions; 500 regions
## of 100 km² are COUNTS, not 500 loaded 3D scenes or imaginary citizens.
## This new world is authoritative; old 80k city save stays read-only for
## compatibility, never counted as additional people.
const SCHEMA: int=207
const SAVE_PATH: String="user://canglan_living_regions_rev207.json"
const WORLD_SEED_DEFAULT: int=20261017
const AREA_KM2: int=50000
const REGION_SIDE_KM: int=10
const REGION_WIDTH: int=25
const REGION_HEIGHT: int=20
const REGION_COUNT: int=500
const INITIAL_PEOPLE: int=5000
const ROOT_BASIS_POINTS: int=250 # configurable 2.5% inherited talent
const HOURS_PER_MONTH: int=720
const BIOMES: Array[String]=["forest","river","hills","wetland","steppe","mountain"]
const DISCIPLINES: Array[String]=[
  "剑修","炼体","炼丹","炼器","符箓","阵法","御兽","灵植","傀儡","驭虫","医修","卜算","商道","鬼道"]
const MINE_GUARDS: Array=[
  {"id":"CL-WILDLIFE-WOLF-01","ore":"CL-LINGSHI-01","species":"wolf","element":"金","population":7},
  {"id":"CL-WILDLIFE-FOX-01","ore":"CL-LINGSHI-02","species":"fox","element":"木","population":6},
  {"id":"CL-WILDLIFE-DEER-01","ore":"CL-LINGSHI-03","species":"deer","element":"水","population":8},
  {"id":"CL-WILDLIFE-COW-01","ore":"CL-LINGSHI-04","species":"cow","element":"土","population":5}]
const SECTS: Array=[
  {"id":"CL-SECT-SWORD-01","name":"青霄剑宗","primary":"剑修","secondary":"阵法","seat":43},
  {"id":"CL-SECT-PILL-01","name":"百草丹谷","primary":"炼丹","secondary":"灵植","seat":147},
  {"id":"CL-SECT-BEAST-01","name":"万灵御兽门","primary":"御兽","secondary":"驭虫","seat":256},
  {"id":"CL-SECT-TALISMAN-01","name":"玄符阁","primary":"符箓","secondary":"炼器","seat":371},
  {"id":"CL-SECT-BODY-01","name":"撼山体宗","primary":"炼体","secondary":"傀儡","seat":484}]
var seed: int=WORLD_SEED_DEFAULT
var regions: Dictionary={}
var sects: Dictionary={}
var beast_packs: Dictionary={}
# Revision-compatible exactly-once death journal for physically represented
# citizens: counts already belong to the original 5,000, not extra bodies.
var named_deaths: Dictionary={}
# rev208 命牌：宗门修士死亡时，只传死者宗门 + 宗门文献一条，
# 不做全城传闻。这里存的是「已确认死亡」的薄账，不新增人口。
var sect_obituaries: Dictionary={}
var confirmed_deaths: int=0
var missing_total: int=0
var hours: int=0
var months: int=0
var born_total: int=0
var died_total: int=0
var spirit_births: int=0
var spiritual_birth_fraction: int=0
var body_birth_fraction: int=0
var _loaded: bool=false
var _last_error: String=""
var _save_writes: int=0
var _birth_offset: int=0
var _death_offset: int=0

func _noise(index: int,salt: int) -> int:
  # Avoid global RNG state and platform-dependent random iteration.
  return posmod((index*7919+salt*15427+seed%100003)*139,1000003)

func initialize(world_seed: int=WORLD_SEED_DEFAULT) -> bool:
  if _loaded:
    return true
  seed=maxi(1,world_seed)
  regions.clear()
  sects.clear()
  beast_packs.clear()
  named_deaths.clear()
  sect_obituaries.clear()
  confirmed_deaths=0
  missing_total=0
  var weights: Array[int]=[]
  var total_weight: int=0
  for n in range(REGION_COUNT):
    var biome: String=BIOMES[_noise(n,13)%BIOMES.size()]
    var weight: int=4 if biome=="river" else (3 if biome in ["steppe","forest"] else (
      2 if biome=="hills" else 1))
    weights.append(weight)
    total_weight+=weight
    var rid: String="CL-REGION-%03d" % n
    # A living seed bank is separate from harvestable adults. Harvesting
    # leaves/buds cannot exterminate the species; dispersal and germination
    # use world-time, not an instant free item when the player presses a key.
    regions[rid]={
      "index":n,"biome":biome,"area_km2":100,
      "people":0,"roots":0,"body_practitioners":0,
      "children":0,"adults":0,"elders":0,
      "seed_bank":30+_noise(n,17)%55,
      "wild_herbs":3+_noise(n,19)%15,
      "forest_density_bp":9700+_noise(n,23)%250,
      "built_ground_bp":0,"births":0,"deaths":0,"missing":0,
      "spirit_ore_traces":_noise(n,29)%15==0,
      "named_npcs":0}
  var assigned: int=0
  for n in range(REGION_COUNT):
    var row: Dictionary=regions["CL-REGION-%03d" % n]
    row["people"]=INITIAL_PEOPLE*weights[n]/total_weight
    assigned+=int(row["people"])
  var remainder: int=INITIAL_PEOPLE-assigned
  var offset: int=_noise(0,37)%REGION_COUNT
  for step in range(remainder):
    var chosen: String="CL-REGION-%03d" % ((offset+step*37)%REGION_COUNT)
    var row: Dictionary=regions[chosen]
    row["people"]=int(row["people"])+1
  # Distributed exact 2.5% spiritual births at world creation. The other
  # 4,875 people are ordinary mortals who CAN cultivate their bodies.
  var root_carry: int=0
  var body_carry: int=0
  for key in regions:
    var r: Dictionary=regions[key]
    var people: int=int(r["people"])
    var total_roots: int=root_carry+people*ROOT_BASIS_POINTS
    r["roots"]=total_roots/10000
    root_carry=total_roots%10000
    var total_body: int=body_carry+(people-int(r["roots"]))*600
    r["body_practitioners"]=total_body/10000
    body_carry=total_body%10000
    r["children"]=people*23/100
    r["elders"]=people*9/100
    r["adults"]=people-int(r["children"])-int(r["elders"])
  for blueprint in SECTS:
    var id: String=String(blueprint["id"])
    sects[id]={
      "id":id,"name":String(blueprint["name"]),
      "primary":String(blueprint["primary"]),"secondary":String(blueprint["secondary"]),
      "territory":"CL-REGION-%03d" % int(blueprint["seat"]),
      # Five actually existing devotees founded each school. They are
      # drawn from the 125 spirit-root and rootless body-cultivator census;
      # do not count them as 25 newly created additional human beings.
      "members":5,"foundation":"山门/功法阁/练功场/药园/丹房须逐步建设",
      "study_hours":0,"technique_experience":0,"founded":true,
      "reserves_spirit_stones":0,"reserves_herbs":0,
      "real_rendered_sect_buildings":0}
  # Distinct packs are physically guarded at four actual CC0 ore nodes.
  # Populations not rendered remain count-only; no 1000-scene-node cheat.
  for blueprint in MINE_GUARDS:
    var id: String=String(blueprint["id"])
    beast_packs[id]={
      "id":id,"ore":String(blueprint["ore"]),"species":String(blueprint["species"]),
      "element":String(blueprint["element"]),"population":int(blueprint["population"]),
      "age_months":18,"layer":1,"realm":"启灵一阶",
      "qi":0,"experience":0,"born_total":0,"died_total":0,
      "food":20,"ore_guarded":true,"physical_leaders":1}
  # New users get this saved once. An invalid save is never overwritten.
  if FileAccess.file_exists(SAVE_PATH):
    var old: Variant=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
    if not old is Dictionary or int(old.get("schema",0))!=SCHEMA or (
        int(old.get("seed",0))!=seed):
      _last_error="LIVING_REGIONS_SCHEMA_OR_SEED_MISMATCH_PRESERVE_SAVE"
      return false
    var stored: Dictionary=old.get("regions",{})
    var saved_sects: Dictionary=old.get("sects",{})
    var saved_packs: Dictionary=old.get("beast_packs",{})
    if stored.size()!=REGION_COUNT or saved_sects.size()!=SECTS.size() or (
        saved_packs.size()!=MINE_GUARDS.size()):
      _last_error="LIVING_REGIONS_MISSING_REGION_SECT_OR_PACK"
      return false
    regions=stored
    sects=saved_sects
    beast_packs=saved_packs
    named_deaths=old.get("named_deaths",{})
    sect_obituaries=old.get("sect_obituaries",{})
    confirmed_deaths=maxi(0,int(old.get("confirmed_deaths",0)))
    missing_total=maxi(0,int(old.get("missing_total",0)))
    if confirmed_deaths==0 and missing_total==0 and died_total>0:
      confirmed_deaths=died_total  # 旧档只有「离开」总数，按确认死亡迁移
    hours=maxi(0,int(old.get("hours",0)))
    months=maxi(0,int(old.get("months",0)))
    born_total=maxi(0,int(old.get("born_total",0)))
    died_total=maxi(0,int(old.get("died_total",0)))
    spirit_births=maxi(0,int(old.get("spirit_births",0)))
    spiritual_birth_fraction=maxi(0,int(old.get("spiritual_birth_fraction",0)))%10000
    body_birth_fraction=maxi(0,int(old.get("body_birth_fraction",0)))%10000
    _birth_offset=maxi(0,int(old.get("birth_offset",0)))
    _death_offset=maxi(0,int(old.get("death_offset",0)))
    if not conservation_ok():
      _last_error="LIVING_REGIONS_CORRUPT_POPULATION_BIODIVERSITY"
      return false
  _loaded=true
  return true

func _pick_region(for_birth: bool,iteration: int) -> Dictionary:
  var starting: int=_birth_offset if for_birth else _death_offset
  for trial in range(REGION_COUNT):
    var index: int=(starting+iteration*37+trial*17)%REGION_COUNT
    var row: Dictionary=regions["CL-REGION-%03d" % index]
    var eligible: bool=int(row["adults"])>=2 if for_birth else (
      int(row["elders"])+int(row["adults"])>1)
    if eligible:
      return row
  return {}

func _advance_month() -> void:
  months+=1
  var total: int=population()
  # Young families have biological children, existing people age and die.
  # No instant population multiplier and no >5000 scene instances.
  var natural_births: int=maxi(1,roundi(float(total)*0.00155))
  var natural_deaths: int=maxi(0,roundi(float(total)*0.00092))
  for i in range(natural_births):
    var r: Dictionary=_pick_region(true,i)
    if r.is_empty():
      break
    r["people"]=int(r["people"])+1
    r["children"]=int(r["children"])+1
    r["births"]=int(r["births"])+1
    born_total+=1
    var root_bp: int=ROOT_BASIS_POINTS+(
      125 if int(r["roots"])>0 else 0)
    spiritual_birth_fraction+=root_bp
    if spiritual_birth_fraction>=10000:
      spiritual_birth_fraction-=10000
      r["roots"]=int(r["roots"])+1
      spirit_births+=1
    # Children may inherit a physical constitution but are not recorded
    # as trained adult body-refiners on the day they are born.
  _birth_offset=(_birth_offset+41)%REGION_COUNT
  for i in range(natural_deaths):
    var d: Dictionary=_pick_region(false,i)
    if d.is_empty():
      break
    d["people"]=int(d["people"])-1
    if int(d["elders"])>0:
      d["elders"]=int(d["elders"])-1
    else:
      d["adults"]=int(d["adults"])-1
    # Cohort deaths remove a proportionate number of inherited roots and
    # trained body cultivators. Rooted children are never all born adults.
    if int(d["roots"])>0 and _noise(months+i,53)%10000<(
        int(d["roots"])*10000/(int(d["people"])+1)):
      d["roots"]=int(d["roots"])-1
    if int(d["body_practitioners"])>0 and _noise(months+i,59)%10000<(
        int(d["body_practitioners"])*10000/(int(d["people"])+1)):
      d["body_practitioners"]=int(d["body_practitioners"])-1
    d["deaths"]=int(d["deaths"])+1
    died_total+=1
    # 自然死亡是确定的「死了」，不属于失踪，直接计入确认死亡。
    confirmed_deaths+=1
  _death_offset=(_death_offset+23)%REGION_COUNT
  if months%12==0:
    for row in regions.values():
      var age_up: int=int(row["children"])/18
      var retire: int=int(row["adults"])/44
      row["children"]=int(row["children"])-age_up
      row["adults"]=int(row["adults"])+age_up-retire
      row["elders"]=int(row["elders"])+retire
      # A subset of newly adult, rootless mortals begins body refinement.
      body_birth_fraction+=age_up*600
      var new_body: int=body_birth_fraction/10000
      body_birth_fraction=body_birth_fraction%10000
      row["body_practitioners"]=mini(int(row["people"])-int(
        row["roots"]),int(row["body_practitioners"])+new_body)
  for row in regions.values():
    var density: int=int(row["forest_density_bp"])
    # Seeds naturally disperse and regrow, up to biomass/canopy carrying
    # capacity. There is NO "harvest wild plant = free inventory" path.
    var germinated: int=mini(int(row["seed_bank"])/11,18)
    row["wild_herbs"]=mini(300,maxi(1,int(row["wild_herbs"])+germinated-(
      1 if months%4==0 else 0)))
    row["seed_bank"]=clampi(int(row["seed_bank"])+2-germinated,1,1000)
    row["forest_density_bp"]=clampi(density+(
      1 if months%3==0 else 0),9500,9950)
  for pack in beast_packs.values():
    pack["age_months"]=int(pack["age_months"])+1
    pack["food"]=mini(50,int(pack["food"])+5)
    # Aura near real ore deposits nurtures a slow, finite energy budget.
    var qi_gain: int=mini(4,int(pack["population"]))
    pack["qi"]=mini(800,int(pack["qi"])+qi_gain)
    pack["experience"]=int(pack["experience"])+qi_gain
    var cost: int=20+int(pack["layer"])*12
    if int(pack["experience"])>=cost and int(pack["qi"])>=cost:
      pack["experience"]=int(pack["experience"])-cost
      pack["qi"]=int(pack["qi"])-cost
      pack["layer"]=mini(27,int(pack["layer"])+1)
      var layer: int=int(pack["layer"])
      pack["realm"]=("启灵%d阶" % layer) if layer<=9 else (
        ("聚灵%d阶" % (layer-9)) if layer<=18 else (
        "凝丹%d阶" % (layer-18)))
    # Reproduction needs mates, territory, age and foraged food.
    if months%6==0 and int(pack["population"])>=2 and (
        int(pack["population"])<18 and int(pack["food"])>=8):
      pack["food"]=int(pack["food"])-8
      pack["population"]=int(pack["population"])+1
      pack["born_total"]=int(pack["born_total"])+1
    if months%30==0 and int(pack["population"])>2:
      pack["population"]=int(pack["population"])-1
      pack["died_total"]=int(pack["died_total"])+1
  var total_rooted: int=root_population()
  var total_body: int=body_cultivator_population()
  var pool: int=total_rooted+total_body
  for key in sects:
    var s: Dictionary=sects[key]
    # Every sect can recruit only from the real aggregated population.
    var cap: int=pool*7/100
    if int(s["members"])<cap and months%3==0:
      s["members"]=int(s["members"])+1
    if int(s["members"])>0:
      s["study_hours"]=int(s["study_hours"])+HOURS_PER_MONTH
      s["technique_experience"]=int(s["technique_experience"])+int(s["members"])
  # Event-driven disk writes (one per 30 world days, not each frame).
  if not _save():
    push_warning("REV207_LIVING_REGIONS_WORLD_SAVE_FAILED_"+_last_error)

func advance_world_hour() -> void:
  if not _loaded:
    return
  hours+=1
  if hours%HOURS_PER_MONTH==0:
    _advance_month()

func record_guardian_death(beast_id: String) -> void:
  if not beast_packs.has(beast_id):
    return
  var p: Dictionary=beast_packs[beast_id]
  if int(p["population"])>0:
    p["population"]=int(p["population"])-1
    p["died_total"]=int(p["died_total"])+1
    _save()

func record_named_cultivator_death(id: String,is_spirit_rooted: bool,
    is_body_cultivator: bool,source: String,
    sect_id: String="",witnessed: bool=true) -> Dictionary:
  # Physical visitors to the starting village are named citizens *within*
  # the preexisting offscreen census; they are not 12 more invented humans.
  # A cultivator may be temporarily visiting the village from a home sect
  # region. Choose the deterministic first home with matching occupation.
  # Journal IDs guard against kill->restart->kill or late callbacks.
  #
  # rev208 命牌（用户口径）：宗门修士死的那一刻宗门就知道，不依赖目击；
  # 散修/无命牌要靠人发现，没人发现只能记 missing（失踪）。
  # people 一律 -1（人口离开账），只有确认死亡才进 deaths/宗门文献。
  if not _loaded or not id.begins_with("CL-XIUXIAN-"):
    return {"ok":false,"reason":"REGIONS_NOT_READY_OR_INVALID_NAMED_ID"}
  if named_deaths.has(id):
    var prior: Dictionary=named_deaths[id]
    return {"ok":true,"already_recorded":true,
      "region_id":String(prior.get("region_id","")),
      "status":String(prior.get("status","dead")),
      "confirmed_by":String(prior.get("confirmed_by",""))}
  var confirmed: bool = sect_id!="" or witnessed
  var confirmed_by: String = "life_tablet" if sect_id!="" else (
    "witness" if witnessed else "")
  var territory: String=""
  if sect_id!="" and sects.has(sect_id):
    territory=String(sects[sect_id].get("territory",""))
  var start: int=_noise(int(id.right(3)),71)%REGION_COUNT
  var chosen_id: String=""
  for step in range(REGION_COUNT):
    var test_id: String="CL-REGION-%03d" % ((start+step*37)%REGION_COUNT)
    var r: Dictionary=regions[test_id]
    if int(r.get("adults",0))<1 or int(r.get("people",0))<1:
      continue
    if is_spirit_rooted and int(r.get("roots",0))<=0:
      continue
    if is_body_cultivator and int(r.get("body_practitioners",0))<=0:
      continue
    chosen_id=test_id
    break
  if chosen_id.is_empty():
    return {"ok":false,"reason":"NO_ELIGIBLE_EXISTING_CENSUS_CITIZEN"}
  var outside_sect: bool = sect_id!="" and not territory.is_empty() and (
    territory!=chosen_id)
  var region: Dictionary=regions[chosen_id]
  var snapshot: Dictionary=region.duplicate(true)
  var old_died: int=died_total
  var old_confirmed: int=confirmed_deaths
  var old_missing: int=missing_total
  var old_obituaries: Dictionary=sect_obituaries.duplicate(true)
  region["people"]=int(region["people"])-1
  region["adults"]=int(region["adults"])-1
  if confirmed:
    region["deaths"]=int(region["deaths"])+1
    confirmed_deaths+=1
  else:
    region["missing"]=int(region.get("missing",0))+1
    missing_total+=1
  if is_spirit_rooted:
    region["roots"]=int(region["roots"])-1
  if is_body_cultivator:
    region["body_practitioners"]=int(region["body_practitioners"])-1
  # died_total 是「离开人口账」的总数（确认死亡 + 失踪），conservation 用它。
  died_total+=1
  named_deaths[id]={"region_id":chosen_id,
    "at_hour":hours,"rooted":is_spirit_rooted,
    "body_cultivator":is_body_cultivator,"cause":source,
    "status":("dead" if confirmed else "missing"),
    "confirmed_by":confirmed_by,"sect_id":sect_id,
    "death_outside_sect":outside_sect}
  if confirmed and sect_id!="":
    # 宗门文献：只记确认死亡，独立小表，不刷全城传闻。
    var rows: Array=sect_obituaries.get(sect_id,[])
    rows.append({"entity_id":id,"sect_id":sect_id,"at_hour":hours,
      "region_id":chosen_id,"cause":source,"confirmed_by":confirmed_by})
    if rows.size()>200:
      rows=rows.slice(rows.size()-200)
    sect_obituaries[sect_id]=rows
  # Durable region update happens before the visible actor's death save.
  # A subsequent game start repairs any second-ledger interrupted commit
  # from this named journal instead of resurrecting an already-debited NPC.
  if not conservation_ok() or not _save():
    regions[chosen_id]=snapshot
    died_total=old_died
    confirmed_deaths=old_confirmed
    missing_total=old_missing
    sect_obituaries=old_obituaries
    named_deaths.erase(id)
    return {"ok":false,"reason":"CENSUS_CONSERVATION_OR_DISK_FAILURE_"+_last_error}
  return {"ok":true,"already_recorded":false,
    "region_id":chosen_id,"status":("dead" if confirmed else "missing"),
    "confirmed_by":confirmed_by,"sect_id":sect_id,
    "death_outside_sect":outside_sect,
    "new_world_population":population()}

func population() -> int:
  var tally: int=0
  for row in regions.values():
    tally+=int(row["people"])
  return tally

func root_population() -> int:
  var tally: int=0
  for row in regions.values():
    tally+=int(row["roots"])
  return tally

func body_cultivator_population() -> int:
  var tally: int=0
  for row in regions.values():
    tally+=int(row["body_practitioners"])
  return tally

func conserved_flora() -> bool:
  for row in regions.values():
    if int(row["seed_bank"])<1 or int(row["wild_herbs"])<1:
      return false
    if int(row["forest_density_bp"])<9500 or (
        int(row["forest_density_bp"])>9950):
      return false
  return true

func conservation_ok() -> bool:
  if regions.size()!=REGION_COUNT or sects.size()!=SECTS.size() or (
      beast_packs.size()!=MINE_GUARDS.size()):
    return false
  if population()!=INITIAL_PEOPLE+born_total-died_total:
    return false
  var species_total: int=0
  var seated: int=0
  for row in regions.values():
    if int(row["people"])<0 or int(row["roots"])<0 or (
        int(row["roots"])>int(row["people"])) or (
        int(row["body_practitioners"])<0 or (
        int(row["body_practitioners"])>int(row["people"])-int(row["roots"]))):
      return false
    if int(row["children"])+int(row["adults"])+int(row["elders"])!=(
        int(row["people"])):
      return false
  for beast in beast_packs.values():
    if int(beast["population"])<1 or int(beast["population"])>18:
      return false
    species_total+=int(beast["population"])
  for sect in sects.values():
    seated+=int(sect["members"])
  return conserved_flora() and species_total>=4 and seated<=(
    root_population()+body_cultivator_population())

func _save() -> bool:
  if not _loaded:
    return false
  var data: Dictionary={
    "schema":SCHEMA,"seed":seed,"hours":hours,"months":months,
    "regions":regions,"sects":sects,"beast_packs":beast_packs,
    "born_total":born_total,"died_total":died_total,
    "spirit_births":spirit_births,
    "spiritual_birth_fraction":spiritual_birth_fraction,
    "body_birth_fraction":body_birth_fraction,
    "birth_offset":_birth_offset,"death_offset":_death_offset,
    "named_deaths":named_deaths,"sect_obituaries":sect_obituaries,
    "confirmed_deaths":confirmed_deaths,"missing_total":missing_total}
  var writer:=FileAccess.open(SAVE_PATH+".tmp",FileAccess.WRITE)
  if writer==null:
    _last_error="REGIONS_WRITE_FAILED"
    return false
  writer.store_string(JSON.stringify(data))
  writer.flush()
  writer.close()
  if DirAccess.rename_absolute(SAVE_PATH+".tmp",SAVE_PATH)!=OK:
    _last_error="REGIONS_ATOMIC_RENAME_FAILED"
    return false
  _last_error=""
  _save_writes+=1
  return true

func force_save() -> bool:
  return conservation_ok() and _save()

func region_at(world_x_km: float,world_z_km: float) -> Dictionary:
  var xi: int=clampi(floori(world_x_km/float(REGION_SIDE_KM)),0,REGION_WIDTH-1)
  var zi: int=clampi(floori(world_z_km/float(REGION_SIDE_KM)),0,REGION_HEIGHT-1)
  return (regions.get("CL-REGION-%03d" % (zi*REGION_WIDTH+xi),{}) as Dictionary).duplicate(true)

func _named_dead_count() -> int:
  var n: int=0
  for id in named_deaths:
    if String(named_deaths[id].get("status","dead"))=="dead":
      n+=1
  return n

func stats() -> Dictionary:
  var plants: int=0
  var seeds: int=0
  var wild_animals: int=0
  var built_area: int=0
  for row in regions.values():
    plants+=int(row["wild_herbs"])
    seeds+=int(row["seed_bank"])
    built_area+=int(row["built_ground_bp"])
  for pack in beast_packs.values():
    wild_animals+=int(pack["population"])
  return {"schema":SCHEMA,"area_km2":AREA_KM2,"region_size_km2":100,
    "regions":REGION_COUNT,"initial_mortal_population":INITIAL_PEOPLE,
    "population":population(),"rooted_mortals":root_population(),
    "root_ratio_basis_points":ROOT_BASIS_POINTS,
    "without_spirit_root":population()-root_population(),
    "body_cultivators":body_cultivator_population(),
    "births":born_total,"deaths":confirmed_deaths,"missing":missing_total,
    "departed_total":died_total,
    "named_confirmed_deaths":_named_dead_count(),"named_deaths_total":named_deaths.size(),
    "months":months,
    "hours":hours,"factions":sects.size(),
    "disciplines":DISCIPLINES.size(),
    "herb_seed_bank":seeds,"wild_herb_plants":plants,
    "region_built_bp":built_area,
    "mine_bound_beast_populations":wild_animals,
    "true_physical_beast_leaders":4,
    "real_loaded_human_scene_nodes":0,
    "offscreen_beast_offspring_as_counts_only":true,
    "conserved":conservation_ok(),"save_writes":_save_writes,
    "loaded":_loaded,"last_error":_last_error}
