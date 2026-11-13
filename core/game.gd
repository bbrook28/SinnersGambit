## Runs one game of the base rules (no Sin abilities yet).
## Decisions are delegated to each player's bot so the same loop serves the sim and, later, the UI.
extends RefCounted

const Rules = preload("res://core/rules.gd")
const PlayerState = preload("res://core/player_state.gd")

const MAX_ROUNDS := 500

## Rule options under test. Defaults = rulebook as written.
## finish_round: reaching 1000 ends the game after the round completes; highest score wins.
## press: after a safe roll you may roll all your dice again. Points and Strikes add up over the turn.
var finish_round := false
var press := false

var players: Array = []
var supply: int
var rng := RandomNumberGenerator.new()
var round_count := 0
var winner = null
var end_triggered := false  # someone reached 1000 this round (finish_round mode)
var is_tie := false


func _init(bots: Array, seed_value: int, options := {}) -> void:
	rng.seed = seed_value
	finish_round = options.get("finish_round", false)
	press = options.get("press", false)
	for i in bots.size():
		players.append(PlayerState.new(i, bots[i]))
	supply = Rules.TOTAL_DICE - Rules.START_DICE * bots.size()


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


func take_turn(p) -> void:
	p.turns += 1

	# Fate Phase 1: escape Purgatory.
	if p.in_purgatory and not _try_escape(p):
		return

	# Fate Phase 2-4: roll (and press), strike check, score.
	var turn_points := 0
	var strikes := 0
	while true:
		var faces := Rules.roll(rng, p.dice)
		strikes += Rules.count_strikes(faces)
		if strikes >= Rules.STRIKES_TO_BUST:
			p.in_purgatory = true
			p.busts += 1
			return
		turn_points += Rules.score(faces)
		if not press or not p.bot.wants_press(p, self, turn_points, strikes):
			break
		p.presses += 1
	p.score += turn_points

	if p.score >= Rules.WIN_SCORE:
		if finish_round:
			end_triggered = true
		else:
			winner = p
			return

	# Gambit Phase: buy dice.
	var n: int = clampi(p.bot.dice_to_buy(p, self), 0, supply)
	n = mini(n, p.score / Rules.DIE_COST)
	p.score -= n * Rules.DIE_COST
	p.dice += n
	supply -= n


func _resolve_finish() -> void:
	var best := leader_score()
	var tied := players.filter(func(p): return p.score == best)
	is_tie = tied.size() > 1
	winner = tied[rng.randi_range(0, tied.size() - 1)]  # stand-in for Sudden Death


## Returns true if the player is free to take the rest of the turn.
func _try_escape(p) -> bool:
	# Indulgence. Rulebook doesn't say what happens below 50 points; we fall back to Redemption.
	if p.bot.pay_indulgence and p.score >= Rules.INDULGENCE_COST:
		p.score -= Rules.INDULGENCE_COST
		p.in_purgatory = false
		return true
	# Redemption: any 6 frees you.
	if 6 in Rules.roll(rng, p.dice):
		p.in_purgatory = false
		return true
	return false
