// A Strike candle. snuffed 0 -> 1: the flame (above `cut` in the texture) goes out and the wax dims.
shader_type canvas_item;

uniform float snuffed : hint_range(0.0, 1.0) = 0.0;
uniform float cut = 0.215;   // the flame's foot, as a fraction of the texture's height

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float flame = 1.0 - smoothstep(cut - 0.02, cut + 0.004, UV.y);
	c.a *= 1.0 - flame * snuffed;
	c.rgb *= mix(1.0, 0.72, snuffed);
	COLOR = c;
}
