// A Strike candle. snuffed 0 -> 1: the flame (above `cut` in the texture) goes out and the wax dims.
// COLOR is already texture x modulate (Godot 4): never multiply by texture(TEXTURE, UV) again.
// tone: a contrast curve on the colour only (alpha stays the texture's); 1 = the art as painted,
// 2 = the deeper look the candle was tuned with (tests/glass_check.gd).
shader_type canvas_item;

uniform float snuffed : hint_range(0.0, 1.0) = 0.0;
uniform float cut = 0.215;   // the flame's foot, as a fraction of the texture's height
uniform float tone = 2.0;

void fragment() {
	vec4 c = COLOR;
	c.rgb = pow(max(c.rgb, vec3(0.0)), vec3(tone));
	float flame = 1.0 - smoothstep(cut - 0.02, cut + 0.004, UV.y);
	c.a *= 1.0 - flame * snuffed;
	c.rgb *= mix(1.0, 0.72, snuffed);
	COLOR = c;
}
