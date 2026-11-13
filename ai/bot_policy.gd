## Simple bot: buys up to a target dice count, presses while it feels safe.
extends RefCounted

const Rules = preload("res://core/rules.gd")

var label: String
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
	var total: int = p.score + turn_points
	if turn_points > 0 and total >= Rules.WIN_SCORE and total > game.leader_score():
		return 0
	if turn_points >= bank_at:
		return 0
	match Rules.STRIKES_TO_BUST - strikes:
		3:
			return mini(cap_3_left, p.dice)
		2:
			return mini(cap_2_left, p.dice)
		_:
			return mini(cap_1_left, p.dice)
