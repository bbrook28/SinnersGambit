## Greed, the Hoarder. The economy.
## T1 The Vig (passive): when an opponent buys a die, 17 of its price goes to Greed. (15: 12% win, 20: 18%.)
## T2 Interest (Gambit): if you buy no dice this turn, gain INTEREST_PCT% of your score, max INTEREST_CAP.
## (5%, max 50: 12.5%. 8%, max 60: 15.2%.)
extends "res://sins/sin.gd"

const Rules = preload("res://core/rules.gd")

const VIG := 17
const INTEREST_PCT := 8
const INTEREST_CAP := 60


func _init() -> void:
	sin_name = "Greed"


func on_other_buy(_game, _me, _other, n: int) -> int:
	return int(game_opt(_game, "vig", VIG)) * n


func gambit(game, me, bought: int) -> void:
	if bought > 0:
		return
	var gain: int = game.opt("interest", 0) if game.v4 else mini(INTEREST_CAP, me.score * INTEREST_PCT / 100)
	me.score += gain
	game.mark_t2(me)
	if game.view:
		fired(game, me, "Interest", "+%d for buying nothing" % gain)


static func game_opt(game, key: String, default):
	return game.opt(key, default) if game else default


# V5 power (Docs/TableDesign.md §10): bank half the stake at greed_mult, then throw on.
func power_window() -> String:
	return "decide"


func power_ready(game, me, turn) -> bool:
	return turn.points >= 10 and game.may_throw(me)


func use_power(game, me, turn, _choice) -> bool:
	var half: int = turn.points / 2 / 5 * 5
	var banked: int = int(half * float(game.opt("greed_mult", 1.5))) / 5 * 5
	me.score += banked
	turn.points -= half
	if game.view:
		fired(game, me, "Cash Out", "banks %d of %d as %d, throws on" % [half, half * 2, banked])
	return true
