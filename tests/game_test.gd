## Step 1 rules core (docs/step1-rules.md): setup, the Fate Phase, Purgatory, buying dice, the 0 floor, the win check.
## godot --headless --path . --script res://tests/game_test.gd
extends SceneTree

const Config = preload("res://game/config.gd")
const Rules = preload("res://game/rules.gd")

var _fails := 0


## A scripted random source: hands out the queued numbers in order.
class Faces:
	var queue: Array = []
	func _init(f: Array) -> void:
		queue = f.duplicate()
	func randi_range(_a: int, _b: int) -> int:
		return queue.pop_front()


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_fails += 1


const SINS := ["wrath", "greed", "lust", "envy"]


## A match with scripted dice and fixed Sins (so no number is spent on the deal).
func game(faces: Array, over := {}):
	return Rules.new_match(Config.merged(over), Faces.new(faces), SINS)


func _init() -> void:
	test_setup()
	test_deal()
	test_scoring_roll()
	test_into_purgatory()
	test_purgatory_stay_and_escape()
	test_escape_roll_all_low()
	test_two_dice()
	test_buy()
	test_buy_limits()
	test_floor()
	test_win()
	test_win_only_on_your_own_fate_phase()
	test_turn_order()
	test_give_points()
	test_lend_a_die()
	test_buy_for_another()
	test_full_match()
	print("game_test: %d failure(s)" % _fails)
	quit(1 if _fails > 0 else 0)


func test_setup() -> void:
	var s = game([])
	check("4 seats", s.seats.size() == 4)
	var ok := true
	for p in s.seats:
		ok = ok and p.points == 0 and p.dice == 3 and not p.purgatory and p.last_roll.is_empty()
	check("everyone starts at 0 points with 3 dice, free, nothing rolled", ok)
	check("15 dice in the supply", s.supply == 15)
	check("27 dice in all", Rules.total_dice(s) == 27)
	check("seat 0 starts, in the Fate Phase", s.turn == 0 and s.phase == Rules.FATE and s.round_number == 1)
	check("no winner yet", s.winner == -1)


func test_deal() -> void:
	var rng := RandomNumberGenerator.new()
	var seen := {}
	var ok := true
	for seed_value in 200:
		rng.seed = seed_value
		var s = Rules.new_match(Config.merged({}), rng)
		var mine := {}
		for p in s.seats:
			ok = ok and Config.SINS.has(p.sin)
			mine[p.sin] = true
			seen[p.sin] = true
		ok = ok and mine.size() == 4
	check("each seat is dealt a different Sin", ok)
	check("all seven Sins get dealt over 200 matches (%d seen)" % seen.size(), seen.size() == 7)
	rng.seed = 11
	var a = Rules.new_match(Config.merged({}), rng)
	rng.seed = 11
	var b = Rules.new_match(Config.merged({}), rng)
	var same := true
	for i in 4:
		same = same and a.seats[i].sin == b.seats[i].sin
	check("the same seed deals the same Sins", same)


func test_scoring_roll() -> void:
	var s = game([4, 5, 6])
	var r: Dictionary = Rules.roll(s)
	check("4, 5, 6 scores 150", s.seats[0].points == 150 and r.scored == 150)
	check("the roll stays on the seat", s.seats[0].last_roll == [4, 5, 6] and s.seats[0].last_score == 150)
	check("a scoring roll goes on to the Gambit Phase", s.phase == Rules.GAMBIT and s.turn == 0)
	s = game([1, 2, 6])
	Rules.roll(s)
	check("1, 2 and 3 score nothing: 1, 2, 6 scores 60", s.seats[0].points == 60)
	check("one roll a turn: a second roll is refused", Rules.roll(s).is_empty() and s.seats[0].points == 60)


func test_into_purgatory() -> void:
	var s = game([1, 2, 3])
	var r: Dictionary = Rules.roll(s)
	check("all dice 1-3: Purgatory, 0 scored", s.seats[0].purgatory and s.seats[0].points == 0 and r.purgatory and r.scored == 0)
	check("the turn is over: only passing is left", s.phase == Rules.END and s.turn == 0)
	check("no buying in Purgatory", Rules.max_buy(s) == 0 and not Rules.buy(s, 1))
	Rules.pass_turn(s)
	check("passing hands the turn to seat 1", s.turn == 1 and s.phase == Rules.FATE)


func test_purgatory_stay_and_escape() -> void:
	# seat 0: into Purgatory; seats 1-3 roll 4,4,4; seat 0: one low (stays); round again; seat 0: two lows (free)
	var s = game([1, 1, 1,  4, 4, 4,  4, 4, 4,  4, 4, 4,  2, 6, 6,  4, 4, 4,  4, 4, 4,  4, 4, 4,  3, 3, 5])
	Rules.roll(s)
	Rules.pass_turn(s)
	for i in 3:
		Rules.roll(s)
		Rules.pass_turn(s)
	var r: Dictionary = Rules.roll(s)
	var p = s.seats[0]
	check("one die showing 1-3 does not free you", p.purgatory and r.purgatory and not r.escaped)
	check("a failed escape scores nothing, even with two 6s", p.points == 0 and r.scored == 0 and p.last_score == 0)
	check("a failed escape ends the turn", s.phase == Rules.END and not Rules.buy(s, 1))
	check("the failed escape roll is the roll left on screen", p.last_roll == [2, 6, 6])
	Rules.pass_turn(s)
	for i in 3:
		Rules.roll(s)
		Rules.pass_turn(s)
	r = Rules.roll(s)
	check("two dice showing 1-3 free you", not p.purgatory and r.escaped)
	check("once free you score the roll's 4s, 5s and 6s: 3, 3, 5 scores 50", p.points == 50 and r.scored == 50)
	check("and you play on into the Gambit Phase", s.phase == Rules.GAMBIT and s.turn == 0)


func test_escape_roll_all_low() -> void:
	var s = game([1, 1, 1,  1, 2, 3])
	s.seats[0].purgatory = true
	Rules.roll(s)
	check("the escape roll is never checked for Purgatory: 1, 1, 1 frees you", not s.seats[0].purgatory and s.phase == Rules.GAMBIT)


func test_two_dice() -> void:
	var s = game([1, 3,  2, 5,  3, 2])
	s.seats[0].dice = 2
	s.supply += 1
	Rules.roll(s)
	check("2 dice, both 1-3: Purgatory", s.seats[0].purgatory)
	s.phase = Rules.FATE
	Rules.roll(s)
	check("2 dice in Purgatory, one low: still in", s.seats[0].purgatory and s.phase == Rules.END)
	s.phase = Rules.FATE
	Rules.roll(s)
	check("2 dice in Purgatory, both low: free", not s.seats[0].purgatory and s.phase == Rules.GAMBIT)


func test_buy() -> void:
	var s = game([6, 6, 6])
	Rules.roll(s)
	check("180 points buys up to 9 dice", Rules.max_buy(s) == 9)
	check("buying 2 dice", Rules.buy(s, 2))
	var p = s.seats[0]
	check("costs 20 each: 180 - 40 = 140", p.points == 140)
	check("the dice come from the supply: 5 dice, supply 13", p.dice == 5 and s.supply == 13)
	check("still 27 dice in all", Rules.total_dice(s) == 27)
	check("you can buy again in the same Gambit Phase", Rules.buy(s, 1) and p.dice == 6 and p.points == 120)
	check("the last roll does not change when you buy", p.last_roll == [6, 6, 6])


func test_buy_limits() -> void:
	var s = game([4, 1, 1])
	check("no buying before you roll", not Rules.buy(s, 1))
	Rules.roll(s)
	check("40 points buys at most 2", Rules.max_buy(s) == 2)
	check("a die you cannot pay for is refused, and nothing changes", not Rules.buy(s, 3) and s.seats[0].points == 40 and s.seats[0].dice == 3 and s.supply == 15)
	check("buying 0 or fewer is refused", not Rules.buy(s, 0) and not Rules.buy(s, -1))
	s.supply = 1
	check("an empty supply limits the buy", Rules.max_buy(s) == 1 and not Rules.buy(s, 2) and Rules.buy(s, 1))
	check("nothing left to buy", s.supply == 0 and Rules.max_buy(s) == 0 and not Rules.buy(s, 1))


func test_floor() -> void:
	var s = game([])
	s.seats[2].points = 30
	check("losing 50 from 30 loses 30", Rules.add_points(s, 2, -50) == -30)
	check("points stop at 0", s.seats[2].points == 0)
	check("gaining works as written", Rules.add_points(s, 2, 70) == 70 and s.seats[2].points == 70)


func test_win() -> void:
	var s = game([6, 1, 1])
	s.seats[0].points = 2940
	var r: Dictionary = Rules.roll(s)
	check("ending your Fate Phase on 3000 wins at once", s.winner == 0 and s.phase == Rules.OVER and r.won)
	check("nothing more can happen", Rules.roll(s).is_empty() and not Rules.buy(s, 1) and not Rules.pass_turn(s) and s.turn == 0)
	s = game([5, 1, 1])
	s.seats[0].points = 2940
	Rules.roll(s)
	check("2990 is not a win", s.winner == -1 and s.phase == Rules.GAMBIT)


func test_win_only_on_your_own_fate_phase() -> void:
	var s = game([4, 4, 4,  1, 1, 1,  4, 4, 4,  4, 4, 4,  4, 4, 4,  6, 6, 2,  4, 4, 4,  4, 4, 4,  4, 4, 4,  1, 1, 5])
	Rules.add_points(s, 1, 3000)
	Rules.roll(s)
	check("points reached outside your own Fate Phase do not win yet", s.winner == -1)
	Rules.pass_turn(s)
	Rules.roll(s)
	check("you cannot win while in Purgatory: 3000 points and a roll into Purgatory is no win", s.winner == -1 and s.phase == Rules.END and s.seats[1].purgatory)
	for i in 4:
		Rules.pass_turn(s)
		Rules.roll(s)
	check("a failed escape at 3000 is no win either", s.winner == -1 and s.seats[1].purgatory and s.turn == 1)
	for i in 4:
		Rules.pass_turn(s)
		Rules.roll(s)
	check("the roll that frees you wins", s.winner == 1 and s.phase == Rules.OVER and not s.seats[1].purgatory)
	s = game([4, 4, 4,  5, 1, 1])
	Rules.add_points(s, 1, 3000)
	Rules.roll(s)
	Rules.pass_turn(s)
	Rules.roll(s)
	check("free at the end of your Fate Phase with 3000: you win", s.winner == 1)


func test_give_points() -> void:
	var s = game([6, 6, 6])
	check("no gifts before the roll", not Rules.gift(s, Rules.POINTS, 0, 1, 10))
	Rules.roll(s)
	check("give 50 of your 180 points", Rules.gift(s, Rules.POINTS, 0, 2, 50) and s.seats[0].points == 130 and s.seats[2].points == 50)
	check("you cannot give more than you have", not Rules.gift(s, Rules.POINTS, 0, 2, 140) and s.seats[0].points == 130)
	check("you can give all you have", Rules.gift(s, Rules.POINTS, 0, 3, 130) and s.seats[0].points == 0 and s.seats[3].points == 130)
	check("0 points is no gift", not Rules.gift(s, Rules.POINTS, 0, 1, 0))
	check("a gift you asked for: seat 3 gives seat 0 (whose turn it is) 30", Rules.gift(s, Rules.POINTS, 3, 0, 30) and s.seats[0].points == 30 and s.seats[3].points == 100)
	check("two other players cannot trade on your turn", not Rules.gift(s, Rules.POINTS, 3, 2, 10))
	check("no gift to yourself", not Rules.gift(s, Rules.POINTS, 0, 0, 10))
	s.seats[1].purgatory = true
	check("no gift to a player in Purgatory", not Rules.gift(s, Rules.POINTS, 0, 1, 10) and Rules.gift_block(s, Rules.POINTS, 0, 1, 10) != "")
	s.seats[1].points = 100
	check("no gift from a player in Purgatory", not Rules.gift(s, Rules.POINTS, 1, 0, 10) and not Rules.gift(s, Rules.LEND, 1, 0) and not Rules.gift(s, Rules.DIE, 1, 0))


func test_lend_a_die() -> void:
	# seat 0 rolls 3 dice and lends one to seat 1; seat 1 rolls 4 dice; next round seat 0 rolls 2 and seat 1 rolls 3
	var s = game([6, 6, 6,  4, 4, 4, 5,  4, 4, 4,  4, 4, 4,  4, 4,  4, 4, 4])
	Rules.roll(s)
	check("lend a die to seat 1", Rules.gift(s, Rules.LEND, 0, 1))
	check("the lender is down to 2 dice; the die waits with seat 1", s.seats[0].dice == 2 and s.seats[1].dice == 3 and s.seats[1].lent == 1)
	check("still 27 dice in all", Rules.total_dice(s) == 27)
	check("you cannot go below 2 dice", not Rules.gift(s, Rules.LEND, 0, 1) and s.seats[0].dice == 2)
	Rules.pass_turn(s)
	var r: Dictionary = Rules.roll(s)
	check("seat 1 rolls 4 dice: 4, 4, 4, 5 scores 170", r.faces == [4, 4, 4, 5] and s.seats[1].points == 170)
	check("after that one roll the lent die goes to the supply, not back to the lender", s.seats[1].lent == 0 and s.seats[1].dice == 3 and s.supply == 16 and s.seats[0].dice == 2)
	check("still 27 dice in all after the roll", Rules.total_dice(s) == 27)
	for i in 4:
		Rules.pass_turn(s)
		Rules.roll(s)
	check("seat 0 now rolls 2 dice and seat 1 rolls 3", s.seats[0].last_roll.size() == 2 and s.seats[1].last_roll.size() == 3)
	s = game([6, 6, 6])
	Rules.roll(s)
	check("a die you asked for: seat 2 lends one to seat 0", Rules.gift(s, Rules.LEND, 2, 0) and s.seats[2].dice == 2 and s.seats[0].lent == 1)
	check("a seat on 2 dice cannot lend", not Rules.gift(s, Rules.LEND, 2, 0))


func test_buy_for_another() -> void:
	var s = game([4, 1, 1])
	Rules.roll(s)
	check("buy a die for seat 3: you pay 20, they keep it", Rules.gift(s, Rules.DIE, 0, 3) and s.seats[0].points == 20 and s.seats[3].dice == 4 and s.seats[0].dice == 3 and s.supply == 14)
	check("still 27 dice in all", Rules.total_dice(s) == 27)
	check("a seat with no points cannot buy one for you", not Rules.gift(s, Rules.DIE, 2, 0))
	s.seats[2].points = 20
	check("a die you asked for: seat 2 pays 20 and it is yours", Rules.gift(s, Rules.DIE, 2, 0) and s.seats[2].points == 0 and s.seats[0].dice == 4 and s.supply == 13)
	s.supply = 0
	check("an empty supply: no die to buy", not Rules.gift(s, Rules.DIE, 0, 1) and s.seats[0].points == 20)


func test_turn_order() -> void:
	var s = game([4, 4, 4,  4, 4, 4,  4, 4, 4,  4, 4, 4])
	check("no passing before you roll", not Rules.pass_turn(s) and s.turn == 0)
	var order := []
	for i in 4:
		order.append(s.turn)
		Rules.roll(s)
		Rules.pass_turn(s)
	check("turns go round in seat order", order == [0, 1, 2, 3])
	check("then back to seat 0, round 2", s.turn == 0 and s.round_number == 2)


## Whole matches on seeded dice, every seat buying all it can: each ends in a winner and no rule is broken on the way.
func test_full_match() -> void:
	var rng := RandomNumberGenerator.new()
	var broken := []
	var rounds := []
	var purgatories := 0
	for seed_value in 200:
		rng.seed = seed_value
		var s = Rules.new_match(Config.merged({}), rng)
		var turns := 0
		while s.winner == -1 and turns < 5000:
			turns += 1
			var r: Dictionary = Rules.roll(s)
			if r.purgatory and not r.escaped:
				purgatories += 1
			if s.phase == Rules.GAMBIT and seed_value % 4 == 3:
				# gifts at random, allowed or not: a refused one must change nothing
				var other: int = (s.turn + 1 + rng.randi_range(0, 2)) % 4
				var pair := [s.turn, other] if rng.randi_range(0, 1) == 0 else [other, s.turn]
				Rules.gift(s, [Rules.POINTS, Rules.LEND, Rules.DIE][rng.randi_range(0, 2)], pair[0], pair[1], rng.randi_range(0, 8) * 10)
			if s.phase == Rules.GAMBIT and seed_value % 2 == 0:
				Rules.buy(s, Rules.max_buy(s))
			if Rules.total_dice(s) != 27:
				broken.append("seed %d: %d dice" % [seed_value, Rules.total_dice(s)])
			for p in s.seats:
				if p.points < 0 or p.dice < 2 or s.supply < 0:
					broken.append("seed %d: points %d, dice %d, supply %d" % [seed_value, p.points, p.dice, s.supply])
			if s.winner == -1:
				Rules.pass_turn(s)
		if s.winner == -1:
			broken.append("seed %d: no winner" % seed_value)
		elif s.seats[s.winner].points < 3000 or s.winner != s.turn:
			broken.append("seed %d: a wrong winner" % seed_value)
		rounds.append(s.round_number)
	check("200 seeded matches each play to one winner with no rule broken (%s)" % ("none" if broken.is_empty() else ", ".join(broken.slice(0, 5))), broken.is_empty())
	check("Purgatory happens in play (%d times)" % purgatories, purgatories > 0)
	var buy := 0
	var keep := 0
	for i in rounds.size():
		if i % 2 == 0:
			buy += rounds[i]
		elif i % 4 == 1:
			keep += rounds[i]
	print("game_test: match length in rounds, buying all you can %.1f (100 matches), never buying %.1f (50 matches)" % [buy / 100.0, keep / 50.0])
