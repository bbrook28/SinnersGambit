## Pastes an edited crop back into a raw, feathered at the crop's edges (the "crop-only" hand fixes:
## a crop of a layer is edited on SpriteCook, then set back in place so nothing else moves).
## godot --headless --path . --script res://tools/paste_patch.gd -- <base.png> <patch.png> <x> <y> <size> <out.png> [alpha]
##   size: the crop's side in base px (the patch is scaled to it). alpha: "base" keeps the base's alpha
##   (default), "patch" takes the patch's (when the edit changes the silhouette, on a transparent layer).
extends SceneTree

const FEATHER := 24.0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var base := _load(a[0])
	var patch := _load(a[1])
	var x0 := int(a[2])
	var y0 := int(a[3])
	var n := int(a[4])
	var use_patch_alpha := a.size() > 6 and a[6] == "patch"
	patch.resize(n, n, Image.INTERPOLATE_LANCZOS)
	for y in n:
		for x in n:
			var bx := x0 + x
			var by := y0 + y
			if bx < 0 or by < 0 or bx >= base.get_width() or by >= base.get_height():
				continue
			var k := clampf(minf(minf(x, n - 1 - x), minf(y, n - 1 - y)) / FEATHER, 0.0, 1.0)
			var b := base.get_pixel(bx, by)
			var p := patch.get_pixel(x, y)
			var c := b.lerp(p, k)
			c.a = lerpf(b.a, p.a, k) if use_patch_alpha else b.a
			base.set_pixel(bx, by, c)
	base.save_png(_path(a[5]))
	print("pasted %s into %s at %d,%d (%d px)" % [a[1].get_file(), a[5].get_file(), x0, y0, n])
	quit()


func _path(p: String) -> String:
	return ProjectSettings.globalize_path(p) if p.begins_with("res://") else p


func _load(p: String) -> Image:
	var im := Image.load_from_file(_path(p))
	im.convert(Image.FORMAT_RGBA8)
	return im
