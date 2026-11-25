## The step 1 rules (docs/step1-rules.md). No UI; static functions over game/state.gd.
## A turn: roll(s), then in the Gambit Phase buy(s, n) as often as you like, then pass_turn(s).
extends RefCounted

const Config = preload("res://game/config.gd")
const State = preload("res://game/state.gd")

const FATE := "fate"      # waiting for the roll
const GAMBIT := "gambit"  # rolled and free: buy, then pass
const END := "end"        # rolled into (or stayed in) Purgatory: the turn is over, only passing is left
const OVER := "over"      # someone has won

# The three gifts.
const POINTS := "points"  # give points
const LEND := "lend"      # lend a die for one roll; then it goes to the supply
const DIE := "die"        # buy a die from the supply for another player


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
	s.supply = int(cfg.total_dice) - n * int(cfg.start_dice)
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


## Points the faces score: a 4, 5 or 6 scores 40, 50 or 60; a 1, 2 or 3 nothing.
static func score(cfg: Dictionary, faces: Array) -> int:
	var total := 0
	for f in faces:
		if f > int(cfg.low_max):
			total += f * int(cfg.face_points)
	return total


## How many of the faces show 1, 2 or 3.
static func lows(cfg: Dictionary, faces: Array) -> int:
	var n := 0
	for f in faces:
		if f <= int(cfg.low_max):
			n += 1
	return n


## The Fate Phase: the player whose turn it is rolls all their dice once.
## Returns {} if no roll is due, else {faces, scored, purgatory (in it after the roll), escaped (freed by this roll), won}.
static func roll(s) -> Dictionary:
	if s.phase != FATE:
		return {}
	var p = s.seats[s.turn]
	var faces := []
	for i in p.dice + p.lent:
		faces.append(s.rng.randi_range(1, 6))
	# A lent die is rolled once, then goes to the supply.
	s.supply += p.lent
	p.lent = 0
	var low := lows(s.cfg, faces)
	var escaped := false
	if p.purgatory:
		# The escape roll: enough lows free you, and it is never checked for Purgatory.
		escaped = low >= int(s.cfg.escape_lows)
		p.purgatory = not escaped
	else:
		p.purgatory = low == faces.size()
	var scored := 0 if p.purgatory else score(s.cfg, faces)
	p.last_roll = faces
	p.last_score = scored
	add_points(s, s.turn, scored)
	# The win check, at the end of the Fate Phase; no one wins while in Purgatory.
	if p.points >= int(s.cfg.win) and not p.purgatory:
		s.winner = s.turn
		s.phase = OVER
	else:
		s.phase = END if p.purgatory else GAMBIT
	return {"faces": faces, "scored": scored, "purgatory": p.purgatory, "escaped": escaped, "won": s.winner == s.turn}


## Dice the player whose turn it is can buy now: what they can pay for and the supply holds.
static func max_buy(s) -> int:
	if s.phase != GAMBIT:
		return 0
	return mini(s.supply, s.seats[s.turn].points / int(s.cfg.die_cost))


## Buy n dice from the supply. False (and nothing changes) if it is not allowed.
static func buy(s, n: int) -> bool:
	if n < 1 or n > max_buy(s):
		return false
	var p = s.seats[s.turn]
	add_points(s, s.turn, -n * int(s.cfg.die_cost))
	p.dice += n
	s.supply -= n
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
		if giver.dice <= int(s.cfg.min_dice):
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
	return true


## End the turn; the next seat's Fate Phase begins. False before the roll and after a win.
static func pass_turn(s) -> bool:
	if s.phase != GAMBIT and s.phase != END:
		return false
	s.turn = (s.turn + 1) % s.seats.size()
	if s.turn == 0:
		s.round_number += 1
	s.phase = FATE
	return true


## Change a seat's points; they never go below 0. Returns the change that happened.
static func add_points(s, seat: int, delta: int) -> int:
	var p = s.seats[seat]
	var before: int = p.points
	p.points = maxi(0, before + delta)
	return p.points - before
