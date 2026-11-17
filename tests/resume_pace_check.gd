## REPLY 35 item 1 (c): Continue on the table. Plays a First Game to ANSWERS answers, takes its save (through JSON,
## as on disk), rebuilds it in a fresh main, and once it has caught up (my decision is up and the ink lifted) times
## the next bot turns at the saved speed: their median must reach the table pace floor, and nothing may still be
## skipping. godot --headless --path . --script res://tests/resume_pace_check.gd -- --table
extends SceneTree

const Tuning = preload("res://ui/tuning.gd")
const TablePace = preload("res://tests/table_pace_check.gd")
const ANSWERS := 6
const BOT_TURNS := 4
const TIME_SCALE := 4.0
const THINK := 1.0
const BANK_AT := 250

var b
var caught := false
var started := false
var cur_mine := false
var turn_t := 0.0
var bot_turns: Array[float] = []
var waited := 0.0
var skipping_after := false


func _initialize() -> void:
	if not Tuning.table_view():
		print("RESUME PACE FAILED: run with -- --table")
		quit()
		return
	Engine.time_scale = 40.0
	var a = await _main()
	seed(5)
	a._start(a.SIN_SCRIPTS[2])
	while true:
		await process_frame
		var bs := _buttons(a)
		if bs.is_empty() or a._q.busy():
			continue
		if a.human.record.size() >= ANSWERS or str(bs[0].get_meta("value", "")) == "new":
			break
		_answer(a, bs)
	var saved = JSON.parse_string(JSON.stringify(a._save))
	a.queue_free()
	await process_frame
	b = await _main()
	b._dir.turn_shown.connect(_on_turn)
	b._start(null, saved)
	var frames := 0
	while frames < 20000:
		await process_frame
		frames += 1
		if not _buttons(b).is_empty() and not b._q.busy() and not b._replaying:
			break
	caught = true
	Engine.time_scale = TIME_SCALE
	print("resume: caught up after %d frames at %d answers" % [frames, saved.choices.size()])


func _main():
	var m = load("res://ui/main.tscn").instantiate()
	root.add_child(m)
	m.save_enabled = false
	m.tutorial_enabled = false
	m.first_game_enabled = true
	m.games_finished = 0
	await process_frame
	return m


func _buttons(m) -> Array:
	return m._buttons.get_children().filter(func(x): return not x.is_queued_for_deletion() and not x.disabled)


func _answer(m, bs: Array) -> void:
	var pick = bs[0]
	var stake: int = int(m.game.turn.points) if m.game.turn != null and "points" in m.game.turn else 0
	for x in bs:
		var v := str(x.get_meta("value", x.get_meta("kind", "")))
		if v == "roll" and stake < BANK_AT:
			pick = x
		elif v == "bank" and stake >= BANK_AT:
			pick = x
	pick.pressed.emit()


func _on_turn(_seat: int, mine: bool) -> void:
	if not caught:
		return
	if started and not cur_mine:
		bot_turns.append(turn_t)
		skipping_after = skipping_after or b._q.skip_all
	started = true
	cur_mine = mine
	turn_t = 0.0
	if bot_turns.size() >= BOT_TURNS:
		var s := bot_turns.duplicate()
		s.sort()
		var med: float = s[s.size() / 2]
		var floor_s: float = TablePace.BOT_TURN_MIN / Tuning.speed
		var ok: bool = med >= floor_s and not skipping_after
		print("resume pace at speed %.2f: %d bot turns after catching up, median %.1f s (floor %.1f)%s" % [Tuning.speed, s.size(), med, floor_s, ", still skipping" if skipping_after else ""])
		print("RESUME PACE PASSED" if ok else "RESUME PACE FAILED")
		quit()


func _process(delta: float) -> bool:
	if not caught or b == null or b.game == null:
		return false
	turn_t += delta
	var bs := _buttons(b)
	if bs.is_empty() or b._q.busy():
		waited = 0.0
		return false
	if str(bs[0].get_meta("value", "")) == "new":
		print("RESUME PACE FAILED: the game ended before %d bot turns" % BOT_TURNS)
		quit()
		return false
	waited += delta
	if waited < THINK:
		return false
	waited = 0.0
	_answer(b, bs)
	return false
