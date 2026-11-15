## Screenshots of the table's new pieces (TableDesign §3, §7): a temptation card, a Sin's line at
## its window, and debt chips on a plate. Windowed, phone size:
## godot --path . --resolution 1080x1920 --script res://tools/table_shots.gd -- <out_dir> [table size] [offer Sin]
extends SceneTree

const Tuning = preload("res://ui/tuning.gd")

var out := "user://shots"
var main
var shots := 0
var want := ""  # only shoot an offer from this Sin


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	Tuning.table_size = int(args[1]) if args.size() > 1 else 4
	want = args[2] if args.size() > 2 else ""
	Engine.time_scale = 6.0
	await process_frame
	main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_enabled = false
	main.tutorial_enabled = false
	main.first_game_enabled = false
	main._start(main.SIN_SCRIPTS[0])
	var offer_shot := false
	var chip_shot := false
	var line_shot := false
	var frames := 0
	while frames < 60000 and not (offer_shot and chip_shot and line_shot):
		await process_frame
		frames += 1
		if not line_shot and main._fx and main._fx.get_children().any(func(c): return c is PanelContainer and c != main._offer_card):
			await _wait(3)
			await _shot("line")
			line_shot = true
		if main._buttons == null:
			continue
		var bs: Array = main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion())
		if bs.is_empty():
			continue
		if bs[0].text == "New game":
			main.queue_free()
			main = load("res://ui/main.tscn").instantiate()
			root.add_child(main)
			await process_frame
			main.save_enabled = false
			main.tutorial_enabled = false
			main.first_game_enabled = false
			main._start(main.SIN_SCRIPTS[frames % 7])
			continue
		var acc: Array = bs.filter(func(b): return b.get_meta("offer", "") == "accept")
		if not acc.is_empty():
			await _wait(30)
			if not offer_shot and is_instance_valid(main._offer_card) and str(main._offer_card.get_meta("sin", "")).begins_with(want):
				await _shot("offer")
				offer_shot = true
			acc[0].pressed.emit()
			continue
		if not chip_shot and main._portraits.any(func(pt): return pt.chips.get_child_count() > 0):
			await _wait(20)
			await _shot("chips")
			chip_shot = true
		bs[randi() % bs.size()].pressed.emit()
	print("SHOTS: %d in %s (offer %s, line %s, chips %s)" % [shots, out, offer_shot, line_shot, chip_shot])
	quit()


func _wait(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
	shots += 1
