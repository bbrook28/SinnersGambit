// Sin window light. Glass is backlit: bright, saturated panes glow, dark leading stays dark.
// glow: that Sin's turn (or its ability fires). dim: inactive. cast: per-window colour cast (Greed's cold silver).
shader_type canvas_item;

uniform float glow = 0.0;
uniform float dim = 0.0;
uniform vec4 cast : source_color = vec4(1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.rgb *= cast.rgb;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(vec3(lum), c.rgb, 1.25);           // a little richer
	c.rgb = c.rgb * 1.2 + c.rgb * c.rgb * 0.9;      // light through glass: brights bloom, leading doesn't
	float flick = 1.0 + glow * 0.06 * sin(TIME * 7.0);
	c.rgb *= (1.0 + glow * 0.35) * flick;
	c.rgb = mix(c.rgb, c.rgb * 0.45, dim);
	COLOR = c;
}
