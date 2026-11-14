// Screen transition: ink floods out from `origin` across the page (progress 0 -> 1 covers it),
// with a ragged, wet leading edge. Run progress back to 1 -> 0 and the ink draws away.
shader_type canvas_item;

uniform float progress = 0.0;
uniform vec2 origin = vec2(0.5, 0.5);   // UV
uniform float ratio = 1.95;             // height / width of the screen
uniform vec4 ink : source_color = vec4(0.07, 0.045, 0.035, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	return noise(p) * 0.55 + noise(p * 2.3) * 0.3 + noise(p * 5.1) * 0.15;
}

void fragment() {
	vec2 p = (UV - origin) * vec2(1.0, ratio);
	float maxd = length(max(abs(origin), abs(vec2(1.0) - origin)) * vec2(1.0, ratio));
	float f = length(p) / maxd + (fbm(UV * vec2(5.0, 5.0 * ratio)) - 0.5) * 0.45;
	float t = progress * 1.5 - 0.25;
	float a = 1.0 - smoothstep(t - 0.05, t, f);
	// Wet edge: a little lighter, browner where the ink is still spreading.
	float wet = smoothstep(t - 0.16, t - 0.02, f) * a;
	COLOR = vec4(ink.rgb + vec3(0.16, 0.08, 0.03) * wet, ink.a * a);
}
