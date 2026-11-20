## Plays a hand with a policy: throw, place one die, the Master answers, throw on or cash out.
## A policy: {"name": String, "choose": Callable(s, faces, moves, rng) -> move or {"reroll": index},
##            "stop": Callable(s, rng) -> bool}.
extends RefCounted

const Rules = preload("res://hand/rules.gd")


## The rng for hand number i of a run: every policy plays the same tables and dice stream per hand.
static func hand_rng(run_seed: int, i: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = run_seed * 1000003 + i
	return r


static func play_hand(cfg: Dictionary, policy: Dictionary, rng):
	return play_from(Rules.new_hand(cfg, rng), policy, rng, false)


## Plays s to its end. answer_first: a die was just placed, so the Master answers before the next throw.
static func play_from(s, policy: Dictionary, rng, answer_first: bool):
	var skip_throw := answer_first
	while not Rules.ended(s):
		if not skip_throw:
			var faces: Array[int] = Rules.throw(s, rng)
			if Rules.ended(s):
				break
			if not faces.is_empty():
				var mv: Dictionary = policy.choose.call(s, faces, Rules.legal_moves(s, faces), rng)
				while mv.has("reroll"):
					faces = Rules.reroll(s, faces, mv.reroll, rng)
					if Rules.ended(s) or faces.is_empty():
						mv = {}
						break
					mv = policy.choose.call(s, faces, Rules.legal_moves(s, faces), rng)
				if Rules.ended(s):
					break
				if not mv.is_empty():
					Rules.place(s, faces, mv)
					if Rules.ended(s):
						break
		skip_throw = false
		Rules.master_answer(s)
		if Rules.ended(s):
			break
		if s.in_hand <= 0 or policy.stop.call(s, rng):
			Rules.cash_out(s)
	return s
