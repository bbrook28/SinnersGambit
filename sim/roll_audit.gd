## Roll audit (REPLY 12 item 3): face counts from the game's own roll path. Sim only.
## A: Rules.roll (the one call every throw goes through, core/game.gd take_turn), seeded per game the
##    way ui/main.gd seeds a table game (randi()).
## B: whole core table games (Rules.V5 plus the Master's call, as ui/main.gd table_rules), counted from
##    each raw throw (before any reroll, Sin or power changes it), seat 0 (the player's seat, played by
##    a stand-in bot: the same code path, no human input) apart from the bots.
## godot --headless --path . --script res://sim/roll_audit.gd -- [dice per group, default 1000000]
extends SceneTree

const Rules = preload("res://core/rules.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const Game = preload("res://core/game.gd")
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"), preload("res://sins/greed.gd"), preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"), preload("res://sins/pride.gd"), preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]


## A stand-in view for core/game.gd: core logs "<name> throws N: ..." straight after Rules.roll, before
## any reroll, Sin or power touches the dice, so the raw throw is read there, by seat kind.
class AuditView extends RefCounted:
	var game = null
	var stand_in = null
	var counts := {"player": [0, 0, 0, 0, 0, 0], "bots": [0, 0, 0, 0, 0, 0]}

	func log_line(text: String) -> void:
		# Only the throw line itself ("seatN throws 5: ..."), not "throws at most 1 fewer" or Purgatory's.
		if game.turn != null and game.current != null and text.begins_with("seat%d throws %d:" % [game.current.seat, game.turn.faces.size()]):
			var c: Array = counts["player" if game.current.bot == stand_in else "bots"]
			for f in game.turn.faces:
				c[f - 1] += 1

	func beat(_p, _kind: String) -> void:
		pass

	func player_name(p) -> String:
		return "seat%d" % p.seat

	func turn_started(_p) -> void:
		pass


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var want: int = int(args[0]) if args.size() > 0 and args[0].is_valid_int() else 1000000
	randomize()
	# A: the roll call itself.
	var a := [0, 0, 0, 0, 0, 0]
	var done := 0
	while done < want:
		var rng := RandomNumberGenerator.new()
		rng.seed = randi()
		for t in 40:
			for f in Rules.roll(rng, 5):
				a[f - 1] += 1
		done += 200
	_print("A  Rules.roll", a)
	# B: whole games.
	var o: Dictionary = Rules.V5.duplicate()
	o["master_call"] = Rules.MASTER_CALL
	o["tier2"] = true
	var tot := {"player": [0, 0, 0, 0, 0, 0], "bots": [0, 0, 0, 0, 0, 0]}
	var games := 0
	while _sum(tot.player) < want:
		var stand_in = BotPolicy.chooser(5, [99, 2, 0], 300)
		var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
		var pool: Array = range(7)
		pool.shuffle()
		var sins := []
		for i in 4:
			sins.append(SIN_SCRIPTS[pool[i]].new())
		var g := Game.new([stand_in, bot, bot, bot], randi(), o, sins)
		var v := AuditView.new()
		v.game = g
		v.stand_in = stand_in
		g.view = v
		await g.play()
		for k in tot:
			for i in 6:
				tot[k][i] += v.counts[k][i]
		games += 1
	print("B  %d core table games" % games)
	_print("B  player seat", tot.player)
	_print("B  bot seats", tot.bots)
	quit()


func _sum(c: Array) -> int:
	var s := 0
	for v in c:
		s += v
	return s


## Counts, shares, Strike share (1-2) and chi-square against a fair die (5 degrees of freedom: 11.07 at p 0.05).
func _print(name: String, c: Array) -> void:
	var n: float = _sum(c)
	var chi := 0.0
	var parts := []
	for i in 6:
		var e := n / 6.0
		chi += pow(c[i] - e, 2) / e
		parts.append("%d: %d (%.2f%%)" % [i + 1, c[i], 100.0 * c[i] / n])
	print("%s, %d dice: %s | Strikes (1-2) %.2f%% (fair 33.33) | chi-square %.2f (fair below 11.07 at p 0.05)" % [
		name, int(n), ", ".join(parts), 100.0 * (c[0] + c[1]) / n, chi])
