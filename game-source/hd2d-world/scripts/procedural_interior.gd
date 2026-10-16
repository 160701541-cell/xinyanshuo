extends Node2D
## Procedural room paired to the SAME persistent external building entity.
## Furniture is separately addressable and generated only upon entering.
const Prop = preload("res://scripts/procedural_prop.gd")
const WIDTH: float = 880.0
const HEIGHT: float = 530.0
var source_building_id: String = ""
var room_kind: String = ""
var furnishings: Array[Node2D] = []
var indoor_entity_index: Dictionary = {}
var night: bool = false

func open_for(building: Node2D, is_night: bool) -> void:
	source_building_id = building.entity_id
	room_kind = building.kind
	night = is_night
	for item in furnishings:
		remove_child(item)
		item.queue_free()
	furnishings.clear()
	indoor_entity_index.clear()
	# Store room and furnishings separately from building roof sprite.
	# Rooms keep the exterior identity instead of creating a unrelated "interior building".
	for i in range(2):
		_make_prop("bench",Vector2(-220+float(i)*435,105),
				source_building_id+"-ROOM-BENCH-%d" % i,i)
	_make_prop("barrel",Vector2(320,-15),source_building_id+"-ROOM-JAR",5)
	if room_kind in ["shop","teahouse","inn","school"]:
		for i in range(3):
			_make_prop("stall",Vector2(-235+float(i)*220,-103),
					source_building_id+"-ROOM-DESK-%d" % i,8+i)
	elif room_kind in ["granary","warehouse","workshop"]:
		for i in range(4):
			_make_prop("barrel",Vector2(-280+float(i)*160,-134),
					source_building_id+"-ROOM-STOCK-%d" % i,13+i)
	else:
		for i in range(3):
			_make_prop("bench",Vector2(-220+float(i)*220,-119),
					source_building_id+"-ROOM-FURNITURE-%d" % i,18+i)
	queue_redraw()

func _make_prop(kind: String, at: Vector2, id: String, variation: int) -> void:
	var p: Node2D = Prop.new()
	p.setup(id,kind,variation)
	p.position = at
	p.update_weather(0,night)
	furnishings.append(p)
	indoor_entity_index[id] = p
	add_child(p)

func _draw() -> void:
	var half: float = WIDTH*0.5
	var top: float = -HEIGHT*0.5
	# Sandstone courtyard threshold, shadowed plaster sidewalls and wooden floor.
	draw_rect(Rect2(-half-75,top-55,WIDTH+150,HEIGHT+110),Color("#413e37"))
	draw_rect(Rect2(-half-25,top-28,WIDTH+50,HEIGHT+56),Color("#b1a58e"))
	draw_rect(Rect2(-half,top,WIDTH,HEIGHT),Color("#b89b74"))
	for i in range(22):
		var xx: float = -half+float(i)*41.0
		draw_line(Vector2(xx,top),Vector2(xx,top+HEIGHT),Color("#856c4f",0.6),2.0)
		for j in range(7):
			var yy: float = top+float(j)*78.0
			draw_line(Vector2(xx,yy),Vector2(xx+40,yy),Color("#dfc39a",0.32),1.4)
	draw_rect(Rect2(-half-27,top-30,WIDTH+54,32),Color("#e4d6bd"))
	draw_rect(Rect2(-half-27,top,25,HEIGHT+27),Color("#d3c7ad"))
	draw_rect(Rect2(half+2,top,25,HEIGHT+27),Color("#c7bba3"))
	draw_rect(Rect2(-half-27,top+HEIGHT-8,WIDTH+54,35),Color("#78624d"))
	# Structural joists, not a flat isolated-room screenshot.
	for i in range(5):
		var x: float = -half+float(i)*WIDTH/4.0
		draw_rect(Rect2(x-8,top-28,16,HEIGHT+40),Color("#715039",0.42))
	draw_rect(Rect2(-half-20,top+45,WIDTH+40,16),Color("#6e4f3c"))
	draw_rect(Rect2(-half-20,top+245,WIDTH+40,13),Color("#6e4f3c",0.36))
	for i in range(3):
		var wx: float = -230.0+float(i)*230.0
		draw_rect(Rect2(wx-42,top+11,84,60),Color("#594c3f"))
		draw_rect(Rect2(wx-37,top+16,74,49),
				Color("#a3ac9e") if not night else Color("#d4ac75"))
		for j in range(1,4):
			draw_line(Vector2(wx-37+float(j)*18,top+16),
					Vector2(wx-37+float(j)*18,top+65),Color("#735641"),3)
		draw_line(Vector2(wx-37,top+40),Vector2(wx+37,top+40),Color("#735641"),3)
	draw_rect(Rect2(-half+25,HEIGHT*0.5-31,WIDTH-50,23),Color("#8c8575"))
	draw_rect(Rect2(-67,HEIGHT*0.5-31,134,23),Color("#51483d"))
	draw_line(Vector2(-67,HEIGHT*0.5-32),Vector2(-67,HEIGHT*0.5-8),Color("#ac9b83"),3)
	if night:
		for x in [-330.0,330.0]:
			draw_circle(Vector2(x,-105),28,Color("#f2ab55",0.11))
			draw_rect(Rect2(x-8,-123,16,31),Color("#bd6e42"))
