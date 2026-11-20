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
