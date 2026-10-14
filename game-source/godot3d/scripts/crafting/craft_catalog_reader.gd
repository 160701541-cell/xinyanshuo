extends RefCounted
## Read-only crafting hypergraph query adapter for the ORIGINAL Godot 4.4.1 game.
## Never writes WorldState, saved inventories, jobs, research or player blueprints.
## Import requires original project's independent content manifest + actual QA.
const CANONICAL_PATH: String = "res://data/craft/material_graph.v1.json"
var items: Dictionary = {}
var recipes: Dictionary = {}
var research: Dictionary = {}
var blueprints: Dictionary = {}
var error_code: String = ""

func load_catalog(path: String = CANONICAL_PATH) -> bool:
	items.clear()
	recipes.clear()
	research.clear()
	blueprints.clear()
	error_code = ""
	if not FileAccess.file_exists(path):
		error_code = "CATALOG_NOT_FOUND"
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		error_code = "INVALID_JSON"
		return false
	var root: Dictionary = parsed
	if int(root.get("schema", 0)) != 1 or String(root.get("status", "")) != "design_candidate_not_integrated":
		error_code = "SCHEMA_OR_RELEASE_CONTRACT"
		return false
	for field in ["items", "recipes", "research", "blueprints"]:
		var records: Variant = root.get(field)
		if not records is Array:
			error_code = "MISSING_" + field.to_upper()
			return false
		var target: Dictionary = {}
		for entry in records:
			if not entry is Dictionary or String(entry.get("id", "")).is_empty():
				error_code = "BAD_" + field.to_upper()
				return false
			var key: String = String(entry["id"])
			if target.has(key):
				error_code = "DUPLICATE_" + field.to_upper()
				return false
			target[key] = entry
		match field:
			"items":
				items = target
			"recipes":
				recipes = target
			"research":
				research = target
			"blueprints":
				blueprints = target
	if items.is_empty() or recipes.is_empty():
		error_code = "EMPTY_CRAFT_GRAPH"
		return false
	for recipe_id in recipes:
		var recipe: Dictionary = recipes[recipe_id]
		var incoming: int = 0
		var outgoing: int = 0
		var inputs: Variant = recipe.get("inputs")
		var outputs: Variant = recipe.get("outputs")
		if not inputs is Dictionary or not outputs is Dictionary:
			error_code = "BAD_RECIPE_MAP"
			return false
		for item_id in inputs:
			if not items.has(item_id) or int(inputs[item_id]) <= 0:
				error_code = "RECIPE_UNKNOWN_INPUT"
				return false
			incoming += int(items[item_id].get("mass_g", -1)) * int(inputs[item_id])
		for item_id in outputs:
			if not items.has(item_id) or int(outputs[item_id]) <= 0:
				error_code = "RECIPE_UNKNOWN_OUTPUT"
				return false
			outgoing += int(items[item_id].get("mass_g", -1)) * int(outputs[item_id])
		if incoming != outgoing + int(recipe.get("loss_g", -1)):
			error_code = "RECIPE_MASS_VIOLATION"
			return false
	return true

func consumers_of(item_id: String) -> Array[String]:
	var found: Array[String] = []
	if not items.has(item_id):
		return found
	for key in recipes.keys():
		var recipe: Dictionary = recipes[key]
		if recipe.get("inputs", {}).has(item_id):
			found.append(String(key))
	found.sort()
	return found

func producers_of(item_id: String) -> Array[String]:
	var found: Array[String] = []
	if not items.has(item_id):
		return found
	for key in recipes.keys():
		var recipe: Dictionary = recipes[key]
		if recipe.get("outputs", {}).has(item_id):
			found.append(String(key))
	found.sort()
	return found

func inspect_recipe(recipe_id: String, acquired_research: Array[String],
		acquired_blueprints: Array[String], stations: Array[String],
		stock: Dictionary) -> Dictionary:
	if not recipes.has(recipe_id):
		return {"ok": false, "missing": ["unknown_recipe"], "world_effect": "none"}
	var row: Dictionary = recipes[recipe_id]
	var missing: Array[String] = []
	var unlock: Dictionary = row.get("unlock", {})
	var mode: String = String(unlock.get("mode", ""))
	var key: String = String(unlock.get("id", ""))
	if mode == "research" and not acquired_research.has(key):
		missing.append("research:" + key)
	if mode == "blueprint":
		if not acquired_blueprints.has(key):
			missing.append("blueprint:" + key)
		var required_research: String = String(unlock.get("research", ""))
		if not required_research.is_empty() and not acquired_research.has(required_research):
			missing.append("research:" + required_research)
	if not stations.has(String(row.get("station", ""))):
		missing.append("station:" + String(row.get("station", "")))
	var inputs: Dictionary = row.get("inputs", {})
	for item_id in inputs:
		if int(stock.get(item_id, 0)) < int(inputs[item_id]):
			missing.append("stock:" + String(item_id))
	return {
		"ok": missing.is_empty(),
		"missing": missing,
		"preview_inputs": inputs.duplicate(true),
		"preview_outputs": row.get("outputs", {}).duplicate(true),
		"work_minutes": int(row.get("work_minutes", 0)),
		"world_effect": "none_only_WorldState_may_commit"
	}
