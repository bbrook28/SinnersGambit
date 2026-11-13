// Recolour painted art: keep its light and shade, swap its hue for `tint` (the turn banner takes the Sin's colour).
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0);
uniform float amount = 0.85;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 t = tint.rgb * lum * 1.9;
	c.rgb = mix(c.rgb, t, amount);
	COLOR = c;
}
