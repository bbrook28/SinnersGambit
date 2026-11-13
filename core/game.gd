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


func play():
	while winner == null and round_count < MAX_ROUNDS:
		round_count += 1
		for p in players:
			take_turn(p)
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


func indulgence_cost(p) -> int:
	if indulgence_pct > 0:
		return p.score * indulgence_pct / 100
	return Rules.INDULGENCE_COST


func take_turn(p) -> void:
	p.turns += 1
	turn = TurnState.new()

	# Fate Phase 1: escape Purgatory.
	if p.in_purgatory and not _try_escape(p):
		_end_turn(0)
		return

	if p.sin:
		p.sin.before_turn(self, p, turn)

	# Fate Phase 2-4: throw (and press), Strike check, score.
	var count: int = p.dice
	if dice_choice:
		count = clampi(p.bot.dice_to_roll(p, self, 0, 0), 1, p.dice)
	while count > 0:
		turn.faces = Rules.roll(rng, count)
		turn.throws += 1
		if p.sin:
			p.sin.after_throw(self, p, turn)
		turn.strikes += Rules.count_strikes(turn.faces)
		if turn.strikes >= Rules.STRIKES_TO_BUST:
			_bust(p)
			return
		turn.points += Rules.score(turn.faces, chain, face_mult)
		if not press:
			break
		if dice_choice:
			count = clampi(p.bot.dice_to_roll(p, self, turn.points, turn.strikes), 0, p.dice)
		else:
			count = p.dice if p.bot.wants_press(p, self, turn.points, turn.strikes) else 0
		if count > 0:
			p.presses += 1

	var banked: int = turn.points
	if p.sin:
		banked = p.sin.on_bank(self, p, turn, banked)
	p.score += banked
	_end_turn(banked)

	if p.score >= Rules.WIN_SCORE:
		if finish_round:
			end_triggered = true
		else:
			winner = p
			return

	# Gambit Phase: buy dice.
	var cost: int = p.sin.die_cost(self, p) if p.sin else die_cost
	var n: int = clampi(p.bot.dice_to_buy(p, self), 0, supply)
	n = mini(n, p.score / cost)
	if n <= 0:
		return
	p.score -= n * cost
	p.dice += n
	supply -= n
	for o in players:
		if o != p and o.sin:
			o.score += o.sin.on_other_buy(self, o, p, n)


func _bust(p) -> void:
	p.in_purgatory = true
	p.busts += 1
	_end_turn(0)
	for o in players:
		if o != p and o.sin:
			o.sin.on_other_bust(self, o, p)


func _end_turn(banked: int) -> void:
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
	if p.bot.wants_indulgence(p, self) and p.score >= cost:
		p.score -= cost
		p.in_purgatory = false
		return true
	# Redemption: any 6 frees you.
	if 6 in Rules.roll(rng, p.dice):
		p.in_purgatory = false
		return true
	return false
