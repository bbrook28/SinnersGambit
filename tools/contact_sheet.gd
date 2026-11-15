## Scratch: a strip of portrait_raw images (384 px each) for a quick look, on magenta.
## godot --headless --path . --script res://tools/contact_sheet.gd -- <out.png> <file> [file...]
extends SceneTree

const SRC := "res://assets/art/sins/portrait_raw/"
const S := 384


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var names := args.slice(1)
	var sheet := Image.create(S * names.size(), S, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(1, 0, 1))
	for i in names.size():
		var p: String = names[i] if names[i].contains("/") else SRC + names[i]
		var im := Image.load_from_file(ProjectSettings.globalize_path(p))
		im.convert(Image.FORMAT_RGBA8)
		im.resize(S, roundi(S * float(im.get_height()) / im.get_width()), Image.INTERPOLATE_BILINEAR)
		sheet.blend_rect(im, Rect2i(0, 0, S, S), Vector2i(S * i, 0))
	sheet.save_png(args[0])
	quit()
