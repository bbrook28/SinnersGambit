## REPLY 22 item 5: the table game through its own code path (core/game.gd play(), the options ui/main.gd
## table_rules() gives a non-first game), with the app's rivals (BotPolicy.chooser(5, [99,2,0], 300)) and a
## Gambler in the human seat (chooser(6, [99,99,2]), never banks early: an approximation of sim_bots' gambler).
## Prints the leader's margin over second after round 3, and busts per turn for rivals and the human seat.
## godot --headless --path . --script res://sim/live_table.gd -- [games] [seats]
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"), preload("res://sins/greed.gd"), preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"), preload("res://sins/pride.gd"), preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var games: int = int(args[0]) if args.size() > 0 else 200
	var seats: int = int(args[1]) if args.size() > 1 else 4
	var o: Dictionary = Rules.V5.duplicate()  # ui/main.gd table_rules() and _start(), not a first game
	o["master_call"] = Rules.MASTER_CALL
	o["call_floor"] = Rules.MASTER_CALL_FLOOR
	o["tier2"] = true
	o["temptations"] = true
	var rival = BotPolicy.chooser(5, [99, 2, 0], 300)
	var gambler = BotPolicy.chooser(6, [99, 99, 2], 9999)
	var rng := RandomNumberGenerator.new()
	rng.seed = 22
	var margins: Array = []
	var gambler_leads := 0
	var r_busts := 0
	var r_turns := 0
	var h_busts := 0
	var h_turns := 0
	var rounds := 0
	var h_wins := 0
	for g in games:
		var pool: Array = range(7)
		for i in range(6, 0, -1):
			var j := rng.randi_range(0, i)
			var t = pool[i]
			pool[i] = pool[j]
			pool[j] = t
		var hseat := rng.randi_range(0, seats - 1)
		var bots := []
		var sins := []
		for i in seats:
			bots.append(gambler if i == hseat else rival)
			sins.append(SIN_SCRIPTS[pool[i]].new())
		var game := Game.new(bots, rng.randi(), o, sins)
		var v := Watch.new()
		v.game = game
		v.hseat = hseat
		game.view = v
		await game.play()
		if v.margin >= 0:
			margins.append(v.margin)
			if v.leader == hseat:
				gambler_leads += 1
		rounds += game.round_count
		for p in game.players:
			if p.seat == hseat:
				h_busts += p.busts
				h_turns += p.turns
			else:
				r_busts += p.busts
				r_turns += p.turns
		if game.winner and game.winner.seat == hseat:
			h_wins += 1
	margins.sort()
	var n := margins.size()
	var avg := 0.0
	for m in margins:
		avg += m
	avg /= maxf(1.0, n)
	var clear := []
	for c in [300, 400, 500, 600]:
		clear.append("%d+ %.1f%%" % [c, 100.0 * margins.filter(func(m): return m >= c).size() / maxf(1.0, n)])
	print("live table, %d games, %d seats, rounds %.2f" % [games, seats, float(rounds) / games])
	print("  leader over second after round 3: mean %.0f, median %d, 90th %d | %s | the Gambler seat leads %.1f%%" % [
		avg, margins[n / 2], margins[int(n * 0.9)], ", ".join(clear), 100.0 * gambler_leads / maxf(1.0, n)])
	print("  busts per turn: rivals %.3f (%d turns), Gambler seat %.3f (%d turns); Gambler seat wins %.1f%%" % [
		float(r_busts) / maxf(1.0, r_turns), r_turns, float(h_busts) / maxf(1.0, h_turns), h_turns, 100.0 * h_wins / games])
	quit()



## A view with only what core/ calls on one: at the first turn of round 4 the scores are round 3's.
class Watch extends RefCounted:
	var game
	var hseat := -1
	var margin := -1
	var leader := -1
	func log_line(_t: String) -> void:
		pass
	func beat(_p, _k: String) -> void:
		pass
	func player_name(p) -> String:
		return "P%d" % p.seat
	func turn_started(_p) -> void:
		if game.round_count == 4 and margin < 0:
			var sc: Array = game.players.map(func(q): return q.score)
			sc.sort()
			margin = sc[-1] - sc[-2]
			leader = game._leader().seat
