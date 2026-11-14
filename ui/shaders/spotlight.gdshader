// Tutorial: darkens the screen except a soft-edged rounded rect (the thing being explained).
shader_type canvas_item;

uniform vec4 rect = vec4(0.4, 0.4, 0.2, 0.1);   // x, y, w, h as fractions of the screen
uniform float aspect = 1.95;                     // height / width
uniform float radius = 0.03;                     // corner radius, fraction of width
uniform float soft = 0.02;
uniform float dim = 0.74;

void fragment() {
	vec2 p = UV * vec2(1.0, aspect);
	vec2 c = (rect.xy + rect.zw * 0.5) * vec2(1.0, aspect);
	vec2 half_size = rect.zw * 0.5 * vec2(1.0, aspect);
	vec2 q = abs(p - c) - half_size + radius;
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	float a = smoothstep(0.0, soft, d) * dim;
	COLOR = vec4(0.02, 0.012, 0.01, a);
}
