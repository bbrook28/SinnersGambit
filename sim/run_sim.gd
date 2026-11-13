## Headless balance runner.
## godot --headless --path . --script res://sim/run_sim.gd
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")

const GAMES := 10000
const BASE := {}
const FINISH := {"finish_round": true}
const PRESS := {"finish_round": true, "press": true}

## Press styles to try: [max strikes to keep pressing, bank at].
const STYLES := [[-1, 9999], [0, 9999], [0, 150], [0, 250], [1, 100], [1, 150], [1, 250], [1, 9999]]


func _init() -> void:
	print("\n######## SEAT BIAS FIX (no press) ########")
	for n in [4, 7]:
		_seat_bias(n, BotPolicy.new(5), BASE, "rulebook")
		_seat_bias(n, BotPolicy.new(5), FINISH, "finish the round")

	print("\n######## PRESS: solo turns to 1000 ########")
	var best_style := _press_grid()

	print("\n######## PRESS + FINISH THE ROUND: tables ########")
	var buyers := []
	for d in range(3, 8):
		buyers.append(_bot(d, best_style[d]))
	_table(buyers, PRESS, "Buy targets, each with its best press style, 4-5 players")

	var styles := []
	for s in [[-1, 9999], [0, 9999], [1, 150], [1, 9999]]:
		styles.append(BotPolicy.new(5, true, s[0], s[1]))
	_table(styles, PRESS, "Press styles, all buy to 5, 4 players")

	_table([_bot(5, best_style[5], true), _bot(5, best_style[5], false)], PRESS, "Purgatory escape with press, 2 players")

	for n in [4, 7]:
		_seat_bias(n, _bot(5, best_style[5]), PRESS, "press + finish the round")
	quit()


func _bot(dice: int, style: Array, pay := true):
	return BotPolicy.new(dice, pay, style[0], style[1])


## Solo: average turns to 1000 for every dice count x press style. Returns best style per dice count.
func _press_grid() -> Dictionary:
	var header := "dice "
	for s in STYLES:
		header += "%10s" % _style_name(s)
	print(header)
	var best := {}
	for d in range(3, 8):
		var line := "%4d " % d
		var best_turns := 1e9
		for s in STYLES:
			var turns := 0
			var busts := 0
			for g in GAMES:
				var game := Game.new([_bot(d, s)], g, {"press": true})
				game.play()
				turns += game.players[0].turns
				busts += game.players[0].busts
			var avg := float(turns) / GAMES
			line += "%5.1f/%2d%%" % [avg, roundi(100.0 * busts / turns)]
			if avg < best_turns:
				best_turns = avg
				best[d] = s
		print(line)
	print("(avg turns / bust rate)  best: ", _best_str(best))
	return best


func _style_name(s: Array) -> String:
	if s[0] < 0:
		return "no press"
	return "s%d%s" % [s[0], "" if s[1] >= 9999 else "b%d" % s[1]]


func _best_str(best: Dictionary) -> String:
	var parts := []
	for d in best:
		parts.append("%d dice: %s" % [d, _style_name(best[d])])
	return ", ".join(parts)


## Mixed bots at one table, seats rotated each game. Prints win rate per bot.
func _table(bots: Array, options: Dictionary, title: String) -> void:
	print("\n== %s ==" % title)
	var wins := {}
	var rounds := 0
	for b in bots:
		wins[b.label] = 0
	for g in GAMES:
		var order := []
		for i in bots.size():
			order.append(bots[(i + g) % bots.size()])
		var game := Game.new(order, g, options)
		var w = game.play()
		rounds += game.round_count
		if w != null:
			wins[w.bot.label] += 1
	for b in bots:
		print("%-16s %5.1f%%" % [b.label, 100.0 * wins[b.label] / GAMES])
	print("avg rounds: %.1f" % (float(rounds) / GAMES))


## Identical bots: does seat order matter?
func _seat_bias(count: int, bot, options: Dictionary, title: String) -> void:
	var wins := []
	wins.resize(count)
	wins.fill(0)
	var bots := []
	for i in count:
		bots.append(bot)
	var rounds := 0
	var ties := 0
	for g in GAMES:
		var game := Game.new(bots, g, options)
		var w = game.play()
		rounds += game.round_count
		if game.is_tie:
			ties += 1
		if w != null:
			wins[w.seat] += 1
	var line := "%dp %-26s" % [count, title]
	for i in count:
		line += " %4.1f" % (100.0 * wins[i] / GAMES)
	line += "  | fair %.1f, rounds %.1f, ties %.1f%%" % [100.0 / count, float(rounds) / GAMES, 100.0 * ties / GAMES]
	print(line)
