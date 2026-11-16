## Blockout 4: plays full games on the table layout (ui/table_play.gd), answering through the table's
## own Bank and Throw seals and its choice buttons; main's buttons only where the table steps aside
## (a temptation offer). One game per Sin, under Rules.V5: when my seal glows it is pressed most of the
## time, else the dice are tapped to let the throw stand. Windowed, it also saves a frame at the first few decisions,
## rivals' turns and busts to build/table_play/.
## godot --headless --path . --script res://tests/table_play_check.gd -- --table
extends SceneTree

const SIN_COUNT := 7
const Tuning = preload("res://ui/tuning.gd")

var main
var sin_i := 0
var games_done := 0
var via_table := 0
var offer_frames := 0  # REPLY 16: frames the offer card screen is up
var offer_beats := 0   # frames the table shows the Master's offer beat
var mark_frames := 0   # frames the table shows his mark pose
var via_main := 0
var shots := {}
var _wait := 0
var _stuck := 0
var seals := 0
var stands := 0


func _initialize() -> void:
	if not Tuning.table_view():
		push_error("run with -- --table")
		quit(1)
		return
	Engine.time_scale = 50.0 if DisplayServer.get_name() == "headless" else 8.0
	DirAccess.make_dir_recursive_absolute("res://build/table_play")
	await process_frame
	_next()


func _next() -> void:
	if main:
		main.queue_free()
	if sin_i >= SIN_COUNT:
		if offer_frames > 0 and offer_beats == 0:
			push_error("TABLE PLAY: offers came (%d frames) but the Master's offer beat never showed" % offer_frames)
			quit(1)
			return
		if mark_frames == 0:
			push_error("TABLE PLAY: the Master never showed his mark")
			quit(1)
			return
		if seals == 0 or stands == 0:
			push_error("TABLE PLAY: my power never used (%d) or never let stand (%d)" % [seals, stands])
			quit(1)
			return
		print("TABLE PLAY PASSED: %d V5 games, %d answers on the table (%d seals, %d let stand), %d on main's screens; offer beat %d frames, mark %d frames" % [games_done, via_table, seals, stands, via_main, offer_beats, mark_frames])
		quit()
		return
	main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	main.save_enabled = false
	main.tutorial_enabled = false
	main.first_game_enabled = false
	Tuning.table_size = Tuning.TABLE_SIZES[sin_i % Tuning.TABLE_SIZES.size()]
	main._start(main.SIN_SCRIPTS[sin_i])
	sin_i += 1


func _shot(kind: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var n: int = shots.get(kind, 0)
	if n >= 3:
		return
	shots[kind] = n + 1
	root.get_viewport().get_texture().get_image().save_png("res://build/table_play/%s_%d.png" % [kind, n])


func _process(_delta: float) -> bool:
	if main == null or main._buttons == null:
		return false
	var t = main._table
	if t and t.showing() and t.view.moment in ["rival", "bust"] and (t.view.moment == "bust" or t.view.points > 0):
		_shot(t.view.moment)
	if t and t.showing() and t.view.master_pose == "offer":
		offer_beats += 1
		_shot("offer_beat")
	if t and t.showing() and t.view.master_pose == "mark":
		mark_frames += 1
		_shot("mark")
	if is_instance_valid(main._offer_card):
		offer_frames += 1
	var bs: Array = main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion())
	if bs.is_empty():
		return false
	if str(bs[0].get_meta("value", "")) == "new":
		games_done += 1
		if not main.game.opt("v5", false):
			push_error("TABLE PLAY: the table game is not Rules.V5")
			quit(1)
		print("%s: %s" % [main.human.label, main._prompt_label.get_parsed_text()])
		_next()
		return false
	_wait += 1
	if _wait < 3:  # let the table catch up with the prompt
		return false
	_wait = 0
	if t and t.showing():
		if t.view.moment == "decision":
			_shot("decision")
			via_table += 1
			_stuck = 0
			if t.view.seal == "ready" and (not t.view.stand_live or randf() < 0.7):
				seals += 1
				t.view.seal_pressed.emit()
				return false
			if t.view.stand_live:
				stands += 1
				t.view.stand_pressed.emit()
				return false
			if t.view.can_bank and (not t.view.can_throw or randf() < 0.35):
				t.view.bank_pressed.emit()
			else:
				t.view.throw_pressed.emit()
			return false
		if is_instance_valid(t._extra):
			var picks: Array = t._extra.get_children().filter(func(c): return c is Button)
			if not picks.is_empty():
				_shot("choice")
				via_table += 1
				_stuck = 0
				picks[randi() % picks.size()].pressed.emit()
				return false
		_stuck += 1
		if _stuck > 300:  # a prompt the table offers no answer to
			push_error("STUCK: '%s' kinds %s moment %s" % [main._prompt_label.get_parsed_text(), str(bs.map(func(b): return b.get_meta("kind", "?"))), t.view.moment])
			quit(1)
		return false
	_stuck = 0
	via_main += 1
	bs[randi() % bs.size()].pressed.emit()
	return false
