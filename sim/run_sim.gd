## Headless balance runner.
## godot --headless --path . --script res://sim/run_sim.gd
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")

const GAMES := 20000


func _init() -> void:
	_solo_race()
	_table([BotPolicy.new(3), BotPolicy.new(4), BotPolicy.new(5), BotPolicy.new(6)], "Buy targets, 4 players")
	_table([BotPolicy.new(5), BotPolicy.new(6), BotPolicy.new(7), BotPolicy.new(8)], "Big buyers, 4 players")
	_table([BotPolicy.new(5, true), BotPolicy.new(5, false)], "Purgatory escape, 2 players")
	_seat_bias(4)
	_seat_bias(7)
	quit()


## One bot alone: turns to reach 1000 and bust rate for each buy target.
func _solo_race() -> void:
	print("\n== Solo race to %d ==" % Rules.WIN_SCORE)
	print("target  avg turns  bust rate")
	for target in range(2, 10):
		var turns := 0
		var busts := 0
		for g in GAMES:
			var game := Game.new([BotPolicy.new(target)], g)
			game.play()
			turns += game.players[0].turns
			busts += game.players[0].busts
		print("%6d  %9.1f  %8.1f%%" % [target, float(turns) / GAMES, 100.0 * busts / turns])


## Mixed bots at one table, seats rotated each game. Prints win rate per bot.
func _table(bots: Array, title: String) -> void:
	print("\n== %s ==" % title)
	var wins := {}
	var rounds := 0
	for b in bots:
		wins[b.label] = 0
	for g in GAMES:
		var order := []
		for i in bots.size():
			order.append(bots[(i + g) % bots.size()])
		var game := Game.new(order, g)
		var w = game.play()
		rounds += game.round_count
		if w != null:
			wins[w.bot.label] += 1
	for b in bots:
		print("%-16s %5.1f%%" % [b.label, 100.0 * wins[b.label] / GAMES])
	print("avg rounds: %.1f" % (float(rounds) / GAMES))


## Identical bots: does going first matter?
func _seat_bias(count: int) -> void:
	print("\n== Seat bias, %d identical buy-to-5 bots ==" % count)
	var wins := []
	wins.resize(count)
	wins.fill(0)
	var bots := []
	for i in count:
		bots.append(BotPolicy.new(5))
	var rounds := 0
	for g in GAMES:
		var game := Game.new(bots, g)
		var w = game.play()
		rounds += game.round_count
		if w != null:
			wins[w.seat] += 1
	for i in count:
		print("seat %d  %5.1f%%" % [i + 1, 100.0 * wins[i] / GAMES])
	print("avg rounds: %.1f (turns per game ~%d)" % [float(rounds) / GAMES, rounds * count / GAMES])
