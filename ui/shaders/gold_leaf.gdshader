// Gold leaf on numbers: bright at the top, burnished band, bronze at the foot, a slow sheen sweep.
// Multiplies the font colour, so the dark outline stays dark. `box` = the label's size in px.
shader_type canvas_item;

uniform vec2 box = vec2(400.0, 160.0);
uniform float sheen = 1.0;

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float y = clamp(lp.y / box.y, 0.0, 1.0);
	float f = mix(1.3, 0.6, smoothstep(0.2, 0.85, y)) + 0.3 * exp(-pow((y - 0.42) * 8.0, 2.0));
	float run = box.x + box.y * 3.0;
	float p = mod(TIME * 140.0, run * 2.5) - box.y;
	float s = lp.x + lp.y * 0.6;
	f += sheen * 0.55 * exp(-pow((s - p) / (box.y * 0.18), 2.0));
	c.rgb *= f;
	COLOR = c;
}
