// A slow specular glint sweeping diagonally across sealing wax. `phase` offsets each seal so the
// glints travel along a row. Only the bright, glossy parts catch it. Tunables: ui/tuning.gd.
shader_type canvas_item;

uniform float phase = 0.0;
uniform float period = 5.5;    // seconds between sweeps
uniform float width = 0.10;    // band half-width in UV
uniform float strength = 0.45;

void fragment() {
	vec4 c = COLOR;  // already texture x modulate in Godot 4
	float t = fract(TIME / period + phase);
	float pos = t * 2.6 - 0.8;                 // starts off one side, ends off the other
	float d = (UV.x * 0.8 + UV.y * 0.6) - pos;
	float band = exp(-(d * d) / (width * width));
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb += band * strength * (0.25 + 1.5 * lum) * vec3(1.0, 0.86, 0.72);
	COLOR = c;
}
