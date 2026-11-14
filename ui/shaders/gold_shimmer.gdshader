// Gold leaf that catches the candle: a narrow light band crosses the highlights now and then,
// plus a faint flicker. `phase` staggers numerals. Tunables: ui/tuning.gd.
shader_type canvas_item;

uniform float phase = 0.0;
uniform float period = 3.2;
uniform float width = 0.08;
uniform float strength = 0.6;

void fragment() {
	vec4 c = COLOR;  // already texture x modulate in Godot 4
	float t = fract(TIME / period + phase);
	float d = (UV.x * 0.7 - UV.y * 0.7 + 0.35) - (t * 2.4 - 0.7);
	float band = exp(-(d * d) / (width * width));
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float hi = smoothstep(0.35, 0.85, lum);      // only the polished gold, not the dark outline
	float flicker = 0.04 * sin(TIME * 7.0 + phase * 40.0) * hi;
	c.rgb += (band * strength * hi + flicker) * vec3(1.0, 0.92, 0.65);
	COLOR = c;
}
