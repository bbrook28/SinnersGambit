## REPLY 35 item 1 (a): one First Game on the table through the real UI (main.tscn), at the saved speed, timed in
## game seconds. Fails when the median bot turn or the whole match is shorter than the floors below (each divided
## by the saved speed). Build 120's "match in 30 s" would fail here. My answers: THINK s after each prompt; throw
## while the stake is under BANK_AT, else bank; any other prompt, its first choice.
## godot --headless --path . --script res://tests/table_pace_check.gd -- --table
extends SceneTree

const Tuning = preload("res://ui/tuning.gd")
const TIME_SCALE := 4.0
const THINK := 1.5
const BANK_AT := 250
const SEED := 7
## Floors at 1x (measured 2026-11-17: median bot turn 2.8 s, match 183 s). Raise them when the pacing floor lands.
const BOT_TURN_MIN := 2.0
const MATCH_MIN := 120.0

var main
var t := 0.0
var turn_t := 0.0
var cur_mine := false
var started := false
var bot_turns: Array[float] = []
var waited := 0.0


func _initialize() -> void:
	if not Tuning.table_view():
		print("TABLE PACE FAILED: run with -- --table")
		quit()
		return
	Engine.time_scale = TIME_SCALE
	await process_frame
	main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)  # _ready loads the saved speed
	main.save_enabled = false
	main.tutorial_enabled = false
	main.first_game_enabled = true
	main.games_finished = 0
	main._dir.turn_shown.connect(_on_turn)
	seed(SEED)
	main._start(main.SIN_SCRIPTS[2])


func _on_turn(_seat: int, mine: bool) -> void:
	if started and not cur_mine:
		bot_turns.append(turn_t)
	started = true
	cur_mine = mine
	turn_t = 0.0


func _end() -> void:
	if started and not cur_mine:
		bot_turns.append(turn_t)
	var s := bot_turns.duplicate()
	s.sort()
	var med: float = s[s.size() / 2] if s.size() else 0.0
	var sp: float = Tuning.speed
	var ok: bool = med >= BOT_TURN_MIN / sp and t >= MATCH_MIN / sp
	print("table pace at speed %.2f: match %.1f s (floor %.1f), %d bot turns, median %.1f s (floor %.1f)" % [sp, t, MATCH_MIN / sp, s.size(), med, BOT_TURN_MIN / sp])
	print("TABLE PACE PASSED" if ok else "TABLE PACE FAILED")
	quit()


func _process(delta: float) -> bool:
	t += delta
	turn_t += delta
	if main == null or main.game == null:
		return false
	if t > 3600.0:
		print("TABLE PACE FAILED: no end in an hour")
		quit()
		return false
	var bs: Array = main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion() and not b.disabled)
	if bs.is_empty() or main._q.busy():
		waited = 0.0
		return false
	if str(bs[0].get_meta("value", "")) == "new":
		_end()
		return false
	waited += delta
	if waited < THINK:
		return false
	waited = 0.0
	var pick = bs[0]
	var stake: int = int(main.game.turn.points) if main.game.turn != null and "points" in main.game.turn else 0
	for b in bs:
		var v := str(b.get_meta("value", b.get_meta("kind", "")))
		if v == "roll" and stake < BANK_AT:
			pick = b
		elif v == "bank" and stake >= BANK_AT:
			pick = b
	pick.pressed.emit()
	return false
