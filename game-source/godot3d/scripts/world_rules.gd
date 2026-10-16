extends RefCounted
## Seeded mainland terrain, metres in Godot Y-up space.
## No copyrighted heightmap, data service, engine plugin or live network request.
const SECTOR_METERS: float = 512.0
var seed: int = 20261016
var hills: FastNoiseLite
var detail: FastNoiseLite
var ecology: FastNoiseLite

func configure(value: int) -> void:
	seed = value
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
	var mountains: float = hills.get_noise_2d(x,z) * 19.0
	var fine: float = detail.get_noise_2d(x,z) * 1.6
	var base: float = mountains + fine
	# Authentic settlement site preparation: 3D buildings have supported foundations.
	var dx: float = maxf(0.0, absf(x)-137.0)
	var dz: float = maxf(0.0, absf(z)-130.0)
	var dist: float = sqrt(dx*dx+dz*dz)
	var flatten: float = 1.0 - smoothstep(6.0,52.0,dist)
	base = lerpf(base, 0.0,flatten)
	# A shallow south-eastern river valley retained outside the settlement.
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
	return {"seed":seed,"river":"seeded shallow valley","noise":"Godot FastNoiseLite MIT"}
