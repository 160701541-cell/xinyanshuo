shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform float side = 1.0;     // -1 左眼 +1 右眼
uniform vec3 sclera : source_color = vec3(0.97, 0.96, 0.94);
uniform vec3 pupil : source_color = vec3(0.06, 0.05, 0.05);
uniform vec3 lid : source_color = vec3(0.10, 0.08, 0.08);

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.x *= side;
	// 眼形：横向椭圆，外眼角略上挑
	vec2 q = p;
	q.y += 0.10 * q.x;
	float d = length(vec2(q.x / 0.92, q.y / 0.60));
	float a = 1.0 - smoothstep(0.92, 1.0, d);
	vec3 col = sclera;
	// 瞳孔
	float pd = length((p - vec2(0.06, -0.04)) / vec2(0.30, 0.38));
	col = mix(col, pupil, 1.0 - smoothstep(0.9, 1.0, pd));
	// 上眼睑压边
	float lidline = 1.0 - smoothstep(0.0, 0.10, abs(p.y - 0.58));
	col = mix(col, lid, lidline * 0.9);
	// 上眼睑以上的眼白不显示
	a *= 1.0 - smoothstep(0.30, 0.55, p.y);
	ALBEDO = col;
	ALPHA = a;
}
