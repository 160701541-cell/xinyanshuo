extends SceneTree
## Real-Godot adversarial decoding tests: fail closed after intentional corruption.
const Reader = preload("res://scripts/craft_catalog_reader.gd")
var failures: int = 0
var cases: int = 0
func _initialize() -> void:
	var db := Reader.new()
	var fixture: String = FileAccess.get_file_as_string("res://data/material_graph.v1.json")
	var pristine: Variant = JSON.parse_string(fixture)
	if not pristine is Dictionary or not db.load_catalog("res://data/material_graph.v1.json"):
		_fail("VALID_FIXTURE_CANNOT_LOAD")
		quit(2)
		return
	var scenarios := [
		"invalid_json",
		"free_materials",
		"natural_resource_forgery",
		"unknown_unlock",
		"blueprint_mismatch",
		"cyclic_research",
		"cyclic_manufacturing",
		"negative_masses",
		"duplicate_ids",
		"illegal_world_authority",
	]
	for scenario in scenarios:
		var data: Dictionary = pristine.duplicate(true)
		match scenario:
			"free_materials":
				data["recipes"][0]["outputs"]["clay_slurry"] = 999
			"natural_resource_forgery":
				data["recipes"][0]["outputs"]["clay_soil"] = 1
			"unknown_unlock":
				data["recipes"][0]["unlock"] = {"mode":"mystery"}
			"blueprint_mismatch":
				data["recipes"][1]["unlock"] = {"mode":"blueprint", "id":"bp_roof_module"}
			"cyclic_research":
				data["research"][0]["requires"] = ["roof_joinery"]
				data["research"][3]["requires"] = ["clay_filtering"]
			"cyclic_manufacturing":
				data["recipes"].append({
					"id":"illegal_reverse_loop","name":"逆流","inputs":{"roof_module":1},
					"outputs":{"clay_slurry":1},"loss_g":41000,
					"work_minutes":1,"station":"mixing_tub",
					"energy_kj":0,"unlock":{"mode":"known"}
				})
			"negative_masses":
				data["items"][0]["mass_g"] = -5
			"duplicate_ids":
				data["items"].append(data["items"][0].duplicate(true))
			"illegal_world_authority":
				data["world_authority"] = "graphics_renderer"
		var sample: String = "this is not valid JSON" if scenario == "invalid_json" else JSON.stringify(data)
		var output: String = "user://craft_adversarial_" + scenario + ".json"
		var writer := FileAccess.open(output, FileAccess.WRITE)
		if writer == null:
			_fail("TEST_FIXTURE_NOT_WRITABLE:" + scenario)
			continue
		writer.store_string(sample)
		writer.close()
		var accepted: bool = db.load_catalog(output)
		cases += 1
		if accepted or db.error_code.is_empty() or not db.items.is_empty() or not db.recipes.is_empty() or not db.blueprints.is_empty():
			_fail("CATALOG_NOT_FAIL_CLOSED:" + scenario + ":" + db.error_code)
		if not db.load_catalog("res://data/material_graph.v1.json"):
			_fail("VALID_CATALOG_CANNOT_RECOVER_AFTER_FAILURE:" + scenario)
	if cases != 10 or failures != 0:
		push_error("CATALOG_ADVERSARIAL_FAILURES:%d" % failures)
		quit(3)
		return
	print("PASS_GODOT_4_4_1_FAIL_CLOSED_CRAFT_CATALOG_10_CORRUPTIONS")
	print("CORRUPT_ASSETS_NEVER_LEAK_INTO_READONLY_CATALOG")
	quit(0)
func _fail(reason: String) -> void:
	failures += 1
	printerr("FAIL_ADVERSARIAL_CATALOG:" + reason)
