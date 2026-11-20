## The bag hand's rules (docs/superpowers/specs/2026-11-20-bag-hand-design.md).
## godot --headless --path . --script res://tests/hand_test.gd
extends SceneTree

const Config = preload("res://hand/config.gd")
const Rules = preload("res://hand/rules.gd")

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
