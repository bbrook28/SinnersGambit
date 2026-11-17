## Sin plates mock (REPLY 28 item 1, re-sheeted for REPLY 31 item 3): a Sin's line on its own window. Not wired;
## the table is drawn from a fixture with no line (the Master has no plate while a Sin speaks), then the
## proposed plate goes on top. One rule: every Sin's plate sits at the FOOT of its own window.
## - The active Sin (large window): across the foot of its window, inside it; it may grow wider than the window,
##   centred on it and clamped to the screen.
## - A rival (small window): hung just under its window's foot, a notch pointing UP at it; that window brightens.
## - Wording: at most MAX_LINES (2 at std, 3 at SE): the plate widens first, then the size steps down from
##   SPEAK_SIZE to MIN_TEXT; then the lines are balanced (the narrowest width that keeps that many lines), so no
##   last line is left with one word.
## - No plate may touch the Master's skull or jaw (boxes "mask"); the printout says if one does.
## The painted plate (plate.png) with its gold border recoloured in that Sin's colour.
## godot --path . --fixed-fps 60 --script res://tools/sin_plate_mock.gd -- <se|std> <fixture> <cur> <seat> <line> <out.png>
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")
const Style = preload("res://ui/style.gd")
const B = preload("res://ui/table_blockout.gd")

const NOTCH := Vector2(40, 22)  # the rival plate's notch: width, height
const EDGE := 16.0  # the screen gutter a plate keeps
const MAX_LINES := {"std": 2, "se": 3, "max": 2}

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
	var fx: Dictionary = Fixture.read(a[1])
	fx["cur"] = int(a[2])
	var seat: int = int(a[3])
	var line: String = a[4]
	var out: String = a[5]
	fx.erase("speak")
	fx.erase("master")
	var px: Array = Fixture.SIZES[size].px
	await process_frame
	DisplayServer.window_set_size(Vector2i(px[0], px[1]))
	root.size = Vector2i(px[0], px[1])
	await process_frame
	await process_frame
	var main = await Fixture.apply(self, fx, size)
	await process_frame
	var t = main._overlay
	var who: String = str(fx.seats[seat].sin)
	var win: Rect2 = t.boxes.windows[seat]
	var vw: float = t.get_viewport_rect().size.x
	var col: Color = Style.SIN_COLORS[who]
	var active: bool = seat == int(fx.cur)
	if not active:  # the speaking rival's window brightens
		for c in t.get_children():
			if c is TextureRect and Rect2(c.position, c.size).is_equal_approx(win):
				c.modulate = Color.WHITE
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = RECOLOUR
	mat.set_shader_parameter("tint", col.lightened(0.15))
	var ml := Style.label(line, B.SPEAK_SIZE, B.on_plate(col.lightened(0.25)), true)
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
	var maxw: float = vw - 2.0 * EDGE
	var minw: float = win.size.x
	var fit: Vector3 = _fit(ml, minw - 2.0 * pad.x, maxw - 2.0 * pad.x, int(MAX_LINES[size]))
	var w: float = maxf(minw, fit.x + 2.0 * pad.x)
	var h: float = fit.y + 2.0 * pad.y
	var x: float = clampf(win.get_center().x - w / 2.0, EDGE, vw - EDGE - w)
	var rect := Rect2()
	if active:
		rect = Rect2(x, win.end.y - h, w, h)
	else:
		rect = Rect2(x, win.end.y + NOTCH.y - 4.0, w, h)
		var tip := Vector2(win.get_center().x, win.end.y - 2.0)
		var base_y: float = rect.position.y + 6.0
		var notch := Polygon2D.new()
		notch.polygon = PackedVector2Array([Vector2(tip.x - NOTCH.x / 2.0, base_y), Vector2(tip.x + NOTCH.x / 2.0, base_y), tip])
		notch.color = Color(0.17, 0.12, 0.09)
		t.add_child(notch)
		var edge := Line2D.new()
		edge.points = PackedVector2Array([Vector2(tip.x - NOTCH.x / 2.0, rect.position.y + 3.0), tip, Vector2(tip.x + NOTCH.x / 2.0, rect.position.y + 3.0)])
		edge.width = 4.0
		edge.default_color = col.lightened(0.15)
		edge.joint_mode = Line2D.LINE_JOINT_ROUND
		t.add_child(edge)
	plate.position = rect.position
	plate.size = rect.size
	ml.custom_minimum_size = Vector2(fit.z, 0)
	ml.size = Vector2(fit.z, fit.y)
	ml.position = Vector2(rect.get_center().x - fit.z / 2.0, rect.position.y + pad.y)
	var mask: Rect2 = t.boxes.get("mask", Rect2())
	var touch: bool = mask.size.x > 0.0 and mask.intersects(rect)
	await process_frame
	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	im.save_png(out)
	var lines := []
	for i in ml.get_line_count():
		lines.append(_line_text(ml, i))
	print("PLATE %s %s %s seat %d plate %d,%d %dx%d window %d,%d %dx%d lines %d size %d skull %s | %s" % [size, "active" if active else "rival", who, seat, rect.position.x, rect.position.y, rect.size.x, rect.size.y, win.position.x, win.position.y, win.size.x, win.size.y, ml.get_line_count(), ml.get_theme_font_size("font_size"), "TOUCHES" if touch else "clear", " / ".join(lines)])
	main.queue_free()
	quit()


## The words within max_lines: the most lines (up to max_lines) for which every line keeps two words or more,
## each balanced (the narrowest width that keeps that many lines, never under the longest word) and within hi;
## else fewer lines; else the next size down (SPEAK_SIZE, SPEAK_SMALL, MIN_TEXT).
## Returns (the plate's text width, at least lo; text height; the words' width).
func _fit(ml: Label, lo: float, hi: float, max_lines: int) -> Vector3:
	var words: PackedStringArray = ml.text.split(" ", false)
	for s in [B.SPEAK_SIZE, B.SPEAK_SMALL, B.MIN_TEXT]:
		ml.add_theme_font_size_override("font_size", s)
		var f: Font = ml.get_theme_font("font")
		var longest := 0.0
		for wd in words:
			longest = maxf(longest, f.get_string_size(wd, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x + 4.0)
		for n in range(mini(max_lines, words.size()), 0, -1):
			var w := _narrowest(ml, n, longest, hi)
			if w < 0.0:
				continue
			_lines(ml, w)
			var ok := true
			if n > 1:
				for i in ml.get_line_count():
					if _line_text(ml, i).split(" ", false).size() < 2:
						ok = false
			if ok:
				return Vector3(maxf(w, lo), ml.get_minimum_size().y, w)
	var w := hi
	_lines(ml, w)
	return Vector3(w, ml.get_minimum_size().y, w)


## The narrowest width in [lo, hi] at which the words take n lines or fewer; -1 if hi is not enough.
func _narrowest(ml: Label, n: int, lo: float, hi: float) -> float:
	if _lines(ml, hi) > n:
		return -1.0
	var a := lo
	var b := hi
	if _lines(ml, a) <= n:
		return a
	while b - a > 2.0:
		var m := (a + b) / 2.0
		if _lines(ml, m) <= n:
			b = m
		else:
			a = m
	return b


func _lines(ml: Label, w: float) -> int:
	ml.custom_minimum_size = Vector2(w, 0)
	ml.size = Vector2(w, 0)
	return ml.get_line_count()


func _line_text(ml: Label, i: int) -> String:
	var f: Font = ml.get_theme_font("font")
	var s: int = ml.get_theme_font_size("font_size")
	var ts := TextServerManager.get_primary_interface()
	var para := TextParagraph.new()
	para.add_string(ml.text, f, s)
	para.width = ml.size.x
	para.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	if i >= para.get_line_count():
		return ""
	var r: Vector2i = para.get_line_range(i)
	return ml.text.substr(r.x, r.y - r.x).strip_edges()
