## Sin selection window mock (REPLY 30, re-mocked for REPLY 31 item 4): every Sin as a lancet in one
## stained-glass window, in place of the carousel. Not wired. The tracery is a PLACEHOLDER (flat gold lines),
## to show layout at 0 credits; the real frame is one painted piece made after the target frame is approved.
## - Lancets: the kept Sin windows (assets/art/runtime/sins/<sin>.png), each keeping its own frame, cropped
##   from the top to whatever height is left once the heading, plate, table control and seal have their room
##   (the crop is printed). Two tiers, 4 over 3, in RulesText.SIN_ORDER.
## - Unlit: moonlit grey with a hint of the Sin's own colour, lead lines visible. Lit: the carousel's glass
##   shader (menu_glass: sheen and backlight), a bloom and a coloured spill below.
## - Above: "Choose thy Sin" in Pirata One (as today). Under the window: a painted plate with the lit Sin's name
##   and epithet (in its colour, lifted to 4.5:1 on the plate), play line and both abilities (IM Fell, 44 px:
##   15 pt on the smallest phone); the "Recommended" tag on Sloth; the table size (4 / 7) and the Choose seal.
## Layout px are the game's (1080 wide); the SE device is 750 x 1334 px (x 0.694).
## godot --path . --fixed-fps 60 --script res://tools/sin_window_mock.gd -- <none|Lust|Sloth|...> <out.png>
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")
const Style = preload("res://ui/style.gd")
const Art = preload("res://ui/art.gd")
const T = preload("res://ui/rules_text.gd")
const B = preload("res://ui/table_blockout.gd")
const Tuning = preload("res://ui/tuning.gd")
const TABLE := preload("res://assets/art/runtime/table/table.jpg")
const PLATE := preload("res://assets/art/runtime/table/plate.png")
const SEAL := preload("res://assets/art/runtime/table/seal_throw.png")
const MENU_GLASS := preload("res://ui/shaders/menu_glass.gdshader")

const W := 1080.0
const SAFE_TOP := 58.0      # SE status bar: 20 pt
const SIDE := 40.0          # the window's outer edge from the screen side
const GAP := 18.0           # mullion between lancets
const CANOPY := 56.0        # the arch over each lancet
const TIER_GAP := 8.0       # the transom between tiers (was 46)
const BASE := 30.0          # the window's base band
const TXT := 44             # body text: 15 pt on the smallest phone
const GOLD := Color("e9c46a")
const BONE := Color("e8dcbc")

const UNLIT := """
shader_type canvas_item;
uniform vec4 tint : source_color;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	vec3 moon = vec3(l) * vec3(0.78, 0.82, 0.92) + vec3(0.03, 0.03, 0.05);  // moonlit grey
	vec3 hint = mix(moon, moon * tint.rgb * 1.6, 0.28);                    // a hint of the Sin's own colour
	COLOR = vec4(hint * 0.92, c.a);
}
"""


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var lit: String = a[0]
	var out: String = a[1]
	var px: Array = Fixture.SIZES["se"].px
	await process_frame
	DisplayServer.window_set_size(Vector2i(px[0], px[1]))
	root.size = Vector2i(px[0], px[1])
	await process_frame
	var h: float = W * px[1] / px[0]
	var s := Control.new()
	s.size = Vector2(W, h)
	root.add_child(s)
	var bg := _tex(s, TABLE, Rect2(0, 0, W, h), true)
	bg.modulate = Color(0.45, 0.4, 0.38)
	var names: Array = T.SIN_ORDER
	var lit_i := names.find(lit)
	var who: String = names[lit_i] if lit_i >= 0 else ""

	# Top: the heading, as today (blackletter, gold, its first letter red).
	var head := RichTextLabel.new()
	head.bbcode_enabled = true
	head.fit_content = true
	head.scroll_active = false
	head.add_theme_font_override("normal_font", Style.BLACKLETTER)
	head.add_theme_font_size_override("normal_font_size", 96)
	head.add_theme_color_override("default_color", GOLD)
	var title: String = T.word("setup_title")
	head.text = "[center][color=#%s]%s[/color]%s[/center]" % [Style.C_STRIKE.to_html(false), title.left(1), title.substr(1)]
	head.position = Vector2(0, SAFE_TOP)
	head.size = Vector2(W, 110)
	s.add_child(head)
	var top: float = SAFE_TOP + 116.0

	# Bottom up: the seal row (table size at the left, Choose seal at the right), then the plate.
	var sd := 170.0
	var seal_y: float = h - 24.0 - 52.0 - sd
	var plate_w: float = W - 2.0 * SIDE
	var body_w: float = plate_w - 64.0
	var lines := []  # [text, font, size, colour]
	if who != "":
		lines.append(["%s, %s" % [who, T.SINS[who].epithet], Style.BLACKLETTER, 60, B.on_plate(Style.SIN_COLORS[who].lightened(0.35))])
		lines.append([T.SINS[who].play, Style.SERIF, TXT, BONE.darkened(0.12)])
		for g in [false, true]:
			lines.append(["%s: %s" % [T.ability_name(who, g), T.ability_text(who, g)], Style.SERIF, TXT, BONE])
	else:
		lines.append(["Touch a Sin", Style.BLACKLETTER, 60, GOLD])
	var labels := []
	var body_h := 0.0
	for l in lines:
		var lb := Style.label(l[0], l[2], l[3], l[1] == Style.BLACKLETTER)
		lb.add_theme_font_override("font", l[1])
		lb.custom_minimum_size = Vector2(body_w, 0)
		lb.size = Vector2(body_w, 0)
		s.add_child(lb)
		labels.append(lb)
		body_h += lb.get_minimum_size().y + 4.0
	# the plate is as tall as the longest Sin's text, so the window never changes size as Sins light
	var most := 0.0
	for n in names:
		var hh := 0.0
		var texts := [["%s, %s" % [n, T.SINS[n].epithet], Style.BLACKLETTER, 60], [T.SINS[n].play, Style.SERIF, TXT]]
		for g in [false, true]:
			texts.append(["%s: %s" % [T.ability_name(n, g), T.ability_text(n, g)], Style.SERIF, TXT])
		for tx in texts:
			var pr := Style.label(tx[0], tx[2], BONE, tx[1] == Style.BLACKLETTER)
			pr.add_theme_font_override("font", tx[1])
			pr.custom_minimum_size = Vector2(body_w, 0)
			pr.size = Vector2(body_w, 0)
			s.add_child(pr)
			hh += pr.get_minimum_size().y + 4.0
			pr.queue_free()
		most = maxf(most, hh)
	var plate_h: float = most + 44.0
	var plate_y: float = seal_y - 20.0 - plate_h

	# The window gets what is left: two tiers of lancets, canopies, the transom and the base.
	var lw: float = (W - 2.0 * SIDE - 3.0 * GAP) / 4.0
	var room: float = plate_y - 24.0 - top - 2.0 * 18.0
	var lh: float = (room - 2.0 * CANOPY - TIER_GAP - BASE) / 2.0
	var ratio: float = lh / lw
	var rects := []
	for i in names.size():
		var tier: int = 0 if i < 4 else 1
		var n_in: int = 4 if tier == 0 else names.size() - 4
		var j: int = i if tier == 0 else i - 4
		var row_w: float = n_in * lw + (n_in - 1) * GAP
		var x: float = (W - row_w) / 2.0 + j * (lw + GAP)
		var y: float = top + 18.0 + CANOPY + tier * (lh + TIER_GAP + CANOPY)
		rects.append(Rect2(x, y, lw, lh))
	var frame := Rect2(SIDE - 18, top, W - 2 * SIDE + 36, (rects[-1] as Rect2).end.y - top + 8 + BASE)
	var back := ColorRect.new()
	back.color = Color(0.06, 0.04, 0.04)
	back.position = frame.position
	back.size = frame.size
	s.add_child(back)
	for i in names.size():
		var r: Rect2 = rects[i]
		var on := i == lit_i
		var col: Color = Style.SIN_COLORS[names[i]]
		if on:  # bloom behind the lancet
			var g := _tex(s, Art.soft_dot(128), Rect2(r.position - r.size * 0.45, r.size * 1.9), false)
			g.material = Art.additive()
			g.modulate = Color(col.lightened(0.3), 0.9)
		var t := _tex(s, Art.window_crop(names[i], ratio), r, false)
		var m := ShaderMaterial.new()
		if on:  # the carousel's glass: sheen and backlight
			m.shader = MENU_GLASS
			m.set_shader_parameter("phase", 2.0)
			m.set_shader_parameter("period", Tuning.MENU_SHEEN_PERIOD)
			m.set_shader_parameter("motion", 1.0)
		else:
			m.shader = Shader.new()
			m.shader.code = UNLIT
			m.set_shader_parameter("tint", col)
		t.material = m
		if on:
			var o := _tex(s, Art.soft_dot(128), Rect2(r.position + Vector2(-r.size.x * 0.2, r.size.y * 0.1), Vector2(r.size.x * 1.4, r.size.y * 0.7)), false)
			o.material = Art.additive()
			o.modulate = Color(col.lightened(0.4), 0.3)
		if names[i] == "Sloth":  # the "Recommended" tag, as today
			var tag := NinePatchRect.new()
			tag.texture = PLATE
			for k in ["patch_margin_left", "patch_margin_right", "patch_margin_top", "patch_margin_bottom"]:
				tag.set(k, 14)
			tag.position = Vector2(r.position.x - 4, r.end.y - 62)
			tag.size = Vector2(r.size.x + 8, 56)
			s.add_child(tag)
			var tl := Style.label(T.word("setup_recommended"), 34, GOLD, true)
			tl.position = tag.position + Vector2(0, 6)
			tl.size = Vector2(tag.size.x, 44)
			s.add_child(tl)
	_rect_line(s, frame, 10.0)
	for r in rects:
		_arch(s, r)
		_rect_line(s, Rect2(r.position - Vector2(5, 0), r.size + Vector2(10, 5)), 5.0)
	var band := ColorRect.new()
	band.color = Color(0.42, 0.3, 0.12)
	band.position = Vector2(frame.position.x, frame.end.y - BASE)
	band.size = Vector2(frame.size.x, BASE)
	s.add_child(band)
	_rect_line(s, Rect2(band.position, band.size), 5.0)
	var ptag := Style.label("placeholder tracery", 22, Color(GOLD, 0.8))
	ptag.size = Vector2(frame.size.x, BASE)
	ptag.position = band.position
	s.add_child(ptag)
	if lit_i >= 0:
		var r: Rect2 = rects[lit_i]
		var sp := _tex(s, Art.soft_dot(128), Rect2(r.get_center().x - 330, frame.end.y - 60, 660, 340), false)
		sp.material = Art.additive()
		sp.modulate = Color(Style.SIN_COLORS[names[lit_i]].lightened(0.2), 0.5)

	var plate := NinePatchRect.new()
	plate.texture = PLATE
	for k in ["patch_margin_left", "patch_margin_right", "patch_margin_top", "patch_margin_bottom"]:
		plate.set(k, 22)
	plate.position = Vector2(SIDE, plate_y)
	plate.size = Vector2(plate_w, plate_h)
	s.add_child(plate)
	var y: float = plate_y + 22.0
	for lb in labels:
		lb.position = Vector2(SIDE + 32, y)
		y += lb.get_minimum_size().y + 4.0
		s.move_child(lb, -1)
	# the seal row: table size (4 | 7) at the left, the Choose seal at the right
	var seg_w := 190.0
	for k in 2:
		var b := NinePatchRect.new()
		b.texture = PLATE
		for mm in ["patch_margin_left", "patch_margin_right", "patch_margin_top", "patch_margin_bottom"]:
			b.set(mm, 18)
		b.position = Vector2(SIDE + k * (seg_w + 8), seal_y + 30)
		b.size = Vector2(seg_w, 128)
		if k == 0:
			b.modulate = Color(1.0, 0.42, 0.38)  # selected: the plate dyed crimson (as the menus sheet)
		s.add_child(b)
		var bl := Style.label(T.word("setup_table", {"n": [4, 7][k]}), TXT, GOLD, true)
		bl.position = b.position + Vector2(0, 34)
		bl.size = Vector2(seg_w, 60)
		s.add_child(bl)
	var sx: float = W - SIDE - 60.0 - sd
	var seal := _tex(s, SEAL, Rect2(sx, seal_y, sd, sd), false)
	if who == "":
		seal.modulate = Color(0.5, 0.45, 0.45)
	var cw := Style.label(T.word("setup_choose") if T.WORDS.has("setup_choose") else "Choose", 48, BONE, true)
	cw.position = Vector2(sx + sd / 2 - 150, seal_y + sd - 4)
	cw.size = Vector2(300, 56)
	s.add_child(cw)

	await process_frame
	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	im.save_png(out)
	var c_info := ""
	for n in names:
		var raw: Color = Style.SIN_COLORS[n].lightened(0.35)
		c_info += " %s %.1f->%.1f" % [n, B._contrast(B._rl(raw), B.PLATE_L), B._contrast(B._rl(B.on_plate(raw)), B.PLATE_L)]
	print("SINWIN %s lancet %dx%d layout px = %dx%d SE px, crop %.2f:1 of 3.4; window %d..%d; plate %d..%d; seal row %d..%d (of %d) | name on plate:%s -> %s" % [lit, lw, lh, lw * px[0] / W, lh * px[0] / W, ratio, frame.position.y, frame.end.y, plate_y, plate_y + plate_h, seal_y, seal_y + sd + 52, h, c_info, out])
	quit()


func _tex(p: Control, t: Texture2D, r: Rect2, tile: bool) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = t
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_TILE if tile else TextureRect.STRETCH_SCALE
	tr.position = r.position
	tr.size = r.size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tr)
	return tr


func _rect_line(p: Control, r: Rect2, w: float) -> void:
	var l := Line2D.new()
	l.points = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position])
	l.width = w
	l.default_color = GOLD.darkened(0.15)
	p.add_child(l)


## A pointed canopy arch over a lancet.
func _arch(p: Control, r: Rect2) -> void:
	var l := Line2D.new()
	var pts := PackedVector2Array()
	var x0: float = r.position.x - 5
	var x1: float = r.end.x + 5
	var y: float = r.position.y
	var top := Vector2((x0 + x1) / 2.0, y - CANOPY + 6)
	for k in 13:
		var t: float = k / 12.0
		pts.append(Vector2(x0, y).lerp(Vector2(x0, y - CANOPY * 0.45), t).lerp(Vector2(x0, y - CANOPY * 0.45).lerp(top, t), t))
	for k in 13:
		var t: float = k / 12.0
		pts.append(top.lerp(Vector2(x1, y - CANOPY * 0.45), t).lerp(Vector2(x1, y - CANOPY * 0.45).lerp(Vector2(x1, y), t), t))
	l.points = pts
	l.width = 6.0
	l.default_color = GOLD.darkened(0.1)
	p.add_child(l)
