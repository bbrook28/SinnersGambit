## Sim-only Game (sim/agency_sim.gd): core/game.gd with prototype rules switched on by option keys, so
## the agency pass can be measured before any core/ change. Nothing in the game uses this file.
##   rethrow: true  -- once a turn, after a throw, one die may be rethrown before Strikes count.
##   tempt_comeback: true -- a temptation's gain scales with how far behind the leader you are.
extends "res://core/game.gd"

var rethrows := 0          # sim stats
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

	# Fate Phase 2-4: throw (and press), Strike check, score.
	var count: int = p.dice
	if dice_choice:
		count = clampi(await p.bot.dice_to_roll(p, self, 0, 0), 1, _max_throw(p))
	elif throw_all:
		await p.bot.wants_throw(p, self, 0, 0)  # the first throw is never optional; you tap Throw
		count = _max_throw(p)
	while count > 0:
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
		turn.strikes += Rules.count_strikes(turn.faces)
		if turn.strikes >= Rules.STRIKES_TO_BUST:
			if view:
				say("  %d Strikes: %s BUSTS and goes to Purgatory." % [turn.strikes, pname(p)])
			_bust(p)
			await beat(p, "end")
			return
		turn.throw_points = throw_score(turn.faces)
		if doubled:
			turn.throw_points *= 2
		turn.points += turn.throw_points
		if view:
			say("  +%d (turn %d, Strikes %d)" % [turn.throw_points, turn.points, turn.strikes])
		await beat(p, "throw")
		if not press:
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
				var go: bool = await p.bot.wants_throw(p, self, turn.points, turn.strikes)
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
	if p.pact_by != null:
		var cut: int = mini(banked, p.pact_pct) if v4 else banked * p.pact_pct / 100
		p.pact_by.score += cut  # like Spark of Rage, 1000 reached off-turn wins on their next turn
		banked -= cut
		if view and cut > 0:
			say("  Binding Pact: %s takes %d." % [pname(p.pact_by), cut])
	if v4:
		banked = _bank_costs(p, banked)
	p.score += banked
	if view:
		say("%s banks %d (score %d)." % [pname(p), banked, p.score])
	if v4:
		if banked >= 200:
			_view_event("bank", p)
		_check_lead()
	_end_turn(p, banked)

	if p.score >= Rules.WIN_SCORE:
		if finish_round:
			end_triggered = true
		else:
			winner = p
			return

	# Gambit Phase: buy dice, then Gambit abilities.
	var n: int = clampi(await p.bot.dice_to_buy(p, self), 0, supply)
	while n > 0 and _buy_price(p, n) > p.score:
		n -= 1
	if n > 0:
		var price := _buy_price(p, n)
		p.score -= price
		p.dice += n
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
	offer_stats[offer.id][1] += 1
	var throws_now := Temptations.apply(scaled, self, p)
	p.marks[sname] = int(p.marks.get(sname, 0)) + 1
	p.marks_taken[sname] = int(p.marks_taken.get(sname, 0)) + 1
	if p.marks[sname] >= marks_to_claim:
		p.marks[sname] = 0
		if not p.claims.has(sname):
			p.claims.append(sname)
			claims_made += 1
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
