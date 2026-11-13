// Sin window light: glow when it's that Sin's turn (or its ability fires), dim otherwise.
shader_type canvas_item;

uniform float glow = 0.0;
uniform float dim = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float flick = 1.0 + glow * 0.06 * sin(TIME * 7.0);
	c.rgb *= (1.0 + glow * 0.45) * flick;
	c.rgb = mix(c.rgb, c.rgb * 0.4, dim);
	COLOR = c;
}
