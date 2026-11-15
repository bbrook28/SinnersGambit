## Crops a region of a PNG and scales it up (nearest) for close inspection; mode "alpha" shows alpha
## as grey, "magenta" composites over magenta so holes show.
## godot --headless --path . --script res://tools/crop.gd -- <in.png> <out.png> x y w h [scale] [mode]
extends SceneTree

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var im := Image.load_from_file(a[0])
	im.convert(Image.FORMAT_RGBA8)
	var r := Rect2i(int(a[2]), int(a[3]), int(a[4]), int(a[5]))
	var c := im.get_region(r)
	var mode: String = a[7] if a.size() > 7 else ""
	if mode != "":
		for y in c.get_height():
			for x in c.get_width():
				var p := c.get_pixel(x, y)
				if mode == "alpha":
					c.set_pixel(x, y, Color(p.a, p.a, p.a, 1))
				else:
					c.set_pixel(x, y, Color(1, 0, 1).lerp(Color(p.r, p.g, p.b), p.a))
	var s := int(a[6]) if a.size() > 6 else 2
	c.resize(r.size.x * s, r.size.y * s, Image.INTERPOLATE_NEAREST)
	c.save_png(a[1])
	quit()
