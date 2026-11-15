// One lead line round a living portrait's whole figure (Ben, Part A): the figure layers draw into a
// CanvasGroup, and this draws near-black round the group's combined alpha, so the line is only ever
// on the outside edge, never at a seam between layers, and follows them as they move.
// width: px in the portrait's viewport (tools/bake_layers.gd writes it as "outline").
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float width = 10.0;
uniform vec4 lead : source_color = vec4(0.031, 0.024, 0.020, 1.0);

const int DIRS = 24;

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	// Nearest figure pixel within `width`: sample rings at the full width and two inner radii.
	float near = 0.0;
	vec2 px = SCREEN_PIXEL_SIZE;
	for (int i = 0; i < DIRS; i++) {
		float ang = 6.2831853 * float(i) / float(DIRS);
		vec2 d = vec2(cos(ang), sin(ang));
		near = max(near, textureLod(screen_texture, SCREEN_UV + d * px * width, 0.0).a);
		near = max(near, textureLod(screen_texture, SCREEN_UV + d * px * width * 0.66, 0.0).a);
		near = max(near, textureLod(screen_texture, SCREEN_UV + d * px * width * 0.33, 0.0).a);
	}
	float line = smoothstep(0.35, 0.65, near);
	vec3 rgb = mix(lead.rgb, c.rgb, c.a);
	COLOR = vec4(rgb, max(c.a, line * lead.a));
}
