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


static func _is_skull(s: HandState, face: int) -> bool:
	return face <= int(s.cfg.skull_faces)


## A skull lands: it stays on the table and leaves your hand. Busts at bust_at, or on the Last Dance.
static func _land_skull(s: HandState) -> void:
	s.skulls += 1
	s.in_hand -= 1
	if s.skulls >= int(s.cfg.bust_at) or s.dance:
		s.outcome = "bust"


## Throws every die in hand; returns the non-skull faces. A one-die throw is the Last Dance.
static func throw(s: HandState, rng) -> Array[int]:
	s.throws += 1
	s.dance = s.in_hand == 1
	if s.dance:
		s.dance_reached = true
	var faces: Array[int] = []
	for i in s.in_hand:
		faces.append(rng.randi_range(1, 6))
	var kept: Array[int] = []
	for f in faces:
		if _is_skull(s, f):
			_land_skull(s)
		else:
			kept.append(f)
	return kept


static func is_dance(s: HandState) -> bool:
	return s.dance


## A face's worth: doubled on the Last Dance.
static func value(s: HandState, face: int) -> int:
	return face * 2 if s.dance else face


## Spends a reroll token to rethrow faces[index]; a skull follows the throw rules. Returns the new faces.
static func reroll(s: HandState, faces: Array[int], index: int, rng) -> Array[int]:
	var out: Array[int] = faces.duplicate()
	if s.rerolls <= 0 or index < 0 or index >= out.size():
		return out
	s.rerolls -= 1
	var f: int = rng.randi_range(1, 6)
	if _is_skull(s, f):
		out.remove_at(index)
		_land_skull(s)
	else:
		out[index] = f
	return out
