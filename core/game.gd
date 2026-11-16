## Runs one game. Decisions are delegated to each player's bot, and Sin abilities
## hook in at fixed timing windows (see sins/sin.gd), so the same loop serves the sim and, later, the UI.
extends RefCounted

const Rules = preload("res://core/rules.gd")
const PlayerState = preload("res://core/player_state.gd")
const TurnState = preload("res://core/turn_state.gd")
const Temptations = preload("res://sins/temptations.gd")

const MAX_ROUNDS := 500

## Rule options under test. Defaults = rulebook as written; Rules.V2 = Phase 1 rules.
## finish_round: reaching 1000 ends the game after the round completes; highest score wins.
## press: after a safe roll you may roll all your dice again. Points and Strikes add up over the turn.
## dice_choice: implies press; each roll you choose how many of your dice to throw (0 = bank).
## seat_bonus: head start; seat N (0-based) starts with N * seat_bonus points.
## supply / supply_per_player: total dice in the game (owned + Shared Supply).
## indulgence_pct: Indulgence costs this % of your score instead of a flat 50.
## chain: combo multiplier per extra scoring die in one roll (see Rules.score).
## face_mult: points per pip (4 -> 4*face_mult). die_cost: price of one die.
var finish_round := false
var press := false
var dice_choice := false
var seat_bonus := 0
var indulgence_pct := 0
var chain := 0.0
var face_mult := 10
var die_cost := Rules.DIE_COST
## tier2: Tier 2 Sin abilities are on (unlock at Rules.TIER2_SCORE, once per round).
var tier2 := false
## throw_all: every throw uses all your dice (minus Drag); after each safe throw, throw again or bank.
## auto_purgatory: Purgatory is a free throw of all your dice at the start of your turn: any 6 frees you,
## otherwise you pay purgatory_cost (nothing if you can't afford it). Either way you then play your turn.
var throw_all := false
var auto_purgatory := false
var purgatory_cost := Rules.INDULGENCE_COST
## Rules.V4 (Docs/TableDesign.md): opts holds the whole rule dict; Sins read their numbers with opt().
var opts := {}
var v4 := false
var v5 := false  # Rules.V5: powers, no Purgatory
var round5 := false
var temptations := false
var tempt_chance := 0.0
var mark_weight := 2
var marks_to_claim := 3
var purgatory_on := true
var leader_seat := -1                # strict leader, for "takes the lead" (view.table_event)
var claims_made := 0                 # sim stats
var offer_stats := {}                # offer id -> [made, accepted] (sim)
var force_claim := {}                # sim: {"seat", "sin", "round"} puts that claim on at that round
var purg_throws := 0                 # sim: Purgatory throws, how many a 6 freed, points paid
var purg_free := 0
var purg_paid := 0

var players: Array = []
var supply: int
var rng := RandomNumberGenerator.new()
var round_count := 0
var winner = null
var end_triggered := false  # someone reached 1000 this round (finish_round mode)
var is_tie := false

var turn = null                     # TurnState of the turn in progress
var last_throw: Array[int] = []     # previous player's last throw (Lust, Envy)
var last_turn_points := 0           # previous player's banked turn, 0 on a bust (Pride)

## UI only (null in the sim): gets log lines and paces the game. See ui/main.gd.
var view = null
var current = null                  # player whose turn it is


## Log line for the UI. Callers guard with `if view:` so the sim skips the formatting.
func say(text: String) -> void:
	if view:
		view.log_line(text)


## UI pause after a throw or a turn end, so bot turns can be followed.
func beat(p, kind: String) -> void:
	if view:
		await view.beat(p, kind)


func pname(p) -> String:
	return view.player_name(p) if view else "P%d" % p.seat


## sins: optional, one Sin instance (or null) per player.
func _init(bots: Array, seed_value: int, options := {}, sins := []) -> void:
	rng.seed = seed_value
	finish_round = options.get("finish_round", false)
	dice_choice = options.get("dice_choice", false)
	throw_all = options.get("throw_all", false) and not dice_choice
	press = options.get("press", false) or dice_choice or throw_all
	auto_purgatory = options.get("auto_purgatory", false)
	purgatory_cost = options.get("purgatory_cost", Rules.INDULGENCE_COST)
	seat_bonus = options.get("seat_bonus", 0)
	indulgence_pct = options.get("indulgence_pct", 0)
	chain = options.get("chain", 0.0)
	face_mult = options.get("face_mult", 10)
	die_cost = options.get("die_cost", Rules.DIE_COST)
	tier2 = options.get("tier2", false)
	opts = options
	v4 = options.get("v4", false)
	v5 = options.get("v5", false)
	round5 = options.get("round5", false)
	temptations = options.get("temptations", false)
	tempt_chance = options.get("tempt_chance", 0.0)
	mark_weight = options.get("mark_weight", 2)
	marks_to_claim = options.get("marks_to_claim", 3)
	purgatory_on = options.get("purgatory", true)
	force_claim = options.get("force_claim", {})
	for i in bots.size():
		var p := PlayerState.new(i, bots[i])
		p.score = i * seat_bonus
		if i < sins.size():
			p.sin = sins[i]
		players.append(p)
	var total_dice: int = options.get("supply", Rules.TOTAL_DICE)
	if options.has("supply_per_player"):
		total_dice = maxi(Rules.TOTAL_DICE, options["supply_per_player"] * bots.size())
	supply = total_dice - Rules.START_DICE * bots.size()


## Decisions and Sin hooks are awaited so a human (ui/human.gd) can answer from the UI.
## Bots answer at once, so in the sim nothing suspends and play() runs synchronously.
func play():
	_master("start", players[0], {})
	while winner == null and round_count < MAX_ROUNDS:
		round_count += 1
		for p in players:
			await take_turn(p)
			if winner != null:
				_master("end", winner, {"margin": _margin()})
				return winner
		if end_triggered:
			_resolve_finish()
			_master("end", winner, {"margin": _margin()})
	return winner


## A rule number: the rule dict's value, or the Sin's own default (V2 / V3 games).
func opt(key: String, default):
	return opts.get(key, default)


## Rules.V4 claims (Docs/TableDesign.md Â§7).
func claimed(p, sname: String) -> bool:
	return p.claims.has(sname)


## Sloth's claim: no more throws than CLAIM_SLOTH_THROWS a turn.
func may_throw(p) -> bool:
	return not (claimed(p, "Sloth") and opt("claim_sloth_fewer", 0) == 0 and turn.throws >= int(opt("claim_sloth_throws", Temptations.CLAIM_SLOTH_THROWS)))


## Lust's claim: no Bank before your CLAIM_LUST_THROWS-th throw.
func may_bank(p) -> bool:
	return not (claimed(p, "Lust") and turn.throws < int(opt("claim_lust_throws", Temptations.CLAIM_LUST_THROWS)))


func sin_player(sname: String):
	for o in players:
		if o.sin and o.sin.sin_name == sname:
			return o
	return null


func _view_event(kind: String, p, other = null) -> void:
	if view and view.has_method("table_event"):
		view.table_event(kind, p, other)


## The strict leader changed: tell the view.
func _check_lead() -> void:
	var best := -1
	var seat := -1
	for o in players:
		if o.score > best:
			best = o.score
			seat = o.seat
		elif o.score == best:
			seat = -1
	if seat >= 0 and seat != leader_seat:
		leader_seat = seat
		_view_event("lead", players[seat])
	elif seat < 0:
		leader_seat = -1


func leader_score() -> int:
	var best := 0
	for p in players:
		best = maxi(best, p.score)
	return best


func best_face_last_throw() -> int:
	var best := 0
	for f in last_throw:
		best = maxi(best, f)
	return best


## Previous player in seat order.
func prev_player(p):
	return players[(p.seat - 1 + players.size()) % players.size()]


## Highest-scoring player other than me (Tier 2 target for bots).
func leader_other(me):
	var best = null
	for p in players:
		if p != me and (best == null or p.score > best.score):
			best = p
	return best


## Tier 2: unlocked (first time at 300+, stays unlocked) and not used since your last turn started.
func t2_available(p) -> bool:
	if not tier2:
		return false
	if not p.t2_unlocked and p.score >= Rules.TIER2_SCORE:
		p.t2_unlocked = true
		p.t2_ready = true
	return p.t2_unlocked and p.t2_ready


func mark_t2(p) -> void:
	p.t2_ready = false
	p.t2_uses += 1


## A targeted Tier 2 (an attack). Pride's Untouchable may bounce it onto the attacker.
## kind: "reroll" (Wrath, amount = dice), "pact" (Lust, amount = %), "drag" (Sloth, amount = dice).
func attack(attacker, target, kind: String, amount: int) -> void:
	mark_t2(attacker)
	var hit = target
	var source = attacker
	if view:
		say("%s %s %s." % [pname(attacker), {"reroll": "unleashes Fury on", "pact": "binds a Pact on", "drag": "Drags"}[kind], pname(target)])
	if target.sin and await target.sin.bounces(self, target, attacker, kind):
		mark_t2(target)
		target.t2_bounces += 1
		hit = attacker
		source = target
		if view:
			say("%s is Untouchable: it bounces back onto %s!" % [pname(target), pname(attacker)])
	if v4:
		hit.grudges.erase(source.seat)
		hit.grudges.append(source.seat)
		source.grudges.erase(hit.seat)  # paid back
		_view_event("attacked", hit, source)
	if view:
		match kind:
			"reroll":
				say("  %s must reroll %d best dice%s." % [pname(hit), amount, "" if hit == target else " on their next throw"])
			"pact":
				say("  %s gives %d%s of their next banked turn to %s." % [pname(hit), amount, "" if v4 else "%", pname(source)])
			"drag":
				say("  %s throws at most %d fewer dice next turn." % [pname(hit), amount])
	match kind:
		"reroll":
			if hit == target:
				reroll_best(turn.faces, amount)  # target is throwing right now
			else:
				hit.reroll_next = amount
		"pact":
			hit.pact_by = source
			hit.pact_pct = amount
		"drag":
			hit.drag = amount


## Reroll the n highest scoring dice in faces.
func reroll_best(faces: Array[int], n: int) -> void:
	var picked: Array[int] = []
	for k in n:
		var best_i := -1
		for i in faces.size():
			if faces[i] >= 4 and not picked.has(i) and (best_i < 0 or faces[i] > faces[best_i]):
				best_i = i
		if best_i < 0:
			break
		picked.append(best_i)
	for i in picked:
		faces[i] = rng.randi_range(1, 6)


func _max_throw(p) -> int:
	var sloth: int = opt("claim_sloth_fewer", 0) if claimed(p, "Sloth") else 0
	return maxi(1, p.dice - p.drag - p.fewer_now - sloth)


func indulgence_cost(p) -> int:
	if indulgence_pct > 0:
		return p.score * indulgence_pct / 100
	return Rules.INDULGENCE_COST


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
	await _power(p, "start")

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
		await _power(p, "throw")
		turn.strikes += Rules.count_strikes(turn.faces)
		if turn.strikes >= Rules.STRIKES_TO_BUST:
			if view:
				say("  %d Strikes: %s BUSTS%s." % [turn.strikes, pname(p), " and goes to Purgatory" if purgatory_on else ""])
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
				var go: bool = await _power(p, "decide") or await p.bot.wants_throw(p, self, turn.points, turn.strikes)
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
			_master("bank", p, {"banked": banked})
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


func max_buy(p) -> int:
	var n := 0
	while n < supply and _buy_price(p, n + 1) <= p.score:
		n += 1
	return n


static func _faces_str(faces: Array[int]) -> String:
	return " ".join(faces.map(func(f): return str(f)))


func _buy_price(p, n: int) -> int:
	return p.sin.buy_price(self, p, n) if p.sin else n * die_cost


func _bust(p) -> void:
	p.in_purgatory = purgatory_on
	p.busts += 1
	if v4:
		if claimed(p, "Wrath") and p.score > 0:
			var lost := mini(p.score, int(opt("claim_bust", Temptations.CLAIM_BUST_COST)))
			p.score -= lost
			if view:
				say("  Wrath's claim: %s loses %d" % [pname(p), lost])
		if claimed(p, "Gluttony") and p.dice > Rules.MIN_DICE:
			p.dice -= 1
			supply += 1
			if view:
				say("  Gluttony's claim: eats a die (%d left)" % p.dice)
		_view_event("bust", p)
		_master("bust", p, {"strikes": turn.strikes, "stake": turn.points})
	_end_turn(p, 0)
	for o in players:
		if o != p and o.sin:
			o.sin.on_other_bust(self, o, p)


func _end_turn(p, banked: int) -> void:
	p.pact_by = null  # Pact and Drag last one turn, bust or not
	p.drag = 0
	p.fewer_now = 0
	if p.pend_die > 0:  # a temptation's "lose a die": paid as the turn ends, bust or not
		var n := mini(p.pend_die, maxi(0, p.dice - Rules.MIN_DICE))
		p.dice -= n
		supply += n
		p.pend_die = 0
		if view and n > 0:
			say("  %s's debt: loses a die (%d left)" % [pname(p), p.dice])
	last_throw = turn.faces.duplicate()
	last_turn_points = banked


func _resolve_finish() -> void:
	var best := leader_score()
	var tied := players.filter(func(p): return p.score == best)
	is_tie = tied.size() > 1
	winner = tied[rng.randi_range(0, tied.size() - 1)]  # stand-in for Sudden Death


## Returns true if the player is free to take the rest of the turn.
func _try_escape(p) -> bool:
	if auto_purgatory:
		var throw := Rules.roll(rng, p.dice)
		purg_throws += 1
		p.in_purgatory = false
		if view:
			turn.redeem_faces = throw  # display only: last_throw stays as the rules have it
			say("%s throws to leave Purgatory: %s" % [pname(p), _faces_str(throw)])
		if 6 in throw:
			purg_free += 1
			if view:
				say("  A 6! Free.")
		else:
			var paid := purgatory_cost if p.score >= purgatory_cost else 0
			p.score -= paid
			purg_paid += paid
			if view:
				if paid > 0:
					say("  No 6: %s pays %d to leave Purgatory." % [pname(p), paid])
				else:
					say("  No 6, and %s can't pay: free anyway." % pname(p))
		return true
	# Indulgence. Rulebook doesn't say what happens if you can't pay; we fall back to Redemption.
	var cost := indulgence_cost(p)
	# (Affordability is checked first so the human is only asked when paying is possible; bots don't care.)
	if p.score >= cost and await p.bot.wants_indulgence(p, self):
		p.score -= cost
		p.in_purgatory = false
		if view:
			say("%s pays the Indulgence (%d) and leaves Purgatory." % [pname(p), cost])  # V2 only (sim)
		return true
	# Redemption: any 6 frees you.
	var faces := Rules.roll(rng, p.dice)
	if view:
		turn.redeem_faces = faces  # display only: last_throw stays as the rules have it
		say("%s rolls for Redemption: %s" % [pname(p), _faces_str(faces)])  # V2 only (sim)
	if 6 in faces:
		p.in_purgatory = false
		if view:
			say("  A 6! Redeemed.")  # V2 only (sim)
		return true
	if view:
		say("  No 6. Still in Purgatory.")
	return false


# ---------- Rules.V4: temptations, marks, claims (Docs/TableDesign.md §7) ----------

## Turn start: pending costs move into this turn, and maybe an offer is ready.
func _start_costs(p) -> void:
	if not force_claim.is_empty() and p.seat == int(force_claim.seat) and round_count == int(force_claim.round) \
			and not p.claims.has(force_claim.sin):
		if String(force_claim.sin).is_valid_int():  # sim: a points loss instead, to price a claim
			p.score = maxi(0, p.score - int(force_claim.sin))
		else:
			p.claims.append(force_claim.sin)
	p.fewer_now = p.pend_fewer
	p.pend_fewer = 0
	if p.pend_strike > 0:
		turn.strikes = mini(p.pend_strike, Rules.STRIKES_TO_BUST - 1)
		p.pend_strike = 0
		if view:
			say("  %s's debt: starts with %d Strike%s" % [pname(p), turn.strikes, "" if turn.strikes == 1 else "s"])
	p.turns_started += 1
	turn.tempt_ready = temptations and round_count > 1 and p.turns_started - p.last_offer_turn >= int(opt("tempt_gap", 1)) and rng.randf() < tempt_chance
	# Rules.V5: a seat comeback_gap_at or more behind gets an offer every turn.
	if temptations and round_count > 1 and not turn.tempt_ready and int(opt("comeback_gap_at", 0)) > 0 and leader_score() - p.score >= int(opt("comeback_gap_at", 0)):
		turn.tempt_ready = true


## Bank-time costs and claims, in order: Pride's claim, your debt, Greed's and Envy's cuts.
func _bank_costs(p, banked: int) -> int:
	var pride_min: int = opt("claim_pride_min", 0)
	if claimed(p, "Pride") and pride_min > 0:
		if banked < pride_min:  # Pride's claim, other form: a Bank under pride_min scores nothing
			if view:
				say("  Pride's claim: %d is under %d" % [banked, pride_min])
			banked = 0
	elif claimed(p, "Pride") and banked > 0 and banked <= p.last_bank:
		# Pride's claim: a Bank that doesn't beat your last scores half (claim_pride_half) or nothing.
		var kept: int = (banked / 2 / 5 * 5) if opt("claim_pride_half", false) else 0
		if view:
			say("  Pride's claim: %d doesn't beat %d" % [banked, p.last_bank])
		banked = kept
	elif banked > 0:
		p.last_bank = banked
	if p.pend_bank > 0 and banked > 0:
		var cut := mini(p.pend_bank, banked)
		banked -= cut
		p.pend_bank = 0
		if view:
			say("  %s's debt: -%d from this Bank" % [pname(p), cut])
	for c in [["Greed", int(opt("claim_greed", Temptations.CLAIM_GREED_CUT)), false], ["Envy", int(opt("claim_envy", Temptations.CLAIM_ENVY_CUT)), true]]:
		if not claimed(p, c[0]) or banked <= 0:
			continue
		if c[2]:  # Envy: only while you lead
			var lead := true
			for o in players:
				if o != p and o.score >= p.score + banked:
					lead = false
			if not lead:
				continue
		var cut: int = mini(c[1], banked)
		banked -= cut
		var to = sin_player(c[0])
		if to and to != p:
			to.score += cut
		if view:
			say("  %s's claim: takes %d" % [c[0], cut])
	return banked


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
	offer = scaled_offer(p, offer)  # Rules.V5: a comeback scales the gain
	_master("offer", p, {"from": from, "scaled": offer.get("scaled", 1.0)})
	var yes: bool = await p.bot.wants_temptation(self, p, from, offer)
	if view:
		say("  %s's answer: %s" % [pname(p), "accepts" if yes else "refuses"])
		_view_event("accept" if yes else "refuse", p, from)
	if not yes:
		return false
	p.offers_taken += 1
	offer_stats[offer.id][1] += 1
	var throws_now := Temptations.apply(offer, self, p)
	var free := mark_is_free(p)
	if not free:  # Rules.V5: a mark taken far behind doesn't count toward a claim
		p.marks[sname] = int(p.marks.get(sname, 0)) + 1
	p.marks_taken[sname] = int(p.marks_taken.get(sname, 0)) + 1
	_master("mark", p, {"from": from, "first": int(p.marks_taken[sname]) == 1, "free": free})
	if int(p.marks.get(sname, 0)) >= marks_to_claim:
		p.marks[sname] = 0
		if not p.claims.has(sname):
			p.claims.append(sname)
			claims_made += 1
			_master("claim", p, {"from": from})
			if view:
				say("  %s's claim: %s, for the rest of the game" % [pname(from), pname(p)])
	_check_lead()
	return throws_now


## A throw's points under this table's options: the chain multiplier, then V4's round down to 5.
func throw_score(faces: Array) -> int:
	var pts := Rules.score(Array(faces, TYPE_INT, "", null), chain, face_mult)
	return pts / 5 * 5 if round5 else pts


# ---------- Rules.V5: powers (Docs/TableDesign.md §10) ----------

## One power a turn, in its Sin's window: the Sin says whether it can change something now, then the
## player answers (a bot at once; you by tapping the seal, or the dice to let the throw stand).
## Returns true when the power throws on at once (Greed).
func _power(p, window: String) -> bool:
	if not opt("powers", false) or p.sin == null or turn.power_used or p.sin.power_window() != window:
		return false
	if not p.sin.power_ready(self, p, turn):
		return false
	_view_event("power_ready", p)
	var choice = await p.bot.wants_power(self, p, p.sin.sin_name)
	if choice == null or (choice is bool and not choice):
		return false
	turn.power_used = true
	p.powers_used += 1
	var on: bool = await p.sin.use_power(self, p, turn, choice)
	_view_event("power", p)
	return on


## Rules.V5 comeback: a seat D behind the leader sees an offer's gain x(1 + D / comeback_per), up to
## x comeback_cap. Points round down to 5 and extra dice round; a cleared Strike, x2 and a free die don't scale.
func comeback_factor(p) -> float:
	if int(opt("comeback_per", 0)) <= 0:
		return 1.0
	var d := float(maxi(0, leader_score() - p.score))
	return minf(float(opt("comeback_cap", 1.0)), 1.0 + d / float(opt("comeback_per", 200)))


func scaled_offer(p, offer: Dictionary) -> Dictionary:
	var f := comeback_factor(p)
	if f <= 1.0 or not offer.gain in ["points", "dice"]:
		return offer
	var out := offer.duplicate()
	if offer.gain == "points":
		out.g = int(offer.g * f) / 5 * 5
	else:
		out.g = int(round(offer.g * f))
	out["scaled"] = f
	return out


## Rules.V5 mark rule: a mark taken mark_free_behind or more behind the leader doesn't count toward a claim.
func mark_is_free(p) -> bool:
	var at := int(opt("mark_free_behind", 0))
	return at > 0 and leader_score() - p.score >= at


## The Master of the Dance (Docs/TableDesign.md §10): core reports facts; the view picks his line and
## shows it only when the fact it states is true. kind: start, bust, bank, offer, mark, claim, end.
func _master(kind: String, p, facts: Dictionary) -> void:
	if view and view.has_method("master_event"):
		view.master_event(kind, p, facts)


## The winner's lead over the best other seat (negative when a rival passed them off-turn, by the Vig or a claim).
func _margin() -> int:
	if winner == null:
		return 0
	var second := -1
	for o in players:
		if o != winner:
			second = maxi(second, o.score)
	return winner.score - second
