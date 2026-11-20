## The bag hand's rules (docs/superpowers/specs/2026-11-20-bag-hand-design.md).
## godot --headless --path . --script res://tests/hand_test.gd
extends SceneTree

const Config = preload("res://hand/config.gd")
const Rules = preload("res://hand/rules.gd")
const Play = preload("res://hand/play.gd")
const Policies = preload("res://hand/policies.gd")

var _fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_fails += 1


func _init() -> void:
	test_layout()
	test_draw_and_skulls()
	test_ward_cancels()
	test_dance()
	test_hunger()
	test_curse()
	test_curse_ladder_six()
	test_moves()
	test_place_returns_dice()
	test_ladder_doubles()
	test_hold()
	test_offering_and_reveal()
	test_prize_and_marks()
	test_second_wire_and_tax()
	test_tax_lands_on_two_die_slot()
	test_tax_unmeets()
	test_all_skulls_ends()
	test_last_placement()
	test_play_terminates()
	test_same_hand_per_policy()
	test_greedy_beats_random()
	test_push_finishes()
	test_strong_dedupes()
	test_strong_plays()
	test_push_seeds_prize()
	test_held_on_all_skulls()
	test_ward_dance_no_second_dance()
	print("hand_test: %d failure(s)" % _fails)
	quit(1 if _fails > 0 else 0)


## A fake RNG that returns queued faces from randi_range.
class FixedRng:
	var queue: Array = []
	func _init(faces: Array) -> void:
		queue = faces.duplicate()
	func randi_range(_a: int, _b: int) -> int:
		return queue.pop_front()


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


## A fresh hand whose table is the Target, the Offering, the given engine kinds and a hidden Pair,
## with the given wires dealt and none left to deal.
func _table(engines: Array, wire_kinds: Array):
	var s = Rules.new_hand(Config.merged({}), _rng(1))
	s.slots = [Rules._slot("target", int(s.cfg.target), 0, 0), Rules._slot("offering", 0, 0, 0)]
	for k in engines:
		s.slots.append(Rules._slot(k, 0, 1 if k == "hold" else 2, 0))
	s.slots.append(Rules._slot("pair", 0, 2, int(s.cfg.pair_marks)))
	s.slots[-1].hidden = true
	s.wires = wire_kinds.map(func(k): return {"kind": k, "slot": -1})
	s.wire_pool = []
	return s


func _moves_to(moves: Array, slot: int) -> Array:
	return moves.filter(func(m): return m.slot == slot)


func test_layout() -> void:
	var cfg := Config.merged({})
	var s = Rules.new_hand(cfg, _rng(7))
	var kinds: Array = s.slots.map(func(x): return x.kind)
	check("layout: target, offering, 2 engines, 1 prize", kinds.size() == 5 and kinds[0] == "target" and kinds[1] == "offering"
		and kinds[2] in ["hold", "ward", "ladder"] and kinds[3] in ["hold", "ward", "ladder"] and kinds[2] != kinds[3] and kinds[4] in ["pair", "sum"])
	check("layout: the prize is face down", s.slots[4].hidden)
	check("layout: a full bag, one wire", s.bag == 8 and s.skulls == 0 and s.wires.size() == 1 and s.wire_pool.size() == 2)
	check("layout: Target needs 16", Rules.need(s) == 16)
	var t = Rules.new_hand(Config.merged({"wire_pool": "tax", "engine_pool": "hold,ladder"}), _rng(3))
	check("layout: a starting Tax sits on the Ladder", t.wires[0].kind == "tax" and t.slots[t.wires[0].slot].kind == "ladder")
	var c = s.clone()
	c.slots[2].dice.append(3)
	c.wire_pool.clear()
	check("state: clone deep-copies slots and wires", s.slots[2].dice.is_empty() and s.wire_pool.size() == 2)


func test_draw_and_skulls() -> void:
	var s = _table(["ward", "ladder"], [])
	var f: Array = Rules.throw(s, FixedRng.new([1, 4, 6]))
	check("throw: draws 3, a skull stays", f == [4, 6] and s.skulls == 1 and s.bag == 5 and s.throws == 1)
	var b = _table(["ward", "ladder"], [])
	b.skulls = 2
	Rules.throw(b, FixedRng.new([1, 4, 6]))
	check("throw: the third skull busts", b.outcome == "bust" and b.skulls == 3)


func test_ward_cancels() -> void:
	var s = _table(["ward", "ladder"], [])
	s.slots[2].dice = [3, 3]
	s.skulls = 2
	Rules.throw(s, FixedRng.new([1, 5, 2]))
	check("ward: cancels the skull and empties, the skull goes back", s.outcome == "" and s.skulls == 2 and s.slots[2].dice.is_empty() and s.bag == 6 and s.cancelled == 1)
	var t = _table(["ward", "ladder"], [])
	t.slots[2].dice = [3, 3]
	Rules.throw(t, FixedRng.new([1, 1, 4]))
	check("ward: cancels only the first skull", t.skulls == 1 and t.cancelled == 1)


func test_dance() -> void:
	var s = _table(["ward", "ladder"], [])
	s.bag = 1
	var f: Array = Rules.throw(s, FixedRng.new([3]))
	check("dance: the last die alone doubles", f == [3] and s.dance and s.dance_reached and Rules.value(s, 3, false) == 6 and Rules.value(s, 3, true) == 3)
	var t = _table(["ward", "ladder"], [])
	t.bag = 1
	Rules.throw(t, FixedRng.new([1]))
	check("dance: a skull busts outright", t.outcome == "bust")
	var w = _table(["ward", "ladder"], [])
	w.bag = 1
	w.slots[2].dice = [4, 4]
	Rules.throw(w, FixedRng.new([1]))
	check("dance: a full Ward cancels the Dance's skull", w.outcome == "" and w.cancelled == 1)
	var u = _table(["ward", "ladder"], [])
	u.bag = 2
	Rules.throw(u, FixedRng.new([4, 5]))
	check("dance: emptying a bag of 2 is not a dance", not u.dance and u.bag == 0)


func test_hunger() -> void:
	var s = _table(["ward", "ladder"], ["hunger"])
	s.progress = 16
	var f: Array = Rules.throw(s, FixedRng.new([4, 4, 4, 4]))
	check("hunger: past the Target, draws 4", f.size() == 4 and s.hunger_on and s.bag == 4)
	var h = _table(["ward", "ladder"], ["hunger"])
	h.progress = 16
	h.bag = 1
	Rules.throw(h, FixedRng.new([4]))
	check("hunger: one die left is still the Dance", h.dance)


func test_curse() -> void:
	var s = _table(["hold", "ward"], ["curse"])
	s.slots[2].dice = [5]
	s.slots[3].dice = [4]
	Rules.throw(s, FixedRng.new([3, 3, 3, 2, 6]))
	check("curse: a held die rolling 2 is a skull and leaves Hold", s.skulls == 1 and s.slots[2].dice.is_empty() and s.curse_skulls == 1)
	check("curse: a waiting die takes its new face", s.slots[3].dice == [6])


func test_curse_ladder_six() -> void:
	var s = _table(["ladder", "ward"], ["curse"])
	s.slots[2].dice = [3]
	Rules.throw(s, FixedRng.new([4, 4, 4, 6]))
	check("curse: a lone 6 in the Ladder goes back to the bag", s.slots[2].dice.is_empty() and s.bag == 6)


func test_moves() -> void:
	var s = _table(["ward", "ladder"], [])
	var f: Array[int] = [6, 3]
	check("moves: a 6 can't start the Ladder", _moves_to(Rules.legal_moves(s, f), 3).map(func(m): return f[m.die]) == [3])
	s.slots[2].dice = [3]
	check("moves: Ward wants the matching face", _moves_to(Rules.legal_moves(s, f), 2).map(func(m): return f[m.die]) == [3])
	s.slots[3].dice = [3]
	check("moves: the Ladder wants a higher second die", _moves_to(Rules.legal_moves(s, f), 3).map(func(m): return f[m.die]) == [6])
	check("moves: the hidden prize takes nothing", _moves_to(Rules.legal_moves(s, f), 4).is_empty())
	check("moves: Target and Offering take any die", _moves_to(Rules.legal_moves(s, f), 0).size() == 2 and _moves_to(Rules.legal_moves(s, f), 1).size() == 2)


func test_place_returns_dice() -> void:
	var s = _table(["ward", "ladder"], [])
	s.bag = 5
	Rules.place(s, [6, 4, 2], {"die": 0, "slot": 0})
	check("place: the rest go back to the bag", s.progress == 6 and s.bag == 7)
	var d = _table(["ward", "ladder"], [])
	d.bag = 0
	d.dance = true
	d.slots[2].dice = [5]
	Rules.place(d, [3], {"die": -1, "slot": 0})
	check("place: an unplaced Dance die leaves the hand", d.bag == 0)


func test_ladder_doubles() -> void:
	var s = _table(["ladder", "ward"], [])
	s.slots[2].dice = [2, 5]
	Rules.place(s, [4], {"die": 0, "slot": 0})
	check("ladder: a full Ladder doubles the Target", s.progress == 8)
	s.dance = true
	Rules.place(s, [3], {"die": 0, "slot": 0})
	check("ladder: with the Dance, x4", s.progress == 20)


func test_hold() -> void:
	var s = _table(["hold", "ward"], [])
	s.slots[2].dice = [6]
	var f: Array[int] = [2, 3]
	var held: Array = Rules.legal_moves(s, f).filter(func(m): return m.die == -1)
	check("hold: the held die can go anywhere but Hold", held.size() > 0 and held.all(func(m): return m.slot != 2))
	s.bag = 4
	Rules.place(s, f, {"die": -1, "slot": 0})
	check("hold: placing it returns both thrown dice", s.progress == 6 and s.bag == 6 and s.slots[2].dice.is_empty())
	var e: Array[int] = []
	check("hold: an empty bag offers only the held die", Rules.legal_moves(s, e).is_empty())


func test_offering_and_reveal() -> void:
	var s = _table(["ward", "ladder"], [])
	s.progress = 15
	Rules.place(s, [4], {"die": 0, "slot": 1})
	check("offering: the Target needs 1 less, and meeting it reveals the prize", Rules.need(s) == 15 and Rules.target_met(s) and s.revealed and not s.slots[4].hidden)


func test_prize_and_marks() -> void:
	var s = _table(["ward", "ladder"], [])
	s.progress = 16
	Rules.place(s, [5], {"die": 0, "slot": 4})
	Rules.place(s, [5], {"die": 0, "slot": 4})
	Rules.cash_out(s)
	check("marks: a won hand with the Pair claimed", s.outcome == "won" and s.slots[4].done and Rules.marks(s) == 3 + 2)
	var b = _table(["ward", "ladder"], [])
	b.outcome = "bust"
	check("marks: a bust pays nothing", Rules.marks(b) == 0)


func test_second_wire_and_tax() -> void:
	var s = _table(["ladder", "ward"], [])
	s.wire_pool = ["tax"]
	Rules.place(s, [3], {"die": 0, "slot": 2})
	Rules.master_answer(s)
	check("wire: the first engine die deals Tax onto that slot", s.wires.size() == 1 and s.wires[0].kind == "tax" and s.wires[0].slot == 2 and not s.tax_on)
	Rules.place(s, [5], {"die": 0, "slot": 2})
	Rules.master_answer(s)
	check("tax: filling the slot raises the Target 3", s.tax_on and Rules.need(s) == 19)
	check("wire: no third wire", s.wires.size() == 1)


func test_tax_lands_on_two_die_slot() -> void:
	var s = _table(["hold", "ward"], [])
	s.wire_pool = ["tax"]
	Rules.place(s, [4], {"die": 0, "slot": 2})
	Rules.master_answer(s)
	check("tax: seeding Hold puts Tax on the other slot", s.wires[0].slot == 3)


func test_tax_unmeets() -> void:
	var s = _table(["ward", "ladder"], [])
	s.wires = [{"kind": "tax", "slot": 2}]
	s.progress = 16
	Rules.place(s, [3], {"die": 0, "slot": 2})
	s.hunger_on = true
	Rules.place(s, [3], {"die": 0, "slot": 2})
	Rules.master_answer(s)
	Rules.cash_out(s)
	check("tax: a late Tax un-meets the Target; the prize stays revealed", s.outcome == "short" and s.revealed and s.hunger_on)


func test_all_skulls_ends() -> void:
	var s = Play.play_hand(Config.merged({"skull_faces": 6}), Policies.random_policy(), _rng(1))
	check("play: an all-skull hand busts", s.outcome == "bust" and s.throws == 1)
	var w = Play.play_hand(Config.merged({"skull_faces": 6, "bust_at": 99}), Policies.random_policy(), _rng(1))
	check("play: skulls that never bust still end the hand", w.outcome == "short" and w.bag == 0)


func test_last_placement() -> void:
	var s = _table(["hold", "ward"], [])
	s.bag = 0
	s.slots[2].dice = [5]
	s.progress = 12
	Play.play_from(s, Policies.greedy_policy(), _rng(1), true)
	check("play: an empty bag gives the held die one last placement", s.progress == 17 and s.outcome == "won" and s.slots[2].dice.is_empty())


func test_play_terminates() -> void:
	for p in [Policies.random_policy(), Policies.greedy_policy()]:
		var ok := true
		for i in 500:
			var s = Play.play_hand(Config.merged({}), p, Play.hand_rng(1, i))
			if not s.outcome in ["won", "short", "bust"] or s.throws > 12:
				ok = false
		check("play: %s hands end" % p.name, ok)


func test_same_hand_per_policy() -> void:
	var a = Rules.new_hand(Config.merged({}), Play.hand_rng(1, 17))
	var b = Rules.new_hand(Config.merged({}), Play.hand_rng(1, 17))
	check("sim: hand 17 is the same table for every policy", a.slots.map(func(x): return x.kind) == b.slots.map(func(x): return x.kind) and a.wires == b.wires)


func _win_rate(policy: Dictionary, hands: int, seed_value: int) -> float:
	var won := 0
	for i in hands:
		if Play.play_hand(Config.merged({}), policy, Play.hand_rng(seed_value, i)).outcome == "won":
			won += 1
	return float(won) / hands


func _mean_marks(policy: Dictionary, hands: int, seed_value: int) -> float:
	var total := 0
	for i in hands:
		total += Rules.marks(Play.play_hand(Config.merged({}), policy, Play.hand_rng(seed_value, i)))
	return float(total) / hands


func test_greedy_beats_random() -> void:
	var g := _win_rate(Policies.greedy_policy(), 2000, 2)
	var r := _win_rate(Policies.random_policy(), 2000, 2)
	print("  greedy %.3f random %.3f" % [g, r])
	check("play: greedy wins more than random", g > r)


func test_push_finishes() -> void:
	var s = _table(["ward", "ladder"], [])
	s.slots[2].dice = [4]
	var f: Array[int] = [6, 4]
	var m: Dictionary = Policies.push_policy().choose.call(s, f, Rules.legal_moves(s, f), _rng(1))
	check("push: a die that fills the Ward goes there", m.slot == 2 and f[m.die] == 4)


func test_strong_dedupes() -> void:
	var s = _table(["ward", "ladder"], [])
	var f: Array[int] = [4, 4]
	var one: Array[int] = [4]
	Policies.strong_move(s, f, Rules.legal_moves(s, f), _rng(5), 8)
	check("strong: two dice of one face are one option per slot", s.decisions[-1].moves == Rules.legal_moves(s, one).size())


## Whether strong beats greedy is the sim's verdict (a design question), not a rules test: this checks strong plays legal,
## finished hands and reports the marks.
func test_strong_plays() -> void:
	var t0 := Time.get_ticks_msec()
	var ok := true
	for i in 40:
		var s = Play.play_hand(Config.merged({}), Policies.strong_policy(16), Play.hand_rng(3, i))
		if not s.outcome in ["won", "short", "bust"] or s.decisions.is_empty() and s.outcome != "bust":
			ok = false
	print("  strong %.2f greedy %.2f marks a hand (%.1f s)" % [_mean_marks(Policies.strong_policy(16), 60, 3), _mean_marks(Policies.greedy_policy(), 60, 3), (Time.get_ticks_msec() - t0) / 1000.0])
	check("strong: plays hands to an end and records its decisions", ok)


func test_push_seeds_prize() -> void:
	var s = _table(["ward", "ladder"], [])
	s.progress = 16
	s.revealed = true
	s.slots[4].hidden = false
	var f: Array[int] = [5, 3]
	var push := Policies.push_policy()
	var m: Dictionary = push.choose.call(s, f, Rules.legal_moves(s, f), _rng(1))
	check("push: past the Target, a die goes into the revealed prize", m.slot == 4)
	check("push: throws on while the prize is open", not push.stop.call(s, _rng(1)))
	s.slots[4].done = true
	check("push: stops once the prize is claimed", push.stop.call(s, _rng(1)))


func test_held_on_all_skulls() -> void:
	var s = _table(["hold", "ward"], [])
	s.cfg = Config.merged({"bust_at": 5})
	s.slots[2].dice = [5]
	s.progress = 12
	Play.play_from(s, Policies.greedy_policy(), FixedRng.new([1, 1, 1]), false)
	check("play: an all-skull throw can still play the held die", s.progress == 17 and s.outcome == "won" and s.skulls == 3)


func test_ward_dance_no_second_dance() -> void:
	var s = _table(["ward", "ladder"], [])
	s.bag = 1
	s.slots[2].dice = [4, 4]
	Rules.throw(s, FixedRng.new([1]))
	check("dance: a Ward-cancelled Dance skull leaves the hand (no second Dance)", s.outcome == "" and s.bag == 0)
