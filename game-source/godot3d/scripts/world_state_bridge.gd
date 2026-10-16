extends RefCounted
## CAC-3D-002: explicit adapter to OLD real WorldState, not a visual replacement.
## NPC visuals may propose movement, but canonical id, owner and stock remain
## in the original serialized authoritative state. No free items are credited.
const MAX_METRES_PER_SECOND: float = 1.7

static func sync_actor(world: RefCounted,canonical_id: String,at: Vector3,
		seconds_elapsed: float) -> bool:
	if world == null or seconds_elapsed <= 0.0:
		return false
	if not is_finite(at.x) or not is_finite(at.y) or not is_finite(at.z):
		return false
	var entities: Dictionary = world.get("entities")
	if not entities.has(canonical_id):
		return false
	var actor: Dictionary = entities[canonical_id]
	if actor.get("kind") != "actor":
		return false
	var before: Vector3 = actor.get("position",at)
	var max_distance: float = MAX_METRES_PER_SECOND*seconds_elapsed+0.55
	if Vector2(before.x,before.z).distance_to(Vector2(at.x,at.z))>max_distance:
		return false
	actor["position"] = at
	var ledger: Array = world.get("ledger")
	ledger.append({"tick":int(world.get("tick")),"action":"actor_movement",
		"entity":canonical_id,"from":before,"to":at})
	return true

static func actor_public_code(world: RefCounted,canonical_id: String) -> String:
	var entities: Dictionary = world.get("entities")
	if not entities.has(canonical_id):
		return ""
	return String(entities[canonical_id].get("public_code",""))

static func identity_count(world: RefCounted) -> int:
	var entities: Dictionary = world.get("entities")
	var result: int = 0
	for id in entities:
		if entities[id].get("kind")=="actor":
			result+=1
	return result
