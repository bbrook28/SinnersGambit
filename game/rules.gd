## The step 1 rules (docs/step1-rules.md). No UI; static functions over game/state.gd.
## A turn: roll(s) (Lust may then whisper or settle), then in the Gambit Phase buy(s, n), gift(...) and use(s, key, args)
## as often as allowed, then pass_turn(s). block(s, key, args) says in plain words why an ability cannot be used now.
##
## Readings of the Sin cards that the cards do not spell out (reported to Ben, 2026-11-25):
## - "At most once per turn" (Ben, 2026-11-25) counts every use by the player whose turn it is, a copy through Jealous
##   Grasp included; Wrath's Spark of Rage on another player's turn is not a use on Wrath's turn (once a round covers it).
## - A round, for "once a round", "each round" and "this round", runs from the start of your turn to the start of your next.
## - A die taken "for N full rounds" is rolled by the taker on their next N turns, then goes back to its owner.
## - In Purgatory no ability works, the passive ones included. A player in Purgatory can be a target.
## - "Targeted" (Superiority) is being chosen by Spark of Rage, Vengeful Strike, Cut a Deal, Whisper of Desire,
##   Entangling Allure, Voracious Bite or Lethargic Aura; not by Green-Eyed Glance, which only copies.
## - A die changed after its roll was scored (Spark of Rage, a copied Whisper) changes that roll's score by the difference.
##   A die another player swaps into your scored roll changes nothing you scored.
extends RefCounted

const Config = preload("res://game/config.gd")
const State = preload("res://game/state.gd")
const Sins = preload("res://game/sins.gd")

const FATE := "fate"      # waiting for the roll
const SWAP := "swap"      # Lust has rolled and may swap a die before scoring (whisper or settle)
const GAMBIT := "gambit"  # rolled and free: buy, trade, use abilities, then pass
const END := "end"        # rolled into (or stayed in) Purgatory: the turn is over, only passing is left
const OVER := "over"      # someone has won

# The three gifts.
const POINTS := "points"  # give points
const LEND := "lend"      # lend a die for one roll; then it goes to the supply
const DIE := "die"        # buy a die from the supply for another player

## The choices every use(s, key, args) needs.
const NEEDS := {"spark": ["target", "index"], "strike": ["target", "choice"], "deal": ["target", "choice"],
	"whisper": ["mine", "target", "theirs"], "allure": ["a", "b", "pick_a", "pick_b"], "glance": ["target", "index"],
	"grasp": ["key"], "vig": [], "hubris": [], "superiority": [], "feast": ["index"], "bite": ["target"], "aura": ["target"], "drip": []}


## A new match. sins: one name a seat, or empty to deal them at random from rng.
static func new_match(cfg: Dictionary, rng, sins: Array = []):
	var s = State.new()
	s.cfg = cfg
	s.rng = rng
	var n := int(cfg.seats)
	if sins.is_empty():
		sins = _deal(rng, n)
	for i in n:
		var p = State.Seat.new()
		p.sin = sins[i]
		p.dice = int(cfg.start_dice)
		s.seats.append(p)
	s.supply = int(cfg.spare_dice)
	return s


## n different Sins in a random order.
static func _deal(rng, n: int) -> Array:
	var deck: Array = Config.SINS.duplicate()
	for i in n:
		var j: int = rng.randi_range(i, deck.size() - 1)
		var t = deck[i]
		deck[i] = deck[j]
		deck[j] = t
	return deck.slice(0, n)


## Every die in the match: the seats' dice and the supply.
static func total_dice(s) -> int:
	var n: int = s.supply
	for p in s.seats:
		n += p.dice + p.lent
	return n


## Points one face scores.
static func face_score(cfg: Dictionary, f: int) -> int:
	return f * int(cfg.face_points) if f > int(cfg.low_max) else 0


## Points the faces score: a 4, 5 or 6 scores 40, 50 or 60; a 1, 2 or 3 nothing.
static func score(cfg: Dictionary, faces: Array) -> int:
	var total := 0
	for f in faces:
		total += face_score(cfg, f)
	return total


## How many of the faces show 1, 2 or 3.
static func lows(cfg: Dictionary, faces: Array) -> int:
	var n := 0
	for f in faces:
		if f <= int(cfg.low_max):
			n += 1
	return n


## Can this seat give away one of its own dice? No one drops below min_dice, and a die held from another player is not theirs to give.
static func spare(s, seat: int) -> bool:
	var p = s.seats[seat]
	return p.dice - p.held > int(s.cfg.min_dice)


## What a declared Hubris must beat: the points the player before scored on their last roll; 50 if no one has rolled.
static func hubris_target(s) -> int:
	var prev = s.seats[(s.turn + s.seats.size() - 1) % s.seats.size()]
	if s.turn_count == 0 and prev.last_roll.is_empty():
		return int(s.cfg.hubris_first)
	return prev.last_score


## The Fate Phase: the player whose turn it is rolls all their dice once.
## Returns {} if no roll is due. For Lust with a swap to make: {faces, pending: true}, and the phase is SWAP.
## Else the settled roll (see settle).
static func roll(s) -> Dictionary:
	if s.phase != FATE:
		return {}
	var p = s.seats[s.turn]
	var faces := []
	var aura: bool = p.lethargic
	for i in p.dice + p.lent:
		var f: int = s.rng.randi_range(1, 6)
		if i == 0 and aura:
			# Lethargic Aura: one die is rolled twice and the lower kept.
			f = mini(f, s.rng.randi_range(1, 6))
		faces.append(f)
	p.lethargic = false
	# A lent die is rolled once, then goes to the supply.
	s.supply += p.lent
	p.lent = 0
	# Green-Eyed Glance: the temporary die, for this roll only.
	var glanced: int = p.glance
	if glanced > 0:
		faces.append(glanced)
		p.glance = 0
	p.last_roll = faces
	var extra := {"aura": aura, "glance": glanced}
	if p.sin == "lust" and not p.purgatory and not p.used_t1 and not whisper_pairs(s, s.turn).is_empty():
		s.phase = SWAP
		extra.merge({"faces": faces, "pending": true})
		return extra
	return settle(s, extra)


## Score the roll on the table and end the Fate Phase (after roll, or after Lust's swap or refusal).
## Returns {faces, scored, purgatory (in it after the roll), escaped (freed by this roll), won,
## hubris ("" not declared, "won", "lost"), beat (what Hubris had to beat), drip (Slow Drip paid), aura, glance}.
static func settle(s, extra := {}) -> Dictionary:
	var p = s.seats[s.turn]
	var faces: Array = p.last_roll
	var low := lows(s.cfg, faces)
	var was_in: bool = p.purgatory
	var escaped := false
	if was_in:
		# The escape roll: enough lows free you, and it is never checked for Purgatory.
		escaped = low >= int(s.cfg.escape_lows)
		p.purgatory = not escaped
	else:
		p.purgatory = low == faces.size()
	var scored := 0 if p.purgatory else score(s.cfg, faces)
	p.last_mult = 0 if p.purgatory else 1
	var hubris := ""
	var beat := 0
	if p.hubris:
		p.hubris = false
		beat = hubris_target(s)
		if not p.purgatory:
			hubris = "won" if scored > beat else "lost"
			p.last_mult = 2 if hubris == "won" else 0
			scored *= p.last_mult
	p.last_score = scored
	add_points(s, s.turn, scored)
	# Slow Drip: a free Sloth who scores under 60 gains 40 more.
	var drip := false
	if p.sin == "sloth" and not p.purgatory and scored < int(s.cfg.drip_under):
		drip = true
		add_points(s, s.turn, int(s.cfg.drip_gain))
		_log(s, "drip")
	# The win check, at the end of the Fate Phase; no one wins while in Purgatory.
	if p.points >= int(s.cfg.win) and not p.purgatory:
		s.winner = s.turn
		s.phase = OVER
	else:
		s.phase = END if p.purgatory else GAMBIT
	var r := {"faces": faces.duplicate(), "scored": scored, "purgatory": p.purgatory, "escaped": escaped, "won": s.winner == s.turn,
		"hubris": hubris, "beat": beat, "drip": drip, "aura": false, "glance": 0}
	r.merge(extra, true)
	return r


## Dice the player whose turn it is can buy now: what they can pay for and the supply holds.
static func max_buy(s) -> int:
	if s.phase != GAMBIT:
		return 0
	return mini(s.supply, s.seats[s.turn].points / int(s.cfg.die_cost))


## The seat The Vig pays when this seat buys a die: a free Greed who is not the buyer; else -1.
static func vig_seat(s, buyer: int) -> int:
	for i in s.seats.size():
		if i != buyer and s.seats[i].sin == "greed" and not s.seats[i].purgatory:
			return i
	return -1


## Buy n dice from the supply. False (and nothing changes) if it is not allowed.
static func buy(s, n: int) -> bool:
	if n < 1 or n > max_buy(s):
		return false
	var p = s.seats[s.turn]
	add_points(s, s.turn, -n * int(s.cfg.die_cost))
	p.dice += n
	s.supply -= n
	var g := vig_seat(s, s.turn)
	if g >= 0:
		add_points(s, g, n * int(s.cfg.vig))
	return true


## Why this gift cannot be made now, in plain words; "" if it can. One of from and to is the player whose turn it is.
## amount: the points to give (POINTS only).
static func gift_block(s, kind: String, from: int, to: int, amount := 0) -> String:
	if s.phase != GAMBIT:
		return "Gifts are made in the Gambit Phase."
	if from == to or (from != s.turn and to != s.turn):
		return "A gift is between the player whose turn it is and one other player."
	if s.seats[from].purgatory or s.seats[to].purgatory:
		return "No gifts to or from a player in Purgatory."
	var giver = s.seats[from]
	if kind == POINTS:
		if amount < 1:
			return "Choose how many points."
		if amount > giver.points:
			return "Not enough points."
	elif kind == LEND:
		if not spare(s, from):
			return "No one can go below %d dice." % int(s.cfg.min_dice)
	elif kind == DIE:
		if s.supply < 1:
			return "The supply is empty."
		if giver.points < int(s.cfg.die_cost):
			return "Not enough points: a die costs %d." % int(s.cfg.die_cost)
	else:
		return "No such gift."
	return ""


## Make a gift, once the other player has agreed; it is permanent. False (and nothing changes) if it is not allowed.
static func gift(s, kind: String, from: int, to: int, amount := 0) -> bool:
	if gift_block(s, kind, from, to, amount) != "":
		return false
	if kind == POINTS:
		add_points(s, from, -amount)
		add_points(s, to, amount)
	elif kind == LEND:
		s.seats[from].dice -= 1
		s.seats[to].lent += 1
	else:
		add_points(s, from, -int(s.cfg.die_cost))
		s.supply -= 1
		s.seats[to].dice += 1
		var g := vig_seat(s, from)
		if g >= 0:
			add_points(s, g, int(s.cfg.vig))
	return true


## End the turn; the next seat's Fate Phase begins. False before the roll and after a win.
static func pass_turn(s) -> bool:
	if s.phase != GAMBIT and s.phase != END:
		return false
	# Dice taken for a time: each of the taker's turns that ends, after the one they were taken on, uses one up.
	for l in s.loans.duplicate():
		if l.taker != s.turn:
			continue
		if l.fresh:
			l.fresh = false
			continue
		l.left -= 1
		if l.left <= 0:
			s.seats[l.taker].dice -= 1
			s.seats[l.taker].held -= 1
			s.seats[l.owner].dice += 1
			s.loans.erase(l)
	s.turn = (s.turn + 1) % s.seats.size()
	s.turn_count += 1
	if s.turn == 0:
		s.round_number += 1
	s.phase = FATE
	# A new round begins for this player.
	var p = s.seats[s.turn]
	p.used_t1 = false
	p.used_t2 = false
	p.used = {}
	p.spark_used = false
	p.armed = false
	p.hubris = false
	p.glance = 0
	return true


## Change a seat's points; they never go below 0. Returns the change that happened. Reaching 350 opens Tier 2 for good.
static func add_points(s, seat: int, delta: int) -> int:
	var p = s.seats[seat]
	var before: int = p.points
	p.points = maxi(0, before + delta)
	if p.points >= int(s.cfg.tier2_at):
		p.tier2 = true
	return p.points - before


# ---- abilities

## The swaps Whisper of Desire allows this seat: [mine (index in their roll), target (seat), theirs (index)], their die higher.
static func whisper_pairs(s, seat: int) -> Array:
	var out := []
	var mine: Array = s.seats[seat].last_roll
	for t in s.seats.size():
		if t == seat:
			continue
		var theirs: Array = s.seats[t].last_roll
		for i in mine.size():
			for j in theirs.size():
				if theirs[j] > mine[i]:
					out.append([i, t, j])
	return out


## The Tier 1 abilities used in the last round (since this player's last turn), newest first, each once: what Jealous Grasp sees.
static func grasp_seen(s) -> Array:
	var out := []
	for i in range(s.t1_log.size() - 1, -1, -1):
		var e: Dictionary = s.t1_log[i]
		if e.turn <= s.turn_count - s.seats.size():
			break
		if not out.has(e.key):
			out.append(e.key)
	return out


## Why the ability cannot be used now, in plain words; "" if it can. The player is the one whose turn it is, unless
## a.by names another seat (Spark of Rage out of turn). Only the choices present in a are checked, so the screen can
## ask before every choice is made. a.copy: Envy is using it through Jealous Grasp (already paid for).
static func block(s, key: String, a: Dictionary = {}) -> String:
	if s.phase == OVER:
		return "The match is over."
	if not NEEDS.has(key):
		return "No such ability."
	var copy: bool = a.get("copy", false)
	var seat: int = a.get("by", s.turn)
	var p = s.seats[seat]
	var cfg: Dictionary = s.cfg
	if not copy and Sins.sin_of(key) != p.sin:
		return "Not this Sin's ability."
	if p.purgatory:
		return "No abilities in Purgatory."
	if Sins.PASSIVE.has(key) and not copy:
		return "Always on."
	if key == "spark" and seat != s.turn:
		if s.phase == SWAP:
			return "Wait for the roll to be scored."
		if p.spark_used:
			return "Once a round."
	else:
		if seat != s.turn:
			return "Not your turn."
		var need := GAMBIT
		if key == "hubris" or key == "glance":
			need = FATE
		elif key == "whisper" and not copy:
			need = SWAP
		if s.phase != need:
			return {FATE: "Before you roll.", SWAP: "Before scoring.", GAMBIT: "After your roll."}[need]
		# Ben, 2026-11-25: every ability at most once per turn by the player whose turn it is.
		if p.used.has(key):
			return "Already used this turn."
		if copy:
			pass
		elif Sins.tier(key) == 1:
			if p.used_t1:
				return "One Tier 1 a turn."
			if key == "spark" and p.spark_used:
				return "Once a round."
		else:
			if not p.tier2:
				return "Tier 2 opens at %d points." % int(cfg.tier2_at)
			if p.used_t2:
				return "One Tier 2 a turn."
			if p.points < Sins.cost(cfg, key):
				return "Costs %d: not enough points." % Sins.cost(cfg, key)
	# the target
	var t: int = a.get("target", -1)
	if a.has("target"):
		if t == seat or t < 0 or t >= s.seats.size():
			return "Choose another player."
		if ["strike", "deal", "bite"].has(key) and p.last_target.get(key, -1) == t:
			return "Not the same target twice running."
	var tp = s.seats[t] if t >= 0 and t < s.seats.size() else null
	match key:
		"spark":
			if tp != null:
				var ok := false
				for f in tp.last_roll:
					ok = ok or f >= int(cfg.spark_min)
				if not ok:
					return "No die showing 5 or 6."
				if a.has("index") and (a.index < 0 or a.index >= tp.last_roll.size() or tp.last_roll[a.index] < int(cfg.spark_min)):
					return "Choose a die showing 5 or 6."
		"strike":
			if tp != null and a.get("choice", "") == "die" and not spare(s, t):
				return "No one can go below %d dice." % int(cfg.min_dice)
		"deal":
			if tp != null:
				var can_pay: bool = tp.points >= int(cfg.deal_pay)
				if not can_pay and not spare(s, t):
					return "They have neither %d points nor a spare die." % int(cfg.deal_pay)
				if a.get("choice", "") == "points" and not can_pay:
					return "They do not have %d points." % int(cfg.deal_pay)
				if a.get("choice", "") == "die" and not spare(s, t):
					return "No one can go below %d dice." % int(cfg.min_dice)
		"whisper":
			if whisper_pairs(s, seat).is_empty():
				return "No other player shows a die higher than one of yours."
			if tp != null and a.has("mine") and a.has("theirs"):
				if a.mine < 0 or a.mine >= p.last_roll.size() or a.theirs < 0 or a.theirs >= tp.last_roll.size():
					return "Choose a die."
				if tp.last_roll[a.theirs] <= p.last_roll[a.mine]:
					return "Their die must be higher than yours."
		"allure":
			for k in ["a", "b"]:
				if a.has(k):
					if a[k] == seat or a[k] < 0 or a[k] >= s.seats.size():
						return "Choose two other players."
					if s.seats[a[k]].last_roll.is_empty():
						return "They have not rolled yet."
					var pick: String = "pick_" + k
					if a.has(pick) and (a[pick] < 0 or a[pick] >= s.seats[a[k]].last_roll.size()):
						return "Choose a die."
			if a.has("a") and a.has("b") and a.a == a.b:
				return "Choose two different players."
			if a.has("take") and (not [a.get("a", -1), a.get("b", -1)].has(a.take) or not spare(s, a.take)):
				return "No one can go below %d dice." % int(cfg.min_dice)
		"glance":
			if tp != null:
				if tp.last_roll.is_empty():
					return "They have not rolled yet."
				if a.has("index") and (a.index < 0 or a.index >= tp.last_roll.size()):
					return "Choose a die."
		"grasp":
			if a.has("key"):
				if not Sins.GRASP_OK.has(a.key):
					return "It works before the roll is scored: too late to copy." if ["hubris", "glance"].has(a.key) else "Always on: nothing to copy."
				if not grasp_seen(s).has(a.key):
					return "Not used this round."
				if p.last_grasp == a.key:
					return "Not the same one twice running."
				var sub: Dictionary = a.duplicate()
				sub.erase("key")
				sub["copy"] = true
				return block(s, a.key, sub)
			else:
				var any := false
				for k in grasp_seen(s):
					any = any or (Sins.GRASP_OK.has(k) and p.last_grasp != k)
				if not any:
					return "No Tier 1 ability to copy this round."
		"superiority":
			if p.armed:
				return "Already armed."
		"feast":
			if not spare(s, seat):
				return "No one can go below %d dice." % int(cfg.min_dice)
			if score(cfg, p.last_roll) == 0:
				return "No die showing 4, 5 or 6 in your roll."
			if a.has("index") and (a.index < 0 or a.index >= p.last_roll.size() or face_score(cfg, p.last_roll[a.index]) == 0):
				return "Choose a die showing 4, 5 or 6."
		"drip":
			if p.last_score >= int(cfg.drip_under):
				return "You scored %d or more this turn." % int(cfg.drip_under)
	return ""


## Use an ability with every choice made (NEEDS). Returns {} (and nothing changes) if it is not allowed, else what
## happened: always {ok, key, by}; "superiority": [seats whose Superiority fired] where someone was targeted; and per
## ability: spark {target, was, face, change, lost}; strike/deal {target, choice, paid}; whisper {target, gave, got, + the
## settled roll before scoring}; allure {a, b, face_a, face_b, match, take}; glance {target, face}; grasp {copied, + the
## copy's result}; feast {face, gain}; bite {target, stolen}; aura {target}; drip {gain}.
static func use(s, key: String, a: Dictionary = {}) -> Dictionary:
	if block(s, key, a) != "":
		return {}
	for k in NEEDS[key]:
		if not a.has(k):
			return {}
	var copy: bool = a.get("copy", false)
	var seat: int = a.get("by", s.turn)
	var p = s.seats[seat]
	var cfg: Dictionary = s.cfg
	var r := {"ok": true, "key": key, "by": seat, "superiority": []}
	if seat == s.turn:
		p.used[key] = true
	# pay, and mark the use
	if not copy:
		if Sins.tier(key) == 1:
			if seat == s.turn:
				p.used_t1 = true
			if key == "spark":
				p.spark_used = true
			_log(s, key)
		else:
			p.used_t2 = true
			add_points(s, seat, -Sins.cost(cfg, key))
	var t: int = a.get("target", -1)
	match key:
		"spark":
			_targeted(s, seat, t, r)
			var was: int = s.seats[t].last_roll[a.index]
			var face: int = s.rng.randi_range(1, 6)
			var change := _change_die(s, t, a.index, face)
			var lost := 0
			if face <= int(cfg.low_max):
				lost = -add_points(s, t, -int(cfg.spark_loss))
			r.merge({"target": t, "was": was, "face": face, "change": change, "lost": lost})
		"strike", "deal":
			_targeted(s, seat, t, r)
			p.last_target[key] = t
			var paid := 0
			if a.choice == "die":
				_take_die(s, t, seat, int(cfg[key + "_rounds"]))
			elif key == "strike":
				paid = -add_points(s, t, -int(cfg.strike_loss))
			else:
				paid = -add_points(s, t, -int(cfg.deal_pay))
				add_points(s, seat, paid)
			r.merge({"target": t, "choice": a.choice, "paid": paid})
		"whisper":
			_targeted(s, seat, t, r)
			var gave: int = p.last_roll[a.mine]
			var got: int = s.seats[t].last_roll[a.theirs]
			s.seats[t].last_roll[a.theirs] = gave
			if copy:
				_change_die(s, seat, a.mine, got)   # already scored: the better die changes the score
				r.merge({"target": t, "gave": gave, "got": got})
			else:
				p.last_roll[a.mine] = got
				r.merge(settle(s))
				r.merge({"target": t, "gave": gave, "got": got})
		"allure":
			_targeted(s, seat, a.a, r)
			_targeted(s, seat, a.b, r)
			var pa = s.seats[a.a]
			var pb = s.seats[a.b]
			var fa: int = pa.last_roll[a.pick_a]
			var fb: int = pb.last_roll[a.pick_b]
			var take: int = -1
			if fa == fb:
				# a match: Lust takes one of the two dice, for good, if its owner can spare it
				take = a.get("take", -1)
				if take < 0:
					take = a.a if spare(s, a.a) else (a.b if spare(s, a.b) else -1)
				if take >= 0:
					s.seats[take].dice -= 1
					s.seats[take].last_roll.remove_at(a.pick_a if take == a.a else a.pick_b)
					p.dice += 1
			else:
				pa.last_roll[a.pick_a] = fb
				pb.last_roll[a.pick_b] = fa
			r.merge({"a": a.a, "b": a.b, "face_a": fa, "face_b": fb, "match": fa == fb, "take": take})
		"glance":
			p.glance = s.seats[t].last_roll[a.index]
			r.merge({"target": t, "face": p.glance})
		"grasp":
			p.last_grasp = a.key
			var sub: Dictionary = a.duplicate()
			sub.erase("key")
			sub["copy"] = true
			var got_r := use(s, a.key, sub)
			r["superiority"] = got_r.get("superiority", [])
			got_r.erase("superiority")
			got_r.erase("key")
			r.merge(got_r)
			r["copied"] = a.key
		"hubris":
			p.hubris = true
			r["beat"] = hubris_target(s)
		"superiority":
			p.armed = true
		"feast":
			var f: int = p.last_roll[a.index]
			p.last_roll.remove_at(a.index)
			p.dice -= 1
			s.supply += 1
			add_points(s, seat, int(cfg.feast_gain))
			r.merge({"face": f, "gain": int(cfg.feast_gain)})
		"bite":
			_targeted(s, seat, t, r)
			p.last_target[key] = t
			var stolen := -add_points(s, t, -int(cfg.bite_steal))
			add_points(s, seat, stolen)
			r.merge({"target": t, "stolen": stolen})
		"aura":
			_targeted(s, seat, t, r)
			s.seats[t].lethargic = true
			add_points(s, seat, int(cfg.aura_gain))
			r["target"] = t
		"drip":
			add_points(s, seat, int(cfg.drip_gain))
			r["gain"] = int(cfg.drip_gain)
	return r


static func _log(s, key: String) -> void:
	s.t1_log.append({"turn": s.turn_count, "key": key})


## Someone is targeted: an armed, free Pride makes the attacker lose 20, once.
static func _targeted(s, attacker: int, target: int, r: Dictionary) -> void:
	var tp = s.seats[target]
	if tp.sin == "pride" and tp.armed and not tp.purgatory:
		tp.armed = false
		add_points(s, attacker, -int(s.cfg.superiority_loss))
		r.superiority.append(target)


## A die of a scored roll changes face: the roll's score and the player's points change by the difference. Returns it.
static func _change_die(s, seat: int, index: int, face: int) -> int:
	var p = s.seats[seat]
	var delta: int = (face_score(s.cfg, face) - face_score(s.cfg, p.last_roll[index])) * p.last_mult
	p.last_roll[index] = face
	p.last_score = maxi(0, p.last_score + delta)
	return add_points(s, seat, delta)


## One of the owner's dice goes to the taker for that many of the taker's turns.
static func _take_die(s, owner: int, taker: int, rounds: int) -> void:
	s.seats[owner].dice -= 1
	s.seats[taker].dice += 1
	s.seats[taker].held += 1
	s.loans.append({"owner": owner, "taker": taker, "left": rounds, "fresh": true})
