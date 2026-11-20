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
