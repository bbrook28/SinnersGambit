## Art mock (REPLY 24 item 6): a fixture with art pieces swapped in at the locked boxes. Not used by the game.
## godot --path . --fixed-fps 60 --script res://tools/art_mock.gd -- <fixture> <size> <master 0-3> <out.png> [art dir] [frame]
## [frame]: an idle frame in place of the still, at the still's size. master 0 keeps the blockout figure. Pieces in the art dir: master_N.png. (Seals and candles are in the game, REPLY 26.)
## REPLY 26: the Master LARGE (his hood spans the hood box); the line plate moves under his jaw, over the rival windows.
## Prints the hood's top against the safe line and the jaw against the plate (viewport px).
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")
const Blockout = preload("res://ui/table_blockout.gd")

const JAW := {1: 0.31, 2: 0.28, 3: 0.28}  # the jaw's line, a fraction of each piece's height from its top (measured by eye)

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
		# REPLY 26: LARGE. His hood at mid-skull spans the hood box; the skull's top at the box's top.
		var s: float = head.size.x / _span(img, JAW[mv] * 0.6).y
		var sz := Vector2(img.get_width(), img.get_height()) * s
		var jaw_y: float = head.position.y + (JAW[mv] * img.get_height() - _top_row(img)) * s
		var mr := TextureRect.new()
		mr.texture = ImageTexture.create_from_image(img)
		if a.size() > 5:  # REPLY 26 item 4: frame N of master_N_idle.png (8 square frames in a row, the still's framing)
			var sheet := _img("master_%d_idle.png" % mv)
			var fw: int = sheet.get_height()
			mr.texture = ImageTexture.create_from_image(sheet.get_region(Rect2i(int(a[5]) * fw, 0, fw, fw)))
		mr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mr.size = sz
		mr.position = Vector2(head.get_center().x - sz.x / 2.0, head.position.y - _top_row(img) * s)
		mr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in range(r0, w0):
			kids[i].visible = false
		t.add_child(mr)
		t.move_child(mr, r0)
		# The line plate (REPLY 26 Q1: it may stand over the rival windows' top edge): its top 8 px under his jaw,
		# drawn over the windows.
		var rt := 1e9
		for i in t.boxes.windows.size():
			if i != t.cur:
				rt = minf(rt, t.boxes.windows[i].position.y)
		if t.boxes.has("line"):
			var ln: Rect2 = t.boxes.line
			var dy: float = maxf(0.0, jaw_y + 8.0 - ln.position.y)
			var moved := []
			for n in t.get_children():
				if n is CanvasItem and n.visible and ln.grow(4.0).encloses(_bounds(n)):
					moved.append(n)
			for n in moved:
				n.position.y += dy
				t.move_child(n, t.get_child_count() - 1)
			print("ART PLATE %s %s m%d jaw %.0f plate %.0f..%.0f rival tops %.0f (over the windows by %.0f px)" % [name, size, mv, jaw_y, ln.position.y + dy, ln.end.y + dy, rt, maxf(0.0, ln.end.y + dy - rt)])
		print("ART SIZE %s %s m%d piece %.0fx%.0f scale %.3f hood box %.0f" % [name, size, mv, sz.x, sz.y, s, head.size.x])
		var safe_top: float = Fixture.safe(size).x
		print("ART HOOD %s %s m%d top %.0f safe %.0f head %s piece %s" % [name, size, mv, mr.position.y, safe_top, head, Rect2(mr.position, sz)])

	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	im.save_png(out)
	print("ART %s %s m%d -> %s" % [name, size, mv, out])
	main.queue_free()
	quit()


func _img(f: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(dir.path_join(f)))


## The first row with any opaque pixel.
func _top_row(img: Image) -> int:
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				return y
	return 0


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
