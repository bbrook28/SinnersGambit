## State of the turn in progress.
extends RefCounted

var faces: Array[int] = []  # current throw, editable by after_throw hooks
var points := 0             # turn points so far
var strikes := 0            # Strikes so far
var throws := 0
var throw_points := 0       # points from the latest throw (UI)
var redeem_faces: Array[int] = []  # Redemption roll (UI)
var used_t1 := false        # once-per-turn Tier 1 used
var min_points := -1        # Pride's Hubris: must beat this to score (-1 = no call)
var used_t1b := false       # once-per-turn flag for a Tier 1 Envy borrowed (Mimicry)
var tempt_ready := false    # an offer may still be made this turn (Rules.V4)
var x2 := false             # the next throw scores double (a temptation)
var extra_dice := 0         # the next throw has this many more dice (a temptation)
var lazy_used := 0         # Sloth's Lazy Bones: Strikes ignored this turn
var power_used := false     # Rules.V5: this turn's power (the seal) is spent
var face_pts := 0          # the turn's face points so far, before chain (a bust keeps half: Rules.V5 "soften")
