## The bag hand's rules (docs/superpowers/specs/2026-11-20-bag-hand-design.md). No UI; static functions over hand_state.gd.
extends RefCounted

const HandState = preload("res://hand/hand_state.gd")

const ENGINES := ["hold", "ward", "ladder", "rites"]


static func _slot(kind: String, need: int, cap: int, marks: int) -> Dictionary:
	return {"kind": kind, "need": need, "cap": cap, "dice": [], "marks": marks, "done": false, "hidden": false, "fills": 0}


static func _pool(text) -> Array:
	return Array(str(text).split(",", false))


static func _draw(pool: Array, rng) -> String:
	return pool.pop_at(rng.randi_range(0, pool.size() - 1))


## The Master lays out a hand: the Target, the Offering, cfg.engines engine slots, one face-down prize, one wire.
static func new_hand(cfg: Dictionary, rng) -> HandState:
	var s := HandState.new()
	s.cfg = cfg
	s.bag = int(cfg.bag)
	s.slots.append(_slot("target", 0, 0, 0))
	s.slots.append(_slot("offering", 0, 0, 0))
	var engines := _pool(cfg.engine_pool)
	for i in mini(int(cfg.engines), engines.size()):
		var k := _draw(engines, rng)
		s.slots.append(_slot(k, 0, {"hold": 1, "rites": 1, "ward": int(cfg.ward_dice)}.get(k, 2), 0))
	var prizes := _pool(cfg.prize_pool)
	if not prizes.is_empty():
		var p := _draw(prizes, rng)
		if p == "pair":
			s.slots.append(_slot("pair", 0, 2, int(cfg.pair_marks)))
		else:
			s.slots.append(_slot("sum", int(cfg.sum_need), 2, int(cfg.sum_marks)))
		s.slots[-1].hidden = true
	s.wire_pool = _pool(cfg.wire_pool)
	if not s.wire_pool.is_empty():
		_deal_wire(s, _draw(s.wire_pool, rng), -1)
	return s


## Deals a wire. A Tax watches a Ward or Ladder: `seeded` if it is one, else the first on the table.
static func _deal_wire(s: HandState, kind: String, seeded: int) -> void:
	var at := -1
	if kind == "tax":
		if seeded >= 0 and _two_die(s.slots[seeded]):
			at = seeded
		else:
			for j in s.slots.size():
				if _two_die(s.slots[j]):
					at = j
					break
	s.wires.append({"kind": kind, "slot": at})


static func _ints(text) -> Array:
	return _pool(text).map(func(x): return int(x))


static func tiers(s: HandState) -> int:
	return _ints(s.cfg.tiers).size()


## What tier i (1-based) needs now: its number, plus a fired Tax, minus Offerings.
static func tier_need(s: HandState, i: int) -> int:
	return int(_ints(s.cfg.tiers)[i - 1]) + (int(s.cfg.tax) if s.tax_on else 0) - s.offerings


## What Tier 1, the win, needs now.
static func need(s: HandState) -> int:
	return tier_need(s, 1)


## The highest tier cleared now (0: none). A live check: a late Tax can drop it.
static func tier(s: HandState) -> int:
	var t := 0
	for i in range(1, tiers(s) + 1):
		if s.progress >= tier_need(s, i):
			t = i
	return t


## A Ward or Ladder that takes 2 dice: the only slots a Tax can watch.
static func _two_die(slot: Dictionary) -> bool:
	return slot.kind in ["ward", "ladder"] and int(slot.cap) >= 2


static func _has_wire(s: HandState, kind: String) -> bool:
	return s.wires.any(func(w): return w.kind == kind)


static func _ward_full(s: HandState) -> int:
	for j in s.slots.size():
		if s.slots[j].kind == "ward" and s.slots[j].dice.size() >= int(s.slots[j].cap):
			return j
	return -1


## A skull lands. A full Ward cancels it (the skull goes back to the bag, the Ward empties);
## otherwise it stays on the table. Busts at bust_at, or at once if it is the Dance die.
static func _land_skull(s: HandState, dance_die: bool) -> void:
	if s.outcome != "":
		return
	var w := _ward_full(s)
	if w >= 0:
		s.slots[w].dice = []
		if not dance_die:
			s.bag += 1  # a cancelled Dance die leaves the hand: there is no second Dance
		s.cancelled += 1
		return
	s.skulls += 1
	if s.skulls >= int(s.cfg.bust_at) or dance_die:
		s.outcome = "bust"
	elif s.rites_armed:
		s.outcome = "bust"
		s.rites_busts += 1
	elif s.cfg.get("skull_strips", false) and tier(s) >= 1 and not s.target_dice.is_empty():
		s.progress -= int(s.target_dice.pop_back())  # past Tier 1, the skull takes your last Target die (it leaves the hand)


## Draws a handful from the bag and throws it; returns the non-skull faces. Under Curse, every die
## waiting alone in an engine slot is rethrown too. Skulls land handful first, then cursed dice.
static func throw(s: HandState, rng) -> Array[int]:
	if _has_wire(s, "hunger") and tier(s) >= 2:
		s.hunger_on = true
	s.pushed = maxi(s.pushed, tier(s))
	s.throw_bag = s.bag
	var skull_face := int(s.cfg.skull_faces)
	if s.bag <= int(s.cfg.get("late_bag", 0)):
		s.late_on = true  # the late wire: checked before the draw
		skull_face = maxi(skull_face, int(s.cfg.late_skull_faces))
	var n := next_draw(s)
	s.dance = n == 1 and s.bag == 1
	if s.dance:
		s.dance_reached = true
		s.dances += 1
	s.bag -= n
	s.throws += 1
	var kept: Array[int] = []
	var skulls := 0
	for i in n:
		var f: int = rng.randi_range(1, 6)
		if f <= skull_face:
			skulls += 1
			if f > int(s.cfg.skull_faces):
				s.late_skulls += 1
		else:
			kept.append(f)
	var curse_skulls := 0
	for j in cursed(s):
		var slot: Dictionary = s.slots[j]
		var f: int = rng.randi_range(1, 6)
		if f <= int(s.cfg.curse_skull_faces):
			slot.dice = []
			curse_skulls += 1
		elif slot.kind == "ladder" and f >= 6:
			slot.dice = []
			s.bag += 1
		else:
			slot.dice = [f]
	for i in skulls:
		_land_skull(s, s.dance)
	for i in curse_skulls:
		s.curse_skulls += 1
		_land_skull(s, false)
	if s.rites_armed and s.outcome == "":
		s.rites_armed = false  # survived the throw: the Rites die banks
		s.progress += s.rites_pending
		s.target_dice.append(s.rites_pending)
		s.rites_pending = 0
		s.rites_banked += 1
		_reveal(s)
	return kept


## How many dice the next throw draws (Hunger counts once you are past Tier 2).
static func next_draw(s: HandState) -> int:
	var hungry: bool = s.hunger_on or (_has_wire(s, "hunger") and tier(s) >= 2)
	return mini(int(s.cfg.hunger_handful if hungry else s.cfg.handful), s.bag)


## The engine slots whose waiting die Curse throws again with the next handful (in slot order).
static func cursed(s: HandState) -> Array:
	var out: Array = []
	if _has_wire(s, "curse"):
		for j in s.slots.size():
			var slot: Dictionary = s.slots[j]
			if slot.kind in ENGINES and slot.dice.size() == 1 and (slot.kind == "hold" or int(slot.cap) >= 2):
				out.append(j)
	return out


class _Faces:
	var queue: Array = []
	func randi_range(_a: int, _b: int) -> int:
		return queue.pop_front()


## The chance that the next throw busts you: every skull pattern of the handful and the cursed dice,
## played through throw() itself on a copy, so the Ward, the Dance and every wire count exactly.
static func bust_chance(s: HandState) -> float:
	if s.bag <= 0 or s.outcome != "":
		return 0.0
	var n := next_draw(s)
	var k := cursed(s).size()
	var hand_faces := int(s.cfg.skull_faces)
	if s.bag <= int(s.cfg.get("late_bag", 0)):
		hand_faces = maxi(hand_faces, int(s.cfg.late_skull_faces))
	var p_hand := hand_faces / 6.0
	var p_curse := int(s.cfg.curse_skull_faces) / 6.0
	var total := 0.0
	for bits in 1 << (n + k):
		var w := 1.0
		var rng := _Faces.new()
		for i in n + k:
			var skull := (bits >> i) & 1 == 1
			var p := p_hand if i < n else p_curse
			w *= p if skull else 1.0 - p
			rng.queue.append(1 if skull else (4 if i < n else 3))
		if w <= 0.0:
			continue
		var c = s.clone()
		throw(c, rng)
		if c.outcome == "bust":
			total += w
	return total


## A die's worth: doubled on the Last Dance, unless it is the held die.
static func value(s: HandState, face: int, from_hold: bool) -> int:
	return face * 2 if s.dance and not from_hold else face


static func target_met(s: HandState) -> bool:
	return tier(s) >= 1


## The face waiting in Hold, or 0.
static func held(s: HandState) -> int:
	for slot in s.slots:
		if slot.kind == "hold" and not slot.dice.is_empty():
			return int(slot.dice[0])
	return 0


static func _ladder_full(s: HandState) -> bool:
	return s.slots.any(func(x): return x.kind == "ladder" and x.dice.size() >= 2)


static func _fits(s: HandState, slot: Dictionary, face: int, from_hold: bool) -> bool:
	var v := value(s, face, from_hold)
	match slot.kind:
		"target", "offering":
			return true
		"hold":
			return not from_hold and slot.dice.is_empty()
		"rites":
			return not from_hold and slot.dice.is_empty() and s.throw_bag <= int(s.cfg.rites_bag)
		"ward":
			if int(s.cfg.ward_cancels) > 0 and s.cancelled >= int(s.cfg.ward_cancels):
				return false  # spent: it has cancelled its skull this hand
			return slot.dice.is_empty() or (slot.dice.size() == 1 and int(slot.cap) >= 2 and absi(int(slot.dice[0]) - face) <= int(s.cfg.ward_spread))
		"ladder":
			if slot.dice.is_empty():
				return v <= 5
			return slot.dice.size() == 1 and v > int(slot.dice[0])
		"pair":
			if slot.hidden or slot.done:
				return false
			return slot.dice.is_empty() or int(slot.dice[0]) == face
		"sum":
			if slot.hidden or slot.done:
				return false
			if slot.dice.is_empty():
				return int(slot.need) - v >= 2
			return int(slot.dice[0]) + v == int(slot.need)
	return false


## Every legal placement: {die, slot}, die = an index into faces, or -1 for the held die.
static func legal_moves(s: HandState, faces: Array[int]) -> Array:
	var moves: Array = []
	for d in faces.size():
		for j in s.slots.size():
			if _fits(s, s.slots[j], faces[d], false):
				moves.append({"die": d, "slot": j})
	var h := held(s)
	if h > 0:
		for j in s.slots.size():
			if _fits(s, s.slots[j], h, true):
				moves.append({"die": -1, "slot": j})
	return moves


## Puts one die in a slot; the unplaced dice go back to the bag (on the Dance they leave the hand).
## Meeting the Target reveals the prize.
static func place(s: HandState, faces: Array[int], move: Dictionary) -> void:
	var from_hold: bool = move.die < 0
	var face: int
	if from_hold:
		face = held(s)
		for slot in s.slots:
			if slot.kind == "hold":
				slot.dice = []
	else:
		face = faces[move.die]
	var v := value(s, face, from_hold)
	var slot: Dictionary = s.slots[move.slot]
	match slot.kind:
		"target":
			var add := v * 2 if _ladder_full(s) else v
			s.progress += add
			s.target_dice.append(add)
		"offering":
			s.offerings += 1
		"rites":
			s.rites_pending = face * int(s.cfg.rites_mult)  # banks after a survived throw; instead of any doubling
			slot.dice.append(face)
			slot.fills += 1
			s.rites_armed = true
			if not s.seeded:
				s.seeded = true
				s.seed_slot = move.slot
		_:
			slot.dice.append(v if slot.kind in ["ladder", "sum"] else face)
			if slot.dice.size() >= int(slot.cap):
				slot.fills += 1
				if slot.kind in ["pair", "sum"]:
					slot.done = true
			if slot.kind in ENGINES and not s.seeded:
				s.seeded = true
				s.seed_slot = move.slot
	if not s.dance:
		s.bag += faces.size() if from_hold else faces.size() - 1
	_reveal(s)


static func _reveal(s: HandState) -> void:
	if target_met(s) and not s.revealed:
		s.revealed = true
		for x in s.slots:
			x.hidden = false


## The Master answers a placement: a Tax whose slot is full fires (for the rest of the hand);
## then, after your first engine die, he deals his second wire (which cannot fire on this answer).
static func master_answer(s: HandState) -> void:
	for w in s.wires:
		if w.kind == "tax" and w.slot >= 0:
			var slot: Dictionary = s.slots[w.slot]
			if slot.dice.size() >= int(slot.cap):
				s.tax_on = true
	if s.seeded and not s.second_wire and not s.wire_pool.is_empty():
		s.second_wire = true
		_deal_wire(s, s.wire_pool.pop_front(), s.seed_slot)


static func cash_out(s: HandState) -> void:
	s.outcome = "won" if target_met(s) else "short"


static func ended(s: HandState) -> bool:
	return s.outcome != ""


## 0 unless won; then the highest tier's marks (not summed) plus the prize's if it was claimed.
static func marks(s: HandState) -> int:
	if s.outcome != "won":
		return 0
	return tier_marks(s) + prize_marks(s)


## The marks of the highest tier cleared now (0 below Tier 1).
static func tier_marks(s: HandState) -> int:
	var t := tier(s)
	return 0 if t == 0 else int(_ints(s.cfg.tier_marks)[t - 1])


## The claimed prize's marks.
static func prize_marks(s: HandState) -> int:
	var m := 0
	for slot in s.slots:
		if slot.done and slot.kind in ["pair", "sum"]:
			m += int(slot.marks)
	return m
