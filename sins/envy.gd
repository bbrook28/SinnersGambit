## Envy, the Mirror. Copies others.
## Basic, Green-Eyed Glance (after throw, once per turn): add a copy of the previous player's
## best die to this throw (only when it scores). It counts toward the multiplier; it's gone after the throw.
## Greater, Mimicry (after throw, once a round): add two copies of that die to this throw.
## (Replaced "borrow the previous player's Tier 1", 2026-11-13: copying Wrath or Greed did nothing on your turn.)
## Bot: either one on the first throw that already has a scorer.
extends "res://sins/sin.gd"

const MIMIC_COPIES := 2


func _init() -> void:
	sin_name = "Envy"


func after_throw(game, me, turn) -> void:
	if game.v4:
		_glance_v4(game, me, turn)
		return
	await _glance(game, me, turn)
	await _mimicry(game, me, turn)


## Rules.V4: automatic. The first scoring throw each turn gains a copy of the last player's best die;
## once a round (Mimicry, from 300) it gains two instead.
func _glance_v4(game, me, turn) -> void:
	var best: int = game.best_face_last_throw()
	if turn.used_t1 or best < 4:
		return
	if game.opt("glance_first_throw", false) and turn.throws > 1:
		return  # tuning: only the turn's first throw can gain the copy
	if not _has_scorer(turn):
		return
	if game.opt("glance_trail", false) and game.leader_score() <= me.score:
		return  # tuning: only while someone is ahead of Envy
	var n := 1
	if game.t2_available(me):
		game.mark_t2(me)
		n = int(game.opt("mimic", 2))
	if game.view:
		fired(game, me, "Mimicry" if n == 2 else "Green-Eyed Glance", "adds %s %d%s" % ["two" if n == 2 else "a", best, "s" if n == 2 else ""])
	for i in n:
		turn.faces.append(best)
	turn.used_t1 = true


func _has_scorer(turn) -> bool:
	for f in turn.faces:
		if f >= 4:
			return true
	return false


func _glance(game, me, turn) -> void:
	if turn.used_t1:
		return
	var best: int = game.best_face_last_throw()
	if best < 4:
		return
	if me.bot.human:
		if not await me.bot.ask(game, "Green-Eyed Glance? Add a %d to this throw (once a turn)." % best):
			return
	elif not _has_scorer(turn):
		return  # worth the most on a throw that already scores (bigger multiplier)
	if game.view:
		fired(game, me, "Green-Eyed Glance", "adds a %d" % best)
	turn.faces.append(best)
	turn.used_t1 = true


func _mimicry(game, me, turn) -> void:
	if not game.t2_available(me):
		return
	var best: int = game.best_face_last_throw()
	if best < 4:
		return
	if me.bot.human:
		if not await me.bot.ask(game, "Mimicry? Add two %ds to this throw (once a round)." % best):
			return
	elif not _has_scorer(turn):
		return
	game.mark_t2(me)
	if game.view:
		fired(game, me, "Mimicry", "adds two %ds" % best)
	for i in MIMIC_COPIES:
		turn.faces.append(best)
