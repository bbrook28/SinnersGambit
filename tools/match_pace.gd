## REPLY 34 item 1: one full match through the real UI (main.tscn, table view if `--table`), timed in game seconds
## at speed 1x (the engine runs TIME_SCALE faster). Reports: total seconds, rounds, each bot turn's seconds
## (min / median / max), my own decision count, how the game ended and in which round.
## My answers: THINK s after each prompt; throw while the stake is under BANK_AT, else bank; any other prompt, its
## first choice.
## godot --headless --path . --script res://tools/match_pace.gd -- [first|normal] [seed] [--table]
extends SceneTree

const Tuning = preload("res://ui/tuning.gd")
const TIME_SCALE := 4.0
const THINK := 1.5
const BANK_AT := 250

var main
var t := 0.0               # game seconds since the match began
var turn_t := 0.0          # since the current turn's banner
var cur_mine := false
var started := false
var bot_turns: Array[float] = []
var my_turns: Array[float] = []
var waited := 0.0          # since my prompt appeared
var answers := 0
var events: Array[String] = []
var mode := "first"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	mode = a[0] if a.size() > 0 else "first"
	var seed_v: int = int(a[1]) if a.size() > 1 else 7
	Tuning.speed = 1.0
	Engine.time_scale = TIME_SCALE
	await process_frame
	main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	main.save_enabled = false
	main.tutorial_enabled = false
	main.first_game_enabled = mode == "first"
	if mode == "first":
		main.games_finished = 0
	else:
		main.games_finished = 1
	main._dir.turn_shown.connect(_on_turn)
	seed(seed_v)
	main._start(main.SIN_SCRIPTS[2])
	print("MATCH mode %s seed %d table_view %s speed %.2f bot_pace_scale %.2f" % [mode, seed_v, Tuning.table_view(), Tuning.speed, Tuning.bot_pace_scale])


func _on_turn(seat: int, mine: bool) -> void:
	if started:
		(my_turns if cur_mine else bot_turns).append(turn_t)
	var g = main.game
	events.append("%6.1f s  round %d  seat %d%s" % [t, int(g.round_count) if g else -1, seat, " (you)" if mine else ""])
	started = true
	cur_mine = mine
	turn_t = 0.0


func _report(why: String) -> void:
	if started:
		(my_turns if cur_mine else bot_turns).append(turn_t)
	var s := bot_turns.duplicate()
	s.sort()
	var g = main.game
	print("END %s at %.1f s: rounds %d, called round %d, winner seat %d" % [why, t, int(g.round_count), int(g.called_round), g.players.find(g.winner) if g.winner else -1])
	if s.size():
		print("BOT TURNS %d: min %.1f s, median %.1f s, max %.1f s" % [s.size(), s[0], s[s.size() / 2], s[-1]])
	print("MY TURNS %d (answers %d, %.1f s thinking each)" % [my_turns.size(), answers, THINK])
	print("LINES %s" % str(main._table.line_stats if main._table else {}))
	for e in events:
		print("  " + e)
	quit()


func _process(delta: float) -> bool:
	t += delta
	turn_t += delta
	if main == null or main.game == null:
		return false
	if t > 3600.0:
		_report("TIMEOUT")
		return false
	var bs: Array = main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion() and not b.disabled)
	if bs.is_empty() or main._q.busy():
		waited = 0.0
		return false
	if str(bs[0].get_meta("value", "")) == "new":
		_report("GAME OVER")
		return false
	waited += delta
	if waited < THINK:
		return false
	waited = 0.0
	answers += 1
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
