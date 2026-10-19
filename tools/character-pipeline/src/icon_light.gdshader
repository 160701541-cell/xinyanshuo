shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque, blend_mix;

uniform float spec_k = 0.85;
uniform float rim_k = 0.32;
uniform vec3 rim_color : source_color = vec3(1.0, 0.90, 0.72);
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
uniform int pat_mode = 0;
uniform vec3 pat_col : source_color = vec3(0.10, 0.08, 0.06);
uniform float pat_density = 1.0;
uniform vec3 key_dir = vec3(-0.45, 0.82, -0.36);
uniform vec3 fill_dir = vec3(0.72, 0.10, -0.45);

varying vec3 vcol;

void vertex() {
	vcol = COLOR.rgb;
}

void fragment() {
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 v = normalize(VIEW);
	vec3 l = normalize(key_dir);
	vec3 f = normalize(fill_dir);
	float d = max(dot(n, l), 0.0);
	float d2 = max(dot(n, f), 0.0);
	vec3 h = normalize(l + v);
	float spec = pow(max(dot(n, h), 0.0), 46.0) * spec_k;
	float rim = pow(1.0 - max(dot(n, v), 0.0), 2.2) * rim_k;
	// 天光 + 地面反弹：上方亮、下方暗且偏暖，才符合常识
	float sky = 0.34 + 0.30 * clamp(n.y, -1.0, 1.0);
	float bounce = 0.10 * clamp(-n.y, 0.0, 1.0);
	float key = 0.78 * d + 0.18 * d2;
	vec3 shadow_tint = vec3(sky * 0.92, sky * 0.96, sky * 1.05) + vec3(bounce * 1.1, bounce * 0.85, bounce * 0.65);
	vec3 lit_tint = vec3(1.05, 1.00, 0.92);
	vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 alb = vcol * tint;
	if (pat_mode == 1) {
		float b = sin(wp.y * 210.0 + sin(wp.z * 70.0) * 1.6);
		alb = mix(alb, pat_col, smoothstep(0.62, 0.94, b) * 0.88);
	} else if (pat_mode == 2) {
		vec2 g = abs(fract(vec2(wp.z * 24.0 * pat_density, wp.y * 30.0 * pat_density)) - 0.5);
		float e = smoothstep(0.34, 0.50, max(g.x, g.y));
		alb = mix(alb, pat_col, e * 0.72);
	} else if (pat_mode == 4) {
		float ang = atan(wp.z, wp.x);
		float c = sin(ang * 24.0 + sin(wp.y * 16.0) * 0.55);
		float e = smoothstep(0.55, 0.98, c) * smoothstep(0.26, 0.02, wp.y);
		alb = mix(alb, pat_col, e * 0.42);
	} else if (pat_mode == 3) {
		float band = fract(wp.y * 85.0 + sin(wp.z * 26.0) * 0.28);
		float e = smoothstep(0.02, 0.20, band) * (1.0 - smoothstep(0.58, 0.66, band));
		alb = mix(alb, pat_col, e * 0.32);
	}
	vec3 base = min(alb * (shadow_tint + lit_tint * key), vec3(1.0));
	vec3 c = base + vec3(spec) + rim_color * rim * length(alb);
	ALBEDO = c;
}
