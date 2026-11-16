## Rules.V5 (Docs/TableDesign.md §10): the rule dict, the powers, comeback offers, the mark rule, the
## Master's facts, and seeded bot games. V4 must be unchanged.
## godot --headless --path . --script res://tests/v5_check.gd
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const TurnState = preload("res://core/turn_state.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"), preload("res://sins/greed.gd"), preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"), preload("res://sins/pride.gd"), preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]

var fails: Array[String] = []
var checks := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		fails.append(what)


func _initialize() -> void:
	_rules()
	_bot()
	check(TurnState.new().power_used == false, "a new turn has its power unspent")
	var base = preload("res://sins/sin.gd").new()
	check(base.power_window() == "" and not base.power_ready(null, null, null) and not base.use_power(null, null, null, true), "a Sin has no power by default")
	for f in fails:
		print("FAIL ", f)
	print("V5 CHECK %s: %d checks" % ["PASSED" if fails.is_empty() else "FAILED (%d)" % fails.size(), checks])
	quit()


func _table(n := 4, opts := {}, first := 0) -> Game:
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	var o := Rules.V5.duplicate()
	o["tier2"] = true
	o.merge(opts, true)
	var sins := []
	var bots := []
	for i in n:
		sins.append(SIN_SCRIPTS[(first + i) % SIN_SCRIPTS.size()].new())
		bots.append(bot)
	var g := Game.new(bots, 1, o, sins)
	g.turn = TurnState.new()
	g.current = g.players[0]
	return g


## Item 1: V5 is V4 with Purgatory off and the §10 numbers; V4 still has Purgatory and its own numbers.
func _rules() -> void:
	check(Rules.V4.purgatory == true and Rules.V4.auto_purgatory == true, "V4 keeps Purgatory")
	check(Rules.V4.vig == 40 and Rules.V4.fury_trigger == 150 and not Rules.V4.has("v5"), "V4 numbers unchanged")
	check(Rules.V5.purgatory == false and Rules.V5.auto_purgatory == false, "V5: no Purgatory")
	check(Rules.V5.v5 and Rules.V5.v4 and Rules.V5.powers, "V5 flags")
	check(Rules.V5.vig == 60 and Rules.V5.fury_trigger == 300 and Rules.V5.fury_grudge == 200, "V5: Vig 60, Fury 300 / 200")
	check(Rules.V5.hubris_mult == 1.75 and Rules.V5.hubris_targets == [150, 200, 250], "V5: Hubris x1.75 at 150 / 200 / 250")
	check(Rules.V5.eat == 90 and Rules.V5.greed_mult == 1.5 and Rules.V5.wrath_rethrow == 2, "V5: power numbers")
	check(Rules.V5.comeback_per == 200 and Rules.V5.comeback_cap == 3.0 and Rules.V5.mark_free_behind == 150, "V5: comeback numbers")
	for k in Rules.V4:
		if k in ["purgatory", "auto_purgatory", "purgatory_cost", "vig", "fury_trigger", "fury_grudge", "hubris_mult", "feast", "rage", "glance_trail"]:
			continue
		check(Rules.V5.has(k) and Rules.V5[k] == Rules.V4[k], "V5 keeps V4's %s" % k)
	var g := _table()
	check(not g.purgatory_on and not g.auto_purgatory, "V5 game: Purgatory off")


## Item 11: the bot presses at the first chance; Pride names the lowest Bank; Greed weighs half now.
func _bot() -> void:
	var g := _table()
	var b = g.players[0].bot
	check(b.wants_power(g, g.players[0], "Wrath") == true, "bot: Wrath presses at once")
	check(b.wants_power(g, g.players[0], "Pride") == 150, "bot: Pride names 150")
	g.turn.points = 20
	check(b.wants_power(g, g.players[0], "Greed") == false, "bot: Greed keeps a small stake whole")
	g.turn.points = 400
	g.turn.strikes = 2
	check(b.wants_power(g, g.players[0], "Greed") == true, "bot: Greed banks half of 400 on 2 Strikes")
