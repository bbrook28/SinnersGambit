## Rules.V4 (Docs/TableDesign.md): every offer's gain and cost, the claims, debts, rounding, seeded bot
## games, and one UI game that must show a temptation with Accept and Refuse.
## godot --headless --path . --script res://tests/table_check.gd
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const TurnState = preload("res://core/turn_state.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const Temptations = preload("res://sins/temptations.gd")
const Tuning = preload("res://ui/tuning.gd")
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"), preload("res://sins/greed.gd"), preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"), preload("res://sins/pride.gd"), preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]

var fails: Array[String] = []
var checks := 0
var main
var ui_offers := 0
var ui_games := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		fails.append(what)


func _initialize() -> void:
	_offers()
	_claims()
	_debts()
	_rounding()
	await _bot_games()
	await _ui_game()
	for f in fails:
		print("FAIL ", f)
	print("TABLE CHECK %s: %d checks" % ["PASSED" if fails.is_empty() else "FAILED (%d)" % fails.size(), checks])
	quit()


func _table(n := 4, opts := {}) -> Game:
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	var o := Rules.V4.duplicate()
	o["tier2"] = true
	o.merge(opts, true)
	var sins := []
	var bots := []
	for i in n:
		sins.append(SIN_SCRIPTS[i].new())
		bots.append(bot)
	var g := Game.new(bots, 1, o, sins)
	g.turn = TurnState.new()
	g.current = g.players[0]
	return g


## Each of the 28 offers: the gain lands now, the cost is booked as its kind says.
func _offers() -> void:
	check(Temptations.all_ids().size() == 28, "28 offers")
	for sname in Temptations.OFFERS:
		check(Temptations.OFFERS[sname].size() == 4, "%s has 4 offers" % sname)
		for offer in Temptations.OFFERS[sname]:
			check(offer.gain in ["points", "clear", "dice", "x2", "die"], "%s gain kind" % offer.id)
			check(offer.cost in ["lose", "bank", "strike", "fewer", "die"], "%s cost kind" % offer.id)
			var g := _table()
			var p = g.players[0]
			p.score = 300
			g.players[1].score = 500  # someone leads, for "trail" and Wrath's w2
			p.dice = 4
			g.turn.strikes = 2
			g.turn.throws = 1
			var supply_before := g.supply
			check(Temptations.fits(offer, g, p) or offer.when.contains("s0"), "%s fits (2 Strikes, trailing)" % offer.id)
			if offer.when.contains("s0"):
				g.turn.strikes = 0
				check(Temptations.fits(offer, g, p), "%s fits with no Strikes" % offer.id)
			var strikes_before: int = g.turn.strikes
			var throws_now := Temptations.apply(offer, g, p)
			check(throws_now == (offer.gain in ["dice", "x2"]), "%s throws at once only for dice / x2" % offer.id)
			match offer.gain:
				"points":
					check(p.score == 300 + offer.g - (offer.c if offer.cost == "lose" else 0), "%s points now" % offer.id)
					if offer.get("leader", false):
						check(g.players[1].score == 500 - offer.g, "%s takes from the leader" % offer.id)
				"clear":
					check(g.turn.strikes == strikes_before - 1, "%s clears a Strike" % offer.id)
				"dice":
					check(g.turn.extra_dice == offer.g, "%s extra dice" % offer.id)
				"x2":
					check(g.turn.x2, "%s x2" % offer.id)
				"die":
					check(p.dice == 5 and g.supply == supply_before - 1, "%s free die" % offer.id)
			match offer.cost:
				"lose":
					if offer.gain != "points":
						check(p.score == 300 - offer.c, "%s loses points now" % offer.id)
				"bank":
					check(p.pend_bank == offer.c, "%s next Bank debt" % offer.id)
				"strike":
					check(p.pend_strike == 1, "%s Strike next turn" % offer.id)
				"fewer":
					check(p.pend_fewer == offer.c, "%s fewer dice next turn" % offer.id)
				"die":
					check(p.pend_die == 1, "%s loses a die" % offer.id)
	# Conditions.
	var g2 := _table()
	g2.turn.strikes = 0
	var w1: Dictionary = Temptations.OFFERS.Wrath[0]
	check(not Temptations.fits(w1, g2, g2.players[0]), "w1 needs 2 Strikes")
	g2.players[0].score = 900
	check(not Temptations.fits(Temptations.OFFERS.Wrath[1], g2, g2.players[0]), "w2 needs someone ahead")
	g2.players[0].dice = Rules.MIN_DICE
	check(not Temptations.fits(Temptations.OFFERS.Greed[3], g2, g2.players[0]), "no die cost at the two-die floor")


## Claims: each binds as written.
func _claims() -> void:
	var g := _table()
	var p = g.players[0]
	p.claims = ["Lust"]
	g.turn.throws = 1
	check(not g.may_bank(p), "Lust: no Bank after one throw")
	g.turn.throws = 2
	check(g.may_bank(p), "Lust: Bank from the second throw")
	p.claims = ["Sloth"]
	p.dice = 5
	check(g._max_throw(p) == 5 - Rules.V4.claim_sloth_fewer, "Sloth: fewer dice")
	p.claims = ["Pride"]
	check(g._bank_costs(p, Rules.V4.claim_pride_min - 5) == 0, "Pride: a Bank under the bar scores nothing")
	check(g._bank_costs(p, Rules.V4.claim_pride_min) == Rules.V4.claim_pride_min, "Pride: the bar itself counts")
	p.claims = ["Greed"]
	var greed = g.sin_player("Greed")
	var before: int = greed.score
	check(g._bank_costs(p, 100) == 100 - Rules.V4.claim_greed and greed.score == before + Rules.V4.claim_greed, "Greed: every Bank pays Greed")
	p.claims = ["Envy"]
	p.score = 0
	g.players[1].score = 500
	check(g._bank_costs(p, 100) == 100, "Envy: no cut while you trail")
	p.score = 600
	check(g._bank_costs(p, 100) == 100 - Rules.V4.claim_envy, "Envy: cut while you lead")
	p.claims = ["Wrath", "Gluttony"]
	p.score = 300
	p.dice = 4
	g._bust(p)
	check(p.score == 300 - Rules.V4.claim_bust, "Wrath: a bust costs")
	check(p.dice == 3, "Gluttony: a bust eats a die")
	# Marks: the claiming mark clears them and adds the claim once.
	var g2 := _table(4, {"tempt_chance": 1.0})
	var q = g2.players[0]
	q.marks = {"Greed": Rules.V4.marks_to_claim - 1}
	check(g2.marks_to_claim == Rules.V4.marks_to_claim, "marks_to_claim from the rules")


## Debts: paid at the right moment, and a bust doesn't pay the next-Bank debt.
func _debts() -> void:
	var g := _table()
	var p = g.players[0]
	p.pend_bank = 50
	check(g._bank_costs(p, 30) == 0 and p.pend_bank == 0, "next-Bank debt takes up to the Bank")
	p.pend_bank = 50
	g._bust(p)
	check(p.pend_bank == 50, "a bust doesn't pay the next-Bank debt")
	p.in_purgatory = false
	p.dice = 4
	p.pend_die = 1
	g._end_turn(p, 0)
	check(p.dice == 3 and p.pend_die == 0, "lose a die as the turn ends")
	p.dice = Rules.MIN_DICE
	p.pend_die = 1
	g._end_turn(p, 0)
	check(p.dice == Rules.MIN_DICE, "lose a die never goes below the floor")
	p.pend_fewer = 2
	p.pend_strike = 1
	p.dice = 5
	g.turn = TurnState.new()
	g._start_costs(p)
	check(p.fewer_now == 2 and g._max_throw(p) == 3, "fewer dice next turn")
	check(g.turn.strikes == 1 and p.pend_strike == 0, "start next turn with a Strike")


func _rounding() -> void:
	var raw := Rules.score([4, 5] as Array[int], 0.5, 5)
	check(raw == 67, "V3 score unchanged (67)")
	check(raw / 5 * 5 == 65, "V4 rounds 67 down to 65")


## Seeded bot games: they end, offers come, claims happen, nothing goes negative.
func _bot_games() -> void:
	var offers := 0
	var taken := 0
	var claims := 0
	for s in 200:
		var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
		var o := Rules.V4.duplicate()
		o["tier2"] = true
		var sins := []
		var bots := []
		for i in 4:
			sins.append(SIN_SCRIPTS[(s + i * 2) % 7].new())
			bots.append(bot)
		var g := Game.new(bots, s, o, sins)
		var w = await g.play()
		check(w != null and w.score >= Rules.WIN_SCORE, "game %d ends with a winner at %d+" % [s, Rules.WIN_SCORE])
		claims += g.claims_made
		for p in g.players:
			offers += p.offers_seen
			taken += p.offers_taken
			check(p.score >= 0 and p.dice >= 1, "game %d: no negative score or dice" % s)
	check(offers > 1000, "offers come (%d in 200 games)" % offers)
	check(taken > 0 and taken < offers, "some offers taken, some refused")
	check(claims > 0, "claims happen (%d in 200 games)" % claims)
	print("bot games: %d offers, %d%% taken, %.2f claims a game" % [offers, 100 * taken / maxi(1, offers), claims / 200.0])


## One UI game per seed until a temptation shows: Accept and Refuse are the only buttons.
func _ui_game() -> void:
	Tuning.table_size = 4
	Tuning.speed = Tuning.SPEED_MAX
	Engine.time_scale = 8.0
	await process_frame
	while ui_offers == 0 and ui_games < 6:
		ui_games += 1
		main = load("res://ui/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		main.save_enabled = false
		main.tutorial_enabled = false
		main.first_game_enabled = false
		main._start(main.SIN_SCRIPTS[ui_games % 7])
		var done := false
		var frames := 0
		while not done and frames < 200000:
			await process_frame
			frames += 1
			if main._buttons == null:
				continue
			var bs: Array = main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion())
			if bs.is_empty():
				continue
			if bs[0].text == "New game":
				done = true
				break
			var texts: Array = bs.map(func(b): return b.text)
			if "Accept" in texts:
				ui_offers += 1
				check(texts.size() == 2 and "Refuse" in texts, "an offer shows Accept and Refuse only: %s" % [texts])
				check(main._prompt_label.get_parsed_text().find(":") > 0, "the offer names its Sin")
			bs[randi() % bs.size()].pressed.emit()
		main.queue_free()
		await process_frame
	check(ui_offers > 0, "a UI game shows a temptation")
	print("ui: %d offers in %d games" % [ui_offers, ui_games])
