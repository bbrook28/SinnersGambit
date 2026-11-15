## Before/after stills for shader changes: the title screen, the board at a Throw-or-Bank prompt
## (Strike candles, gold numerals, the banner) and the bronze Bank seal close up. Fixed seed.
## godot --path . --resolution 1080x1920 --script res://tools/screens_shot.gd -- <out_dir>
extends SceneTree

var out := "user://shots"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else out
	DirAccess.make_dir_recursive_absolute(out)
	seed(7)
	await process_frame
	var main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	main.save_enabled = false
	main.tutorial_enabled = false
	main.first_game_enabled = false
	await create_timer(2.0).timeout
	await _shot("title")
	main._start(main.SIN_SCRIPTS[0])
	Engine.time_scale = 6.0
	var frames := 0
	while frames < 20000:
		await process_frame
		frames += 1
		if main._buttons == null:
			continue
		var bs: Array = main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion())
		var bank: Array = bs.filter(func(b): return b.get_meta("kind", "") == "bank" and not b.has_meta("offer"))
		if not bank.is_empty() and main.game and main.game.turn and main.game.turn.strikes > 0:
			Engine.time_scale = 1.0
			await create_timer(1.5).timeout
			var img: Image = await _shot("board")
			var r := Rect2i(bank[0].get_global_rect().grow(30))
			img.get_region(r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))).save_png("%s/seal.png" % out)
			break
		if bs.is_empty():
			continue
		var acc: Array = bs.filter(func(b): return b.get_meta("offer", "") == "refuse" or b.get_meta("kind", "") == "roll")
		(acc[0] if not acc.is_empty() else bs[randi() % bs.size()]).pressed.emit()
	print("SCREENS: %s" % out)
	quit()


func _shot(name: String) -> Image:
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	return img
