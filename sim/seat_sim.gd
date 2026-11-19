## REPLY 40 item 3 (sim only): seat order. Core V5 with the Master's call, the game's bot in every seat, all 35
## tables of four Sins pooled, seat order shuffled each game. Plays the rounds itself (as core/game.gd play()) so
## the turn order can change without touching core/:
##   order=fixed   -- as today: seat 0 first every round (must match tables_sim)
##   order=rotate  -- the first seat moves one place each round (round 1: seat 0 first, round 2: seat 1 ...)
##   order=final   -- as today, but the Master's final round runs from the leader down (the last seat throws last)
##   order=both    -- rotate, and the final round from the leader down
##   order=chase   -- as today, but the final round runs from the last seat up (the leader throws last)
## Prints wins by seat, first to last, and each Sin's spread over its tables.
## godot --headless --path . --script res://sim/seat_sim.gd -- [games per table] order=<...> [part=i/n]
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
	var games: int = int(args[0]) if args.size() > 0 and args[0].is_valid_int() else 500
	var order := "fixed"
	var part := [0, 1]
	var o := Rules.V5.duplicate()
	o["master_call"] = Rules.MASTER_CALL
	o["call_floor"] = Rules.MASTER_CALL_FLOOR
	o["tier2"] = true
	for a in args:
		if a.begins_with("order="):
			order = a.substr(6)
		elif a.begins_with("part="):
			var pr: PackedStringArray = a.substr(5).split("/")
			part = [int(pr[0]), int(pr[1])]
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	var tables := []
	for a in 7:
		for b in range(a + 1, 7):
			for c in range(b + 1, 7):
				for d in range(c + 1, 7):
					tables.append([a, b, c, d])
	var seat_w := [0, 0, 0, 0]
	var n := 0
	var rounds := 0
	for t in tables.size():
		if t % part[1] != part[0]:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = 1000 + t
		for g in games:
			var ord: Array = tables[t].duplicate()
			for i in range(3, 0, -1):
				var j := rng.randi_range(0, i)
				var x = ord[i]
				ord[i] = ord[j]
				ord[j] = x
			var sins := []
			for i in ord:
				sins.append(SIN_SCRIPTS[i].new())
			var game := Game.new([bot, bot, bot, bot], t * 100003 + g, o.duplicate(), sins)
			var w = await _play(game, order)
			n += 1
			rounds += game.round_count
			if w != null:
				seat_w[w.seat] += 1
	print("order=%s | %d games (35 tables pooled, part %d/%d) | rounds %.2f | wins by seat 0-3 (seat 0 is you; today it throws first every round): %s" % [
		order, n, part[0], part[1], float(rounds) / maxf(1, n), " ".join(seat_w.map(func(x): return "%.1f" % (100.0 * x / maxf(1, n))))])
	print("raw %s" % str(seat_w + [n]))
	quit()


## core/game.gd play(), with the turn order chosen per round. The Master's lines are skipped (no view).
func _play(game, order: String):
	while game.winner == null and game.round_count < game.MAX_ROUNDS:
		game.round_count += 1
		if game.called_round >= 0 and game.round_count == game.called_round + 2:
			game.finish_round = true
			game.end_triggered = true
		game.mark_leader()
		var seq: Array = game.players.duplicate()
		match order:
			"rotate", "both":
				var k: int = (game.round_count - 1) % seq.size()
				seq = seq.slice(k) + seq.slice(0, k)
				if order == "both" and game.end_triggered:
					seq.sort_custom(func(a, b): return a.score > b.score)
			"final", "chase":
				if game.end_triggered:
					seq.sort_custom(func(a, b): return a.score > b.score if order == "final" else a.score < b.score)
		for p in seq:
			await game.take_turn(p)
			if game.winner != null:
				return game.winner
		if game.end_triggered:
			game._resolve_finish()
		elif game.master_call > 0 and game.called_round < 0 and game.leader_score() >= game.master_call and game.round_count >= game.call_floor:
			game.called_round = game.round_count
	return game.winner
