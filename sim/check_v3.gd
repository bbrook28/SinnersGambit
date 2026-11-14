## Rules.V2 vs Rules.V3 with Sins: win rate per Sin, game length, busts and Purgatory.
## godot --headless --path . --script res://sim/check_v3.gd [-- games]
## Every game: a table of 7 (one of each Sin) or 4 (random Sins), seats shuffled, Greater on.
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
	var games: int = int(args[0]) if args.size() > 0 else 4000
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	for rules in [["V2", Rules.V2], ["V3", Rules.V3]]:
		for table in [4, 7]:
			for tier2 in [false, true]:
				_run(rules[0], rules[1], table, tier2, games, bot)
	quit()


func _run(name: String, rules: Dictionary, table: int, tier2: bool, games: int, bot) -> void:
	var options := rules.duplicate()
	options["tier2"] = tier2
	var wins := {}
	var seats_in := {}
	var rounds := 0
	var turns := 0
	var busts := 0
	var throws_per_turn := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for g in games:
		var pool := SIN_SCRIPTS.duplicate()
		for i in range(pool.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t = pool[i]
			pool[i] = pool[j]
			pool[j] = t
		var sins := []
		var bots := []
		for i in table:
			sins.append(pool[i].new())
			bots.append(bot)
		var game := Game.new(bots, g, options, sins)
		var w = await game.play()
		rounds += game.round_count
		for p in game.players:
			turns += p.turns
			busts += p.busts
			throws_per_turn += p.presses
			seats_in[p.sin.sin_name] = seats_in.get(p.sin.sin_name, 0) + 1
		wins[w.sin.sin_name] = wins.get(w.sin.sin_name, 0) + 1
	var line := "%s table %d %s: rounds %.1f, busts/turn %.2f, throws/turn %.2f |" % [
		name, table, "Basic+Greater" if tier2 else "Basic only", float(rounds) / games,
		float(busts) / turns, 1.0 + throws_per_turn / turns]
	# Win share relative to fair (1.00 = wins exactly its share of the games it sat in).
	for s in SIN_SCRIPTS:
		var n: String = s.new().sin_name
		var fair := float(seats_in.get(n, 0)) / table
		line += " %s %.2f" % [n.substr(0, 4), float(wins.get(n, 0)) / maxf(1.0, fair)]
	print(line)
