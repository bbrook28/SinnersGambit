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
	_oot = []
	_wager = {}
	_fall = 0
	_dead = []
	_sk = []
	_raise = 0
	var d0: int = p.dice
	await super(p)
	var bust := false
	if audit_turns.size() > a0:
		bust = bool(audit_turns[audit_turns.size() - 1][4])
	last = {"throws": audit_throws.size() - t0, "bust": bust, "buys": int(p.get_meta("buys", 0)) - b0,
		"uses": _uses, "offers": p.offers_seen - o0, "oot": _oot.duplicate(), "dead": _dead.duplicate()}
	if p.seat != 0 and str(opt("oot", "none")) != "none":
		_settle_wager(p, bust and int(_wager.get("throw", -1)) == int(last.throws))
		oot_stats.rival_turns += 1
		oot_stats.rival_busts += 1 if bust else 0
		for k in _sk:
			oot_stats["rs%d_t" % k] = int(oot_stats.get("rs%d_t" % k, 0)) + 1
			oot_stats["rs%d_b" % k] = int(oot_stats.get("rs%d_b" % k, 0)) + (1 if bust else 0)
		if _raise > 0:
			if bust:
				players[0].score += _raise
				oot_stats.net += _raise
				oot_stats.raise_won += 1
			else:
				players[0].score -= 50
				p.score += 50
				oot_stats.net -= 50
		var dk := "bd%d" % clampi(d0, 3, 8)
		oot_stats[dk + "_t"] = int(oot_stats.get(dk + "_t", 0)) + 1
		oot_stats[dk + "_b"] = int(oot_stats.get(dk + "_b", 0)) + (1 if bust else 0)
		var sn: Array = _seen.get(p.seat, [0, 0])
		_seen[p.seat] = [sn[0] + 1, sn[1] + (1 if bust else 0)]
		if _fall > 0:
			if bust:
				var w: int = _fall_pay * _fall / 50
				players[0].score += w
				oot_stats.net += w
				oot_stats.fall_won += 1
			else:
				players[0].score -= _fall
				p.score += _fall
				oot_stats.net -= _fall
		if _oot.is_empty():
			oot_stats.rival_turns_none += 1
	oot_stats.low = mini(int(oot_stats.low), players[0].score)


func _use(p, first: bool, saved := false) -> void:
	_uses += 1
	super(p, first, saved)


## REPLY 35/38 item 3 (sim only): out-of-turn decisions for seat 0 (you) on a rival's turn. opt "oot":
## "wager", "hex" or "both". Each prompt is shown only when it is live (both answers are plausible); every
## prompt shown, taken or not, is a decision. last.oot lists them as [throw index, "wager"|"hex"].
##   wager -- before a rival's 2nd+ throw (it is pressing a stake of 80+): put wager_stake (50) on it busting
##            this throw. It busts: you take half the stake that breaks. It doesn't: your 50 goes to it.
##            wager_odds=fair: the Master prices the long shot (bust, or survive) by the dice; you win
##            50 x (1 - q) / q at chance q; you lose: your 50 goes to the rival. wager_from / wager_every: when.
##   fall  -- at a rival's turn start: 50 that it busts this turn. It busts: the Master pays you 100. It banks:
##            your 50 goes to it. You judge by its busts so far this match (from 1 in 2).
##   hex   -- once a round, after a rival's throw would leave it on 2 Strikes: pay hex_cost (60) to turn its
##            best scorer into a Strike, so the throw busts it.
var _oot: Array = []
var _wager := {}
var hex_round := -1
var _fall := 0  # the fall bet's stake this turn
var _fall_pay := 0
var _dead: Array = []
var _sk: Array = []  # a rival's Strikes before each of its throws after the first (the raise's price table)
var _raise := 0      # the raise's pay this turn, 0 = none taken
## raise: P(the turn busts | Strikes before a later throw), measured (sim/match_sim.gd today, 4 seats, fall+hex off)
const RAISE_RATE := {0: 0.31, 1: 0.51, 2: 0.84}  # per throw of this turn (a rival's): true when that throw could not bust it
## A rival's turn busts this often by its dice at turn start (measured: sim/match_sim.gd today, 4 seats).
const FALL_RATE := {3: 0.50, 4: 0.57, 5: 0.62, 6: 0.66, 7: 0.70, 8: 0.72}
var _seen := {}  # seat -> [turns, busts], what you have watched this match
var oot_stats := {"wager_shown": 0, "wager_taken": 0, "wager_won": 0, "wager_close": 0, "hex_shown": 0,
	"hex_taken": 0, "hex_close": 0, "fall_shown": 0, "fall_taken": 0, "fall_won": 0, "fall_close": 0, "rival_turns": 0, "rival_turns_none": 0, "rival_busts": 0, "cap_blocks": 0, "low": 0, "raise_shown": 0, "raise_taken": 0, "raise_won": 0, "raise_close": 0, "net": 0}


## Can you put n at stake? On the Master's credit (credit=true) your score may go below 0, down to
## -credit_cap; a prompt you can't cover is never shown (REPLY 39 item 2c).
func _can_stake(n: int) -> bool:
	var me = players[0]
	if opt("credit", false):
		var held: int = _fall + (50 if _raise > 0 else 0)  # bets still open count against the cap
		var ok: bool = me.score - held - n >= -int(opt("credit_cap", 99999))
		if not ok:
			oot_stats.cap_blocks += 1
		return ok
	return me.score >= n


## The Master's price for the fall (REPLY 39 item 2e). flat: fall_pay. dice: he prices by the rival's dice
## held at its turn start, from the table's bust rate for that many dice, at fair odds less his cut.
func _fall_price(p) -> int:
	if str(opt("fall_price", "flat")) == "standing":  # he wants the leader down: more on it, less on the last
		var sc: Array = players.map(func(q): return q.score)
		if p.score >= sc.max():
			return int(opt("fall_lead", 60))
		if p.score <= sc.min():
			return int(opt("fall_last", 25))
		return int(opt("fall_pay", 40))
	if str(opt("fall_price", "flat")) != "dice":
		return int(opt("fall_pay", 100))
	var r: float = FALL_RATE.get(clampi(p.dice, 3, 8), 0.57)
	return int(50.0 * (1.0 - r) / r * float(opt("fall_cut", 0.9))) / 5 * 5


func _oot_on(kind: String) -> bool:
	var o := str(opt("oot", "none"))
	return o == "all" or (o == "both" and kind != "fall") or kind in o.split("+")


## Chance n dice bring strikes from s to 3 or more (each die 1 in 3).
static func bust_chance(n: int, s: int) -> float:
	var need := Rules.STRIKES_TO_BUST - s
	if need <= 0:
		return 1.0
	var q := 0.0
	for k in range(need, n + 1):
		q += _binom(n, k) * pow(1.0 / 3.0, k) * pow(2.0 / 3.0, n - k)
	return q


static func _binom(n: int, k: int) -> float:
	var r := 1.0
	for i in k:
		r = r * (n - i) / (i + 1)
	return r


func _power_declare(p) -> void:
	super(p)
	if p.seat != 0:
		_dead.append(bust_chance(_max_throw(p), turn.strikes) <= 0.0)
		if turn.throws >= 1:
			_sk.append(mini(turn.strikes, 2))
		_offer_raise(p)
	if p.seat != 0 and _oot_on("fall") and turn.throws == 0 and (_can_stake(50) if opt("credit", false) else players[0].score >= (10 if opt("loose", false) else 50)):
		var sn: Array = _seen.get(p.seat, [0, 0])
		var pb: float = (sn[1] + 2.0) / (sn[0] + 4.0)  # from 1 in 2, today's table rate
		var fs: int = 50 if opt("credit", false) else mini(50, players[0].score) / 5 * 5
		_fall_pay = _fall_price(p)
		var ev: float = (pb * _fall_pay - (1.0 - pb) * 50.0) * fs / 50.0
		oot_stats.fall_shown += 1
		if absf(ev) < 15.0:
			oot_stats.fall_close += 1
		_oot.append([0, "fall"])
		if ev > 0.0:
			oot_stats.fall_taken += 1
			_fall = fs
	if not _wager.is_empty() and turn.throws >= int(_wager.throw):
		_settle_wager(p, false)  # it threw again, so the wagered throw didn't bust it
	var last_k: int = int(_oot[-1][0]) if not _oot.is_empty() else 0
	if p.seat == 0 or not _oot_on("wager") or turn.throws < int(opt("wager_from", 2)) or turn.throws - last_k < int(opt("wager_every", 99)) and _oot.any(func(o): return o[1] == "wager") or turn.points < (0 if opt("loose", false) else 80):
		return
	var me = players[0]
	var stake: int = int(opt("wager_stake", 50))
	if opt("loose", false) and not opt("credit", false):
		stake = mini(stake, me.score) / 5 * 5
	if not _can_stake(stake) or stake < 10:
		return  # credit=true: on the Master's credit, a stake you don't hold comes off your next bank
	var pb := bust_chance(_max_throw(p), turn.strikes)
	var fair := str(opt("wager_odds", "half")) == "fair"
	# fair (the Master prices it by the dice): you back the long shot, it busts or it survives this throw
	var q: float = minf(pb, 1.0 - pb) if fair else pb
	var side := "bust" if not fair or pb <= 0.5 else "survive"
	var pay: int = int(stake * (1.0 - q) / maxf(0.05, q)) / 5 * 5 if fair else int(turn.points) / 2 / 5 * 5
	var ev: float = q * pay - (1.0 - q) * stake
	var lo: float = float(opt("wager_q", 0.1)) if fair else 0.12
	if q < lo or (not fair and pb > 0.85) or pay < 10:
		return  # not live: nobody would take it, or everybody would
	oot_stats.wager_shown += 1
	var take: bool = ev > 0.0
	if fair:  # a pure swing by the dice, so it is about standing: behind takes it, ahead doesn't
		take = me.score < leader_score()
		oot_stats.wager_close += 1
	elif absf(ev) < 25.0:
		oot_stats.wager_close += 1
	_oot.append([turn.throws, "wager"])
	if take:
		oot_stats.wager_taken += 1
		_wager = {"pay": pay, "throw": turn.throws + 1, "side": side}


## raise (REPLY 39 item 2d/e): before a rival's 3rd+ throw, at least 2 throws after your last prompt, while you
## hold no bet on this turn: 50 says it busts before it banks. The Master prices it by its Strikes now
## (RAISE_RATE, less his cut); you read it by its busts so far against the table's. Live on a throw that can't
## bust too: the turn still can.
func _offer_raise(p) -> void:
	if not _oot_on("raise") or turn.throws < 2 or _raise > 0 or (_fall > 0 and not opt("raise_on_fall", false)):
		return
	var last_k: int = int(_oot[-1][0]) if not _oot.is_empty() else 0
	if turn.throws - last_k < 2 or not _can_stake(50):
		return
	var r: float = RAISE_RATE.get(mini(turn.strikes, 2), 0.5)
	var pay: int = int(50.0 * (1.0 - r) / r * float(opt("raise_cut", 0.9))) / 5 * 5
	if pay < 10:
		return
	var sn: Array = _seen.get(p.seat, [0, 0])
	var tilt: float = ((sn[1] + 2.0) / (sn[0] + 4.0)) / 0.5  # its busts so far against 1 in 2
	var pb: float = clampf(r * tilt, 0.02, 0.98)
	var ev: float = pb * pay - (1.0 - pb) * 50.0
	oot_stats.raise_shown += 1
	if absf(ev) < 15.0:
		oot_stats.raise_close += 1
	_oot.append([turn.throws, "raise"])
	if ev > 0.0:
		oot_stats.raise_taken += 1
		_raise = pay


func _do_rethrow(p) -> void:
	super(p)
	if p.seat == 0 or not _oot_on("hex") or hex_round == round_count:
		return
	var me = players[0]
	var cost := int(opt("hex_cost", 60))
	var s: int = turn.strikes + Rules.count_strikes(Array(turn.faces, TYPE_INT, "", null))
	if not _can_stake(cost) or s != Rules.STRIKES_TO_BUST - 1:
		return
	if opt("nocombo", false) and (_fall > 0 or _raise > 0):  # no hex on a turn you have a bet on
		return
	var best := -1
	for i in turn.faces.size():
		if turn.faces[i] >= 4 and (best < 0 or turn.faces[i] > turn.faces[best]):
			best = i
	if best < 0:
		return
	var at_risk: int = turn.points + Rules.score(Array(turn.faces, TYPE_INT, "", null), 0.0, face_mult)
	var lead: bool = p.score + at_risk >= leader_score() and p.score >= me.score
	var value: float = at_risk * (1.0 if lead else 0.5) - cost
	oot_stats.hex_shown += 1
	if absf(value) < 40.0:
		oot_stats.hex_close += 1
	_oot.append([turn.throws, "hex"])
	if value > 0.0:
		oot_stats.hex_taken += 1
		hex_round = round_count
		me.score -= cost
		oot_stats.net -= cost
		turn.faces[best] = 1
		_uses += 1  # it shows as a power beat on the rival's turn


func _settle_wager(p, bust: bool) -> void:
	if _wager.is_empty():
		return
	var me = players[0]
	if bust == (str(_wager.get("side", "bust")) == "bust"):
		var g: int = int(_wager.pay)
		me.score += g
		oot_stats.net += g
		oot_stats.wager_won += 1
	else:
		var st := int(opt("wager_stake", 50))
		me.score -= st
		p.score += st
		oot_stats.net -= st
	_wager = {}
