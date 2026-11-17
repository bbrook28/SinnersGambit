## Art mock (REPLY 24 item 6): a fixture with art pieces swapped in at the locked boxes. Not used by the game.
## godot --path . --fixed-fps 60 --script res://tools/art_mock.gd -- <fixture> <size> <master 0-3> <out.png> [art dir] [seal 0-2]
## master 0 keeps the blockout figure; seal 0 keeps the blockout seals. Pieces in the art dir: master_N.png, candle_lit/out.png,
## bank_N.png and throw_N.png (no word on the wax: the word sits under the seal, inside its box).
## REPLY 25: the Master is scaled so his jaw clears a two-line plate standing on the rival windows' tops.
## Prints the hood's top against the safe line and the jaw against the plate (viewport px).
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")
const Blockout = preload("res://ui/table_blockout.gd")

const Style = preload("res://ui/style.gd")
const JAW := {1: 0.31, 2: 0.28, 3: 0.28}  # the jaw's line, a fraction of each piece's height from its top (measured by eye)
const PLATE2 := 168.0  # a two-line plate at SPEAK_SIZE 60 (2 x 60 x 1.3 + 12)
const WORD_H := 58.0   # the word's strip under the wax, inside the seal's box

var dir := "res://build/art25"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var name: String = a[0]
	var size: String = a[1]
	var mv: int = int(a[2])
	var out: String = a[3]
	if a.size() > 4:
		dir = a[4]
	var px: Array = Fixture.SIZES[size].px
	await process_frame
	DisplayServer.window_set_size(Vector2i(px[0], px[1]))
	root.size = Vector2i(px[0], px[1])
	await process_frame
	await process_frame
	var fx: Dictionary = Fixture.read(name)
	var main = await Fixture.apply(self, fx, size)
	await process_frame
	var t = main._overlay
	var kids: Array = t.get_children()
	var sv: int = int(a[5]) if a.size() > 5 else 0

	# The Master: the blockout figure (robe polygon up to the first window) hidden, the piece in its place.
	if mv > 0:
		kids = t.get_children()
		var r0 := -1
		var w0 := -1
		for i in kids.size():
			if r0 < 0 and kids[i] is Polygon2D and kids[i].color == Blockout.ROBE:
				r0 = i
			elif r0 >= 0 and kids[i] is TextureRect:
				w0 = i
				break
		var head: Rect2 = t.boxes.head
		var img := _img("master_%d.png" % mv)
		var rt := 1e9  # the rival windows' tops
		for i in t.boxes.windows.size():
			if i != t.cur:
				rt = minf(rt, t.boxes.windows[i].position.y)
		if rt > 1e8:
			rt = head.end.y
		var plate_top: float = rt - PLATE2
		if t.boxes.has("line"):
			plate_top = minf(plate_top, t.boxes.line.position.y)
		var jaw_y: float = plate_top - 8.0
		var s: float = (jaw_y - head.position.y) / (JAW[mv] * img.get_height())
		var sz := Vector2(img.get_width(), img.get_height()) * s
		var mr := TextureRect.new()
		mr.texture = ImageTexture.create_from_image(img)
		mr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mr.size = sz
		mr.position = Vector2(head.get_center().x - sz.x / 2.0, head.position.y)
		print("ART JAW %s %s m%d jaw %.0f plate %.0f rival tops %.0f skull-row width %.0f hood box %.0f" % [name, a[1], mv, jaw_y, plate_top, rt, _span(img, JAW[mv] * 0.6).y * s, head.size.x])
		mr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in range(r0, w0):
			kids[i].visible = false
		t.add_child(mr)
		t.move_child(mr, r0)
		var safe_top: float = Fixture.safe(size).x
		print("ART HOOD %s %s m%d top %.0f safe %.0f head %s piece %s" % [name, size, mv, mr.position.y, safe_top, head, Rect2(mr.position, sz)])

	# Candles: lit or snuffed as the blockout had them (a crimson cap = snuffed); the blockout's wax, wick and flame hidden.
	for cr in t.candle_rects:
		var zone := Rect2(cr.position - Vector2(30, 140), cr.size + Vector2(60, 140))
		var snuffed := false
		var par: Node = null
		for n in _all(t):
			if not (n is CanvasItem) or not n.visible:
				continue
			if n is ColorRect and n.color == Blockout.CRIMSON and absf(n.size.y - 26.0) < 0.5 and zone.has_point(n.position):
				snuffed = true
			if n is ColorRect and n.color == Blockout.BONE and n.get_rect().is_equal_approx(cr):
				par = n.get_parent()
			if (n is ColorRect or n is Line2D or n is Polygon2D) and zone.encloses(_bounds(n)):
				n.visible = false
		var ci := _img("candle_out.png" if snuffed else "candle_lit.png")
		var top := _body_top(ci)
		var cs: float = cr.size.y / (ci.get_height() - top)
		var cw: float = ci.get_width() * cs
		var ct := TextureRect.new()
		ct.texture = ImageTexture.create_from_image(ci)
		ct.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ct.size = Vector2(cw, ci.get_height() * cs)
		ct.position = Vector2(cr.get_center().x - cw / 2.0, cr.end.y - ct.size.y)
		ct.mouse_filter = Control.MOUSE_FILTER_IGNORE
		(par if par else t).add_child(ct)

	# Bank and Throw: the wax over the top of the box, no word on it; the word under it, inside the box.
	if sv > 0:
		for n in _all(t):
			if n is Button and n.text in ["Bank", "Throw"]:
				var word: String = n.text
				var none := StyleBoxEmpty.new()
				for st in ["normal", "hover", "pressed", "disabled", "focus"]:
					n.add_theme_stylebox_override(st, none)
				n.text = ""
				var d: float = n.size.x - WORD_H
				var wax := TextureRect.new()
				wax.texture = ImageTexture.create_from_image(_img("%s_%d.png" % [word.to_lower(), sv]))
				wax.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				wax.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				wax.position = Vector2(WORD_H / 2.0, 0)
				wax.size = Vector2(d, d)
				wax.mouse_filter = Control.MOUSE_FILTER_IGNORE
				n.add_child(wax)
				var l := Label.new()
				l.text = word
				l.add_theme_font_override("font", Style.BLACKLETTER)
				l.add_theme_font_size_override("font_size", 48)
				l.add_theme_color_override("font_color", Blockout.GOLD if word == "Bank" else Blockout.CRIMSON.lightened(0.35))
				l.add_theme_color_override("font_outline_color", Blockout.BLACK)
				l.add_theme_constant_override("outline_size", 10)
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				l.position = Vector2(-20, d - 6)
				l.size = Vector2(n.size.x + 40, WORD_H + 6)
				n.add_child(l)

	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	im.save_png(out)
	print("ART %s %s m%d -> %s" % [name, size, mv, out])
	main.queue_free()
	quit()


func _img(f: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(dir.path_join(f)))


func _tex(f: String, r: Rect2, tile: bool) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(_img(f))
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_TILE if tile else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.position = r.position
	tr.size = r.size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## The opaque run across one row (fraction of the height): x = its left, y = its width.
func _span(img: Image, fr: float) -> Vector2:
	var y := int(img.get_height() * fr)
	var x0 := -1
	var x1 := -1
	for x in img.get_width():
		if img.get_pixel(x, y).a > 0.5:
			if x0 < 0:
				x0 = x
			x1 = x
	return Vector2(x0, x1 - x0)


## The first row where a candle's wax runs at least 70% of the image wide (above it: flame or smoke).
func _body_top(img: Image) -> int:
	for y in img.get_height():
		var sp := _span_row(img, y)
		if sp >= img.get_width() * 0.7:
			return y
	return 0


func _span_row(img: Image, y: int) -> float:
	var x0 := -1
	var x1 := -1
	for x in img.get_width():
		if img.get_pixel(x, y).a > 0.5:
			if x0 < 0:
				x0 = x
			x1 = x
	return x1 - x0


func _all(n: Node) -> Array:
	var r: Array = []
	for c in n.get_children():
		r.append(c)
		r.append_array(_all(c))
	return r


func _bounds(n: CanvasItem) -> Rect2:
	if n is Control:
		return n.get_global_rect()
	var pts: PackedVector2Array = n.points if n is Line2D else n.polygon
	if pts.is_empty():
		return Rect2(-1e6, -1e6, 1, 1)
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r.grow(1.0)
