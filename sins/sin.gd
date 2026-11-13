## Base Sin. Each hook is a timing window; override the ones the Sin uses.
## `me` is the PlayerState holding this Sin. `turn` is the active TurnState.
extends RefCounted

var sin_name := "None"


## Before roll, own turn. Pride declares here.
func before_turn(_game, _me, _turn) -> void:
	pass


## After each throw on your own turn, before the Strike check. May edit turn.faces / me.dice.
func after_throw(_game, _me, _turn) -> void:
	pass


## When you bank. Return the adjusted turn points.
func on_bank(_game, _me, turn, points: int) -> int:
	return points


## Price you pay for one die.
func die_cost(game, _me) -> int:
	return game.die_cost


## Passive: another player busted.
func on_other_bust(_game, _me, _other) -> void:
	pass


## Passive: another player bought n dice. Return points they pay to you (taken out of the bank's share).
func on_other_buy(_game, _me, _other, _n: int) -> int:
	return 0


# --- Tier 2 hooks (only called when Game.tier2 is on). Keep Tier 1 and Tier 2 in
# separate methods: Envy's Mimicry borrows only the Tier 1 hooks above.

## After roll, another player's turn: they just threw (turn.faces), before their own Sin reacts.
func on_other_throw(_game, _me, _other, _turn) -> void:
	pass


## Gambit Phase, own turn, after buying (bought = dice bought this turn). Not called on a bust.
func gambit(_game, _me, _bought: int) -> void:
	pass


## Total price for buying n dice this turn.
func buy_price(game, me, n: int) -> int:
	return n * die_cost(game, me)


## Another player's Tier 2 targets you (kind: "reroll", "pact", "drag"). Return true to bounce it back (Pride).
func bounces(_game, _me, _attacker, _kind: String) -> bool:
	return false


## Log an ability firing (UI only). Call as `if game.view: fired(game, me, "Feast", "...")`.
func fired(game, me, ability: String, what: String) -> void:
	game.say("  %s's %s: %s" % [game.pname(me), ability, what])


## Human picks an opponent for a targeted Tier 2, or null to skip. Bots use bot_pick.
func pick_target(game, me, ability: String, bot_pick):
	if not me.bot.human:
		return bot_pick
	return await me.bot.choose_target(game, me, ability)
