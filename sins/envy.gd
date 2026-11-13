## Envy, the Mirror. Copies others.
## T1 Green-Eyed Glance (after throw, once per turn): add a temporary die to this throw
## showing the best face in the previous player's last throw. It counts toward the combo.
## T2 Mimicry (before roll, once per round): gain the previous player's Tier 1, on top of your own,
## for your own turn only: borrowed passives (Spark of Rage, The Vig) don't fire on others' turns. Bot: always.
## (Until your next turn, passives included: 16.7%. Own turn only: 15.4%.)
extends "res://sins/sin.gd"

var borrowed = null  # a fresh instance of the previous player's Sin; only its Tier 1 hooks are called
## Borrowed passives (Spark of Rage, The Vig) also fire on other players' turns until your next turn.
const MIMIC_PASSIVES := false


func _init() -> void:
	sin_name = "Envy"


func before_turn(game, me, turn) -> void:
	borrowed = null
	if game.t2_available(me):
		var prev = game.prev_player(me)
		if prev.sin and prev.sin.get_script() != get_script():
			if not me.bot.human or await me.bot.ask(game, "Mimicry? Borrow %s's Tier 1 (%s) for this turn." % [game.pname(prev), prev.sin.sin_name]):
				borrowed = prev.sin.get_script().new()
				game.mark_t2(me)
				if game.view:
					fired(game, me, "Mimicry", "borrows %s's Tier 1" % prev.sin.sin_name)
	if borrowed:
		await borrowed.before_turn(game, me, turn)


func after_throw(game, me, turn) -> void:
	if borrowed:
		# The borrowed Tier 1 gets its own once-per-turn flag.
		var own: bool = turn.used_t1
		turn.used_t1 = turn.used_t1b
		await borrowed.after_throw(game, me, turn)
		turn.used_t1b = turn.used_t1
		turn.used_t1 = own
	await _glance(game, me, turn)


func on_bank(game, me, turn, points: int) -> int:
	return borrowed.on_bank(game, me, turn, points) if borrowed else points


func die_cost(game, me) -> int:
	return borrowed.die_cost(game, me) if borrowed else game.die_cost


func on_other_bust(game, me, other) -> void:
	if borrowed and MIMIC_PASSIVES:
		borrowed.on_other_bust(game, me, other)


func on_other_buy(game, me, other, n: int) -> int:
	return borrowed.on_other_buy(game, me, other, n) if borrowed and MIMIC_PASSIVES else 0


func _glance(game, me, turn) -> void:
	if turn.used_t1:
		return
	var best: int = game.best_face_last_throw()
	if best < 4:
		return
	if me.bot.human:
		if not await me.bot.ask(game, "Green-Eyed Glance? Add a %d to this throw (once a turn)." % best):
			return
	else:
		# Worth the most on a throw that already has scorers (bigger combo).
		var scorers := 0
		for f in turn.faces:
			if f >= 4:
				scorers += 1
		if scorers == 0:
			return
	if game.view:
		fired(game, me, "Green-Eyed Glance", "adds a %d" % best)
	turn.faces.append(best)
	turn.used_t1 = true
