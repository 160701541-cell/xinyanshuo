extends SceneTree
## Real Godot 4.4.1 direct runtime for EXACT PCK-mounted herb and ore scripts.
## Cold cache, physical-node finite yields, atomic saved backpack, world
## regeneration, actual recipes and repeat-load conservation.
func _fail(reason: String) -> void:
  push_error("FAIL_REV206_GENUINE_SPIRIT_ECOLOGY "+reason)
  quit(2)

func _initialize() -> void:
  call_deferred("_run")

func _run() -> void:
  var res_script: GDScript=load("res://canglan_rev187/spirit_resources.gd") as GDScript
  var bag_script: GDScript=load("res://canglan_rev187/backpack.gd") as GDScript
  if res_script==null or bag_script==null:
    _fail("SCRIPTS_ABSENT_FROM_ORIGINAL_APK176_STAGE")
    return
  # Fresh scripted Godot project user:// must not modify real Android save.
  var ledger: RefCounted=res_script.new()
  var bag: RefCounted=bag_script.new()
  if not bool(ledger.call("initialize")):
    _fail("LEDGER_SAVE_LOAD")
    return
  var start: Dictionary=ledger.call("stats")
  if int(start.get("resource_nodes",0))!=13 or (
      int(start.get("live_spirit_stone_units",0))!=12) or (
      not bool(start.get("conserved",false))):
    _fail("REAL13_CC0_NODE_FINITE_SPIRIT_STONE_UNITS_NOT_INITIALIZED_"+str(start))
    return
  var nearest: Dictionary=ledger.call("get_nearest_resource",
    Vector3(-11.4,0,-12.2),3.0)
  if String(nearest.get("id",""))!="CL-LINGCAO-W-01":
    _fail("HERB_NOT_NEAR_ITS_ACTUAL_DEFINED_TERRAIN_COORDINATE")
    return
  var id: String="CL-LINGCAO-W-01"
  for i in range(4):
    var gained: Dictionary=ledger.call("harvest",id,bag)
    if not bool(gained.get("ok",false)) or (
        String(gained.get("kind",""))!="herb_wood"):
      _fail("FINITE_CC0_WOOD_HERB_NOT_GRANTED_FROM_REAL_SPENT_NODE")
      return
  if int(bag.call("amount","herb_wood"))!=4 or (
      bool(ledger.call("harvest",id,bag).get("ok",false))):
    _fail("DEPLETED_NODE_ALLOW_FREE_HARVEST_OR_BAG_DUPLICATION")
    return
  if not bool(ledger.call("conservation_ok")):
    _fail("FIRST_HARVEST_DOES_NOT_CONSERVE_WORLD_VS_INVENTORY")
    return
  var test_reload: RefCounted=res_script.new()
  if not bool(test_reload.call("initialize")) or (
      int(test_reload.get("nodes")[id]["remaining"])!=0):
    _fail("REAL_WORLD_SPIRIT_RESOURCE_PERSISTENCE_NOT_SAVED")
    return
  # Persistent player pill chain: no instant potion item without
  # harvest of the exact finite physical mushrooms and cold herbs.
  for kind_id in ["CL-LINGZHI-01","CL-LINGCAO-I-01",
      "CL-LINGCAO-I-01","CL-LINGSHI-01"]:
    if not bool(ledger.call("harvest",kind_id,bag).get("ok",false)):
      _fail("HERB_WATER_MUSHROOM_OR_ORE_NOT_PHYSICALLY_HARVESTABLE")
      return
  var potion: Dictionary=bag.call("craft","healing_pill")
  if not bool(potion.get("ok",false)) or int(
      bag.call("amount","herb_wood"))!=2 or int(
      bag.call("amount","mushroom"))!=0:
    _fail("HEALING_PILL_CRAFT_MUST_DEBIT_REAL_2_HERBS_1_MUSHROOM")
    return
  var mana: Dictionary=bag.call("craft","mana_pill")
  if not bool(mana.get("ok",false)) or int(
      bag.call("amount","spirit_stone"))!=0:
    _fail("QI_RESTORE_PILL_MUST_SPEND_REAL_COLD_FLOWERS_AND_ORE")
    return
  if bool(bag.call("equip","mana_pill").get("ok",false)):
    _fail("CONSUMABLE_MUST_NOT_EQUIP_AS_MAGIC_WEAPON")
    return
  if not bool(bag.call("consume_item","healing_pill",1)) or (
      int(bag.call("amount","healing_pill"))!=0):
    _fail("MEDICINE_CONSUMPTION_CANNOT_BE_FREE_OR_REPEATABLE")
    return
  var preserved: RefCounted=bag_script.new()
  if int(preserved.call("amount","herb_wood"))!=2 or (
      int(preserved.call("amount","mana_pill"))!=1) or (
      int(preserved.call("amount","healing_pill"))!=0):
    _fail("BACKPACK_SAVE_DID_NOT_SURVIVE_NEW_INSTANCE")
    return
  # Rev206: medicinal plant recovers 1 unit per 18 in-world HOURS only.
  for hour in range(17):
    ledger.call("advance_world_hour")
  if int(ledger.get("nodes")[id]["remaining"])!=0:
    _fail("HERBS_RESPAWN_BEFORE_WORLD_18H")
    return
  ledger.call("advance_world_hour")
  if int(ledger.get("nodes")[id]["remaining"])!=1 or not (
      bool(ledger.call("conservation_ok"))):
    _fail("HERBS_DO_NOT_SLOWLY_REGROW_CONSERVED_AFTER_WORLD_18H")
    return
  # Ore requires much longer real simulation time; cannot be clicked
  # repeatedly to create an infinite premium currency.
  for k in range(90):
    ledger.call("advance_world_hour")
  var final: Dictionary=ledger.call("stats")
  if not bool(final.get("conserved",false)) or (
      int(final.get("world_hours",-1))!=108) or (
      int(final.get("renewed_units",0))<=0):
    _fail("EXTENDED_WORLD_REGENERATION_AND_FINITE_STONE_MASS_NOT_CONSERVED")
    return
  # rev207: native flowers spread outside roads and houses after 720
  # genuine world hours, keeping rev206 13-node saves and finite mass.
  for hour in range(612):
    ledger.call("advance_world_hour")
  var living_nodes: Dictionary=ledger.get("nodes")
  var spreading_id: String="CL-WILD-LINGCAO-R207-0001"
  if int(living_nodes.size())<14 or not living_nodes.has(spreading_id) or (
      int(living_nodes[spreading_id]["remaining"])!=1) or (
      not bool(ledger.call("conservation_ok"))):
    _fail("REV207_NO_REAL_720H_NATURAL_CC0_SPIRIT_HERB_SPREAD_"+str(ledger.call("stats")))
    return
  var born: Dictionary=living_nodes[spreading_id]
  var world_x: float=float(born["x"])
  var world_z: float=float(born["z"])
  if absf(world_x)<9.0 or absf(world_x)>44.0 or (
      absf(world_z)>44.0):
    _fail("REV207_SEEDLING_SPAWNED_ON_RESERVED_BUILDING_OR_ROAD")
    return
  var natural_after_boot: RefCounted=res_script.new()
  if not bool(natural_after_boot.call("initialize")) or (
      not natural_after_boot.get("nodes").has(spreading_id)) or (
      not bool(natural_after_boot.call("conservation_ok"))):
    _fail("REV207_DISPERSED_SEEDLING_NOT_SAVED_IN_ORIGINAL_INVENTORY")
    return
  print("PASS_REV207_REAL_WIND_DISPERSAL_720H_CC0_MEDICINAL_PLANTS_SAVE_NO_BARE_SEEDBANK_WITHOUT_INVENTORY_DUPLICATION")
  print("PASS_REV206_REAL_WORLD_13_HERB_ORE_SOURCE_CC0_NODES_PERSISTED_CONSERVATION_AND_18_TO_96H_REGROWTH")
  print("PASS_REV206_REAL_GODOT_BACKPACK_PILL_CRAFT_SPENDS_HARVESTED_HERBS_SPIRIT_STONES_SAVES_AND_CONSUMES")
  quit(0)
