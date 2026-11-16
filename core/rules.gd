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



## Phase 7 table rework (Docs/TableDesign.md): V3 plus flat ability numbers, throws rounded to 5,
## temptations, marks and claims. V3 stays as it was so its tests and saves still replay.
const V4 := {
	"throw_all": true,
	"chain": 0.5,
	"face_mult": 5,
	"die_cost": 100,
	"seat_bonus": 20,
	"supply_per_player": 8,
	"auto_purgatory": true,
	"purgatory_cost": 50,
	"v4": true,             # automatic Glance / Mimicry / Whisper / Untouchable / Fury; flat numbers below
	"round5": true,         # a throw's points round down to a multiple of 5
	# Ability numbers (sim/check_v3.gd v4: every Sin wins 20-30% at 4 seats, TableDesign Â§11)
	"vig": 40, "interest": 75, "pact": 50, "feast": 75, "gorge": 40, "rage": 40,
	"glance_trail": true,   # Envy's Glance only while someone is ahead of Envy
	"hubris_targets": [150, 200, 250],
	"fury_dice": 3, "fury_trigger": 150, "fury_grudge": 100, "drag": 3,
	"temptations": true,
	"tempt_chance": 1.0,    # share of turns with an offer ready (made at the first decision it fits)
	"tempt_gap": 2,         # an offer at most every other turn of yours
	"mark_weight": 4,       # a Sin's pick weight: 1 + this per mark of it the player holds
	"marks_to_claim": 2,    # sim: at 3, claims came 0.1 a game (TableDesign §11)
	"purgatory": true,      # sim: false = a bust only loses the turn
	# Claims (sins/temptations.gd; costs measured by sim/check_v3.gd, TableDesign Â§7)
	"claim_bust": 125,      # Wrath: each bust costs you this
	"claim_greed": 20,      # Greed: every Bank pays Greed this
	"claim_lust_throws": 2, # Lust: no Bank before this throw
	"claim_envy": 25,       # Envy: while you lead, each Bank pays Envy this
	"claim_pride_min": 200, # Pride: a Bank under this scores nothing
	"claim_sloth_fewer": 2, # Sloth: you throw this many fewer dice
}

## Rules.V5 (Docs/TableDesign.md §10): V4 without Purgatory, with active powers (each Basic becomes a
## once-a-turn seal; Greater stays), comeback offers and the mark rule. V4 is untouched, so V4 replays still play.
const V5 := {
	"throw_all": true, "chain": 0.5, "face_mult": 5, "die_cost": 100, "seat_bonus": 20, "supply_per_player": 8,
	"v4": true, "v5": true, "round5": true,
	"purgatory": false, "auto_purgatory": false,
	"vig": 60, "interest": 75, "pact": 50, "gorge": 40, "mimic": 2,
	"hubris_targets": [150, 200, 250], "hubris_mult": 1.75,
	"fury_dice": 3, "fury_trigger": 300, "fury_grudge": 200, "drag": 3,
	"powers": true,
	"wrath_rethrow": 2,      # Wrath: rethrow up to this many of this throw's Strikes
	"greed_mult": 1.5,       # Greed: half the stake banks at this
	"eat": 90,               # Gluttony: eating a Strike die adds this to the stake
	"temptations": true, "tempt_chance": 1.0, "tempt_gap": 2, "mark_weight": 4, "marks_to_claim": 2,
	"comeback_per": 200,     # an offer's gain x(1 + D / comeback_per) for a seat D behind the leader...
	"comeback_cap": 3.0,     # ...up to x this
	"comeback_gap_at": 150,  # a seat this far behind gets an offer every turn
	"mark_free_behind": 150, # a mark taken this far behind doesn't count toward a claim (it still counts for Solo endings)
	"claim_bust": 125, "claim_greed": 20, "claim_lust_throws": 2, "claim_envy": 25, "claim_pride_min": 200, "claim_sloth_fewer": 2,
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
