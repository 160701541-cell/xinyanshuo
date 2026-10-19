extends Node3D
# 加载 C 生成的 1mm 体素 mesh，四视图 + 反转外壳描边
const Stage := preload("res://rig/stage.gd")
const OUTLINE_PX := 0.0035

var mat: ShaderMaterial
var out_mat: ShaderMaterial

func _make_materials() -> void:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
varying vec3 vcol;
varying float vdepth;
void vertex() { vcol = COLOR.rgb; vdepth = -VERTEX.z; }
void fragment() {
	float e = 1.0;
	vec2 px = SCREEN_PIXEL_SIZE * e;
	vec2 uv = SCREEN_UV;
	float d0 = vdepth;
	if (d0 < 4000.0) {
		float dc = 0.0;
		dc += step(0.001, texture(screen_tex, uv + vec2(px.x, 0.0)).r) * 0.0;
	}
	ALBEDO = vcol * vec3(0.86, 0.97, 1.04);
	ALPHA = 1.0;
}
"""
	mat = ShaderMaterial.new()
	mat.shader = sh

	var osh := Shader.new()
	osh.code = """
shader_type spatial;
render_mode unshaded, cull_front;
uniform float px = 2.0;
void vertex() { VERTEX += NORMAL * px * 0.001; }
void fragment() { ALBEDO = vec3(0.02, 0.02, 0.03); ALPHA = 1.0; }
"""
	out_mat = ShaderMaterial.new()
	out_mat.shader = osh

func load_mesh(path: String) -> ArrayMesh:
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "缺少 voxmesh.bin")
	var magic := f.get_buffer(4)
	var nm := f.get_32()
	var arr := []
	for k in nm:
		var vc := f.get_32()
		var ic := f.get_32()
		var pos := f.get_buffer(vc * 12).to_float32_array()
		var nrm := f.get_buffer(vc * 12).to_float32_array()
		var col := f.get_buffer(vc * 12).to_float32_array()
		var idx := f.get_buffer(ic * 4).to_int32_array()
		var a := []
		a.resize(Mesh.ARRAY_MAX)
		a[Mesh.ARRAY_VERTEX] = pos
		a[Mesh.ARRAY_NORMAL] = nrm
		a[Mesh.ARRAY_COLOR] = col
		a[Mesh.ARRAY_INDEX] = idx
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		# 按索引折行，避免单次提交过大
		return m
	return null

func _ready() -> void:
	Stage.setup(self, Color(0.03, 0.045, 0.062), 0.30)
	_make_materials()
	print("load start ", Time.get_ticks_msec())
	var mesh := load_mesh("res://out/voxmesh.bin")
	print("load done ", Time.get_ticks_msec(), " aabb=", mesh.get_aabb())
	var rots := [0.0, 40.0, 90.0, 180.0]
	var xs := [1.55, 0.52, -0.52, -1.55]
	for i in 4:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = Vector3(float(xs[i]), 0.0, 0.0)
		mi.rotation_degrees.y = float(rots[i])
		mi.extra_cull_margin = 0.1
		add_child(mi)
	Stage.camera(self, Vector3(0.0, 1.05, -6.4), Vector3(0.0, 1.02, 0.0), 20)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	for f in 8:
		await get_tree().process_frame
	await Shot.grab(self, "res://out/vox1mm_turn.png")
	get_tree().quit()
