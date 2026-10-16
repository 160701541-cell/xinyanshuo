extends Node2D
## CAC-PROC-001: deterministic seed + district rules => playable, layered world.
## No image downloads, atlas tiles, model services, or generated asset approvals.
const Building = preload("res://scripts/procedural_building.gd")
const Prop = preload("res://scripts/procedural_prop.gd")
const COLUMNS: int = 6
const ROWS: int = 4
const PLOT_W: float = 515.0
const PLOT_H: float = 390.0
const STEP_X: float = 570.0
const STEP_Y: float = 465.0
const ORIGIN := Vector2(335, 300)
const WORLD_SIZE := Vector2(3960, 2680)
const ZONES := ["residence","farm","market","workshop","inn","temple","school","warehouse","teahouse"]

var world_seed: int = 1729
var season: int = 0
var night: bool = false
var buildings: Array[Node2D] = []
var props: Array[Node2D] = []
var entity_index: Dictionary = {}
var _plots: Array[Dictionary] = []

func _ready() -> void:
	y_sort_enabled = true
	generate(world_seed)

func _kind_at(col: int, row: int) -> String:
	if row == 0 and col == 2:
		return "temple"
	if row == 0 and col == 3:
		return "school"
	if row == 3 and col in [0,1,4,5]:
		return "farm"
	if row == 1 and col in [2,3]:
		return "market"
	return ZONES[posmod(col*7 + row*5 + world_seed, ZONES.size())]

func generate(new_seed: int) -> void:
	world_seed = new_seed
	for item in buildings:
		remove_child(item)
		item.queue_free()
	for item in props:
		remove_child(item)
		item.queue_free()
	buildings.clear()
	props.clear()
	entity_index.clear()
	_plots.clear()
	for row in range(ROWS):
		for col in range(COLUMNS):
			var center: Vector2 = ORIGIN + Vector2(float(col)*STEP_X,float(row)*STEP_Y)
			var zone: String = _kind_at(col,row)
			var prefix: String = "CZ-%02d-%02d" % [row,col]
			_plots.append({"id": prefix, "zone": zone, "center": center})
			_make_plot(col,row,center,zone,prefix)
	# The river, ferry route, and cultivated banks are part of the world geometry,
	# not a still background. Prop entities remain independent of the landscape.
	for i in range(16):
		_spawn_prop("tree", Vector2(70+float(i)*242,2220+float(i%3)*44), "RIVER-TREE-%02d" % i, i, (i+1)%3)
	for i in range(8):
		_spawn_prop("stone",Vector2(160+float(i)*475,2300), "RIVER-STONE-%02d" % i,i)
	queue_redraw()

func _make_plot(col: int, row: int, c: Vector2, zone: String, id: String) -> void:
	var n: int = row*COLUMNS+col
	var main_kind: String = zone
	if zone == "farm":
		main_kind = "granary" if n%2==0 else "residence"
	var main_width: float = 250.0 if zone in ["temple","school","inn","teahouse"] else 220.0
	_spawn_building(main_kind,c+Vector2(0,-40),id+"-H0",main_width,n)
	if zone in ["residence","temple","school","inn","teahouse"]:
		_spawn_building("residence" if zone=="residence" else "warehouse",
				c+Vector2(-166,103),id+"-W1",145.0,n+21)
		_spawn_building("residence" if zone=="residence" else "workshop",
				c+Vector2(166,103),id+"-E1",145.0,n+34)
	elif zone == "market":
		_spawn_building("shop",c+Vector2(-160,104),id+"-W1",152.0,n+12)
		_spawn_building("shop",c+Vector2(160,104),id+"-E1",152.0,n+25)
		_spawn_prop("stall",c+Vector2(0,126),id+"-STALL",n)
	else:
		_spawn_building("workshop" if zone=="workshop" else "warehouse",
				c+Vector2(-161,110),id+"-SIDE",165.0,n+12)
	if zone == "farm":
		for i in range(3):
			_spawn_prop("field",c+Vector2(-160+float(i)*156,143),
					id+"-FIELD-%d" % i,n+i)
	else:
		_spawn_prop("well" if n%5==0 else "stone",c+Vector2(63,99),id+"-CENTER",n)
	_spawn_prop("tree",c+Vector2(-204,87),id+"-TREE",n,n%3)
	_spawn_prop("lantern",c+Vector2(-64,182),id+"-LIGHT-A",n)
	_spawn_prop("lantern",c+Vector2(64,182),id+"-LIGHT-B",n)
	if zone in ["market","teahouse","inn","workshop"]:
		_spawn_prop("cart",c+Vector2(201,153),id+"-CART",n)
	elif zone == "farm":
		_spawn_prop("hay",c+Vector2(191,153),id+"-HAY",n)
	else:
		_spawn_prop("bamboo",c+Vector2(202,84),id+"-BAMBOO",n)
	if zone == "temple":
		_spawn_prop("bench",c+Vector2(0,160),id+"-BENCH",n)

func _spawn_building(kind: String, at: Vector2, id: String, size: float, variation: int) -> void:
	var building: Node2D = Building.new()
	building.call("setup",id,kind,size,variation)
	building.position = at
	building.call("set_night",night)
	buildings.append(building)
	entity_index[id] = building
	add_child(building)

func _spawn_prop(kind: String, at: Vector2, id: String, variation: int, growth_stage: int = 2) -> void:
	var prop: Node2D = Prop.new()
	prop.call("setup",id,kind,variation)
	prop.call("set_growth",growth_stage)
	prop.call("update_weather",season,night)
	prop.position = at
	props.append(prop)
	entity_index[id] = prop
	add_child(prop)

func get_entity(id: String) -> Node2D:
	return entity_index.get(id,null) as Node2D

func find_door(at: Vector2, radius: float = 38.0) -> Node2D:
	var best: Node2D = null
	var best_dist: float = radius*radius
	for b in buildings:
		if int(b.get("damage")) == 2:
			continue
		var door_pos: Vector2 = b.call("door_world_position")
		var delta: Vector2 = door_pos-at
		var dist: float = delta.length_squared()
		if dist <= best_dist:
			best_dist = dist
			best = b
	return best

func set_night(enabled: bool) -> void:
	night = enabled
	for b in buildings:
		b.call("set_night",enabled)
	for p in props:
		p.call("update_weather",season,enabled)
	queue_redraw()

func set_season(value: int) -> void:
	season = posmod(value,4)
	for p in props:
		p.call("update_weather",season,night)
	queue_redraw()

func set_selected(building: Node2D) -> void:
	for b in buildings:
		if bool(b.get("selected")):
			b.set("selected",false)
			b.queue_redraw()
	if building != null:
		building.set("selected",true)
		building.queue_redraw()

func counts() -> Dictionary:
	var zones: Dictionary = {}
	for plot in _plots:
		var kind: String = String(plot["zone"])
		zones[kind] = int(zones.get(kind,0))+1
	return {"plots":_plots.size(),"buildings":buildings.size(),"props":props.size(),
			"entities":entity_index.size(),"zones":zones,"seed":world_seed}

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,WORLD_SIZE),Color("#77906a"))
	# Terrain is hand-coded geometry and uses repeatable micro-color variations.
	for i in range(520):
		var x: float = float((i*937+world_seed*13)%int(WORLD_SIZE.x))
		var y: float = float((i*571+world_seed*29)%2190)
		var w: float = 9.0+float(i%7)*3
		draw_line(Vector2(x,y),Vector2(x+w,y+2),Color("#b6b799",0.14),1.4)
	# Main river: shore, depth bands, and stones with bridges at fixed crossings.
	draw_rect(Rect2(0,2180,WORLD_SIZE.x,402),Color("#afa98a"))
	draw_rect(Rect2(0,2230,WORLD_SIZE.x,291),Color("#567c83"))
	draw_rect(Rect2(0,2251,WORLD_SIZE.x,235),Color("#6c9296"))
	for i in range(62):
		var rx: float = float((i*163)%int(WORLD_SIZE.x))
		var ry: float = 2265+float((i*47)%190)
		draw_line(Vector2(rx,ry),Vector2(rx+35+float(i%5)*8,ry-3),Color("#b1c6b5",0.29),1.9)
	for bx in [1035.0,2800.0]:
		draw_rect(Rect2(bx-57,2170,114,375),Color("#595c53"))
		draw_rect(Rect2(bx-44,2170,88,375),Color("#a09c88"))
		for j in range(12):
			var by: float = 2180+float(j)*31
			draw_line(Vector2(bx-42,by),Vector2(bx+42,by),Color("#686d65"),2.4)
	# Dressed stone streets and gutters between walled courtyards.
	for row in range(ROWS+1):
		var street_y: float = ORIGIN.y + float(row)*STEP_Y - 247
		draw_rect(Rect2(20,street_y,WORLD_SIZE.x-40,77),Color("#a69f89"))
		draw_line(Vector2(20,street_y+4),Vector2(WORLD_SIZE.x-20,street_y+4),Color("#756f64"),3)
		for i in range(85):
			var x: float = 30+float(i)*46
			var y: float = street_y+8+float(i%4)*16
			draw_line(Vector2(x,y),Vector2(x+22,y-1),Color("#6d7167",0.44),1.4)
	for col in range(COLUMNS+1):
		var street_x: float = ORIGIN.x + float(col)*STEP_X-286
		draw_rect(Rect2(street_x,25,58,2100),Color("#a49f89"))
		draw_line(Vector2(street_x+5,25),Vector2(street_x+5,2125),Color("#686d64"),2)
	# Enclosed courtyard walls and articulated entrance break on south edge.
	for p in _plots:
		var c: Vector2 = p["center"]
		var l: float = c.x-PLOT_W*0.5
		var r: float = c.x+PLOT_W*0.5
		var t: float = c.y-PLOT_H*0.5
		var b: float = c.y+PLOT_H*0.5
		draw_rect(Rect2(l,t,PLOT_W,PLOT_H),Color("#c2b797",0.27))
		for off in [0.0,5.0]:
			var wall: Color = Color("#e0d7c0") if off==0.0 else Color("#938a77")
			draw_line(Vector2(l,t+off),Vector2(r,t+off),wall,5)
			draw_line(Vector2(l+off,t),Vector2(l+off,b),wall,5)
			draw_line(Vector2(r-off,t),Vector2(r-off,b),wall,5)
			draw_line(Vector2(l,b-off),Vector2(c.x-42,b-off),wall,5)
			draw_line(Vector2(c.x+42,b-off),Vector2(r,b-off),wall,5)
		draw_rect(Rect2(c.x-43,b-9,86,13),Color("#b4aca0"))
		draw_rect(Rect2(c.x-37,b-7,74,9),Color("#6a5140"))
		for side in [-1.0,1.0]:
			draw_rect(Rect2(c.x+side*46-5,b-29,10,35),Color("#6e5541"))
		# Courtyard walk of slightly irregular flagstones, not one big background blob.
		for j in range(6):
			var py: float = c.y+float(j)*26+19
			draw_rect(Rect2(c.x-18+float(j%2)*2,py,36,20),Color("#98988b",0.62))
			draw_line(Vector2(c.x-18,py+1),Vector2(c.x+14,py+1),Color("#d1c9b5",0.46),1)
