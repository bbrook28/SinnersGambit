## A scripted tour of the whole game for a video: menu, Settings, rulebook, the tutorial, the Sin
## carousel, then a full game at 1x as Envy (a simple player: throw, take every ability, bank at
## 150 or on two Strikes, buy when offered) with a look at the pause menu, an explanation, the
## Chronicle and the bot-turn summary, through to the win. Saves a still at each moment worth
## describing (<out_dir>/shots/NN_name.jpg).
## Record with Movie Maker (windowed):
## godot --path . --resolution 720x1560 --fixed-fps 30 --write-movie <out_dir>/tour.avi --script res://tools/tour.gd -- <out_dir>
extends SceneTree

const GAME_CAP := 330.0     # game seconds at 1x before the rest of the game is sped up
const PROMPT_THINK := 1.4   # the player looks at each prompt this long before answering

var main
var out := ""
var shots := {}
var shot_n := 0
var game_time := 0.0  # game seconds since the game started (Movie Maker time, not the wall clock)
var in_game := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(out.path_join("shots"))
	_run()


func _wait(s: float) -> void:
	await create_timer(s).timeout


func _new_main() -> void:
	if main and is_instance_valid(main):
		main.queue_free()
		await process_frame
	main = load("res://ui/main.tscn").instantiate()
	main.save_enabled = false
	main.tutorial_enabled = false
	main.first_game_enabled = false
	root.add_child(main)


func shot(name: String) -> void:
	if shots.has(name):
		return
	shots[name] = true
	shot_n += 1
	var img := root.get_viewport().get_texture().get_image()
	img.save_jpg(out.path_join("shots/%02d_%s.jpg" % [shot_n, name]), 0.85)
	print("SHOT %02d %s" % [shot_n, name])


func _close_overlay() -> void:
	if main._overlay and is_instance_valid(main._overlay):
		main._overlay.queue_free()
	main._overlay = null
	main._q.set_paused(false)


func _run() -> void:
	await _new_main()
	main.Tuning.table_size = 4
	main.Tuning.speed = 1.0
	# 1. Title page.
	await _wait(5.0)
	shot("menu")
	# 2. Settings.
	main._open_settings()
	await _wait(3.0)
	shot("settings")
	main._settings.queue_free()
	main._settings = null
	await _wait(0.6)
	# 3. Rulebook.
	main.open_rulebook("contents")
	for id in ["contents", "scoring", "strikes", "purgatory", "all_sins", "glossary"]:
		var i: int = main.RulesText.page_index(id)
		if i < 0:
			continue
		main._overlay.show_page(i)
		await _wait(2.6)
		shot("rulebook_" + id)
	_close_overlay()
	await _wait(0.8)
	# 4. The tutorial, start to finish.
	main.start_tutorial(false)
	await _tutorial()
	# 5. Sin select.
	await _new_main()
	await _wait(1.0)
	await main._open_setup()
	await _wait(2.5)
	shot("select_sloth")
	var car = main._content.find_children("*", "VBoxContainer", true, false).filter(func(c): return c.has_method("go_to"))[0]
	for i in 7:
		car.go_to(i)
		await _wait(2.4)
		if i == 0:
			shot("select_wrath")
		if i == 3:
			shot("select_envy")
	await _wait(1.0)
	# 6. A game as Envy at a table of 4.
	main._start(main.SIN_SCRIPTS[3])
	in_game = true
	game_time = 0.0
	await _play()
	in_game = false
	await _wait(6.0)
	shot("win")
	print("TOUR DONE")
	quit()


func _tutorial() -> void:
	var pressed_at := -1
	var guard := 0.0
	while guard < 400.0:
		await process_frame
		guard += 1.0 / 30.0
		var t = main._tutor
		if t == null:
			return
		var ov = t.overlay
		var i: int = t.index - 1
		if ov.mode == ov.READ and ov._choices.visible:
			await _wait(3.0)
			shot("tutorial_end")
			return
		if ov.mode == ov.READ and ov._ready_for_tap:
			await _wait(2.4)
			if i in [0, 2, 4, 7, 10, 12, 14]:
				shot("tutorial_%02d" % i)
			ov.advance()
		elif ov.mode == ov.ACT and pressed_at != i:
			await _wait(1.6)
			var live: Array = main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion() and not b.disabled)
			if live.is_empty():
				continue
			if i in [1, 5, 6, 9]:
				shot("tutorial_%02d_act" % i)
			pressed_at = i
			live[0].pressed.emit()


func _prompt_buttons() -> Array:
	if main._buttons == null:
		return []
	return main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion() and b.visible and not b.disabled)


func _play() -> void:
	var prompts := 0
	while true:
		await process_frame
		var bs := _prompt_buttons()
		if bs.is_empty() or main._q.busy():
			continue
		await _wait(PROMPT_THINK)
		bs = _prompt_buttons()
		if bs.is_empty() or main._q.busy():
			continue
		prompts += 1
		if str(bs[0].get_meta("value", "")) == "new":
			shot("game_over_prompt")
			return
		if game_time > GAME_CAP and main.Tuning.speed < 2.0:
			main.Tuning.speed = 3.0  # the rest of the game, quicker
		var kinds := bs.map(func(b): return b.get_meta("kind", "?"))
		if "roll" in kinds:
			shot("prompt_throw" if not "bank" in kinds else "prompt_throw_or_bank")
		elif main._prompt_label.get_parsed_text().begins_with("Buy"):
			shot("prompt_buy")
		else:
			shot("prompt_ability")
		# A look round the menus, once each.
		if prompts == 3:
			main._open_pause()
			await _wait(3.0)
			shot("pause_menu")
			_close_overlay()
			await _wait(0.8)
		if prompts == 5:
			main._explain_sin(main.game.players.find(main.human_player()))
			await _wait(3.5)
			shot("explain_your_sin")
			_close_overlay()
			await _wait(0.8)
		if prompts == 8:
			main._log_overlay.visible = true
			await _wait(3.5)
			shot("chronicle")
			main._log_overlay.visible = false
			await _wait(0.8)
		_answer(bs, kinds)


func _answer(bs: Array, kinds: Array) -> void:
	var t = main.game.turn
	var pts: int = t.points if t else 0
	var strikes: int = t.strikes if t else 0
	if "bank" in kinds:
		var bank = bs[kinds.find("bank")]
		if pts >= 150 or (strikes >= 2 and pts > 0):
			bank.pressed.emit()
			return
	if "roll" in kinds:
		bs[kinds.find("roll")].pressed.emit()
		return
	bs[0].pressed.emit()  # abilities: yes; buy: the first offer; a target: the first


## Stills of moments that come and go during play.
func _process(d: float) -> bool:
	game_time += d
	if not in_game or main == null or not is_instance_valid(main) or main._throw_label == null:
		return false
	var tl: String = main._throw_label.text
	if tl.contains("x") and tl.begins_with("+"):
		shot("score_multiplier")
	elif tl.begins_with("+") and main._throw_label.modulate.a > 0.9:
		shot("score_total")
	if main._result_label.text == main.RulesText.word("res_bust"):
		shot("bust")
	for die in main._dice_nodes:
		if is_instance_valid(die) and die.tint.a > 0.0 and die.height == 0.0:
			shot("added_dice_tinted")
			break
	if not main._notes.is_empty():
		shot("ability_note")
	if main._summary != null and main._summary.visible and main._summary_rows.get_child_count() >= 2:
		shot("bot_summary")
	if main._dir and main._dir.fx.get_child_count() > 6:
		shot("vfx_busy")
	return false
