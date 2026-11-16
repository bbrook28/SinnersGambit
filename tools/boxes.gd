## Pixel boxes for art made to size (REPLY 16 item 8) and the layout lock (REPLY 23 item 3): opens table
## fixtures (tools/fixture.gd) and prints the table view's boxes (ui/table_blockout.gd `boxes`: windows,
## head, mask, shoulders, robe, arm, card, line), then every element drawn (each Label, Button and die,
## and the page, track band and dice area), in the layout's own pixels (1080 wide; the height is the
## device's at that size). Flags a tap target under 44 pt and any two texts or buttons that overlap.
## godot --path . --fixed-fps 60 --script res://tools/boxes.gd -- <fixture,fixture,...> [se|std|max]
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")
const Die = preload("res://ui/widgets/die.gd")


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.is_empty():
		print("usage: -- <fixture,fixture,...> [se|std|max]")
		quit(1)
		return
	var size: String = a[1] if a.size() > 1 else "std"
	var px: Array = Fixture.SIZES[size].px
	var pt_w: float = Fixture.SIZES[size].pt[0]
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
		var pt: float = vp.x / pt_w  # layout px per pt
		print("## %s (%s, layout %dx%d px, 44 pt = %d px)" % [name, size, int(vp.x), int(vp.y), roundi(44.0 * pt)])
		var b: Dictionary = t.boxes
		for k in ["head", "mask", "shoulders", "robe", "arm", "card", "line"]:
			if b.has(k):
				print("  %-9s %s" % [k, _r(b[k])])
		var ws := []
		for r in b.get("windows", []):
			ws.append(_r(r))
		print("  windows   " + " | ".join(ws))
		print("  page      " + _r(t.page_rect))
		print("  band      " + _r(Rect2(t.page_rect.position, Vector2(t.page_rect.size.x, t.band_bottom - t.page_rect.position.y))))
		print("  dice      " + _r(t.dice_area))
		var items := []  # [kind, text, rect]
		for n in t.find_children("*", "Control", true, false):
			var c := n as Control
			if not c.is_visible_in_tree() or c.size.x <= 0.0 or c.modulate.a * c.self_modulate.a <= 0.05:
				continue
			var r := Rect2(c.global_position, c.size * c.get_global_transform().get_scale())
			if c is Button:
				var bt := c as Button
				var tap: bool = not bt.disabled and bt.mouse_filter != Control.MOUSE_FILTER_IGNORE
				items.append(["button", bt.text.replace("\n", " ") if bt.text != "" else "(%s)" % bt.name, r, tap])
			elif c is Label and (c as Label).text.strip_edges() != "":
				items.append(["label", (c as Label).text.replace("\n", " "), r, false])
			elif c is Die:
				items.append(["die", "", r, false])
		var flags := []
		for it in items:
			var line := "  %-6s %-30s %s" % [it[0], str(it[1]).left(30), _r(it[2])]
			if it[0] == "button" and it[3] and minf(it[2].size.x, it[2].size.y) < 44.0 * pt - 0.5:
				line += "   UNDER 44 PT (%.0f pt)" % (minf(it[2].size.x, it[2].size.y) / pt)
				flags.append("under 44 pt: %s" % it[1])
			print(line)
		for i in items.size():  # overlaps between texts and buttons (a label inside its own button is fine)
			for j in range(i + 1, items.size()):
				var p: Array = items[i]
				var q: Array = items[j]
				if p[0] == "die" or q[0] == "die" or str(p[1]).begins_with("(") or str(q[1]).begins_with("("):
					continue  # a wordless tap area (the track, the dice, a seal) holds what it covers
				var ov: Rect2 = p[2].intersection(q[2])
				if ov.size.x > 2.0 and ov.size.y > 2.0 and not (p[2].encloses(q[2]) or q[2].encloses(p[2])):
					flags.append("overlap (line boxes): %s %s / %s %s (%dx%d px)" % [p[0], str(p[1]).left(24), q[0], str(q[1]).left(24), int(ov.size.x), int(ov.size.y)])
		print("  FLAGS: " + ("none" if flags.is_empty() else ""))
		for f in flags:
			print("    " + f)
		main.queue_free()
		await process_frame
	quit()


## x, y, w x h, rounded to the pixel.
func _r(r: Rect2) -> String:
	return "%d,%d %dx%d" % [roundi(r.position.x), roundi(r.position.y), roundi(r.size.x), roundi(r.size.y)]
