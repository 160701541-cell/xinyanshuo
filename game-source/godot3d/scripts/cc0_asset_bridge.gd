extends RefCounted
## Import ONLY real CC0 Kenney GLBs and Quaternius free modular glTF models.
## This never generates a house, adds resources, changes construction time or
## replaces citizen identities; it only decorates EXISTING 3D world geometry.
const PIECES := {
	"tree_log":"res://assets/free_cc0/kenney/3d/castle/tree-log.glb",
	"stone_cluster":"res://assets/free_cc0/kenney/3d/castle/rocks-small.glb",
	"tree_oak":"res://assets/free_cc0/kenney/3d/nature/tree_oak.glb",
	"wood_fence":"res://assets/free_cc0/kenney/3d/castle/wall-narrow-wood-fence.glb",
	"stone_steps":"res://assets/free_cc0/kenney/3d/castle/stairs-stone.glb",
	"wood_door":"res://assets/free_cc0/kenney/3d/castle/door.glb",
	"wood_bridge":"res://assets/free_cc0/kenney/3d/nature/bridge_wood.glb",
	"plaster_wall":"res://assets/free_cc0/quaternius/glTF/Wall_Plaster_Straight.gltf",
	"clay_tiled_roof":"res://assets/free_cc0/quaternius/glTF/Roof_2x4_RoundTile.gltf",
	"storage_crate":"res://assets/free_cc0/quaternius/glTF/Prop_Crate.gltf",
	"civilian_rig":"res://assets/free_cc0/quaternius_humanoid/public/assets/character.glb",
	"guard_rig":"res://assets/free_cc0/quaternius_knight/public/models/knight.glb"
}
const MAX_RENDER_DISTANCE: float = 65.0
const DEFAULT_MAX_SCALE: float = 1.6

static func is_installed(role: String) -> bool:
	if not PIECES.has(role):
		return false
	return ResourceLoader.exists(String(PIECES[role]))

static func instantiate_asset(role: String,parent: Node3D,local_pos: Vector3,
		local_scale: Vector3 = Vector3.ONE) -> Node3D:
	if parent==null or not is_installed(role):
		return null
	var resource: Resource = load(String(PIECES[role]))
	if not (resource is PackedScene):
		push_warning("CC0 asset not imported as a 3D PackedScene: "+role)
		return null
	if local_scale.x<=0.0 or local_scale.y<=0.0 or local_scale.z<=0.0:
		return null
	if local_scale.length() > 12.0:
		push_error("CC0 imported model scale too large; needs QA")
		return null
	var built: Node = (resource as PackedScene).instantiate()
	if not (built is Node3D):
		built.queue_free()
		return null
	var node: Node3D = built
	node.name = "RealCC0_" + role
	node.position = local_pos
	node.scale = local_scale
	node.set_meta("asset_origin", "LICENSE_VERIFIED_EXISTING_CC0")
	node.set_meta("asset_source", "kenney" if String(PIECES[role]).contains("/kenney/") else "quaternius")
	node.set_meta("original_cc0_asset",true)
	node.set_meta("not_generated_by_ai",true)
	node.set_meta("asset_key", role)
	node.set_meta("asset_path", String(PIECES[role]))
	# The caller's site/material inventory and collision remain authoritative.
	# Imported art NEVER carries the right to create goods or alter world state.
	parent.add_child(node)
	return node

static func get_import_status() -> Dictionary:
	var installed: Array[String] = []
	var missing: Array[String] = []
	for key in PIECES:
		if is_installed(String(key)):
			installed.append(String(key))
		else:
			missing.append(String(key))
	return {"provider":"Existing free licensed CC0 assets",
		"kenney_quaternius_installed":installed,
		"missing":missing,"no_ai_generated_models":true,
		"original_apk_hot_updated":false}
