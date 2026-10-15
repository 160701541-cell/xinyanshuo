extends Node3D
class_name CanglanHD2DActor
## 3D world coordinates + an authentic 2D sprite; never creates actors,
## inventory, collision or a second simulation. This is an optional VIEW.
## Source art metadata is held beside each imported PNG.
const HERO_IMAGE := "res://assets/production/hd2d/han_male.png"
const CITIZEN_IMAGE := "res://assets/production/hd2d/han_female.png"

var sprite: Sprite3D
var foot_shadow: MeshInstance3D
var sprite_height: float = 1.72
var is_moving: bool = false
var motion_phase: float = 0.0
var actor_id: String = ""

static func has_authored_sprite(is_player: bool) -> bool:
	var image_path: String = HERO_IMAGE if is_player else CITIZEN_IMAGE
	return ResourceLoader.exists(image_path, "Texture2D")

static func create_for(entity: Dictionary, is_player: bool = false) -> CanglanHD2DActor:
	if not entity.has("id"):
		return null
	var image_path: String = HERO_IMAGE if is_player else CITIZEN_IMAGE
	if not ResourceLoader.exists(image_path, "Texture2D"):
		return null
	var img: Resource = load(image_path)
	if not img is Texture2D:
		return null
	var root := CanglanHD2DActor.new()
	root.actor_id = String(entity["id"])
	root.set_meta("entity_id", root.actor_id)
	root.set_meta("render_source", "licensed_cc0_hd2d_character")
	root.name = "HD2D_" + root.actor_id.replace(":", "_")
	root._attach_visual(img as Texture2D)
	return root

func _attach_visual(texture: Texture2D) -> void:
	var h: int = texture.get_height()
	assert(h > 0 and texture.get_width() > 0)
	# Sprite is centred in its own plane at half human height; boots align to Y=0.
	sprite = Sprite3D.new()
	sprite.name = "CameraFacing2DPerson"
	sprite.texture = texture
	sprite.pixel_size = sprite_height / float(h)
	sprite.position = Vector3(0, sprite_height * 0.5, 0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.shaded = true
	sprite.no_depth_test = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	# Real world-contact shadow, not an ungrounded sticker on a building.
	foot_shadow = MeshInstance3D.new()
	foot_shadow.name = "WorldContactShadow"
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.85, 0.46)
	foot_shadow.mesh = plane
	foot_shadow.position.y = 0.014
	foot_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded,blend_mix,depth_draw_never,cull_disabled; void fragment(){float r=length(UV-vec2(0.5))*2.0; ALBEDO=vec3(0.05,0.06,0.05); ALPHA=clamp((1.0-r)*0.33,0.0,0.33);}"
	material.shader = shader
	foot_shadow.material_override = material
	add_child(foot_shadow)

func update_motion(delta: float, metres_per_second: float) -> void:
	# Only tiny vertical character motion is synthetic. Real 2D art animation
	# will replace this after approved frame-sheet intake (not claimed yet).
	is_moving = metres_per_second > 0.1
	if is_moving:
		motion_phase += delta * minf(metres_per_second * 8.0, 25.0)
	else:
		motion_phase = 0.0
	if sprite != null:
		sprite.position.y = sprite_height * 0.5 + (absf(sin(motion_phase)) * 0.03 if is_moving else 0.0)
