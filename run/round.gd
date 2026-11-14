## One turn of keep-and-rethrow (Docs/RunDesign.md §3). Rules only, static functions on plain data,
## so the board, the bot and the sim all play through the same code.
##
## ctx (one turn's fixed facts, built by run_state.gd begin_turn):
##   cfg, sin (your kit), twist (the ruling Sin's name in its round, else ""), dice (the round's dice),
##   fx (relics.gd effective), owned (dice you own), gold, turns_left (after this one),
##   busted_rounds, carry_mult (Wrath's kit), last_bank (Pride's twist; -1 none)
## A die: {f: six face values, g: six 0/1 gild marks, c: six 0/1 crimson marks, r: repainted face indices}.
## Die index -1 is Ossuary's extra plain die.
##
## st (the turn so far, copied freely by the bot):
##   left (die indices to throw next), returned (every die came back already), p, m, throws,
##   holy (Holy Waters used), eaten, singles (kept a single), big / big_v (largest set kept: size, face),
##   roll_d / roll_f (this throw: die index and face index per position), bank_only (must Bank now)
extends RefCounted

const Relics = preload("res://run/relics.gd")
const Kits = preload("res://run/kits.gd")

const PLAIN := [1, 2, 3, 4, 5, 6]


static func plain_die() -> Dictionary:
	return {"f": PLAIN.duplicate(), "g": [0, 0, 0, 0, 0, 0], "c": [0, 0, 0, 0, 0, 0], "r": []}


static func new_turn(ctx: Dictionary) -> Dictionary:
	var left: Array = range(ctx.dice.size())
	for i in Relics.extra_first_dice(ctx.fx):
		left.append(-1)
	return {
		"left": left, "returned": false, "p": 0, "m": 1 + int(ctx.carry_mult), "throws": 0,
		"holy": 0, "eaten": false, "singles": false, "big": 0, "big_v": 0,
		"roll_d": [], "roll_f": [], "bank_only": false,
	}


static func face_of(ctx: Dictionary, d: int, fi: int) -> int:
	return PLAIN[fi] if d < 0 else ctx.dice[d].f[fi]


## Throws st.left. Returns the keepable groups; empty means a bust (after any Holy Water).
static func throw(ctx: Dictionary, st: Dictionary, rng: RandomNumberGenerator) -> Array:
	st.throws += 1
	_roll(st, rng)
	st.p += Relics.on_throw(ctx.fx, st)
	var gs := groups(ctx, st)
	while gs.is_empty() and st.holy < Relics.holy_waters(ctx.fx):
		st.holy += 1
		_roll(st, rng)
		gs = groups(ctx, st)
	return gs


static func _roll(st: Dictionary, rng: RandomNumberGenerator) -> void:
	var rd: Array = []
	var rf: Array = []
	for d in st.left:
		rd.append(d)
		rf.append(rng.randi_range(0, 5))
	st.roll_d = rd
	st.roll_f = rf


## Sets the throw by hand (tests, the tutorial card): faces as face indices 0-5.
static func set_roll(st: Dictionary, faces: Array) -> void:
	st.roll_d = st.left.duplicate()
	st.roll_f = faces.duplicate()


## The groups you may keep from this throw. Whole groups only: tapping a die keeps all dice of its face.
## Each: {kind: "set" | "single" | "beads", v, pos: roll positions, p, m}.
static func groups(ctx: Dictionary, st: Dictionary) -> Array:
	var fx: Dictionary = ctx.fx
	var cfg: Dictionary = ctx.cfg
	var by_v := [[], [], [], [], [], [], []]
	for i in st.roll_d.size():
		by_v[face_of(ctx, st.roll_d[i], st.roll_f[i])].append(i)
	var out: Array = []
	var beads: bool = fx.has("beads") and by_v[4].size() == 1 and by_v[5].size() == 1 and by_v[6].size() == 1
	for v in range(1, 7):
		var pos: Array = by_v[v]
		var c := pos.size()
		if c >= 2:
			var r := Relics.on_keep(fx, v, c, true)
			var g := {"kind": "set", "v": v, "pos": pos, "p": 5 * v * c + r[0], "m": Kits.set_mult(ctx.sin, c, cfg) + r[1]}
			_marks(ctx, st, g)
			out.append(g)
		elif c == 1 and not (beads and v >= 4) and Relics.single_ok(fx, v, cfg):
			var r := Relics.on_keep(fx, v, 1, false)
			var pts := 0 if ctx.twist == "Lust" else Relics.single_points(fx, v)
			var g := {"kind": "single", "v": v, "pos": pos, "p": pts + r[0], "m": r[1]}
			_marks(ctx, st, g)
			out.append(g)
	if beads:
		var g := {"kind": "beads", "v": 0, "pos": [by_v[4][0], by_v[5][0], by_v[6][0]], "p": 75, "m": 2}
		for v in [4, 5, 6]:
			var r := Relics.on_keep(fx, v, 1, false)
			g.p += r[0]
			g.m += r[1]
		_marks(ctx, st, g)
		out.append(g)
	return out


## Repainted marks on the kept faces: Gild +15 Points, Crimson +1 Mult.
static func _marks(ctx: Dictionary, st: Dictionary, g: Dictionary) -> void:
	for i in g.pos:
		var d: int = st.roll_d[i]
		if d < 0:
			continue
		var fi: int = st.roll_f[i]
		g.p += 15 * int(ctx.dice[d].g[fi])
		g.m += int(ctx.dice[d].c[fi])


## Roll positions no group holds (Gluttony may eat one of these).
static func unkeepable(st: Dictionary, gs: Array) -> Array:
	var held := {}
	for g in gs:
		for i in g.pos:
			held[i] = true
	var out: Array = []
	for i in st.roll_d.size():
		if not held.has(i):
			out.append(i)
	return out


static func can_eat(ctx: Dictionary, st: Dictionary) -> bool:
	return Kits.can_eat(ctx.sin) and not st.eaten


## Keeps the chosen groups (indices into gs), optionally eating one unkeepable die (roll position).
## Then st.left is what you would rethrow; st.bank_only means you must Bank.
## Returns the Mult Censer added (for the board's pops), or -1 if the keep is illegal.
static func keep(ctx: Dictionary, st: Dictionary, gs: Array, sel: Array, eat_pos := -1) -> int:
	if sel.is_empty():
		return -1
	var kept := {}
	for gi in sel:
		var g: Dictionary = gs[gi]
		st.p += g.p
		st.m += g.m
		if g.kind == "single":
			st.singles = true
		elif g.kind == "set":
			var c: int = g.pos.size()
			if c > st.big or (c == st.big and g.v > st.big_v):
				st.big = c
				st.big_v = g.v
		for i in g.pos:
			kept[i] = true
	if eat_pos >= 0:
		if not can_eat(ctx, st) or kept.has(eat_pos):
			return -1
		kept[eat_pos] = true
		st.eaten = true
	var n: int = st.roll_d.size()
	var unkept := n - kept.size()
	if ctx.twist == "Wrath":
		st.p = maxi(0, st.p - ctx.cfg.wrath_unkept * unkept)
	var censer := 0
	if unkept == 0:
		censer = Relics.on_keep_all(ctx.fx)
		st.m += censer
		if not st.returned:
			st.returned = true
			st.left = range(ctx.dice.size())
		else:
			st.bank_only = true
			st.left = []
	else:
		var left: Array = []
		for i in n:
			if not kept.has(i):
				left.append(st.roll_d[i])
		st.left = left
	st.roll_d = []
	st.roll_f = []
	return censer


## What a Bank would score now, without changing st: {score, gold, parts: [Points, Mult, x2 count], zeroed, halved}.
static func bank_value(ctx: Dictionary, st: Dictionary) -> Dictionary:
	var fx: Dictionary = ctx.fx
	var chal: int = fx.get("chalice", 0) if st.big >= 2 else 0
	var info := {
		"unkept": 0 if st.bank_only else st.left.size(), "owned": ctx.owned, "throws": st.throws,
		"turns_left": ctx.turns_left, "gold": ctx.gold, "busted_rounds": ctx.busted_rounds,
		"big_set": st.big + chal,
	}
	var r := Relics.on_bank(fx, info)
	var k := Kits.on_bank(ctx.sin, ctx.gold, not st.singles, ctx.cfg)
	var pts: int = st.p + r[0] + k[0] + chal * 5 * st.big_v
	var mult: int = st.m + r[1] + chal
	var x: int = r[2] + k[1]
	var score: int = pts * mult * (1 << x)
	var gold: int = r[3]
	var halved := false
	var zeroed := false
	if ctx.twist == "Greed":
		if ctx.gold >= 1:
			gold -= 1
		else:
			score = score / 2 / 5 * 5
			halved = true
	if ctx.twist == "Pride" and ctx.last_bank >= 0 and score <= ctx.last_bank:
		score = 0
		zeroed = true
	return {"score": score, "gold": gold, "parts": [pts, mult, x], "halved": halved, "zeroed": zeroed}


## A bust: {score, carry_mult} from your kit (Sloth banks the Points, Wrath carries Mult).
static func bust_value(ctx: Dictionary, st: Dictionary) -> Dictionary:
	var k := Kits.on_bust(ctx.sin, st.p, st.m, ctx.cfg)
	return {"score": k[0], "carry_mult": k[1]}


## Every legal keep for a throw: [sel, eat_pos]. All non-empty sets of groups, each with and without
## eating (Gluttony, once a turn).
static func keep_choices(ctx: Dictionary, st: Dictionary, gs: Array) -> Array:
	var out: Array = []
	var n := gs.size()
	var eats: Array = [-1]
	if can_eat(ctx, st):
		eats += unkeepable(st, gs).slice(0, 1)  # any unkeepable die eats the same
	for mask in range(1, 1 << n):
		var sel: Array = []
		for i in n:
			if mask & (1 << i):
				sel.append(i)
		for e in eats:
			out.append([sel, e])
	return out
