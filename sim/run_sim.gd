## Headless balance runner. Phase 1: base loop with dice choice.
## godot --headless --path . --script res://sim/run_sim.gd
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")

const GRID_GAMES := 1000
const GAMES := 10000

const CAPS_3 := [2, 3, 4, 99]
const CAPS_2 := [2, 3, 99]
const CAPS_1 := [0, 1]
const BANKS := [300, 9999]

## Rule options for the current experiment, merged into every game.
var rule := {}


func _opts(players: int, extra := {}) -> Dictionary:
	var o := {"dice_choice": true, "supply": maxi(Rules.TOTAL_DICE, players * 8)}
	o.merge(rule, true)
	o.merge(extra, true)
	return o


func _init() -> void:
	# Run 4: combo multiplier, to make big throws worth it.
	for c in [0.0, 0.25, 0.5, 1.0]:
		rule = {"chain": c}
		print("\n\n================ CHAIN %.2f ================" % c)
		print("\n## Solo: best way to play each dice count")
		var best := _grid()
		print("\n## Does buying pay? (6 players, seats rotated)")
		var buyers := []
		for d in range(3, 9):
			buyers.append(best[d])
		_table(buyers, _opts(6))
	quit()


## Run 3 (kept for reference): skill check, head start, Indulgence sweep.
func _run3() -> void:
	print("\n######## A. Solo: best way to play each dice count ########")
	var best := _grid()

	print("\n######## B. Does buying pay? (6 players, seats rotated) ########")
	var buyers := []
	for d in range(3, 9):
		buyers.append(best[d])
	_table(buyers, _opts(6))

	print("\n######## C. Skill check: play styles at buy-to-5 (4 players) ########")
	_table([
		best[5],
		BotPolicy.chooser(5, [99, 99, 0], 400),   # always throw everything
		BotPolicy.chooser(5, [99, 2, 0], 200),    # cautious
		BotPolicy.chooser(5, [99, 0, 0], 1),      # one roll and bank
	], _opts(4))

	print("\n######## D. Head start per seat (identical best buy-to-5 bots) ########")
	for n in [4, 7]:
		for bonus in [0, 10, 20, 30, 40, 60]:
			_seat_bias(n, best[5], _opts(n, {"seat_bonus": bonus}), "bonus %d" % bonus)

	var s: BotPolicy = best[5]
	var caps := [s.cap_3_left, s.cap_2_left, s.cap_1_left]
	for pct in [10, 20, 30]:
		print("\n######## E. Indulgence = %d%% of score (4 players) ########" % pct)
		var escapes := []
		for pay_below in [99999, 0, 300, 600]:
			escapes.append(BotPolicy.chooser(5, caps, s.bank_at, pay_below))
		_table(escapes, _opts(4, {"indulgence_pct": pct}))


## Solo: average turns to 1000 for each dice count, over every play style. Returns best bot per dice count.
func _grid() -> Dictionary:
	var best := {}
	print("dice  best style                   turns  bust%  rolls/turn | throw-all  one-roll")
	for d in range(3, 9):
		var best_turns := 1e9
		var best_line := ""
		for c3 in CAPS_3:
			for c2 in CAPS_2:
				for c1 in CAPS_1:
					for b in BANKS:
						var bot = BotPolicy.chooser(d, [c3, c2, c1], b)
						var r := _solo(bot, GRID_GAMES)
						if r[0] < best_turns:
							best_turns = r[0]
							best[d] = bot
							best_line = "%-28s %5.1f  %4.0f%%  %5.2f" % [bot.label, r[0], r[1], r[2]]
		var allin := _solo(BotPolicy.chooser(d, [99, 99, 0], 400), GRID_GAMES)
		var one := _solo(BotPolicy.chooser(d, [99, 0, 0], 1), GRID_GAMES)
		print("%4d  %s     | %8.1f  %8.1f" % [d, best_line, allin[0], one[0]])
	return best


## Returns [avg turns to 1000, bust %, rolls per turn].
func _solo(bot, games: int) -> Array:
	var turns := 0
	var busts := 0
	var presses := 0
	for g in games:
		var game := Game.new([bot], g, _opts(1))
		game.play()
		turns += game.players[0].turns
		busts += game.players[0].busts
		presses += game.players[0].presses
	return [float(turns) / games, 100.0 * busts / turns, 1.0 + float(presses) / turns]


## Mixed bots at one table, seats rotated each game. Prints win rate per bot.
func _table(bots: Array, options: Dictionary) -> void:
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
		print("  %-28s %5.1f%%" % [b.label, 100.0 * wins[b.label] / GAMES])
	print("  avg rounds: %.1f" % (float(rounds) / GAMES))


## Identical bots: does seat order matter?
func _seat_bias(count: int, bot, options: Dictionary, title: String) -> void:
	var wins := []
	wins.resize(count)
	wins.fill(0)
	var bots := []
	for i in count:
		bots.append(bot)
	var rounds := 0
	for g in GAMES:
		var game := Game.new(bots, g, options)
		var w = game.play()
		rounds += game.round_count
		if w != null:
			wins[w.seat] += 1
	var line := "  %dp %-10s" % [count, title]
	var spread := 0.0
	for i in count:
		var pct: float = 100.0 * wins[i] / GAMES
		spread = maxf(spread, absf(pct - 100.0 / count))
		line += " %4.1f" % pct
	line += "  | worst seat off by %.1f, rounds %.1f" % [spread, float(rounds) / GAMES]
	print(line)
