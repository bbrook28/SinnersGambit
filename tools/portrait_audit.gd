## Hands-and-faces audit (Ben, Nov 15): one crop per hand and per face from every Sin's still.png at
## full resolution, in one sheet, each with its verdict. The crops and verdicts live in CROPS; set a
## verdict only after looking at the crop at full size:
##   thumb and four fingers present or plausibly hidden; every finger joined to the palm; no extra
##   knuckles, nails on the right side; no pane, lead line or outline crossing a hand or face.
## godot --path . --resolution 1600x2400 --script res://tools/portrait_audit.gd -- <out.png>
extends SceneTree

const CELL := 360
const COLS := 4
## [sin, what, window rect x y w h, verdict ("pass", "fail" or "" before checking), note]
const CROPS := [
	["Wrath", "face", [290, 260, 240, 260], "pass", ""],
	["Wrath", "left fist", [80, 60, 200, 170], "pass", ""],
	["Wrath", "right fist", [520, 40, 210, 180], "pass", ""],
	["Greed", "face", [420, 150, 250, 260], "pass", ""],
	["Greed", "coin hand", [470, 380, 240, 250], "pass", "fixed: pane and line off the hand"],
	["Greed", "lower hand", [290, 580, 320, 190], "pass", ""],
	["Lust", "face", [430, 160, 260, 260], "pass", ""],
	["Lust", "dice hand", [20, 620, 310, 270], "pass", ""],
	["Lust", "chest hand", [420, 360, 360, 360], "pass", "fixed: thumb added (crop edit)"],
	["Envy", "face", [230, 180, 330, 360], "pass", ""],
	["Envy", "hand", [50, 590, 260, 340], "pass", ""],
	["Pride", "face", [250, 170, 270, 260], "pass", ""],
	["Pride", "mirror face", [640, 150, 180, 270], "pass", ""],
	["Pride", "hair hand", [0, 450, 210, 230], "pass", ""],
	["Pride", "mirror hand", [630, 450, 170, 270], "pass", ""],
	["Gluttony", "face", [460, 180, 360, 340], "pass", ""],
	["Gluttony", "goblet hand", [30, 170, 310, 310], "pass", "fixed: little finger joined"],
	["Gluttony", "dice hand", [500, 560, 270, 330], "pass", ""],
	["Sloth", "face", [290, 110, 300, 320], "pass", ""],
	["Sloth", "cheek hand", [250, 270, 200, 200], "pass", ""],
	["Sloth", "resting hand", [450, 770, 290, 230], "pass", ""],
]


func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var root_c := Control.new()
	root_c.size = Vector2(COLS * CELL, ceili(CROPS.size() / float(COLS)) * (CELL + 64))
	var bg := ColorRect.new()
	bg.color = Color("16110e")
	bg.size = root_c.size
	root_c.add_child(bg)
	var stills := {}
	for i in CROPS.size():
		var e: Array = CROPS[i]
		if not stills.has(e[0]):
			stills[e[0]] = Image.load_from_file(ProjectSettings.globalize_path("res://assets/art/runtime/sins/%s_layers/still.png" % e[0].to_lower()))
		var r: Array = e[2]
		var im: Image = stills[e[0]].get_region(Rect2i(r[0], r[1], r[2], r[3]))
		var k := minf(float(CELL - 12) / r[2], float(CELL - 12) / r[3])
		im.resize(roundi(r[2] * k), roundi(r[3] * k), Image.INTERPOLATE_LANCZOS)
		var cx := (i % COLS) * CELL
		var cy := (i / COLS) * (CELL + 64)
		var t := TextureRect.new()
		t.texture = ImageTexture.create_from_image(im)
		t.position = Vector2(cx + (CELL - im.get_width()) / 2.0, cy + 6 + (CELL - 12 - im.get_height()) / 2.0)
		root_c.add_child(t)
		var v: String = e[3]
		var l := Label.new()
		l.text = "%s · %s · %s%s" % [e[0], e[1], v.to_upper() if v != "" else "?", ("\n" + e[4]) if e[4] != "" else ""]
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", Color("6fd36f") if v == "pass" else (Color("ff6a5a") if v == "fail" else Color.WHITE))
		l.position = Vector2(cx + 8, cy + CELL - 2)
		root_c.add_child(l)
	var vp := SubViewport.new()
	vp.size = Vector2i(root_c.size)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.add_child(root_c)
	root.add_child(vp)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(out)
	print("sheet: %d crops -> %s" % [CROPS.size(), out])
	quit()
