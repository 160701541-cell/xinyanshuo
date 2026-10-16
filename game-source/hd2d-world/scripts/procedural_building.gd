extends Node2D
## CAC-PROC-001: original vector HD2D architectural module.
## Each building is a separately addressable entity, NOT an atlas cell.
## Position is the ground-floor doorway/footprint anchor.
const ROOF := Color("#455b61")
const RIDGE := Color("#809199")
const WOOD := Color("#624638")
const PLASTER := Color("#e1d6bc")
const STONE := Color("#8f9185")

var entity_id: String = ""
var kind: String = "residence"
var width: float = 210.0
var height: float = 150.0
var seed: int = 0
var door_open: bool = false
var lantern_lit: bool = false
var damage: int = 0
var selected: bool = false

func setup(id: String, building_kind: String, building_width: float, variant_seed: int) -> void:
	entity_id = id
	kind = building_kind
	width = building_width
	seed = variant_seed
	height = 156.0 if kind in ["temple", "inn", "school"] else 137.0
	queue_redraw()

func set_night(enabled: bool) -> void:
	lantern_lit = enabled
	queue_redraw()

func toggle_door() -> void:
	if damage == 2:
		return
	door_open = not door_open
	queue_redraw()

func set_damage(level: int) -> void:
	damage = clampi(level, 0, 2)
	queue_redraw()

func door_world_position() -> Vector2:
	return global_position + Vector2(0, -24)

func footprint() -> Rect2:
	return Rect2(position + Vector2(-width * 0.54, -height - 27.0), Vector2(width * 1.08, height + 45.0))

func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _line(points: Array, color: Color, thickness: float = 2.0) -> void:
	draw_polyline(PackedVector2Array(points), color, thickness, true)

func _draw() -> void:
	var half: float = width * 0.5
	var top: float = -height
	var dark: Color = Color("#34484e") if damage == 0 else Color("#302f30")
	var tile: Color = ROOF if damage == 0 else Color("#49423e")
	var front: Color = PLASTER if damage == 0 else Color("#a79c88")
	var side: Color = Color("#b2a991") if damage == 0 else Color("#8b7f70")
	var ornate: bool = kind in ["temple", "inn", "school", "teahouse"]
	# Contact shadow, masonry podium, and actual gabled wall volume.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.27))
	draw_circle(Vector2(0, 19), half * 1.13, Color(0.13, 0.15, 0.14, 0.22))
	draw_set_transform(Vector2.ZERO)
	_poly([Vector2(-half-6, -7), Vector2(half+8,-7), Vector2(half+23,8),Vector2(-half+9,8)], Color("#656a63"))
	_poly([Vector2(-half,-50), Vector2(half,-50), Vector2(half, -8), Vector2(-half,-8)], front)
	_poly([Vector2(half,-50), Vector2(half+17,-66), Vector2(half+17,-24),Vector2(half,-8)], side)
	draw_rect(Rect2(-half, -13, width, 6), STONE)
	# Visible rammed plaster/wood timber frame with non-repeating proportions.
	var beam_width: float = 9.0 if ornate else 7.0
	for i in range(4):
		var x: float = -half + float(i) * width / 3.0
		draw_rect(Rect2(x - beam_width * 0.5, -85, beam_width, 77), WOOD)
	draw_rect(Rect2(-half, -53, width, 8), Color("#a58c69"))
	# Deep recessed double leaf entrance. A click toggles the actual door state.
	var door_w: float = 38.0 if width < 175 else 50.0
	draw_rect(Rect2(-door_w*0.5-4, -61, door_w+8, 53), Color("#3c312a"))
	if not door_open:
		draw_rect(Rect2(-door_w*0.5, -57, door_w*0.5-1, 47), Color("#875b3f"))
		draw_rect(Rect2(1, -57, door_w*0.5-1, 47), Color("#956e4f"))
		draw_circle(Vector2(-5,-32), 1.8, Color("#bdad7d"))
		draw_circle(Vector2(5,-32), 1.8, Color("#bdad7d"))
	else:
		_poly([Vector2(-door_w/2,-57),Vector2(-door_w/2+8,-51),Vector2(-door_w/2+8,-4),Vector2(-door_w/2,-10)], Color("#825739"))
		_poly([Vector2(door_w/2,-57),Vector2(door_w/2-8,-51),Vector2(door_w/2-8,-4),Vector2(door_w/2,-10)], Color("#825739"))
	# Gridded windows and wooden frames, deliberately on the same perspective.
	for sign in [-1.0, 1.0]:
		var window_x: float = sign*(half*0.67)
		var window_color: Color = Color("#b7a77f") if lantern_lit else Color("#6d7774")
		draw_rect(Rect2(window_x-19, -56, 38, 31), WOOD)
		draw_rect(Rect2(window_x-16, -53, 32, 25), window_color)
		for j in range(1,4):
			var gx: float = window_x-16 + j*8.0
			draw_line(Vector2(gx,-53),Vector2(gx,-28),WOOD,1.4)
		draw_line(Vector2(window_x-16,-40),Vector2(window_x+16,-40),WOOD,1.5)
	# Roof: layered pitched polygon, raised ridge, distinct overhanging curved eaves.
	var eave_y: float = -67.0
	var ridge_y: float = top - 13.0
	_poly([Vector2(-half-23,eave_y+8),Vector2(-half-12,eave_y-6),
			Vector2(0,ridge_y),Vector2(half+9,eave_y-6),Vector2(half+23,eave_y+8),
			Vector2(half+13,eave_y+18),Vector2(0,ridge_y+15),Vector2(-half-13,eave_y+18)],dark)
	_poly([Vector2(0,ridge_y+10),Vector2(half+10,eave_y-5),
			Vector2(half+17,eave_y+11),Vector2(0,ridge_y+23)],Color("#39494e") if damage==0 else dark)
	_poly([Vector2(-half-14,eave_y+7),Vector2(-half-8,eave_y-4),
			Vector2(0,ridge_y+9),Vector2(0,ridge_y+23),Vector2(-half-8,eave_y+17)],tile)
	_poly([Vector2(0,ridge_y+23),Vector2(half+15,eave_y+17),
			Vector2(half+19,eave_y+12),Vector2(0,ridge_y+10)],Color("#566a6d") if damage==0 else dark)
	# Tiles: stroke density scales with facade width; no PNG or CDN.
	var columns: int = maxi(9, int(width/14))
	for i in range(columns+1):
		var q: float = float(i)/float(columns)
		var x: float = lerpf(-half-9, half+12, q)
		var peak: float = absf(2*q-1)
		var y0: float = lerpf(ridge_y+11, eave_y+10, peak)
		var y1: float = lerpf(ridge_y+22, eave_y+19, peak)
		draw_line(Vector2(x,y0),Vector2(x+3,y1),Color("#8a9795",0.45),1.0)
	for row in range(4):
		var t: float = float(row+1)/5.0
		var hx: float = half * t
		var yy: float = lerpf(ridge_y+17,eave_y+15,t)
		_line([Vector2(-hx-3,yy),Vector2(0,yy-4.0),Vector2(hx+5,yy+1)],Color("#26383e",0.37),1.1)
	_line([Vector2(-half-22,eave_y+8),Vector2(-half-14,eave_y+17),
			Vector2(0,ridge_y+24),Vector2(half+14,eave_y+17),
			Vector2(half+22,eave_y+8)],Color("#b1aaa0"),3.4)
	_line([Vector2(-half-14,eave_y-1),Vector2(0,ridge_y+1),Vector2(half+13,eave_y-1)],RIDGE,4.5)
	# Eave curl and carved tips are deliberately restrained to avoid icon-like flatness.
	for sign in [-1.0,1.0]:
		_line([Vector2(sign*(half+12),eave_y+16),Vector2(sign*(half+24),eave_y+10),
				Vector2(sign*(half+26),eave_y+1)],Color("#9ba9a6"),3)
	if ornate:
		draw_rect(Rect2(-36,-76,72,17),WOOD)
		draw_rect(Rect2(-32,-74,64,12),Color("#c5a979"))
		draw_rect(Rect2(-half-9,-63,15,9),Color("#987649"))
		draw_rect(Rect2(half-6,-63,15,9),Color("#987649"))
	if kind in ["shop","teahouse","inn","workshop","warehouse"]:
		draw_rect(Rect2(-half+10,-22,28,15),Color("#8e7755"))
		_line([Vector2(-half+13,-18),Vector2(-half+34,-18)],Color("#cfc4a1"))
	# Real stateful lanterns, night only, with small bounded glow.
	for sign in [-1.0,1.0]:
		var lamp_x: float = sign*(half-14)
		draw_line(Vector2(lamp_x,-65),Vector2(lamp_x,-53),WOOD,2)
		if lantern_lit and damage == 0:
			draw_circle(Vector2(lamp_x,-45),17,Color("#ffaa40",0.11))
		draw_rect(Rect2(lamp_x-5,-53,10,16),Color("#d48b43") if lantern_lit else Color("#924638"))
		draw_line(Vector2(lamp_x-5,-51),Vector2(lamp_x+5,-51),Color("#633d2b"),2)
	# Burnt and collapsed states are actually different geometry.
	if damage >= 1:
		_line([Vector2(-half*0.7,-43),Vector2(-half*0.4,-31),Vector2(-half*0.5,-14)],Color("#453c36"),2.5)
		for k in range(7):
			var smoke_x: float = -half*0.52+float(k)*14
			draw_circle(Vector2(smoke_x,-15+float(k%3)*4),3.8,Color("#3d3632",0.7))
	if damage == 2:
		_poly([Vector2(-half-20,eave_y+7),Vector2(-half*0.25,-95),
				Vector2(half*0.1,-50),Vector2(half+17,eave_y+20),
				Vector2(half+3,-28),Vector2(-half-3,-36)],Color("#625b56"))
		_line([Vector2(-half*0.4,-74),Vector2(-half*0.25,-48),Vector2(0,-35),Vector2(half*0.45,-10)],WOOD,6)
	if selected:
		draw_arc(Vector2(0,-13),half*0.88,0.0,TAU,38,Color("#edd084",0.75),2)
