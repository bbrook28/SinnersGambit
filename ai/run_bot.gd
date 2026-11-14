## Run-mode bot (Docs/RunDesign.md §11).
## Play: after each throw it scores every legal keep, then plays each promising (keep, throw again)
## to the end of the turn many times (Monte Carlo search of the whole turn, a fast policy for the rest).
## It plays for the round, not for points: a turn's worth is the chance it clears the target, using
## this build's own spread of turn scores for the turns still to come.
## Shop: values each offer by simulating turns with and without it and estimating how many more rounds
## the run then survives; buys while the gain beats the gold.
extends RefCounted

const Round = preload("res://run/round.gd")
const Relics = preload("res://run/relics.gd")
const Shop = preload("res://run/shop.gd")

var rng := RandomNumberGenerator.new()
var rollouts := 16        # per candidate (keep, throw again)
var top_k := 5            # candidates that get rollouts
var fast := false         # fast policy only (no search): quick tuning, buy sims
var dist_turns := 40      # turns sampled for a build's spread
var horizon := 9          # rounds ahead the shop looks
var gold_worth := 0.015   # rounds of survival one gold is worth, held
## Counted for the sim: throw points, and those where the best two options are within 20%.
var decision_points := 0
var decisions := 0

var _need := 1 << 30      # Points still needed this round
var _after := 1           # turns left after this one
var _dist := PackedInt32Array()
var _pride := false       # Pride rules this round: each Bank must beat the last
var _floor := -1
var _stats_cache := {}
var _dist_cache := {}
var _r := RandomNumberGenerator.new()


func _init(p_seed := 1) -> void:
	rng.seed = p_seed


# ---------- play ----------

## Set before each turn: what the round still needs and how many turns follow this one.
func begin_turn(run, ctx: Dictionary) -> void:
	_need = run.target - run.score
	_after = run.turns_left - 1
	_pride = ctx.twist == "Pride"
	_floor = ctx.last_bank
	_dist = _build_dist(ctx)


## After a throw with groups gs: applies the chosen keep to st. Returns true to throw again, false to Bank.
func play(ctx: Dictionary, st: Dictionary, gs: Array) -> bool:
	if fast:
		return _fast(ctx, st, gs)
	var choices := Round.keep_choices(ctx, st, gs)
	var cands: Array = []   # [prior, st_after, choice]
	var banks: Array = []   # [utility, score, st_after, choice]
	for ch in choices:
		var s2: Dictionary = st.duplicate()
		Round.keep(ctx, s2, gs, ch[0], ch[1])
		var b: int = Round.bank_value(ctx, s2).score
		banks.append([_u(b), b, s2, ch])
		if not s2.bank_only:
			cands.append([_cont_estimate(ctx, s2, b), s2, ch])
	cands.sort_custom(func(a, b): return a[0] > b[0])
	var best_u := -1.0
	var best_score := -1.0
	var best: Array = []
	var go := false
	var scores: Array = []
	for bk in banks:
		scores.append(float(bk[1]))
		if bk[0] > best_u or (bk[0] == best_u and bk[1] > best_score):
			best_u = bk[0]
			best_score = bk[1]
			best = bk
			go = false
	var base_seed := rng.randi()
	var n_search := 0 if best_u >= 1.0 else mini(top_k, cands.size())  # a Bank that clears can't be beaten
	if n_search == 0:
		for c in cands:
			scores.append(float(c[0]))
	for i in n_search:
		var c: Array = cands[i]
		var su := 0.0
		var ss := 0.0
		for k in rollouts:
			var sc := _rollout(ctx, c[1], base_seed + k)
			su += _u(sc)
			ss += sc
		su /= rollouts
		ss /= rollouts
		scores.append(ss)
		if su > best_u + 1e-9 or (absf(su - best_u) <= 1e-9 and ss > best_score):
			best_u = su
			best_score = ss
			best = [su, ss, c[1], c[2]]
			go = true
	decision_points += 1
	scores.sort()
	if scores.size() >= 2 and scores[-1] > 0.0 and (scores[-1] - scores[-2]) / scores[-1] <= 0.2:
		decisions += 1
	Round.keep(ctx, st, gs, best[3][0], best[3][1])
	return go and not st.bank_only


## Worth of banking `score` this turn: the chance the round clears.
func _u(score: int) -> float:
	if score >= _need:
		return 1.0 + 0.01 * _after
	if _after <= 0:
		return 0.0
	return _clear_chance(_need - score, _after, maxi(_floor, score) if _pride else -1)


## Chance `turns` more turns make `need`. Pride's twist: a Bank at or under `floor` scores 0, and
## each Bank that counts raises the floor.
func _clear_chance(need: int, turns: int, floor_v := -1) -> float:
	if need <= 0:
		return 1.0
	if turns <= 0 or _dist.is_empty():
		return 0.0
	if turns == 1:
		var i := _dist.bsearch(maxi(need, floor_v + 1))  # first index with value >= need
		return float(_dist.size() - i) / _dist.size()
	var tot := 0.0
	var step := maxi(1, _dist.size() / 30)
	var n := 0
	for i in range(0, _dist.size(), step):
		var s := _dist[i]
		if floor_v >= 0 and s <= floor_v:
			tot += _clear_chance(need, turns - 1, floor_v)
		else:
			tot += _clear_chance(need - s, turns - 1, s if floor_v >= 0 else -1)
		n += 1
	return tot / n


func _rollout(ctx: Dictionary, st: Dictionary, seed_v: int) -> int:
	_r.seed = seed_v
	var s: Dictionary = st.duplicate()
	for t in 40:
		var gs := Round.throw(ctx, s, _r)
		if gs.is_empty():
			return Round.bust_value(ctx, s).score
		if not _fast(ctx, s, gs):
			break
	return Round.bank_value(ctx, s).score


## A one-step guess at throwing again from s (already kept), used to rank candidates and by _fast.
func _cont_estimate(ctx: Dictionary, s: Dictionary, bank: int) -> float:
	var n: int = s.left.size()
	var t := _stats(ctx)
	var b: float = t[0][mini(n, 10)]
	var dp: float = t[1][mini(n, 10)]
	var dm: float = t[2][mini(n, 10)]
	var p := maxf(1.0, float(s.p))
	var m := maxf(1.0, float(s.m))
	return (1.0 - b) * float(bank) * ((p + dp) * (m + dm)) / (p * m)


## The fast policy: a few natural keeps, then Bank or throw on a one-step estimate (or the need).
func _fast(ctx: Dictionary, st: Dictionary, gs: Array) -> bool:
	var opts: Array = []
	var all: Array = range(gs.size())
	opts.append([all, -1])
	var best_set := -1
	var best_single := -1
	var sets: Array = []
	for i in gs.size():
		var g: Dictionary = gs[i]
		if g.kind != "single":
			sets.append(i)
			if best_set < 0 or g.m * 1000 + g.p > gs[best_set].m * 1000 + gs[best_set].p:
				best_set = i
		elif best_single < 0 or g.p > gs[best_single].p:
			best_single = i
	if best_set >= 0 and gs.size() > 1:
		opts.append([[best_set], -1])
		if sets.size() > 1 and sets.size() < gs.size():
			opts.append([sets, -1])
	if best_single >= 0 and gs.size() > 1:
		opts.append([[best_single], -1])
	if Round.can_eat(ctx, st):
		var un := Round.unkeepable(st, gs)
		if un.size() == 1:
			opts.append([all, un[0]])
	var top_v := -1.0
	var top_s: Dictionary = {}
	var top_go := false
	for o in opts:
		var s2: Dictionary = st.duplicate()
		Round.keep(ctx, s2, gs, o[0], o[1])
		var b := float(Round.bank_value(ctx, s2).score)
		var v := b
		var go := false
		if b >= _need:
			v = 1e12 + b
		elif not s2.bank_only:
			var c := _cont_estimate(ctx, s2, int(b))
			if _after <= 0:
				c += 1e9  # last turn and short: throw on
			if c > v:
				v = c
				go = true
		if v > top_v:
			top_v = v
			top_s = s2
			top_go = go
	for k in top_s:
		st[k] = top_s[k]
	return top_go


# ---------- a build's numbers ----------

func _sig(ctx: Dictionary) -> String:
	return "%s|%s|%s|%s|%d|%d|%d|%d" % [ctx.sin, ctx.twist, str(ctx.dice), str(ctx.fx), ctx.gold, ctx.turns_left, ctx.busted_rounds, ctx.carry_mult]


## Per dice count n: [bust chance, mean Points gained, mean Mult gained] keeping every group.
func _stats(ctx: Dictionary) -> Array:
	var key := "%s|%s|%s|%s" % [ctx.sin, ctx.twist, str(ctx.dice), str(ctx.fx)]
	if _stats_cache.has(key):
		return _stats_cache[key]
	if _stats_cache.size() > 400:
		_stats_cache.clear()
	var b := PackedFloat32Array()
	var dp := PackedFloat32Array()
	var dm := PackedFloat32Array()
	var r := RandomNumberGenerator.new()
	r.seed = 77
	b.append(1.0)
	dp.append(0.0)
	dm.append(0.0)
	var N := 60
	var top_n := mini(10, ctx.dice.size() + 2)
	for n in range(1, 11):
		if n > top_n:
			b.append(b[top_n]); dp.append(dp[top_n]); dm.append(dm[top_n])
			continue
		var busts := 0
		var sp := 0.0
		var sm := 0.0
		var left: Array = []
		for i in n:
			left.append(i if i < ctx.dice.size() else -1)
		for k in N:
			var s := {"left": left, "throws": 2, "p": 0, "m": 0, "roll_d": [], "roll_f": []}
			var rd: Array = []
			var rf: Array = []
			for d in left:
				rd.append(d)
				rf.append(r.randi_range(0, 5))
			s.roll_d = rd
			s.roll_f = rf
			var gs := Round.groups(ctx, s)
			if gs.is_empty():
				busts += 1
				continue
			for g in gs:
				sp += g.p
				sm += g.m
		b.append(float(busts) / N)
		var ok := maxi(1, N - busts)
		dp.append(sp / ok)
		dm.append(sm / ok)
	var out := [b, dp, dm]
	_stats_cache[key] = out
	return out


## This build's turn scores (fast policy, playing for points), sorted.
func _build_dist(ctx: Dictionary) -> PackedInt32Array:
	var key := _sig(ctx)
	if _dist_cache.has(key):
		return _dist_cache[key]
	if _dist_cache.size() > 400:
		_dist_cache.clear()
	var keep_need := _need
	var keep_after := _after
	_need = 1 << 30
	_after = 1
	var out := PackedInt32Array()
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for i in dist_turns:
		out.append(_fast_turn(ctx, r))
	out.sort()
	_need = keep_need
	_after = keep_after
	_dist_cache[key] = out
	return out


func _fast_turn(ctx: Dictionary, r: RandomNumberGenerator) -> int:
	var s := Round.new_turn(ctx)
	for t in 40:
		var gs := Round.throw(ctx, s, r)
		if gs.is_empty():
			return Round.bust_value(ctx, s).score
		if not _fast(ctx, s, gs):
			break
	return Round.bank_value(ctx, s).score


# ---------- shop ----------

## Spends in the shop (run.status == "shop"), then returns. Doesn't leave the shop.
func shop(run) -> void:
	# Greed rules the next round: keep 3 gold for its Bank toll.
	var reserve: int = 3 if run.round_i == 2 and run.ruler() == "Greed" else 0
	for guard in 12:
		var base := _worth(run, run.dice, run.relics, run.gold)
		var best_gain := 0.0
		var best: Callable = Callable()
		# Relics: into a free slot, or in place of the weakest one.
		for i in run.offers.relics.size():
			var id: String = run.offers.relics[i]
			if id == "":
				continue
			var price := Shop.relic_price(run, id)
			if run.relics.size() < run.cfg.relic_slots:
				if run.gold - reserve < price:
					continue
				var row: Array = run.relics.duplicate()
				row.append({"id": id, "n": 0})
				var g := _worth(run, run.dice, row, run.gold - price) - base
				if g > best_gain:
					best_gain = g
					best = func(): Shop.buy_relic(run, i)
			else:
				for j in run.relics.size():
					var refund := Shop.sell_value(run, run.relics[j].id)
					if run.gold + refund - reserve < price:
						continue
					var row: Array = run.relics.duplicate()
					row[j] = {"id": id, "n": 0}
					var g := _worth(run, run.dice, row, run.gold + refund - price) - base
					if g > best_gain:
						best_gain = g
						best = func(): Shop.sell_relic(run, j); Shop.buy_relic(run, i)
		if Shop.can_buy_die(run) and run.gold - reserve >= Shop.die_price(run):
			var ds: Array = run.dice.duplicate()
			ds.append(Round.plain_die())
			var g := _worth(run, ds, run.relics, run.gold - Shop.die_price(run)) - base
			if g > best_gain:
				best_gain = g
				best = func(): Shop.buy_die(run)
		for i in run.offers.repaints.size():
			if not Shop.can_buy_repaint(run, i) or run.gold - reserve < run.cfg.repaint_price:
				continue
			var spot := _repaint_spot(run, run.offers.repaints[i])
			if spot.is_empty():
				continue
			var ds: Array = run.dice.duplicate(true)
			_apply_repaint(ds[spot[0]], run.offers.repaints[i], spot[1])
			var g := _worth(run, ds, run.relics, run.gold - run.cfg.repaint_price) - base
			if g > best_gain:
				best_gain = g
				best = func(): Shop.buy_repaint(run, i, spot[0], spot[1])
		if best.is_valid():
			best.call()
			continue
		# Nothing worth it: reroll if rich and a slot is free.
		if run.relics.size() < run.cfg.relic_slots and run.gold >= Shop.reroll_price(run) + 12 and run.offers.rerolls < 2:
			Shop.reroll(run)
			continue
		break


## Where a repaint helps most: Six on a low face, Gild / Crimson on a high face; the plainest die first.
func _repaint_spot(run, kind: String) -> Array:
	var best: Array = []
	var best_v := -999
	for d in run.dice.size():
		var die: Dictionary = run.dice[d]
		for fi in range(1, 6):
			if not Shop.can_repaint(run, d, fi):
				continue
			var v: int = die.f[fi]
			var score := 0
			match kind:
				"six":
					if v == 6:
						continue
					score = 10 - v
				_:
					var mark: Array = die.g if kind == "gild" else die.c
					if mark[fi] == 1:
						continue
					score = v
			score = score * 10 - die.r.size() * 3
			if score > best_v:
				best_v = score
				best = [d, fi]
	return best


func _apply_repaint(die: Dictionary, kind: String, fi: int) -> void:
	match kind:
		"six": die.f[fi] = 6
		"gild": die.g[fi] = 1
		"crimson": die.c[fi] = 1
	if not fi in die.r:
		die.r = die.r + [fi]


## Expected rounds survived over the next `horizon` rounds with this build, plus held gold.
func _worth(run, dice: Array, row: Array, gold: int) -> float:
	var ctx := {
		"cfg": run.cfg, "sin": run.sin, "twist": "", "dice": dice,
		"fx": Relics.effective(_projected(row), run.sin == "Envy"), "owned": dice.size(), "gold": gold,
		"turns_left": 1, "busted_rounds": run.busted_rounds, "carry_mult": 0, "last_bank": -1,
	}
	var keep_dist := _dist
	_dist = _build_dist(ctx)
	var turns: int = run.cfg.turns - Relics.turns_lost(ctx.fx)
	var c: int = run.circle
	var ri: int = run.round_i
	var alive := 1.0
	var total := 0.0
	for h in horizon:
		if c >= run.cfg.targets.size():
			break
		alive *= _clear_chance(run.round_target(c, ri), turns)
		total += alive
		ri += 1
		if ri > 2:
			ri = 0
			c += 1
	_dist = keep_dist
	return total + gold_worth * (gold + _income(row) * total)


## Pilgrim's Staff grows: value it at the Mult it will have a few rounds from now.
func _projected(row: Array) -> Array:
	var out: Array = []
	for r in row:
		if r.id == "pilgrim":
			out.append({"id": "pilgrim", "n": int(r.n) + 3})
		else:
			out.append(r)
	return out


## Gold a round the economy relics are worth (rough: Plate 1.5 Banks, Almoner 2 x 0.7 unused turns,
## Tithe Box sometimes, Sexton's Key a better pick).
func _income(row: Array) -> float:
	var g := 0.0
	for r in row:
		match r.id:
			"plate": g += 1.5
			"almoner": g += 1.4
			"tithe": g += 1.0
			"sexton": g += 1.0
	return g
