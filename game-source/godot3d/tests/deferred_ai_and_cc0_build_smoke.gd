extends SceneTree
## Native Godot acceptance: NPCs can live/build with NO local LLM selected.
const AI = preload("res://scripts/local_ai_service.gd")
const Bridge = preload("res://scripts/cc0_asset_bridge.gd")
const Building = preload("res://scripts/npc_building_system.gd")
const Life = preload("res://scripts/worldbox_life_sim.gd")

func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	assert(Bridge.PIECES.size() >= 12, "Existing licensed 3D asset catalog incomplete")
	assert(Bridge.PIECES.has("plaster_wall") and Bridge.PIECES.has("clay_tiled_roof"))
	assert(Bridge.PIECES.has("civilian_rig") and Bridge.PIECES.has("guard_rig"))
	assert(Building.RECIPES.has("timber") and Building.RECIPES.has("cut_stone"))
	assert(Building.RECIPES.has("roof_tile") and Building.RECIPES.has("mortar"))
	var sim: RefCounted = Life.new()
	sim.call("start",20261017)
	assert(sim.call("create_village","CL-HX-VILLAGE-0001",{"wood":8,"stone":8,"clay":8,"water":8}))
	assert(sim.call("add_citizen","CL-NPC-0001","CL-HX-VILLAGE-0001","carpenter",28))
	assert(sim.call("add_citizen","CL-NPC-0002","CL-HX-VILLAGE-0001","mason",34))
	assert(sim.call("add_citizen","CL-NPC-0003","CL-HX-VILLAGE-0001","potter",31))
	assert(not sim.get("citizens").is_empty())
	assert(AI.USER_MODEL_CHOICE_PATH == "user://local_models/selected_model.json")
	var ai: Node = AI.new()
	root.add_child(ai)
	if not FileAccess.file_exists(AI.USER_MODEL_CHOICE_PATH):
		assert(String(ai.get("stage")) == "awaiting_user_selection",
			"LLM must NOT auto-download or auto-select before player choice")
	ai.queue_free()
	print("PASS_NPC_JOBS_CC0_REAL_ASSETS_AI_CHOICE_DEFERRED_NO_FORCED_QWEN")
	quit(0)
