## Sim-only bots for sim/agency_sim.gd. Nothing in the game uses this file.
extends RefCounted

const Rules = preload("res://core/rules.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")


## The game's bot (BotPolicy.chooser(5, [99, 2, 0], 300)), aware of the sim's strike_cap.
class Plain extends "res://ai/bot_policy.gd":
	var smart := false
	var buy_until := 99999   # buy only while the leader is under this

	func _init(p_target := 5, p_bank_at := 300) -> void:
		super(p_target, 99999, 0, p_bank_at)
		cap_3_left = 99
		cap_2_left = 2
		cap_1_left = 0
		press_max_strikes = -2
		label = "plain buy%d" % p_target

	## Like BotPolicy.expected_after_throw, under strike_cap: dice beyond the third add at most one Strike.
	static func ev_capped(n: int, turn_points: int, strikes_left: int, chain: float, face_mult: int) -> float:
		var a := mini(n, 3)
		var m := n - a
		var ev := 0.0
		for k1 in a + 1:
			for s1 in a - k1 + 1:
				var p1 := _multi(a, k1, s1)
				for k2 in m + 1:
					for s2 in m - k2 + 1:
						var p2 := _multi(m, k2, s2)
						if k1 + mini(k2, 1) >= strikes_left:
							continue
						var s := s1 + s2
						var gain := 0.0
						if s > 0:
							gain = s * 5.0 * face_mult * (1.0 + chain * (s - 1))
						ev += p1 * p2 * (turn_points + gain)
		return ev


	static func _multi(n: int, k: int, s: int) -> float:
		var b := n - k - s
		return _fact(n) / (_fact(k) * _fact(b) * _fact(s)) * pow(1.0 / 3.0, k) * pow(1.0 / 6.0, b) * pow(0.5, s)



	func dice_to_buy(p, game) -> int:
		if game.leader_score() >= buy_until:
			return 0
		return target_dice - p.dice

	func risk_for(p, game) -> float:
		if game.opt("no_sin_risk", false):
			return risk
		return super(p, game)

	## scale_bots (REPLY 4): the bot's score thresholds follow the win target (win_score / 1000);
	## 1 otherwise, so 1000-point games play exactly as before.
	static func scale(game) -> float:
		if not game.opt("scale_bots", false):
			return 1.0
		return float(game.opt("win_score", Rules.WIN_SCORE)) / Rules.WIN_SCORE

	## BotPolicy.offer_value with the game's progress measured against the win target, not 1000.
	func offer_value(game, p, from, offer: Dictionary) -> float:
		var v: float = super(game, p, from, offer)
		var k := scale(game)
		if k == 1.0:
			return v
		# Undo the progress terms super computed at 1000 and redo them at the target: die worth, the
		# later-turn discount and the claim cost all move with progress.
		var lead := float(game.leader_score())
		var p0 := clampf(lead / Rules.WIN_SCORE, 0.0, 1.0)
		var p1 := clampf(lead / (Rules.WIN_SCORE * k), 0.0, 1.0)
		return v + _progress_part(game, p, from, offer, p1) - _progress_part(game, p, from, offer, p0)

	## The part of offer_value that depends on progress (die worth, the later discount, the claim cost).
	func _progress_part(game, p, from, offer: Dictionary, progress: float) -> float:
		var die_worth := 110.0 * (1.0 - progress) + 20.0
		var base_turn: float = 45.0 * p.dice
		var later := 1.0 - 0.5 * progress
		var part := 0.0
		if offer.gain == "die":
			part += die_worth
		match offer.cost:
			"bank":
				part -= offer.c * 0.9 * later
			"strike":
				part -= 0.3 * base_turn * later
			"fewer":
				part -= base_turn * float(offer.c) / maxf(1.0, p.dice) * later
			"die":
				part -= die_worth
		var sname: String = from.sin.sin_name
		if int(p.marks.get(sname, 0)) + 1 >= game.marks_to_claim and not p.claims.has(sname):
			part -= CLAIM_COST * (1.0 - progress * 0.5)
		return part

	func ev(game, n: int, tp: int, left: int) -> float:
		var v: float
		var ch: float = game.chain_for(game.current) if game.has_method("chain_for") else game.chain
		if game.opt("strike_cap", false):
			v = ev_capped(n, tp, left, ch, game.face_mult)
		else:
			v = expected_after_throw(n, tp, left, ch, game.face_mult)
		if str(game.opt("soften", "")) == "half" and game.turn != null:  # REPLY 14: a bust still keeps half the face points
			v += bust_chance(n, left) * float(int(game.turn.get_meta("face_pts", 0)) / 2 / 5 * 5)
		return v

	## The chance one throw of n dice brings at least `left` Strikes (a Strike is a 1 or 2).
	static func bust_chance(n: int, left: int) -> float:
		var keep := 0.0
		for k in mini(left, n + 1):
			keep += _fact(n) / (_fact(k) * _fact(n - k)) * pow(1.0 / 3.0, k) * pow(2.0 / 3.0, n - k)
		return 1.0 - keep

	func wants_throw(p, game, turn_points: int, strikes: int) -> bool:
		if game.turn.throws == 0:
			return true
		var total: int = p.score + turn_points
		if game.finish_round and game.end_triggered:
			return total <= game.leader_score()
		if game.v4 and game.claimed(p, "Pride") and turn_points < int(game.opt("claim_pride_min", 0)):
			return true
		if game.turn.min_points >= 0 and turn_points < game.turn.min_points:
			return true
		if must_chase(p, game, turn_points, strikes):  # the call: behind in the penultimate round
			return true
		if total >= int(game.opt("win_score", Rules.WIN_SCORE)) and total > game.leader_score():
			return false
		if bank_at < 9999 and turn_points >= int(bank_at * scale(game)):
			return false
		return ev(game, game._max_throw(p), turn_points, Rules.STRIKES_TO_BUST - strikes) > turn_points * risk_for(p, game)


## The best bot we have: the plain bot's one-throw lookahead, but its risk follows the standings
## (bank sooner when ahead), it buys to `target` dice, no bank cap, and it weighs its power (smart).
class Best extends Plain:
	var base := 1.0
	var kb := 0.0    # behind: risk falls by kb x deficit/1000 x (0.5 + progress)
	var ka := 0.5    # ahead: risk rises by ka x lead/1000
	var late := 0.3  # someone else at 850+ and I'm behind: push this much harder

	func _init(p_target := 4, p_base := 0.9, p_kb := 0.0, p_ka := 0.5, p_late := 0.3) -> void:
		super(p_target, 9999)
		base = p_base
		kb = p_kb
		ka = p_ka
		late = p_late
		smart = true
		label = "best t%d b%.2f kb%.1f ka%.1f l%.1f" % [p_target, p_base, p_kb, p_ka, p_late]

	func risk_for(p, game) -> float:
		var lead = game.leader_other(p)
		if lead == null:
			return base
		var w: float = 1000.0 * scale(game)
		var d := float(lead.score - p.score) / w
		var prog := float(maxi(lead.score, p.score)) / w
		var r := base
		if d > 0.0:
			r -= kb * d * (0.5 + prog)
			if lead.score >= 0.85 * w:
				r -= late
		else:
			r += ka * -d
		return clampf(r, 0.4, 1.8)


## A new player, roughly: throws again while the turn is under `stop` and it has fewer than 2 Strikes;
## buys to 4 dice. (A stand-in for a first game; real players will vary.)
class Novice extends "res://ai/bot_policy.gd":
	var stop := 150

	func _init(p_stop := 150) -> void:
		super(4, 99999, 0, 9999)
		stop = p_stop
		press_max_strikes = -2
		label = "novice stop%d" % p_stop

	func wants_throw(p, game, turn_points: int, strikes: int) -> bool:
		if game.turn.throws == 0:
			return true
		if game.turn.min_points >= 0 and turn_points < game.turn.min_points:
			return true
		if p.score + turn_points >= int(game.opt("win_score", Rules.WIN_SCORE)):
			return false
		return turn_points < stop and strikes < 2


## Decision split (sim pass 3): a plain bot that changes one decision at a time.
## offer_mode: "heur" (BotPolicy.offer_value), "weigh" (standings-aware), "never", "always".
## target_mode: "heur" (newest grudge, else leader), "leader", "next" (the seat closest above me).
class Split extends Plain:
	var offer_mode := "heur"
	var target_mode := "heur"

	func _init(p_target := 5, p_bank_at := 300) -> void:
		super(p_target, p_bank_at)
		label = "split"

	func wants_temptation(game, p, from, offer: Dictionary) -> bool:
		match offer_mode:
			"never":
				return false
			"always":
				return true
			"weigh":
				return weigh(game, p, from, offer) > 0.0
		return super(game, p, from, offer)

	## The heuristic's value, but a mark that can't count costs nothing, a claim costs more while
	## ahead, and while behind a gain counts more (a lead is worth more than its points).
	func weigh(game, p, from, offer: Dictionary) -> float:
		var v := offer_value(game, p, from, offer)
		var sname: String = from.sin.sin_name
		var behind: int = game.leader_score() - p.score
		var free_at := int(game.opt("mark_free_behind", 0))
		var mark: float = MARK_COST
		var prog := BotPolicy.progress(game)
		if int(p.marks.get(sname, 0)) + 1 >= game.marks_to_claim and not p.claims.has(sname):
			mark = CLAIM_COST * (1.0 - prog * 0.5)
		if free_at > 0 and behind >= free_at:
			v += mark  # this mark won't count
		elif behind <= 0:
			v -= mark * 0.5  # ahead: a claim is a bigger threat to a lead
		if behind >= 200:
			v += 20.0
		return v

	func pick_target(game, me):
		match target_mode:
			"leader":
				return game.leader_other(me)
			"next":
				var best = null
				for o in game.players:
					if o != me and o.score >= me.score and (best == null or o.score < best.score):
						best = o
				return best if best != null else game.leader_other(me)
		return super(game, me)


## Best, plus Split's offer and target modes.
class BestSplit extends Best:
	var offer_mode := "heur"
	var target_mode := "heur"
	var _s := Split.new()

	func wants_temptation(game, p, from, offer: Dictionary) -> bool:
		_s.offer_mode = offer_mode
		return _s.wants_temptation(game, p, from, offer)

	func pick_target(game, me):
		_s.target_mode = target_mode
		return _s.pick_target(game, me)


## REPLY 7: player profiles. Each game draws its numbers from a range (make(kind, rng)), and every
## decision has a `whim` chance of going the other way. Kinds: plain, novice (Novice's stop rule),
## banker, gambler, chaser, sitter, forgetter, taker, grudge.
class Profile extends Plain:
	const KINDS := ["plain", "novice", "banker", "gambler", "chaser", "sitter", "forgetter", "taker", "grudge"]
	var kind := "plain"
	var rng: RandomNumberGenerator
	var whim := 0.03          # a decision's chance of a mistake or a whim
	var seal_use := 1.0       # share of turns the seal is used at all (Forgetter)
	var accept_scale := 1.0   # Forgetter: share of the offers plain would take that it takes
	var buy_chance := 1.0     # Banker: rarely buys
	var behind_risk := 1.0    # Chaser: risk factor when 150+ behind
	var ahead_risk := 1.0     # Sitter: risk factor when ahead
	var tilt := 0.0           # Gambler: risk falls by this for two turns after a bust
	var novice_stop := 0      # Novice: throw again while under this and under 2 Strikes
	var _bust_seen := 0
	var _tilt_turns := 0
	var whims := 0

	static func make(p_kind: String, r: RandomNumberGenerator):
		var b = load("res://sim/sim_bots.gd").Profile.new()
		b.kind = p_kind
		b.rng = r
		b.label = p_kind
		b.whim = r.randf_range(0.01, 0.05)
		match p_kind:
			"plain":
				b.risk = r.randf_range(0.95, 1.05)
				b.bank_at = r.randi_range(270, 330)
			"novice":
				b.novice_stop = r.randi_range(120, 200)
				b.target_dice = 4
				b.risk = 1.0
				b.bank_at = 9999
			"banker":
				b.risk = r.randf_range(1.2, 1.5)
				b.bank_at = r.randi_range(120, 220)
				b.target_dice = r.randi_range(3, 4)
				b.buy_chance = r.randf_range(0.1, 0.3)
			"gambler":
				b.risk = r.randf_range(0.65, 0.85)
				b.bank_at = 9999
				b.tilt = r.randf_range(0.1, 0.2)
				b.target_dice = r.randi_range(5, 6)
			"chaser":
				b.risk = r.randf_range(0.95, 1.05)
				b.bank_at = r.randi_range(270, 330)
				b.behind_risk = r.randf_range(0.6, 0.75)
			"sitter":
				b.risk = r.randf_range(0.95, 1.05)
				b.bank_at = r.randi_range(270, 330)
				b.ahead_risk = r.randf_range(1.3, 1.6)
			"forgetter":
				b.risk = r.randf_range(0.95, 1.05)
				b.bank_at = r.randi_range(250, 350)
				b.seal_use = r.randf_range(0.3, 0.6)
				b.accept_scale = r.randf_range(0.1, 0.3)
			"taker", "grudge":
				b.risk = r.randf_range(0.95, 1.05)
				b.bank_at = r.randi_range(270, 330)
		return b

	func _whim() -> bool:
		if rng.randf() < whim:
			whims += 1
			return true
		return false

	func risk_for(p, game) -> float:
		var r: float = super(p, game)
		var lead = game.leader_other(p)
		if lead != null:
			var d: int = lead.score - p.score
			if d >= 150:
				r *= behind_risk
			elif d < 0:
				r *= ahead_risk
		if p.busts > _bust_seen:  # Gambler's tilt
			_bust_seen = p.busts
			_tilt_turns = 2
		if _tilt_turns > 0:
			r -= tilt
		return r

	func wants_throw(p, game, turn_points: int, strikes: int) -> bool:
		if game.turn.throws == 0:
			if _tilt_turns > 0:
				_tilt_turns -= 1
			return true
		var go: bool
		if kind == "novice":
			if game.turn.min_points >= 0 and turn_points < game.turn.min_points:
				go = true
			elif p.score + turn_points >= int(game.opt("win_score", Rules.WIN_SCORE)) and not game.end_triggered:
				go = false
			elif game.finish_round and game.end_triggered:
				go = p.score + turn_points <= game.leader_score()
			else:
				go = turn_points < int(novice_stop * scale(game)) and strikes < 2
		else:
			go = super(p, game, turn_points, strikes)
		return not go if _whim() else go

	func dice_to_buy(p, game) -> int:
		if buy_chance < 1.0 and rng.randf() >= buy_chance:
			return 0
		var n: int = super(p, game)
		if _whim():
			n = maxi(0, n + (1 if rng.randf() < 0.5 else -1))
		return n

	func wants_temptation(game, p, from, offer: Dictionary) -> bool:
		var yes: bool
		match kind:
			"taker":
				yes = true
			"novice":
				yes = rng.randf() < 0.5  # a new player takes about half, without sums
			_:
				yes = super(game, p, from, offer)
				if yes and accept_scale < 1.0:
					yes = rng.randf() < accept_scale
		return not yes if _whim() else yes

	## The Master's borrowed seal (sim_game _master_bargain).
	func wants_borrow(game, p, from, costs_mark: bool) -> bool:
		var yes := true
		var sname: String = from.sin.sin_name
		if costs_mark and int(p.marks.get(sname, 0)) + 1 >= game.marks_to_claim and not p.claims.has(sname):
			yes = kind == "taker"
		if kind == "forgetter" or kind == "novice":
			yes = yes and rng.randf() < 0.5
		return not yes if _whim() else yes

	## Swap (opt "swap"): trade seals for a round when behind; Taker always, Forgetter and Novice half the time.
	func wants_swap(game, p, from, costs_mark: bool) -> bool:
		var yes: bool = kind == "taker" or game.leader_score() > p.score
		if costs_mark and int(p.marks.get(from.sin.sin_name, 0)) + 1 >= game.marks_to_claim and not p.claims.has(from.sin.sin_name):
			yes = kind == "taker"
		if kind == "forgetter" or kind == "novice":
			yes = rng.randf() < 0.5
		return not yes if _whim() else yes

	## Grudge: whoever last hurt me, never the leader by default.
	func pick_target(game, me):
		if kind == "grudge" and not me.grudges.is_empty():
			return game.players[me.grudges[me.grudges.size() - 1]]
		return super(game, me)
