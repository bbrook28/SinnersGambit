## Times bot turns in the real UI at speed 1x: from one turn-change beat to the next.
## Target: every bot turn in 4 s or less on average, and your turn back within about 15 s at a table of 4.
## godot --headless --path . --script res://tests/bot_pace.gd [-- <table size>]
extends SceneTree

const Tuning = preload("res://ui/tuning.gd")
const TIME_SCALE := 4.0    # game time runs 4x; all timings below are game time (= seconds at 1x)
const BOT_TURNS := 40

var main
var games := 0
var t := 0.0               # game time since the current turn's banner
var cur_mine := false
var started := false
var bot_times: Array[float] = []
var waits: Array[float] = []   # from your turn ending to your next turn's banner
var wait_acc := 0.0
var in_wait := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	Tuning.table_size = int(args[0]) if args.size() > 0 else 4
	Tuning.speed = 1.0
	Engine.time_scale = TIME_SCALE
	await process_frame
	_next()


func _next() -> void:
	if main:
		main.queue_free()
	main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	main.save_enabled = false
	main.tutorial_enabled = false
	main._dir.turn_shown.connect(_on_turn)
	started = false
	main._start(main.SIN_SCRIPTS[6 - games % 7])
	games += 1


func _on_turn(_seat: int, mine: bool) -> void:
	if started:
		if not cur_mine:
			bot_times.append(t)
			wait_acc += t
		if mine and in_wait:
			waits.append(wait_acc)
		if cur_mine and not mine:
			in_wait = true
			wait_acc = 0.0
		if mine:
			in_wait = false
	started = true
	cur_mine = mine
	t = 0.0
	if bot_times.size() >= BOT_TURNS:
		_report()


func _report() -> void:
	var s := bot_times.duplicate()
	s.sort()
	var avg := 0.0
	for x in s:
		avg += x
	avg /= s.size()
	var w_avg := 0.0
	for x in waits:
		w_avg += x
	w_avg /= maxf(1.0, waits.size())
	print("Table of %d, %d bot turns at 1x: avg %.1f s, median %.1f s, 90th pct %.1f s, max %.1f s" % [
		Tuning.table_size, s.size(), avg, s[s.size() / 2], s[int(s.size() * 0.9)], s[-1]])
	print("Your turn back after: avg %.1f s over %d waits" % [w_avg, waits.size()])
	print("PACE %s" % ("PASSED" if avg <= 4.0 else "SLOW"))
	quit()


func _process(delta: float) -> bool:
	t += delta
	if main == null or main._buttons == null:
		return false
	var bs: Array = main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion())
	if bs.is_empty() or main._q.busy():
		return false
	if bs[0].text == "New game":
		_next()
		return false
	bs[randi() % bs.size()].pressed.emit()
	return false
