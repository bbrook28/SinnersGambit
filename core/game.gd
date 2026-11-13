## Runs one game. Decisions are delegated to each player's bot, and Sin abilities
## hook in at fixed timing windows (see sins/sin.gd), so the same loop serves the sim and, later, the UI.
extends RefCounted

const Rules = preload("res://core/rules.gd")
const PlayerState = preload("res://core/player_state.gd")
const TurnState = preload("res://core/turn_state.gd")

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
	press = options.get("press", false) or dice_choice
	seat_bonus = options.get("seat_bonus", 0)
	indulgence_pct = options.get("indulgence_pct", 0)
	chain = options.get("chain", 0.0)
	face_mult = options.get("face_mult", 10)
	die_cost = options.get("die_cost", Rules.DIE_COST)
	tier2 = options.get("tier2", false)
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
	while winner == null and round_count < MAX_ROUNDS:
		round_count += 1
		for p in players:
			await take_turn(p)
			if winner != null:
				return winner
		if end_triggered:
			_resolve_finish()
	return winner


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
	if view:
		match kind:
			"reroll":
				say("  %s must reroll %d best dice%s." % [pname(hit), amount, "" if hit == target else " on their next throw"])
			"pact":
				say("  %s gives %d%% of their next banked turn to %s." % [pname(hit), amount, pname(source)])
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
	return maxi(1, p.dice - p.drag)


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

	if p.sin:
		await p.sin.before_turn(self, p, turn)

	# Fate Phase 2-4: throw (and press), Strike check, score.
	var count: int = p.dice
	if dice_choice:
		count = clampi(await p.bot.dice_to_roll(p, self, 0, 0), 1, _max_throw(p))
	while count > 0:
		turn.faces = Rules.roll(rng, count)
		turn.throws += 1
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
		turn.strikes += Rules.count_strikes(turn.faces)
		if turn.strikes >= Rules.STRIKES_TO_BUST:
			if view:
				say("  %d Strikes: %s BUSTS and goes to Purgatory." % [turn.strikes, pname(p)])
			_bust(p)
			await beat(p, "end")
			return
		turn.throw_points = Rules.score(turn.faces, chain, face_mult)
		turn.points += turn.throw_points
		if view:
			say("  +%d (turn %d, Strikes %d)" % [turn.throw_points, turn.points, turn.strikes])
		await beat(p, "throw")
		if not press:
			break
		if dice_choice:
			count = clampi(await p.bot.dice_to_roll(p, self, turn.points, turn.strikes), 0, _max_throw(p))
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
		var cut: int = banked * p.pact_pct / 100
		p.pact_by.score += cut  # like Spark of Rage, 1000 reached off-turn wins on their next turn
		banked -= cut
		if view and cut > 0:
			say("  Binding Pact: %s takes %d." % [pname(p.pact_by), cut])
	p.score += banked
	if view:
		say("%s banks %d (score %d)." % [pname(p), banked, p.score])
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
	p.in_purgatory = true
	p.busts += 1
	_end_turn(p, 0)
	for o in players:
		if o != p and o.sin:
			o.sin.on_other_bust(self, o, p)


func _end_turn(p, banked: int) -> void:
	p.pact_by = null  # Pact and Drag last one turn, bust or not
	p.drag = 0
	last_throw = turn.faces.duplicate()
	last_turn_points = banked


func _resolve_finish() -> void:
	var best := leader_score()
	var tied := players.filter(func(p): return p.score == best)
	is_tie = tied.size() > 1
	winner = tied[rng.randi_range(0, tied.size() - 1)]  # stand-in for Sudden Death


## Returns true if the player is free to take the rest of the turn.
func _try_escape(p) -> bool:
	# Indulgence. Rulebook doesn't say what happens if you can't pay; we fall back to Redemption.
	var cost := indulgence_cost(p)
	# (Affordability is checked first so the human is only asked when paying is possible; bots don't care.)
	if p.score >= cost and await p.bot.wants_indulgence(p, self):
		p.score -= cost
		p.in_purgatory = false
		if view:
			say("%s pays the Indulgence (%d) and leaves Purgatory." % [pname(p), cost])
		return true
	# Redemption: any 6 frees you.
	var faces := Rules.roll(rng, p.dice)
	if view:
		turn.redeem_faces = faces  # display only: last_throw stays as the rules have it
		say("%s rolls for Redemption: %s" % [pname(p), _faces_str(faces)])
	if 6 in faces:
		p.in_purgatory = false
		if view:
			say("  A 6! Redeemed.")
		return true
	if view:
		say("  No 6. Still in Purgatory.")
	return false
