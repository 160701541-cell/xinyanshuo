shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform vec3 head_c = vec3(0.0, 1.60, 0.0);
uniform vec3 head_r = vec3(0.10, 0.12, 0.10);
uniform vec3 skin : source_color = vec3(0.86, 0.72, 0.56);
uniform vec3 ink : source_color = vec3(0.07, 0.06, 0.06);
uniform vec3 lip : source_color = vec3(0.55, 0.22, 0.20);
uniform vec3 hair : source_color = vec3(0.10, 0.09, 0.10);

varying vec3 vpos;
varying vec3 vnrm;

void vertex() {
	vpos = VERTEX;
	vnrm = NORMAL;
}

vec2 rot(vec2 p, float a) {
	float c = cos(a); float s = sin(a);
	return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}

float ell(vec2 p, vec2 c, vec2 r) {
	return length((p - c) / r);
}

void fragment() {
	vec3 p = vpos;
	vec2 q = vec2((p.x - head_c.x) / head_r.x, (p.y - head_c.y) / head_r.y);
	float wz = (p.z - head_c.z) / head_r.z;
	vec3 col = skin;
	// 头发：发际线随“前后”插值 —— 正面高、后脑低，保证后脑勺也有头发
	float hairline = mix(-0.18, 0.66, smoothstep(0.10, -0.70, wz));
	hairline += 0.07 * cos(q.x * 2.6) * smoothstep(-0.20, 0.40, wz);
	if (q.y > hairline || abs(q.x) > 0.84) {
		col = hair;
	}
	// 面向遮罩：只有真正朝前的像素才画五官，侧面/背面不画
	float facing = normalize(vnrm).z;
	if (wz > 0.12 && facing > 0.32 && q.y < hairline) {
		// 五官已改为独立贴片，这里只保留鼻影
		float ns = ell(q, vec2(0.0, -0.22), vec2(0.035, 0.14));
		col = mix(col, col * 0.90, step(ns, 1.0) * 0.6);
	}
	ALBEDO = col;
	ROUGHNESS = 0.82;
}
