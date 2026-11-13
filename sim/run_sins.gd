## Sin balance runner (Rules.V2, Tiers 1+2).
## godot --headless --path . --script res://sim/run_sins.gd          (Tiers 1+2)
## godot --headless --path . --script res://sim/run_sins.gd -- t1    (Tier 1 only)
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")

const GAMES := 10000
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"),
	preload("res://sins/greed.gd"),
	preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"),
	preload("res://sins/pride.gd"),
	preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]


func _init() -> void:
	var options := Rules.V2.duplicate()
	options["tier2"] = not ("t1" in OS.get_cmdline_user_args())
	print("Tier 2: ", "on" if options["tier2"] else "off")
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)

	print("\n## 7 players, one of each Sin, seats shuffled each game (fair = 14.3%)")
	print("  Sin        win%  T2 uses/game  bounces/game")
	var wins := {}
	var uses := {}
	var bounces := {}
	var rounds := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for s in SIN_SCRIPTS:
		var n: String = s.new().sin_name
		wins[n] = 0
		uses[n] = 0
		bounces[n] = 0
	for g in GAMES:
		var order := []
		for s in SIN_SCRIPTS:
			order.append(s.new())  # fresh instances: Envy keeps per-game state
		for i in range(order.size() - 1, 0, -1):  # Fisher-Yates
			var j := rng.randi_range(0, i)
			var t = order[i]
			order[i] = order[j]
			order[j] = t
		var bots := []
		for i in order.size():
			bots.append(bot)
		var game := Game.new(bots, g, options, order)
		var w = game.play()
		rounds += game.round_count
		wins[w.sin.sin_name] += 1
		for p in game.players:
			uses[p.sin.sin_name] += p.t2_uses
			bounces[p.sin.sin_name] += p.t2_bounces
	for n in wins:
		print("  %-9s %5.1f%%  %6.2f  %6.2f" % [n, 100.0 * wins[n] / GAMES, float(uses[n]) / GAMES, float(bounces[n]) / GAMES])
	print("  avg rounds: %.2f" % (float(rounds) / GAMES))

	print("\n## 4 players: one Sin vs 3 plain bots, Sin seat rotated (fair = 25%)")
	for s in SIN_SCRIPTS:
		var w := 0
		var sname := ""
		for g in GAMES:
			var seat := g % 4
			var table := [null, null, null, null]
			table[seat] = s.new()
			sname = table[seat].sin_name
			var game := Game.new([bot, bot, bot, bot], g, options, table)
			if game.play().seat == seat:
				w += 1
		print("  %-9s %5.1f%%" % [sname, 100.0 * w / GAMES])
	quit()
