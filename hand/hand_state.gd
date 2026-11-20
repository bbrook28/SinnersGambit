## One bag hand in progress. Plain data; hand/rules.gd changes it.
extends RefCounted

var cfg: Dictionary = {}
var bag := 0              # dice still in the bag
var skulls := 0           # skulls on the table
var slots: Array = []     # Dictionaries: kind, need, cap, dice, marks, done, hidden, fills; the Target is slots[0]
var progress := 0         # pips placed toward the Target
var target_dice: Array = [] # what each die placed in the Target added, in order
var offerings := 0        # dice placed in the Offering: the Target needs 1 less each
var tax_on := false       # a Tax has fired: the Target needs cfg.tax more
var wires: Array = []     # wires dealt: {kind, slot} (slot: the engine slot a Tax watches, else -1)
var wire_pool: Array = [] # wires not yet dealt, in dealing order
var seeded := false       # a die has gone into an engine slot (the Master deals his second wire)
var seed_slot := -1       # the engine slot that first die went into
var second_wire := false  # the Master has dealt his second wire
var hunger_on := false
var revealed := false     # the Target has been met: the prize is face up
var throws := 0
var outcome := ""         # "", "won", "short", "bust"
var dance := false        # the current throw drew the bag's last die alone (the Last Dance)
var dance_reached := false
var pushed := 0           # the highest tier already cleared when a throw began (0: never threw on)
var dances := 0            # Last Dances thrown this hand (a cursed Ladder 6 can bring a second)
var cancelled := 0        # skulls a Ward cancelled
var curse_skulls := 0     # skulls from Curse rethrows
var late_on := false      # the late wire has struck: a throw began with the bag at cfg.late_bag or fewer
var late_skulls := 0      # handful dice that were skulls only because of the late wire
var decisions: Array = [] # the strong policy's per-placement values
var stops: Array = []     # the strong policy's stop calls: {now, on, throw}


func clone():
	var c = get_script().new()
	for p in ["cfg", "bag", "skulls", "progress", "offerings", "tax_on", "seeded", "seed_slot", "second_wire", "hunger_on", "revealed",
			"throws", "outcome", "dance", "dance_reached", "dances", "pushed", "cancelled", "curse_skulls", "late_on", "late_skulls"]:
		c.set(p, get(p))
	c.slots = slots.duplicate(true)
	c.target_dice = target_dice.duplicate()
	c.wires = wires.duplicate(true)
	c.wire_pool = wire_pool.duplicate()
	c.decisions = []
	c.stops = []
	return c
