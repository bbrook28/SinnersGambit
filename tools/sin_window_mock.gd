## Sin selection window mock (REPLY 30): every Sin as a lancet in one stained-glass window, in place of the
## carousel. Not wired. The tracery here is a PLACEHOLDER (flat gold lines), to show layout at 0 credits;
## the real frame is one painted piece made after the REPLY 29 target frame is approved.
## - Lancets: the kept Sin windows (assets/art/runtime/sins/<sin>.png), cropped from the top to LANCET_RATIO
##   (their arch and figure; the lower part of each tall window is cut), each keeping its own frame.
## - Two tiers: 4 over 3 (Tuning.SIN order of RulesText.SIN_ORDER).
## - Unlit: desaturated and dark, lead lines still visible. Lit: full colour, a bloom and a coloured spill below.
## - Under the window: a painted plate with the lit Sin's name, epithet and power, and the Choose seal.
## Layout px are the game's (1080 wide); the SE device is 750 x 1334 px (x 0.694).
## godot --path . --fixed-fps 60 --script res://tools/sin_window_mock.gd -- <none|Lust|Sloth|...> <out.png>
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")
const Style = preload("res://ui/style.gd")
const Art = preload("res://ui/art.gd")
const T = preload("res://ui/rules_text.gd")
const PAGE := preload("res://assets/art/runtime/table/page.jpg")
const TABLE := preload("res://assets/art/runtime/table/table.jpg")
const PLATE := preload("res://assets/art/runtime/table/plate.png")
const SEAL := preload("res://assets/art/runtime/table/seal_throw.png")

const W := 1080.0
const SIDE := 44.0          # the window's outer edge from the screen side
const GAP := 22.0           # mullion between lancets
const LANCET_RATIO := 2.0   # height / width of each lancet's crop (the kept windows are about 3.4)
const CANOPY := 70.0        # the arch over each lancet
const TIER_GAP := 46.0      # the transom between tiers
const TOP := 90.0  # the frame clears the SE status bar (20 pt = 58 px)
const PLATE_H := 300.0
const GOLD := Color("e9c46a")
const INK := Color("2a1810")
const BONE := Color("e8dcbc")

const UNLIT := """
shader_type canvas_item;
uniform float lit = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	vec3 night = vec3(l) * vec3(0.32, 0.34, 0.42);  // glass at night: dark, cold, no colour
	vec3 day = c.rgb * 1.12;                        // lit: full colour, a touch brighter
	COLOR = vec4(mix(night, day, lit), c.a);
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
	var vp: Vector2 = root.get_visible_rect().size
	var h: float = W * px[1] / px[0]
	var s := Control.new()
	s.size = Vector2(W, h)
	root.add_child(s)
	var bg := _tex(s, TABLE, Rect2(0, 0, W, h), true)
	bg.modulate = Color(0.45, 0.4, 0.38)

	var lw: float = (W - 2.0 * SIDE - 3.0 * GAP) / 4.0
	var lh: float = lw * LANCET_RATIO
	var names: Array = T.SIN_ORDER
	var rects := []
	for i in names.size():
		var tier: int = 0 if i < 4 else 1
		var n_in: int = 4 if tier == 0 else names.size() - 4
		var j: int = i if tier == 0 else i - 4
		var row_w: float = n_in * lw + (n_in - 1) * GAP
		var x: float = (W - row_w) / 2.0 + j * (lw + GAP)
		var y: float = TOP + CANOPY + tier * (lh + TIER_GAP + CANOPY)
		rects.append(Rect2(x, y, lw, lh))
	var frame := Rect2(SIDE - 18, TOP - 18, W - 2 * SIDE + 36, (rects[-1] as Rect2).end.y - TOP + 18 + 50)

	# window back: dark lead behind the glass
	var back := ColorRect.new()
	back.color = Color(0.06, 0.04, 0.04)
	back.position = frame.position
	back.size = frame.size
	s.add_child(back)
	var lit_i := names.find(lit)
	for i in names.size():
		var r: Rect2 = rects[i]
		var on := i == lit_i
		if on:  # bloom behind the lancet
			var g := _tex(s, Art.soft_dot(128), Rect2(r.position - r.size * 0.45, r.size * 1.9), false)
			g.material = Art.additive()
			g.modulate = Color(Style.SIN_COLORS[names[i]].lightened(0.3), 0.9)
		var t := _tex(s, Art.window_crop(names[i], LANCET_RATIO), r, false)
		var m := ShaderMaterial.new()
		m.shader = Shader.new()
		m.shader.code = UNLIT
		m.set_shader_parameter("lit", 1.0 if on else 0.0)
		t.material = m
		if on:  # bloom over the glass, and the coloured spill down onto the base band and plate
			var o := _tex(s, Art.soft_dot(128), Rect2(r.position + Vector2(-r.size.x * 0.2, r.size.y * 0.1), Vector2(r.size.x * 1.4, r.size.y * 0.7)), false)
			o.material = Art.additive()
			o.modulate = Color(Style.SIN_COLORS[names[i]].lightened(0.4), 0.35)
	# placeholder tracery: the frame, a canopy arch over each lancet, the transom and the base band
	_rect_line(s, frame, 10.0)
	for r in rects:
		_arch(s, r)
		_rect_line(s, Rect2(r.position - Vector2(6, 0), r.size + Vector2(12, 6)), 5.0)
	var base_y: float = frame.end.y
	var band := ColorRect.new()
	band.color = Color(0.42, 0.3, 0.12)
	band.position = Vector2(frame.position.x, base_y - 36)
	band.size = Vector2(frame.size.x, 36)
	s.add_child(band)
	_rect_line(s, Rect2(band.position, band.size), 5.0)
	var tag := Style.label("placeholder tracery", 26, Color(GOLD, 0.8))
	tag.size = Vector2(frame.size.x, 36)
	tag.position = band.position
	s.add_child(tag)
	if lit_i >= 0:  # the spill below the window, in the lit Sin's colour
		var r: Rect2 = rects[lit_i]
		var sp := _tex(s, Art.soft_dot(128), Rect2(r.get_center().x - 330, base_y - 60, 660, 360), false)
		sp.material = Art.additive()
		sp.modulate = Color(Style.SIN_COLORS[names[lit_i]].lightened(0.2), 0.55)

	# the plate: name, epithet, power
	var py: float = base_y + 30
	var plate := NinePatchRect.new()
	plate.texture = PLATE
	for k in ["patch_margin_left", "patch_margin_right", "patch_margin_top", "patch_margin_bottom"]:
		plate.set(k, 22)
	plate.position = Vector2(SIDE, py)
	plate.size = Vector2(W - 2 * SIDE, PLATE_H)
	s.add_child(plate)
	var who: String = names[lit_i] if lit_i >= 0 else ""
	var head := Style.label(("%s, %s" % [who, T.SINS[who].epithet]) if who != "" else "Touch a Sin", 60, Style.SIN_COLORS[who].lightened(0.35) if who != "" else GOLD, true)
	head.position = plate.position + Vector2(30, 22)
	head.size = Vector2(plate.size.x - 60, 70)
	s.add_child(head)
	if who != "":
		var body := Style.label("%s: %s" % [T.SINS[who].power[0], T.power(who)], 40, BONE)
		body.position = plate.position + Vector2(40, 104)
		body.size = Vector2(plate.size.x - 80, 200)
		s.add_child(body)
	# the Choose seal
	var sd := 180.0
	var seal := _tex(s, SEAL, Rect2(W / 2 - sd / 2, py + PLATE_H + 24, sd, sd), false)
	if who == "":
		seal.modulate = Color(0.5, 0.45, 0.45)
	var cw := Style.label("Choose", 48, INK if false else BONE, true)
	cw.position = Vector2(W / 2 - 150, py + PLATE_H + 24 + sd - 10)
	cw.size = Vector2(300, 60)
	s.add_child(cw)

	await process_frame
	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	im.save_png(out)
	print("SINWIN %s lancet %dx%d layout px = %dx%d SE px; window %d..%d; plate %d..%d; seal %d..%d (of %d) -> %s" % [lit, lw, lh, lw * px[0] / W, lh * px[0] / W, frame.position.y, frame.end.y, py, py + PLATE_H, py + PLATE_H + 24, py + PLATE_H + 24 + sd + 50, h, out])
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


## A pointed canopy arch over a lancet (two arcs meeting at a point).
func _arch(p: Control, r: Rect2) -> void:
	var l := Line2D.new()
	var pts := PackedVector2Array()
	var x0: float = r.position.x - 6
	var x1: float = r.end.x + 6
	var y: float = r.position.y
	var top := Vector2((x0 + x1) / 2.0, y - CANOPY + 8)
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
