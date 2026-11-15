## Temptations (Docs/TableDesign.md §7): 4 offers per Sin, each one gain and one cost, and the 7 claims.
## Rules only; the words are in ui/rules_text.gd TEMPT (by id) and CLAIMS.
## Gains: points (score now; `leader`: taken from the leader), clear (a Strike), dice (extra dice on the
## next throw), x2 (the next throw scores double), die (a free die). dice and x2 throw at once.
## Costs: lose (points now), bank (from your next Bank), strike (next turn starts with one),
## fewer (dice next turn), die (lost when this turn ends).
## when: "" any time, "s0" no Strikes yet this turn, "s1" / "s2" at least that many, "trail" someone is
## ahead of you; "trail+s0" both.
extends RefCounted

const Rules = preload("res://core/rules.gd")

const OFFERS := {
	"Wrath": [
		{"id": "w1", "gain": "clear", "g": 1, "cost": "bank", "c": 25, "when": "s2"},
		{"id": "w2", "gain": "points", "g": 60, "leader": true, "cost": "strike", "c": 1, "when": "trail"},
		{"id": "w3", "gain": "x2", "g": 1, "cost": "lose", "c": 50, "when": ""},
		{"id": "w4", "gain": "dice", "g": 2, "cost": "bank", "c": 50, "when": "s0"},
	],
	"Greed": [
		{"id": "g1", "gain": "die", "g": 1, "cost": "bank", "c": 75, "when": ""},
		{"id": "g2", "gain": "clear", "g": 1, "cost": "bank", "c": 25, "when": "s2"},
		{"id": "g3", "gain": "x2", "g": 1, "cost": "bank", "c": 50, "when": ""},
		{"id": "g4", "gain": "points", "g": 100, "cost": "die", "c": 1, "when": ""},
	],
	"Lust": [
		{"id": "l1", "gain": "x2", "g": 1, "cost": "fewer", "c": 1, "when": ""},
		{"id": "l2", "gain": "points", "g": 50, "cost": "fewer", "c": 1, "when": ""},
		{"id": "l3", "gain": "dice", "g": 2, "cost": "fewer", "c": 1, "when": "s0"},
		{"id": "l4", "gain": "clear", "g": 1, "cost": "bank", "c": 25, "when": "s1"},
	],
	"Envy": [
		{"id": "e1", "gain": "dice", "g": 2, "cost": "strike", "c": 1, "when": "trail+s0"},
		{"id": "e2", "gain": "x2", "g": 1, "cost": "strike", "c": 1, "when": "trail"},
		{"id": "e3", "gain": "die", "g": 1, "cost": "lose", "c": 75, "when": "trail"},
		{"id": "e4", "gain": "clear", "g": 1, "cost": "fewer", "c": 1, "when": "s1"},
	],
	"Pride": [
		{"id": "p1", "gain": "x2", "g": 1, "cost": "bank", "c": 50, "when": ""},
		{"id": "p2", "gain": "dice", "g": 2, "cost": "fewer", "c": 1, "when": "s0"},
		{"id": "p3", "gain": "clear", "g": 1, "cost": "lose", "c": 25, "when": "s1"},
		{"id": "p4", "gain": "points", "g": 60, "cost": "strike", "c": 1, "when": ""},
	],
	"Gluttony": [
		{"id": "u1", "gain": "dice", "g": 2, "cost": "lose", "c": 25, "when": "s0"},
		{"id": "u2", "gain": "clear", "g": 1, "cost": "die", "c": 1, "when": "s1"},
		{"id": "u3", "gain": "x2", "g": 1, "cost": "die", "c": 1, "when": ""},
		{"id": "u4", "gain": "die", "g": 1, "cost": "strike", "c": 1, "when": ""},
	],
	"Sloth": [
		{"id": "s1", "gain": "points", "g": 90, "cost": "fewer", "c": 2, "when": ""},
		{"id": "s2", "gain": "clear", "g": 1, "cost": "fewer", "c": 1, "when": "s2"},
		{"id": "s3", "gain": "die", "g": 1, "cost": "fewer", "c": 2, "when": ""},
		{"id": "s4", "gain": "points", "g": 60, "cost": "strike", "c": 1, "when": ""},
	],
}

## Claims at marks_to_claim marks (game.gd applies them; words in RulesText.CLAIMS).
## Defaults when the rule dict has no claim_* keys; Rules.V4 sets them (sim-measured, TableDesign Â§7).
const CLAIM_BUST_COST := 125     # Wrath: each bust costs you this
const CLAIM_GREED_CUT := 20      # Greed: every Bank pays Greed this
const CLAIM_LUST_THROWS := 2     # Lust: no Bank before this throw
const CLAIM_ENVY_CUT := 25       # Envy: while you lead, each Bank pays Envy this
const CLAIM_SLOTH_THROWS := 3    # Sloth (other form, claim_sloth_fewer 0): no more throws than this a turn


static func all_ids() -> Array:
	var ids := []
	for s in OFFERS:
		for o in OFFERS[s]:
			ids.append(o.id)
	return ids


## The leader other than p, if strictly ahead of p.
static func leader_ahead(game, p):
	var best = null
	for o in game.players:
		if o != p and o.score > p.score and (best == null or o.score > best.score):
			best = o
	return best


## Can this offer be made to p right now?
static func fits(offer: Dictionary, game, p) -> bool:
	var t = game.turn
	for w in String(offer.when).split("+", false):
		match w:
			"s0":
				if t.strikes > 0:
					return false
			"s1":
				if t.strikes < 1:
					return false
			"s2":
				if t.strikes < 2:
					return false
			"trail":
				if leader_ahead(game, p) == null:
					return false
	match offer.gain:
		"clear":
			if t.strikes < 1:
				return false
		"dice", "x2":
			if not game.may_throw(p) or t.x2 or t.extra_dice > 0:
				return false
		"die":
			if game.supply <= 0:
				return false
		"points":
			if offer.get("leader", false) and leader_ahead(game, p) == null:
				return false
	if offer.cost == "die" and p.dice - p.pend_die <= Rules.MIN_DICE:
		return false
	return true


## Gives p the gain and books the cost. Returns true when the gain throws at once (dice, x2).
static func apply(offer: Dictionary, game, p) -> bool:
	var t = game.turn
	match offer.gain:
		"points":
			var amt: int = offer.g
			if offer.get("leader", false):
				var lead = leader_ahead(game, p)
				amt = mini(amt, lead.score)
				lead.score -= amt
			p.score += amt
		"clear":
			t.strikes = maxi(0, t.strikes - offer.g)
		"dice":
			t.extra_dice += offer.g
		"x2":
			t.x2 = true
		"die":
			p.dice += 1
			game.supply -= 1
	match offer.cost:
		"lose":
			p.score = maxi(0, p.score - offer.c)
		"bank":
			p.pend_bank += offer.c
		"strike":
			p.pend_strike += offer.c
		"fewer":
			p.pend_fewer += offer.c
		"die":
			p.pend_die += offer.c
	return offer.gain in ["dice", "x2"]
