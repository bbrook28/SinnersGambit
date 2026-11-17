## Art mock (REPLY 24 item 6): a fixture with art pieces swapped in at the locked boxes. Not used by the game.
## godot --path . --fixed-fps 60 --script res://tools/art_mock.gd -- <fixture> <size> <master 0-3> <out.png> [art dir]
## master 0 keeps the blockout figure. Pieces: master_N.png, candle_lit/out.png, seal_bank/throw.png, page.jpg, table.jpg.
## Prints the hood's top against the safe line (viewport px).
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")
const Blockout = preload("res://ui/table_blockout.gd")

var dir := "res://build/art24"


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
	var vp: Vector2 = t.get_viewport_rect().size
	var kids: Array = t.get_children()
	var pg: Rect2 = t.page_rect

	# Table surface under the page, from the page's top down; the page itself in parchment.
	for i in kids.size():
		var c = kids[i]
		if c is ColorRect and c.color == Blockout.PARCH and c.get_rect().is_equal_approx(pg):
			var tb := _tex("table.jpg", Rect2(0, pg.position.y, vp.x, vp.y - pg.position.y), true)
			t.add_child(tb)
			t.move_child(tb, i)
			var pt := _tex("page.jpg", pg, false)
			t.add_child(pt)
			t.move_child(pt, i + 1)
			c.visible = false
			break

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
		var span := _span(img, 0.25)
		var s: float = head.size.x / span.y
		var sz := Vector2(img.get_width(), img.get_height()) * s
		var mr := TextureRect.new()
		mr.texture = ImageTexture.create_from_image(img)
		mr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mr.size = sz
		mr.position = Vector2(head.get_center().x - (span.x + span.y / 2.0) * s, head.position.y)
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

	# Bank and Throw: the wax seals as their faces, the words left on top.
	for n in _all(t):
		if n is Button and n.text in ["Bank", "Throw"]:
			var sb := StyleBoxTexture.new()
			sb.texture = ImageTexture.create_from_image(_img("seal_bank.png" if n.text == "Bank" else "seal_throw.png"))
			for st in ["normal", "hover", "pressed", "disabled", "focus"]:
				n.add_theme_stylebox_override(st, sb)

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
