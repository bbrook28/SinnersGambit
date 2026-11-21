## Spike (throwaway): three candidate cores for dice poker, each solved exactly and compared with obvious play.
## godot --headless --path . --script res://sim/cores_sim.gd
## Faces 2-6 are pips, 1 is a skull. Poker hands and pay from dice/config.gd and dice/rules.gd.
extends SceneTree

const Config = preload("res://dice/config.gd")
const Rules = preload("res://dice/rules.gd")

var cfg := Config.merged({})
var dist := {}        # m -> Array of [sorted faces 1..6, probability]
var memo := {}
var target := -1      # C: the Master's hand rank to beat; -1 scores marks
var mode := ""        # which policy the A recursion follows


func _init() -> void:
	for m in 6:
		dist[m] = _dist(m)
	var t0 := Time.get_ticks_msec()
	_core_b()
	print("run time %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	quit()


func _dist(m: int) -> Array:
	var agg := {}
	for c in int(pow(6, m)):
		var x := c
		var f: Array = []
		for i in m:
			f.append(x % 6 + 1)
			x /= 6
		f.sort()
		var k := str(f)
		if not agg.has(k):
			agg[k] = [f, 0.0]
		agg[k][1] += 1.0 / pow(6, m)
	return agg.values()


func _val(faces: Array) -> float:
	var sc: Dictionary = Rules.score(cfg, faces)
	if target < 0:
		return float(sc.marks)
	if sc.hand > target:
		return 1.0
	return 0.5 if sc.hand == target else 0.0


# ---------- A: throw 5, rethrow any non-skulls up to twice, stop any time ----------

func _core_a() -> void:
	print("== A: Rethrow. Throw 5; 1s are skulls and stay; rethrow any others, up to 2 times; 3 skulls bust; stop any time.")
	var res := {}
	for m in ["strong", "greedy", "careful", "allin"]:
		mode = m
		memo.clear()
		res[m] = _a_start()
	print("  marks a hand: strong %.3f, greedy (hold matches, rethrow till full house) %.3f, careful (same, stop at 2 skulls) %.3f, all-in (always rethrow) %.3f" % [
		res.strong.v, res.greedy.v, res.careful.v, res.allin.v])
	var best_obvious: float = maxf(res.greedy.v, maxf(res.careful.v, res.allin.v))
	print("  strong over the best obvious play: %+.0f%%; strong busts %.1f%%" % [100.0 * (res.strong.v / best_obvious - 1.0), 100.0 * res.strong.bust])
	mode = "strong"
	memo.clear()
	_a_decisions()


func _a_start() -> Dictionary:
	var v := 0.0
	var bust := 0.0
	for o in dist[5]:
		var k: int = o[0].count(1)
		if k >= 3:
			bust += o[1]
			continue
		var r: Array = _a(_pips(o[0]), k, 2)
		v += o[1] * r[0]
		bust += o[1] * r[1]
	return {"v": v, "bust": bust}


func _pips(f: Array) -> Array:
	return f.filter(func(x): return x > 1)


## Returns [value, bust chance] under the current mode.
func _a(faces: Array, skulls: int, rolls: int) -> Array:
	var key := "%s|%d|%d|%d" % [faces, skulls, rolls, target]
	if memo.has(key):
		return memo[key]
	var stop := [_val(faces), 0.0]
	var out: Array = stop
	if rolls > 0 and faces.size() > 0:
		if mode == "strong":
			for h in _holds(faces):
				var r := _a_roll(h, faces.size() - h.size(), skulls, rolls)
				if r[0] > out[0] + 1e-12:
					out = r
		else:
			var go := true
			var hand: int = Rules.score(cfg, faces).hand
			if mode == "greedy" or mode == "careful":
				go = hand < 5 and not (mode == "careful" and skulls >= 2)
			var h := _greedy_hold(faces)
			if go and h.size() < faces.size():
				out = _a_roll(h, faces.size() - h.size(), skulls, rolls)
	memo[key] = out
	return out


func _a_roll(hold: Array, m: int, skulls: int, rolls: int) -> Array:
	var v := 0.0
	var bust := 0.0
	for o in dist[m]:
		var k: int = o[0].count(1)
		if skulls + k >= 3:
			bust += o[1]
			continue
		var nf: Array = hold + _pips(o[0])
		nf.sort()
		var r: Array = _a(nf, skulls + k, rolls - 1)
		v += o[1] * r[0]
		bust += o[1] * r[1]
	return [v, bust]


## Every distinct hold that rethrows at least one die.
func _holds(faces: Array) -> Array:
	var seen := {}
	var out: Array = []
	for mask in int(pow(2, faces.size())) - 1:
		var h: Array = []
		for i in faces.size():
			if mask & (1 << i):
				h.append(faces[i])
		h.sort()
		var k := str(h)
		if not seen.has(k):
			seen[k] = true
			out.append(h)
	return out


## Obvious play: hold every die that matches another; with four or more different faces, hold them for the straight.
func _greedy_hold(faces: Array) -> Array:
	var h: Array = faces.filter(func(x): return faces.count(x) >= 2)
	var distinct := {}
	for f in faces:
		distinct[f] = true
	if h.is_empty() and distinct.size() >= 4:
		h = distinct.keys()
	if h.is_empty() and not faces.is_empty():
		h = [faces.max()]
	h.sort()
	return h


## How often the obvious hold is wrong, and how much it costs, over the positions strong play reaches.
func _a_decisions() -> void:
	var n := 0.0
	var wrong := 0.0
	var costly := 0.0
	var close := 0.0
	for o in dist[5]:
		var k: int = o[0].count(1)
		if k >= 3:
			continue
		var faces := _pips(o[0])
		var vals: Array = [_val(faces)]
		var best_h := -1
		var hs := _holds(faces)
		for h in hs:
			vals.append(_a_roll(h, faces.size() - h.size(), k, 2)[0])
		var sorted := vals.duplicate()
		sorted.sort()
		var top: float = sorted[-1]
		var g := _greedy_hold(faces)
		var gv: float = vals[0] if g.size() == faces.size() else _a_roll(g, faces.size() - g.size(), k, 2)[0]
		n += o[1]
		if top - gv > 1e-9:
			wrong += o[1]
		if top - gv >= 0.25:
			costly += o[1]
		if sorted.size() > 1 and top - sorted[-2] < 0.15 and top - sorted[-2] > 1e-9:
			close += o[1]
	print("  first decision: the obvious hold is wrong %.0f%% of the time, wrong by >= 0.25 marks %.0f%%; best two options within 0.15 marks %.0f%%" % [
		100.0 * wrong / n, 100.0 * costly / n, 100.0 * close / n])


# ---------- C: A against the Master's shown hand ----------

func _core_c() -> void:
	print("== C: Beat the Master. The Master shows a 5-dice hand first (pips only); play A to beat it. Win 1, tie 0.5.")
	# the Master's hand: 5 dice of faces 2-6, uniform
	var agg := {}
	for c in int(pow(5, 5)):
		var x := c
		var f: Array = []
		for i in 5:
			f.append(x % 5 + 2)
			x /= 5
		var h: int = Rules.score(cfg, f).hand
		agg[h] = agg.get(h, 0.0) + 1.0 / pow(5, 5)
	var parts: Array = []
	for h in agg.keys():
		parts.append("%s %.0f%%" % [Rules.HANDS[h], 100.0 * agg[h]])
	print("  the Master shows: " + ", ".join(parts))
	var win := {"aware": 0.0, "marks": 0.0, "greedy": 0.0, "careful": 0.0}
	for t in agg.keys():
		# target-aware best play
		target = t
		mode = "strong"
		memo.clear()
		win.aware += agg[t] * _a_start().v
		# obvious plays, scored against the target
		for m in ["greedy", "careful"]:
			mode = m
			memo.clear()
			win[m] += agg[t] * _a_start().v
	# marks-optimal play that ignores the Master, scored against the target
	win.marks = _blind_marks_win(agg)
	target = -1
	print("  win chance: target-aware best %.1f%%, marks-best ignoring the Master %.1f%%, greedy %.1f%%, careful %.1f%%" % [
		100.0 * win.aware, 100.0 * win.marks, 100.0 * win.greedy, 100.0 * win.careful])
	var best_obvious: float = maxf(win.greedy, maxf(win.careful, win.marks))
	print("  target-aware over the best blind play: %+.1f points" % (100.0 * (win.aware - best_obvious)))


## Win chance of marks-optimal play (chosen with target -1) when scored against each target.
func _blind_marks_win(agg: Dictionary) -> float:
	var total := 0.0
	for t in agg.keys():
		total += agg[t] * _blind_start(t)
	return total


func _blind_start(t: int) -> float:
	var v := 0.0
	for o in dist[5]:
		var k: int = o[0].count(1)
		if k >= 3:
			continue
		v += o[1] * _blind(_pips(o[0]), k, 2, t)
	return v


var bmemo := {}
var mmemo := {}

## Follows the hold marks-optimal play picks; returns its win chance against t.
func _blind(faces: Array, skulls: int, rolls: int, t: int) -> float:
	var key := "%s|%d|%d|%d" % [faces, skulls, rolls, t]
	if bmemo.has(key):
		return bmemo[key]
	var h = _marks_choice(faces, skulls, rolls)
	var out := 0.0
	if h == null:
		var hand: int = Rules.score(cfg, faces).hand
		out = 1.0 if hand > t else (0.5 if hand == t else 0.0)
	else:
		for o in dist[faces.size() - h.size()]:
			var k: int = o[0].count(1)
			if skulls + k >= 3:
				continue
			var nf: Array = h + _pips(o[0])
			nf.sort()
			out += o[1] * _blind(nf, skulls + k, rolls - 1, t)
	bmemo[key] = out
	return out


## The hold marks-optimal play chooses here, or null to stop.
func _marks_choice(faces: Array, skulls: int, rolls: int):
	var key := "%s|%d|%d" % [faces, skulls, rolls]
	if mmemo.has(key):
		return mmemo[key]
	var keep_target := target
	var keep_mode := mode
	target = -1
	mode = "strong"
	var best = null
	var bv := _val(faces)
	if rolls > 0 and faces.size() > 0:
		for h in _holds(faces):
			var r := _a_roll(h, faces.size() - h.size(), skulls, rolls)
			if r[0] > bv + 1e-12:
				bv = r[0]
				best = h
	target = keep_target
	mode = keep_mode
	mmemo[key] = best
	return best


# ---------- B: today's row, but you choose to draw 1, 2 or 3 dice each throw ----------

var bm := {}
var bmode := ""

func _core_b() -> void:
	print("== B: Choose your draw. Today's row (bag 7, keep 1, row of 5, 3 skulls bust), but each throw you draw 1, 2 or 3 dice.")
	var out := {}
	for m in ["strong", "fixed2", "greedy2", "greedy3", "rule", "rulebest"]:
		bmode = m
		bm.clear()
		out[m] = _b([], 0, 7)
	print("  marks a hand: strong %.3f, best play drawing 2 always %.3f, greedy drawing 2 %.3f, greedy drawing 3 %.3f" % [
		out.strong, out.fixed2, out.greedy2, out.greedy3])
	print("  the rule (draw 3 with no skulls, 2 with one, 1 with two): greedy keeps %.3f, best keeps %.3f" % [out.rule, out.rulebest])
	var best_obvious: float = maxf(maxf(out.greedy2, out.greedy3), out.rule)
	print("  strong over the best obvious play: %+.0f%%; the draw choice alone adds %+.0f%%" % [
		100.0 * (out.strong / best_obvious - 1.0), 100.0 * (out.strong / out.fixed2 - 1.0)])


func _b(row: Array, skulls: int, bag: int) -> float:
	var r := row.duplicate()
	r.sort()
	var key := "%s|%d|%d" % [r, skulls, bag]
	if bm.has(key):
		return bm[key]
	var v := float(Rules.score(cfg, r).marks)
	if r.size() < 5 and bag > 0:
		var ns: Array = [mini(2, bag)]
		if bmode == "strong":
			ns = range(1, mini(3, bag) + 1)
		elif bmode == "greedy3":
			ns = [mini(3, bag)]
		elif bmode == "rule" or bmode == "rulebest":
			ns = [mini(3 - skulls, bag)]
		var best := -1.0
		for n in ns:
			best = maxf(best, _b_throw(r, skulls, bag, n))
		v = best
	bm[key] = v
	return v


func _b_throw(row: Array, skulls: int, bag: int, n: int) -> float:
	var dance := bag == 1
	var total := 0.0
	for o in dist[n]:
		var k: int = o[0].count(1)
		if skulls + k >= 3 or (dance and k > 0):
			continue
		var pips := _pips(o[0])
		if dance:
			total += o[1] * _b(row + [0], skulls + k, 0)
		elif pips.is_empty():
			total += o[1] * _b(row, skulls + k, bag - n)
		elif bmode == "greedy2" or bmode == "greedy3" or bmode == "rule":
			var bi := 0
			var bk := -1
			for i in pips.size():
				var f: int = pips[i]
				var kk: int = Rules.score(cfg, row + [f]).marks * 100 + row.count(f) * 10 + f
				if kk > bk:
					bk = kk
					bi = i
			total += o[1] * _b(row + [pips[bi]], skulls + k, bag - k - 1)
		else:
			var best := -1.0
			for f in pips:
				best = maxf(best, _b(row + [f], skulls + k, bag - k - 1))
			total += o[1] * best
	return total
