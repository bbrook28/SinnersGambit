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
	print("hand_test: %d failure(s)" % _fails)
	quit(1 if _fails > 0 else 0)


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
