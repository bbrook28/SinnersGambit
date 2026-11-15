## A short recording of a Sin's temptation: the offer opens (breathing, the slight idle gesture), then
## Accept is pressed and the portrait reacts; the offer opens again and Refuse is pressed. Run under
## Movie Maker. Accept at 2 + 4 s, the second offer at 10 s, Refuse at 13 s, end at 16 s.
## godot --path . --resolution 1080x1920 --write-movie out.avi --fixed-fps 30 --script res://tools/offer_movie.gd -- Gluttony
extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var s: String = args[0] if args.size() > 0 else "Gluttony"
	await process_frame
	var main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_enabled = false
	main.tutorial_enabled = false
	main.first_game_enabled = false
	main._start(main.SIN_SCRIPTS[0])
	await create_timer(2.0).timeout
	for answer in ["accept", "refuse"]:
		# Wait for the human's own prompt, so the game behind is waiting on us (as for a real offer).
		while main._buttons.get_child_count() == 0 or main._waiting:
			await process_frame
		main._show_offer_now("", [["Accept", true], ["Refuse", false]], {
			"sin": s, "text": "A free die. Start next turn with a Strike.", "tip": "",
			"context": "This turn 20 · 1 Strike · You 20 · Leader 690"})
		await create_timer(4.0 if answer == "accept" else 3.0).timeout
		for b in main._buttons.get_children():
			if b.get_meta("offer", "") == answer:
				b.button_down.emit()
				b.button_up.emit()
				b.pressed.emit()
		await create_timer(3.0).timeout
	quit()
