## Pixel boxes for art made to size (REPLY 16 item 8): opens table fixtures (tools/fixture.gd) and prints
## the table view's boxes (ui/table_blockout.gd `boxes`: windows, head, mask, shoulders, robe, arm, card)
## in the layout's own pixels (1080 wide; the height is the device's at that size).
## godot --path . --fixed-fps 60 --script res://tools/boxes.gd -- <fixture,fixture,...> [se|std|max]
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.is_empty():
		print("usage: -- <fixture,fixture,...> [se|std|max]")
		quit(1)
		return
	var size: String = a[1] if a.size() > 1 else "std"
	var px: Array = Fixture.SIZES[size].px
	await process_frame
	DisplayServer.window_set_size(Vector2i(px[0], px[1]))
	root.size = Vector2i(px[0], px[1])
	await process_frame
	await process_frame
	for name in a[0].split(","):
		var main = await Fixture.apply(self, Fixture.read(name), size)
		await process_frame
		var t = main._overlay if main != null else null
		if t == null or not ("boxes" in t):
			printerr("BOXES FAILED %s %s: no table view" % [name, size])
			quit(1)
			return
		var vp: Vector2 = t.get_viewport_rect().size
		print("## %s (%s, layout %dx%d px)" % [name, size, int(vp.x), int(vp.y)])
		var b: Dictionary = t.boxes
		for k in ["head", "mask", "shoulders", "robe", "arm", "card"]:
			if b.has(k):
				print("  %-9s %s" % [k, _r(b[k])])
		var ws := []
		for r in b.get("windows", []):
			ws.append(_r(r))
		print("  windows   " + " | ".join(ws))
		main.queue_free()
		await process_frame
	quit()


## x, y, w x h, rounded to the pixel.
func _r(r: Rect2) -> String:
	return "%d,%d %dx%d" % [roundi(r.position.x), roundi(r.position.y), roundi(r.size.x), roundi(r.size.y)]
