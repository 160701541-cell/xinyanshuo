extends RefCounted
## CAC-OSS-001: Godot 4.4 built-in MIT components; no new downloaded plugins.
## FastNoiseLite: deterministic terrain field. AStarGrid2D: actual obstruction-aware
## navigation. Neither can write economy, ownership or player save data.
const CELL: int = 48
const RIVER_MIN_Y: float = 2230.0
const RIVER_MAX_Y: float = 2521.0

var _noise: FastNoiseLite
var _nav: AStarGrid2D
var _grid_size := Vector2i.ZERO
var _world_extent := Vector2.ZERO
var _seed: int = 0
var _solid_cells: int = 0

func configure(world_seed: int, world_size: Vector2, footprints: Array[Rect2]) -> void:
	_seed = world_seed
	_world_extent = world_size
	_noise = FastNoiseLite.new()
	_noise.seed = world_seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 3
	_noise.frequency = 0.0035
	_grid_size = Vector2i(ceili(world_size.x / CELL), ceili(world_size.y / CELL))
	_nav = AStarGrid2D.new()
	_nav.region = Rect2i(Vector2i.ZERO, _grid_size)
	_nav.cell_size = Vector2(CELL, CELL)
	_nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_nav.update()
	# The river has just two bridges; it is not walkable water.
	for y in range(_grid_size.y):
		var pixel_y: float = (float(y) + 0.5) * CELL
		if pixel_y < RIVER_MIN_Y or pixel_y > RIVER_MAX_Y:
			continue
		for x in range(_grid_size.x):
			var pixel_x: float = (float(x) + 0.5) * CELL
			var crossing: bool = absf(pixel_x - 1035.0) < 54.0 or absf(pixel_x - 2800.0) < 54.0
			if not crossing:
				_nav.set_point_solid(Vector2i(x,y), true)
	for footprint in footprints:
		var low := Vector2i(floori(footprint.position.x / CELL), floori(footprint.position.y / CELL))
		var high := Vector2i(ceili(footprint.end.x / CELL), ceili(footprint.end.y / CELL))
		for y in range(maxi(0,low.y), mini(_grid_size.y,high.y)):
			for x in range(maxi(0,low.x), mini(_grid_size.x,high.x)):
				var center := Vector2((float(x)+0.5)*CELL,(float(y)+0.5)*CELL)
				if footprint.has_point(center):
					_nav.set_point_solid(Vector2i(x,y), true)
	_solid_cells = 0
	for y in range(_grid_size.y):
		for x in range(_grid_size.x):
			if _nav.is_point_solid(Vector2i(x,y)):
				_solid_cells += 1

func biome_value(point: Vector2) -> float:
	if _noise == null:
		return 0.0
	return _noise.get_noise_2d(point.x,point.y)

func _cell(point: Vector2) -> Vector2i:
	return Vector2i(clampi(floori(point.x/CELL),0,_grid_size.x-1),
			clampi(floori(point.y/CELL),0,_grid_size.y-1))

func is_walkable(point: Vector2) -> bool:
	if _nav == null or point.x < 0.0 or point.y < 0.0 or point.x >= _world_extent.x or point.y >= _world_extent.y:
		return false
	return not _nav.is_point_solid(_cell(point))

func find_path(start: Vector2, goal: Vector2) -> PackedVector2Array:
	# No "fake" path from a blocked doorway to avoid violating wall collision.
	if not is_walkable(start) or not is_walkable(goal):
		return PackedVector2Array()
	return _nav.get_point_path(_cell(start),_cell(goal))

func get_stats() -> Dictionary:
	return {"noise":"Godot FastNoiseLite", "navigation":"Godot AStarGrid2D",
			"grid_width":_grid_size.x,"grid_height":_grid_size.y,
			"blocked_cells":_solid_cells,"seed":_seed,"license":"MIT (Godot Engine)"}
