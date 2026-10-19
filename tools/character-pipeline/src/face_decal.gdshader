shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform int mode = 0;          // 0=眼 1=眉 2=嘴
uniform float side = 1.0;
uniform vec3 sclera : source_color = vec3(0.97, 0.96, 0.93);
uniform vec3 pupil : source_color = vec3(0.06, 0.05, 0.05);
uniform vec3 browc : source_color = vec3(0.09, 0.07, 0.07);
uniform vec3 lipc : source_color = vec3(0.55, 0.18, 0.17);

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.x *= side;
	float a = 0.0;
	vec3 col = sclera;

	if (mode == 0) {
		// 细长上挑的眼：横 1 : 竖 0.42
		vec2 q = p;
		q.y += 0.18 * q.x;
		float d = length(vec2(q.x / 0.95, q.y / 0.42));
		a = 1.0 - smoothstep(0.90, 1.0, d);
		float pd = length((p - vec2(0.10, -0.02)) / vec2(0.26, 0.30));
		col = mix(col, pupil, 1.0 - smoothstep(0.88, 1.0, pd));
		// 上睑压边 + 切掉上三分之一
		float lidline = 1.0 - smoothstep(0.0, 0.10, abs(p.y - 0.30));
		col = mix(col, pupil, lidline * 0.85);
		a *= 1.0 - smoothstep(0.34, 0.56, p.y);
	} else if (mode == 1) {
		// 斜挑的眉：细长椭圆
		vec2 q = p;
		q.y += 0.22 * q.x;
		float d = length(vec2(q.x / 0.92, q.y / 0.34));
		a = 1.0 - smoothstep(0.75, 1.0, d);
		col = browc;
	} else {
		// 嘴：上唇 + 下唇 + 中缝
		float up = length(vec2(p.x / 0.86, (p.y - 0.16) / 0.30));
		float dn = length(vec2(p.x / 0.80, (p.y + 0.24) / 0.34));
		a = max(1.0 - smoothstep(0.86, 1.0, up), 1.0 - smoothstep(0.86, 1.0, dn));
		col = lipc;
		float seam = 1.0 - smoothstep(0.0, 0.12, abs(p.y));
		col = mix(col, lipc * 0.35, seam);
	}
	ALBEDO = col;
	ALPHA = a;
}
