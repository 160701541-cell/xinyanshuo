extends RefCounted
## Offline authoring only. Never generate a 2k/8k image on the phone's main thread.
## North is -Z, west is -X. Coordinates and elevations are in metres.

const CITY_HALF := 250.0
const CITY_ELEVATION := 26.0
const WATER_ELEVATION := 12.0
const INITIAL_SIZE := 2048 # 24m padding around the requested +/-1000m play area.
const MAX_SIZE := 8192
const PALETTE := [Color("586d3d"), Color("82745b"), Color("87919a"),
    Color("c3b58a"), Color("9da29e")]

var noise := FastNoiseLite.new()

func _init() -> void:
    noise.seed = 160701541
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = 5
    noise.frequency = 0.003

func height_at(x: float, z: float) -> float:
    var n := noise.get_noise_2d(x, z)
    # Separate broad mountain envelopes preserve the north/west alignment.
    var north := smoothstep(240.0, 800.0, -z)
    var west := smoothstep(280.0, 850.0, -x)
    var ridge := pow(1.0 - absf(n), 2.0)
    var mountains := north * (85.0 + 150.0 * ridge) + west * (60.0 + 130.0 * ridge)
    # A low southeastern basin gives the beach/water height rule real coverage.
    var basin := smoothstep(450.0, 950.0, x) * smoothstep(450.0, 950.0, z)
    var natural := 17.0 + n * 5.0 + mountains - basin * 10.0
    var edge := maxf(absf(x), absf(z))
    var city_blend := 1.0 - smoothstep(CITY_HALF, CITY_HALF + 65.0, edge)
    return lerpf(natural, CITY_ELEVATION, city_blend)

func urban_paving_at(x: float, z: float) -> bool:
    # IMPORTANT: a flat city lot is NOT a paved 500 x 500m tile field.
    # Keep grass under the broader urban footprint; apply paving only to
    # actual narrow paths and to the existing central house foundation.
    var on_street: bool = (absf(x) <= 2.5 and absf(z) <= 235.0) or (absf(z) <= 2.5 and absf(x) <= 235.0)
    var home_footprint: bool = absf(x) <= 8.0 and absf(z) <= 4.0
    return on_street or home_footprint

func rule(height: float, slope: float, city: bool) -> Vector3:
    # x/y = base/overlay texture IDs, z = overlay blend; explicit paint overrides auto.
    if city:
        return Vector3(4, 4, 0)
    if height < WATER_ELEVATION + 2.0:
        return Vector3(3, 3, 0)
    if slope < 15.0:
        return Vector3(0, 0, 0)
    if slope < 30.0:
        return Vector3(0, 1, smoothstep(15.0, 30.0, slope))
    if slope < 35.0:
        return Vector3(1, 2, smoothstep(30.0, 35.0, slope))
    return Vector3(2, 2, 0)

func generate(tree: SceneTree, size: int = INITIAL_SIZE) -> Dictionary:
    assert(size >= 512 and size <= MAX_SIZE and size % 512 == 0)
    var height := Image.create(size, size, false, Image.FORMAT_RF)
    var control := Image.create(size, size, false, Image.FORMAT_RF)
    var color := Image.create(size, size, false, Image.FORMAT_RGBA8)
    var half := float(size) * 0.5
    var range_m := Vector2(INF, -INF)
    var counts := PackedInt64Array([0, 0, 0, 0, 0])
    for z in size:
        for x in size:
            var h := height_at(float(x) - half, float(z) - half)
            height.set_pixel(x, z, Color(h, 0, 0))
            range_m.x = minf(range_m.x, h)
            range_m.y = maxf(range_m.y, h)
        if z % 64 == 0:
            await tree.process_frame
    var bits := PackedByteArray()
    bits.resize(4)
    for z in size:
        for x in size:
            var dx := (height.get_pixel(mini(x + 1, size - 1), z).r - height.get_pixel(maxi(x - 1, 0), z).r) / (1.0 if x == 0 or x == size - 1 else 2.0)
            var dz := (height.get_pixel(x, mini(z + 1, size - 1)).r - height.get_pixel(x, maxi(z - 1, 0)).r) / (1.0 if z == 0 or z == size - 1 else 2.0)
            var slope := rad_to_deg(atan(sqrt(dx * dx + dz * dz)))
            var city := absf(float(x) - half) <= CITY_HALF and absf(float(z) - half) <= CITY_HALF
            var paving_only: bool = city and urban_paving_at(float(x) - half, float(z) - half)
            var r := rule(height.get_pixel(x, z).r, slope, paving_only)
            var blend := int(round(r.z * 255.0))
            # Terrain3D 1.0.2 control encoding. Bit 0 AUTO remains off for baked rules.
            bits.encode_u32(0, (int(r.x) << 27) | (int(r.y) << 22) | (blend << 14))
            control.set_pixel(x, z, Color(bits.decode_float(0), 0, 0))
            color.set_pixel(x, z, PALETTE[int(r.x)].lerp(PALETTE[int(r.y)], r.z))
            counts[int(r.y) if r.z > 0.5 else int(r.x)] += 1
        if z % 64 == 0:
            await tree.process_frame
    return {"height": height, "control": control, "color": color,
        "range_m": range_m, "coverage_pixels": Array(counts), "size": size}
