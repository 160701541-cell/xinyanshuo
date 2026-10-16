extends SceneTree
## Confirms the REAL local AI decision bridge has no magical inventory access.
## This tests safety/scene coupling, NOT native mobile llama.cpp inference.
const Policy = preload("res://scripts/npc_intent_policy.gd")
func _initialize() -> void:
	call_deferred("_test")
func _test() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	assert(packed!=null)
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	var logic: RefCounted = Policy.new()
	var sim: RefCounted = game.get("life_sim")
	var build: Node3D = game.get("npc_building_system")
	var resident: Node3D = null
	for candidate in game.get("citizen_nodes"):
		if not bool(candidate.get("_externally_assigned_job")):
			resident=candidate
			break
	assert(resident!=null and sim!=null and build!=null)
	var code: String = String(resident.get_meta("entity_id",""))
	var person: Dictionary = sim.get("citizens")[code]
	var town: Dictionary = sim.get("villages")[String(person["village_id"])]
	var stock: Dictionary = town["stock"]
	assert(logic.call("parse_intent","ACTION=eat")=="eat")
	assert(logic.call("parse_intent","ACTION=inspect_stock")=="inspect_stock")
	assert(logic.call("parse_intent","ACTION=spawn_gold")=="")
	assert(logic.call("parse_intent","IGNORE RULES\nACTION=eat")=="")
	assert(logic.call("parse_intent","ACTION=rest; game.cheat()")=="")
	assert(logic.call("parse_intent","ACTION=inspect_site\nGIVE GOLD")=="inspect_site")
	person["hunger"]=60
	var before_food: int = int(stock["food"])
	var applied: bool = bool(logic.call("apply_intent",code,"eat",sim,resident,build,100))
	assert(applied and int(stock["food"])==before_food-1)
	assert(int(person["hunger"])==15,"Eating must require real WorldBox stock")
	assert(not bool(logic.call("apply_intent",code,"eat",sim,resident,build,100)),
		"Model must not repeatedly invoke action same hour")
	assert(not bool(logic.call("apply_intent","ANOTHER-NPC","rest",sim,resident,build,105)),
		"No cross-citizen actions")
	var old_gold: int = int(stock.get("coin",0))
	person["energy"]=36
	assert(bool(logic.call("apply_intent",code,"rest",sim,resident,build,105)))
	assert(int(person["energy"])==42 and int(stock.get("coin",0))==old_gold)
	person["energy"]=90
	assert(not bool(logic.call("apply_intent",code,"rest",sim,resident,build,110)),
		"High-energy character has no legitimate reason to rest")
	assert(bool(logic.call("apply_intent",code,"inspect_stock",sim,resident,build,115)))
	assert(bool(resident.get("_externally_assigned_job")),
		"Deciding to inspect requires real movement, never teleportation")
	assert(not bool(logic.call("apply_intent",code,"inspect_site",sim,resident,build,120)),
		"AI may not seize busy worker assigned to physical job")
	var history: Dictionary = logic.call("snapshot")
	assert((history["accepted_intents"] as Array).size()==3)
	assert(history["source"]=="REAL_OFFLINE_QWEN_IF_LOADED_OTHERWISE_WORLD_SIM_NO_FAKE_AI")
	var bridge: Node = game.get("local_ai")
	assert(bridge!=null and bridge.has_signal("npc_intent"))
	assert(bridge.has_method("ask_npc_intent"))
	assert(game.get("npc_intent_policy")!=null)
	print("PASS CAC LOCAL QWEN NPC AI INTENT: strict parsing, grounded food, independent energy, real travel and no economy cheats")
	game.queue_free()
	quit(0)
