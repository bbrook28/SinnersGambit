// Menu stained-glass window, lit from behind: the panes glow (leading stays dark), the light
// swells and fades like clouds passing outside, and now and then a pale sheen sweeps across the glass.
shader_type canvas_item;
render_mode blend_mix;

uniform float phase = 0.0;          // per-window offset (s)
uniform float period = 9.0;         // seconds between sweeps
uniform float sweep = 0.55;         // sheen strength
uniform float backlight = 0.35;     // extra light through the bright panes
uniform float motion = 1.0;         // 0 = Reduce Motion: no sweep, steady light

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	float glass = smoothstep(0.12, 0.45, lum);       // panes, not leading
	float t = TIME * motion + phase;
	// Clouds: two slow waves, never fully dark.
	float cloud = 0.75 + 0.25 * sin(t * 0.37) * sin(t * 0.23 + 1.3);
	vec3 col = tex.rgb * (1.0 + backlight * glass * cloud);
	// Brighter toward the middle of the window, as if the sun sits behind it.
	vec2 c = UV - vec2(0.5, 0.4);
	col *= 0.9 + 0.25 * (1.0 - clamp(dot(c, c) * 3.0, 0.0, 1.0));
	// Sheen: a soft diagonal band crossing the glass once per period.
	float k = fract(t / period);
	float pos = mix(-0.4, 1.4, k);
	float d = (UV.x * 0.6 + UV.y * 0.4) - pos;
	float band = exp(-d * d / 0.004) * motion;
	col += vec3(1.0, 0.95, 0.85) * band * sweep * glass;
	COLOR = vec4(col, tex.a);
}
