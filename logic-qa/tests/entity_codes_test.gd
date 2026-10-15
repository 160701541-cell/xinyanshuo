extends SceneTree
## Actual Godot unit test for the audited entity_codes.gd module only.
const Codes = preload("res://scripts/entity_codes.gd")
var failures: Array[String] = []
var checks: int = 0

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("ENTITY_CODES_FAIL: ", message)

func _initialize() -> void:
	verify(Codes.make("actor_000100", "actor") == "NPC-HX-00000100", "stable actor ID")
	verify(Codes.make("item_000023", "ceramic_pot") == "GT-HX-00000023", "stable pot ID")
	verify(Codes.make("door_000003", "house_door") == "MN-HX-00000003", "stable door ID")
	verify(Codes.make("item_000125", "clay") == "ZY-HX-00000125", "resource namespace")
	verify(Codes.make("item_000002", "unknown", "YZ") == "WP-YZ-00000002", "unknown kind and explicit region")
	verify(Codes.make("actor_0", "actor").is_empty(), "zero ID refused")
	verify(Codes.make("actor_unknown", "actor").is_empty(), "non-numeric ID refused")
	verify(Codes.make("actor_000001", "actor", "").is_empty(), "empty region refused")
	# Red-team invalid IDs. A malformed canonical ID must not be able to
	# receive an apparently valid, potentially colliding public identity.
	verify(Codes.make("actor_1_extra", "actor").is_empty(), "reject trailing canonical segment")
	verify(Codes.make("_100", "actor").is_empty(), "reject missing canonical type")
	verify(Codes.make("actor_+1", "actor").is_empty(), "reject signed numeric ID")
	verify(Codes.make("actor_999999999", "actor").is_empty(), "reject overflow beyond eight digit code")
	verify(Codes.make("actor_000099", "actor", "HN ZJ").is_empty(), "reject spaces in region")
	verify(Codes.make("actor_000099", "actor", "Q/../../").is_empty(), "reject slash in region")
	verify(Codes.make("actor_000099", "actor", "HN-ZJ") == "NPC-HN-ZJ-00000099", "retain hyphenated region")
	verify(Codes.make("actor_000099", "actor", "1234567890123").is_empty(), "reject oversized region")
	var existing := {"id": "actor_000007", "kind": "actor", "public_code": "NPC-HX-99999999"}
	verify(Codes.annotate(existing) == "NPC-HX-99999999", "existing public ID retained")
	verify(String(existing.get("public_code", "")) == "NPC-HX-99999999", "existing public ID not rewritten")
	var fresh := {"id": "item_000008", "kind": "stone"}
	verify(Codes.annotate(fresh) == "ZY-HX-00000008", "new ID annotated")
	verify(fresh.get("region_id") == "HX", "default region stored")
	print("ENTITY_CODES_TESTS checks=", checks, " failed=", failures.size())
	if failures.is_empty():
		print("PASS CANG LAN ENTITY CODES REAL GODOT")
		quit(0)
	else:
		quit(1)
