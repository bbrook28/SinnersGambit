// REPLY 32: the painted plate with its gold border recoloured to a Sin's colour; the darker wood stays.
shader_type canvas_item;
uniform vec4 tint : source_color;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float v = max(c.r, max(c.g, c.b));
	float gold = smoothstep(0.3, 0.6, v);  // the border's gold; the wood inside is darker (v about 0.2)
	vec3 t = tint.rgb * clamp(v / 0.8, 0.0, 1.3);
	COLOR = vec4(mix(c.rgb, t, gold), c.a);
}
