## One hand in progress. Plain data; hand/rules.gd changes it.
extends RefCounted

var cfg: Dictionary = {}
var in_hand := 0          # dice you still throw
var skulls := 0           # skulls on the table
var slots: Array = []     # Dictionaries: kind, need, dice, cap, countdown, marks, done, gone
var target_slot := 0
var progress := 0         # pips placed toward the Target
var rerolls := 0          # reroll tokens claimed and unspent
var throws := 0
var outcome := ""         # "", "won", "short", "bust"
var dance := false        # the current faces came from a one-die throw (the Last Dance)
var dance_reached := false
var decisions: Array = [] # the strong policy's per-placement values


func clone():
	var c = get_script().new()
	c.cfg = cfg
	c.in_hand = in_hand
	c.skulls = skulls
	c.slots = slots.duplicate(true)
	c.target_slot = target_slot
	c.progress = progress
	c.rerolls = rerolls
	c.throws = throws
	c.outcome = outcome
	c.dance = dance
	c.dance_reached = dance_reached
	c.decisions = []
	return c
