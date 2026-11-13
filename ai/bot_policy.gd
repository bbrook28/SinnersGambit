## Simple bot: buys up to a target dice count, picks a Purgatory escape style.
extends RefCounted

var label: String
var target_dice: int
var pay_indulgence: bool


func _init(p_target_dice: int, p_pay_indulgence := true) -> void:
	target_dice = p_target_dice
	pay_indulgence = p_pay_indulgence
	label = "buy-to-%d/%s" % [target_dice, "pay" if pay_indulgence else "redeem"]


func dice_to_buy(p) -> int:
	return target_dice - p.dice
