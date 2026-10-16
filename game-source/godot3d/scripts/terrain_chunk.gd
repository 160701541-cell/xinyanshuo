extends MeshInstance3D
## Deterministic streamable terrain chunk with physical collision.
## 96m x 96m, native Godot SurfaceTool mesh; no static image backdrop.
const CHUNK_METERS: float = 96.0
const GRID: int = 24
const CELL: float = CHUNK_METERS / GRID
var chunk_coords: Vector2i
var source_seed: int
var _body: StaticBody3D

func build(coords: Vector2i, rules: RefCounted) -> void:
	chunk_coords = coords
	source_seed = int(rules.get("seed"))
	position = Vector3(float(coords.x)*CHUNK_METERS,0.0,float(coords.y)*CHUNK_METERS)
	name = "Terrain_%d_%d" % [coords.x,coords.y]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(GRID):
		for x in range(GRID):
			var gx: float = position.x + float(x)*CELL
			var gz: float = position.z + float(z)*CELL
			var a: Vector3 = Vector3(float(x)*CELL, float(rules.call("height_at",gx,gz)), float(z)*CELL)
			var b: Vector3 = Vector3(float(x)*CELL, float(rules.call("height_at",gx,gz+CELL)), float(z+1)*CELL)
			var c: Vector3 = Vector3(float(x+1)*CELL, float(rules.call("height_at",gx+CELL,gz)),float(z)*CELL)
			var d: Vector3 = Vector3(float(x+1)*CELL,float(rules.call("height_at",gx+CELL,gz+CELL)),float(z+1)*CELL)
			_push_triangle(st,a,b,c,rules,Vector2(gx+CELL*0.33,gz+CELL*0.33))
			_push_triangle(st,c,b,d,rules,Vector2(gx+CELL*0.67,gz+CELL*0.67))
	st.generate_normals()
	mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat
	_body = StaticBody3D.new()
	_body.name = "GroundCollision"
	add_child(_body)
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	_body.add_child(shape)

func _push_triangle(st: SurfaceTool, a: Vector3,b: Vector3,c: Vector3,
		rules: RefCounted,center: Vector2) -> void:
	var h: float = (a.y+b.y+c.y)/3.0
	var bio: float = float(rules.call("biome_at",center.x,center.y))
	var c1 := Color("#5d825c")
	if h < -2.5:
		c1 = Color("#b5aa85")
	elif h > 14.0:
		c1 = Color("#8e9688")
	elif bio > 0.25:
		c1 = Color("#71905e")
	elif bio < -0.23:
		c1 = Color("#6c815d")
	var noise_tint: float = clampf(bio*0.20+0.04,-0.15,0.17)
	c1 = c1.lightened(noise_tint) if noise_tint>=0.0 else c1.darkened(-noise_tint)
	for point in [a,b,c]:
		st.set_color(c1)
		st.add_vertex(point)

func sample_count() -> int:
	return (GRID+1)*(GRID+1)
