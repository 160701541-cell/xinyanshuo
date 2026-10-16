extends RefCounted
## Reuses the actual original Canglan 3D Terrain3D authoring height function.
const OriginalTerrainField = preload("res://scripts/terrain/heightfield.gd")
## Seeded mainland terrain, metres in Godot Y-up space.
## No copyrighted heightmap, data service, engine plugin or live network request.
const SECTOR_METERS: float = 512.0
var seed: int = 20261016
var original_terrain: RefCounted
var hills: FastNoiseLite
var detail: FastNoiseLite
var ecology: FastNoiseLite

func configure(value: int) -> void:
	seed = value
	original_terrain = OriginalTerrainField.new()
	hills = FastNoiseLite.new()
	hills.seed = value
	hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	hills.fractal_type = FastNoiseLite.FRACTAL_FBM
	hills.fractal_octaves = 4
	hills.frequency = 0.0027
	detail = FastNoiseLite.new()
	detail.seed = value + 137
	detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	detail.frequency = 0.029
	ecology = FastNoiseLite.new()
	ecology.seed = value + 701
	ecology.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ecology.frequency = 0.006

func height_at(x: float, z: float) -> float:
	# Preserve the REAL prior Canglan world's northern/western mountain
	# envelopes, 500m original city plateau and terrain authoring coordinates.
	# Translate its 26m city datum to this gameplay mesh's y=0 origin.
	var baseline: float = float(original_terrain.call("height_at",x,z)) - OriginalTerrainField.CITY_ELEVATION
	var micro: float = detail.get_noise_2d(x,z) * 0.36
	var base: float = baseline + micro
	# Physical foundations for current newly generated compact settlement.
	var dx: float = maxf(0.0, absf(x)-137.0)
	var dz: float = maxf(0.0, absf(z)-130.0)
	var dist: float = sqrt(dx*dx+dz*dz)
	var flatten: float = 1.0 - smoothstep(6.0,52.0,dist)
	base = lerpf(base, 0.0,flatten)
	# Small tributary route for this technical slice only; the historical
	# terrain generator and original main-game river remain untouched.
	var river_axis: float = 270.0 + sin(x*0.003)*37.0
	var d: float = absf(z-river_axis)
	if d < 45.0:
		base = minf(base, -4.2 + smoothstep(0.0,45.0,d)*3.8)
	return base

func biome_at(x: float, z: float) -> float:
	return ecology.get_noise_2d(x,z)

func is_river(x: float,z: float) -> bool:
	return absf(z-(270.0+sin(x*0.003)*37.0)) < 29.0

func settlement_zone(col: int,row: int) -> String:
	if row==1 and col==2:
		return "temple"
	if row==1 and col==3:
		return "school"
	if row==2 and col in [2,3]:
		return "market"
	var names := ["farmhouse","home","teahouse","workshop","inn","granary","shop","warehouse"]
	return names[posmod(col*7+row*11+seed,names.size())]

func stats() -> Dictionary:
	return {"seed":seed,"river":"technical tributary valley","noise":"Godot FastNoiseLite MIT", "height_source":"original Canglan Terrain3D heightfield.gd"}
