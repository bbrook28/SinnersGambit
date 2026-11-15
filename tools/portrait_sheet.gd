## All seven baked stills in one sheet, colour over greyscale (figure-ground check).
## godot --headless --path . --script res://tools/portrait_sheet.gd -- <out.png> [still name, default still.png]
extends SceneTree

const SINS := ["wrath", "pride", "greed", "envy", "gluttony", "lust", "sloth"]
const W := 328
const H := 410


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var name: String = a[1] if a.size() > 1 else "still.png"
	var sheet := Image.create(SINS.size() * (W + 6) - 6, H * 2 + 6, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.1, 0.1))
	for i in SINS.size():
		var im := Image.load_from_file(ProjectSettings.globalize_path("res://assets/art/runtime/sins/%s_layers/%s" % [SINS[i], name]))
		im.convert(Image.FORMAT_RGBA8)
		im.resize(W, H, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(im, Rect2i(0, 0, W, H), Vector2i(i * (W + 6), 0))
		for y in H:
			for x in W:
				var c := im.get_pixel(x, y)
				var l := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
				im.set_pixel(x, y, Color(l, l, l))
		sheet.blit_rect(im, Rect2i(0, 0, W, H), Vector2i(i * (W + 6), H + 6))
	sheet.save_png(ProjectSettings.globalize_path(a[0]))
	quit()
