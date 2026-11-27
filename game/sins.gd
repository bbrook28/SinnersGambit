## The Sin cards: each Sin's Tier 1 and Tier 2 ability, in the words of docs/step1-rules.md (copied as written).
## The numbers that the rules use are in game/config.gd; what each ability does is in game/rules.gd.
extends RefCounted

const INFO := {
	"wrath": {
		"t1": {"key": "spark", "name": "Spark of Rage", "text": "Make a player reroll one die showing 5 or 6. If it comes up 1-3 they score 0 for it and lose 10."},
		"t2": {"key": "strike", "name": "Vengeful Strike", "text": "Target chooses: lose 50, or give you 1 die for 2 full rounds. Not the same target twice running."}},
	"greed": {
		"t1": {"key": "vig", "name": "The Vig", "text": "Passive. When an opponent buys a die, 20 of its price goes to you."},
		"t2": {"key": "deal", "name": "Cut a Deal", "text": "Target chooses: pay you 50, or give you 1 die for 1 full round. Not the same target twice running."}},
	"lust": {
		"t1": {"key": "whisper", "name": "Whisper of Desire", "text": "Before scoring, swap one of your dice with a higher die of another player's. Not if the swap is what takes you to 1000."},
		"t2": {"key": "allure", "name": "Entangling Allure", "text": "Choose 2 players; each secretly picks 1 die. Match: you take one. No match: they swap."}},
	"envy": {
		"t1": {"key": "glance", "name": "Green-Eyed Glance", "text": "Before you roll, copy any die an opponent just rolled: one of your dice is not rolled and shows that number. Not on two turns running."},
		"t2": {"key": "grasp", "name": "Jealous Grasp", "text": "Copy any Tier 1 ability used this round. Not the same one twice running."}},
	"pride": {
		"t1": {"key": "hubris", "name": "Hubris", "text": "Before you roll, declare. Beat the previous player's total and score 50 more for the roll; fail and it is 0. First player must beat 50."},
		"t2": {"key": "superiority", "name": "Superiority", "text": "Passive. The first time you are targeted each round, the attacker loses 20."}},
	"gluttony": {
		"t1": {"key": "feast", "name": "Feast", "text": "Once a round, give one of your scoring dice (4-6) to the supply and gain 150."},
		"t2": {"key": "bite", "name": "Voracious Bite", "text": "Steal 20 from a player. Not the same target twice running."}},
	"sloth": {
		"t1": {"key": "drip", "name": "Slow Drip", "text": "If you score under 60 this turn, gain 40 more."},
		"t2": {"key": "aura", "name": "Lethargic Aura", "text": "Next turn the target rolls 1 die twice and keeps the lower. You gain 10."}},
}

## The cards whose words change at a two-player table (Ben, 2026-11-26). With one opponent, "not the same target twice
## running" means not on two of your turns running, and Entangling Allure is between Lust and the other player.
const TWO := {
	"strike": "The other player chooses: lose 50, or give you 1 die for 2 full rounds. Not on two turns running.",
	"deal": "The other player chooses: pay you 50, or give you 1 die for 1 full round. Not on two turns running.",
	"allure": "You and the other player each secretly pick 1 of your own dice. Match: you take theirs. No match: the two dice swap.",
	"grasp": "Copy any Tier 1 ability used this round. Not the same one on two turns running.",
	"bite": "Steal 20 from the other player. Not on two turns running.",
}

const PASSIVE :=["vig", "drip"]                       # always on: never a button
const GRASP_OK := ["spark", "whisper", "feast", "drip"]  # the Tier 1 abilities Jealous Grasp can copy after Envy's roll


## The ability's card: {key, name, text}, or {} for an unknown key.
static func card(key: String) -> Dictionary:
	for sin in INFO:
		for t in ["t1", "t2"]:
			if INFO[sin][t].key == key:
				return INFO[sin][t]
	return {}


## The card's words at a table of this many players.
static func text(key: String, seats: int) -> String:
	if seats == 2 and TWO.has(key):
		return TWO[key]
	return str(card(key).get("text", ""))


static func ability_name(key: String) -> String:
	return str(card(key).get("name", key))


## The Sin whose ability this is.
static func sin_of(key: String) -> String:
	for sin in INFO:
		if INFO[sin].t1.key == key or INFO[sin].t2.key == key:
			return sin
	return ""


## 1 or 2.
static func tier(key: String) -> int:
	for sin in INFO:
		if INFO[sin].t2.key == key:
			return 2
	return 1


## What it costs to use (Tier 1 is free).
static func cost(cfg: Dictionary, key: String) -> int:
	return int(cfg.get(key + "_cost", 0))
