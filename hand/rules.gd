## The bag hand's rules (docs/superpowers/specs/2026-11-20-bag-hand-design.md). No UI; static functions over hand_state.gd.
extends RefCounted

const HandState = preload("res://hand/hand_state.gd")

const ENGINES := ["hold", "ward", "ladder"]


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
	s.slots.append(_slot("target", int(cfg.target), 0, 0))
	s.slots.append(_slot("offering", 0, 0, 0))
	var engines := _pool(cfg.engine_pool)
	for i in mini(int(cfg.engines), engines.size()):
		var k := _draw(engines, rng)
		s.slots.append(_slot(k, 0, 1 if k == "hold" else 2, 0))
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
		if seeded >= 0 and s.slots[seeded].kind in ["ward", "ladder"]:
			at = seeded
		else:
			for j in s.slots.size():
				if s.slots[j].kind in ["ward", "ladder"]:
					at = j
					break
	s.wires.append({"kind": kind, "slot": at})


## What the Target needs now: its number, plus a fired Tax, minus Offerings.
static func need(s: HandState) -> int:
	return int(s.cfg.target) + (int(s.cfg.tax) if s.tax_on else 0) - s.offerings


static func _has_wire(s: HandState, kind: String) -> bool:
	return s.wires.any(func(w): return w.kind == kind)


static func _ward_full(s: HandState) -> int:
	for j in s.slots.size():
		if s.slots[j].kind == "ward" and s.slots[j].dice.size() >= 2:
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
		s.bag += 1
		s.cancelled += 1
		return
	s.skulls += 1
	if s.skulls >= int(s.cfg.bust_at) or dance_die:
		s.outcome = "bust"


## Draws a handful from the bag and throws it; returns the non-skull faces. Under Curse, every die
## waiting alone in an engine slot is rethrown too. Skulls land handful first, then cursed dice.
static func throw(s: HandState, rng) -> Array[int]:
	if _has_wire(s, "hunger") and target_met(s):
		s.hunger_on = true
	var n := mini(int(s.cfg.hunger_handful if s.hunger_on else s.cfg.handful), s.bag)
	s.dance = n == 1 and s.bag == 1
	if s.dance:
		s.dance_reached = true
	s.bag -= n
	s.throws += 1
	var kept: Array[int] = []
	var skulls := 0
	for i in n:
		var f: int = rng.randi_range(1, 6)
		if f <= int(s.cfg.skull_faces):
			skulls += 1
		else:
			kept.append(f)
	var curse_skulls := 0
	if _has_wire(s, "curse"):
		for slot in s.slots:
			if slot.kind in ENGINES and slot.dice.size() == 1:
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
	return kept


## A die's worth: doubled on the Last Dance, unless it is the held die.
static func value(s: HandState, face: int, from_hold: bool) -> int:
	return face * 2 if s.dance and not from_hold else face


static func target_met(s: HandState) -> bool:
	return s.progress >= need(s)
