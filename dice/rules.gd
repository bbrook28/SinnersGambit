## Dice poker's rules (docs/superpowers/specs/2026-11-20-dice-poker-pitch.md). No UI; static functions over dice/state.gd.
extends RefCounted

const State = preload("res://dice/state.gd")

const HANDS := ["High die", "Pair", "Two pair", "Three of a kind", "Straight", "Full house", "Four of a kind", "Five of a kind"]


static func new_hand(cfg: Dictionary, rng):
	var s = State.new()
	s.cfg = cfg
	s.rng = rng
	s.bag = int(cfg.bag)
	return s


## Dice the next throw draws.
static func next_draw(s) -> int:
	return mini(int(s.cfg.draw), s.bag)


## The next throw is the Last Dance: the bag's last die, thrown alone.
static func is_dance(s) -> bool:
	return s.bag == 1


static func can_throw(s) -> bool:
	return not s.over and s.thrown.is_empty() and s.bag > 0 and s.row.size() < int(s.cfg.row)


static func throw(s) -> void:
	if not can_throw(s):
		return
	var n := next_draw(s)
	s.dance = is_dance(s)
	s.bag -= n
	s.throws += 1
	s.last_faces = []
	s.thrown = []
	var k := 0
	for i in n:
		var f: int = s.rng.randi_range(1, 6)
		s.last_faces.append(f)
		if f <= int(s.cfg.skull_faces):
			k += 1
		else:
			s.thrown.append(f)
	s.skulls += k
	if s.skulls >= int(s.cfg.bust_at) or (s.dance and k > 0):
		s.thrown = []
		s.over = true
		s.busted = true
		s.marks = 0
		return
	if s.dance:
		s.thrown = []
		s.row.append(0)
		_settle(s)
	elif s.thrown.size() == 1:
		keep(s, 0)
	else:
		_settle(s)


## Keep thrown die i in the row; the others go back into the bag.
static func keep(s, i: int) -> void:
	if s.over or i < 0 or i >= s.thrown.size():
		return
	s.row.append(s.thrown[i])
	s.bag += s.thrown.size() - 1
	s.thrown = []
	_settle(s)


## The hand is paid: the row's best poker hand.
static func _pay_out(s) -> void:
	s.over = true
	s.marks = score(s.cfg, s.row).marks


## A full row or an empty bag ends the hand and pays it.
static func _settle(s) -> void:
	if s.thrown.is_empty() and (s.row.size() >= int(s.cfg.row) or s.bag == 0):
		_pay_out(s)


static func pay(cfg: Dictionary, hand: int) -> int:
	return int(str(cfg.pay).split(",")[hand])


## The best poker hand in a row: {hand, name, marks}. A 0 is wild and takes its best face.
static func score(cfg: Dictionary, row: Array) -> Dictionary:
	var w := row.find(0)
	if w >= 0:
		var best := {}
		for f in range(int(cfg.skull_faces) + 1, 7):
			var r := row.duplicate()
			r[w] = f
			var sc := score(cfg, r)
			if best.is_empty() or sc.marks > best.marks or (sc.marks == best.marks and sc.hand > best.hand):
				best = sc
		return best
	var h := _classify(row)
	return {"hand": h, "name": HANDS[h], "marks": pay(cfg, h)}


static func _classify(row: Array) -> int:
	var counts := {}
	for f in row:
		counts[f] = counts.get(f, 0) + 1
	var c: Array = counts.values()
	c.sort()
	c.reverse()
	if c.is_empty():
		return 0
	if c[0] >= 5:
		return 7
	if c[0] == 4:
		return 6
	if c[0] == 3 and c.size() > 1 and c[1] == 2:
		return 5
	if row.size() == 5 and counts.size() == 5 and row.max() - row.min() == 4:
		return 4
	if c[0] == 3:
		return 3
	if c[0] == 2 and c.size() > 1 and c[1] == 2:
		return 2
	if c[0] == 2:
		return 1
	return 0


## What keeping thrown die i would make of the row.
static func preview(s, i: int) -> Dictionary:
	return score(s.cfg, s.row + [s.thrown[i]])


## The chance the next throw busts you.
static func bust_chance(s) -> float:
	var n := next_draw(s)
	if n <= 0:
		return 0.0
	var p := float(int(s.cfg.skull_faces)) / 6.0
	if is_dance(s):
		return 1.0 - pow(1.0 - p, n)
	var need: int = int(s.cfg.bust_at) - s.skulls
	var total := 0.0
	for k in range(maxi(need, 0), n + 1):
		total += _choose(n, k) * pow(p, k) * pow(1.0 - p, n - k)
	return total


static func _choose(n: int, k: int) -> float:
	var r := 1.0
	for i in k:
		r = r * (n - i) / (i + 1)
	return r
