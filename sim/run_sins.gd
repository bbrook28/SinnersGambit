## Sin balance runner (Rules.V2).
## godot --headless --path . --script res://sim/run_sins.gd
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
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	var sins := []
	for s in SIN_SCRIPTS:
		sins.append(s.new())

	print("\n## 7 players, one of each Sin, seats shuffled each game (fair = 14.3%)")
	var wins := {}
	var rounds := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for s in sins:
		wins[s.sin_name] = 0
	for g in GAMES:
		var order := sins.duplicate()
		for i in range(order.size() - 1, 0, -1):  # Fisher-Yates
			var j := rng.randi_range(0, i)
			var t = order[i]
			order[i] = order[j]
			order[j] = t
		var bots := []
		for i in order.size():
			bots.append(bot)
		var game := Game.new(bots, g, Rules.V2, order)
		var w = game.play()
		rounds += game.round_count
		wins[w.sin.sin_name] += 1
	for s in sins:
		print("  %-9s %5.1f%%" % [s.sin_name, 100.0 * wins[s.sin_name] / GAMES])
	print("  avg rounds: %.1f" % (float(rounds) / GAMES))

	print("\n## 4 players: one Sin vs 3 plain bots, Sin seat rotated (fair = 25%)")
	for s in sins:
		var w := 0
		for g in GAMES:
			var seat := g % 4
			var table := [null, null, null, null]
			table[seat] = s
			var game := Game.new([bot, bot, bot, bot], g, Rules.V2, table)
			if game.play().seat == seat:
				w += 1
		print("  %-9s %5.1f%%" % [s.sin_name, 100.0 * w / GAMES])
	quit()
