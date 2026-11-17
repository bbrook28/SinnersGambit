## Sin plates mock (REPLY 28 item 1): a Sin's line on its own window, not on the Master's plate. Not wired;
## the table is drawn from a fixture with no line (the Master has no plate while a Sin speaks), then the
## proposed plate goes on top:
## - the active Sin (large window): across the foot of its own window, at the window's width;
## - a rival (small window): hanging from that window's top edge, a notch pointing down at it.
## The painted plate (plate.png) with its gold border recoloured in that Sin's colour; the words in its
## blackletter at SPEAK_SIZE, SPEAK_SMALL when they wrap (as wired today).
## godot --path . --fixed-fps 60 --script res://tools/sin_plate_mock.gd -- <se|std> <a1|a2|r1|r2> <out.png>
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")
const Style = preload("res://ui/style.gd")
const B = preload("res://ui/table_blockout.gd")

const NOTCH := Vector2(40, 24)  # the rival plate's notch: width, depth
const EDGE := 16.0  # the screen gutter a rival plate keeps

# case: fixture, the turn's seat, the speaker's seat, the line
const CASES := {
	"a1": ["table_rival_4", 1, 1, "Pay up."],
	"a2": ["table_rival_4", 1, 1, "Your fortune looks underpriced, leader."],
	"r1": ["table_speech", 0, 2, "Burn it all."],
	"r2": ["table_speech", 0, 3, "You smell delicious. Like Circle 4."],
}

const RECOLOUR := """
shader_type canvas_item;
uniform vec4 tint : source_color;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float v = max(c.r, max(c.g, c.b));
	float gold = smoothstep(0.3, 0.6, v);  // the border's gold; the wood inside is darker (v about 0.2)
	vec3 t = tint.rgb * clamp(v / 0.8, 0.0, 1.3);
	COLOR = vec4(mix(c.rgb, t, gold), c.a);
}
"""


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var size: String = a[0]
	var cs: Array = CASES[a[1]]
	var out: String = a[2]
	var px: Array = Fixture.SIZES[size].px
	await process_frame
	DisplayServer.window_set_size(Vector2i(px[0], px[1]))
	root.size = Vector2i(px[0], px[1])
	await process_frame
	await process_frame
	var fx: Dictionary = Fixture.read(cs[0])
	fx["cur"] = cs[1]
	fx.erase("speak")
	var main = await Fixture.apply(self, fx, size)
	await process_frame
	var t = main._overlay
	var seat: int = cs[2]
	var who: String = str(fx.seats[seat].sin)
	var win: Rect2 = t.boxes.windows[seat]
	var vw: float = t.get_viewport_rect().size.x
	var col: Color = Style.SIN_COLORS[who]
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = RECOLOUR
	mat.set_shader_parameter("tint", col.lightened(0.15))
	var ml := Style.label(str(cs[3]), B.SPEAK_SIZE, B.on_plate(col.lightened(0.25)), true)
	ml.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var plate := NinePatchRect.new()
	plate.texture = B.PLATE_TEX
	for m in ["patch_margin_left", "patch_margin_right", "patch_margin_top", "patch_margin_bottom"]:
		plate.set(m, B.PLATE_EDGE)
	plate.material = mat
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(plate)
	t.add_child(ml)
	var pad: Vector2 = B.PLATE_PAD
	var rect := Rect2()
	if seat == int(fx.cur):  # active: across the foot of its own window, at its width
		var lw: float = win.size.x - 2.0 * pad.x
		var th := _fit(ml, lw)
		rect = Rect2(win.position.x, win.end.y - th - 2.0 * pad.y, win.size.x, th + 2.0 * pad.y)
	else:  # rival: hung from the window's top, centred on it as far as the screen allows, a notch down at it
		var natural: float = ml.get_theme_font("font").get_string_size(ml.text, HORIZONTAL_ALIGNMENT_LEFT, -1, B.SPEAK_SIZE).x
		var maxw: float = minf(vw - 2.0 * EDGE, 3.0 * win.size.x + 40.0)
		var w: float = clampf(natural + 2.0 * pad.x + 8.0, win.size.x, maxw)
		var th := _fit(ml, w - 2.0 * pad.x)
		var h: float = th + 2.0 * pad.y
		var x: float = clampf(win.get_center().x - w / 2.0, EDGE, vw - EDGE - w)
		rect = Rect2(x, win.position.y - NOTCH.y - h + 6.0, w, h)
		var tip := Vector2(win.get_center().x, win.position.y + 2.0)
		var base_y: float = rect.end.y - 8.0
		var notch := Polygon2D.new()
		notch.polygon = PackedVector2Array([Vector2(tip.x - NOTCH.x / 2.0, base_y), Vector2(tip.x + NOTCH.x / 2.0, base_y), tip])
		notch.color = Color(0.17, 0.12, 0.09)
		t.add_child(notch)
		t.move_child(notch, plate.get_index())
		var edge := Line2D.new()
		edge.points = PackedVector2Array([Vector2(tip.x - NOTCH.x / 2.0, rect.end.y - 3.0), tip, Vector2(tip.x + NOTCH.x / 2.0, rect.end.y - 3.0)])
		edge.width = 4.0
		edge.default_color = col.lightened(0.15)
		edge.joint_mode = Line2D.LINE_JOINT_ROUND
		t.add_child(edge)
		t.move_child(edge, plate.get_index())
	plate.position = rect.position
	plate.size = rect.size
	ml.position = rect.position + pad
	ml.size = Vector2(rect.size.x - 2.0 * pad.x, rect.size.y - 2.0 * pad.y)
	await process_frame
	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	im.save_png(out)
	print("PLATE %s %s %s plate %d,%d %dx%d window %d,%d %dx%d lines %d size %d" % [size, a[1], who, rect.position.x, rect.position.y, rect.size.x, rect.size.y, win.position.x, win.position.y, win.size.x, win.size.y, ml.get_line_count(), ml.get_theme_font_size("font_size")])
	main.queue_free()
	quit()


## The words at lw: SPEAK_SIZE, or SPEAK_SMALL if they wrap (as wired). Their height.
func _fit(ml: Label, lw: float) -> float:
	ml.custom_minimum_size = Vector2(lw, 0)
	ml.size = Vector2(lw, 0)
	if ml.get_line_count() > 1:
		ml.add_theme_font_size_override("font_size", B.SPEAK_SMALL)
	return ml.get_minimum_size().y
