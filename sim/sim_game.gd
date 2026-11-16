## Sim-only Game (sim/agency_sim.gd): core/game.gd with prototype rules switched on by option keys, so
## the agency pass can be measured before any core/ change. Nothing in the game uses this file.
##   rethrow: true  -- once a turn, after a throw, one die may be rethrown before Strikes count.
##   tempt_comeback: true -- a temptation's gain scales with how far behind the leader you are.
extends "res://core/game.gd"

var rethrows := 0          # sim stats
## Audit (REPLY 12, opt "audit"), read by sim/profile_sim.gd: per throw [profile, dice thrown, busted];
## per turn [profile, dice held, round, banked, busted, base points, chain bonus, everything else].
var audit_throws := []
var audit_turns := []
var rethrow_saves := 0     # rethrows that turned a bust into a safe throw


## The die to rethrow, or -1: a Strike, when this throw would bust, or would bring the turn to 2 Strikes.
func _rethrow_pick(p) -> int:
	var s := Rules.count_strikes(turn.faces)
	if s == 0:
		return -1
	if turn.strikes + s >= 2:
		for i in turn.faces.size():
			if turn.faces[i] <= 2:
				return i
	return -1


func _do_rethrow(p) -> void:
	if not opt("rethrow", false) or turn.has_meta("rethrown"):
		return
	var i := _rethrow_pick(p)
	if i < 0:
		return
	var busting: bool = turn.strikes + Rules.count_strikes(turn.faces) >= Rules.STRIKES_TO_BUST
	turn.set_meta("rethrown", true)
	turn.faces[i] = rng.randi_range(1, 6)
	rethrows += 1
	if busting and turn.strikes + Rules.count_strikes(turn.faces) < Rules.STRIKES_TO_BUST:
		rethrow_saves += 1


## A temptation's gain for p: points gains scale with the deficit to the leader (tempt_comeback).
func comeback_factor(p) -> float:
	if not opt("tempt_comeback", false):
		return 1.0
	var d: float = maxf(0.0, float(leader_score() - p.score))
	return 1.0 + clampf(d / float(opt("comeback_per", 200)), 0.0, float(opt("comeback_max", 2.0)))


func take_turn(p) -> void:
	p.turns += 1
	turn = TurnState.new()
	current = p
	if t2_available(p) or p.t2_unlocked:
		p.t2_ready = true  # Tier 2 recharges at the start of your turn
	if view:
		view.turn_started(p)

	# Fate Phase 1: escape Purgatory.
	if p.in_purgatory and not await _try_escape(p):
		_end_turn(p, 0)
		await beat(p, "end")
		return

	if v4:
		_start_costs(p)
	if p.sin:
		await p.sin.before_turn(self, p, turn)
	_master_bargain(p)
	_master_swap(p)
	_both(p, _power_start)

	# Fate Phase 2-4: throw (and press), Strike check, score.
	var audit: bool = opt("audit", false)
	var kind: String = str(p.bot.get("kind")) if p.bot.get("kind") != null else "plain"
	var held: int = p.dice
	var base_sum := 0
	var chain_sum := 0
	var first_base := 0  # the face points of the turn's first throw (soften=first)
	var cap: int = int(opt("turn_cap", 0)) if called_round < 0 else 0  # turn_cap=N: one turn banks at most N before the call
	var count: int = p.dice
	if dice_choice:
		count = clampi(await p.bot.dice_to_roll(p, self, 0, 0), 1, _max_throw(p))
	elif throw_all:
		await p.bot.wants_throw(p, self, 0, 0)  # the first throw is never optional; you tap Throw
		count = _max_throw(p)
	while count > 0:
		_power_declare(p)
		turn.faces = Rules.roll(rng, count)
		turn.throws += 1
		var doubled: bool = turn.x2
		turn.x2 = false
		turn.extra_dice = 0
		if view:
			say("%s throws %d: %s" % [pname(p), count, _faces_str(turn.faces)])
		if p.reroll_next > 0:
			reroll_best(turn.faces, p.reroll_next)
			if view:
				say("  Fury (bounced) rerolls %d: %s" % [p.reroll_next, _faces_str(turn.faces)])
			p.reroll_next = 0
		# Opponents react first (Wrath's Fury), then your own Sin.
		if tier2:
			for o in players:
				if o != p and o.sin and t2_available(o):
					await o.sin.on_other_throw(self, o, p, turn)
		if p.sin:
			await p.sin.after_throw(self, p, turn)
		_do_rethrow(p)
		_both(p, _power_after_throw)
		_both(p, _power_envy_copy)
		if opt("first_ones", false) and turn.throws == 1:  # first_ones: on a turn's first throw only 1s strike
			turn.strikes += turn.faces.count(1)
		else:
			turn.strikes += _strikes(turn.faces)
		if audit:
			audit_throws.append([kind, turn.faces.size(), turn.strikes >= Rules.STRIKES_TO_BUST])
		if turn.strikes >= Rules.STRIKES_TO_BUST:
			# soften (REPLY 13): a bust keeps the first throw's face points ("first") or half the turn's
			# face points ("half"), never the chain.
			var keep := 0
			match str(opt("soften", "")):
				"first":
					keep = first_base
				"half":
					keep = base_sum / 2
			keep = keep / 5 * 5
			if audit:
				audit_turns.append([kind, held, round_count, keep, true, keep, 0, 0])
			if view:
				say("  %d Strikes: %s BUSTS and goes to Purgatory." % [turn.strikes, pname(p)])
			_bust(p)
			p.score += keep
			await beat(p, "end")
			return
		turn.throw_points = throw_score(turn.faces)
		var base := Rules.score(Array(turn.faces, TYPE_INT, "", null), 0.0, face_mult)
		base_sum += base
		turn.set_meta("face_pts", base_sum)  # the sim bots weigh a softened bust with it
		if turn.throws == 1:
			first_base = base
		chain_sum += turn.throw_points - base
		if doubled:
			turn.throw_points *= 2
		turn.points += turn.throw_points
		_both(p, _power_scored)
		var capped: bool = cap > 0 and turn.points >= cap
		if capped:
			turn.points = cap
		if view:
			say("  +%d (turn %d, Strikes %d)" % [turn.throw_points, turn.points, turn.strikes])
		await beat(p, "throw")
		if not press or capped:  # a capped turn banks: nothing more can count
			break
		if dice_choice:
			count = clampi(await p.bot.dice_to_roll(p, self, turn.points, turn.strikes), 0, _max_throw(p))
		elif throw_all:
			var forced := false
			if temptations and turn.tempt_ready:
				forced = await _tempt(p)
			if forced:
				count = _max_throw(p) + turn.extra_dice
			elif not may_throw(p):
				count = 0
			else:
				var go: bool = _greed_both(p) or await p.bot.wants_throw(p, self, turn.points, turn.strikes)
				count = _max_throw(p) if go or not may_bank(p) else 0
		else:
			count = p.dice if p.bot.wants_press(p, self, turn.points, turn.strikes) else 0
		if count > 0:
			p.presses += 1

	var banked: int = turn.points
	if p.sin:
		banked = p.sin.on_bank(self, p, turn, banked)
		if view and turn.min_points >= 0:
			say("  Hubris %s: %d -> %d" % ["pays off" if banked > 0 else "fails", turn.points, banked])
	if turn.has_meta("b_hubris"):  # a borrowed Hubris pays here (its own Sin isn't Pride)
		var before := banked
		banked = int(banked * float(opt("hubris_mult", 1.5))) / 5 * 5 if turn.points >= turn.min_points else 0
		p.set_meta("b_gain", int(p.get_meta("b_gain", 0)) + maxi(0, banked - before))
	if p.pact_by != null:
		var cut: int = mini(banked, p.pact_pct) if v4 else banked * p.pact_pct / 100
		p.pact_by.score += cut  # like Spark of Rage, 1000 reached off-turn wins on their next turn
		banked -= cut
		if view and cut > 0:
			say("  Binding Pact: %s takes %d." % [pname(p.pact_by), cut])
	if v4:
		banked = _bank_costs(p, banked)
	banked = _power_bank(p, banked)
	if audit:
		audit_turns.append([kind, held, round_count, banked, false, base_sum, chain_sum, banked - base_sum - chain_sum])
	p.score += banked
	if view:
		say("%s banks %d (score %d)." % [pname(p), banked, p.score])
	if v4:
		if banked >= 200:
			_view_event("bank", p)
		_check_lead()
	_end_turn(p, banked)

	if p.score >= int(opt("win_score", Rules.WIN_SCORE)):
		if finish_round:
			end_triggered = true
		else:
			winner = p
			return

	# Gambit Phase: buy dice, then Gambit abilities.
	var n: int = clampi(await p.bot.dice_to_buy(p, self), 0, mini(supply, int(opt("max_buy", Rules.MAX_BUY))))  # REPLY 21: max_buy=99 for the old rule
	while n > 0 and (_buy_price(p, n) > p.score or (opt("buy_from_bank", false) and _buy_price(p, n) > banked)):  # buy_from_bank: only from this turn's Bank
		n -= 1
	if n > 0:
		var price := _buy_price(p, n)
		p.score -= price
		p.dice += n
		p.set_meta("buys", int(p.get_meta("buys", 0)) + n)
		supply -= n
		if view:
			say("%s buys %d %s for %d (now %d dice)." % [pname(p), n, "die" if n == 1 else "dice", price, p.dice])
		for o in players:
			if o != p and o.sin:
				var vig: int = o.sin.on_other_buy(self, o, p, n)
				o.score += vig
				if view and vig > 0:
					say("  The Vig: %s takes %d." % [pname(o), vig])
	if p.sin and t2_available(p):
		await p.sin.gambit(self, p, n)
	await beat(p, "end")


## One rival Sin may tempt p at this decision. Returns true when the accepted gain throws at once.
func _tempt(p) -> bool:
	var picks := []  # [sin player, offers that fit, weight]
	var total := 0.0
	for o in players:
		if o == p or o.sin == null:
			continue
		var fit: Array = Temptations.OFFERS.get(o.sin.sin_name, []).filter(func(of): return Temptations.fits(of, self, p))
		if fit.is_empty():
			continue
		var w := 1.0 + mark_weight * int(p.marks.get(o.sin.sin_name, 0))
		picks.append([o, fit, w])
		total += w
	if picks.is_empty():
		return false
	turn.tempt_ready = false
	var r := rng.randf() * total
	var pick = picks[picks.size() - 1]
	for e in picks:
		r -= e[2]
		if r <= 0.0:
			pick = e
			break
	var from = pick[0]
	var offer: Dictionary = pick[1][rng.randi_range(0, pick[1].size() - 1)]
	var sname: String = from.sin.sin_name
	p.offers_seen += 1
	var far: bool = leader_score() - p.score >= 150
	tempt_counts[0 if far else 2] += 1
	p.last_offer_turn = p.turns_started
	if not offer_stats.has(offer.id):
		offer_stats[offer.id] = [0, 0]
	offer_stats[offer.id][0] += 1
	if view:
		say("  %s's temptation: %s" % [pname(from), offer.id])
	var scaled := offer.duplicate()
	var f := comeback_factor(p)
	if f > 1.0:
		match offer.gain:
			"points":
				scaled.g = int(offer.g * f) / 5 * 5
			"dice", "die":
				scaled.g = int(round(offer.g * f))
	var yes: bool = await p.bot.wants_temptation(self, p, from, scaled)
	if view:
		say("  %s's answer: %s" % [pname(p), "accepts" if yes else "refuses"])
		_view_event("accept" if yes else "refuse", p, from)
	if not yes:
		return false
	p.offers_taken += 1
	tempt_counts[1 if far else 3] += 1
	offer_stats[offer.id][1] += 1
	var throws_now := Temptations.apply(scaled, self, p)
	var behind: int = leader_score() - p.score
	# mark_free_behind: a mark taken while this far behind the leader doesn't count toward a claim.
	if not (opt("mark_free_behind", 0) > 0 and behind >= int(opt("mark_free_behind", 0))):
		p.marks[sname] = int(p.marks.get(sname, 0)) + 1
	p.marks_taken[sname] = int(p.marks_taken.get(sname, 0)) + 1
	if p.marks.get(sname, 0) >= marks_to_claim:
		p.marks[sname] = 0
		if not p.claims.has(sname):
			p.claims.append(sname)
			claims_made += 1
			claim_ranks.append(_rank(p))
			if view:
				say("  %s's claim: %s, for the rest of the game" % [pname(from), pname(p)])
	_check_lead()
	return throws_now


## comeback_gap: true -- a seat trailing the leader by comeback_gap_at or more gets an offer every turn
## (tempt_gap 1, always ready) instead of every other turn.
func _start_costs(p) -> void:
	super(p)
	if opt("comeback_gap", false) and temptations and round_count > 1 and not turn.tempt_ready:
		if leader_score() - p.score >= int(opt("comeback_gap_at", 150)):
			turn.tempt_ready = true


# ---------- Prototype: dice and Strikes ----------

## strike_cap: true -- dice beyond the third add at most one Strike to a throw.
## mark "die" (REPLY 14, sim only): the seat core/game.gd marks throws one die fewer that round. The
## mark itself, mark "chain", chain_cap and the bust softener live in core (Rules.V5, REPLY 15).
func _max_throw(p) -> int:
	var n: int = super(p)
	if is_marked(p) and str(opt("mark", "")) == "die":
		n = maxi(1, n - 1)
	return n


func _strikes(faces: Array) -> int:
	var s := Rules.count_strikes(Array(faces, TYPE_INT, "", null))
	if not opt("strike_cap", false) or faces.size() <= 3:
		return s
	var base := 0
	for i in 3:
		if faces[i] <= 2:
			base += 1
	return mini(s, base + 1)


# ---------- Prototype: active powers (opt "powers"; TableDesign §10) ----------
## Once a turn; plain bots press at the first chance that does something, a bot with `smart` weighs it.
## Stats per Sin: turns, uses, uses at the first chance, chances seen, busts a use saved.
var power_stats := {}


func _ps(p) -> Dictionary:
	var n: String = _pname(p) + ("" if _slot == 0 else "+")  # "Wrath+": a borrowed Wrath seal
	if not power_stats.has(n):
		power_stats[n] = {"turns": 0, "uses": 0, "first": 0, "chances": 0, "saves": 0, "turns_with_chance": 0}
	return power_stats[n]


func _powers_on(p) -> bool:
	return opt("powers", false) and p.sin != null


func _smart(p) -> bool:
	return p.bot.get("smart") == true or (p.sin != null and _pname(p) in str(opt("smart_sins", "")).split(","))


## A legal chance this turn: count it; true if it's the turn's first.
func _chance(p) -> bool:
	var st := _ps(p)
	st.chances += 1
	var n: int = turn.get_meta("chances", 0) + 1
	turn.set_meta("chances", n)
	if n == 1:
		st.turns_with_chance += 1
	return n == 1


func _use(p, first: bool, saved := false) -> void:
	var st := _ps(p)
	st.uses += 1
	if first:
		st.first += 1
	if saved:
		st.saves += 1
	if _slot == 0:
		turn.set_meta("power", true)
		p.set_meta("charges", int(p.get_meta("charges", 0)) + 1)
		return
	turn.set_meta("power_b", true)
	p.set_meta("b_uses", int(p.get_meta("b_uses", 0)) + 1)
	if saved:  # a bust the borrowed seal turned safe: the stake it kept counts as its gain
		p.set_meta("b_gain", int(p.get_meta("b_gain", 0)) + turn.points)
	var left: int = int(p.get_meta("b_left", 0)) - 1
	p.set_meta("b_left", left)
	if left == 0:  # out of charges: the seal empties
		p.remove_meta("borrowed")


func _power_free() -> bool:
	if _slot == 1:
		return not turn.has_meta("power_b") and current.has_meta("borrowed") and _will_use(current, "b")
	if int(opt("power_charges", 0)) > 0 and int(current.get_meta("charges", 0)) >= int(opt("power_charges", 0)):
		return false
	return not turn.has_meta("power") and _will_use(current, "a")


# ---------- REPLY 6-7 prototypes: profiles, the borrowed seal, the Master's round, the buy rule ----------

## The power in play now: slot 0 is the Sin's own seal, slot 1 the borrowed one (opt "borrow").
var _slot := 0


func _pname(p) -> String:
	if _slot == 0:
		return str(p.get_meta("swap_as", p.sin.sin_name))  # a swapped seal (opt "swap") plays as the rival's
	return str(p.get_meta("borrowed", ""))


## A profile that uses its seal only some turns (Forgetter): one roll a turn a slot (bot.seal_use).
func _will_use(p, key: String) -> bool:
	var u = p.bot.get("seal_use")
	if u == null or float(u) >= 1.0:
		return true
	var mk := "will_" + key
	if not turn.has_meta(mk):
		turn.set_meta(mk, rng.randf() < float(u))
	return turn.get_meta(mk)


## Runs one power hook for the borrowed seal too (slot 1), when one is held.
func _both(p, hook: Callable) -> void:
	hook.call(p)
	if p.has_meta("borrowed") and opt("borrow", "") != "":
		var e_before: int = turn.points + p.score
		_slot = 1
		hook.call(p)
		_slot = 0
		var gained: int = turn.points + p.score - e_before
		if gained > 0:
			p.set_meta("b_gain", int(p.get_meta("b_gain", 0)) + gained)


func _greed_both(p) -> bool:
	if _power_greed(p):
		return true
	if p.has_meta("borrowed") and opt("borrow", "") != "":
		_slot = 1
		var r := _power_greed(p)
		_slot = 0
		return r
	return false


## borrow "charges3" | "keep" | "free3": at the start of your turn, if your second seal is empty, the
## Master offers you one rival Sin's power from the table (at random) for one mark of that Sin (free3: no
## mark). charges3 / free3: three uses, then it empties; keep: until the game ends. borrow_every
## "turn" (default) or "round" (once a round, the turn's first seat to have an empty slot... per seat).
func _master_bargain(p) -> void:
	var mode := str(opt("borrow", ""))
	if mode == "" or round_count < 2 or p.has_meta("borrowed") or not _powers_on(p):
		return
	if str(opt("borrow_every", "turn")) == "round" and _offer_round == round_count:
		return  # one offer a round for the whole table (was per seat: the same as every turn)
	_offer_round = round_count
	var pool := []
	for o in players:
		if o != p and o.sin != null and o.sin.sin_name != p.sin.sin_name:
			pool.append(o)
	if pool.is_empty():
		return
	var from = pool[rng.randi_range(0, pool.size() - 1)]
	var sname: String = from.sin.sin_name
	var costs_mark: bool = mode != "free3"
	var offer := {"id": "borrow", "gain": "power", "g": 0, "cost": "mark" if costs_mark else "none", "c": 0}
	var yes := true
	if p.bot.has_method("wants_borrow"):
		yes = p.bot.wants_borrow(self, p, from, costs_mark)
	elif costs_mark:
		yes = int(p.marks.get(sname, 0)) + 1 < marks_to_claim or p.claims.has(sname)
	borrow_offers += 1
	if not yes:
		return
	borrow_taken += 1
	p.set_meta("borrowed", sname)
	p.set_meta("b_left", 9999 if mode == "keep" else 3)
	var used: Dictionary = p.get_meta("b_held", {})
	used[sname] = int(used.get(sname, 0)) + 1
	p.set_meta("b_held", used)
	if costs_mark:
		var behind: int = leader_score() - p.score
		if not (opt("mark_free_behind", 0) > 0 and behind >= int(opt("mark_free_behind", 0))):
			p.marks[sname] = int(p.marks.get(sname, 0)) + 1
		if p.marks.get(sname, 0) >= marks_to_claim:
			p.marks[sname] = 0
			if not p.claims.has(sname):
				p.claims.append(sname)
				claims_made += 1
				claim_ranks.append(_rank(p))


var borrow_offers := 0
var borrow_taken := 0


## swap "free" | "mark": at the start of your turn the Master offers to trade your seal for a random
## rival's (a different Sin) until your next turn starts; the rival holds yours for the same span. No
## second slot. "mark" costs one mark of the Sin you take. swap_every works like borrow_every.
func _master_swap(p) -> void:
	if p.has_meta("swap_as"):  # my last trade ends as my turn starts; so does the rival's half
		var o = p.get_meta("swap_with")
		p.remove_meta("swap_as")
		p.remove_meta("swap_with")
		if o.get_meta("swap_with", null) == p:
			o.remove_meta("swap_as")
			o.remove_meta("swap_with")
	var mode := str(opt("swap", ""))
	if mode == "" or round_count < 2 or not _powers_on(p) or p.has_meta("swap_with"):
		return
	if str(opt("swap_every", "turn")) == "round" and _offer_round == round_count:
		return
	var pool := []
	for o in players:
		if o != p and o.sin != null and o.sin.sin_name != p.sin.sin_name and not o.has_meta("swap_with"):
			pool.append(o)
	if pool.is_empty():
		return
	_offer_round = round_count
	var from = pool[rng.randi_range(0, pool.size() - 1)]
	var sname: String = from.sin.sin_name
	var costs_mark: bool = mode == "mark"
	var yes: bool = leader_score() > p.score
	if p.bot.has_method("wants_swap"):
		yes = p.bot.wants_swap(self, p, from, costs_mark)
	borrow_offers += 1
	if not yes:
		return
	borrow_taken += 1
	p.set_meta("swap_as", sname)
	p.set_meta("swap_with", from)
	from.set_meta("swap_as", p.sin.sin_name)
	from.set_meta("swap_with", p)
	var used: Dictionary = p.get_meta("b_held", {})
	used[sname] = int(used.get(sname, 0)) + 1
	p.set_meta("b_held", used)
	if costs_mark:
		p.marks[sname] = int(p.marks.get(sname, 0)) + 1
		if p.marks.get(sname, 0) >= marks_to_claim:
			p.marks[sname] = 0
			if not p.claims.has(sname):
				p.claims.append(sname)
				claims_made += 1
				claim_ranks.append(_rank(p))


var _offer_round := -1  # the round the Master last made an offer (*_every "round": one offer a round, table-wide)


## Turn start: Pride names a Bank.
func _power_start(p) -> void:
	if not _powers_on(p):
		return
	_ps(p).turns += 1
	if _pname(p) != "Pride" or not _power_free():
		return
	_chance(p)
	var n := _max_throw(p)
	var target := -1
	var behind: int = leader_score() - p.score
	if _smart(p):
		if n >= 7:
			target = 250
		elif n >= 5:
			target = 200
		elif n >= 4 or behind >= 150:
			target = 150
	else:
		target = 150
	if target > 0:
		turn.min_points = target
		if _slot == 1:
			turn.set_meta("b_hubris", true)
		_use(p, true)


## After a throw, before Strikes count: Sloth, Wrath, Lust, Gluttony.
func _power_after_throw(p) -> void:
	if not _powers_on(p) or not _power_free():
		return
	var sname: String = _pname(p)
	if not sname in ["Sloth", "Wrath", "Lust", "Gluttony"]:
		return
	var s := _strikes(turn.faces)
	var best := best_face_last_throw()
	if opt("declare", false):
		if not turn.has_meta("power_after"):
			return
		turn.remove_meta("power_after")
		turn.set_meta("power", true)
		var was_bust: bool = turn.strikes + s >= Rules.STRIKES_TO_BUST
		if s == 0 and sname in ["Lust", "Gluttony"]:
			var lo := 0
			for i in turn.faces.size():
				if turn.faces[i] < turn.faces[lo]:
					lo = i
			if sname == "Lust":
				turn.faces[lo] = maxi(best, turn.faces[lo])
			else:
				turn.faces.remove_at(lo)
				turn.points += int(opt("eat", 50))
		elif s > 0:
			_power_effect(p, sname, best)
		if was_bust and turn.strikes + _strikes(turn.faces) < Rules.STRIKES_TO_BUST:
			_ps(p).saves += 1
		return
	if s == 0 or (sname == "Lust" and best < 4):
		return
	var first := _chance(p)
	var busting: bool = turn.strikes + s >= Rules.STRIKES_TO_BUST
	var go := true
	if _smart(p):
		var stake: int = turn.points + throw_score(turn.faces)
		go = (busting and stake > _price()) or (turn.strikes + s >= int(opt("smart_min_strikes", 2)) and stake >= int(opt("smart_stake", 100)) + _price())
	if not go:
		return
	_power_effect(p, sname, best)
	_use(p, first, busting and turn.strikes + _strikes(turn.faces) < Rules.STRIKES_TO_BUST)


func _power_effect(p, sname: String, best: int) -> void:
	match sname:
		"Sloth":  # idle_face (REPLY 15, sim only): the face a Strike becomes; the build keeps 3
			var lifted := false  # idle_one (REPLY 16): the first Strike becomes a 4, the rest 3s
			for i in turn.faces.size():
				if turn.faces[i] <= 2:
					turn.faces[i] = 4 if opt("idle_one", false) and not lifted else int(opt("idle_face", 3))
					lifted = true
		"Wrath":
			for i in turn.faces.size():
				if turn.faces[i] <= 2:
					turn.faces[i] = rng.randi_range(1, 6)
					if opt("wrath_noscore", false) and turn.faces[i] >= 4:
						turn.faces[i] = 3
					var wn: int = turn.get_meta("wn", 0) + 1
					turn.set_meta("wn", wn)
					if opt("wrath_one", false) or wn >= int(opt("wrath_max", 99)):
						break
		"Lust":
			var i: int = turn.faces.find(1)
			if i < 0:
				i = turn.faces.find(2)
			turn.faces[i] = best
		"Gluttony":
			var i: int = turn.faces.find(1)
			if i < 0:
				i = turn.faces.find(2)
			turn.faces.remove_at(i)
			turn.points += int(opt("eat", 50))


## After a safe throw has scored: Envy mirrors it (its points count twice).
func _power_scored(p) -> void:
	if not _powers_on(p) or not _power_free() or _pname(p) != "Envy" or turn.throw_points <= 0 or opt("envy_mode", "mirror") != "mirror":
		return
	var first := _chance(p)
	var go := true
	if _smart(p):
		var banking: bool = not p.bot.wants_throw(p, self, turn.points, turn.strikes)
		go = turn.throw_points >= int(opt("smart_mirror", 60)) or banking
	if go:
		turn.points += turn.throw_points
		_use(p, first)


## At a throw-or-bank decision: Greed banks half the stake and throws on. True = it did (throw again).
func _power_greed(p) -> bool:
	if not _powers_on(p) or not _power_free() or _pname(p) != "Greed" or turn.points < 10:
		return false
	var first := _chance(p)
	var n := _max_throw(p)
	var left: int = Rules.STRIKES_TO_BUST - turn.strikes
	var half: int = turn.points / 2 / 5 * 5
	var go: bool
	if _smart(p):
		var ev_all: float = maxf(float(turn.points), p.bot.expected_after_throw(n, turn.points, left, chain, face_mult))
		var ev_half: float = half + p.bot.expected_after_throw(n, turn.points - half, left, chain, face_mult)
		go = ev_half + half * (float(opt("greed_mult", 1.0)) - 1.0) - _price() > ev_all and turn.points >= int(opt("smart_greed", 0))
	else:
		go = turn.points >= 150
	if not go:
		return false
	p.score += int(half * float(opt("greed_mult", 1.0))) / 5 * 5
	turn.points -= half
	_use(p, first)
	return true


## Claims by the claimed seat's place when claimed: "last", "lead" or "mid".
var claim_ranks := []
## Offers to a seat 150+ behind, accepted; offers to other seats, accepted.
var tempt_counts := [0, 0, 0, 0]


func _rank(p) -> String:
	var lo := 99999
	var hi := -1
	for o in players:
		lo = mini(lo, o.score)
		hi = maxi(hi, o.score)
	if p.score == lo and lo != hi:
		return "last"
	if p.score == hi and lo != hi:
		return "lead"
	return "mid"


## Envy variant (envy_mode "copy"): after a throw with a scorer, before Strikes count, add a copy of
## this throw's best die. Smart: on a throw with 2+ scorers, or when it would bank after it.
func _power_envy_copy(p) -> void:
	if not _powers_on(p) or not _power_free() or _pname(p) != "Envy" or opt("envy_mode", "mirror") != "copy":
		return
	var best := 0
	var scorers := 0
	for f in turn.faces:
		best = maxi(best, f)
		if f >= 4:
			scorers += 1
	if best < 4:
		return
	var first := _chance(p)
	if turn.strikes + _strikes(turn.faces) >= Rules.STRIKES_TO_BUST:
		return  # a busting throw: nothing to copy into
	var go := true
	if _smart(p):
		go = best * face_mult > _price() and scorers >= int(opt("smart_copy", 2)) and (best >= int(opt("smart_best", 4)) or not p.bot.wants_throw(p, self, turn.points + throw_score(turn.faces), turn.strikes + _strikes(turn.faces)))
	if go:
		if opt("envy_flat", false):
			turn.points += best * face_mult  # the copy scores its face, outside the multiplier
		else:
			turn.faces.append(best)
		_use(p, first)


## declare: true -- Sloth, Wrath, Lust and Gluttony name the throw before it's thrown; the power then
## acts on that throw (on its Strikes; with none, Gluttony eats and Lust turns the lowest die). Plain bots
## declare the turn's first throw; smart ones once the stake is declare_at or more, or with a Strike already.
func _power_declare(p) -> void:
	if not _powers_on(p) or not opt("declare", false) or not _power_free() or turn.has_meta("declared"):
		return
	if not _pname(p) in ["Sloth", "Wrath", "Lust", "Gluttony"]:
		return
	if _pname(p) == "Lust" and best_face_last_throw() < 4:
		return
	var first := _chance(p)
	var go := true
	if _smart(p):
		go = turn.points >= int(opt("declare_at", 100)) or turn.strikes >= int(opt("declare_strikes", 1))
	if go:
		turn.set_meta("declared", true)
		_use(p, first)
		turn.remove_meta("power")  # the effect still has to fire after the throw
		turn.set_meta("power_after", true)


## power_restraint N: bank with your power unspent this turn, +N. power_cost N: bank after using it, -N.
func _power_bank(p, banked: int) -> int:
	if not _powers_on(p) or banked <= 0:
		return banked
	if turn.has_meta("power"):
		return maxi(0, banked - int(opt("power_cost", 0)))
	return banked + int(opt("power_restraint", 0))


## What a use costs at the Bank, for a smart bot's sums.
func _price() -> int:
	return int(opt("power_cost", 0)) + int(opt("power_restraint", 0))
