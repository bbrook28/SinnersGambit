## The core hand's rules as static functions over hand/hand_state.gd. No UI.
## rng is duck-typed: only randi_range(a, b) is called, so tests can queue faces.
extends RefCounted

const HandState = preload("res://hand/hand_state.gd")


static func _slot(kind: String, need: int, cap: int, countdown: int, marks: int) -> Dictionary:
	return {"kind": kind, "need": need, "dice": [], "cap": cap, "countdown": countdown, "marks": marks, "done": false, "gone": false}


## The Master lays out a hand: the Target, the Offering, then cfg.extras kinds from cfg.extra_pool.
static func new_hand(cfg: Dictionary, rng) -> HandState:
	var s := HandState.new()
	s.cfg = cfg
	s.in_hand = cfg.dice
	s.slots.append(_slot("target", cfg.target, 0, -1, 0))
	s.slots.append(_slot("offering", 0, 0, -1, 0))
	var pool: Array = Array(str(cfg.extra_pool).split(","))
	for i in mini(cfg.extras, pool.size()):
		var kind: String = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		match kind:
			"threat":
				s.slots.append(_slot("threat", cfg.threat_need, 1, cfg.threat_countdown, 0))
			"pair":
				s.slots.append(_slot("pair", 0, 2, cfg.pair_countdown, cfg.pair_marks))
			"sum":
				s.slots.append(_slot("sum", cfg.sum_need, 2, cfg.sum_countdown, cfg.sum_marks))
			"reroll":
				s.slots.append(_slot("reroll", cfg.reroll_need, 1, cfg.reroll_countdown, 0))
	return s
