extends Node2D
## WorldX NPC demonstration inside the old installed Canglan game scene.
## Real imported frame timing and sheets, no fake painted stick figures.
const DIR := "res://hd2d/worldx/npcs/"
signal character_selected(id: String, name: String, description: String)
var elapsed := 0.0
var actors: Array[AnimatedSprite2D] = []
var directions: Array[float] = []
var nav_lines: Array[String] = []
var nav_width := 0
var nav_height := 0
var nav_map_index := 0
var wander_targets: Array[Vector2] = []
var next_decision := 0.0
var character_data: Array[Dictionary] = []
var citizen_profiles: Dictionary = {}
var status_clock: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 160701541
	_load_worldx_navigation()
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
	for i in range(mini(items.size(), 5)):
		var cfg: Dictionary = items[i]
		var sprite: AnimatedSprite2D = _make_actor(cfg)
		if sprite == null:
			continue
		sprite.position = _choose_spawn_point(i)
		sprite.scale = Vector2(0.72, 0.72)
		add_child(sprite)
		actors.append(sprite)
		character_data.append(cfg)
		var code: String = str(cfg.get("id",""))
		var jobs := ["商贾","算命先生","捕快","平民","酒馆常客"]
		assert(not code.is_empty() and not citizen_profiles.has(code),
			"Original NPC must have independent canonical ID")
		citizen_profiles[code]={"entity_id":code,
			"display_name":str(cfg.get("name","村民")),
			"occupation":jobs[mini(i,4)],
			"age":22+(i*7)%40,"energy":100-i*4,
			"hunger":i*5,"mood":57+i*3,
			"inventory":{},"activity":"行走","world_position":sprite.position}
		directions.append(1.0 if (i % 2 == 0) else -1.0)
		wander_targets.append(sprite.position)
		if sprite.sprite_frames.has_animation("walk-down"):
			sprite.play("walk-down")
		else:
			sprite.play("idle-front")
	print("WORLDX_NPCS_LOADED ",actors.size())

func _load_worldx_navigation(index: int = 0) -> bool:
	# Each WorldX scene has a different actual collision grid. Never let
	# NPCs keep navigating grid000 after the user selects grid001.
	if index < 0 or index > 7:
		return false
	var nav_path := "res://hd2d/worldx/nav_%03d.json" % index
	if not FileAccess.file_exists(nav_path):
		push_warning("WorldX walkability grid unavailable: " + nav_path)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(nav_path))
	if not (parsed is Dictionary):
		return false
	var width: int = int(parsed.get("width", 0))
	var height: int = int(parsed.get("height", 0))
	var rows: Variant = parsed.get("cells",[])
	if width < 10 or height < 10 or not (rows is Array) or rows.size() != height:
		return false
	var next_lines: Array[String] = []
	for row in rows:
		var line := str(row)
		if line.length() != width or (line.count("0") + line.count("1")) != width:
			return false
		next_lines.append(line)
	# Commit only a validated complete grid, so errors cannot leave
	# an NPC navigating half of the previous map.
	nav_width = width
	nav_height = height
	nav_lines = next_lines
	nav_map_index = index
	return true

func set_map_index(index: int) -> bool:
	if not _load_worldx_navigation(index):
		return false
	for i in range(actors.size()):
		var point := _choose_spawn_point(i)
		actors[i].position = point
		wander_targets[i] = point
	return true

func _walkable_at(col: int, row: int) -> bool:
	if col < 0 or row < 0 or col >= nav_width or row >= nav_height:
		return false
	return nav_lines[row].substr(col,1) == "0"

func _pixel_at(col: int,row: int) -> Vector2:
	return Vector2((float(col)+0.5)*1280.0 / float(nav_width),
		(float(row)+0.5)*715.0 / float(nav_height))

func _choose_spawn_point(index: int) -> Vector2:
	if nav_width == 0 or nav_height == 0:
		return Vector2(160.0+float(index%3)*280.0,200.0+float(index/3)*190.0)
	var candidates: Array[Vector2i] = []
	for row in range(2,nav_height-2,3):
		for col in range(2,nav_width-2,3):
			if _walkable_at(col,row):
				candidates.append(Vector2i(col,row))
	if candidates.is_empty():
		return Vector2(240.0+float(index)*20.0,350.0)
	var idx := mini(index*(candidates.size()/6),candidates.size()-1)
	var point := candidates[idx]
	return _pixel_at(point.x,point.y)

func _new_walk_target(old: Vector2) -> Vector2:
	if nav_width == 0 or nav_height == 0:
		return old
	var col := clampi(int(old.x * float(nav_width)/1280.0),0,nav_width-1)
	var row := clampi(int(old.y * float(nav_height)/715.0),0,nav_height-1)
	var neighbours := [Vector2i(col+1,row),Vector2i(col-1,row),
		Vector2i(col,row+1),Vector2i(col,row-1)]
	var valid: Array[Vector2i] = []
	for cell in neighbours:
		if _walkable_at(cell.x,cell.y):
			valid.append(cell)
	if valid.is_empty():
		return old
	var target := valid[rng.randi_range(0,valid.size()-1)]
	return _pixel_at(target.x,target.y)

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

func get_citizen_status(id: String) -> Dictionary:
	return (citizen_profiles[id] as Dictionary).duplicate(true) if citizen_profiles.has(id) else {}

func _process(delta: float) -> void:
	elapsed += delta
	status_clock += delta
	if status_clock >= 9.0:
		status_clock=0.0
		for citizen_id in citizen_profiles:
			var profile: Dictionary = citizen_profiles[citizen_id]
			profile["energy"]=maxi(0,int(profile["energy"])-1)
			profile["hunger"]=mini(100,int(profile["hunger"])+1)
	next_decision -= delta
	if next_decision <= 0.0:
		next_decision = 1.25
		for i in range(actors.size()):
			wander_targets[i] = _new_walk_target(actors[i].position)
	for i in range(actors.size()):
		var actor := actors[i]
		var distance: Vector2 = wander_targets[i] - actor.position
		if distance.length() > 1.0:
			actor.position = actor.position.move_toward(wander_targets[i], 28.0*delta)
			if absf(distance.x)>absf(distance.y):
				actor.flip_h = distance.x > 0.0
				if actor.animation != "walk-left":
					actor.play("walk-left")
			elif distance.y < 0.0:
				if actor.animation != "walk-up":
					actor.play("walk-up")
			else:
				if actor.animation != "walk-down":
					actor.play("walk-down")
		elif actor.sprite_frames.has_animation("idle-front") and actor.animation != "idle-front":
			actor.play("idle-front")

func _unhandled_input(event: InputEvent) -> void:
	var pointer: Vector2
	if event is InputEventScreenTouch and event.pressed:
		pointer = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pointer = event.position
	else:
		return
	var local: Vector2 = to_local(pointer)
	var selected := -1
	var min_distance := 82.0
	for i in range(actors.size()):
		var distance: float = actors[i].position.distance_to(local)
		if distance < min_distance:
			selected = i
			min_distance = distance
	if selected >= 0:
		var cfg := character_data[selected]
			var person_code: String = str(cfg.get("id",""))
			var record: Dictionary = get_citizen_status(person_code)
			var biography: String = str(cfg.get("description",""))
			if not record.is_empty():
				biography += " | ID:"+person_code
				biography += " | 年龄:"+str(record["age"])
				biography += " | 精力:"+str(record["energy"])
				biography += " | 饥饿:"+str(record["hunger"])
				biography += " | 心情:"+str(record["mood"])
				biography += " | 行为:"+str(record["activity"])
			character_selected.emit(person_code,str(cfg.get("name","旅人")),biography)
		get_viewport().set_input_as_handled()
