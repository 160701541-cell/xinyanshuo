extends SceneTree
## Godot 4.4.1 live GDScript: 50,000 km²/500 regions, 5k mortals,
## inherited spiritual roots, physical refinement, sect crafts, herb seedbank
## and mine-guarding cultivating/reproducing yao-beast populations.
func _fail(msg: String) -> void:
  printerr("FAIL_REV207_LIVING_WORLD_"+msg)
  quit(29)

func _initialize() -> void:
  call_deferred("_run")

func _run() -> void:
  var packed: GDScript=load("res://canglan_rev187/living_regions.gd") as GDScript
  if packed==null:
    _fail("PCK_SOURCE_NOT_STAGED")
    return
  var model: RefCounted=packed.new()
  if not bool(model.call("initialize",20261017)):
    _fail("INITIAL_GENERATION_OR_SAVE_"+String(model.get("_last_error")))
    return
  var initial: Dictionary=model.call("stats")
  if int(initial["area_km2"])!=50000 or int(initial["regions"])!=500 or (
      int(initial["population"])!=5000) or (
      int(initial["rooted_mortals"])!=125) or (
      int(initial["without_spirit_root"])!=4875) or (
      int(initial["body_cultivators"])<150) or (
      int(initial["mine_bound_beast_populations"])<20) or (
      int(initial["factions"])!=5) or (
      int(initial["disciplines"])<14) or (
      not bool(initial["conserved"])):
    _fail("INITIAL_WORLD_POPULATION_REALM_CRAFTS_"+str(initial))
    return
  if (model.get("regions") as Dictionary).size()!=500:
    _fail("NEVER_SPAWN_500_3D_REGIONS")
    return
  var region: Dictionary=model.call("region_at",231.0,101.0)
  if int(region.get("area_km2",-1))!=100:
    _fail("REGION_GRID_TERRITORY_SIZE")
    return
  var cohort_population: int=0
  var flora_minimum: int=1000000
  for r in (model.get("regions") as Dictionary).values():
    cohort_population+=int(r["children"])+int(r["adults"])+int(r["elders"])
    flora_minimum=mini(flora_minimum,int(r["seed_bank"]))
    if int(r["forest_density_bp"])<9500 or int(r["wild_herbs"])<1:
      _fail("LOGICAL_WILDERNESS_BARE_OR_SPECIES_EXTINCT")
      return
  if cohort_population!=5000 or flora_minimum<1:
    _fail("INITIAL_COHORT_OR_SEEDBANK_NOT_CONSERVED")
    return
  for pack in (model.get("beast_packs") as Dictionary).values():
    if not String(pack["ore"]).begins_with("CL-LINGSHI-") or (
        int(pack["layer"])!=1) or (
        int(pack["population"])<2):
      _fail("ORE_SPECIES_GUARDIAN_MISSING")
      return
  var catalog: Array=packed.get_script_constant_map()["DISCIPLINES"]
  for sect in (model.get("sects") as Dictionary).values():
    if not catalog.has(sect["primary"]) or (
        not catalog.has(sect["secondary"])):
      _fail("REAL_SECT_DISCIPLINE_CATALOG_MISSING")
      return
  print("PASS_REV207_REAL_WORLD_INITIAL_50000_KM2_500_REGIONS_5000_MORTALS_ONLY_125_SPIRIT_ROOTS_OTHER_CAN_BODY_REFINE")
  for hour in range(24*30*24):
    model.call("advance_world_hour")
  var advanced: Dictionary=model.call("stats")
  if int(advanced["months"])!=24 or int(advanced["births"])<=0 or (
      int(advanced["deaths"])<=0) or (
      int(advanced["population"])!=5000+int(advanced["births"])-int(advanced["deaths"])) or (
      int(advanced["mine_bound_beast_populations"])<=int(initial["mine_bound_beast_populations"])) or (
      int(advanced["rooted_mortals"])<125) or (
      int(advanced["herb_seed_bank"])<500) or (
      not bool(advanced["conserved"])):
    _fail("24_MONTHS_BIRTHS_DEATHS_BEAST_BREED_QI_PLANTS_"+str(advanced))
    return
  var any_progress: bool=false
  var newborns: int=0
  for pack in (model.get("beast_packs") as Dictionary).values():
    any_progress=any_progress or int(pack["layer"])>=2
    newborns+=int(pack["born_total"])
  if not any_progress or newborns<4:
    _fail("MONSTERS_NEAR_ORE_NOT_CULTIVATING_OR_REPRODUCING")
    return
  var trained: int=0
  for sect in (model.get("sects") as Dictionary).values():
    trained+=int(sect["study_hours"])
    if int(sect["members"])<1 or int(sect["reserves_spirit_stones"])!=0:
      _fail("SECTS_FABRICATED_SUPPLIES_OR_NOT_RECRUITING")
      return
  if trained<=0:
    _fail("NO_INDEPENDENT_SECT_VOCATIONS")
    return
  var victim: String="CL-WILDLIFE-WOLF-01"
  var before: int=int(model.get("beast_packs")[victim]["population"])
  model.call("record_guardian_death",victim)
  if int(model.get("beast_packs")[victim]["population"])!=before-1:
    _fail("REAL_MONSTER_DEATH_NOT_DEBITING_PACK")
    return
  if not bool(model.call("force_save")):
    _fail("WORLD_ATOMIC_PERSISTENCE_FAILED")
    return
  var reload: RefCounted=packed.new()
  if not bool(reload.call("initialize",20261017)):
    _fail("WORLD_SAVE_CANNOT_RELOAD_"+String(reload.get("_last_error")))
    return
  var after: Dictionary=reload.call("stats")
  if int(after["population"])!=int(advanced["population"]) or (
      int(after["months"])!=24) or (
      int(reload.get("beast_packs")[victim]["population"])!=before-1) or (
      not bool(after["conserved"])):
    _fail("WORLD_RELOAD_DUPLICATED_BIRTHS_OR_LOST_BEASTS_"+str(after))
    return
  print("PASS_REV207_REAL_24_MONTH_DEMOGRAPHIC_BIRTHS_DEATHS_SECT_PROFESSIONS_ANNUAL_BODY_CULTIVATION_ATOMIC_SAVE")
  print("PASS_REV207_REAL_ORE_GUARD_YAO_BEAST_CULTIVATION_BREEDING_MORTALITY_PHYSICAL_DEATH_DEBIT")
  print("PASS_REV207_REAL_EVERGREEN_SEEDBANK_FORESTS_AND_WILD_HERBS_NO_BARREN_UNBUILT_REGIONS")
  quit(0)
