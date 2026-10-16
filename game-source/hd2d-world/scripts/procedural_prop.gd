extends Node2D
## CAC-PROC-001: independently addressable small scene props. Not baked into houses.
var entity_id: String = ""
var kind: String = "tree"
var variant_seed: int = 0
var season: int = 0  # 0 spring, 1 summer, 2 autumn, 3 winter
var growth: int = 2  # 0 sapling, 1 young, 2 mature
var night: bool = false
var damaged: bool = false

func setup(id: String, prop_kind: String, value: int) -> void:
	entity_id = id
	kind = prop_kind
	variant_seed = value
	queue_redraw()

func update_weather(next_season: int, is_night: bool) -> void:
	season = posmod(next_season, 4)
	night = is_night
	queue_redraw()

func set_growth(stage: int) -> void:
	growth = clampi(stage, 0, 2)
	queue_redraw()

func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _draw() -> void:
	match kind:
		"tree": _tree()
		"bamboo": _bamboo()
		"well": _well()
		"lantern": _lantern()
		"cart": _cart()
		"barrel": _barrel()
		"stall": _stall()
		"bench": _bench()
		"stone": _stone()
		"field": _field()
		"hay": _hay()
		_: _stone()

func _tree() -> void:
	var s: float = [0.35, 0.63, 1.0][growth]
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(s,s))
	draw_circle(Vector2(4,8),20,Color(0.10,0.16,0.13,0.18))
	_poly([Vector2(-6,2),Vector2(-5,-94),Vector2(4,-110),Vector2(9,2)], Color("#674b36"))
	draw_line(Vector2(-1,-65),Vector2(-26,-95),Color("#674b36"),6.0)
	draw_line(Vector2(2,-81),Vector2(32,-114),Color("#674b36"),6.0)
	var foliage: Color = Color("#547d4e")
	match season:
		0: foliage = Color("#78a272")
		1: foliage = Color("#477248")
		2: foliage = Color("#ae8650")
		3: foliage = Color("#787c75")
	if season != 3:
		for k in range(11):
			var x: float = float((k*43 + variant_seed*7) % 105) - 52.0
			var y: float = -112.0-float((k*29+variant_seed*3)%50)
			var radius: float = 20.0 + float((k*7)%12)
			draw_circle(Vector2(x,y),radius,foliage.darkened(float(k%4)*0.07))
			draw_arc(Vector2(x-3,y-4),radius*0.75,PI*1.05,PI*1.75,8,Color("#c1cdb0",0.2),1.4)
	else:
		for k in range(6):
			var x: float = -35.0+float(k)*14.0
			draw_line(Vector2(0,-92),Vector2(x,-152+float(k%3)*12),Color("#695949"),3)
	draw_set_transform(Vector2.ZERO)

func _bamboo() -> void:
	for i in range(5):
		var x: float = float(i-2)*8
		var h: float = 90.0+float((i*13+variant_seed)%45)
		draw_line(Vector2(x,0),Vector2(x-10,-h),Color("#55774b"),4.0)
		for j in range(3):
			var y: float = -h*(0.32+float(j)*0.24)
			draw_line(Vector2(x-10,y),Vector2(x-30,y-12),Color("#688d5c"),2.2)
			_poly([Vector2(x-30,y-12),Vector2(x-57,y-25),Vector2(x-35,y-3)],Color("#72985e"))
			draw_line(Vector2(x-10,y-5),Vector2(x+16,y-21),Color("#688d5c"),2.0)
			_poly([Vector2(x+16,y-21),Vector2(x+43,y-32),Vector2(x+21,y-11)],Color("#557d54"))

func _well() -> void:
	draw_set_transform(Vector2.ZERO,0.0,Vector2(1,0.55))
	draw_circle(Vector2(0,4),46,Color("#545750"))
	draw_circle(Vector2(0,-5),39,Color("#adafa0"))
	draw_circle(Vector2(0,-7),26,Color("#373e40"))
	draw_circle(Vector2(0,-7),19,Color("#4f6669"))
	draw_arc(Vector2(0,-7),20,PI*0.1,PI*0.95,16,Color("#8ba2a2",0.7),1.5)
	draw_set_transform(Vector2.ZERO)
	for sign in [-1.0,1.0]:
		draw_rect(Rect2(sign*29-3,-100,6,80),Color("#705542"))
	draw_line(Vector2(-35,-99),Vector2(35,-99),Color("#765b43"),8)
	draw_circle(Vector2(0,-99),5,Color("#af9a76"))
	draw_line(Vector2(0,-99),Vector2(0,-44),Color("#99815a"),2)
	draw_rect(Rect2(-11,-47,22,18),Color("#806145"))

func _lantern() -> void:
	draw_rect(Rect2(-3,-84,6,84),Color("#4c4238"))
	draw_rect(Rect2(-12,-87,24,5),Color("#66513c"))
	draw_line(Vector2(0,-86),Vector2(0,-76),Color("#9d8765"),2)
	if night and not damaged:
		draw_circle(Vector2(0,-65),26,Color("#ffa83a",0.16))
		draw_circle(Vector2(0,-65),18,Color("#ffd06d",0.16))
	draw_rect(Rect2(-10,-77,20,27),Color("#b6613c") if night else Color("#884b3d"))
	draw_line(Vector2(-10,-74),Vector2(10,-74),Color("#e3b17b"),2.0)
	draw_line(Vector2(0,-50),Vector2(0,-40),Color("#ad7850"),2.0)

func _cart() -> void:
	_poly([Vector2(-45,-30),Vector2(24,-42),Vector2(46,-24),Vector2(-22,-12)], Color("#785a3e"))
	_poly([Vector2(-45,-30),Vector2(-45,-51),Vector2(24,-61),Vector2(24,-42)], Color("#9b7851"))
	draw_line(Vector2(28,-30),Vector2(67,-46),Color("#5e4535"),5.0)
	for x in [-27.0,25.0]:
		draw_circle(Vector2(x,-7),17,Color("#3e3833"))
		draw_circle(Vector2(x,-7),11,Color("#826448"))
		draw_circle(Vector2(x,-7),3,Color("#3e3833"))
	if not damaged:
		for i in range(3):
			draw_line(Vector2(-37+float(i)*13,-55),Vector2(-28+float(i)*13,-66),Color("#b79760"),4)

func _barrel() -> void:
	_poly([Vector2(-17,-39),Vector2(17,-39),Vector2(22,-5),Vector2(-22,-5)],Color("#8b603d"))
	for k in range(4):
		draw_line(Vector2(-14+float(k)*9,-37),Vector2(-18+float(k)*12,-7),Color("#573d2b"),1.8)
	draw_line(Vector2(-20,-30),Vector2(20,-30),Color("#696b63"),5)
	draw_line(Vector2(-22,-10),Vector2(22,-10),Color("#696b63"),5)
	draw_arc(Vector2(0,-39),17,PI,TAU,18,Color("#d1b78e"),2)

func _stall() -> void:
	for x in [-57.0,57.0]:
		draw_rect(Rect2(x-4,-77,8,78),Color("#72533a"))
	_poly([Vector2(-69,-77),Vector2(-40,-113),Vector2(46,-113),Vector2(69,-77)],Color("#a07d58"))
	for i in range(7):
		var x: float = -62+float(i)*20
		var c: Color = Color("#b07958") if i%2==0 else Color("#e1c9a1")
		_poly([Vector2(x,-78),Vector2(x+20,-78),Vector2(x+12,-106),Vector2(x+2,-106)],c)
	draw_rect(Rect2(-57,-35,114,9),Color("#624632"))
	draw_rect(Rect2(-50,-27,7,26),Color("#73533f"))
	draw_rect(Rect2(42,-27,7,26),Color("#73533f"))
	for i in range(5):
		draw_circle(Vector2(-37+float(i)*17,-40),7,Color("#b68b52") if i%2==0 else Color("#698457"))

func _bench() -> void:
	draw_rect(Rect2(-37,-28,74,13),Color("#7a5d40"))
	for x in [-28.0,26.0]:
		draw_rect(Rect2(x,-16,6,16),Color("#594634"))

func _stone() -> void:
	_poly([Vector2(-26,-2),Vector2(-24,-18),Vector2(-8,-34),Vector2(16,-31),
			Vector2(28,-13),Vector2(22,0)],Color("#8c9188"))
	_poly([Vector2(-24,-18),Vector2(-8,-34),Vector2(16,-31),Vector2(3,-17)],Color("#b1b4a7"))
	draw_line(Vector2(-13,-15),Vector2(4,-9),Color("#727c72"),1.5)

func _field() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0,0.40))
	draw_rect(Rect2(-62,-65,124,130),Color("#665d3d"))
	for j in range(7):
		var y: float = -55+float(j)*16
		draw_line(Vector2(-56,y),Vector2(56,y),Color("#9a7749"),3)
		for i in range(8):
			var x: float = -48+float(i)*14
			if season == 3:
				draw_circle(Vector2(x,y-2),2,Color("#797e63"))
			else:
				draw_line(Vector2(x,y),Vector2(x-1,y-10),Color("#63804d"),2)
				draw_line(Vector2(x,y-3),Vector2(x+5,y-10),Color("#85a65c"),1)
	draw_set_transform(Vector2.ZERO)

func _hay() -> void:
	_poly([Vector2(-24,-3),Vector2(-31,-28),Vector2(0,-59),Vector2(25,-30),Vector2(27,-3)],Color("#a88a54"))
	for i in range(10):
		var x: float = -24+float(i)*5.0
		draw_line(Vector2(x,-7),Vector2(x+float(i%3)*4,-27),Color("#cfad69"),1.5)
