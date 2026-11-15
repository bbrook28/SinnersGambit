## A short recording of a Sin's temptation: the offer arrives, the portrait makes its gesture, then
## breathes at rest. Run under Movie Maker; the offer opens 2 s in and the run ends 8 s later.
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
	main._show_offer_now("", [["Accept", true], ["Refuse", false]], {
		"sin": s, "text": "A free die. Start next turn with a Strike.", "tip": "",
		"context": "This turn 20 · 1 Strike · You 20 · Leader 690"})
	await create_timer(8.0).timeout
	quit()
