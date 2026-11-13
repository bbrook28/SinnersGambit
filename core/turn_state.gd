## State of the turn in progress.
extends RefCounted

var faces: Array[int] = []  # current throw, editable by after_throw hooks
var points := 0             # turn points so far
var strikes := 0            # Strikes so far
var throws := 0
var used_t1 := false        # once-per-turn Tier 1 used
var min_points := -1        # Pride's Hubris: must beat this to score (-1 = no call)
var used_t1b := false       # once-per-turn flag for a Tier 1 Envy borrowed (Mimicry)
