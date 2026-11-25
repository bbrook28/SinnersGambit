## One match of the step 1 game. Plain data; game/rules.gd changes it.
extends RefCounted


class Seat:
	var sin := ""              # a name from Config.SINS
	var points := 0            # never below 0
	var dice := 0              # dice this player owns
	var lent := 0              # dice lent to this player: rolled with their next roll, then they go to the supply
	var purgatory := false
	var last_roll: Array = []  # the faces of the last roll; stays until this player rolls again
	var last_score := 0        # points that roll scored (0 in Purgatory)


var cfg: Dictionary
var rng                    # anything with randi_range(a, b)
var seats: Array = []      # Seat, in turn order
var supply := 0            # dice no one holds
var turn := 0              # the seat whose turn it is
var round_number := 1      # goes up each time the turn comes back to seat 0
var phase := "fate"        # a Rules phase: FATE, GAMBIT, END or OVER
var winner := -1           # the winning seat, or -1
