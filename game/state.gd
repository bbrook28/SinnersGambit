## One match of the step 1 game. Plain data; game/rules.gd changes it.
extends RefCounted


class Seat:
	var sin := ""              # a name from Config.SINS ("" in tests: no abilities)
	var points := 0            # never below 0
	var dice := 0              # dice this player rolls each turn: their own and any they hold from another player
	var held := 0              # of those, dice taken from another player for a time (Vengeful Strike, Cut a Deal)
	var lent := 0              # dice lent to this player: rolled with their next roll, then they go to the supply
	var bought := 0            # dice this player has bought this turn, for themselves or as a gift: at most cfg.buys_a_turn
	var purgatory := false
	var last_roll: Array = []  # the faces of the last roll; stays until this player rolls again
	var last_score := 0        # points that roll scored (0 in Purgatory)
	var last_mult := 1         # what each scoring die of that roll was worth: 0 (Purgatory, a failed Hubris), 1, or 2 (Hubris)
	# abilities
	var tier2 := false         # reached 350 once: Tier 2 is open for good
	var used_t1 := false       # used a Tier 1 this turn
	var used_t2 := false       # used a Tier 2 this turn
	var used := {}             # the abilities used on this turn of theirs (key -> true): each at most once a turn
	var spark_used := false    # Wrath: Spark of Rage used since their last turn began (once a round)
	var hubris := false        # Pride: declared for the coming roll
	var glance := 0            # Envy: the face of the temporary die for the coming roll (0: none)
	var armed := false         # Pride: Superiority is paid for, until it fires or their next turn
	var lethargic := false     # Lethargic Aura: on their next roll one die is rolled twice and the lower kept
	var last_target := {}      # ability key -> the seat it last hit ("not the same target twice running")
	var last_grasp := ""       # Envy: the ability Jealous Grasp copied last ("not the same one twice running")


var cfg: Dictionary
var rng                    # anything with randi_range(a, b)
var seats: Array = []      # Seat, in turn order
var supply := 0            # dice no one holds
var turn := 0              # the seat whose turn it is
var round_number := 1      # goes up each time the turn comes back to seat 0
var turn_count := 0        # turns passed so far
var phase := "fate"        # a Rules phase: FATE, SWAP, GAMBIT, END or OVER
var winner := -1           # the winning seat, or -1
var loans: Array = []      # dice taken for a time: {owner, taker, left (the taker's turns still to end), fresh (taken this turn)}
var t1_log: Array = []     # Tier 1 abilities used: {turn (turn_count then), key}; Jealous Grasp reads the last round of it
