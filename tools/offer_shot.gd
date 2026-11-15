## The temptation screen for chosen Sins, shot at rest (after the arrival flare), each saved full
## screen and as a pair: the raw runtime PNG beside the window as drawn in game. Windowed:
## godot --path . --resolution 1080x1920 --script res://tools/offer_shot.gd -- <out_dir> Gluttony Lust
extends SceneTree

var out := "user://shots"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else out
	DirAccess.make_dir_recursive_absolute(out)
	var sins: Array = Array(args.slice(1)).filter(func(a): return not "=" in a)
	if sins.is_empty():
		sins = ["Gluttony", "Lust"]
	# Diagnosis: shader=off draws the window plain; param=value sets a flare uniform on it.
	var sets: Array = Array(args.slice(1)).filter(func(a): return "=" in a)
	await process_frame
	var main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_enabled = false
	main.tutorial_enabled = false
	main.first_game_enabled = false
	main._start(main.SIN_SCRIPTS[0])
	await _wait(90)
	for s in sins:
		main._show_offer_now("", [["Accept", true], ["Refuse", false]], {
			"sin": s, "text": "A free die. Start next turn with a Strike.", "tip": "",
			"context": "This turn 20 · 1 Strike · You 20 · Leader 690"})
		await _wait(5)
		main._offer_card.get_meta("place").call()
		await create_timer(1.6).timeout  # the arrival flare is over
		var w0: TextureRect = _find_window(main._offer_card)
		for kv in sets:
			var k: String = kv.get_slice("=", 0)
			if k == "shader":
				w0.material = null
			else:
				w0.material.set_shader_parameter(k, float(kv.get_slice("=", 1)))
		await _wait(3)
		await RenderingServer.frame_post_draw
		var shot: Image = root.get_texture().get_image()
		shot.save_png("%s/%s_screen.png" % [out, s.to_lower()])
		var win: TextureRect = _find_window(main._offer_card)
		var r := Rect2i(win.get_global_rect())
		var drawn := shot.get_region(r)
		var raw: Image = win.texture.get_image()
		raw.decompress()
		raw.convert(Image.FORMAT_RGBA8)
		raw.resize(roundi(raw.get_width() * float(r.size.y) / raw.get_height()), r.size.y, Image.INTERPOLATE_LANCZOS)
		var pair := Image.create(raw.get_width() + drawn.get_width() + 24, r.size.y, false, Image.FORMAT_RGBA8)
		pair.fill(Color.BLACK)
		pair.blit_rect(raw, Rect2i(Vector2i.ZERO, raw.get_size()), Vector2i.ZERO)
		drawn.convert(Image.FORMAT_RGBA8)
		pair.blit_rect(drawn, Rect2i(Vector2i.ZERO, drawn.get_size()), Vector2i(raw.get_width() + 24, 0))
		pair.save_png("%s/%s_pair%s.png" % [out, s.to_lower(), "_" + "_".join(sets) if sets.size() else ""])
		print("%s: window %s, shader %s" % [s, r, win.material != null])
		main.clear_prompt()
		await _wait(5)
	quit()


func _find_window(n: Node) -> TextureRect:
	for c in n.get_children():
		if c is TextureRect:
			return c
		var f = _find_window(c)
		if f:
			return f
	return null


func _wait(n: int) -> void:
	for i in n:
		await process_frame
