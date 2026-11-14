## Sinners' Gambit base rules: constants and pure dice helpers. No UI, no state.
extends RefCounted

const WIN_SCORE := 1000
const START_DICE := 3
const MIN_DICE := 2
const TOTAL_DICE := 27
const DIE_COST := 100
const STRIKES_TO_BUST := 3
const INDULGENCE_COST := 50
const TIER2_SCORE := 300

## Phase 1 rule set (sim run 5, 2026-11-13). Pass to Game.new() as options.
const V2 := {
	"dice_choice": true,  # each throw, choose how many dice; Strikes add up; bank any time
	"chain": 0.5,         # +x0.5 per extra scoring die in one throw
	"face_mult": 5,       # 4/5/6 = 20/25/30
	"die_cost": 100,
	"seat_bonus": 20,     # seat N starts with 20 x (N-1)
	"supply_per_player": 8,
}

## Phase 0 simplification (2026-11-13): the default game. Pass to Game.new() as options.
## First Game mode (UI) = V3 with "tier2" off at a table of 4.
const V3 := {
	"throw_all": true,      # every throw uses all your dice; after a safe throw, throw again or bank
	"chain": 0.5,           # +x0.5 per extra scoring die in one throw
	"face_mult": 5,         # 4/5/6 = 20/25/30
	"die_cost": 100,
	"seat_bonus": 20,       # seat N starts with 20 x (N-1)
	"supply_per_player": 8,
	"auto_purgatory": true, # turn starts in Purgatory: free throw of all dice, any 6 frees you,
	"purgatory_cost": 50,   # otherwise you pay this (nothing if you can't); then play the turn as normal
}


static func roll(rng: RandomNumberGenerator, count: int) -> Array[int]:
	var faces: Array[int] = []
	for i in count:
		faces.append(rng.randi_range(1, 6))
	return faces


## 1s and 2s are Strikes.
static func count_strikes(faces: Array[int]) -> int:
	var n := 0
	for f in faces:
		if f <= 2:
			n += 1
	return n


## 4/5/6 score 40/50/60. 1-3 score nothing.
## chain (option under test): each extra scoring die in the same roll adds this much multiplier.
## face_mult (option under test): points per pip on a scoring die. Rulebook = 10.
static func score(faces: Array[int], chain := 0.0, face_mult := 10) -> int:
	var total := 0
	var scorers := 0
	for f in faces:
		if f >= 4:
			total += f * face_mult
			scorers += 1
	if scorers > 1:
		total = int(total * (1.0 + chain * (scorers - 1)))
	return total
