## REPLY 34 item 3 (sim only): sim/sim_game.gd plus what a match timer needs from each turn: throws, bust or
## bank, dice bought, powers fired, offers shown. Read by sim/match_sim.gd. Nothing in the game uses this file.
extends "res://sim/sim_game.gd"

var last := {}  # the turn just taken: {throws, bust, buys, uses, offers}
var _uses := 0


func take_turn(p) -> void:
	var t0 := audit_throws.size()
	var a0 := audit_turns.size()
	var b0 := int(p.get_meta("buys", 0))
	var o0: int = p.offers_seen
	_uses = 0
	await super(p)
	var bust := false
	if audit_turns.size() > a0:
		bust = bool(audit_turns[audit_turns.size() - 1][4])
	last = {"throws": audit_throws.size() - t0, "bust": bust, "buys": int(p.get_meta("buys", 0)) - b0,
		"uses": _uses, "offers": p.offers_seen - o0}


func _use(p, first: bool, saved := false) -> void:
	_uses += 1
	super(p, first, saved)
