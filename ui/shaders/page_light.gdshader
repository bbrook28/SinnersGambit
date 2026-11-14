// Candlelight pooled on the parchment; the pool slides with device tilt (`tilt`, about -1..1),
// as if the page were a real sheet under a fixed candle. Tunables: ui/tuning.gd.
shader_type canvas_item;

uniform vec2 tilt = vec2(0.0);
uniform float strength = 0.14;
uniform float reach = 0.75;

void fragment() {
	vec4 c = COLOR;  // already texture x modulate in Godot 4
	vec2 light = vec2(0.62, 0.35) + tilt * 0.3;
	float d = distance(UV * vec2(1.6, 1.0), light * vec2(1.6, 1.0));
	float pool = 1.0 - smoothstep(0.0, reach, d);
	c.rgb *= 1.0 - strength * 0.5 + strength * pool;
	COLOR = c;
}
