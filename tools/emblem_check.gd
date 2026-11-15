## Every emblem seal at the sizes it is drawn on screen (game px), to catch emblems that fill in.
## Rows: 280 (menu), 200 (Bank/Throw, Choose), 140 (small seals). Left half on parchment, right on dark.
## godot --headless --path . --script res://tools/emblem_check.gd -- <out.png> [name ...]
extends SceneTree

const RAW := "res://assets/art/seals/raw/emblem_%s_raw.png"
const NAMES := ["play", "bank", "refuse", "throw_v2", "choose", "rulebook", "settings", "pause", "back", "newgame",
	"accept_gluttony_v2", "accept_wrath", "accept_greed", "accept_lust", "accept_envy", "accept_pride", "accept_sloth",
	"bank_cracked", "throw_cracked", "choose_cracked"]
const SIZES := [280, 200, 140]


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var names: Array = a.slice(1) if a.size() > 1 else NAMES
	var cell := 300
	var sheet := Image.create(cell * names.size(), cell * SIZES.size() + 40, false, Image.FORMAT_RGBA8)
	for i in names.size():
		var im := Image.load_from_file(ProjectSettings.globalize_path(RAW % names[i]))
		im.convert(Image.FORMAT_RGBA8)
		for y in im.get_height():
			for x in im.get_width():
				var c := im.get_pixel(x, y)
				c.a = 1.0 if c.a > 0.6 else 0.0
				im.set_pixel(x, y, c)
		im = im.get_region(im.get_used_rect())
		var bgc := Color("c8b28a") if i % 2 == 0 else Color("1c1512")
		sheet.fill_rect(Rect2i(i * cell, 0, cell, sheet.get_height()), bgc)
		for r in SIZES.size():
			var s: int = SIZES[r]
			var t: Image = im.duplicate()
			t.resize(s, roundi(s * float(t.get_height()) / t.get_width()), Image.INTERPOLATE_LANCZOS)
			sheet.blend_rect(t, Rect2i(Vector2i.ZERO, t.get_size()), Vector2i(i * cell + (cell - s) / 2, 40 + r * cell + (cell - t.get_height()) / 2))
	sheet.save_png(ProjectSettings.globalize_path(a[0]))
	print("emblems: %d" % names.size())
	quit()
