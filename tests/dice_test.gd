## Dice poker's rules (docs/superpowers/specs/2026-11-20-dice-poker-pitch.md).
## godot --headless --path . --script res://tests/dice_test.gd
extends SceneTree

const Config = preload("res://dice/config.gd")
const Rules = preload("res://dice/rules.gd")
const Policies = preload("res://dice/policies.gd")

var _fails := 0


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


func hand(faces: Array, over := {}):
	return Rules.new_hand(Config.merged(over), Faces.new(faces))


func _init() -> void:
	test_score()
	test_score_wild()
	test_keep_returns_the_other()
	test_lone_die_kept()
	test_two_skulls()
	test_bust()
	test_no_cash_out()
	test_full_row_cashes()
	test_last_dance_wild()
	test_last_dance_skull()
	test_bust_chance()
	test_preview()
	test_draw_choice()
	test_solver()
	test_policies_play()
	test_demand_faces()
	test_demand_wild()
	test_demand_wrath()
	test_demand_solver()
	print("dice_test: %d failure(s)" % _fails)
	quit(1 if _fails > 0 else 0)


func test_score() -> void:
	var cfg := Config.merged({})
	var cases := [[[], "No match", 0], [[4], "No match", 0], [[4, 4], "Pair", 1],
		[[4, 4, 5, 5], "Two pair", 2], [[3, 3, 3], "Three of a kind", 3],
		[[2, 3, 4, 5, 6], "Run", 5], [[6, 2, 5, 3, 4], "Run", 5],
		[[2, 2, 3, 3, 3], "Three and a pair", 5], [[5, 5, 5, 5, 2], "Four of a kind", 7],
		[[6, 6, 6, 6, 6], "Five of a kind", 12], [[2, 3, 4, 5, 5], "Pair", 1]]
	for c in cases:
		var sc: Dictionary = Rules.score(cfg, c[0])
		check("score %s is %s" % [c[0], c[1]], sc.name == c[1] and sc.marks == c[2])


func test_score_wild() -> void:
	var cfg := Config.merged({})
	check("wild makes a pair from a single", Rules.score(cfg, [4, 0]).name == "Pair")
	check("wild fills the straight", Rules.score(cfg, [2, 3, 5, 6, 0]).name == "Run")
	check("wild takes the best hand: four over full house", Rules.score(cfg, [3, 3, 3, 2, 0]).name == "Four of a kind")
	check("wild alone is high die", Rules.score(cfg, [0]).name == "No match")


func test_keep_returns_the_other() -> void:
	var s = hand([3, 5])
	Rules.throw(s)
	check("two pips wait for a keep", s.thrown == [3, 5] and not Rules.can_throw(s))
	Rules.keep(s, 1)
	check("kept 5 in the row, the 3 went back", s.row == [5] and s.thrown.is_empty() and s.bag == 6)
	check("can throw again", Rules.can_throw(s) and s.throws == 1)


func test_lone_die_kept() -> void:
	var s = hand([1, 4])
	Rules.throw(s)
	check("skull stays and leaves the bag; the lone 4 is kept", s.skulls == 1 and s.row == [4] and s.bag == 5 and s.thrown.is_empty())
	check("last_faces shows both", s.last_faces == [1, 4])


func test_two_skulls() -> void:
	var s = hand([1, 1])
	Rules.throw(s)
	check("two skulls, nothing to keep, not bust", s.skulls == 2 and s.row.is_empty() and s.bag == 5 and not s.over and Rules.can_throw(s))


func test_bust() -> void:
	var s = hand([1, 1, 1, 5])
	Rules.throw(s)
	Rules.throw(s)
	check("third skull busts: nothing paid", s.over and s.busted and s.marks == 0 and s.skulls == 3)


func test_no_cash_out() -> void:
	var s = hand([4, 2, 4, 6, 3, 5, 2, 6, 5, 6])
	for i in 5:
		Rules.throw(s)
		Rules.keep(s, 0)
	check("the hand plays to a full row: a pair of 4s pays 1", s.over and s.row == [4, 4, 3, 2, 5] and s.marks == 1)
	check("there is no cash out", not (Rules.new() as Object).has_method("cash_out") and not (Rules.new() as Object).has_method("can_cash"))


func test_full_row_cashes() -> void:
	var s = hand([2, 2, 3, 3, 4, 4, 5, 5, 6, 6])
	for i in 5:
		Rules.throw(s)
		if not s.over:
			Rules.keep(s, 0)
	check("a full row cashes out by itself: straight 5", s.over and s.row == [2, 3, 4, 5, 6] and s.marks == 5)


func test_last_dance_wild() -> void:
	var s = hand([4, 2, 1, 1, 4, 3, 4], {"bag": 5})  # 5 dice so the Last Dance comes on the fourth throw
	Rules.throw(s)          # 4,2: keep 4, bag 4
	Rules.keep(s, 0)
	Rules.throw(s)          # 1,1: two skulls, bag 2
	Rules.throw(s)          # 4,3: keep 4, bag 1
	Rules.keep(s, 0)
	check("a one-die bag throws one die", Rules.next_draw(s) == 1 and Rules.is_dance(s))
	Rules.throw(s)          # 4: wild
	check("the Last Dance die is wild and the bag is empty: cashed", s.dance and s.row == [4, 4, 0] and s.over and s.marks == 3)


func test_last_dance_skull() -> void:
	var s = hand([1], {"bag": 1})
	Rules.throw(s)
	check("a skull on the Last Dance busts outright", s.over and s.busted and s.skulls == 1)


func test_bust_chance() -> void:
	var s = hand([])
	check("no skulls: no bust risk", is_equal_approx(Rules.bust_chance(s), 0.0))
	s.skulls = 1
	check("one skull: both dice skulls, 1/36", is_equal_approx(Rules.bust_chance(s), 1.0 / 36.0))
	s.skulls = 2
	check("two skulls: 11/36", is_equal_approx(Rules.bust_chance(s), 11.0 / 36.0))
	s.skulls = 0
	s.bag = 1
	check("the Last Dance: 1/6", is_equal_approx(Rules.bust_chance(s), 1.0 / 6.0))


func test_preview() -> void:
	var s = hand([4, 6, 4, 2])
	Rules.throw(s)
	Rules.keep(s, 0)
	Rules.throw(s)
	check("preview shows what each keep makes", Rules.preview(s, 0).name == "Pair" and Rules.preview(s, 0).marks == 1
		and Rules.preview(s, 1).name == "No match")
	check("preview changes nothing", s.row == [4] and s.thrown == [4, 2])


func test_solver() -> void:
	var cfg := Config.merged({})
	var sol = Policies.Solver.new(cfg)
	check("a full row is worth its pay", is_equal_approx(sol.value([2, 3, 4, 5, 6], 0, 3), 5.0))
	var start: float = sol.value([], 0, int(cfg.bag))
	check("the start is worth more than nothing (%.3f)" % start, start > 0.5)
	check("a pair with two skulls is worth less than with none", sol.value([4, 4], 2, 3) < sol.value([4, 4], 0, 5))


func test_policies_play() -> void:
	var cfg := Config.merged({})
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var ok := true
	for p in [Policies.random_policy(), Policies.greedy_policy(), Policies.strong_policy(cfg)]:
		for i in 50:
			var s = Rules.new_hand(cfg, rng)
			var r: Dictionary = Policies.play(s, p)
			ok = ok and s.over and r.throws >= 1 and r.throws <= 20
	check("every policy finishes its hands", ok)


func test_draw_choice() -> void:
	var s = hand([5, 1, 3])
	check("you may draw 1, 2 or 3", Rules.draw_options(s) == [1, 2, 3])
	Rules.throw(s, 3)
	check("three drawn: a skull, and 5 and 3 wait", s.last_faces == [5, 1, 3] and s.skulls == 1 and s.thrown == [5, 3] and s.bag == 4)
	Rules.keep(s, 0)
	check("the 3 goes back", s.row == [5] and s.bag == 5)
	s.skulls = 1
	check("three dice with one skull: 16/216", is_equal_approx(Rules.bust_chance(s, 3), 16.0 / 216.0))
	s.bag = 2
	check("no more than the bag holds", Rules.draw_options(s) == [1, 2])
	s.bag = 1
	check("a one-die bag: the Last Dance only", Rules.draw_options(s) == [1])


func test_demand_faces() -> void:
	var pride := Config.merged({"demand": "pride"})
	var t: Dictionary = Rules.total(pride, [6, 3, 3, 4, 5], 0)
	check("Pride: a lone 6 pays 4 on a pair: 5 in all", t.name == "Pair" and t.marks == 1 and t.sin == 4 and t.total == 5)
	t = Rules.total(pride, [6, 6, 3, 4, 5], 0)
	check("Pride: a second 6 and it pays nothing", t.marks == 1 and t.sin == 0 and t.total == 1)
	t = Rules.total(pride, [6, 2, 2, 4, 5], 0)
	check("Pride: each 2 costs 1", t.marks == 1 and t.sin == 2 and t.total == 3)
	t = Rules.total(pride, [2, 2, 3, 4, 5], 0)
	check("Pride: a pair of 2s pays 1, costs 2, never less than 0", t.marks == 1 and t.sin == -2 and t.total == 0)
	var envy := Config.merged({"demand": "envy"})
	t = Rules.total(envy, [6, 6, 5, 3, 3], 0)
	check("Envy still pays by the face: two 6s pay 2", t.marks == 2 and t.sin == 2 and t.total == 4)
	t = Rules.total(Config.merged({}), [6, 3, 3, 4, 5], 0)
	check("no Sin: the hand alone", t.marks == 1 and t.sin == 0 and t.total == 1 and t.wild_as == 0)
	var s = hand([6, 2], {"demand": "pride"})
	Rules.throw(s)
	check("Pride: the preview counts both", Rules.preview_total(s, 0).sin == 4 and Rules.preview_total(s, 1).sin == -1
		and Rules.preview(s, 0).marks == 0)
	check("Pride: a first 6 would add 4, a 2 would take 1", Rules.keep_delta(s, 0) == 4 and Rules.keep_delta(s, 1) == -1)
	s.row = [6]
	check("Pride: a second 6 would take the 4 back", Rules.keep_delta(s, 0) == -4)
	s.row = [6, 6]
	check("Pride: a third 6 changes nothing", Rules.keep_delta(s, 0) == 0)
	s = hand([6, 2, 3, 2, 3, 2, 4, 2, 5, 2], {"demand": "pride"})
	for i in 5:
		Rules.throw(s)
		Rules.keep(s, 0)
	check("Pride: a paid row pays hand and Sin (%d)" % s.marks, s.over and s.row == [6, 3, 3, 4, 5] and s.marks == 5)


func test_demand_wild() -> void:
	var pride := Config.merged({"demand": "pride"})
	var t: Dictionary = Rules.total(pride, [3, 3, 4, 0], 0)
	check("Pride: the wild is a lone 6 (pair 1 + 4), not a third 3 (3)", t.name == "Pair" and t.total == 5 and t.sin == 4 and t.wild_as == 6)
	t = Rules.total(pride, [6, 3, 0], 0)
	check("Pride: holding a 6, the wild pairs the 3 and leaves the 6 alone", t.name == "Pair" and t.total == 5 and t.wild_as == 3)
	t = Rules.total(pride, [4, 4, 4, 0], 0)
	check("Pride: four 4s (7) beat three 4s and a lone 6 (3 + 4): a tie goes to the better hand", t.name == "Four of a kind" and t.total == 7 and t.wild_as == 4)
	check("score still means the poker hand", Rules.score(pride, [3, 3, 4, 0]).name == "Three of a kind")


func test_demand_wrath() -> void:
	var s = hand([1, 1, 4, 5, 3], {"demand": "wrath"})
	Rules.throw(s)
	check("Wrath: nothing for a throw with no skulls showing", s.bank == 0 and s.skulls == 2)
	check("Wrath: two dice at two skulls would pay 2", Rules.throw_pays(s, 2) == 2 and Rules.throw_pays(s, 1) == 1)
	Rules.throw(s)
	check("Wrath: the throw is banked", s.bank == 2)
	s = hand([1, 1, 1, 5], {"demand": "wrath"})
	Rules.throw(s)
	Rules.throw(s)
	check("Wrath: a bust pays nothing, bank and all", s.busted and s.marks == 0 and s.bank == 2)
	s = hand([4], {"demand": "wrath", "bag": 1})
	s.skulls = 2
	check("Wrath: the Last Dance pays nothing", Rules.throw_pays(s, 1) == 0)
	s = hand([1, 1, 4, 5, 4, 6, 4, 4], {"demand": "wrath", "bag": 8})
	Rules.throw(s)          # two skulls, bag 6
	Rules.throw(s)          # 4,5 at two skulls: banks 2
	Rules.keep(s, 0)
	check("Wrath: one skull showing pays nothing", Rules.throw_pays(hand([], {"demand": "wrath"}), 3) == 0)
	check("Wrath: the total adds the bank", Rules.total(s.cfg, [4, 4], s.bank).total == 3 and Rules.total(s.cfg, [4, 4], s.bank).sin == 2)
	check("no Sin: no throw pays", Rules.throw_pays(hand([]), 3) == 0)
	var c = s.clone()
	check("a clone keeps the bank", c.bank == 2)


func test_demand_solver() -> void:
	var none = Policies.Solver.new(Config.merged({}))
	var start: float = none.value([], 0, 7)
	check("no Sin: best play is still worth 3.581 (%.3f)" % start, absf(start - 3.581) < 0.0005)
	var pride = Policies.Solver.new(Config.merged({"demand": "pride"}))
	check("Pride: a full row is worth hand and Sin", is_equal_approx(pride.value([6, 3, 3, 4, 5], 0, 2), 5.0))
	check("Pride: the start is worth more than with no Sin", pride.value([], 0, 7) > start + 1.0)
	var alone = Policies.Solver.new(Config.merged({"demand": "pride"}), true)
	check("the Sin alone: the hand is worth nothing, and a cost is not floored", is_equal_approx(alone.value([6, 3, 3, 4, 5], 0, 2), 4.0)
		and is_equal_approx(alone.value([2, 2, 3, 4, 5], 0, 2), -2.0))
	check("the Sin alone: its wild is a lone 6", is_equal_approx(alone.value([3, 3, 4, 0], 0, 0), 4.0))
	var wrath = Policies.Solver.new(Config.merged({"demand": "wrath"}))
	check("Wrath: a full row is worth its hand and its bank", is_equal_approx(wrath.value([4, 4, 2, 3, 5], 2, 0, 3), 4.0))
	check("Wrath: the bank is part of the state", wrath.value([4, 4], 2, 3, 2) > wrath.value([4, 4], 2, 3, 0) + 1.0)
	var s = hand([], {"demand": "wrath"})
	s.row = [4, 4, 4]
	s.skulls = 2
	s.bag = 2
	var p: Dictionary = Policies.strong_policy(s.cfg)
	check("Wrath: the solver weighs each draw with what it pays", p.solver.throw_value(s.row, 2, 2, 2, 0) != p.solver.throw_value(s.row, 2, 2, 1, 0)
		and p.draw.call(s) in [1, 2])
