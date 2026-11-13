## Quick sanity check of Rules.V2: seat win rates and game length.
## godot --headless --path . --script res://sim/check_v2.gd
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")

const GAMES := 4000


func _init() -> void:
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	for n in [4, 7]:
		var wins := []
		wins.resize(n)
		wins.fill(0)
		var bots := []
		for i in n:
			bots.append(bot)
		var rounds := 0
		for g in GAMES:
			var game := Game.new(bots, g, Rules.V2)
			game.play()
			rounds += game.round_count
			wins[game.winner.seat] += 1
		var line := "%dp V2 seats:" % n
		for w in wins:
			line += " %4.1f" % (100.0 * w / GAMES)
		print(line, "  | rounds %.1f" % (float(rounds) / GAMES))
	quit()
