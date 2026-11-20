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
