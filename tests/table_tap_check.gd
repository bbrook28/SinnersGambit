## REPLY 35 item 1 (b): quick taps on the background during the bots' turns. On the table a tap finishes at most
## one beat: a double tap must not skip to my next decision (skip_all stays off, and the bots still take their
## time). Off the table (the old board) a double tap still skips to my decision, as before.
## Plays a First Game; at the start of each bot turn that has another bot turn after it before mine, double taps
## (two taps 0.1 s apart) on a point that is not a button. Three checks, then stops.
## godot --headless --path . --script res://tests/table_tap_check.gd [-- --table]
extends SceneTree

const Tuning = preload("res://ui/tuning.gd")
const THINK := 0.8
const BANK_AT := 200
const CHECKS := 3
const AFTER_MIN := 1.0  # s on the table from the double tap to my next decision: at least this (a skip takes ~0)
const POINTS := [Vector2(540, 1300), Vector2(540, 1000), Vector2(300, 1450), Vector2(780, 1100), Vector2(540, 700)]

var main
var table := false
var waited := 0.0
var tapping := false
var armed := false      # a bot turn started with another bot turn after it before mine
var since_tap := -1.0   # s since the double tap, until my next decision
var results: Array[String] = []
var fails := 0


func _initialize() -> void:
	table = Tuning.table_view()
	Engine.time_scale = 1.0
	await process_frame
	main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	Tuning.speed = 1.0
	main.save_enabled = false
	main.tutorial_enabled = false
	main.first_game_enabled = true
	main.games_finished = 0
	main._dir.turn_shown.connect(_on_turn)
	seed(11)
	main._start(main.SIN_SCRIPTS[2])


func _on_turn(seat: int, mine: bool) -> void:
	if mine or tapping or since_tap >= 0.0 or main.game == null:
		return
	var n: int = main.game.players.size()
	var me: int = main.game.players.find(main.game.players.filter(func(p): return p.bot == main.human)[0])
	armed = posmod(me - seat, n) >= 2
	if armed:
		_double_tap()


func _press(pos: Vector2, down: bool) -> void:
	var m := InputEventMouseButton.new()
	m.position = pos
	m.global_position = pos
	m.button_index = MOUSE_BUTTON_LEFT
	m.pressed = down
	Input.parse_input_event(m)


func _double_tap() -> void:
	tapping = true
	await create_timer(0.2).timeout
	var done := 0
	for p in POINTS:
		if done == 2:
			break
		var pos: Vector2 = root.get_final_transform() * p
		_press(pos, true)
		await process_frame
		var bg: bool = main._press_at != Vector2.INF  # main took it as a background tap
		_press(pos, false)
		await process_frame
		if bg:
			done += 1
			if done == 1:
				await create_timer(0.1).timeout
	if done < 2:
		results.append("no background point found")
		fails += 1
		_finish()
		return
	var skipped: bool = main._q.skip_all
	if table and skipped:
		results.append("table: double tap set skip_all")
		fails += 1
	elif not table and not skipped:
		results.append("old board: double tap did not skip")
		fails += 1
	since_tap = 0.0
	tapping = false


func _finish() -> void:
	for r in results:
		print("  " + r)
	print("TABLE TAP %s (%s, %d checks)" % ["PASSED" if fails == 0 and results.size() >= CHECKS else "FAILED", "table" if table else "old board", results.size()])
	quit()


func _process(delta: float) -> bool:
	if main == null or main.game == null or tapping:
		return false
	if since_tap >= 0.0:
		since_tap += delta
	var bs: Array = main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion() and not b.disabled)
	if bs.is_empty() or main._q.busy():
		waited = 0.0
		return false
	if since_tap >= 0.0:  # my decision is up: how long after the double tap
		var ok: bool = since_tap >= AFTER_MIN if table else true
		results.append("double tap, then my decision %.2f s later%s" % [since_tap, "" if ok else " (FAIL: under %.1f s)" % AFTER_MIN])
		if not ok:
			fails += 1
		since_tap = -1.0
		if results.size() >= CHECKS:
			_finish()
			return false
	if str(bs[0].get_meta("value", "")) == "new":
		_finish()
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
