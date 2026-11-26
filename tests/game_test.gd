## Step 1 rules core (docs/step1-rules.md): setup, the Fate Phase, Purgatory, buying dice, the 0 floor, the win check.
## godot --headless --path . --script res://tests/game_test.gd
extends SceneTree

const Config = preload("res://game/config.gd")
const Rules = preload("res://game/rules.gd")
const Sins = preload("res://game/sins.gd")

var _fails := 0


## A scripted random source: hands out the queued numbers in order.
class Faces:
	var queue: Array = []
	func _init(f: Array) -> void:
		queue = f.duplicate()
	func randi_range(_a: int, _b: int) -> int:
		return 4 if queue.is_empty() else queue.pop_front()   # past the script every die shows 4


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_fails += 1


const SINS := ["", "", "", ""]   # no Sins: the base rules alone


## A match with scripted dice and no Sins (so no number is spent on the deal, and no ability acts).
func game(faces: Array, over := {}):
	return Rules.new_match(Config.merged(over), Faces.new(faces), SINS)


func _init() -> void:
	test_setup()
	test_sins_dealt()
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
	test_tier2()
	test_once_a_turn()
	test_spark()
	test_strike()
	test_vig()
	test_deal()
	test_whisper()
	test_allure()
	test_glance()
	test_grasp()
	test_hubris()
	test_superiority()
	test_feast()
	test_bite()
	test_drip()
	test_aura()
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
	check("6 spare dice in the supply", s.supply == 6)
	check("18 dice in all at a table of 4", Rules.total_dice(s) == 18)
	check("6 spare dice at any table size", Rules.new_match(Config.merged({"seats": 7}), Faces.new([]), ["", "", "", "", "", "", ""]).supply == 6)
	check("seat 0 starts, in the Fate Phase", s.turn == 0 and s.phase == Rules.FATE and s.round_number == 1)
	check("no winner yet", s.winner == -1)


func test_sins_dealt() -> void:
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
	var p = s.seats[0]
	check("180 points could pay for 9 dice, but only one die a turn", Rules.max_buy(s) == 1)
	check("buying 2 dice at once is refused, and nothing changes", not Rules.buy(s, 2) and p.points == 180 and p.dice == 3 and s.supply == 6)
	check("buying 1 die", Rules.buy(s, 1))
	check("costs 20: 180 - 20 = 160", p.points == 160)
	check("the die comes from the supply: 4 dice, supply 5", p.dice == 4 and s.supply == 5)
	check("still 18 dice in all", Rules.total_dice(s) == 18)
	check("no second die in the same turn", Rules.max_buy(s) == 0 and not Rules.buy(s, 1) and p.dice == 4 and p.points == 160)
	check("a die for another player is extra: still allowed, as often as you can pay", Rules.gift(s, Rules.DIE, 0, 1) and Rules.gift(s, Rules.DIE, 0, 2) and s.supply == 3 and p.points == 120 and p.dice == 4)
	Rules.pass_turn(s)
	play(s, 3)
	Rules.roll(s)
	check("on the next turn one die can be bought again", Rules.max_buy(s) == 1 and Rules.buy(s, 1) and p.dice == 5)
	s = game([6, 6, 6])
	Rules.roll(s)
	p = s.seats[0]
	check("a die bought for another player first does not use up your own buy", Rules.gift(s, Rules.DIE, 0, 1) and Rules.max_buy(s) == 1 and Rules.buy(s, 1) and not Rules.buy(s, 1))
	s = sg(["gluttony", "", "", ""], [6, 6, 6])
	rolled(s)
	p = s.seats[0]
	check("after Feast the die bought back is the one buy of the turn", not Rules.use(s, "feast", {"index": 0}).is_empty() and p.dice == 2 and Rules.buy(s, 1) and p.dice == 3 and not Rules.buy(s, 1) and Rules.max_buy(s) == 0)
	s = game([6, 6, 6])
	Rules.roll(s)
	p = s.seats[0]
	Rules.buy(s, 1)
	check("the last roll does not change when you buy", p.last_roll == [6, 6, 6])


func test_buy_limits() -> void:
	var s = game([4, 1, 1])
	check("no buying before you roll", not Rules.buy(s, 1))
	Rules.roll(s)
	check("40 points could pay for 2, but only one die a turn", Rules.max_buy(s) == 1)
	check("a die you cannot pay for is refused, and nothing changes", not Rules.buy(s, 3) and s.seats[0].points == 40 and s.seats[0].dice == 3 and s.supply == 6)
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
	s.seats[0].points = 940
	var r: Dictionary = Rules.roll(s)
	check("ending your Fate Phase on 1000 wins at once", s.winner == 0 and s.phase == Rules.OVER and r.won)
	check("nothing more can happen", Rules.roll(s).is_empty() and not Rules.buy(s, 1) and not Rules.pass_turn(s) and s.turn == 0)
	s = game([5, 1, 1])
	s.seats[0].points = 940
	Rules.roll(s)
	check("990 is not a win", s.winner == -1 and s.phase == Rules.GAMBIT)


func test_win_only_on_your_own_fate_phase() -> void:
	var s = game([4, 4, 4,  1, 1, 1,  4, 4, 4,  4, 4, 4,  4, 4, 4,  6, 6, 2,  4, 4, 4,  4, 4, 4,  4, 4, 4,  1, 1, 5])
	Rules.add_points(s, 1, 1000)
	Rules.roll(s)
	check("points reached outside your own Fate Phase do not win yet", s.winner == -1)
	Rules.pass_turn(s)
	Rules.roll(s)
	check("you cannot win while in Purgatory: 1000 points and a roll into Purgatory is no win", s.winner == -1 and s.phase == Rules.END and s.seats[1].purgatory)
	for i in 4:
		Rules.pass_turn(s)
		Rules.roll(s)
	check("a failed escape at 1000 is no win either", s.winner == -1 and s.seats[1].purgatory and s.turn == 1)
	for i in 4:
		Rules.pass_turn(s)
		Rules.roll(s)
	check("the roll that frees you wins", s.winner == 1 and s.phase == Rules.OVER and not s.seats[1].purgatory)
	s = game([4, 4, 4,  5, 1, 1])
	Rules.add_points(s, 1, 1000)
	Rules.roll(s)
	Rules.pass_turn(s)
	Rules.roll(s)
	check("free at the end of your Fate Phase with 1000: you win", s.winner == 1)


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
	check("still 18 dice in all", Rules.total_dice(s) == 18)
	check("you cannot go below 2 dice", not Rules.gift(s, Rules.LEND, 0, 1) and s.seats[0].dice == 2)
	Rules.pass_turn(s)
	var r: Dictionary = Rules.roll(s)
	check("seat 1 rolls 4 dice: 4, 4, 4, 5 scores 170", r.faces == [4, 4, 4, 5] and s.seats[1].points == 170)
	check("after that one roll the lent die goes to the supply, not back to the lender", s.seats[1].lent == 0 and s.seats[1].dice == 3 and s.supply == 7 and s.seats[0].dice == 2)
	check("still 18 dice in all after the roll", Rules.total_dice(s) == 18)
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
	check("buy a die for seat 3: you pay 20, they keep it", Rules.gift(s, Rules.DIE, 0, 3) and s.seats[0].points == 20 and s.seats[3].dice == 4 and s.seats[0].dice == 3 and s.supply == 5)
	check("still 18 dice in all", Rules.total_dice(s) == 18)
	check("a seat with no points cannot buy one for you", not Rules.gift(s, Rules.DIE, 2, 0))
	s.seats[2].points = 20
	check("a die you asked for: seat 2 pays 20 and it is yours", Rules.gift(s, Rules.DIE, 2, 0) and s.seats[2].points == 0 and s.seats[0].dice == 4 and s.supply == 4)
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


## A match with these Sins and scripted dice (past the script every die shows 4: a roll of three scores 120).
func sg(sins: Array, faces: Array = []):
	return Rules.new_match(Config.merged({}), Faces.new(faces), sins)


## The player whose turn it is rolls (Lust scores without swapping) and passes; n times.
func play(s, n := 1) -> void:
	for i in n:
		Rules.roll(s)
		if s.phase == Rules.SWAP:
			Rules.settle(s)
		Rules.pass_turn(s)


## Rolls for the player whose turn it is and stops in their Gambit Phase.
func rolled(s) -> void:
	Rules.roll(s)
	if s.phase == Rules.SWAP:
		Rules.settle(s)


func test_tier2() -> void:
	var s = sg(["gluttony", "", "", ""])
	rolled(s)
	check("Tier 2 is shut below 350, and says so", Rules.block(s, "bite", {"target": 1}).contains("350") and Rules.use(s, "bite", {"target": 1}).is_empty())
	Rules.add_points(s, 0, 230)
	check("reaching 350 opens Tier 2", s.seats[0].points == 350 and s.seats[0].tier2 and Rules.block(s, "bite", {"target": 1}) == "")
	Rules.add_points(s, 0, -300)
	check("it stays open after dropping below 350", s.seats[0].points == 50 and Rules.block(s, "bite", {"target": 1}) == "")
	check("at most once a turn", not Rules.use(s, "bite", {"target": 1}).is_empty() and Rules.block(s, "bite", {"target": 2}) == "Already used this turn.")
	Rules.add_points(s, 0, -1000)
	play(s, 4)
	rolled(s)
	Rules.add_points(s, 0, -1000)
	Rules.add_points(s, 0, 10)
	check("you cannot pay a cost you do not have", Rules.block(s, "bite", {"target": 2}).contains("not enough points") and Rules.use(s, "bite", {"target": 2}).is_empty() and s.seats[0].points == 10)
	check("another Sin's ability is refused", Rules.use(s, "aura", {"target": 1}).is_empty() and Rules.use(s, "nonsense").is_empty())


## Ben, 2026-11-25: every ability at most once per turn by the player whose turn it is.
func test_once_a_turn() -> void:
	# each ability with a button: used once, then refused with the reason, then free again on the next turn
	var cases := [["wrath", "spark", {"target": 1, "index": 0}], ["wrath", "strike", {"target": 1, "choice": "points"}],
		["greed", "deal", {"target": 1, "choice": "points"}], ["lust", "allure", {"a": 1, "b": 2, "pick_a": 0, "pick_b": 1}],
		["envy", "grasp", {"key": "feast", "index": 0}], ["pride", "superiority", {}], ["gluttony", "feast", {"index": 0}],
		["gluttony", "bite", {"target": 1}], ["sloth", "aura", {"target": 1}]]
	var bad := []
	for c in cases:
		var s = sg([c[0], "", "", ""])
		for i in 4:
			Rules.add_points(s, i, 400)
			s.seats[i].dice = 4
			s.seats[i].last_roll = [6, 5, 4, 4]
		s.supply = 2
		s.t1_log.append({"turn": 0, "key": "feast"})
		rolled(s)
		var first: Dictionary = Rules.use(s, c[1], c[2])
		var why: String = Rules.block(s, c[1])
		var second: Dictionary = Rules.use(s, c[1], c[2])
		Rules.pass_turn(s)
		play(s, 3)
		s.t1_log.append({"turn": s.turn_count, "key": "spark"})
		rolled(s)
		var again: String = Rules.block(s, c[1])
		if first.is_empty() or why != "Already used this turn." or not second.is_empty() or again == "Already used this turn.":
			bad.append("%s (%s / %s)" % [c[1], why, again])
	check("each ability: once, then 'Already used this turn.', then free on the next turn (wrong: %s)" % ", ".join(bad), bad.is_empty())
	# before the roll, and before scoring
	var s = sg(["pride", "", "", ""])
	Rules.use(s, "hubris")
	check("Hubris twice before one roll", Rules.block(s, "hubris") == "Already used this turn." and Rules.use(s, "hubris").is_empty())
	s = sg(["", "envy", "", ""], [6, 1, 1])
	play(s)
	Rules.use(s, "glance", {"target": 0, "index": 0})
	check("Green-Eyed Glance twice before one roll", Rules.block(s, "glance") == "Already used this turn." and s.seats[1].glance == 6)
	s = sg(["", "lust", "", ""], [6, 5, 1,  1, 2, 3])
	play(s)
	Rules.roll(s)
	Rules.use(s, "whisper", {"mine": 0, "target": 0, "theirs": 0})
	check("Whisper of Desire is used for the turn", s.seats[1].used.has("whisper"))
	# a copy counts as a use of that ability by the player whose turn it is
	s = sg(["wrath", "envy", "", ""], [6, 6, 1])
	rolled(s)
	Rules.pass_turn(s)
	Rules.add_points(s, 1, 400)
	s.t1_log.append({"turn": s.turn_count, "key": "spark"})
	rolled(s)
	check("a copied ability is marked used for the copier's turn", not Rules.use(s, "grasp", {"key": "spark", "target": 0, "index": 0}).is_empty() and s.seats[1].used.has("spark") and s.seats[1].used.has("grasp"))
	# Wrath's Spark of Rage on another player's turn is not a use on Wrath's own turn
	s = sg(["wrath", "", "", ""], [4, 4, 4,  6, 6, 1])
	play(s)
	Rules.roll(s)
	check("Spark of Rage out of turn stays once a round", not Rules.use(s, "spark", {"by": 0, "target": 1, "index": 0}).is_empty() and Rules.block(s, "spark", {"by": 0, "target": 1, "index": 1}) == "Once a round." and not s.seats[0].used.has("spark"))
	Rules.pass_turn(s)
	play(s, 2)
	rolled(s)
	check("and on Wrath's next turn it can be used", Rules.block(s, "spark", {"target": 1, "index": 1}) == "")
	# the passives are unchanged
	s = sg(["", "greed", "", ""], [6, 6, 6])
	rolled(s)
	Rules.buy(s, 1)
	check("The Vig pays for the die, as before", s.seats[1].points == 20)
	# not the same target twice running still holds
	s = sg(["gluttony", "", "", ""])
	Rules.add_points(s, 0, 400)
	Rules.add_points(s, 1, 100)
	rolled(s)
	Rules.use(s, "bite", {"target": 1})
	Rules.pass_turn(s)
	play(s, 3)
	rolled(s)
	check("not the same target twice running still holds", Rules.block(s, "bite", {"target": 1}) == "Not the same target twice running." and Rules.block(s, "bite", {"target": 2}) == "")


func test_spark() -> void:
	# Wrath 4,4,4; seat 1 rolls 6,5,1 (110); the 6 is rerolled to a 2
	var s = sg(["wrath", "", "", ""], [4, 4, 4,  6, 5, 1,  2])
	play(s)
	Rules.roll(s)
	check("Spark of Rage needs a die showing 5 or 6", Rules.block(s, "spark", {"by": 0, "target": 1, "index": 2}) != "" and Rules.use(s, "spark", {"by": 0, "target": 1, "index": 2}).is_empty())
	var r: Dictionary = Rules.use(s, "spark", {"by": 0, "target": 1, "index": 0})
	check("Spark of Rage, out of turn: the 6 is rerolled", r.get("ok", false) and r.was == 6 and r.face == 2 and s.seats[1].last_roll == [2, 5, 1])
	check("it came up 1-3: they score 0 for it and lose 10 (110 - 60 - 10 = 40)", s.seats[1].points == 40 and r.change == -60 and r.lost == 10 and s.seats[1].last_score == 50)
	check("at most once a round", Rules.block(s, "spark", {"by": 0, "target": 1, "index": 1}) == "Once a round.")
	play(s, 3)
	# Wrath's own turn: a new round; the 5 is rerolled to the script's end, a 4
	rolled(s)
	r = Rules.use(s, "spark", {"target": 1, "index": 1})
	check("a new round at Wrath's turn: the 5 is rerolled to a 4, which scores 40 in its place", r.get("ok", false) and r.face == 4 and r.change == -10 and r.lost == 0)
	check("on Wrath's own turn it is used once", s.seats[0].used_t1 and Rules.block(s, "spark", {"target": 2}) == "Already used this turn.")
	s = sg(["wrath", "", "", ""], [1, 1, 1,  6, 6, 6])
	play(s)
	Rules.roll(s)
	check("in Purgatory Wrath cannot use it", Rules.use(s, "spark", {"by": 0, "target": 1, "index": 0}).is_empty() and Rules.block(s, "spark", {"by": 0}) == "No abilities in Purgatory.")
	check("no one but Wrath can use it", Rules.use(s, "spark", {"by": 2, "target": 1, "index": 0}).is_empty())


func test_strike() -> void:
	var s = sg(["wrath", "", "", ""])
	Rules.add_points(s, 0, 400)
	Rules.add_points(s, 1, 100)
	rolled(s)
	var r: Dictionary = Rules.use(s, "strike", {"target": 1, "choice": "points"})
	check("Vengeful Strike costs 50; the target chose to lose 50", r.get("ok", false) and s.seats[0].points == 470 and s.seats[1].points == 50 and r.paid == 50)
	play(s, 0)
	Rules.pass_turn(s)
	play(s, 3)
	rolled(s)
	check("not the same target twice running", Rules.block(s, "strike", {"target": 1}) == "Not the same target twice running.")
	r = Rules.use(s, "strike", {"target": 2, "choice": "die"})
	check("the target chose to give a die: Wrath holds 4, the target 2", r.get("ok", false) and s.seats[0].dice == 4 and s.seats[0].held == 1 and s.seats[2].dice == 2 and Rules.total_dice(s) == 18)
	Rules.pass_turn(s)
	play(s, 3)
	check("the target rolled 2 dice", s.seats[2].last_roll.size() == 2)
	rolled(s)
	check("Wrath rolls 4 dice", s.seats[0].last_roll.size() == 4)
	check("the same target can be struck after another was", Rules.block(s, "strike", {"target": 1}) == "")
	s.seats[3].dice = 2
	s.supply += 1
	check("a target on 2 dice cannot choose to give a die", Rules.block(s, "strike", {"target": 3, "choice": "die"}).contains("below 2") and Rules.block(s, "strike", {"target": 3, "choice": "points"}) == "")
	Rules.pass_turn(s)
	play(s, 3)
	rolled(s)
	check("the die is still with Wrath for a second round", s.seats[0].last_roll.size() == 4 and s.seats[2].last_roll.size() == 2)
	Rules.pass_turn(s)
	check("after 2 full rounds the die goes back", s.seats[0].dice == 3 and s.seats[0].held == 0 and s.seats[2].dice == 3 and s.loans.is_empty())
	s = sg(["wrath", "", "", ""])
	Rules.add_points(s, 0, 400)
	Rules.add_points(s, 1, 20)
	rolled(s)
	Rules.use(s, "strike", {"target": 1, "choice": "points"})
	check("a loss stops at 0: a target on 20 loses 20", s.seats[1].points == 0)


func test_vig() -> void:
	var s = sg(["", "greed", "", ""], [6, 6, 6])
	rolled(s)
	Rules.buy(s, 1)
	check("The Vig: an opponent buys a die, Greed gains 20", s.seats[1].points == 20 and s.seats[0].points == 160)
	Rules.gift(s, Rules.DIE, 0, 2)
	check("a die bought for another player: the buyer pays, Greed gains 20", s.seats[1].points == 40 and s.seats[0].points == 140)
	Rules.pass_turn(s)
	rolled(s)
	var before: int = s.seats[1].points
	Rules.buy(s, 1)
	check("Greed's own die pays no Vig", s.seats[1].points == before - 20)
	s = sg(["", "greed", "", ""], [6, 6, 6])
	s.seats[1].purgatory = true
	rolled(s)
	Rules.buy(s, 1)
	check("in Purgatory The Vig is off", s.seats[1].points == 0)
	check("The Vig is never a button", Rules.block(s, "vig", {"by": 1}) != "")


func test_deal() -> void:
	var s = sg(["greed", "", "", ""])
	Rules.add_points(s, 0, 400)
	Rules.add_points(s, 1, 80)
	Rules.add_points(s, 2, 30)
	s.seats[3].dice = 2
	s.supply += 1
	rolled(s)
	check("a target with under 50 points cannot choose to pay", Rules.block(s, "deal", {"target": 2, "choice": "points"}).contains("50"))
	check("a target with neither 50 points nor a spare die cannot be chosen", Rules.block(s, "deal", {"target": 3}).contains("neither"))
	var r: Dictionary = Rules.use(s, "deal", {"target": 1, "choice": "points"})
	check("Cut a Deal costs 70; the target chose to pay Greed 50", r.get("ok", false) and s.seats[0].points == 500 and s.seats[1].points == 30)
	Rules.pass_turn(s)
	play(s, 3)
	rolled(s)
	check("not the same target twice running", Rules.block(s, "deal", {"target": 1}) == "Not the same target twice running.")
	r = Rules.use(s, "deal", {"target": 2, "choice": "die"})
	check("the target chose to give a die", r.get("ok", false) and s.seats[0].dice == 4 and s.seats[2].dice == 2)
	Rules.pass_turn(s)
	play(s, 3)
	rolled(s)
	check("Greed rolls it once", s.seats[0].last_roll.size() == 4 and s.seats[2].last_roll.size() == 2)
	Rules.pass_turn(s)
	check("after 1 full round the die goes back", s.seats[0].dice == 3 and s.seats[2].dice == 3 and s.loans.is_empty())


func test_whisper() -> void:
	# seat 0 rolls 6,5,1 (110); Lust rolls 1,2,3
	var s = sg(["", "lust", "", ""], [6, 5, 1,  1, 2, 3,  1, 2, 3])
	play(s)
	var r: Dictionary = Rules.roll(s)
	check("Lust's roll waits before scoring when a swap can be made", r.get("pending", false) and s.phase == Rules.SWAP and s.seats[1].points == 0)
	check("their die must be higher", Rules.use(s, "whisper", {"mine": 1, "target": 0, "theirs": 2}).is_empty())
	r = Rules.use(s, "whisper", {"mine": 0, "target": 0, "theirs": 0})
	check("Whisper of Desire: Lust's 1 for their 6", r.get("ok", false) and s.seats[1].last_roll == [6, 2, 3] and s.seats[0].last_roll == [1, 5, 1])
	check("then the roll is scored: not Purgatory, 60", not s.seats[1].purgatory and s.seats[1].points == 60 and s.phase == Rules.GAMBIT and r.scored == 60)
	check("the other player keeps what they scored", s.seats[0].points == 110)
	s = sg(["", "lust", "", ""], [6, 5, 1,  1, 2, 3])
	play(s)
	Rules.roll(s)
	Rules.settle(s)
	check("without the swap, 1, 2, 3 is Purgatory", s.seats[1].purgatory and s.phase == Rules.END)
	s = sg(["lust", "", "", ""], [1, 2, 4])
	Rules.roll(s)
	check("no higher die on the table: the roll is scored at once", s.phase == Rules.GAMBIT and s.seats[0].points == 40)
	check("after scoring it is too late", Rules.block(s, "whisper") == "Before scoring.")


func test_allure() -> void:
	var s = sg(["lust", "", "", ""], [4, 4, 4])
	Rules.add_points(s, 0, 400)
	rolled(s)
	check("the chosen players must have rolled", Rules.block(s, "allure", {"a": 1, "b": 2}) == "They have not rolled yet.")
	Rules.pass_turn(s)
	s.rng.queue = [5, 5, 2,  5, 3, 3,  4, 4, 4,  1, 1, 4]
	play(s, 3)
	rolled(s)
	var before: int = s.seats[0].points
	check("two different other players", Rules.block(s, "allure", {"a": 1, "b": 1}) != "" and Rules.block(s, "allure", {"a": 0, "b": 1}) != "")
	var r: Dictionary = Rules.use(s, "allure", {"a": 1, "b": 2, "pick_a": 2, "pick_b": 0})
	check("Entangling Allure costs 40", r.get("ok", false) and s.seats[0].points == before - 40)
	check("a 2 and a 5 do not match: they swap", not r.match and s.seats[1].last_roll == [5, 5, 5] and s.seats[2].last_roll == [2, 3, 3])
	check("the swap changes no one's points", s.seats[1].points == 100 and s.seats[2].points == 50)
	Rules.pass_turn(s)
	play(s, 3)
	s.seats[1].last_roll = [5, 5, 2]
	s.seats[2].last_roll = [5, 3, 3]
	rolled(s)
	r = Rules.use(s, "allure", {"a": 1, "b": 2, "pick_a": 0, "pick_b": 0, "take": 2})
	check("a 5 and a 5 match: Lust takes one of them, to keep", r.get("ok", false) and r.match and r.take == 2 and s.seats[0].dice == 4 and s.seats[2].dice == 2 and s.seats[2].last_roll == [3, 3] and s.seats[1].dice == 3)
	check("still 18 dice in all", Rules.total_dice(s) == 18)
	s.seats[0].used_t2 = false
	s.seats[0].used = {}
	check("a player on 2 dice cannot have theirs taken", Rules.block(s, "allure", {"a": 1, "b": 2, "take": 2}).contains("below 2"))


func test_glance() -> void:
	# seat 0 rolls 6,1,1; Envy rolls 1,2,3 with a temporary 6
	var s = sg(["", "envy", "", ""], [6, 1, 1,  1, 2, 3])
	Rules.roll(s)
	check("only before your own roll", Rules.block(s, "glance", {"by": 1, "target": 0, "index": 0}) == "Not your turn.")
	Rules.pass_turn(s)
	var r: Dictionary = Rules.use(s, "glance", {"target": 0, "index": 0})
	check("Green-Eyed Glance copies an opponent's 6", r.get("ok", false) and r.face == 6)
	r = Rules.roll(s)
	check("the roll has a temporary fourth die showing 6", s.seats[1].last_roll == [1, 2, 3, 6] and s.seats[1].points == 60 and not s.seats[1].purgatory)
	check("the opponent's die is untouched", s.seats[0].last_roll == [6, 1, 1])
	Rules.pass_turn(s)
	play(s, 3)
	Rules.roll(s)
	check("the die was for that roll only", s.seats[1].last_roll.size() == 3 and s.seats[1].dice == 3)
	check("after the roll it is too late", Rules.block(s, "glance", {"target": 0}) != "")


func test_grasp() -> void:
	# Gluttony rolls 6,4,1 and feasts; Pride declares Hubris; Envy rolls 5,4,1
	var s = sg(["gluttony", "pride", "envy", ""], [6, 4, 1,  4, 4, 4,  5, 4, 1])
	rolled(s)
	Rules.use(s, "feast", {"index": 0})
	Rules.pass_turn(s)
	Rules.use(s, "hubris")
	play(s)
	Rules.add_points(s, 2, 400)
	rolled(s)
	check("Jealous Grasp sees the Tier 1 abilities used this round", Rules.grasp_seen(s).has("feast") and Rules.grasp_seen(s).has("hubris"))
	check("Hubris cannot be copied after the roll", Rules.block(s, "grasp", {"key": "hubris"}).contains("too late"))
	check("an ability no one used this round cannot be copied", Rules.block(s, "grasp", {"key": "spark"}) == "Not used this round.")
	var r: Dictionary = Rules.use(s, "grasp", {"key": "feast", "index": 0})
	check("Jealous Grasp costs 30 and copies Feast: a 5 to the supply for 150", r.get("ok", false) and r.copied == "feast" and s.seats[2].points == 490 + 150 - 30 and s.seats[2].dice == 2 and s.seats[2].last_roll == [4, 1])
	check("at most once a turn", Rules.block(s, "grasp") == "Already used this turn.")
	Rules.pass_turn(s)
	play(s)
	s.rng.queue = [6, 6, 4]
	s.seats[0].dice = 3
	s.supply -= 1
	rolled(s)
	Rules.use(s, "feast", {"index": 0})
	Rules.pass_turn(s)
	play(s)
	s.seats[2].dice = 3
	s.supply -= 1
	rolled(s)
	check("not the same one twice running", Rules.block(s, "grasp", {"key": "feast"}) == "Not the same one twice running." and Rules.block(s, "grasp") != "")
	# copies of Slow Drip, Spark of Rage and Whisper of Desire
	s = sg(["sloth", "envy", "", ""], [4, 1, 1,  4, 1, 1])
	play(s)
	Rules.add_points(s, 1, 400)
	rolled(s)
	r = Rules.use(s, "grasp", {"key": "drip"})
	check("a copied Slow Drip: Envy scored 40 this turn and gains 40", r.get("ok", false) and s.seats[1].points == 440 + 40 - 30)
	s = sg(["wrath", "envy", "", "lust"], [6, 5, 1,  4, 4, 4,  4, 4, 4,  2, 2, 4])
	play(s)
	play(s, 2)
	Rules.roll(s)
	Rules.use(s, "whisper", {"mine": 0, "target": 0, "theirs": 0})   # Lust's 2 for Wrath's 6
	Rules.pass_turn(s)
	s.rng.queue = [4, 5, 4]
	rolled(s)
	Rules.use(s, "spark", {"target": 3, "index": 0})   # the script is over: the 6 comes up 4
	Rules.pass_turn(s)
	Rules.add_points(s, 1, 400)
	s.rng.queue = [1, 4, 4,  2]
	rolled(s)
	var mine: int = s.seats[1].points
	r = Rules.use(s, "grasp", {"key": "whisper", "mine": 0, "target": 0, "theirs": 1})
	check("a copied Whisper of Desire after scoring: Envy's 1 for a 5, and the roll scores 50 more", r.get("ok", false) and s.seats[1].last_roll == [5, 4, 4] and s.seats[1].points == mine - 30 + 50 and s.seats[0].last_roll[1] == 1)
	Rules.pass_turn(s)
	play(s, 3)
	s.rng.queue = [4, 4, 4,  2]
	s.seats[2].last_roll = [6, 4, 4]
	s.seats[2].last_score = 140
	s.seats[2].points = 140
	s.t1_log.append({"turn": s.turn_count, "key": "spark"})
	rolled(s)
	r = Rules.use(s, "grasp", {"key": "spark", "target": 2, "index": 0})
	check("a copied Spark of Rage: their 6 comes up 2, they lose 60 and 10 more", r.get("ok", false) and r.face == 2 and s.seats[2].points == 70)


func test_hubris() -> void:
	var s = sg(["pride", "", "", ""], [6, 1, 1])
	var r: Dictionary = Rules.use(s, "hubris")
	check("Hubris is declared before the roll; the first player must beat 50", r.get("ok", false) and r.beat == 50)
	r = Rules.roll(s)
	check("60 beats 50: the roll scores 50 more, 110", r.hubris == "won" and s.seats[0].points == 110 and s.seats[0].last_score == 110)
	check("the Hubris card says the number the rules use", Sins.card("hubris").text.contains("score %d more" % int(s.cfg.hubris_win_add)) and int(s.cfg.hubris_win_pct) == 100)
	check("after the roll it is too late", Rules.block(s, "hubris") != "")
	s = sg(["pride", "", "", ""], [5, 1, 1])
	Rules.use(s, "hubris")
	r = Rules.roll(s)
	check("50 does not beat 50: the roll scores 0, and it is not Purgatory", r.hubris == "lost" and s.seats[0].points == 0 and not s.seats[0].purgatory and s.phase == Rules.GAMBIT)
	# the player before Pride scored 150
	s = sg(["", "", "", "pride"], [4, 4, 4,  4, 4, 4,  6, 5, 4,  6, 6, 4,  4, 4, 4,  4, 4, 4,  1, 1, 1,  4, 1, 1])
	play(s, 3)
	check("what Hubris must beat is what the player before scored on their last roll", Rules.hubris_target(s) == 150)
	Rules.use(s, "hubris")
	r = Rules.roll(s)
	check("160 beats 150: 210", r.hubris == "won" and r.beat == 150 and s.seats[3].points == 210)
	Rules.pass_turn(s)
	play(s, 3)
	check("a player before in Purgatory scored 0", s.seats[2].purgatory and Rules.hubris_target(s) == 0)
	Rules.use(s, "hubris")
	Rules.roll(s)
	check("40 beats 0: 90", s.seats[3].points == 300)
	# Wrath rerolls a die of a won Hubris roll: the die counts once, and the 50 stays
	s = sg(["pride", "wrath", "", ""], [6, 6, 1,  2])
	Rules.use(s, "hubris")
	Rules.roll(s)
	r = Rules.use(s, "spark", {"by": 1, "target": 0, "index": 0})
	check("Spark of Rage on a won Hubris: 170, less the 6 and 10 more, is 100", r.get("ok", false) and r.change == -60 and s.seats[0].points == 100 and s.seats[0].last_score == 110)
	s = sg(["pride", "", "", ""], [1, 2, 3])
	Rules.use(s, "hubris")
	r = Rules.roll(s)
	check("Hubris and a roll of 1, 2, 3: Purgatory as usual", s.seats[0].purgatory and s.seats[0].points == 0)
	play(s, 0)
	Rules.pass_turn(s)
	play(s, 3)
	check("no Hubris in Purgatory", Rules.use(s, "hubris").is_empty())


func test_superiority() -> void:
	var s = sg(["gluttony", "pride", "sloth", ""])
	for i in 3:
		Rules.add_points(s, i, 400)
	play(s)
	rolled(s)
	var r: Dictionary = Rules.use(s, "superiority")
	check("Superiority costs 40 and is armed", r.get("ok", false) and s.seats[1].armed and s.seats[1].points == 400 + 120 - 40)
	check("it cannot be armed twice", Rules.block(s, "superiority") != "")
	Rules.pass_turn(s)
	rolled(s)
	var sloth: int = s.seats[2].points
	r = Rules.use(s, "aura", {"target": 1})
	check("the first to target Pride loses 20", r.superiority == [1] and s.seats[2].points == sloth - 30 + 10 - 20 and not s.seats[1].armed)
	Rules.pass_turn(s)
	play(s)
	rolled(s)
	var glut: int = s.seats[0].points
	r = Rules.use(s, "bite", {"target": 1})
	check("the second in the same round loses nothing", r.superiority == [] and s.seats[0].points == glut - 20 + 20)
	Rules.pass_turn(s)
	rolled(s)
	Rules.use(s, "superiority")
	Rules.pass_turn(s)
	play(s, 3)
	check("it lasts until Pride's next turn", not s.seats[1].armed)
	s = sg(["gluttony", "pride", "", ""])
	Rules.add_points(s, 0, 400)
	s.seats[1].armed = true
	s.seats[1].purgatory = true
	rolled(s)
	r = Rules.use(s, "bite", {"target": 1})
	check("in Purgatory Superiority is off", r.superiority == [] and s.seats[1].armed)


func test_feast() -> void:
	var s = sg(["gluttony", "", "", ""], [6, 4, 1])
	check("Feast is for after the roll", Rules.block(s, "feast") == "After your roll.")
	rolled(s)
	check("the die must show 4, 5 or 6", Rules.use(s, "feast", {"index": 2}).is_empty())
	var r: Dictionary = Rules.use(s, "feast", {"index": 0})
	check("Feast: the 6 goes to the supply for 150", r.get("ok", false) and s.seats[0].points == 250 and s.seats[0].dice == 2 and s.supply == 7 and s.seats[0].last_roll == [4, 1])
	check("still 18 dice in all", Rules.total_dice(s) == 18)
	check("once a round", Rules.block(s, "feast") == "Already used this turn.")
	Rules.pass_turn(s)
	play(s, 3)
	rolled(s)
	check("no one goes below 2 dice", Rules.block(s, "feast").contains("below 2") and Rules.use(s, "feast", {"index": 0}).is_empty())
	s = sg(["gluttony", "", "", ""], [1, 2, 3])
	s.seats[0].purgatory = true
	rolled(s)
	check("an escape roll of 1, 2, 3 has no scoring die to give", Rules.block(s, "feast").contains("4, 5 or 6"))


func test_bite() -> void:
	var s = sg(["gluttony", "", "", ""])
	Rules.add_points(s, 0, 400)
	Rules.add_points(s, 1, 100)
	Rules.add_points(s, 2, 10)
	rolled(s)
	var r: Dictionary = Rules.use(s, "bite", {"target": 1})
	check("Voracious Bite costs 20 and steals 20", r.get("ok", false) and r.stolen == 20 and s.seats[0].points == 520 and s.seats[1].points == 80)
	Rules.pass_turn(s)
	play(s, 3)
	rolled(s)
	check("not the same target twice running", Rules.block(s, "bite", {"target": 1}) == "Not the same target twice running.")
	var mine: int = s.seats[0].points
	var theirs: int = s.seats[2].points
	r = Rules.use(s, "bite", {"target": 2})
	check("a target cannot lose more than they have", r.stolen == mini(20, theirs) and s.seats[0].points == mine - 20 + r.stolen)
	Rules.pass_turn(s)
	play(s, 3)
	rolled(s)
	check("the first target can be bitten again after another", Rules.block(s, "bite", {"target": 1}) == "")
	check("no biting yourself", Rules.block(s, "bite", {"target": 0}) != "")


func test_drip() -> void:
	var s = sg(["sloth", "", "", ""], [4, 1, 1,  4, 4, 4,  4, 4, 4,  4, 4, 4,  6, 1, 1,  4, 4, 4,  4, 4, 4,  4, 4, 4,  1, 1, 1])
	var r: Dictionary = Rules.roll(s)
	check("Slow Drip: a roll of 40 gains 40 more", r.drip and s.seats[0].points == 80)
	Rules.pass_turn(s)
	play(s, 3)
	r = Rules.roll(s)
	check("a roll of 60 is not under 60", not r.drip and s.seats[0].points == 140)
	Rules.pass_turn(s)
	play(s, 3)
	r = Rules.roll(s)
	check("a roll into Purgatory gains nothing", not r.drip and s.seats[0].points == 140 and s.seats[0].purgatory)


func test_aura() -> void:
	# Sloth rolls 4,4,4; seat 1's first die is rolled twice (6 then 2), then 5, 5
	var s = sg(["sloth", "", "", ""], [4, 4, 4,  6, 2, 5, 5])
	Rules.add_points(s, 0, 400)
	rolled(s)
	var r: Dictionary = Rules.use(s, "aura", {"target": 1})
	check("Lethargic Aura costs 30 and Sloth gains 10", r.get("ok", false) and s.seats[0].points == 500 and s.seats[1].lethargic)
	Rules.pass_turn(s)
	r = Rules.roll(s)
	check("next turn the target rolls one die twice and keeps the lower: 6 and 2 make 2", r.aura and s.seats[1].last_roll == [2, 5, 5] and s.seats[1].points == 100)
	Rules.pass_turn(s)
	play(s, 3)
	r = Rules.roll(s)
	check("the turn after is a plain roll", not r.aura and s.seats[1].last_roll == [4, 4, 4])


## Whole matches on seeded dice with the Sins dealt: seats buy, give and use abilities at random, allowed or not.
## Each ends in a winner and no rule is broken on the way.
func test_full_match() -> void:
	var rng := RandomNumberGenerator.new()
	var broken := []
	var rounds := []
	var purgatories := 0
	var used := {}
	for seed_value in 300:
		rng.seed = seed_value
		# the matches that use abilities play to 3000, long enough for every ability to come up; the plain ones play to the goal as built
		var s = Rules.new_match(Config.merged({"win": 3000} if seed_value % 3 > 0 else {}), rng)
		var turns := 0
		while s.winner == -1 and turns < 5000:
			turns += 1
			if seed_value % 3 > 0:
				_fuzz(s, rng, used)
			var r: Dictionary = Rules.roll(s)
			if s.phase == Rules.SWAP:
				var pairs: Array = Rules.whisper_pairs(s, s.turn)
				var pr: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
				if rng.randi_range(0, 1) == 0 and not Rules.use(s, "whisper", {"mine": pr[0], "target": pr[1], "theirs": pr[2]}).is_empty():
					used["whisper"] = true
				else:
					Rules.settle(s)
			if s.seats[s.turn].purgatory:
				purgatories += 1
			if seed_value % 3 > 0:
				for i in 3:
					_fuzz(s, rng, used)
			if s.phase == Rules.GAMBIT and seed_value % 3 == 2:
				# gifts at random, allowed or not: a refused one must change nothing
				var other: int = (s.turn + 1 + rng.randi_range(0, 2)) % 4
				var pair := [s.turn, other] if rng.randi_range(0, 1) == 0 else [other, s.turn]
				Rules.gift(s, [Rules.POINTS, Rules.LEND, Rules.DIE][rng.randi_range(0, 2)], pair[0], pair[1], rng.randi_range(0, 8) * 10)
			if s.phase == Rules.GAMBIT and rng.randi_range(0, 2) == 0:
				Rules.buy(s, rng.randi_range(1, 2))
			if Rules.total_dice(s) != 18:
				broken.append("seed %d: %d dice" % [seed_value, Rules.total_dice(s)])
			for p in s.seats:
				if p.points < 0 or p.dice < 2 or p.dice - p.held < 2 or s.supply < 0 or p.held < 0:
					broken.append("seed %d: points %d, dice %d, held %d, supply %d" % [seed_value, p.points, p.dice, p.held, s.supply])
			if s.winner == -1:
				Rules.pass_turn(s)
		if s.winner == -1:
			broken.append("seed %d: no winner" % seed_value)
		elif s.seats[s.winner].points < int(s.cfg.win) or s.winner != s.turn or s.seats[s.winner].purgatory:
			broken.append("seed %d: a wrong winner" % seed_value)
		rounds.append(s.round_number)
	check("300 seeded matches each play to one winner with no rule broken (%s)" % ("none" if broken.is_empty() else ", ".join(broken.slice(0, 5))), broken.is_empty())
	check("Purgatory happens in play (%d times)" % purgatories, purgatories > 0)
	var missing := []
	for k in Rules.NEEDS:
		if not used.has(k) and not Sins.PASSIVE.has(k):
			missing.append(k)
	check("every ability with a button was used in those matches (never: %s)" % ", ".join(missing), missing.is_empty())
	var plain := 0
	var wild := 0
	for i in rounds.size():
		if i % 3 == 0:
			plain += rounds[i]
		else:
			wild += rounds[i]
	print("game_test: match length in rounds: to the goal as built with no abilities used %.1f (100 matches); to 3000 with abilities at random %.1f (200 matches)" % [plain / 100.0, wild / 200.0])


## One ability at random with choices at random, by the player whose turn it is or (Spark of Rage) by Wrath.
func _fuzz(s, rng, used: Dictionary) -> void:
	var keys: Array = Rules.NEEDS.keys()
	var key: String = keys[rng.randi_range(0, keys.size() - 1)]
	var a := {}
	var n: int = s.seats.size()
	for need in Rules.NEEDS[key]:
		match need:
			"target", "a", "b":
				a[need] = rng.randi_range(0, n - 1)
			"index", "mine", "theirs", "pick_a", "pick_b":
				a[need] = rng.randi_range(0, 3)
			"choice":
				a[need] = ["points", "die"][rng.randi_range(0, 1)]
			"key":
				a[need] = Sins.GRASP_OK[rng.randi_range(0, Sins.GRASP_OK.size() - 1)]
				for sub in Rules.NEEDS[a[need]]:
					a[sub] = rng.randi_range(0, 3)
	if key == "spark" and rng.randi_range(0, 1) == 0:
		for i in n:
			if s.seats[i].sin == "wrath":
				a["by"] = i
	if not Rules.use(s, key, a).is_empty():
		used[key] = true
		if key == "grasp":
			used["grasp:" + a.key] = true
