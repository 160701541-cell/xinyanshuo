extends Control
class_name XianfanRouteCanvas

# Native Godot route schematic. Location/edge identities come from the same
# route rules used by actual movement; it does not pretend to be full atlas art.
signal location_tapped(place: String)
const WIDTH := 650.0
const HEIGHT := 365.0
const POINTS := {
    "石桥村·家中":Vector2(120,230),
    "石桥村·街口":Vector2(205,213),
    "石桥村·溪边":Vector2(165,302),
    "石桥村·林缘":Vector2(70,302),
    "临安县城·旧书铺":Vector2(441,225),
    "临安县城·东市":Vector2(515,246),
    "青云山门·山门外":Vector2(552,69)
}
const EDGES := [
    ["石桥村·家中","石桥村·街口"],
    ["石桥村·家中","石桥村·溪边"],
    ["石桥村·家中","石桥村·林缘"],
    ["石桥村·街口","石桥村·溪边"],
    ["石桥村·林缘","石桥村·溪边"],
    ["石桥村·家中","临安县城·东市"],
    ["临安县城·东市","临安县城·旧书铺"],
    ["临安县城·东市","青云山门·山门外"]
]
var current_place: String=""
var _font: Font

func _ready() -> void:
    custom_minimum_size=Vector2(0,252)
    mouse_filter=Control.MOUSE_FILTER_STOP
    _font=ThemeDB.fallback_font
    resized.connect(queue_redraw)

func set_position_place(place: String) -> void:
    current_place=place
    queue_redraw()

func _pt(p: Vector2) -> Vector2:
    return Vector2(p.x/WIDTH*size.x,p.y/HEIGHT*size.y)

func _draw() -> void:
    if size.x<=0 or size.y<=0: return
    draw_rect(Rect2(Vector2.ZERO,size),Color("#F1EBD9"),true)
    # Streams, road corridors and softly colored settlement zones.
    var villages:=_pt(Vector2(155,255))
    var county:=_pt(Vector2(483,235))
    var ridge:=_pt(Vector2(552,66))
    draw_circle(villages,54.0*size.x/WIDTH,Color("#D7E2D3"))
    draw_circle(county,54.0*size.x/WIDTH,Color("#E7D4BB"))
    draw_circle(ridge,58.0*size.x/WIDTH,Color("#D9E2E7"))
    draw_line(_pt(Vector2(30,330)),_pt(Vector2(222,318)),Color("#8BB6C1"),4.5,true)
    for edge in EDGES:
        var a: Vector2=_pt(POINTS[str(edge[0])])
        var b: Vector2=_pt(POINTS[str(edge[1])])
        draw_line(a,b,Color("#B49B77"),2.8,true)
    var scale_factor:=size.x/WIDTH
    for loc in POINTS:
        var origin: Vector2=_pt(POINTS[loc])
        var chosen:=str(loc)==current_place
        draw_circle(origin,9.0*scale_factor,Color("#327B6B") if chosen else Color("#B48B68"))
        draw_circle(origin,4.0*scale_factor,Color.WHITE)
        var title:=str(loc).get_slice("·",1)
        var vertical: float= -15.0 if origin.y>size.y*0.27 else 20.0
        var at:=origin+Vector2(-32.0*scale_factor,vertical)
        draw_string(_font,at,title,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#31473F"))
        if chosen:
            draw_arc(origin,14.0*scale_factor,0,TAU,30,Color("#327B6B"),2.0,true)

func _gui_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT):
        return
    var click: Vector2=event.position
    var nearest: String=""
    var distance:=INF
    for name in POINTS:
        var offset:=click.distance_to(_pt(POINTS[name]))
        if offset<distance:
            distance=offset
            nearest=str(name)
    if not nearest.is_empty() and distance<maxf(32.0,24.0*size.x/WIDTH):
        location_tapped.emit(nearest)
        accept_event()
