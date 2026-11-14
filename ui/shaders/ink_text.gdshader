// Manuscript ink on text: uneven density (iron-gall ink pooling in the strokes) and a left-to-right
// reveal (`reveal` 0..1 across the words) with a wet, darker leading edge.
// Children that span the same width can share it with use_parent_material (the prompt's flourish).
shader_type canvas_item;

uniform float reveal = 1.0;
uniform float start = 0.0;        // px: where the words begin in the node (set by ui/main.gd)
uniform float width = 1000.0;     // px: how wide the words run
uniform float edge = 0.08;        // soft leading edge, fraction of the width
uniform float grain = 0.35;       // ink density variation

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec4 c = COLOR;  // already texture x modulate in Godot 4
	float n = noise(lp / 9.0) * 0.6 + noise(lp / 3.0) * 0.4;
	c.rgb *= 1.0 - grain * 0.5 + grain * n;
	float x = (lp.x - start) / max(width, 1.0);
	// Bleed: the edge wanders a little up and down the line, like ink soaking into parchment.
	// reveal 0: the front sits left of the words; 1: past their right end, edge and wobble included.
	float front = mix(-0.05, 1.0 + edge * 1.5, reveal) + (noise(vec2(lp.y / 14.0, 3.0)) - 0.5) * edge * 0.6;
	float shown = 1.0 - smoothstep(front - edge, front, x);
	float wet = smoothstep(front - edge * 2.0, front - edge * 0.5, x) * shown;
	c.rgb *= 1.0 - 0.35 * wet;
	c.a *= shown;
	COLOR = c;
}
