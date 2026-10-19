shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, fog_disabled;

uniform vec3 zenith : source_color = vec3(0.35, 0.52, 0.62);
uniform vec3 horizon : source_color = vec3(0.90, 0.90, 0.86);

void fragment() {
	float t = clamp(normalize(VERTEX).y * 1.7 + 0.12, 0.0, 1.0);
	t = pow(t, 0.85);
	ALBEDO = mix(horizon, zenith, t);
}
