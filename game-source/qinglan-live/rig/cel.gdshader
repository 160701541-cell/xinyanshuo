shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 shade_tint : source_color = vec4(0.52, 0.58, 0.72, 1.0);
uniform float bands = 3.0;
uniform float rim_power = 0.35;

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 0.95;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float q = clamp(ndl, 0.0, 1.0);
	float step_ = floor(q * bands + 0.5) / bands;
	step_ = clamp(step_, 0.0, 1.0);
	vec3 lit = LIGHT_COLOR * ATTENUATION * step_;
	vec3 shadow = shade_tint.rgb * 0.42;
	DIFFUSE_LIGHT += (lit + shadow * (1.0 - step_)) / PI;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	DIFFUSE_LIGHT += LIGHT_COLOR * fres * rim_power * 0.12;
}
