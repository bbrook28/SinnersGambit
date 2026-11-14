// Candlelight pooled on the parchment; the pool slides with device tilt (`tilt`, about -1..1),
// as if the page were a real sheet under a fixed candle, and flickers (`flicker`). Tunables: ui/tuning.gd.
shader_type canvas_item;

uniform vec2 tilt = vec2(0.0);
uniform float strength = 0.14;
uniform float reach = 0.75;
uniform float flicker = 0.25;

void fragment() {
	vec4 c = COLOR;  // already texture x modulate in Godot 4
	// Three unrelated sines read as an irregular flame; the pool breathes and wavers a little.
	float f = sin(TIME * 7.3) * 0.5 + sin(TIME * 13.1 + 1.7) * 0.3 + sin(TIME * 2.9 + 0.4) * 0.4;
	vec2 light = vec2(0.62, 0.35) + tilt * 0.3 + vec2(sin(TIME * 5.1), cos(TIME * 4.3)) * 0.01 * flicker;
	float d = distance(UV * vec2(1.6, 1.0), light * vec2(1.6, 1.0));
	float pool = 1.0 - smoothstep(0.0, reach * (1.0 + 0.06 * flicker * f), d);
	float s = strength * (1.0 + flicker * f * 0.5);
	c.rgb *= 1.0 - strength * 0.5 + s * pool;
	COLOR = c;
}
