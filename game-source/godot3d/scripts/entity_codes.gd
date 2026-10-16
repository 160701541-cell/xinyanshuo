extends RefCounted
class_name CanglanEntityCodes
## Human-readable stable identity. The canonical WorldState id is immutable.
## HX is the H e X i valley REGION namespace, never the actor's profession.
## Legacy entity IDs share a single monotonic global numeric allocation.
const REGION: String = "HX"

static func prefix(kind: String) -> String:
	match kind:
		"actor":
			return "NPC"
		"ceramic_pot":
			return "GT"
		"mud_house":
			return "FZ"
		"house_door":
			return "MN"
		"living_tree":
			return "SM"
		"water", "clay", "stone", "terrain_soil", "firewood", "vegetables", "log", "reeds", "oil_seeds":
			return "ZY"
		_:
			return "WP"

static func make(canonical_id: String, kind: String, region: String = REGION) -> String:
	# canonical id is actor_000100, resource_000002, item_000023 or door_...
	var suffix: String = canonical_id.get_slice("_", 1)
	if not suffix.is_valid_int() or int(suffix) <= 0:
		return ""
	if region.is_empty() or region.length() > 12:
		return ""
	return "%s-%s-%08d" % [prefix(kind), region, int(suffix)]

static func code_of(entity: Dictionary) -> String:
	if not String(entity.get("public_code", "")).is_empty():
		return String(entity["public_code"])
	return make(String(entity.get("id", "")), String(entity.get("kind", "")), String(entity.get("region_id", REGION)))

static func annotate(entity: Dictionary) -> String:
	var generated: String = code_of(entity)
	if generated.is_empty():
		return ""
	entity["public_code"] = generated
	if not entity.has("region_id"):
		entity["region_id"] = REGION
	return generated
