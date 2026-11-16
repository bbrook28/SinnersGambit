## Simple bot: buys up to a target dice count, presses while it feels safe.
extends RefCounted

const Rules = preload("res://core/rules.gd")

var label: String
var human := false  # ui/human.gd sets true; Sins then prompt instead of using their bot logic
var target_dice: int
## Pay the Indulgence while score is below this; above it, roll for Redemption.
var pay_below: int
## Press-all mode: press only while Strikes so far <= this. -1 = never press.
var press_max_strikes: int
## Stop pressing once the turn is worth this much.
var bank_at: int
## Dice-choice mode: most dice to throw with 3 / 2 / 1 Strikes left. 0 = bank.
var cap_3_left := 99
var cap_2_left := 99
var cap_1_left := 0
## Throw-all mode: throw again only when the average after one more throw beats banking by this factor.
var risk := 1.0


func _init(p_target_dice: int, p_pay_below := 99999, p_press_max_strikes := -1, p_bank_at := 9999) -> void:
	target_dice = p_target_dice
	pay_below = p_pay_below
	press_max_strikes = p_press_max_strikes
	bank_at = p_bank_at
	_make_label()


## The Master's call (Rules.MASTER_CALL, REPLY 10, 11): rounds left counting this one, 2 in the
## penultimate round and 1 in the final round; 0 before the call or with no call.
static func call_rounds_left(game) -> int:
	var at = game.get("master_call")
	var called = game.get("called_round")
	if at == null or int(at) <= 0 or called == null or int(called) < 0:
		return 0
	return maxi(0, int(called) + 3 - int(game.round_count))


## Banking this total wins the game outright: first to 1000 (never under the call, which has no win score).
static func wins_now(game, total: int) -> bool:
	var at = game.get("master_call")
	if at != null and int(at) > 0:
		return false
	return total >= Rules.WIN_SCORE and total > game.leader_score()


## How far through the game it is, 0 to 1: the leader against 1000, or under the call at least
## 0.7 in the penultimate round and 0.85 in the final round (a die is worth little with a turn or two left).
static func progress(game) -> float:
	var pr := clampf(float(game.leader_score()) / Rules.WIN_SCORE, 0.0, 1.0)
	var left := call_rounds_left(game)
	if left > 0:
		pr = maxf(pr, 1.0 - 0.15 * left)
	return pr


## Under the call, the penultimate round: behind the leader, keep throwing until this turn has made up
## half the gap (the final round is for the rest), while one more Strike would not bust.
static func must_chase(p, game, turn_points: int, strikes: int) -> bool:
	if call_rounds_left(game) != 2:
		return false
	var gap: int = game.leader_score() - p.score
	return gap > 0 and turn_points < gap / 2 and Rules.STRIKES_TO_BUST - strikes >= 2


## Dice-choice bot. caps = [with 3 Strikes left, 2 left, 1 left].
static func chooser(p_target_dice: int, caps: Array, p_bank_at := 9999, p_pay_below := 99999):
	var b = load("res://ai/bot_policy.gd").new(p_target_dice, p_pay_below, 0, p_bank_at)
	b.cap_3_left = caps[0]
	b.cap_2_left = caps[1]
	b.cap_1_left = caps[2]
	b.press_max_strikes = -2  # marks a chooser for the label
	b._make_label()
	return b


static func _cap_str(c: int) -> String:
	return "A" if c >= 99 else str(c)


func _make_label() -> void:
	label = "buy%d" % target_dice
	if press_max_strikes >= 0:
		label += "/s%d" % press_max_strikes
	elif press_max_strikes == -2:
		label += "/roll%s-%s-%s" % [_cap_str(cap_3_left), _cap_str(cap_2_left), _cap_str(cap_1_left)]
	if bank_at < 9999:
		label += "b%d" % bank_at
	if pay_below < 99999:
		label += "/pay<%d" % pay_below if pay_below > 0 else "/redeem"


func dice_to_buy(p, _game) -> int:
	return target_dice - p.dice


func wants_indulgence(p, _game) -> bool:
	return p.score < pay_below


func wants_press(p, game, turn_points: int, strikes: int) -> bool:
	var total: int = p.score + turn_points
	if game.finish_round and game.end_triggered:
		# Someone already hit 1000, or the Master's final round: press until we beat them, there's no next turn.
		return total <= game.leader_score()
	if must_chase(p, game, turn_points, strikes):  # the call: behind in the penultimate round
		return true
	if wins_now(game, total):
		return false
	if press_max_strikes < 0:
		return false
	return strikes <= press_max_strikes and turn_points < bank_at


## Dice-choice mode: how many dice to throw next. 0 = bank. Called before the first roll too.
func dice_to_roll(p, game, turn_points: int, strikes: int) -> int:
	var n := _normal_roll(p, game, turn_points, strikes)
	# Pride's Hubris: a called turn scores 0 unless it beats the bar, so don't bank short of it.
	if n == 0 and game.turn != null and game.turn.min_points >= 0 and turn_points < game.turn.min_points:
		n = mini(1 if Rules.STRIKES_TO_BUST - strikes <= 1 else 2, p.dice)
	return n


## Throw-all mode (Rules.V3): throw again (true) or bank (false). The first throw of a turn is always true.
## Throws again when one more throw, then banking, is worth more on average than banking now.
func wants_throw(p, game, turn_points: int, strikes: int) -> bool:
	if game.turn.throws == 0:
		return true
	var total: int = p.score + turn_points
	if game.finish_round and game.end_triggered:
		return total <= game.leader_score()
	# Pride's claim (V4): a Bank that doesn't beat your last scores 0.
	if game.v4 and game.claimed(p, "Pride") and turn_points <= p.last_bank and not game.opt("claim_pride_half", false) and game.opt("claim_pride_min", 0) == 0:
		return true
	if game.v4 and game.claimed(p, "Pride") and turn_points < int(game.opt("claim_pride_min", 0)):
		return true
	# Pride's Hubris: a bet turn scores 0 below the target, so never bank short of it.
	if game.turn.min_points >= 0 and turn_points < game.turn.min_points:
		return true
	if must_chase(p, game, turn_points, strikes):  # the call: behind in the penultimate round
		return true
	if wins_now(game, total):
		return false
	if turn_points >= bank_at:
		return false
	return expected_after_throw(game._max_throw(p), turn_points, Rules.STRIKES_TO_BUST - strikes, game.chain, game.face_mult) > turn_points * risk_for(p, game)


## Throw-all mode: banking now is worth turn_points; this is the average of throwing n dice once more
## and then banking (0 on a bust). Exact over how many dice come up Strike / blank 3 / scorer
## (a scorer averages 5 pips).
static func expected_after_throw(n: int, turn_points: int, strikes_left: int, chain: float, face_mult: int) -> float:
	var ev := 0.0
	for k in range(0, mini(strikes_left - 1, n) + 1):  # Strikes this throw that don't bust
		for s in range(0, n - k + 1):
			var b := n - k - s
			var prob := _fact(n) / (_fact(k) * _fact(b) * _fact(s)) * pow(1.0 / 3.0, k) * pow(1.0 / 6.0, b) * pow(0.5, s)
			var gain := 0.0
			if s > 0:
				gain = s * 5.0 * face_mult * (1.0 + chain * (s - 1))
			ev += prob * (turn_points + gain)
	return ev


static func _fact(n: int) -> float:
	var f := 1.0
	for i in range(2, n + 1):
		f *= i
	return f


func _normal_roll(p, game, turn_points: int, strikes: int) -> int:
	var total: int = p.score + turn_points
	if turn_points > 0 and wins_now(game, total):
		return 0
	if turn_points >= bank_at and not must_chase(p, game, turn_points, strikes):
		return 0
	if p.sin and p.sin.has_method("bot_bank_now") and game.turn != null and p.sin.bot_bank_now(game.turn):
		return 0
	match Rules.STRIKES_TO_BUST - strikes:
		3:
			return mini(cap_3_left, p.dice)
		2:
			return mini(cap_2_left, p.dice)
		_:
			return mini(cap_1_left, p.dice)


# ---------- Rules.V4: rivalry and temptations (Docs/TableDesign.md §4, §7) ----------

## Each Sin's bot plays to its nature: throws again when one more throw beats banking by this factor.
## Below 1 pushes harder (Wrath, Lust, Gluttony), above banks sooner (Sloth, Greed).
const SIN_RISK := {"Wrath": 0.9, "Lust": 0.9, "Gluttony": 0.9, "Sloth": 1.15, "Greed": 1.15}
## A claim's cost in points, for the mark that would bring it on (rough; sim/check_v3.gd measures it).
const CLAIM_COST := 100
## Points a mark costs when it doesn't bring a claim.
const MARK_COST := 15
## Accept when the offer's value beats refusing by this much (tunes the accept share).
const TEMPT_EDGE := 0.0


func risk_for(p, game) -> float:
	if game.v4 and p.sin:
		return risk * SIN_RISK.get(p.sin.sin_name, 1.0)
	return risk


## Pact and Drag: the newest grudge, unless the leader is 200+ ahead of that seat; then the leader.
func pick_target(game, me):
	var lead = game.leader_other(me)
	for i in range(me.grudges.size() - 1, -1, -1):
		var o = game.players[me.grudges[i]]
		if o != me and (lead == null or lead.score - o.score < 200):
			return o
	return lead


## A rough value of each offer for this decision, in points. Accepts when gain - cost - mark > edge.
## sim/check_v3.gd: offer id -> values seen (only while log_values is on).
static var log_values := false
static var value_log := {}


func wants_temptation(game, p, from, offer: Dictionary) -> bool:
	var v := offer_value(game, p, from, offer)
	if log_values:
		if not value_log.has(offer.id):
			value_log[offer.id] = []
		value_log[offer.id].append(v)
	return v > TEMPT_EDGE


func offer_value(game, p, from, offer: Dictionary) -> float:
	var t = game.turn
	var n: int = game._max_throw(p)
	var left: int = Rules.STRIKES_TO_BUST - t.strikes
	var ev_throw := expected_after_throw(n, t.points, left, game.chain, game.face_mult)
	var best_now := maxf(ev_throw, float(t.points)) if game.may_bank(p) else ev_throw
	var prog := progress(game)
	var die_worth := 110.0 * (1.0 - prog) + 20.0       # a die for the rest of the game
	var base_turn: float = 45.0 * p.dice                        # a typical banked turn with these dice
	var gain := 0.0
	match offer.gain:
		"points":
			gain = offer.g
		"clear":
			# One Strike fewer: worth the chance it saves the turn.
			var ev_after := expected_after_throw(n, t.points, left + 1, game.chain, game.face_mult)
			gain = maxf(ev_after, float(t.points)) - best_now + (0.15 * t.points if t.strikes >= 2 else 0.0)
		"dice":
			gain = expected_after_throw(n + offer.g, t.points, left, game.chain, game.face_mult) - best_now
		"x2":
			gain = expected_after_throw(n, t.points, left, game.chain, game.face_mult * 2) - best_now
		"die":
			gain = die_worth
	var cost := 0.0
	var later := 1.0 - 0.5 * prog  # a later turn may never come
	match offer.cost:
		"lose":
			cost = mini(offer.c, p.score)
		"bank":
			cost = offer.c * 0.9 * later
		"strike":
			cost = 0.3 * base_turn * later
		"fewer":
			cost = base_turn * float(offer.c) / maxf(1.0, p.dice) * later
		"die":
			cost = die_worth
	var sname: String = from.sin.sin_name
	var mark: float = MARK_COST
	if int(p.marks.get(sname, 0)) + 1 >= game.marks_to_claim and not p.claims.has(sname):
		mark = CLAIM_COST * (1.0 - prog * 0.5)
	return gain - cost - mark


# ---------- Rules.V5: powers (Docs/TableDesign.md §10) ----------

## The power is ready: use it? Returns false, true, or Pride's named Bank. Pressing at the first chance
## was the best policy in the sim for six Sins (sim/agency_sim.gd skill); Greed weighs half now at
## greed_mult against throwing the whole stake on.
func wants_power(game, p, sname: String):
	match sname:
		"Pride":
			return int(game.opt("hubris_targets", [150])[0])
		"Greed":
			var t = game.turn
			if t.points < int(game.opt("greed_min", 50)):
				return false
			var n: int = game._max_throw(p)
			var left: int = Rules.STRIKES_TO_BUST - t.strikes
			var half: int = t.points / 2 / 5 * 5
			var ev_all: float = maxf(float(t.points), expected_after_throw(n, t.points, left, game.chain, game.face_mult))
			var ev_half: float = half * float(game.opt("greed_mult", 1.5)) + expected_after_throw(n, t.points - half, left, game.chain, game.face_mult)
			return ev_half > ev_all
	return true


## Onboarding game one (Docs/Onboarding.md): an easier table, banking at 200, risk 1.55, buying to 4.
## A novice stand-in wins about 40% against two of these (sim/agency_sim.gd first).
static func first_game():
	var b = chooser(4, [99, 2, 0], 200)
	b.risk = 1.55
	b.label = "first game"
	return b
