## Lust, the Temptress. Takes what others have.
## T1 Whisper of Desire (after throw, once per turn): swap one of your 3s for the best face
## in the previous player's last throw; if you have no 3, you may swap a 2 (cancels that Strike).
## (Any die: 33% win. 3s only: 9%. 2 first: 20%.)
## T2 Binding Pact (Gambit): name an opponent; you take PACT_PCT% of their next banked turn. Bot: the leader.
## (25%: 18.4%. 20%: 17.0%. 15%: 13.6%.)
extends "res://sins/sin.gd"

const PACT_PCT := 15


func _init() -> void:
	sin_name = "Lust"


func after_throw(game, me, turn) -> void:
	if turn.used_t1:
		return
	var best: int = game.best_face_last_throw()
	if best < 4:
		return
	var i: int = turn.faces.find(3)
	if i < 0:
		i = turn.faces.find(2)
	if i < 0:
		return
	if me.bot.human and not await me.bot.ask(game, "Whisper of Desire? Swap your %d for a %d (once a turn)." % [turn.faces[i], best]):
		return
	if game.view:
		fired(game, me, "Whisper of Desire", "swaps a %d for a %d" % [turn.faces[i], best])
	turn.faces[i] = best
	turn.used_t1 = true


func gambit(game, me, _bought: int) -> void:
	var target = await pick_target(game, me, "Binding Pact (take %d%% of their next banked turn)" % PACT_PCT, game.leader_other(me))
	if target:
		await game.attack(me, target, "pact", PACT_PCT)
