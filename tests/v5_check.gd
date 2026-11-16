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
	await _windows()
	_comeback()
	_gap()
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
	g.turn.strikes = 0
	check(b.wants_power(g, g.players[0], "Greed") == true, "bot: Greed banks half of 400 with no Strikes")


## A test Sin: its power, in `window`, is always ready and counts its uses.
class TestSin extends "res://sins/sin.gd":
	var window := "throw"
	var asked := 0
	var used := 0
	func _init(w := "throw") -> void:
		sin_name = "Test"
		window = w
	func power_window() -> String:
		return window
	func power_ready(_g, _m, _t) -> bool:
		asked += 1
		return true
	func use_power(_g, _m, turn, _c) -> bool:
		used += 1
		for i in turn.faces.size():
			if turn.faces[i] <= 2:
				turn.faces[i] = 3
		return false


## Item 3: one power a turn, asked only in its window; off without the powers key.
func _windows() -> void:
	for w in ["start", "throw", "decide"]:
		var g := _table(2)
		var s := TestSin.new(w)
		g.players[0].sin = s
		for i in 6:
			await g.take_turn(g.players[0])
		check(s.used == 6, "%s window: used once a turn (%d)" % [w, s.used])
		check(g.players[0].powers_used == 6, "%s window: counted" % w)
	var off := _table(2, {"powers": false})
	var s2 := TestSin.new("throw")
	off.players[0].sin = s2
	await off.take_turn(off.players[0])
	check(s2.asked == 0 and s2.used == 0, "powers off: never asked")


## Item 4: an offer's gain scales with the deficit (points to 5, dice rounded, others not); the mark rule.
func _comeback() -> void:
	var g := _table()
	var p = g.players[0]
	var lead = g.players[1]
	lead.score = 500
	p.score = 500
	check(g.comeback_factor(p) == 1.0, "level: x1")
	p.score = 300
	check(is_equal_approx(g.comeback_factor(p), 2.0), "200 behind: x2")
	p.score = 0
	check(is_equal_approx(g.comeback_factor(p), 3.0), "500 behind: capped at x3")
	p.score = 400
	var pts: Dictionary = g.scaled_offer(p, {"id": "t", "gain": "points", "g": 50, "cost": "lose", "c": 25})
	check(pts.g == 75 and pts.c == 25, "100 behind: 50 points -> 75, cost unchanged")
	p.score = 340
	pts = g.scaled_offer(p, {"id": "t", "gain": "points", "g": 60, "cost": "lose", "c": 25})
	check(pts.g == 105, "160 behind: 60 x1.8 = 108 -> 105")
	var dice: Dictionary = g.scaled_offer(p, {"id": "t", "gain": "dice", "g": 2, "cost": "bank", "c": 50})
	check(dice.g == 4, "160 behind: 2 extra dice -> 4")
	var x2: Dictionary = g.scaled_offer(p, {"id": "t", "gain": "x2", "g": 1, "cost": "bank", "c": 50})
	check(x2.g == 1 and not x2.has("scaled"), "x2 doesn't scale")
	check(g.mark_is_free(p), "160 behind: the mark is free")
	p.score = 400
	check(not g.mark_is_free(p), "100 behind: the mark counts")
	var v4 := Game.new([p.bot, p.bot], 1, Rules.V4.duplicate(), [])
	check(v4.comeback_factor(v4.players[0]) == 1.0 and not v4.mark_is_free(v4.players[0]), "V4: no comeback, every mark counts")


## Item 5: a seat 150+ behind has an offer ready every turn; others every other turn.
func _gap() -> void:
	var g := _table()
	g.round_count = 2
	var p = g.players[0]
	g.players[1].score = 400
	p.score = 300
	p.turns_started = 1
	p.last_offer_turn = 1
	g.turn = TurnState.new()
	g._start_costs(p)
	check(not g.turn.tempt_ready, "100 behind, offered last turn: no offer")
	p.score = 200
	p.last_offer_turn = p.turns_started
	g.turn = TurnState.new()
	g._start_costs(p)
	check(g.turn.tempt_ready, "200 behind, offered last turn: an offer anyway")
