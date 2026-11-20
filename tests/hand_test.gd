## The core hand's rules (docs/superpowers/specs/2026-11-20-core-hand-design.md).
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
	test_new_hand_layout()
	test_skulls_leave_hand()
	test_third_skull_busts()
	test_dance_doubles_and_busts()
	test_reroll_skull_stays()
	test_threshold_and_dance()
	test_sum_exact()
	test_offering_without_countdowns()
	test_all_skulls_answer()
	test_strike_busts()
	test_marks()
	test_auto_cash_out()
	print("hand_test: %d failure(s)" % _fails)
	quit(1 if _fails > 0 else 0)


## A fake RNG that returns queued faces from randi_range.
class FixedRng:
	var queue: Array = []
	func _init(faces: Array) -> void:
		queue = faces.duplicate()
	func randi_range(_a: int, _b: int) -> int:
		return queue.pop_front()


func _hand():
	return Rules.new_hand(Config.merged({}), _rng(1))


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func test_new_hand_layout() -> void:
	var cfg := Config.merged({})
	var s = Rules.new_hand(cfg, _rng(7))
	check("layout: slot count", s.slots.size() == 2 + cfg.extras)
	check("layout: target first, need 12", s.slots[0].kind == "target" and s.slots[0].need == 12)
	check("layout: offering second", s.slots[1].kind == "offering")
	check("layout: fresh hand", s.in_hand == 5 and s.skulls == 0 and s.outcome == "")
	var t = Rules.new_hand(cfg, _rng(7))
	check("layout: reproducible", s.slots.map(func(x): return x.kind) == t.slots.map(func(x): return x.kind))
	var m := Config.merged({"target": 20})
	var same := true
	for k in Config.DEFAULTS:
		if k != "target" and m[k] != Config.DEFAULTS[k]:
			same = false
	check("config: override one key", m.target == 20 and same)


func test_skulls_leave_hand() -> void:
	var s = _hand()
	var f: Array = Rules.throw(s, FixedRng.new([1, 4, 6, 1, 3]))
	check("throw: skulls leave the hand", f == [4, 6, 3] and s.skulls == 2 and s.in_hand == 3 and s.outcome == "")


func test_third_skull_busts() -> void:
	var s = _hand()
	s.skulls = 2
	s.in_hand = 2
	Rules.throw(s, FixedRng.new([1, 5]))
	check("throw: third skull busts", s.outcome == "bust")


func test_dance_doubles_and_busts() -> void:
	var s = _hand()
	s.in_hand = 1
	var f: Array = Rules.throw(s, FixedRng.new([3]))
	check("dance: one die doubles", f == [3] and Rules.is_dance(s) and Rules.value(s, 3) == 6 and s.dance_reached)
	var t = _hand()
	t.in_hand = 1
	Rules.throw(t, FixedRng.new([1]))
	check("dance: a skull busts outright", t.outcome == "bust" and t.skulls == 1)


func test_reroll_skull_stays() -> void:
	var s = _hand()
	s.skulls = 2
	s.in_hand = 2
	s.rerolls = 1
	var f: Array = Rules.reroll(s, [5, 2], 1, FixedRng.new([1]))
	check("reroll: a skull stays and busts", s.outcome == "bust" and s.rerolls == 0 and f == [5] and s.skulls == 3)


## A hand whose table is the Target, the Offering and the given slots.
func _table(extra: Array):
	var s = _hand()
	s.slots = [Rules._slot("target", 12, 0, -1, 0), Rules._slot("offering", 0, 0, -1, 0)] + extra
	return s


func _moves_to(moves: Array, slot: int) -> Array:
	return moves.filter(func(m): return m.slot == slot)


func test_threshold_and_dance() -> void:
	var s = _table([Rules._slot("threat", 5, 1, 2, 0)])
	check("threat: 3 misses 5+", _moves_to(Rules.legal_moves(s, [3]), 2).is_empty())
	s.dance = true
	check("threat: a doubled 3 meets 5+", _moves_to(Rules.legal_moves(s, [3]), 2).size() == 1)
	var p = _table([Rules._slot("pair", 0, 2, 3, 2)])
	p.slots[2].dice = [4]
	check("pair: matches by face", _moves_to(Rules.legal_moves(p, [4]), 2).size() == 1)
	p.dance = true
	check("pair: a doubled 2 is not a 4", _moves_to(Rules.legal_moves(p, [2]), 2).is_empty())


func test_sum_exact() -> void:
	var s = _table([Rules._slot("sum", 8, 2, 3, 1)])
	check("sum: first 3 fits", _moves_to(Rules.legal_moves(s, [3]), 2).size() == 1)
	check("sum: first 7 leaves no second", _moves_to(Rules.legal_moves(s, [7]), 2).is_empty())
	s.slots[2].dice = [3]
	check("sum: 3 + 5 fits", _moves_to(Rules.legal_moves(s, [5]), 2).size() == 1)
	check("sum: 3 + 4 misses", _moves_to(Rules.legal_moves(s, [4]), 2).is_empty())


func test_offering_without_countdowns() -> void:
	var s = _table([])
	var off: Array = _moves_to(Rules.legal_moves(s, [4]), 1)
	check("offering: legal with no countdown", off.size() == 1 and off[0].bump == -1)


func test_all_skulls_answer() -> void:
	var s = _table([Rules._slot("threat", 5, 1, 2, 0)])
	check("all skulls: no move", Rules.legal_moves(s, []).is_empty())
	Rules.master_answer(s)
	check("all skulls: the Master still answers", s.slots[2].countdown == 1)


func test_strike_busts() -> void:
	var s = _table([Rules._slot("threat", 5, 1, 1, 0)])
	s.skulls = 2
	Rules.master_answer(s)
	check("strike: third skull busts", s.outcome == "bust" and s.skulls == 3 and s.slots[2].gone)


func test_marks() -> void:
	var s = _table([Rules._slot("pair", 0, 2, 3, 2), Rules._slot("sum", 8, 2, 3, 1)])
	s.progress = 12
	s.slots[2].done = true
	s.slots[3].gone = true
	Rules.cash_out(s)
	check("marks: win plus a claimed pair", s.outcome == "won" and Rules.marks(s) == 3 + 2)
	var b = _table([])
	b.outcome = "bust"
	check("marks: a bust pays nothing", Rules.marks(b) == 0)


func test_auto_cash_out() -> void:
	var s = _table([])
	s.in_hand = 2
	Rules.place(s, [6, 6], {"die": 0, "slot": 0, "bump": -1})
	check("place: hand continues", s.outcome == "" and s.progress == 6 and s.in_hand == 1)
	s.in_hand = 1
	Rules.place(s, [6], {"die": 0, "slot": 0, "bump": -1})
	check("place: last die cashes out", s.outcome == "won" and s.progress == 12)
