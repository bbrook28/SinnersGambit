## Type sheet (REPLY 26 item 3): every kind of table text in the proposed lettering, on the painted page and on
## painted plates, with each sample's contrast measured against what is behind it. Not used by the game.
## Proposal: one blackletter (Pirata One) and one plain face (IM Fell English, numerals too; Cinzel dropped);
## dark ink on the page, no ink shadows; gold and light colours only on dark surfaces (a painted plate).
## godot --path . --fixed-fps 60 --script res://tools/type_sheet.gd -- <se|std> <out.png> [plate.png]
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")
const Style = preload("res://ui/style.gd")
const B = preload("res://ui/table_blockout.gd")
const PAGE := preload("res://assets/art/runtime/table/page.jpg")
const TABLE := preload("res://assets/art/runtime/table/table.jpg")

const INK := Color("2a1810")
const BONE := Color("e8dcbc")
const GOLD := Color("e9c46a")
const W := 1080.0
const PLATE_L := 0.03  # the plate's centre, lightest 5% (measured 0.026)

var sheet: Control
var samples: Array = []  # [label, kind, caption label]
var plate_tex: Texture2D
var k := 1.0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var size: String = a[0]
	var out: String = a[1]
	var plate_path: String = a[2] if a.size() > 2 else "res://build/art26/plate_c.png"
	plate_tex = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(plate_path)))
	var px: Array = Fixture.SIZES[size].px
	await process_frame
	DisplayServer.window_set_size(Vector2i(px[0], px[1]))
	root.size = Vector2i(px[0], px[1])
	k = px[0] / W
	var h: float = px[1] / k
	sheet = Control.new()
	# the project stretch (canvas_items) maps 1080 layout px to the device width; k converts for measuring
	sheet.size = Vector2(W, h)
	root.add_child(sheet)
	var page_h := 1060.0
	_tex(TABLE, Rect2(0, 0, W, h), true)
	_tex(PAGE, Rect2(24, 20, W - 48, page_h), false)

	# On the page: dark ink, no outline, no shadow.
	var y := 40.0
	_head("ON THE PAGE · dark ink · no shadows", Vector2(48, y), INK)
	y += 46.0
	_sample("230", Style.SERIF, 160, INK, Vector2(60, y), "my stake · plain 160")
	_sample("-50", Style.SERIF, 64, _to_ratio(B.CRIMSON, true), Vector2(340, y + 10), "Bank loss · plain 64")
	_sample("+130", Style.SERIF, 80, INK, Vector2(680, y + 30), "gain · plain 80")
	y += 210.0
	_sample("520", Style.SERIF, 44, INK, Vector2(60, y), "total · plain 44")
	_sample("1000", Style.SERIF, 46, INK, Vector2(400, y), "goal · plain 46")
	_sample("550", Style.SERIF, 46, _to_ratio(B.CRIMSON, true), Vector2(700, y), "post · plain 46")
	y += 110.0
	_head("a rival's turn, each Sin's colour darkened to 4.5:1 on the page · plain 44", Vector2(48, y), INK)
	y += 40.0
	var col := 0
	for s in Style.SIN_COLORS:
		var c: Color = _to_ratio(Style.SIN_COLORS[s], true)
		_sample("%s's turn" % s, Style.SERIF, 44, c, Vector2(60 + (col % 2) * 480, y + int(col / 2) * 92), "")
		col += 1
	y += 4 * 92.0 + 10.0
	# Seals: painted wax, the word under it.
	for i in 2:
		var word: String = ["Bank", "Throw"][i]
		var x: float = 140.0 + i * 500.0
		var d: float = B.SEAL - B.SEAL_WORD_H
		_tex(B.SEAL_TEX[word], Rect2(x + B.SEAL_WORD_H / 2.0, y, d, d), false)
		_sample(word, Style.BLACKLETTER, 48, INK if word == "Bank" else _to_ratio(B.CRIMSON, true), Vector2(x + B.SEAL / 2.0 - 60, y + d - 6), "seal · blackletter 48", true)

	# On dark surfaces: painted plates; gold and light colours here only.
	y = page_h + 50.0
	_head("ON DARK · painted plates · gold and light colours only here", Vector2(48, y), BONE)
	y += 48.0
	_plate(Rect2(60, y, 960, 140))
	_sample("Candles are patient. I am less.", Style.SERIF, 44, BONE, Vector2(110, y + 44), "the Master's line · plain 44 · bone", false, true)
	y += 160.0
	_plate(Rect2(60, y, 960, 140))
	_sample("Burn it all.", Style.BLACKLETTER, 60, _to_ratio(Style.SIN_COLORS["Wrath"].lightened(0.25), false, PLATE_L), Vector2(150, y + 36), "Sin's line · blackletter 60 · lightened to 4.5:1", false, true)
	y += 160.0
	_plate(Rect2(60, y, 960, 230))
	col = 0
	for s in Style.SIN_COLORS:
		_sample(s, Style.BLACKLETTER, 48, _to_ratio(Style.SIN_COLORS[s].lightened(0.25), false, PLATE_L), Vector2(110 + (col % 4) * 225, y + 40 + int(col / 4) * 84), "", false, true)
		col += 1
	y += 250.0
	_plate(Rect2(60, y, 960, 120))
	_sample("Buy dice?", Style.SERIF, 44, GOLD, Vector2(110, y + 34), "question · plain 44 · gold", false, true)
	_sample("Standings", Style.BLACKLETTER, 60, GOLD, Vector2(560, y + 26), "heading · blackletter 60", false, true)

	# Measure: text hidden, what is behind each sample.
	for smp in samples:
		smp[0].visible = false
	await RenderingServer.frame_post_draw
	var bg := root.get_texture().get_image()
	var lines: PackedStringArray = []
	for smp in samples:
		var l: Label = smp[0]
		var r: Rect2 = _glyph_rect(l)
		var st := _lum_stats(bg, Rect2(r.position * k, r.size * k))
		var lc: float = _lum(l.get_theme_color("font_color"))
		var med: float = _ratio(lc, st.x)
		var worst: float = _ratio(lc, st.y if lc < st.x else st.z)  # the background nearest the text's own lightness
		var cap: Label = smp[2]
		if cap:
			cap.text = "%s · %.1f:1 (worst %.1f)" % [smp[1], med, worst] if smp[1] != "" else "%.1f:1 (worst %.1f)" % [med, worst]
		lines.append("TYPE %s %-34s %-60s median %.1f worst %.1f" % [size, l.text.left(34), smp[1], med, worst])
		l.visible = true
	await process_frame
	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	im.save_png(out)
	for s in lines:
		print(s)
	print("TYPE %s -> %s" % [size, out])
	quit()


func _tex(t: Texture2D, r: Rect2, tile: bool) -> void:
	var tr := TextureRect.new()
	tr.texture = t
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_TILE if tile else TextureRect.STRETCH_SCALE
	tr.position = r.position
	tr.size = r.size
	sheet.add_child(tr)


func _plate(r: Rect2) -> void:
	var p := NinePatchRect.new()
	p.texture = plate_tex
	p.patch_margin_left = 34
	p.patch_margin_right = 34
	p.patch_margin_top = 34
	p.patch_margin_bottom = 34
	p.position = r.position
	p.size = r.size
	sheet.add_child(p)


func _head(t: String, at: Vector2, c: Color) -> void:
	var l := _plain(t, Style.SERIF, 28, c)
	l.position = at
	sheet.add_child(l)


func _plain(t: String, f: Font, s: int, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", s)
	l.add_theme_color_override("font_color", c)
	return l


## A sample at its game size, with a caption under it (filled with its contrast once measured).
func _sample(t: String, f: Font, s: int, c: Color, at: Vector2, kind: String, centre := false, dark := false) -> void:
	var l := _plain(t, f, s, c)
	l.position = at
	if centre:
		l.size = Vector2(120, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.add_child(l)
	var cap := _plain("", Style.SERIF, 24, BONE if dark else INK)
	cap.position = at + Vector2(-70 if centre else 0, l.get_minimum_size().y - 4)
	sheet.add_child(cap)
	samples.append([l, kind, cap])


## The label's ink box: its text's width at its alignment, the font's ascent band (layout px).
func _glyph_rect(l: Label) -> Rect2:
	var f: Font = l.get_theme_font("font")
	var s: int = l.get_theme_font_size("font_size")
	var w: float = f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	var x: float = l.position.x
	if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x += (l.size.x - w) / 2.0
	var h: float = l.get_minimum_size().y
	return Rect2(x, l.position.y + h * 0.2, w, h * 0.6)


## Background luminance under r (viewport px): x median, y its darkest 5%, z its lightest 5%.
func _lum_stats(im: Image, r: Rect2) -> Vector3:
	var ls: Array = []
	var x0 := int(maxf(r.position.x, 0))
	var y0 := int(maxf(r.position.y, 0))
	for yy in range(y0, mini(int(r.end.y), im.get_height()), 2):
		for xx in range(x0, mini(int(r.end.x), im.get_width()), 2):
			ls.append(_lum(im.get_pixel(xx, yy)))
	if ls.is_empty():
		return Vector3(1, 1, 1)
	ls.sort()
	return Vector3(ls[ls.size() / 2], ls[int(ls.size() * 0.05)], ls[int(ls.size() * 0.95)])


func _ratio(a: float, b: float) -> float:
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)


func _lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


## A colour darkened (or lightened) in steps until it reads 4.5:1 on a background: the page's darkest 5%
## (0.62), or the plate's lightest 5% (PLATE_L).
func _to_ratio(c: Color, darker: bool, bgl := 0.62) -> Color:
	var out := c
	var i := 0
	while _ratio(_lum(out), bgl) < 4.5 and i < 40:
		out = out.darkened(0.05) if darker else out.lightened(0.05)
		i += 1
	return out
