## Renders every fixture (tools/fixtures/) at the three phone sizes (tools/fixture.gd SIZES), one
## tools/show.gd process each, PARALLEL at a time, into build/gallery/<size>/<fixture>.png, plus one
## labelled contact sheet per size (build/gallery/sheet_<size>.png).
##
##   godot --path . --script res://tools/gallery.gd [-- options]
##     --only a,b,c     just these fixtures (default: all)
##     --sizes se,std   just these sizes (default: all three)
##     --check          compare each render with tests/golden/<size>/<fixture>.png; one line per
##                      fixture that changed (with the share of pixels different), and
##                      build/gallery/changed.png: changed fixtures, reference beside render
##     --packet <topic> --check, then start Docs/review/latest/ for that topic (the old packet goes
##                      to Docs/review/archive/<date>-<topic>/) with the changed sheet as sheet.png;
##                      packet.md is written by hand
##     --approve <fixture>  copy its renders (every size) over the references. Only when Ben says.
##     --no-render      use the renders already in build/gallery
##     --against <dir>  compare with <dir>/<size>/<fixture>.png instead of the references (a
##                      before snapshot, or a determinism check)
## Working rule (Ben): text audit first (tools/ui_audit.gd -- fixtures), then --check, then open only
## the images that changed.
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")
const OUT := "res://build/gallery/"
const GOLDEN := "res://tests/golden/"
const PARALLEL := 6
const THRESH := 10.0 / 255.0   # a channel off by more than this counts as a changed pixel
const REPORT_MIN := 0.05       # % changed under which a fixture counts as unchanged (noise)
const THUMB := 300             # px wide per render on a sheet
const SHEET_MAX := 1980        # px, sheets stay under 2000 wide


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var only: Array = Fixture.names()
	var sizes: Array = Fixture.ORDER.duplicate()
	var check := false
	var render := true
	var topic := ""
	var approve := ""
	var i := 0
	while i < a.size():
		match a[i]:
			"--only":
				i += 1; only = Array(a[i].split(","))
			"--sizes":
				i += 1; sizes = Array(a[i].split(","))
			"--check":
				check = true
			"--packet":
				i += 1; topic = a[i]; check = true
			"--approve":
				i += 1; approve = a[i]
			"--no-render":
				render = false
			"--against":
				i += 1; against = a[i]; check = true
		i += 1
	if approve != "":
		_approve(approve, sizes)
		quit()
		return
	if render:
		await _render(only, sizes)
	for s in sizes:
		await _sheet(s, only.map(func(n): return [n, _out(s, n), ""]), ProjectSettings.globalize_path(OUT + "sheet_%s.png" % s))
	if check:
		var changed := _check(only, sizes)
		if not changed.is_empty():
			await _sheet("changed", changed, ProjectSettings.globalize_path(OUT + "changed.png"))
		if topic != "":
			_packet(topic, not changed.is_empty())
	quit()


func _out(size: String, name: String) -> String:
	return ProjectSettings.globalize_path(OUT + "%s/%s.png" % [size, name])


var against := ""


func _golden(size: String, name: String) -> String:
	if against != "":
		return against.path_join("%s/%s.png" % [size, name])
	return ProjectSettings.globalize_path(GOLDEN + "%s/%s.png" % [size, name])


## One tools/show.gd per fixture and size, PARALLEL at once.
func _render(names: Array, sizes: Array) -> void:
	var jobs := []
	for s in sizes:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + s))
		for n in names:
			jobs.append([n, s])
	var exe := OS.get_executable_path()
	var running := {}
	var t0 := Time.get_ticks_msec()
	while not jobs.is_empty() or not running.is_empty():
		while running.size() < PARALLEL and not jobs.is_empty():
			var j: Array = jobs.pop_front()
			var pid := OS.create_process(exe, ["--path", ProjectSettings.globalize_path("res://"), "--fixed-fps", "60",
				"--script", "res://tools/show.gd", "--", j[0], j[1], _out(j[1], j[0])])
			running[pid] = j
		await create_timer(0.25).timeout
		for pid in running.keys():
			if not OS.is_process_running(pid):
				var j: Array = running[pid]
				running.erase(pid)
				if not FileAccess.file_exists(_out(j[1], j[0])):
					print("FAILED %s %s" % [j[0], j[1]])
	print("rendered %d in %.0f s" % [names.size() * sizes.size(), (Time.get_ticks_msec() - t0) / 1000.0])


## Changed fixtures as sheet rows [label, after, before].
func _check(names: Array, sizes: Array) -> Array:
	var changed := []
	var lines := []
	for n in names:
		for s in sizes:
			var g := _golden(s, n)
			var r := _out(s, n)
			if not FileAccess.file_exists(r):
				lines.append("%s %s: no render" % [n, s])
				continue
			if not FileAccess.file_exists(g):
				lines.append("%s %s: new (no reference)" % [n, s])
				changed.append(["%s %s (new)" % [n, s], r, ""])
				continue
			var pct := _diff(Image.load_from_file(g), Image.load_from_file(r))
			if pct >= REPORT_MIN:
				lines.append("%s %s: %.2f%% of pixels changed" % [n, s, pct])
				changed.append(["%s %s %.1f%%" % [n, s, pct], r, g])
	print("CHECK: %d of %d changed" % [changed.size(), names.size() * sizes.size()])
	for l in lines:
		print("  " + l)
	var f := FileAccess.open(ProjectSettings.globalize_path(OUT + "changed.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	return changed


func _diff(a: Image, b: Image) -> float:
	if a.get_size() != b.get_size():
		return 100.0
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	var da := a.get_data()
	var db := b.get_data()
	if da == db:
		return 0.0  # identical: skip the per-pixel pass
	var lim := int(THRESH * 255.0)
	var n := 0
	var px := da.size() / 4
	for i in px:
		var k := i * 4
		if absi(da[k] - db[k]) > lim or absi(da[k + 1] - db[k + 1]) > lim or absi(da[k + 2] - db[k + 2]) > lim:
			n += 1
	return 100.0 * n / maxf(1.0, px)


func _approve(name: String, sizes: Array) -> void:
	for s in sizes:
		var r := _out(s, name)
		if not FileAccess.file_exists(r):
			print("no render for %s %s: run the gallery first" % [name, s])
			continue
		DirAccess.make_dir_recursive_absolute(_golden(s, name).get_base_dir())
		DirAccess.copy_absolute(r, _golden(s, name))
		print("approved %s %s" % [name, s])


## A labelled grid: each row is [label, image, before image or ""]; a before sits left of its after.
## Drawn by the renderer (a SubViewport) so the labels are real text. Under SHEET_MAX wide.
func _sheet(title: String, rows: Array, path: String) -> void:
	var pairs := rows.any(func(r): return r[2] != "")
	var cell := THUMB * (2 if pairs else 1) + 20
	var cols := maxi(1, SHEET_MAX / cell)
	var thumb_h := 0
	var ims := []
	for r in rows:
		var im := Image.load_from_file(r[1]) if FileAccess.file_exists(r[1]) else null
		var before := Image.load_from_file(r[2]) if r[2] != "" and FileAccess.file_exists(r[2]) else null
		ims.append([r[0], im, before])
		if im:
			thumb_h = maxi(thumb_h, roundi(THUMB * float(im.get_height()) / im.get_width()))
	var row_h := thumb_h + 44
	var vp := SubViewport.new()
	vp.size = Vector2i(mini(SHEET_MAX, cols * cell), ceili(ims.size() / float(cols)) * row_h + 10)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.13)
	bg.size = Vector2(vp.size)
	vp.add_child(bg)
	for i in ims.size():
		var e: Array = ims[i]
		var at := Vector2((i % cols) * cell + 10, (i / cols) * row_h + 6)
		var x := at.x
		for im in [e[2], e[1]]:
			if im == null:
				if pairs and e[2] == null and im == e[2]:
					x += THUMB  # no reference: leave its place empty
				continue
			var tr := TextureRect.new()
			tr.texture = ImageTexture.create_from_image(im)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			tr.position = Vector2(x, at.y + 34)
			tr.size = Vector2(THUMB, thumb_h)
			vp.add_child(tr)
			x += THUMB
		var l := Label.new()
		l.text = e[0] + ("   (before | after)" if e[2] != null else "")
		l.position = at
		l.add_theme_font_size_override("font_size", 20)
		l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
		vp.add_child(l)
	for k in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(path)
	vp.queue_free()
	print("sheet %s: %d -> %s" % [title, ims.size(), path])


## Docs/review/latest/ for a new piece of work: the old packet is archived first.
func _packet(topic: String, has_changes: bool) -> void:
	var latest := ProjectSettings.globalize_path("res://Docs/review/latest/")
	var arch := ProjectSettings.globalize_path("res://Docs/review/archive/")
	if DirAccess.dir_exists_absolute(latest):
		var old_topic := "packet"
		var md := FileAccess.get_file_as_string(latest + "packet.md")
		if md.begins_with("# "):
			old_topic = md.get_slice("\n", 0).trim_prefix("# ").strip_edges().to_lower().replace(" ", "-").left(40)
		var dest := arch + "%s-%s/" % [Time.get_date_string_from_system(), old_topic]
		DirAccess.make_dir_recursive_absolute(dest)
		for f in DirAccess.get_files_at(latest):
			DirAccess.rename_absolute(latest + f, dest + f)
	DirAccess.make_dir_recursive_absolute(latest)
	if has_changes:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(OUT + "changed.png"), latest + "sheet.png")
	DirAccess.copy_absolute(ProjectSettings.globalize_path(OUT + "changed.txt"), latest + "changed.txt")
	print("packet started: %s (write %spacket.md)" % [topic, latest])
