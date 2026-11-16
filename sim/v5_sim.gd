## Rules.V5 as built in core/ (no sim prototypes): win % per Sin at 4 seats with the game's bot, power use,
## comebacks, rounds; and the skill bot's edge. Confirms core matches sim/agency_sim.gd (TableDesign §10).
## godot --headless --path . --script res://sim/v5_sim.gd -- [games] [key=value ...]
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"), preload("res://sins/greed.gd"), preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"), preload("res://sins/pride.gd"), preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]
const NAMES := ["Wrath", "Greed", "Lust", "Envy", "Pride", "Gluttony", "Sloth"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var games: int = int(args[0]) if args.size() > 0 and args[0].is_valid_int() else 4000
	var o := Rules.V5.duplicate()
	o["tier2"] = true
	for a in args:
		if "=" in a:
			var kv: PackedStringArray = a.split("=")
			o[kv[0]] = str_to_var(kv[1])
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var wins := {}
	var seats := {}
	var uses := {}
	var turns := {}
	var rounds := 0
	var halves := 0
	var comebacks := 0
	for g in games:
		var pool: Array = range(7)
		for i in range(6, 0, -1):
			var j := rng.randi_range(0, i)
			var t = pool[i]
			pool[i] = pool[j]
			pool[j] = t
		var sins := []
		for i in 4:
			sins.append(SIN_SCRIPTS[pool[i]].new())
		var game := Game.new([bot, bot, bot, bot], g, o, sins)
		var half_last := []
		while game.winner == null and game.round_count < game.MAX_ROUNDS:
			game.round_count += 1
			for p in game.players:
				await game.take_turn(p)
				if half_last.is_empty() and game.leader_score() >= 500:
					var low := 99999
					for q in game.players:
						low = mini(low, q.score)
					for q in game.players:
						if q.score == low:
							half_last.append(q.seat)
				if game.winner != null:
					break
			if game.winner != null:
				break
			if game.end_triggered:
				game._resolve_finish()
		rounds += game.round_count
		if not half_last.is_empty():
			halves += 1
			if game.winner.seat in half_last:
				comebacks += 1
		for p in game.players:
			var n: String = p.sin.sin_name
			seats[n] = seats.get(n, 0) + 1
			uses[n] = uses.get(n, 0) + p.powers_used
			turns[n] = turns.get(n, 0) + p.turns
		wins[game.winner.sin.sin_name] = wins.get(game.winner.sin.sin_name, 0) + 1
	var line := "core V5, %d games, 4 seats: win %% (fair 25):" % games
	var lo := 100.0
	var hi := 0.0
	for n in NAMES:
		var w: float = 100.0 * wins.get(n, 0) / maxf(1.0, seats.get(n, 0))
		lo = minf(lo, w)
		hi = maxf(hi, w)
		line += " %s %.1f" % [n.substr(0, 4), w]
	print(line + " | range %.1f-%.1f" % [lo, hi])
	var pl := "  power used on % of turns:"
	for n in NAMES:
		pl += " %s %.0f" % [n.substr(0, 4), 100.0 * uses.get(n, 0) / maxf(1.0, turns.get(n, 0))]
	print(pl + " | comebacks %.1f%%, rounds %.1f" % [100.0 * comebacks / maxf(1.0, halves), float(rounds) / games])
	quit()
