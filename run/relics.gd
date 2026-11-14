## The 30 relics (Docs/RunDesign.md §5). Rules only, no UI.
## A relic row is an Array of {id, n}: n is the relic's own counter (Pilgrim's Staff, Pyre).
## Each turn the row becomes `fx` (effective()): how many times each relic fires, after Mirror Shard and
## Envy's kit. Every hook reads fx, so a copied relic simply counts twice.
## Hooks: on_throw, on_keep, on_bank, on_bust (round.gd asks holy_water), on_round_end.
extends RefCounted

const C := "C"
const U := "U"
const R := "R"

## id: [name, rarity, text]. Order is the doc's numbering.
const LIST := {
	"rosary": ["Rosary", U, "Each 6 you keep adds +1 Mult."],
	"gilt_pip": ["Gilt Pip", C, "Each 4 you keep scores 15 more Points."],
	"knuckle": ["Saint's Knuckle", C, "Each 5 you keep scores 15 more Points."],
	"votive": ["Votive Candle", C, "+50 Points on your first throw each turn."],
	"bell": ["Cracked Bell", U, "A single 3 can be kept, for 15 Points."],
	"plate": ["Collection Plate", C, "+1 gold each time you Bank."],
	"ossuary": ["Ossuary", C, "Your first throw each turn has one extra die."],
	"bone_dice": ["Bone Dice", C, "A set of 1s adds +3 more Mult."],
	"reliquary": ["Reliquary", C, "When you Bank, +5 Points per die you own."],
	"psalter": ["Psalter", C, "Bank after a single throw: +4 Mult."],
	"sexton": ["Sexton's Key", C, "The shop offers one more relic."],
	"beads": ["Prayer Beads", U, "A 4, 5 and 6 in one throw keep as a set (+2 Mult)."],
	"censer": ["Censer", U, "+3 Mult each time you keep every die."],
	"nail": ["Martyr's Nail", U, "When you Bank, +1 Mult per die left unkept."],
	"holy_water": ["Holy Water", U, "Once a turn, a bust rethrows instead."],
	"hourglass": ["Hourglass", U, "When you Bank, +2 Mult per turn left this round."],
	"ember": ["Ember", U, "+1 Mult for each round you busted in, this run."],
	"pilgrim": ["Pilgrim's Staff", U, "Gains +1 Mult for every round you clear."],
	"calf": ["Golden Calf", U, "+1 Mult for every 5 gold you hold."],
	"chalice": ["Twin Chalice", U, "Your largest set each turn counts one die bigger."],
	"hair_shirt": ["Hair Shirt", U, "+5 Mult on every Bank, but single dice can't be kept."],
	"gargoyle": ["Gargoyle", U, "+1 Mult for each throw after your second."],
	"tithe": ["Tithe Box", U, "Interest pays up to 10 gold, not 5."],
	"almoner": ["Almoner's Purse", U, "Unused turns pay 3 gold each, not 1."],
	"candelabra": ["Candelabra", R, "+1 Mult for every relic you own."],
	"pyre": ["Pyre", U, "Each round you bust in adds 10 Points to your 6s."],
	"halo": ["Halo", R, "Bank with a set of four or more kept: x2 total."],
	"mirror": ["Mirror Shard", R, "Copies the relic to its right."],
	"thorn": ["Thorn Crown", R, "x2 total, but one fewer turn each round."],
	"last_rites": ["Last Rites", R, "Bank with exactly one die left unkept: x2 total."],
}
## Relics that double the total (the x2 sources, RunDesign §11).
const X2 := ["halo", "thorn", "last_rites"]


static func name_of(id: String) -> String:
	return LIST[id][0]


static func rarity(id: String) -> String:
	return LIST[id][1]


static func text(id: String) -> String:
	return LIST[id][2]


static func ids(rar := "") -> Array:
	var out: Array = []
	for id in LIST:
		if rar == "" or LIST[id][1] == rar:
			out.append(id)
	return out


## How often each relic fires this turn. row: the relics in play, left to right.
## Mirror Shard adds one firing of the relic to its right (not another Mirror). Envy's kit: the
## leftmost relic fires twice. Counters (Pilgrim's Staff, Pyre) add up per firing.
static func effective(row: Array, envy_kit: bool) -> Dictionary:
	var fx := {"_pilgrim": 0, "_pyre": 0, "_count": row.size()}
	for i in row.size():
		var times := 2 if envy_kit and i == 0 else 1
		var id: String = row[i].id
		if id == "mirror":
			if i + 1 < row.size() and row[i + 1].id != "mirror":
				_add(fx, row[i + 1], times)
			continue
		_add(fx, row[i], times)
	return fx


static func _add(fx: Dictionary, r: Dictionary, times: int) -> void:
	fx[r.id] = fx.get(r.id, 0) + times
	if r.id == "pilgrim":
		fx._pilgrim += int(r.get("n", 0)) * times
	elif r.id == "pyre":
		fx._pyre += int(r.get("n", 0)) * times


# ---------- rule changes (read by round.gd) ----------

static func single_ok(fx: Dictionary, v: int, cfg: Dictionary) -> bool:
	if fx.has("hair_shirt"):
		return false
	if v == 3 and fx.has("bell"):
		return true
	return v in cfg.singles


static func single_points(fx: Dictionary, v: int) -> int:
	return 15 if v == 3 else v * 5


static func extra_first_dice(fx: Dictionary) -> int:
	return fx.get("ossuary", 0)


static func turns_lost(fx: Dictionary) -> int:
	return 1 if fx.has("thorn") else 0


static func interest_cap(fx: Dictionary, cfg: Dictionary) -> int:
	return cfg.interest_cap + 5 * fx.get("tithe", 0)


static func unused_turn_pay(fx: Dictionary, cfg: Dictionary) -> int:
	return cfg.unused_turn_gold + 2 * fx.get("almoner", 0)


static func shop_relics(fx: Dictionary, cfg: Dictionary) -> int:
	return cfg.shop_relics + fx.get("sexton", 0)


static func holy_waters(fx: Dictionary) -> int:
	return fx.get("holy_water", 0)


# ---------- hooks ----------

## A throw lands (before keeping). Returns Points added.
static func on_throw(fx: Dictionary, st: Dictionary) -> int:
	if st.throws == 1:
		return 50 * fx.get("votive", 0)
	return 0


## One kept group: v face, c dice. Returns [Points, Mult] added by relics.
static func on_keep(fx: Dictionary, v: int, c: int, is_set: bool) -> Array:
	var p := 0
	var m: int = 0
	if v == 6:
		m += c * fx.get("rosary", 0)
		p += c * 10 * fx._pyre
	elif v == 4:
		p += c * 15 * fx.get("gilt_pip", 0)
	elif v == 5:
		p += c * 15 * fx.get("knuckle", 0)
	elif v == 1 and is_set:
		m += 3 * fx.get("bone_dice", 0)
	return [p, m]


## Keeping every die thrown. Returns Mult added.
static func on_keep_all(fx: Dictionary) -> int:
	return 3 * fx.get("censer", 0)


## Bank. Returns [Points, Mult, times x2, gold].
## info: unkept, owned (dice), throws, turns_left, gold, busted_rounds, big_set (size after Chalice).
static func on_bank(fx: Dictionary, info: Dictionary) -> Array:
	var p: int = 5 * info.owned * fx.get("reliquary", 0)
	var m: int = 0
	var x: int = 0
	m += info.unkept * fx.get("nail", 0)
	if info.throws == 1:
		m += 4 * fx.get("psalter", 0)
	m += 2 * info.turns_left * fx.get("hourglass", 0)
	m += info.busted_rounds * fx.get("ember", 0)
	m += fx._pilgrim
	m += (info.gold / 5) * fx.get("calf", 0)
	m += 5 * fx.get("hair_shirt", 0)
	m += maxi(0, info.throws - 2) * fx.get("gargoyle", 0)
	m += fx._count * fx.get("candelabra", 0)
	if info.big_set >= 4:
		x += fx.get("halo", 0)
	x += fx.get("thorn", 0)
	if info.unkept == 1:
		x += fx.get("last_rites", 0)
	return [p, m, x, fx.get("plate", 0)]


## Round end: scaling relics grow. row is mutated (counters live on the relic).
static func on_round_end(row: Array, cleared: bool, busted: bool) -> void:
	for r in row:
		if r.id == "pilgrim" and cleared:
			r.n = int(r.get("n", 0)) + 1
		elif r.id == "pyre" and busted:
			r.n = int(r.get("n", 0)) + 1
