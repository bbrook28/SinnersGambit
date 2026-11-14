## Touch-target audit: walks the setup screen, every prompt layout in a game and the Chronicle,
## checks every visible Button against the rules below, and saves a screenshot of each layout.
## Windowed (not headless), phone size with fake notch / home insets:
## godot --path . --resolution 1080x2341 --script res://tools/ui_audit.gd -- <out_dir>
extends SceneTree

const PT := 1080.0 / 393.0      # px per iPhone point
const MIN_TARGET := 44.0 * PT   # Apple HIG minimum target
const MIN_GAP := 12.0 * PT      # between separate targets
const SIDE := 16.0 * PT         # layout margin at the screen's left and right
const SAFE := Vector2(162, 93)  # notch / home indicator, as main.debug_safe

var main
var out := ""
var seen := {}
var report: Array[String] = []
var prompts := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://ui/main.tscn").instantiate()
	main.debug_safe = SAFE
	root.add_child(main)
	await _settle(20)
	await _check("setup")
	main._start(main.SIN_SCRIPTS[3])
	Engine.time_scale = 40.0
	while prompts < 60:
		await process_frame
		var bs := _prompt_buttons()
		if bs.is_empty() or main._q.busy():
			continue
		Engine.time_scale = 1.0
		await _settle(8)
		bs = _prompt_buttons()
		if bs.is_empty():
			Engine.time_scale = 40.0
			continue
		var sig := ",".join(bs.map(func(b): return b.get_meta("kind", "?")))
		if not seen.has(sig):
			seen[sig] = true
			await _check("prompt_%d [%s] %s" % [seen.size(), sig, main._prompt_label.text.left(40).replace("\n", " ")])
		if bs[0].text == "New game":
			break
		if prompts == 6 and not seen.has("chronicle"):
			seen["chronicle"] = true
			main._log_overlay.visible = true
			await _settle(4)
			await _check("chronicle")
			main._log_overlay.visible = false
		prompts += 1
		Engine.time_scale = 40.0
		bs[randi() % bs.size()].pressed.emit()
	# Worst cases a random game may not reach: many dice, with and without Bank.
	Engine.time_scale = 1.0
	for n in [5, 8]:
		for bank in [false, true]:
			var opts := []
			for i in range(1, n + 1):
				opts.append([str(i), i])
			if bank:
				opts.append(["Bank 1240", 0])
			main._show_prompt_now("Throw again, or bank?" if bank else "Throw how many dice?", opts)
			await _settle(6)
			main._layout_buttons()
			await process_frame
			await _check("synthetic %d dice%s" % [n, " + Bank" if bank else ""])
	var f := FileAccess.open(out.path_join("audit.txt"), FileAccess.WRITE)
	f.store_string("\n".join(report))
	print("\n".join(report))
	quit()


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame
	if main._dir:
		main._dir._stop_pulses()
	for b in _all_buttons(main):
		b.scale = Vector2.ONE
	await process_frame


func _prompt_buttons() -> Array:
	if main._buttons == null:
		return []
	return main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion() and b.visible)


func _all_buttons(n: Node) -> Array:
	var r := []
	for c in n.get_children():
		if c is BaseButton and c.is_visible_in_tree() and not c.is_queued_for_deletion() and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			r.append(c)
		r.append_array(_all_buttons(c))
	return r


func _name(b: Control) -> String:
	var t: String = b.text if b is Button and b.text != "" else ""
	if t == "":
		var r := b.find_children("*", "RichTextLabel", true, false)
		t = r[0].get_parsed_text() if not r.is_empty() else ""
	if t == "":
		var l := b.find_children("*", "Label", true, false)
		t = l[0].text if not l.is_empty() else str(b.get_meta("kind", b.name))
	return "\"%s\"" % t.replace("\n", " ").strip_edges().left(24)


func _check(screen: String) -> void:
	var path := out.path_join("%02d.png" % (report.filter(func(s): return s.begins_with("## ")).size()))
	root.get_viewport().get_texture().get_image().save_png(path)
	report.append("## %s  (%s)" % [screen, path.get_file()])
	var vp := root.get_viewport().get_visible_rect().size
	var bs := _all_buttons(main)
	# The Chronicle covers the board: only its own buttons count while it's open.
	if main._log_overlay and main._log_overlay.visible:
		bs = _all_buttons(main._log_overlay)
	var n := 0
	for i in bs.size():
		var a: Control = bs[i]
		var ra := a.get_global_rect()
		var nm := _name(a)
		if ra.size.x < MIN_TARGET - 0.5 or ra.size.y < MIN_TARGET - 0.5:
			report.append("- target %s is %.0fx%.0f pt (min 44)" % [nm, ra.size.x / PT, ra.size.y / PT]); n += 1
		if ra.position.y < SAFE.x - 0.5 or ra.end.y > vp.y - SAFE.y + 0.5:
			report.append("- safe area: %s spans y %.0f-%.0f pt (allowed %.0f-%.0f)" % [nm, ra.position.y / PT, ra.end.y / PT, SAFE.x / PT, (vp.y - SAFE.y) / PT]); n += 1
		if ra.position.x < SIDE - 0.5 or ra.end.x > vp.x - SIDE + 0.5:
			report.append("- side margin: %s spans x %.0f-%.0f pt (allowed 16-%.0f)" % [nm, ra.position.x / PT, ra.end.x / PT, (vp.x - SIDE) / PT]); n += 1
		for j in range(i + 1, bs.size()):
			var b: Control = bs[j]
			if a.is_ancestor_of(b) or b.is_ancestor_of(a):
				continue
			var rb := b.get_global_rect()
			if ra.intersects(rb):
				var x := ra.intersection(rb)
				report.append("- OVERLAP %s and %s by %.0fx%.0f pt" % [nm, _name(b), x.size.x / PT, x.size.y / PT]); n += 1
			else:
				var dx := maxf(0.0, maxf(ra.position.x - rb.end.x, rb.position.x - ra.end.x))
				var dy := maxf(0.0, maxf(ra.position.y - rb.end.y, rb.position.y - ra.end.y))
				var gap := sqrt(dx * dx + dy * dy)
				if gap < MIN_GAP - 0.5:
					report.append("- gap %s to %s is %.1f pt (min 12)" % [nm, _name(b), gap / PT]); n += 1
	if n == 0:
		report.append("- ok (%d targets)" % bs.size())
