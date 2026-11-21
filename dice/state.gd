## One hand of dice poker. Plain data; dice/rules.gd changes it.
extends RefCounted

var cfg: Dictionary
var rng                      # anything with randi_range(a, b)
var bag := 0                 # dice left in the bag
var row: Array = []          # kept faces in order; 0 is the wild Last Dance die
var skulls := 0              # skulls on the table
var thrown: Array = []       # the pip dice of the last throw, waiting for a keep
var last_faces: Array = []   # every face of the last throw, skulls included
var dance := false           # the last throw was the Last Dance
var throws := 0
var over := false
var busted := false
var marks := 0
var bank := 0                # marks the Sin has promised for throws already made (Wrath); paid with the hand


func clone():
	var c = get_script().new()
	c.cfg = cfg
	c.rng = rng
	c.bag = bag
	c.row = row.duplicate()
	c.skulls = skulls
	c.thrown = thrown.duplicate()
	c.last_faces = last_faces.duplicate()
	c.dance = dance
	c.throws = throws
	c.over = over
	c.busted = busted
	c.marks = marks
	c.bank = bank
	return c
