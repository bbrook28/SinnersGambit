// Recolour painted art: keep its light and shade, swap its hue for `tint` (the turn banner takes
// the Sin's colour; the Bank seal turns bronze). COLOR is already texture x modulate (Godot 4):
// never multiply by texture(TEXTURE, UV) again. The new colour is tint x gain x luminance^power;
// gain and power are set per use (Art.tint_material) to keep the look each was tuned with.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0);
uniform float amount = 0.85;
uniform float gain = 2.6;
uniform float power = 2.3;

void fragment() {
	vec4 c = COLOR;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 t = tint.rgb * pow(max(lum, 0.0), power) * gain;
	c.rgb = mix(c.rgb, t, amount);
	COLOR = c;
}
