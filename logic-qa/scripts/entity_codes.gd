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
	# _new_id() assigns a monotonic global number. Do not silently drop
	# trailing canonical components or accept a signed / overlong number,
	# as that can generate ambiguous public IDs for distinct entities.
	var parts: PackedStringArray = canonical_id.split("_")
	if parts.size() != 2 or parts[0].is_empty():
		return ""
	var canonical_prefix: String = parts[0]
	for index in range(canonical_prefix.length()):
		var cp: int = canonical_prefix.unicode_at(index)
		if not ((cp >= 97 and cp <= 122) or (cp >= 48 and cp <= 57)):
			return ""
	var suffix: String = parts[1]
	if suffix.is_empty() or suffix.length() > 8:
		return ""
	for index in range(suffix.length()):
		var digit: int = suffix.unicode_at(index)
		if digit < 48 or digit > 57:
			return ""
	var serial: int = int(suffix)
	if serial <= 0 or region.is_empty() or region.length() > 12:
		return ""
	for index in range(region.length()):
		var ch: int = region.unicode_at(index)
		var permitted: bool = (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or (ch >= 48 and ch <= 57) or ch == 45 or ch == 95
		if not permitted:
			return ""
	return "%s-%s-%08d" % [prefix(kind), region, serial]

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
