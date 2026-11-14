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
		# Someone already hit 1000: press until we beat them, there's no next turn.
		return total <= game.leader_score()
	if total >= Rules.WIN_SCORE and total > game.leader_score():
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
	# Pride's Hubris: a bet turn scores 0 below the target, so never bank short of it.
	if game.turn.min_points >= 0 and turn_points < game.turn.min_points:
		return true
	if total >= Rules.WIN_SCORE and total > game.leader_score():
		return false
	if turn_points >= bank_at:
		return false
	return expected_after_throw(game._max_throw(p), turn_points, Rules.STRIKES_TO_BUST - strikes, game.chain, game.face_mult) > turn_points * risk


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
	if turn_points > 0 and total >= Rules.WIN_SCORE and total > game.leader_score():
		return 0
	if turn_points >= bank_at:
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
