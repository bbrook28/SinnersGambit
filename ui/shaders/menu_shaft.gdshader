// A shaft of coloured light from a menu window onto the table. Draw on a Polygon2D:
// u across the beam (0..1), v along it (0 at the window), passed in the vertex colour (r = u, g = v):
// Polygon2D has no UVs without a texture. Soft edges, fades with distance,
// and faint bands of brighter light drift through it, like dust catching the sun.
shader_type canvas_item;
render_mode blend_add;

uniform vec4 tint : source_color = vec4(1.0, 0.8, 0.5, 1.0);
uniform float strength = 0.22;
uniform float phase = 0.0;
uniform float motion = 1.0;

void fragment() {
	vec2 uv = COLOR.rg;
	float across = sin(uv.x * PI);                    // 0 at the edges, 1 in the middle
	float edge = pow(across, 1.6);
	float fade = pow(1.0 - uv.y, 1.4);
	float t = TIME * motion + phase;
	// Drifting streaks along the beam.
	float streak = 0.7 + 0.18 * sin(uv.x * 23.0 + t * 0.6) + 0.12 * sin(uv.x * 41.0 - t * 0.9 + uv.y * 3.0);
	// Slow swell, in step with the window's clouds.
	float swell = 0.8 + 0.2 * sin(t * 0.37) * sin(t * 0.23 + 1.3);
	float a = strength * edge * fade * streak * swell;
	COLOR = vec4(tint.rgb * a, 1.0);
}
