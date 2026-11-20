## The core hand's rules as static functions over hand/hand_state.gd. No UI.
## rng is duck-typed: only randi_range(a, b) is called, so tests can queue faces.
extends RefCounted

const HandState = preload("res://hand/hand_state.gd")


static func _slot(kind: String, need: int, cap: int, countdown: int, marks: int) -> Dictionary:
	return {"kind": kind, "need": need, "dice": [], "cap": cap, "countdown": countdown, "marks": marks, "done": false, "gone": false, "hidden": false}


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
				s.slots[-1].hidden = cfg.get("prizes_after_target", false)
			"sum":
				s.slots.append(_slot("sum", cfg.sum_need, 2, cfg.sum_countdown, cfg.sum_marks))
				s.slots[-1].hidden = cfg.get("prizes_after_target", false)
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


## In play: not stopped or claimed, not gone, and not still hidden (prizes_after_target).
static func _live(slot: Dictionary) -> bool:
	return not slot.done and not slot.gone and not slot.get("hidden", false)


## Whether a die of this face may go in this slot now.
static func _fits(s: HandState, slot: Dictionary, face: int) -> bool:
	if not _live(slot):
		return false
	var v := value(s, face)
	match slot.kind:
		"target", "offering":
			return true
		"threat", "reroll":
			return v >= slot.need
		"pair":
			return slot.dice.is_empty() or int(slot.dice[0]) == face
		"sum":
			if slot.dice.is_empty():
				return slot.need - v >= 2
			return int(slot.dice[0]) + v == slot.need
	return false


## Every legal move for these faces: {die, slot, bump}. Offering moves name the countdown they raise (-1: none).
static func legal_moves(s: HandState, faces: Array[int]) -> Array:
	var moves: Array = []
	var bumps: Array = []
	for j in s.slots.size():
		if _live(s.slots[j]) and s.slots[j].countdown >= 0:
			bumps.append(j)
	if bumps.is_empty():
		bumps = [-1]
	for d in faces.size():
		for j in s.slots.size():
			if not _fits(s, s.slots[j], faces[d]):
				continue
			if s.slots[j].kind == "offering":
				for b in bumps:
					moves.append({"die": d, "slot": j, "bump": b})
			else:
				moves.append({"die": d, "slot": j, "bump": -1})
	return moves


## Puts one die in a slot. Placing the last die in hand cashes out.
static func place(s: HandState, faces: Array[int], move: Dictionary) -> void:
	var face: int = faces[move.die]
	var v := value(s, face)
	var slot: Dictionary = s.slots[move.slot]
	s.in_hand -= 1
	match slot.kind:
		"target":
			s.progress += v
			if target_met(s):
				for sl in s.slots:
					sl.hidden = false  # the Master reveals his prizes once the Target is met
		"offering":
			if move.bump >= 0:
				s.slots[move.bump].countdown += 1
		"threat":
			slot.done = true
		"reroll":
			slot.done = true
			s.rerolls += 1
		"pair", "sum":
			# a sum keeps values (a doubled die counts double); a pair keeps faces
			slot.dice.append(v if slot.kind == "sum" else face)
			if slot.dice.size() >= slot.cap:
				slot.done = true
	if s.in_hand <= 0 and s.outcome == "":
		cash_out(s)


## The Master answers a throw: countdowns drop; a threat at 0 strikes (a skull), a prize at 0 is taken.
static func master_answer(s: HandState) -> void:
	for slot in s.slots:
		if not _live(slot) or slot.countdown <= 0:
			continue
		slot.countdown -= 1
		if slot.countdown == 0:
			slot.gone = true
			slot.dice = []
			if slot.kind == "threat":
				s.skulls += 1
				if s.skulls >= int(s.cfg.bust_at):
					s.outcome = "bust"
					return


static func target_met(s: HandState) -> bool:
	return s.progress >= int(s.slots[s.target_slot].need)


static func cash_out(s: HandState) -> void:
	s.outcome = "won" if target_met(s) else "short"


static func ended(s: HandState) -> bool:
	return s.outcome != ""


## 0 unless won; then the win marks plus every claimed prize's marks.
static func marks(s: HandState) -> int:
	if s.outcome != "won":
		return 0
	var m := int(s.cfg.win_marks)
	for slot in s.slots:
		if slot.done and not slot.gone and (slot.kind == "pair" or slot.kind == "sum"):
			m += int(slot.marks)
	return m
