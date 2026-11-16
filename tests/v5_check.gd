## Rules.V5 (Docs/TableDesign.md §10): the rule dict, the powers, comeback offers, the mark rule, the
## Master's facts, and seeded bot games. V4 must be unchanged.
## godot --headless --path . --script res://tests/v5_check.gd
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const TurnState = preload("res://core/turn_state.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const Temptations = preload("res://sins/temptations.gd")
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
	await _master()
	_sins()
	await _fury()
	_apply()
	_bots()
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
	check(Rules.V5.eat == 60 and Rules.V5.greed_mult == 2.0 and Rules.V5.wrath_rethrow == 2 and Rules.V5.mimic == 3 and Rules.V5.drag == 4, "V5: power numbers")
	check(Rules.V5.comeback_per == 200 and Rules.V5.comeback_cap == 3.0 and Rules.V5.mark_free_behind == 150, "V5: comeback numbers")
	for k in Rules.V4:
		if k in ["purgatory", "auto_purgatory", "purgatory_cost", "vig", "fury_trigger", "fury_grudge", "hubris_mult", "feast", "rage", "glance_trail", "drag"]:
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


## A view that keeps the Master's facts and ignores the rest.
class FactView extends RefCounted:
	var events := []
	func master_event(kind, p, facts) -> void:
		events.append([kind, p.seat, facts])
	func log_line(_t) -> void:
		pass
	func say(_t) -> void:
		pass
	func beat(_p, _k) -> void:
		pass
	func turn_started(_p) -> void:
		pass
	func player_name(p) -> String:
		return "P%d" % p.seat


## Item 6: whole V5 games report start, busts, Banks of 200+, offers, marks and the end, with their facts.
func _master() -> void:
	var kinds := {}
	for seed in 12:
		var g := _table(4, {}, seed)
		g.rng.seed = seed
		var v := FactView.new()
		g.view = v
		await g.play()
		check(v.events[0][0] == "start", "seed %d: start first" % seed)
		check(v.events[-1][0] == "end" and v.events[-1][1] == g.winner.seat, "seed %d: end, with the winner" % seed)
		for e in v.events:
			kinds[e[0]] = kinds.get(e[0], 0) + 1
			match e[0]:
				"bust":
					check(e[2].strikes >= Rules.STRIKES_TO_BUST, "bust facts: Strikes")
				"bank":
					check(e[2].banked >= 200, "bank facts: 200+")
				"mark":
					check(e[2].has("first") and e[2].has("free"), "mark facts")
				"end":
					check(e[2].has("margin"), "end facts: margin (negative when a rival passed the winner off-turn)")
	for k in ["start", "bust", "bank", "offer", "mark", "end"]:
		check(kinds.get(k, 0) > 0, "12 games show a %s event" % k)


## Item 8: each Sin's power, and the Basics it replaces are off under V5 (still on under V4).
func _sins() -> void:
	var g := _table(4)
	var me = g.players[0]
	var t = g.turn
	var S := {}
	for s in SIN_SCRIPTS:
		var o = s.new()
		S[o.sin_name] = o
	g.last_throw = F([6, 2, 1])
	t.faces = F([1, 2, 5])
	check(S.Wrath.power_window() == "throw" and S.Wrath.power_ready(g, me, t), "Wrath: ready on a Strike")
	S.Wrath.use_power(g, me, t, true)
	check(t.faces[2] == 5 and t.faces.size() == 3, "Wrath: scorers stay")
	var w2 := [1, 1, 1, 5]
	t.faces = Array(w2, TYPE_INT, "", null)
	g.rng.seed = 3
	S.Wrath.use_power(g, me, t, true)
	check(t.faces[2] == 1, "Wrath: at most 2 Strikes rethrown")
	t.faces = F([4, 5, 6])
	check(not S.Wrath.power_ready(g, me, t), "Wrath: not ready without a Strike")
	t.faces = F([1, 4, 5])
	check(S.Lust.power_ready(g, me, t), "Lust: ready on a Strike when the last best is 4+")
	check(S.Lust.power_face(g) == 6, "Lust: her seal shows a 6")
	S.Lust.use_power(g, me, t, true)
	check(Array(t.faces) == [6, 4, 5], "Lust: the 1 becomes a 6")
	g.last_throw = F([3, 3])
	t.faces = F([1, 4])
	check(not S.Lust.power_ready(g, me, t), "Lust: not ready when the last best is under 4")
	t.faces = F([2, 4, 5])
	t.points = 0
	check(S.Gluttony.power_ready(g, me, t), "Gluttony: ready on a Strike")
	S.Gluttony.use_power(g, me, t, true)
	check(Array(t.faces) == [4, 5] and t.points == Rules.V5.eat and me.dice == 3, "Gluttony: eats the Strike die, +eat, keeps its dice")
	t.faces = F([1, 2, 6])
	S.Sloth.use_power(g, me, t, true)
	check(Array(t.faces) == [3, 3, 6], "Sloth: Strikes become 3s")
	t.faces = F([6, 4, 2])
	t.strikes = 0
	t.points = 0
	check(S.Envy.power_ready(g, me, t), "Envy: ready with a scorer")
	S.Envy.use_power(g, me, t, true)
	check(t.points == 6 * g.face_mult and t.faces.size() == 3, "Envy: +face x face_mult, no die added")
	t.faces = F([6, 1, 2])
	t.strikes = 1
	check(not S.Envy.power_ready(g, me, t), "Envy: not on a busting throw")
	t.strikes = 0
	check(S.Pride.power_window() == "start" and S.Pride.power_ready(g, me, t), "Pride: ready at the start")
	S.Pride.use_power(g, me, t, 250)
	check(t.min_points == 250, "Pride: names 250")
	S.Pride.use_power(g, me, t, 999)
	check(t.min_points == 150, "Pride: an unknown Bank names the lowest")
	t.points = 200
	me.score = 100
	check(S.Greed.power_window() == "decide" and S.Greed.power_ready(g, me, t), "Greed: ready with a stake")
	check(S.Greed.use_power(g, me, t, true) == true, "Greed: throws on")
	check(me.score == 100 + int(100 * Rules.V5.greed_mult) / 5 * 5 and t.points == 100, "Greed: half banked at greed_mult")
	# Basics off under V5, on under V4.
	t.faces = F([1, 3, 5])
	t.used_t1 = false
	var before: int = me.score
	S.Wrath.on_other_bust(g, me, g.players[1])
	check(me.score == before, "V5: Spark of Rage off")
	g.last_throw = F([6, 6])
	S.Lust.after_throw(g, me, t)
	check(Array(t.faces) == [1, 3, 5], "V5: Whisper off")
	S.Sloth.after_throw(g, me, t)
	check(Array(t.faces) == [1, 3, 5], "V5: Lazy Bones off")
	S.Gluttony.after_throw(g, me, t)
	check(Array(t.faces) == [1, 3, 5], "V5: Feast off")
	var t2 := TurnState.new()
	S.Pride.before_turn(g, me, t2)
	check(t2.min_points == -1, "V5: Hubris isn't automatic")
	var v4 := Game.new([me.bot, me.bot], 1, Rules.V4.duplicate(), [])
	v4.turn = TurnState.new()
	var q = v4.players[0]
	var b4: int = q.score
	S.Wrath.on_other_bust(v4, q, v4.players[1])
	check(q.score == b4 + Rules.V4.rage, "V4: Spark of Rage still on")


static func F(a: Array) -> Array[int]:
	return Array(a, TYPE_INT, "", null)


## Item 9: Fury reads fury_trigger / fury_grudge (V5: 300 / 200).
func _fury() -> void:
	var g := _table(2)
	var wrath = g.players[0]
	var other = g.players[1]
	wrath.sin = SIN_SCRIPTS[0].new()
	wrath.t2_unlocked = true
	wrath.t2_ready = true
	g.current = other
	g.turn.faces = F([6, 6, 6, 5])  # 287: under 300, over 200
	await wrath.sin.on_other_throw(g, wrath, other, g.turn)
	check(Array(g.turn.faces) == [6, 6, 6, 5] and wrath.t2_ready, "Fury: 287 from a stranger doesn't trigger at 300")
	wrath.grudges = [other.seat]
	await wrath.sin.on_other_throw(g, wrath, other, g.turn)
	check(not wrath.t2_ready, "Fury: 287 from a grudge triggers at 200")


## Item 10: Temptations.apply takes the scaled gain.
func _apply() -> void:
	var g := _table(2)
	var p = g.players[0]
	p.score = 0
	Temptations.apply({"id": "t", "gain": "points", "g": 75, "cost": "lose", "c": 0}, g, p)
	check(p.score == 75, "apply: scaled points land")
	Temptations.apply({"id": "t", "gain": "dice", "g": 4, "cost": "bank", "c": 50}, g, p)
	check(g.turn.extra_dice == 4 and p.pend_bank == 50, "apply: scaled extra dice land, the cost doesn't change")


## Item 12: the per-Sin risk tilt stays under V5. Item 13: the first-game bot.
func _bots() -> void:
	var g := _table(1)
	var p = g.players[0]
	var b = p.bot
	p.sin = SIN_SCRIPTS[6].new()  # Sloth banks early
	check(is_equal_approx(b.risk_for(p, g), b.risk * BotPolicy.SIN_RISK.Sloth), "V5 keeps the Sin risk tilt")
	var f = BotPolicy.first_game()
	check(f.bank_at == 200 and is_equal_approx(f.risk, 1.55) and f.target_dice == 4, "first-game bot: 200, 1.55, 4 dice")
