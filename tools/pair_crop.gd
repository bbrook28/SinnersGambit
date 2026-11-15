## Before | after close-up: the same rect from two images, side by side, scaled up (nearest), with a
## 6 px gap. For review packets (Docs/review/latest/).
## godot --headless --path . --script res://tools/pair_crop.gd -- <before.png> <after.png> <out.png> x y w h [scale]
extends SceneTree

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var r := Rect2i(int(a[3]), int(a[4]), int(a[5]), int(a[6]))
	var s := int(a[7]) if a.size() > 7 else 2
	var out := Image.create(r.size.x * s * 2 + 6, r.size.y * s, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.12, 0.12, 0.13))
	for i in 2:
		var im := Image.load_from_file(a[i])
		im.convert(Image.FORMAT_RGBA8)
		var c := im.get_region(r)
		c.resize(r.size.x * s, r.size.y * s, Image.INTERPOLATE_NEAREST)
		out.blit_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(i * (r.size.x * s + 6), 0))
	out.save_png(a[2])
	quit()
