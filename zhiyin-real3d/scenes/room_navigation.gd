extends RefCounted
## Tiny apartment 0.16m grid navigation. Prevents walking through furniture.
## It is a real AStarGrid2D pathfinder on X/Z, not a straight-line lerp.
const WIDTH: int = 20
const CELL: float = 0.16
const ROOM_HALF: float = 1.6
const CLEARANCE: float = 0.13
var grid: AStarGrid2D
var obstacle_count: int = 0

func setup(items: Array) -> void:
    grid = AStarGrid2D.new()
    grid.region = Rect2i(0, 0, WIDTH, WIDTH)
    grid.cell_size = Vector2.ONE
    grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    grid.update()
    obstacle_count = 0
    for y in range(WIDTH):
        for x in range(WIDTH):
            var pos = world_from_cell(Vector2i(x,y))
            for item in items:
                if str(item["id"])=="rug":
                    continue # floor rug is walkable; do not block the path.
                var at: Vector2 = item["at"]
                var dimensions: Vector3 = item["dims"]
                if absf(pos.x-at.x) < dimensions.x*0.5+CLEARANCE and absf(pos.y-at.y)<dimensions.z*0.5+CLEARANCE:
                    grid.set_point_solid(Vector2i(x,y),true)
                    obstacle_count+=1
                    break

func cell_from_world(pos: Vector2) -> Vector2i:
    return Vector2i(
        clampi(int(floor((pos.x+ROOM_HALF)/CELL)),0,WIDTH-1),
        clampi(int(floor((pos.y+ROOM_HALF)/CELL)),0,WIDTH-1))

func world_from_cell(id: Vector2i) -> Vector2:
    return Vector2(-ROOM_HALF+(float(id.x)+0.5)*CELL,
        -ROOM_HALF+(float(id.y)+0.5)*CELL)

func is_free_world(pos: Vector2) -> bool:
    if grid==null:
        return false
    return not grid.is_point_solid(cell_from_world(pos))

func _closest_free(pos: Vector2) -> Vector2i:
    var p:=cell_from_world(pos)
    if not grid.is_point_solid(p):
        return p
    for radius in range(1,WIDTH):
        var near:=Vector2i(-1,-1)
        var shortest:=INF
        for y in range(maxi(0,p.y-radius),mini(WIDTH,p.y+radius+1)):
            for x in range(maxi(0,p.x-radius),mini(WIDTH,p.x+radius+1)):
                var test:=Vector2i(x,y)
                if grid.is_point_solid(test):
                    continue
                var d:=world_from_cell(test).distance_squared_to(pos)
                if d<shortest:
                    near=test
                    shortest=d
        if near.x>=0:
            return near
    return Vector2i(-1,-1)

func nearest_furniture_path(start: Vector2, object: Dictionary) -> Array[Vector3]:
    var output: Array[Vector3]=[]
    if grid==null:
        return output
    var begin:=_closest_free(start)
    if begin.x<0:
        return output
    var target: Vector2=object["at"]
    var dim: Vector3=object["dims"]
    var best_len:=INF
    # Try approach points on each side. Feet stop 0.20m outside furniture.
    var offsets=[
        Vector2(dim.x*.5+0.22,0.0),Vector2(-dim.x*.5-0.22,0.0),
        Vector2(0.0,dim.z*.5+0.22),Vector2(0.0,-dim.z*.5-0.22),
        Vector2(dim.x*.5+0.23,dim.z*.5+0.23),
        Vector2(-dim.x*.5-0.23,dim.z*.5+0.23),
        Vector2(dim.x*.5+0.23,-dim.z*.5-0.23),
        Vector2(-dim.x*.5-0.23,-dim.z*.5-0.23)
    ]
    for offset in offsets:
        var approach: Vector2=target+offset
        if absf(approach.x)>=ROOM_HALF-0.08 or absf(approach.y)>=ROOM_HALF-0.08:
            continue
        if not is_free_world(approach):
            continue
        var dest:=cell_from_world(approach)
        var ids:=grid.get_id_path(begin,dest)
        if ids.is_empty():
            continue
        if ids.size()<best_len:
            output.clear()
            for id in ids:
                var p:=world_from_cell(id)
                output.append(Vector3(p.x,0.0,p.y))
            best_len=ids.size()
    return output

func path_is_clear(path: Array[Vector3]) -> bool:
    for p in path:
        if not is_free_world(Vector2(p.x,p.z)):
            return false
    return true
