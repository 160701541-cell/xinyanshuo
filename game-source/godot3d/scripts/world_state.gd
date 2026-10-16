extends RefCounted
class_name WorldState
const Codes = preload("res://scripts/entity_codes.gd")
## Authoritative entity/material ledger. Render nodes are never the world state.
## Every manufactured entity must have a paid recipe and a traceable provenance.

const RECIPES := {
	"clay_brick": {"input": {"clay": 3, "water": 1, "firewood": 1}, "output": {"clay_brick": 2}, "ticks": 3, "tool": "kiln"},
	"timber_beam": {"input": {"log": 2}, "output": {"timber_beam": 1, "wood_scrap": 1}, "ticks": 2, "tool": "saw"},
	"rope": {"input": {"reeds": 3}, "output": {"rope": 1}, "ticks": 2, "tool": "spindle"},
	"paper": {"input": {"reeds": 4, "water": 1}, "output": {"paper": 2}, "ticks": 6, "tool": "paper_screen"},
	"lamp_oil": {"input": {"oil_seeds": 4}, "output": {"lamp_oil": 1}, "ticks": 4, "tool": "oil_press"},
	"thatch_panel": {"input": {"reeds": 5, "rope": 1}, "output": {"thatch_panel": 1}, "ticks": 2, "tool": "knife"},
	"ceramic_pot": {"input": {"clay": 4, "water": 1, "firewood": 2}, "output": {"ceramic_pot": 1}, "ticks": 4, "tool": "kiln"},
	"wooden_lantern": {"input": {"timber_beam": 1, "paper": 2, "rope": 1, "lamp_oil": 1}, "output": {"wooden_lantern": 1}, "ticks": 3, "tool": "carving_knife"},
	"mud_house": {"input": {"clay_brick": 24, "timber_beam": 8, "thatch_panel": 12, "stone": 16}, "output": {"mud_house": 1}, "ticks": 12, "tool": "building_site"},
	"cooked_meal": {"input": {"vegetables": 2, "water": 1, "firewood": 1}, "output": {"cooked_meal": 3}, "ticks": 20, "tool": "hearth"},
	"hearth": {"input": {"clay_brick": 4, "stone": 4}, "output": {"hearth": 1}, "ticks": 6, "tool": "mason_tools"},
	"wooden_bed": {"input": {"timber_beam": 2, "reeds": 8, "rope": 2}, "output": {"wooden_bed": 1}, "ticks": 12, "tool": "carpenter_bench"},
	"wooden_table": {"input": {"timber_beam": 2}, "output": {"wooden_table": 1}, "ticks": 8, "tool": "carpenter_bench"},
	"straw_mat": {"input": {"reeds": 5, "rope": 1}, "output": {"straw_mat": 1}, "ticks": 4, "tool": "weaving_mat"},
	"garden_pavilion": {"input": {"clay_brick": 8, "timber_beam": 4, "stone": 4}, "output": {"garden_pavilion": 1}, "ticks": 18, "tool": "joinery_tools"},
	"courtyard_moon_gate": {"input": {"clay_brick": 6, "stone": 2, "timber_beam": 1}, "output": {"courtyard_moon_gate": 1}, "ticks": 12, "tool": "mason_tools"},
	"courtyard_wall": {"input": {"clay_brick": 8, "stone": 2}, "output": {"courtyard_wall": 1}, "ticks": 8, "tool": "mason_tools"},
	"courtyard_flower_window": {"input": {"clay_brick": 8, "stone": 2, "timber_beam": 1}, "output": {"courtyard_flower_window": 1}, "ticks": 10, "tool": "mason_tools"}
}

const ASSEMBLED_RECIPES := ["mud_house", "hearth", "wooden_bed", "wooden_table", "straw_mat", "garden_pavilion", "courtyard_moon_gate", "courtyard_wall", "courtyard_flower_window"]

var next_id: int = 1
var tick: int = 0
var entities: Dictionary = {}
var inventories: Dictionary = {}
var jobs: Dictionary = {}
var ledger: Array[Dictionary] = []

func _new_id(prefix: String) -> String:
	var result := "%s_%06d" % [prefix, next_id]
	next_id += 1
	return result

func create_natural_resource(kind: String, amount: int, position: Vector3, biome: String) -> String:
	assert(amount > 0 and not biome.is_empty())
	var id := _new_id("resource")
	entities[id] = {"id": id, "kind": kind, "position": position, "owner": "nature", "durability": 100, "quantity": amount, "origin": "natural:" + biome, "parent": "", "state": "available"}
	Codes.annotate(entities[id])
	ledger.append({"tick": tick, "action": "natural_generation", "entity": id, "kind": kind, "amount": amount, "biome": biome})
	return id

func create_actor(name: String, position: Vector3) -> String:
	var id := _new_id("actor")
	entities[id] = {"id": id, "kind": "actor", "name": name, "position": position, "owner": id, "durability": 100, "origin": "population", "parent": "", "state": "idle"}
	Codes.annotate(entities[id])
	inventories[id] = {}
	return id

func quantity(owner: String, kind: String) -> int:
	return int(inventories.get(owner, {}).get(kind, 0))

func _credit(owner: String, kind: String, amount: int, reason: String) -> void:
	assert(amount > 0)
	if not inventories.has(owner):
		inventories[owner] = {}
	inventories[owner][kind] = quantity(owner, kind) + amount
	ledger.append({"tick": tick, "action": "credit", "owner": owner, "kind": kind, "amount": amount, "reason": reason})

func _debit(owner: String, kind: String, amount: int, reason: String) -> bool:
	if amount <= 0 or quantity(owner, kind) < amount:
		return false
	inventories[owner][kind] = quantity(owner, kind) - amount
	ledger.append({"tick": tick, "action": "debit", "owner": owner, "kind": kind, "amount": amount, "reason": reason})
	return true

func harvest(actor: String, source: String, amount: int) -> bool:
	if not entities.has(actor) or not entities.has(source) or amount <= 0:
		return false
	var resource: Dictionary = entities[source]
	if resource.get("owner") != "nature" or resource.get("state") != "available" or int(resource.get("quantity", 0)) < amount:
		return false
	resource["quantity"] = int(resource["quantity"]) - amount
	if int(resource["quantity"]) == 0:
		resource["state"] = "depleted"
	_credit(actor, String(resource["kind"]), amount, "harvest:" + source)
	ledger.append({"tick": tick, "action": "harvest", "actor": actor, "source": source, "amount": amount})
	return true

func transfer(from_owner: String, to_owner: String, kind: String, amount: int) -> bool:
	if amount <= 0 or not entities.has(from_owner) or not entities.has(to_owner):
		return false
	if not _debit(from_owner, kind, amount, "transfer:" + to_owner):
		return false
	_credit(to_owner, kind, amount, "transfer:" + from_owner)
	# Finished crafted items are physical entities, not just aggregate stacks.
	# Their owner/containment must follow the same real transfer of inventory.
	var remaining: int = amount
	for id in entities:
		if remaining <= 0:
			break
		var item: Dictionary = entities[id]
		if item.get("owner") == from_owner and item.get("kind") == kind and item.get("state") == "stored":
			item["owner"] = to_owner
			item["parent"] = to_owner
			remaining -= 1
	ledger.append({"tick": tick, "action": "transfer", "from": from_owner, "to": to_owner, "kind": kind, "amount": amount})
	return true

## Explicit consumption for a crafted object or stack. Kept items remain in ledger
## with state=consumed so crafted food cannot be re-used or placed twice.
func consume(owner: String, kind: String, amount: int, reason: String) -> bool:
	if amount <= 0 or not entities.has(owner) or not _debit(owner, kind, amount, "consumed:" + reason):
		return false
	var outstanding: int = amount
	for id in entities:
		if outstanding <= 0:
			break
		var item: Dictionary = entities[id]
		if item.get("owner") == owner and item.get("kind") == kind and item.get("state") == "stored":
			item["state"] = "consumed"
			item["parent"] = ""
			outstanding -= 1
	ledger.append({"tick": tick, "action": "consume", "owner": owner, "kind": kind, "amount": amount, "reason": reason})
	return true

func start_job(actor: String, recipe_id: String, tool: String, position: Vector3) -> String:
	if not entities.has(actor) or not RECIPES.has(recipe_id):
		return ""
	var recipe: Dictionary = RECIPES[recipe_id]
	if String(recipe["tool"]) != tool:
		return ""
	if tool == "hearth":
		var has_installed_hearth: bool = false
		for facility_id in entities:
			var station: Dictionary = entities[facility_id]
			if station.get("kind") == "hearth" and station.get("state") == "placed" and (station["position"] as Vector3).distance_to(position) <= 5.0:
				has_installed_hearth = true
				break
		if not has_installed_hearth:
			return ""
	var inputs: Dictionary = recipe["input"]
	for kind in inputs:
		if quantity(actor, String(kind)) < int(inputs[kind]):
			return ""
	var id := _new_id("job")
	var consumed_item_ids: Array[String] = []
	for kind in inputs:
		var debited: bool = _debit(actor, String(kind), int(inputs[kind]), "reserved:" + id)
		assert(debited)
		# Physically reserve previously crafted materials as components;
		# a finished brick must not remain in the free inventory after building.
		var remaining: int = int(inputs[kind])
		for entity_id in entities:
			if remaining <= 0:
				break
			var item: Dictionary = entities[entity_id]
			if item.get("kind") == kind and item.get("owner") == actor and item.get("state") == "stored":
				item["state"] = "reserved"
				item["parent"] = id
				item["used_in_job"] = id
				consumed_item_ids.append(String(entity_id))
				remaining -= 1
	jobs[id] = {"id": id, "actor": actor, "recipe": recipe_id, "tool": tool, "position": position, "remaining": int(recipe["ticks"]), "state": "working", "inputs": inputs.duplicate(true), "component_ids": consumed_item_ids}
	ledger.append({"tick": tick, "action": "start_job", "job": id, "actor": actor, "recipe": recipe_id})
	return id

func advance_time(steps: int = 1) -> void:
	assert(steps >= 0)
	for step in range(steps):
		tick += 1
		for id in jobs.keys():
			var job: Dictionary = jobs[id]
			if job["state"] != "working":
				continue
			job["remaining"] = int(job["remaining"]) - 1
			if int(job["remaining"]) > 0:
				continue
			job["state"] = "finished"
			var recipe: Dictionary = RECIPES[job["recipe"]]
			for kind in recipe["output"]:
				var amount: int = int(recipe["output"][kind])
				_credit(String(job["actor"]), String(kind), amount, "crafted:" + id)
				for n in range(amount):
					var entity_id := _new_id("item")
					entities[entity_id] = {"id": entity_id, "kind": kind, "position": job["position"], "owner": job["actor"], "durability": 100, "origin": "crafted:" + id, "parent": job["actor"], "state": "stored"}
					Codes.annotate(entities[entity_id])
					if job["recipe"] in ASSEMBLED_RECIPES:
						entities[entity_id]["component_ids"] = job.get("component_ids", []).duplicate()
						for component_id in job.get("component_ids", []):
							if entities.has(component_id):
								entities[component_id]["state"] = "installed"
								entities[component_id]["parent"] = entity_id
			for component_id in job.get("component_ids", []):
				if entities.has(component_id) and entities[component_id]["state"] == "reserved":
					entities[component_id]["state"] = "consumed"
			ledger.append({"tick": tick, "action": "finish_job", "job": id, "recipe": job["recipe"]})

func place_item(actor: String, kind: String, position: Vector3) -> String:
	if not entities.has(actor) or quantity(actor, kind) < 1:
		return ""
	var candidate := ""
	for id in entities:
		var item: Dictionary = entities[id]
		if item.get("kind") == kind and item.get("owner") == actor and item.get("state") == "stored":
			candidate = String(id)
			break
	if candidate.is_empty():
		return ""
	if not _debit(actor, kind, 1, "placed:" + candidate):
		return ""
	entities[candidate]["position"] = position
	entities[candidate]["state"] = "placed"
	entities[candidate]["parent"] = ""
	ledger.append({"tick": tick, "action": "place", "entity": candidate, "actor": actor})
	return candidate

## A house door is a named subassembly of the already paid-for house.
## Source is an installed crafted timber beam, not an invented free item.
func ensure_house_door(house_id: String) -> String:
	if not entities.has(house_id):
		return ""
	var house: Dictionary = entities[house_id]
	if house.get("kind") != "mud_house" or house.get("state") != "placed":
		return ""
	for id in entities:
		var entry: Dictionary = entities[id]
		if entry.get("kind") == "house_door" and entry.get("parent") == house_id and entry.get("state") in ["open", "closed"]:
			return String(id)
	var beam_id: String = ""
	for component_id in house.get("component_ids", []):
		if entities.has(component_id) and entities[component_id].get("kind") == "timber_beam" and entities[component_id].get("parent") == house_id and entities[component_id].get("state") == "installed":
			beam_id = String(component_id)
			break
	if beam_id.is_empty():
		return ""
	var id: String = _new_id("door")
	entities[id] = {
		"id": id, "kind": "house_door",
		"position": (house["position"] as Vector3) + Vector3(0, 0, 2.72),
		"owner": house["owner"], "durability": 100, "origin": house["origin"],
		"parent": house_id, "assembled_from": beam_id, "state": "closed"
	}
	Codes.annotate(entities[id])
	ledger.append({"tick": tick, "action": "install_house_door", "entity": id,
		"house": house_id, "source_component": beam_id})
	return id

func set_house_door_open(door_id: String, actor_id: String, open: bool) -> bool:
	if not entities.has(door_id) or not entities.has(actor_id):
		return false
	var door: Dictionary = entities[door_id]
	if door.get("kind") != "house_door" or door.get("state") not in ["closed", "open"]:
		return false
	if not entities.has(door.get("parent", "")) or entities[door["parent"]].get("state") != "placed":
		return false
	if entities[actor_id].get("kind") != "actor":
		return false
	if (entities[actor_id]["position"] as Vector3).distance_to(door["position"]) > 2.7:
		return false
	var new_state: String = "open" if open else "closed"
	if door["state"] == new_state:
		return false
	door["state"] = new_state
	ledger.append({"tick": tick, "action": "door_open" if open else "door_close",
		"entity": door_id, "actor": actor_id, "house": door["parent"]})
	return true

## A placed, already-crafted vessel can be loaned to household residents.
## Owner remains unchanged: a borrowed jar is NOT gifted or newly spawned.
func grant_pot_household_use(owner_actor: String, pot_id: String, house_id: String) -> bool:
	if not entities.has(owner_actor) or not entities.has(pot_id) or not entities.has(house_id):
		return false
	var pot: Dictionary = entities[pot_id]
	var house: Dictionary = entities[house_id]
	if pot.get("kind") != "ceramic_pot" or pot.get("owner") != owner_actor or house.get("kind") != "mud_house":
		return false
	if house.get("state") != "placed" or (pot["position"] as Vector3).distance_to(house["position"]) > 12.0:
		return false
	if pot.get("household_use") == house_id:
		return true # Grant is idempotent on restored legacy save files.
	if pot.get("state") not in ["placed", "carried"]:
		return false
	pot["household_use"] = house_id
	pot["visual_asset_id"] = "pot_00" # Model catalog ID, NOT a new entity.
	ledger.append({"tick":tick, "action":"owner_grants_household_use", "entity":pot_id, "owner":owner_actor, "house":house_id, "visual_asset_id":"pot_00"})
	return true

func _actor_may_borrow_pot(actor_id: String, pot: Dictionary) -> bool:
	if not entities.has(actor_id) or entities[actor_id].get("kind") != "actor":
		return false
	return pot.get("owner") == actor_id or (
		not String(pot.get("household_use", "")).is_empty()
		and entities[actor_id].get("residence") == pot.get("household_use")
	)

func take_placed_pot(actor_id: String, pot_id: String) -> bool:
	if not entities.has(pot_id) or not entities.has(actor_id):
		return false
	var pot: Dictionary = entities[pot_id]
	if pot.get("kind") != "ceramic_pot" or pot.get("state") != "placed" or not _actor_may_borrow_pot(actor_id, pot):
		return false
	for id in entities:
		if entities[id].get("carrier") == actor_id and entities[id].get("state") == "carried":
			return false
	if (pot["position"] as Vector3).distance_to(entities[actor_id]["position"]) > 2.6:
		return false
	pot["state"] = "carried"
	pot["position"] = entities[actor_id]["position"]
	pot["carrier"] = actor_id
	pot["parent"] = actor_id
	ledger.append({"tick": tick, "action": "pick_up_pot", "actor":actor_id, "entity":pot_id, "owner":pot["owner"]})
	return true

## Keep the carried object's authoritative world position synchronized to the
## real bone socket each frame; never leave it at the pickup coordinates.
## This is pose state, not an inventory mutation, so it does not spam the ledger.
func sync_carried_pot_position(actor_id: String, pot_id: String, position: Vector3) -> bool:
	if not entities.has(actor_id) or not entities.has(pot_id):
		return false
	var pot: Dictionary = entities[pot_id]
	if pot.get("state") != "carried" or pot.get("carrier") != actor_id or pot.get("kind") != "ceramic_pot":
		return false
	if not is_finite(position.x) or not is_finite(position.y) or not is_finite(position.z):
		return false
	if position.distance_to(entities[actor_id]["position"]) > 3.0:
		return false
	pot["position"] = position
	return true

func put_down_pot(actor_id: String, pot_id: String, position: Vector3) -> bool:
	if not entities.has(pot_id) or not entities.has(actor_id):
		return false
	var pot: Dictionary = entities[pot_id]
	if pot.get("kind") != "ceramic_pot" or pot.get("state") != "carried" or pot.get("carrier") != actor_id:
		return false
	if Vector2(position.x, position.z).length() > 500.0 or position.distance_to(entities[actor_id]["position"]) > 2.6:
		return false
	pot["state"] = "placed"
	pot["position"] = position
	pot["parent"] = ""
	pot.erase("carrier")
	ledger.append({"tick":tick, "action":"put_down_pot", "actor":actor_id, "entity":pot_id, "position":position})
	return true

func fill_carried_pot_from_spring(actor_id: String, pot_id: String, source_id: String) -> int:
	if not entities.has(actor_id) or not entities.has(pot_id) or not entities.has(source_id):
		return 0
	var pot: Dictionary = entities[pot_id]
	var source: Dictionary = entities[source_id]
	if pot.get("kind") != "ceramic_pot" or pot.get("state") != "carried" or pot.get("carrier") != actor_id:
		return 0
	if source.get("kind") != "water" or source.get("owner") != "nature" or source.get("state") != "available":
		return 0
	if (entities[actor_id]["position"] as Vector3).distance_to(source["position"]) > 2.8:
		return 0
	var can_take: int = mini(3 - quantity(pot_id,"water"), int(source.get("quantity",0)))
	if can_take <= 0:
		return 0
	if not harvest(actor_id, source_id, can_take):
		return 0
	assert(transfer(actor_id, pot_id, "water", can_take))
	ledger.append({"tick":tick,"action":"fill_pot","actor":actor_id,"entity":pot_id,"source":source_id,"amount":can_take})
	return can_take

func drink_carried_pot_water(actor_id: String, pot_id: String) -> bool:
	if not entities.has(actor_id) or not entities.has(pot_id):
		return false
	var pot: Dictionary = entities[pot_id]
	if pot.get("kind") != "ceramic_pot" or pot.get("state") != "carried" or pot.get("carrier") != actor_id:
		return false
	if not consume(pot_id, "water", 1, "drink_from_pot:" + actor_id):
		return false
	ledger.append({"tick":tick, "action":"actor_drinks_from_pot", "actor":actor_id,"entity":pot_id})
	return true

func get_placed_entities() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in entities:
		if entities[id].get("state") == "placed":
			result.append(entities[id])
	return result

func serialize() -> Dictionary:
	return {"version": 1, "next_id": next_id, "tick": tick, "entities": _encode(entities), "inventories": inventories.duplicate(true), "jobs": _encode(jobs), "ledger": _encode(ledger)}

func _encode(value: Variant) -> Variant:
	if value is Vector3:
		return {"__vec3": [value.x, value.y, value.z]}
	if value is Dictionary:
		var d: Dictionary = {}
		for k in value:
			d[k] = _encode(value[k])
		return d
	if value is Array:
		var a: Array = []
		for item in value:
			a.append(_encode(item))
		return a
	return value

func _decode(value: Variant) -> Variant:
	if value is Dictionary:
		if value.has("__vec3"):
			var a: Array = value["__vec3"]
			return Vector3(float(a[0]), float(a[1]), float(a[2]))
		var d: Dictionary = {}
		for k in value:
			d[k] = _decode(value[k])
		return d
	if value is Array:
		var a: Array = []
		for item in value:
			a.append(_decode(item))
		return a
	return value

func restore(data: Dictionary) -> void:
	assert(int(data.get("version", 0)) == 1)
	next_id = int(data["next_id"])
	tick = int(data["tick"])
	entities = _decode(data["entities"])
	# Backward-compatible, deterministic migration of v102-v107 player saves.
	# Never rewrite canonical ids or ownership: all links and recipes remain valid.
	for id in entities:
		if String(entities[id].get("public_code", "")).is_empty():
			Codes.annotate(entities[id])
	inventories = _decode(data["inventories"])
	jobs = _decode(data["jobs"])
	ledger.clear()
	for record in _decode(data["ledger"]):
		ledger.append(record)
