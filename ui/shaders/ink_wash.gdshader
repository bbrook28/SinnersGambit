// Screen transition: ink and candle smoke billow out from `origin` (progress 0 -> 1 covers the
// screen). Full-resolution noise, domain-warped and drifting upward, so the edge is a soft curling
// smoke front with a darker wet ink core behind it. Run progress back to 0 and it draws away.
shader_type canvas_item;

uniform float progress = 0.0;
uniform vec2 origin = vec2(0.5, 0.5);   // UV
uniform float ratio = 1.95;             // height / width of the screen
uniform vec4 ink : source_color = vec4(0.07, 0.045, 0.035, 1.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);  // quintic: no grid creases
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 6; i++) {
		v += a * noise(p);
		p = r * p * 2.03 + 11.7;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 q = UV * vec2(4.0, 4.0 * ratio);
	float t = TIME * 0.12;
	// Domain warp: the smoke curls instead of growing as a blob.
	vec2 w = vec2(fbm(q + vec2(0.0, t)), fbm(q + vec2(5.2, 1.3 - t)));
	float n = fbm(q + 2.2 * w + vec2(0.0, -t * 2.0));
	vec2 p = (UV - origin) * vec2(1.0, ratio);
	float maxd = length(max(abs(origin), abs(vec2(1.0) - origin)) * vec2(1.0, ratio));
	float f = length(p) / maxd + (n - 0.5) * 0.7;
	float front = progress * 1.7 - 0.35;
	// Smoke: a soft, wide, wispy edge. Ink: the solid core a little behind it.
	float smoke = 1.0 - smoothstep(front - 0.22, front + 0.04, f);
	float core = 1.0 - smoothstep(front - 0.32, front - 0.12, f);
	float wisps = smoothstep(0.35, 0.75, n);
	float a = clamp(core + smoke * (0.45 + 0.55 * wisps), 0.0, 1.0);
	vec3 smoke_col = mix(ink.rgb, vec3(0.2, 0.15, 0.12), 0.6);
	vec3 col = mix(smoke_col, ink.rgb, core);
	COLOR = vec4(col, ink.a * a);
}
