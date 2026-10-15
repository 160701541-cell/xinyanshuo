extends Node2D
## WorldX NPC demonstration inside the old installed Canglan game scene.
## Real imported frame timing and sheets, no fake painted stick figures.
const DIR := "res://hd2d/worldx/npcs/"
var elapsed := 0.0
var actors: Array[AnimatedSprite2D] = []
var directions: Array[float] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 160701541
	var meta_path := DIR + "npcs.json"
	if not FileAccess.file_exists(meta_path):
		push_warning("WorldX NPC atlas manifest unavailable")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	if not (parsed is Dictionary):
		push_error("WorldX NPC manifest invalid")
		return
	var items: Variant = parsed.get("characters", [])
	if not (items is Array):
		return
	for i in range(mini(items.size(), 16)):
		var cfg: Dictionary = items[i]
		var sprite: AnimatedSprite2D = _make_actor(cfg)
		if sprite == null:
			continue
		sprite.position = Vector2(240.0 + float(i % 4) * 260.0, 320.0 + float(i / 4) * 230.0)
		sprite.scale = Vector2(0.72, 0.72)
		add_child(sprite)
		actors.append(sprite)
		directions.append(1.0 if (i % 2 == 0) else -1.0)
		if sprite.sprite_frames.has_animation("walk-down"):
			sprite.play("walk-down")
		else:
			sprite.play("idle-front")
	print("WORLDX_NPCS_LOADED ",actors.size())

func _make_actor(cfg: Dictionary) -> AnimatedSprite2D:
	var path: String = DIR + str(cfg.get("sheet", ""))
	if not FileAccess.file_exists(path):
		return null
	var im := Image.new()
	if im.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
		return null
	var tex := ImageTexture.create_from_image(im)
	var fw: int = int(cfg.get("frame_width",0))
	var fh: int = int(cfg.get("frame_height",0))
	var cols: int = int(cfg.get("columns",0))
	var rows: int = int(cfg.get("rows",0))
	if mini(fw,mini(fh,mini(cols,rows))) < 1:
		return null
	if cols*fw > im.get_width() or rows*fh > im.get_height():
		return null
	var frames := SpriteFrames.new()
	var anims: Dictionary = cfg.get("animations",{})
	for key in anims:
		var info: Dictionary = anims[key]
		var name: String = str(key)
		if not frames.has_animation(name):
			frames.add_animation(name)
		frames.set_animation_speed(name, float(info.get("frameRate", 8.0)))
		frames.set_animation_loop(name,true)
		var start: int = int(info.get("start",info.get("frame",0)))
		var stop: int = int(info.get("end",start))
		for index in range(start,mini(stop,cols*rows-1)+1):
			if index < 0:
				continue
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(index % cols * fw, index / cols * fh, fw, fh)
			frames.add_frame(name,atlas)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "WorldXNPC_" + str(cfg.get("id","unknown"))
	sprite.sprite_frames = frames
	sprite.z_index = 6
	return sprite

func _process(delta: float) -> void:
	elapsed += delta
	for i in range(actors.size()):
		var actor := actors[i]
		actor.position.x += delta * directions[i] * 12.0
		if elapsed > 4.0:
			directions[i] = -directions[i]
			actor.flip_h = directions[i] < 0.0
	if elapsed > 4.0:
		elapsed = 0.0
