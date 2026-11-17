## Menus restyle mock (REPLY 28 item 8): every menu, settings and overlay screen in the table's lettering
## (1fcf581), restyled in place after the screen is built. Not wired; nothing in ui/ changes.
## - Flat page panels (Style.page) -> the painted page (page.jpg) if light, the painted plate if dark.
## - Every button (flat wax seals, the table's cream choice boxes, buy buttons) -> the painted plate,
##   its words in Pirata One, gold, no outline.
## - Full-screen flat colour (dims, backdrops) -> the painted table top, darkened.
## - Text: IM Fell English; headings (56 px and up) in Pirata One; dark ink on the page, bone on dark,
##   no outlines or shadows; numerals stay as each screen sets them.
## godot --path . --fixed-fps 60 --script res://tools/menu_restyle_mock.gd -- <fixture> <se|std> <out.png>
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")
const Style = preload("res://ui/style.gd")
const PAGE := preload("res://assets/art/runtime/table/page.jpg")
const TABLE := preload("res://assets/art/runtime/table/table.jpg")
const PLATE := preload("res://assets/art/runtime/table/plate.png")

const INK := Color("2a1810")
const BONE := Color("e8dcbc")
const GOLD := Color("e9c46a")

var vp := Vector2.ZERO
var restyled := {}


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var name: String = a[0]
	var size: String = a[1]
	var out: String = a[2]
	var px: Array = Fixture.SIZES[size].px
	await process_frame
	DisplayServer.window_set_size(Vector2i(px[0], px[1]))
	root.size = Vector2i(px[0], px[1])
	await process_frame
	await process_frame
	var main = await Fixture.apply(self, Fixture.read(name), size)
	vp = main.get_viewport().get_visible_rect().size
	# A selected toggle is drawn crimson: read it from the screen as drawn, before restyling.
	await RenderingServer.frame_post_draw
	var pre := root.get_texture().get_image()
	var k0: float = pre.get_width() / vp.x
	for b in main.find_children("*", "Button", true, false):
		if b.is_visible_in_tree():
			var cc: Vector2 = (b.global_position + b.size * b.get_global_transform().get_scale() * Vector2(0.5, 0.82)) * k0
			var pc := pre.get_pixel(clampi(int(cc.x), 0, pre.get_width() - 1), clampi(int(cc.y), 0, pre.get_height() - 1))
			b.set_meta("mock_selected", pc.s > 0.5 and pc.r > pc.g * 1.8 and pc.r > 0.35)
	for pass_i in 3:  # screens that build lazily get a second look
		_restyle(main)
		await process_frame
	# Text colour from what is really behind it: render, then ink on light ground, bone or gold on dark.
	await RenderingServer.frame_post_draw
	var bg := root.get_texture().get_image()
	var k: float = bg.get_width() / vp.x
	for c in main.find_children("*", "Control", true, false):
		if not c.is_visible_in_tree() or c.get_parent() is Button:
			continue
		if c is Label or c is RichTextLabel:
			var g := Rect2(c.global_position * k, c.size * c.get_global_transform().get_scale() * k)
			var light: bool = _median(bg, g) > 0.3
			if c is Label:
				_label_colour(c, light)
			else:
				c.add_theme_color_override("default_color", INK if light else BONE)
	await process_frame
	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	im.save_png(out)
	print("RESTYLE %s %s -> %s" % [name, size, out])
	main.queue_free()
	quit()


func _restyle(n: Node) -> void:
	for c in n.find_children("*", "Control", true, false):
		if restyled.has(c.get_instance_id()):
			continue
		restyled[c.get_instance_id()] = true
		if c is Button:
			_button(c)
		elif c is PanelContainer or c is Panel:
			_panel(c)
		elif c is ColorRect:
			_backdrop(c)
	for c in n.find_children("*", "Control", true, false):
		if c is Label and not (c.get_parent() is Button):
			_label(c)
		elif c is RichTextLabel:
			_rich(c)


func _page_box(sb: StyleBox) -> StyleBoxTexture:
	var t := StyleBoxTexture.new()
	t.texture = PAGE
	_margins(t, sb)
	t.modulate_color = Color(1, 1, 1)
	return t


func _plate_box(sb: StyleBox) -> StyleBoxTexture:
	var t := StyleBoxTexture.new()
	t.texture = PLATE
	t.set_texture_margin_all(22)
	_margins(t, sb)
	return t


func _margins(t: StyleBox, sb: StyleBox) -> void:
	if sb == null:
		return
	for s in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		t.set_content_margin(s, maxf(sb.get_content_margin(s), 18.0))


func _light(sb: StyleBox) -> bool:
	if sb is StyleBoxFlat:
		return (sb as StyleBoxFlat).bg_color.get_luminance() > 0.4
	return false


func _panel(c: Control) -> void:
	var name := "panel"
	var sb: StyleBox = c.get_theme_stylebox(name)
	if sb == null or sb is StyleBoxEmpty or (sb is StyleBoxFlat and (sb as StyleBoxFlat).bg_color.a < 0.2):
		return
	c.add_theme_stylebox_override(name, _page_box(sb) if _light(sb) else _plate_box(sb))


func _backdrop(c: ColorRect) -> void:
	if c.size.x < vp.x * 0.9 or c.size.y < vp.y * 0.5 or c.color.a < 0.3:
		return
	var tr := TextureRect.new()
	tr.texture = TABLE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_TILE
	tr.position = c.position
	tr.size = c.size
	tr.modulate = Color(0.55, 0.5, 0.48, c.color.a)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(tr)
	c.color = Color(0, 0, 0, 0)


func _button(b: Button) -> void:
	var sb: StyleBox = b.get_theme_stylebox("normal")
	if not (sb is StyleBoxFlat) or b.icon != null:  # painted seals and icon buttons stay as they are
		return
	var p := _plate_box(sb)
	var crim := p.duplicate()  # selected (drawn crimson today): the plate dyed crimson
	crim.modulate_color = Color(1.0, 0.42, 0.38)
	var base: StyleBox = crim if bool(b.get_meta("mock_selected", false)) else p
	for st in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(st, base)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if b.toggle_mode:
		b.add_theme_stylebox_override("pressed", crim)
		b.add_theme_stylebox_override("hover_pressed", crim)
	else:
		var pr := base.duplicate()
		pr.modulate_color = pr.modulate_color * Color(0.75, 0.7, 0.65)
		b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_font_override("font", Style.BLACKLETTER)
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, GOLD)
	b.add_theme_color_override("font_disabled_color", GOLD.darkened(0.45))
	b.add_theme_constant_override("outline_size", 0)
	for l in b.find_children("*", "Label", true, false):  # words drawn as child labels (the table's choice boxes)
		l.add_theme_color_override("font_color", GOLD if l.get_index() == 0 else BONE)
		l.add_theme_constant_override("outline_size", 0)
		l.add_theme_constant_override("shadow_outline_size", 0)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))


func _label(l: Label) -> void:
	var s: int = l.get_theme_font_size("font_size")
	var f: Font = l.get_theme_font("font")
	var keep: bool = f == Style.BLACKLETTER or f == Style.NUMERAL or (f is FontVariation and (f as FontVariation).base_font == Style.NUMERAL.base_font)
	if not keep:
		l.add_theme_font_override("font", Style.BLACKLETTER if s >= 56 else Style.SERIF)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("shadow_outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))


func _label_colour(l: Label, light: bool) -> void:
	var s: int = l.get_theme_font_size("font_size")
	var c: Color = l.get_theme_color("font_color")
	var col: Color = INK if light else (GOLD if s >= 56 else BONE)
	if light and c.s > 0.35 and c.get_luminance() < 0.2:  # a coloured word already dark on the page keeps its colour
		col = c
	if not light and c.s > 0.35 and c.get_luminance() > 0.3:  # a coloured word already light on the dark keeps it
		col = c
	l.add_theme_color_override("font_color", col)


func _median(im: Image, r: Rect2) -> float:
	var ls: Array = []
	for yy in range(int(maxf(r.position.y, 0)), mini(int(r.end.y), im.get_height()), 3):
		for xx in range(int(maxf(r.position.x, 0)), mini(int(r.end.x), im.get_width()), 3):
			ls.append(im.get_pixel(xx, yy).get_luminance())
	if ls.is_empty():
		return 0.0
	ls.sort()
	return ls[ls.size() / 2]


func _rich(r: RichTextLabel) -> void:
	r.add_theme_font_override("normal_font", Style.SERIF)
	r.add_theme_constant_override("outline_size", 0)
	r.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
