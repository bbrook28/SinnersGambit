// Aged-surface grain for panels (parchment, dark frames). Applies to the node's own drawing only.
shader_type canvas_item;

uniform float amount = 0.08;
uniform float pixel = 4.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(FRAGCOORD.xy / pixel);
	float n = hash(cell) * 0.6 + hash(floor(cell / 6.0)) * 0.4;
	COLOR.rgb *= 1.0 - amount + amount * 2.0 * n;
}
