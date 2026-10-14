extends SceneTree
const Reader = preload("res://scripts/craft_catalog_reader.gd")
func _initialize() -> void:
	var db = Reader.new()
	if not db.load_catalog("res://data/material_graph.v1.json"):
		push_error("GRAPH_IMPORT_FAIL: " + db.error_code)
		quit(1)
		return
	if db.items.size() != 24 or db.recipes.size() != 14:
		push_error("GRAPH_ENTRY_MISMATCH")
		quit(2)
		return
	var chains: Array[String] = db.consumers_of("clay_slurry")
	if not chains.has("clay_settling") or not chains.has("ram_wall_core"):
		push_error("GRAPH_HYPEREDGE_MISSING")
		quit(3)
		return
	if not db.producers_of("roof_module").has("assemble_roof_module"):
		push_error("GRAPH_PRODUCER_MISSING")
		quit(4)
		return
	var blocked: Dictionary = db.inspect_recipe("fire_roof_tile",[],[],[],{})
	if bool(blocked.get("ok",true)) or blocked["missing"].size() < 3:
		push_error("GRAPH_UNLOCK_BYPASS")
		quit(5)
		return
	var allowed: Dictionary = db.inspect_recipe("fire_roof_tile",
		["ceramics_1"],["bp_kiln_arch"],["kiln"],{"tile_blank":1,"firewood":1})
	if not bool(allowed.get("ok",false)) or allowed.get("world_effect") != "none_only_WorldState_may_commit":
		push_error("GRAPH_READONLY_PROTOCOL_FAILED")
		quit(6)
		return
	print("PASS_GODOT_4_4_1_ISOLATED_ITEM_GRAPH_READONLY")
	print("NOT_WORLDSTATE_INTEGRATED_OR_ANDROID_APPROVED")
	quit(0)
