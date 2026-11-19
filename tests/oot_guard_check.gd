## REPLY 41 item 3: the 0.6 s tap guard on a bet's slip. Plays a table game through the real UI until the first
## bet is offered (a rival's fall at its turn start), then, timed from the moment the slip starts to rise:
##   (A) double taps at the Throw spot (where Take sits) from 0 to 0.6 s, a press begun at 0.5 s and held past
##       the guard, and background taps throughout: no bet is placed and my score is unchanged;
##   (B) one tap at 0.75 s takes the bet.
## With -- --noguard the slip answers at once (TableBlockout.guard_on off): (A) must then fail.
## godot --headless --path . --script res://tests/oot_guard_check.gd -- --table [--noguard]
extends SceneTree

const Tuning = preload("res://ui/tuning.gd")
const TableBlockout = preload("res://ui/table_blockout.gd")
const BG := Vector2(540, 300)  # a background point: the windows, no button

var main
var answers: Array = []
var testing := false
var done := false
var waited := 0.0


func _initialize() -> void:
	if not Tuning.table_view():
		print("OOT GUARD FAILED: run with -- --table")
		quit()
		return
	TableBlockout.guard_on = not OS.get_cmdline_user_args().has("--noguard")
	Engine.time_scale = 1.0
	await process_frame
	main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	Tuning.speed = 4.0  # the bots' beats fly by; the guard is real time at any speed
	main.save_enabled = false
	main.tutorial_enabled = false
	main.first_game_enabled = false
	main.games_finished = 1
	seed(3)
	main._start(main.SIN_SCRIPTS[2])


func _tap(at: Vector2, down: bool) -> void:
	var m := InputEventMouseButton.new()
	m.position = root.get_final_transform() * at
	m.global_position = m.position
	m.button_index = MOUSE_BUTTON_LEFT
	m.pressed = down
	Input.parse_input_event(m)


## Waits until the slip has been up `t` seconds (TableBlockout._clock from its start).
func _until(t: float) -> void:
	while TableBlockout._clock - main._table._slip_start < t:
		await process_frame


func _check() -> void:
	testing = true
	var t: Node = main._table
	var take: Button = t.view.slip_buttons[1]
	var at: Vector2 = take.get_global_rect().get_center()
	var me = main.human_player()
	var score0: int = me.score
	answers.clear()
	main.human.answered.connect(func(v): answers.append(v))
	# (A) double taps at the Throw spot, 0 to 0.6 s; background taps between; a press held across the guard.
	var downs := []
	for t0 in [0.0, 0.12, 0.24, 0.36, 0.48]:
		await _until(t0)
		for k in 2:
			downs.append(TableBlockout._clock - t._slip_start)
			_tap(at, true)
			await process_frame
			_tap(at, false)
			await process_frame
			_tap(BG, true)
			await process_frame
			_tap(BG, false)
			await create_timer(0.03).timeout
	await _until(0.55)
	downs.append(TableBlockout._clock - t._slip_start)
	_tap(at, true)  # begun before the ring fills: released after it, it never answers
	await _until(0.8)
	_tap(at, false)
	print("  presses at the Throw spot began at %s s (the last held to 0.8 s)" % ", ".join(downs.map(func(d): return "%.2f" % d)))
	await process_frame
	var a_ok: bool = answers.is_empty() and me.score == score0 and not main.game._bets.has("fall")
	print("  (A) taps 0-0.6 s after the slip starts to rise: %s (answers %s, score %d -> %d)" % ["no bet" if a_ok else "BET PLACED", str(answers), score0, me.score])
	# (B) a single tap at 0.75 s or later takes it.
	await _until(0.9)
	_tap(at, true)
	await process_frame
	_tap(at, false)
	for i in 10:
		await process_frame
	var b_ok: bool = answers == [true] and int(main.game._bets.get("fall", 0)) == 50
	print("  (B) one tap after the guard: %s (answers %s)" % ["bet taken" if b_ok else "NOT TAKEN", str(answers)])
	print("OOT GUARD %s (guard %s)" % ["PASSED" if a_ok and b_ok else "FAILED", "on" if TableBlockout.guard_on else "off"])
	done = true
	quit()


func _process(delta: float) -> bool:
	if main == null or main.game == null or testing or done:
		return false
	if main._table and not main._table._bet.is_empty():
		_check()
		return false
	var bs: Array = main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion() and not b.disabled)
	if bs.is_empty() or main._q.busy():
		waited = 0.0
		return false
	waited += delta
	if waited < 0.3:
		return false
	waited = 0.0
	for b in bs:  # my turn: bank as soon as I can, else throw
		if str(b.get_meta("kind", "")) == "bank":
			b.pressed.emit()
			return false
	bs[0].pressed.emit()
	if main.game.round_count > 6:
		print("OOT GUARD FAILED: no bet offered by round 6")
		quit()
	return false
