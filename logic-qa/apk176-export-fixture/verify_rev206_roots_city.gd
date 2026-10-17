extends SceneTree
## Native Godot 4.4.1 test, not a Python simulation of spiritual genetics.
## Load the exact same GDScript files that are bundled in original APK176.
func _fail(message: String) -> void:
  push_error("FAIL_REV206_ROOT_CENSUS "+message)
  quit(2)

func _initialize() -> void:
  call_deferred("_execute")

func _execute() -> void:
  var root_scene: GDScript=load("res://canglan_rev187/root_taxonomy.gd") as GDScript
  var city_scene: GDScript=load("res://canglan_rev187/city_population.gd") as GDScript
  if root_scene==null or city_scene==null:
    _fail("REAL_ROOT_DATA_OR_CITY_DEMOGRAPHY_NOT_IN_ORIGINAL_PCK_STAGE")
    return
  var roots: RefCounted=root_scene.new()
  var cities: RefCounted=city_scene.new()
  if not bool(cities.call("initialize",roots)):
    _fail("ROOT_CATALOG_NOT_BOUND_TO_CITY")
    return
  if int(roots.call("catalog_size"))<32 or (
      roots.call("supported_root_names") as Array).size()<40:
    _fail("ROOT_TAXONOMY_STILL_LIMITED_TO_FIVE_ELEMENTS")
    return
  var sample: Dictionary=roots.call("generate",20261017,
    "CL-PLAYER-0184-0001","player")
  var repeat: Dictionary=roots.call("generate",20261017,
    "CL-PLAYER-0184-0001","player")
  if sample!=repeat or not bool(sample.get("has_root",false)) or (
      sample.get("roots",[]) as Array).is_empty():
    _fail("PLAYER_SPIRIT_ROOT_NOT_PRESENT_AT_BIRTH_OR_REROLLS")
    return
  var normal_count: int=0
  var labor_without: int=0
  for n in range(640):
    var code: String="CL-ROOT-NORMAL-%04d" % n
    var profile: Dictionary=roots.call("generate",20261017,code,"citizen")
    if not bool(profile.get("has_root",false)) or String(
        profile.get("kind",""))=="无灵根":
      _fail("NORMAL_NPC_HAS_NO_ROOT_"+code)
      return
    normal_count+=1
    var employed: Dictionary=roots.call("generate",20261017,
      "CL-BONDED-EXCEPTION-%04d" % n,"bonded_labor")
    if not bool(employed.get("has_root",true)):
      labor_without+=1
  if labor_without<70 or labor_without>400:
    _fail("RECRUITABLE_BONDED_LABOR_ROOTLESS_EXCEPTION_NOT_WORKING")
    return
  var old_no_root: Dictionary=roots.call("migrate_existing",
    20261017,"CL-PLAYER-0184-0001","无灵根",[],"player")
  if not bool(old_no_root.get("has_root",false)) or String(
      old_no_root.get("origin",""))!="migrated_legacy_no_root":
    _fail("REV201_SAVE_NO_ROOT_PLAYER_NOT_MIGRATED_WITHOUT_WIPING_PROGRESS")
    return
  var legacy_metal: Dictionary=roots.call("migrate_existing",
    20261017,"CL-XIUXIAN-001","金灵根",[93,12,21,11,5],"cultivator")
  if String(legacy_metal.get("kind",""))!="金灵根" or (
      legacy_metal["root_weights"]!=[93,12,21,11,5]):
    _fail("REV201_EXISTING_ROOT_GRADE_AND_WEIGHTS_REROLLED")
    return
  var flame: Dictionary=roots.call("signature",
    {"has_root":true,"roots":["火"]})
  var ice: Dictionary=roots.call("signature",
    {"has_root":true,"roots":["冰"]})
  var thunder: Dictionary=roots.call("signature",
    {"has_root":true,"roots":["雷"]})
  var wood: Dictionary=roots.call("signature",
    {"has_root":true,"roots":["木"]})
  if String(flame.get("effect",""))!="burn" or String(
      ice.get("effect",""))!="freeze" or String(
      thunder.get("effect",""))!="shock" or String(
      wood.get("effect",""))!="entangle" or String(
      flame.get("color",""))==String(ice.get("color","")):
    _fail("ELEMENTAL_ROOTS_MUST_HAVE_DIFFERENT_COMBAT_AND_WORLD_RULES")
    return
  if float(roots.call("interaction",{"has_root":true,"roots":["水"]},
      {"has_root":true,"roots":["火"]})["multiplier"])<=1.0:
    _fail("WATER_TO_FIRE_COUNTER_NOT_REAL")
    return
  print("PASS_REV206_GODOT_PLAYER_AND_640_NAMED_NPCS_GUARANTEED_STABLE_ROOT_WITH_RECRUITABLE_NO_ROOT_EXCEPTION")
  print("PASS_REV206_GODOT_32_ROOT_ATTRIBUTES_MUTATIONS_QUALITY_FIRE_ICE_THUNDER_STATUS_AND_ELEMENTS_COUNTERS")
  for limit in [10000,80000,250000]:
    var cid: String="CL-CITY-REV206-%06d" % limit
    var created: Dictionary=cities.call("create_city",cid,20261017,limit)
    if not bool(created.get("ok",false)) or int(
        created.get("instantiated_npcs",-1))!=0:
      _fail("CITY_CREATED_10000_TO_250000_REAL_RENDER_NODES")
      return
    if not bool(cities.call("assert_city_bounds",cid)):
      _fail("CITY_START_COHORTS_NOT_CONSERVED")
      return
    var named: Dictionary=cities.call("register_named_person",
      cid,cid+"-MERCHANT","merchant")
    if not bool(named.get("has_root",false)):
      _fail("NORMAL_MERCHANT_WITHOUT_PERMANENT_ROOT")
      return
    var labor: Dictionary=cities.call("recruit_bonded_worker",
      cid,cid+"-BONDED")
    if not bool(labor.get("ok",false)):
      _fail("RECRUITABLE_BONDED_LABORER_POOL_NOT_WORKING")
      return
    for day in range(370):
      var step: Dictionary=cities.call("advance_city_day",cid)
      if not bool(step.get("ok",false)) or not bool(
          cities.call("assert_city_bounds",cid)):
        _fail("DAY_%d_CITY_%d_COUPLED_AGE_DISTRICTS_NO_LONGER_CONSERVED" % [
          day,limit])
        return
      var census: Dictionary=cities.call("describe_city",cid)
      if int(census.get("population",0))<10000 or int(
          census.get("population",0))>250000 or int(
          census.get("spawned_visual_nodes",-1))!=0:
        _fail("CITY_EXCEEDED_250K_OR_SPAWNED_100K_NODES")
        return
  if bool(cities.call("create_city","bad",20261017,250001).get(
      "ok",true)) or bool(cities.call("create_city",
      "bad",20261017,9999).get("ok",true)):
    _fail("CITY_10K_TO_250K_POPULATION_BOUNDS_NOT_ENFORCED")
    return
  print("PASS_REV206_GODOT_10000_80000_250000_CITY_MORTAL_POPULATION_LAZY_COUNTS_370_DAYS_NO_SCENE_BLOAT")
  quit(0)
