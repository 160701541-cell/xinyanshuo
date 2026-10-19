class_name VoxelBuilder
extends RefCounted

const VOX := 0.25
var solid := {}      # Vector3i -> Color
var emissive := {}   # Vector3i -> Color

func put(x:int,y:int,z:int,c:Color) -> void:
	solid[Vector3i(x,y,z)] = Color(c.r, c.g, c.b).srgb_to_linear()

func put_e(x:int,y:int,z:int,c:Color) -> void:
	emissive[Vector3i(x,y,z)] = Color(c.r, c.g, c.b).srgb_to_linear()

func box(x0:int,y0:int,z0:int,x1:int,y1:int,z1:int,c:Color,jitter:=0.0) -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = hash(Vector3i(x0,y0,z0))
	for x in range(x0,x1):
		for y in range(y0,y1):
			for z in range(z0,z1):
				var k := 1.0 + (rnd.randf()-0.5)*2.0*jitter
				put(x,y,z, Color(c.r*k, c.g*k, c.b*k, 1.0))

func box_e(x0:int,y0:int,z0:int,x1:int,y1:int,z1:int,c:Color) -> void:
	for x in range(x0,x1):
		for y in range(y0,y1):
			for z in range(z0,z1):
				emissive[Vector3i(x,y,z)] = Color(c.r, c.g, c.b).srgb_to_linear()

func sphere(cx:int,cy:int,cz:int,r:float,c:Color,jitter:=0.06) -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = hash(Vector3i(cx,cy,cz))
	for x in range(cx-int(r)-1, cx+int(r)+2):
		for y in range(cy-int(r)-1, cy+int(r)+2):
			for z in range(cz-int(r)-1, cz+int(r)+2):
				var d := Vector3(x-cx, y-cy, z-cz).length()
				if d <= r:
					var k := 1.0 + (rnd.randf()-0.5)*2.0*jitter
					put(x,y,z, Color(c.r*k, c.g*k, c.b*k, 1.0))

func box_occ(p:Vector3i) -> bool:
	return solid.has(p) or emissive.has(p)

const FACES := [
	[Vector3i(0,0,1),  Vector3i(1,0,0), Vector3i(0,1,0)],
	[Vector3i(0,0,-1), Vector3i(0,1,0), Vector3i(1,0,0)],
	[Vector3i(1,0,0),  Vector3i(0,1,0), Vector3i(0,0,1)],
	[Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,1,0)],
	[Vector3i(0,1,0),  Vector3i(0,0,1), Vector3i(1,0,0)],
	[Vector3i(0,-1,0), Vector3i(1,0,0), Vector3i(0,0,1)],
]
const CORNERS := [Vector2i(-1,-1), Vector2i(1,-1), Vector2i(1,1), Vector2i(-1,1)]

func build(mat_solid:Material, mat_emis:Material) -> Array:
	var out := []
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh_quads(st, solid, [0.0])
	var m1 := st.commit()
	if m1 != null:
		var mi := MeshInstance3D.new(); mi.mesh = m1; mi.material_override = mat_solid
		out.append(mi)
	if emissive.size() > 0:
		var st2 := SurfaceTool.new()
		st2.begin(Mesh.PRIMITIVE_TRIANGLES)
		_mesh_quads(st2, emissive, [0.0])
		var m2 := st2.commit()
		var mi2 := MeshInstance3D.new(); mi2.mesh = m2; mi2.material_override = mat_emis
		out.append(mi2)
	return out

func _mesh_quads(st:SurfaceTool, data:Dictionary, max_layers:Array) -> void:
	for p in data.keys():
		var col:Color = data[p]
		for f in FACES:
			var d:Vector3i = f[0]
			if box_occ(p+d): continue
			var u:Vector3i = f[1]
			var v:Vector3i = f[2]
			var idx := [0,2,1, 0,3,2]
			for i in idx:
				var cs:Vector2i = CORNERS[i]
				var s1 := 1 if box_occ(p+d+u*cs.x) else 0
				var s2 := 1 if box_occ(p+d+v*cs.y) else 0
				var s3 := 1 if box_occ(p+d+u*cs.x+v*cs.y) else 0
				var shade := 0.55 + 0.15*(3-(s1+s2+s3))
				st.set_color(Color(col.r*shade, col.g*shade, col.b*shade, 1.0))
				st.set_normal(Vector3(d))
				var frac := Vector3(0.5,0.5,0.5) + Vector3(d)*0.5 + Vector3(u)*0.5*cs.x + Vector3(v)*0.5*cs.y
				st.add_vertex((Vector3(p)+frac)*VOX)
