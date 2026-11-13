## Simple bot: buys up to a target dice count, presses while it feels safe.
extends RefCounted

const Rules = preload("res://core/rules.gd")

var label: String
var target_dice: int
var pay_indulgence: bool
## Press only while Strikes so far <= this. -1 = never press.
var press_max_strikes: int
## Stop pressing once the turn is worth this much.
var bank_at: int


func _init(p_target_dice: int, p_pay_indulgence := true, p_press_max_strikes := -1, p_bank_at := 9999) -> void:
	target_dice = p_target_dice
	pay_indulgence = p_pay_indulgence
	press_max_strikes = p_press_max_strikes
	bank_at = p_bank_at
	label = "buy%d" % target_dice
	if not pay_indulgence:
		label += "/redeem"
	if press_max_strikes >= 0:
		label += "/s%d" % press_max_strikes
		if bank_at < 9999:
			label += "b%d" % bank_at


func dice_to_buy(p, _game) -> int:
	return target_dice - p.dice


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
