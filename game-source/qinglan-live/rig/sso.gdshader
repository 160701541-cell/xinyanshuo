shader_type spatial;
// 屏幕空间恒定粗细描边（近景专用），沿投影法线外扩
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;
uniform vec3 line_color : source_color = vec3(0.078, 0.086, 0.102);
uniform float px = 1.8;
uniform vec2 viewport = vec2(1920.0, 1080.0);

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 nclip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(NORMAL, 0.0);
	vec2 dir = normalize(nclip.xy + vec2(1e-5));
	clip.xy += dir * px * 2.0 / viewport * clip.w;
	POSITION = clip;
}

void fragment() {
	ALBEDO = line_color;
}
