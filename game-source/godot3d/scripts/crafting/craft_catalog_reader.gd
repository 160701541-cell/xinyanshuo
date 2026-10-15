extends RefCounted
## Fail-closed, transactional READ-ONLY catalog decoder.
## Zero permissions to grant knowledge, assets, crafting jobs or inventory.
## Gameplay remains authoritative in the existing WorldState instance.
const CANONICAL_PATH: String = "res://data/craft/material_graph.v1.json"
const STAGES := ["raw", "intermediate", "product", "byproduct", "construction"]
const MODES := ["known", "research", "blueprint"]
const MAX_ITEMS: int = 20000
const MAX_RECIPES: int = 60000
var items: Dictionary = {}
var recipes: Dictionary = {}
var research: Dictionary = {}
var blueprints: Dictionary = {}
var producers: Dictionary = {}
var consumers: Dictionary = {}
var error_code: String = ""

func _reset() -> void:
	items.clear()
	recipes.clear()
	research.clear()
	blueprints.clear()
	producers.clear()
	consumers.clear()

func _bad(message: String) -> bool:
	_reset()
	error_code = message
	return false

func _valid_id(value: Variant) -> bool:
	if not value is String or value.length() < 2 or value.length() > 64:
		return false
	var allowed := "abcdefghijklmnopqrstuvwxyz0123456789_"
	var first := "abcdefghijklmnopqrstuvwxyz"
	if first.find(value.substr(0, 1)) < 0:
		return false
	for index in range(value.length()):
		if allowed.find(value.substr(index, 1)) < 0:
			return false
	return true

func _nonnegative_int(value: Variant) -> bool:
	return value is int and value >= 0 and value <= 1000000000

func _positive_int(value: Variant) -> bool:
	return _nonnegative_int(value) and value > 0

func _has_cycle(nodes: Dictionary, dependencies: Dictionary) -> bool:
	# Kahn ordering: O(V + E), no recursive stack or indefinite exploration.
	var indegree: Dictionary = {}
	var outgoing: Dictionary = {}
	for key in nodes:
		indegree[key] = 0
		outgoing[key] = {}
	for key in dependencies:
		if not indegree.has(key):
			return true
		var unique: Dictionary = {}
		for dep in dependencies[key]:
			if not indegree.has(dep) or dep == key:
				return true
			unique[dep] = true
		indegree[key] = unique.size()
		for dep in unique:
			outgoing[dep][key] = true
	var queue: Array[String] = []
	for key in indegree:
		if int(indegree[key]) == 0:
			queue.append(String(key))
	var consumed: int = 0
	var index: int = 0
	while index < queue.size():
		var key: String = queue[index]
		index += 1
		consumed += 1
		for successor in outgoing[key]:
			indegree[successor] = int(indegree[successor]) - 1
			if int(indegree[successor]) == 0:
				queue.append(String(successor))
	return consumed != nodes.size()

func load_catalog(path: String = CANONICAL_PATH) -> bool:
	_reset()
	error_code = ""
	if not FileAccess.file_exists(path):
		return _bad("CATALOG_NOT_FOUND")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return _bad("INVALID_JSON")
	var root: Dictionary = parsed
	if root.get("schema") != 1 or root.get("status") != "design_candidate_not_integrated":
		return _bad("SCHEMA_OR_RELEASE_CONTRACT")
	if root.get("world_authority") != "existing_WorldState_only":
		return _bad("WORLD_AUTHORITY_VIOLATION")
	var assembled: Dictionary = {}
	for field in ["items", "recipes", "research", "blueprints"]:
		var records: Variant = root.get(field)
		if not records is Array or records.is_empty():
			return _bad("MISSING_" + field.to_upper())
		var cap: int = MAX_ITEMS if field == "items" else MAX_RECIPES
		if records.size() > cap:
			return _bad("OVERSIZE_" + field.to_upper())
		var table: Dictionary = {}
		for entry in records:
			if not entry is Dictionary:
				return _bad("BAD_" + field.to_upper())
			var identifier: Variant = entry.get("id")
			if not _valid_id(identifier):
				return _bad("BAD_" + field.to_upper() + "_ID")
			if table.has(identifier):
				return _bad("DUPLICATE_" + field.to_upper())
			table[identifier] = entry
		assembled[field] = table
	var new_items: Dictionary = assembled["items"]
	var new_recipes: Dictionary = assembled["recipes"]
	var new_research: Dictionary = assembled["research"]
	var new_blueprints: Dictionary = assembled["blueprints"]
	for item_id in new_items:
		var item: Dictionary = new_items[item_id]
		if not STAGES.has(item.get("stage")) or not _positive_int(item.get("mass_g")):
			return _bad("INVALID_ITEM_STAGE_OR_MASS")
		if String(item.get("name", "")).strip_edges().is_empty() or String(item.get("origin", "")).is_empty():
			return _bad("INVALID_ITEM_IDENTITY")
	var research_edges: Dictionary = {}
	for research_id in new_research:
		var tech: Dictionary = new_research[research_id]
		var prior: Variant = tech.get("requires")
		var observations: Variant = tech.get("observations")
		if not prior is Array or not observations is Array or observations.is_empty():
			return _bad("INVALID_RESEARCH_EVIDENCE")
		if not _positive_int(tech.get("work_minutes")):
			return _bad("INVALID_RESEARCH_WORK")
		var seen: Dictionary = {}
		for dep in prior:
			if not new_research.has(dep) or seen.has(dep):
				return _bad("INVALID_RESEARCH_DEPENDENCY")
			seen[dep] = true
		research_edges[research_id] = seen
		var evidence_seen: Dictionary = {}
		for observation in observations:
			if not _valid_id(observation) or evidence_seen.has(observation):
				return _bad("INVALID_RESEARCH_OBSERVATION")
			evidence_seen[observation] = true
		var costs: Variant = tech.get("cost")
		if not costs is Dictionary or costs.is_empty():
			return _bad("INVALID_RESEARCH_COST")
		for cost_id in costs:
			if not _valid_id(cost_id) or not _positive_int(costs[cost_id]):
				return _bad("INVALID_RESEARCH_COST")
	if _has_cycle(new_research, research_edges):
		return _bad("RESEARCH_CYCLE")
	for blueprint_id in new_blueprints:
		var blueprint: Dictionary = new_blueprints[blueprint_id]
		var reveals: Variant = blueprint.get("reveals")
		if not reveals is Array or reveals.is_empty():
			return _bad("INVALID_BLUEPRINT")
		var seen: Dictionary = {}
		for recipe_id in reveals:
			if not new_recipes.has(recipe_id) or seen.has(recipe_id):
				return _bad("INVALID_BLUEPRINT_RECIPE")
			seen[recipe_id] = true
	var new_producers: Dictionary = {}
	var new_consumers: Dictionary = {}
	var material_edges: Dictionary = {}
	for item_id in new_items:
		new_producers[item_id] = []
		new_consumers[item_id] = []
		material_edges[item_id] = {}
	for recipe_id in new_recipes:
		var recipe: Dictionary = new_recipes[recipe_id]
		var inputs: Variant = recipe.get("inputs")
		var outputs: Variant = recipe.get("outputs")
		if not inputs is Dictionary or inputs.is_empty() or not outputs is Dictionary or outputs.is_empty():
			return _bad("BAD_RECIPE_MAP")
		if not _nonnegative_int(recipe.get("loss_g")) or not _positive_int(recipe.get("work_minutes")):
			return _bad("BAD_RECIPE_TIME_OR_LOSS")
		if not _nonnegative_int(recipe.get("energy_kj")) or not _valid_id(recipe.get("station")):
			return _bad("BAD_RECIPE_ENERGY_OR_STATION")
		var incoming: int = 0
		var outgoing: int = 0
		for item_id in inputs:
			if not new_items.has(item_id) or not _positive_int(inputs[item_id]):
				return _bad("RECIPE_UNKNOWN_INPUT")
			incoming += int(new_items[item_id]["mass_g"]) * int(inputs[item_id])
		for item_id in outputs:
			if not new_items.has(item_id) or not _positive_int(outputs[item_id]):
				return _bad("RECIPE_UNKNOWN_OUTPUT")
			if inputs.has(item_id):
				return _bad("RECIPE_SELF_REGENERATION")
			if new_items[item_id]["stage"] == "raw":
				return _bad("RECIPE_FABRICATES_NATURAL_MATERIAL")
			outgoing += int(new_items[item_id]["mass_g"]) * int(outputs[item_id])
		if incoming != outgoing + int(recipe["loss_g"]):
			return _bad("RECIPE_MASS_VIOLATION")
		if String(recipe["station"]) == "kiln" and (int(recipe["energy_kj"]) == 0 or not inputs.has("firewood")):
			return _bad("FREE_KILN_HEAT")
		var unlock: Variant = recipe.get("unlock")
		if not unlock is Dictionary or not MODES.has(unlock.get("mode")):
			return _bad("UNKNOWN_UNLOCK_MODE")
		if unlock["mode"] == "known":
			if unlock.size() != 1:
				return _bad("KNOWN_UNLOCK_HAS_EXTRA_PREREQUISITES")
		elif unlock["mode"] == "research":
			if not new_research.has(unlock.get("id")):
				return _bad("RECIPE_MISSING_RESEARCH")
		else:
			var blueprint_id: Variant = unlock.get("id")
			if not new_blueprints.has(blueprint_id):
				return _bad("RECIPE_MISSING_BLUEPRINT")
			var sheet: Dictionary = new_blueprints[blueprint_id]
			if not sheet["reveals"].has(recipe_id):
				return _bad("RECIPE_NOT_REVEALED_BY_BLUEPRINT")
			if unlock.has("research") and not new_research.has(unlock["research"]):
				return _bad("RECIPE_MISSING_RESEARCH")
		for item_id in inputs:
			new_consumers[item_id].append(String(recipe_id))
		for item_id in outputs:
			new_producers[item_id].append(String(recipe_id))
			for source_id in inputs:
				material_edges[item_id][source_id] = true
	if _has_cycle(new_items, material_edges):
		return _bad("MATERIAL_CYCLE")
	for item_id in new_items:
		if new_items[item_id]["stage"] != "raw" and new_producers[item_id].is_empty():
			return _bad("ORPHAN_MANUFACTURED_ITEM")
		new_producers[item_id].sort()
		new_consumers[item_id].sort()
	# All validation passed: assign fully connected catalog atomically.
	items = new_items
	recipes = new_recipes
	research = new_research
	blueprints = new_blueprints
	producers = new_producers
	consumers = new_consumers
	return true

func consumers_of(item_id: String) -> Array[String]:
	var result: Array[String] = []
	for value in consumers.get(item_id, []):
		result.append(String(value))
	return result

func producers_of(item_id: String) -> Array[String]:
	var result: Array[String] = []
	for value in producers.get(item_id, []):
		result.append(String(value))
	return result

func inspect_recipe(recipe_id: String, acquired_research: Array[String],
		acquired_blueprints: Array[String], stations: Array[String],
		stock: Dictionary) -> Dictionary:
	if not recipes.has(recipe_id):
		return {"ok": false, "missing": ["unknown_recipe"], "world_effect": "none"}
	var recipe: Dictionary = recipes[recipe_id]
	var missing: Array[String] = []
	var unlock: Dictionary = recipe["unlock"]
	var mode: String = String(unlock["mode"])
	var key: String = String(unlock.get("id", ""))
	if mode == "research" and not acquired_research.has(key):
		missing.append("research:" + key)
	elif mode == "blueprint":
		if not acquired_blueprints.has(key):
			missing.append("blueprint:" + key)
		var required: String = String(unlock.get("research", ""))
		if not required.is_empty() and not acquired_research.has(required):
			missing.append("research:" + required)
	elif mode != "known":
		missing.append("unrecognized_recipe_unlock")
	var station: String = String(recipe["station"])
	if not stations.has(station):
		missing.append("station:" + station)
	var inputs: Dictionary = recipe["inputs"]
	for item_id in inputs:
		if int(stock.get(item_id, 0)) < int(inputs[item_id]):
			missing.append("stock:" + String(item_id))
	return {
		"ok": missing.is_empty(),
		"missing": missing,
		"preview_inputs": inputs.duplicate(true),
		"preview_outputs": recipe["outputs"].duplicate(true),
		"work_minutes": int(recipe["work_minutes"]),
		"world_effect": "none_only_WorldState_may_commit"
	}
