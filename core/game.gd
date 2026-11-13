## Runs one game of the base rules (no Sin abilities yet).
## Decisions are delegated to each player's bot so the same loop serves the sim and, later, the UI.
extends RefCounted

const Rules = preload("res://core/rules.gd")
const PlayerState = preload("res://core/player_state.gd")

const MAX_ROUNDS := 500

var players: Array = []
var supply: int
var rng := RandomNumberGenerator.new()
var round_count := 0
var winner = null


func _init(bots: Array, seed_value: int) -> void:
	rng.seed = seed_value
	for i in bots.size():
		players.append(PlayerState.new(i, bots[i]))
	supply = Rules.TOTAL_DICE - Rules.START_DICE * bots.size()


func play():
	while winner == null and round_count < MAX_ROUNDS:
		round_count += 1
		for p in players:
			take_turn(p)
			if winner != null:
				break
	return winner


func take_turn(p) -> void:
	p.turns += 1

	# Fate Phase 1: escape Purgatory.
	if p.in_purgatory and not _try_escape(p):
		return

	# Fate Phase 2-4: roll, strike check, score.
	var faces := Rules.roll(rng, p.dice)
	if Rules.count_strikes(faces) >= Rules.STRIKES_TO_BUST:
		p.in_purgatory = true
		p.busts += 1
		return
	p.score += Rules.score(faces)
	if p.score >= Rules.WIN_SCORE:
		winner = p
		return

	# Gambit Phase: buy dice.
	var n: int = clampi(p.bot.dice_to_buy(p), 0, supply)
	n = mini(n, p.score / Rules.DIE_COST)
	p.score -= n * Rules.DIE_COST
	p.dice += n
	supply -= n


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
