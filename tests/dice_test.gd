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
	print("dice_test: %d failure(s)" % _fails)
	quit(1 if _fails > 0 else 0)


func test_score() -> void:
	var cfg := Config.merged({})
	var cases := [[[], "High die", 0], [[4], "High die", 0], [[4, 4], "Pair", 1],
		[[4, 4, 5, 5], "Two pair", 2], [[3, 3, 3], "Three of a kind", 3],
		[[2, 3, 4, 5, 6], "Straight", 5], [[6, 2, 5, 3, 4], "Straight", 5],
		[[2, 2, 3, 3, 3], "Full house", 5], [[5, 5, 5, 5, 2], "Four of a kind", 7],
		[[6, 6, 6, 6, 6], "Five of a kind", 12], [[2, 3, 4, 5, 5], "Pair", 1]]
	for c in cases:
		var sc: Dictionary = Rules.score(cfg, c[0])
		check("score %s is %s" % [c[0], c[1]], sc.name == c[1] and sc.marks == c[2])


func test_score_wild() -> void:
	var cfg := Config.merged({})
	check("wild makes a pair from a single", Rules.score(cfg, [4, 0]).name == "Pair")
	check("wild fills the straight", Rules.score(cfg, [2, 3, 5, 6, 0]).name == "Straight")
	check("wild takes the best hand: four over full house", Rules.score(cfg, [3, 3, 3, 2, 0]).name == "Four of a kind")
	check("wild alone is high die", Rules.score(cfg, [0]).name == "High die")


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
		and Rules.preview(s, 1).name == "High die")
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
