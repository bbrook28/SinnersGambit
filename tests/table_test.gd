## Drives the step 1 pass-and-play screen (ui/table_screen.gd) as taps would: every tap presses a button that is on screen.
## godot --headless --path . --script res://tests/table_test.gd
extends SceneTree

const TableScreen = preload("res://ui/table_screen.gd")
const Rules = preload("res://game/rules.gd")

var _fails := 0
var h


class Faces:
	var queue: Array = []
	func _init(f: Array) -> void:
		queue = f.duplicate()
	func randi_range(_a: int, _b: int) -> int:
		return 4 if queue.is_empty() else queue.pop_front()   # past the script every die shows 4


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_fails += 1


## A fresh screen on scripted dice (or random ones, seeded).
func screen(faces = null, seed_value := 1, card := false, sins := ["wrath", "pride", "gluttony", "envy"]) -> void:
	if h != null:
		h.queue_free()
	h = TableScreen.new()
	if faces != null:
		h.rng = Faces.new(faces)
	else:
		h.rng = RandomNumberGenerator.new()
		h.rng.seed = seed_value
	h.sins = sins
	h.size = Vector2(1080, 1920)
	root.add_child(h)
	await process_frame
	await process_frame
	if not card:
		tap("got_it")   # the How to play card, tested in test_howto


## Is this button on screen and able to be tapped?
func can_tap(key: String) -> bool:
	return h.btn.has(key) and h.btn[key].is_visible_in_tree() and not h.btn[key].disabled


## Taps a button; a tap on one that is missing or switched off fails the test.
func tap(key: String) -> void:
	if not can_tap(key):
		check("tap '%s' (on screen: %s)" % [key, ", ".join(h.btn.keys())], false)
		return
	h.btn[key].pressed.emit()


## The buttons on screen, not counting How to play, the Sins' names and Spark of Rage on a roll.
func acts() -> int:
	var n := 0
	for k in h.btn:
		if k != "help" and not k.begins_with("sin") and not k.begins_with("spark"):
			n += 1
	return n


## Ready, roll (Lust scores without swapping) and pass, for the player whose turn it is; n times.
func turns(n := 1) -> void:
	for i in n:
		tap("ready")
		tap("roll")
		if can_tap("settle"):
			tap("settle")
		tap("pass")


## Gives a seat points as the rules would (so 350 opens Tier 2) and redraws.
func give(seat: int, points: int) -> void:
	Rules.add_points(h.s, seat, points)
	h._refresh()


func shown() -> String:
	return h.title.text + " " + h.text.text


func _initialize() -> void:
	await test_howto()
	await test_first_turn()
	await test_purgatory()
	await test_buy()
	await test_gifts()
	await test_win()
	await test_sin_card()
	await test_abilities()
	await test_fits()
	await test_whole_match()
	print("table_test: %d failure(s)" % _fails)
	quit(1 if _fails > 0 else 0)


func test_howto() -> void:
	await screen([4, 5, 1], 1, true)
	check("a match opens on the How to play card, with one button", h.howto.is_visible_in_tree() and can_tap("got_it") and acts() == 1)
	var all := " ".join(h.HOWTO)
	check("the card is at most eight lines", h.HOWTO.size() <= 8)
	var facts := ["1000", "40, 50 or 60", "Purgatory", "two or more", "20", "give points", "lend a die", "one die a turn", "for someone else", "not binding", "pass the phone", "Tap a Sin", "each ability once on your turn"]
	var missing := []
	for f in facts:
		if not all.contains(f):
			missing.append(f)
	check("the card covers the goal, the roll, Purgatory, buying, the gifts, the Sins, promises and passing (missing: %s)" % ", ".join(missing), missing.is_empty())
	await process_frame
	check("the card fits the screen (button ends at %d of 1920)" % int(h.got_btn.get_global_rect().end.y), h.got_btn.get_global_rect().end.y <= 1920.0)
	tap("got_it")
	check("Got it shows the table: pass the phone to Player 1", not h.howto.visible and can_tap("ready") and can_tap("help"))
	tap("help")
	check("How to play brings the card back", h.howto.visible and can_tap("got_it") and acts() == 1)
	tap("got_it")
	tap("ready")
	tap("roll")
	tap("help")
	tap("got_it")
	check("the card can be read mid-turn and nothing changes", can_tap("pass") and can_tap("buy") and h.panels[0].points.text == "90")
	tap("points")
	check("How to play is on the table in the gift form too", can_tap("help"))


func test_first_turn() -> void:
	await screen([4, 5, 1,  6, 6, 6])
	check("it opens on: pass the phone to Player 1", h.title.text == "Pass the phone to Player 1" and can_tap("ready") and acts() == 1)
	var ok := true
	for i in 4:
		var n: Dictionary = h.panels[i]
		ok = ok and n.points.text == "0" and n.dice.text == "3 dice" and n.points.is_visible_in_tree() and n.dice.is_visible_in_tree()
	check("all four players show 0 points and 3 dice", ok)
	check("each player's Sin is shown", h.panels[0].sin.text == "Wrath" and h.panels[3].sin.text == "Envy")
	check("the header shows the goal and the supply", h.header.text.contains("1000") and h.header.text.contains("6 dice"))
	check("Player 1 is marked as the turn", h.panels[0].tag.text == "TURN" and h.panels[1].tag.text == "")
	tap("ready")
	check("then one Roll button, and the rules of the roll", can_tap("roll") and acts() == 1 and h.btn.roll.text == "Roll 3 dice" and shown().contains("Purgatory") and shown().contains("40, 50 or 60"))
	tap("roll")
	check("the result and what it scored", shown().contains("You rolled 4, 5, 1 and scored 90."))
	check("the panel shows 90 points, the roll and its score", h.panels[0].points.text == "90" and h.panels[0].roll.get_child_count() == 3 and h.panels[0].scored.text == "scored 90")
	check("the Gambit Phase offers Buy, the three gifts and Pass", can_tap("buy") and can_tap("points") and can_tap("lend") and can_tap("die") and can_tap("pass") and acts() == 6)
	tap("pass")
	check("passing asks for the phone to go to Player 2", h.title.text == "Pass the phone to Player 2" and h.panels[1].tag.text == "TURN" and h.panels[0].tag.text == "")
	tap("ready")
	tap("roll")
	check("Player 1's last roll stays on screen after Player 2 rolls", h.panels[0].roll.get_child_count() == 3 and h.panels[0].scored.text == "scored 90" and h.panels[1].points.text == "180")


func test_purgatory() -> void:
	# P1 into Purgatory; P2-P4 score; P1 one low: stays; P2-P4; P1 two lows: out
	await screen([1, 2, 3,  4, 4, 4,  4, 4, 4,  4, 4, 4,  2, 6, 6,  4, 4, 4,  4, 4, 4,  4, 4, 4,  3, 3, 5])
	tap("ready")
	tap("roll")
	check("all dice 1-3: the screen says Purgatory, 0 scored, turn over", shown().contains("Purgatory") and shown().contains("score 0") and h.panels[0].tag.text.contains("IN PURGATORY"))
	check("in Purgatory the only button is Pass", can_tap("pass") and acts() == 1)
	tap("pass")
	for i in 3:
		tap("ready")
		tap("roll")
		tap("pass")
	check("Purgatory status stays visible on other players' turns", h.panels[0].tag.text.contains("IN PURGATORY"))
	check("the handover says they are in Purgatory", shown().contains("in Purgatory"))
	tap("ready")
	check("the roll screen explains how to get out", shown().contains("two or more showing 1, 2 or 3"))
	tap("roll")
	check("one low die: stays in, scores nothing, and says why", shown().contains("need two or more") and h.panels[0].points.text == "0" and acts() == 1 and can_tap("pass"))
	tap("pass")
	for i in 3:
		tap("ready")
		tap("roll")
		tap("pass")
	tap("ready")
	tap("roll")
	check("two low dice: out of Purgatory, the roll scores, the Gambit Phase opens", shown().contains("out of Purgatory") and h.panels[0].points.text == "50" and not h.panels[0].tag.text.contains("PURGATORY") and can_tap("buy"))


func test_buy() -> void:
	await screen([4, 1, 1,  1, 1, 5])
	tap("ready")
	tap("roll")
	tap("buy")
	check("Buy takes 20 points and adds a die", h.panels[0].points.text == "20" and h.panels[0].dice.text == "4 dice" and h.header.text.contains("5 dice"))
	check("the screen says the die rolls from your next turn", shown().contains("next turn"))
	check("after one die the Buy button is off and says why", h.panels[0].points.text == "20" and not can_tap("buy") and h.btn.buy.text.contains("only one die a turn"))
	h.s.seats[0].bought = 0
	h.s.seats[0].points = 0
	h._refresh()
	check("with 0 points the Buy button is off and says why", h.panels[0].points.text == "0" and not can_tap("buy") and h.btn.buy.text.contains("need 20"))
	h.s.supply = 0
	h.s.seats[0].points = 100
	h._refresh()
	check("with an empty supply the Buy button is off and says why", not can_tap("buy") and h.btn.buy.text.contains("supply is empty"))


func test_gifts() -> void:
	await screen([6, 6, 6,  4, 4, 4, 4])
	tap("ready")
	tap("roll")
	# give points: 180 -> Player 3 gets 60
	tap("points")
	check("the gift form: I give or I ask, the three other players, an amount", can_tap("give") and can_tap("ask") and can_tap("other1") and can_tap("other2") and can_tap("other3") and not h.btn.has("other0") and can_tap("p10"))
	check("no offer until a player is chosen", not can_tap("offer") and shown().contains("Choose a player"))
	tap("other2")
	for i in 5:
		tap("p10")
	check("the form says what will happen", shown().contains("Player 1 gives 60 points to Player 3."))
	tap("offer")
	check("nothing changes until the other player agrees", h.s.seats[0].points == 180 and h.title.text == "Pass the phone to Player 3" and shown().contains("permanent") and can_tap("agree") and can_tap("refuse"))
	tap("agree")
	check("agreed: the points move, and the screen says so", h.panels[0].points.text == "120" and h.panels[2].points.text == "60" and shown().contains("Player 3 agreed") and shown().contains("Pass the phone back to Player 1"))
	# a refused gift changes nothing
	tap("points")
	tap("other1")
	tap("offer")
	tap("refuse")
	check("refused: nothing moves, and the screen says so", h.panels[0].points.text == "120" and h.panels[1].points.text == "0" and shown().contains("Player 2 refused"))
	# you cannot offer more than you have
	tap("points")
	tap("other1")
	tap("p100")
	tap("p100")
	check("the amount stops at what the giver has", h.offer.amount == 120)
	tap("all")
	check("All is everything the giver has", h.offer.amount == 120 and can_tap("offer"))
	# ask: Player 3 has 60
	tap("ask")
	tap("other2")
	tap("all")
	check("asking: the other player is the giver, so the amount stops at their points", h.offer.amount == 60 and shown().contains("Player 3 gives 60 points to Player 1."))
	tap("offer")
	check("the ask is put to Player 3", shown().contains("Player 1 asks") and h.title.text == "Pass the phone to Player 3")
	tap("agree")
	check("agreed: Player 3 gave 60 to Player 1", h.panels[0].points.text == "180" and h.panels[2].points.text == "0")
	# lend a die
	tap("lend")
	check("the lend form states the rule", shown().contains("one roll") and shown().contains("supply") and shown().contains("below 2 dice"))
	tap("other1")
	tap("offer")
	tap("agree")
	check("lent: Player 1 has 2 dice, Player 2 shows 3 dice + 1 lent", h.panels[0].dice.text == "2 dice" and h.panels[1].dice.text == "3 dice + 1 lent")
	tap("lend")
	tap("other1")
	check("on 2 dice you cannot lend, and the form says why", not can_tap("offer") and shown().contains("below 2 dice"))
	tap("back")
	# buy a die for another player
	tap("die")
	check("the form states who pays", shown().contains("pays 20"))
	tap("other3")
	tap("offer")
	tap("agree")
	check("bought for Player 4: Player 1 paid 20, Player 4 has 4 dice", h.panels[0].points.text == "160" and h.panels[3].dice.text == "4 dice" and h.header.text.contains("5 dice"))
	# no gifts with a player in Purgatory
	h.s.seats[2].purgatory = true
	h._refresh()
	tap("points")
	check("a player in Purgatory cannot be chosen, and the button says why", not can_tap("other2") and h.btn.other2.text.contains("Purgatory"))
	tap("back")
	tap("pass")
	tap("ready")
	check("Player 2 is told a die is lent for this roll", h.btn.roll.text == "Roll 4 dice" and shown().contains("lent to you for this roll"))
	tap("roll")
	check("after the roll the lent die is in the supply", h.panels[1].dice.text == "3 dice" and h.panels[1].roll.get_child_count() == 4 and h.header.text.contains("6 dice"))


func test_win() -> void:
	await screen([6, 1, 1,  4, 4, 4])
	h.s.seats[0].points = 940
	h._refresh()
	tap("ready")
	tap("roll")
	check("the winner screen names the winner", h.title.text == "Player 1 wins!" and h.panels[0].tag.text.contains("WINNER") and shown().contains("1000"))
	check("the only button starts a new match", can_tap("new") and acts() == 1)
	tap("new")
	check("a new match opens on the How to play card again", can_tap("got_it") and acts() == 1)
	tap("got_it")
	var fresh := true
	for i in 4:
		fresh = fresh and h.panels[i].points.text == "0" and h.panels[i].dice.text == "3 dice" and h.panels[i].roll.get_child_count() == 1
	check("a new match: everyone at 0 with 3 dice and no roll, Player 1 to start", fresh and h.title.text == "Pass the phone to Player 1")
	# no win while in Purgatory
	await screen([1, 1, 1])
	h.s.seats[0].points = 1000
	h._refresh()
	tap("ready")
	tap("roll")
	check("1000 points and a roll into Purgatory: no winner, and the screen says why", h.s.winner == -1 and shown().contains("cannot win while in Purgatory") and can_tap("pass"))


## Every view at its fullest stays inside a 1080 x 1920 screen.
func test_fits() -> void:
	await screen([1, 6, 6, 6, 6, 6, 6])
	var worst := 0.0
	var where := ""
	var views := ["handover"]
	tap("ready")
	views.append("roll")
	# the fullest table: everyone with many dice rolled, and 4-digit scores
	for p in h.s.seats:
		p.points = 600
		p.dice = 4
		p.last_roll = [6, 6, 6, 6]
		p.last_score = 240
		p.purgatory = true
	h.s.seats[0].purgatory = false
	h.s.seats[0].last_roll = []
	h.s.seats[0].lent = 1
	h.s.seats[1].dice = 6
	h.s.seats[1].last_roll = [6, 6, 6, 6, 6, 6]
	h.s.supply = 0
	h._refresh()
	var steps := [["", "roll"], ["roll", "gambit"], ["points", "give points"], ["back", ""], ["lend", "lend"], ["back", ""], ["die", "buy for a player"]]
	for st in steps:
		if st[0] != "":
			tap(st[0])
		if st[1] == "":
			continue
		if st[1] == "gambit":
			for p in h.s.seats:
				p.purgatory = false
			h._refresh()
		if h.btn.has("other1"):
			tap("other1")
		h.event = "Player 1 (Wrath) used Entangling Allure on Player 2 and Player 3: they picked a 5 and a 5. A match: Player 1 took that die from Player 3, to keep. Superiority: Player 1 lost 20 for targeting Player 2."
		h._refresh()
		await process_frame
		await process_frame
		await process_frame
		var bottom: float = h.buttons.get_global_rect().end.y
		if bottom > worst:
			worst = bottom
			where = st[1]
	check("the buttons end inside the screen in every view (lowest: %d of 1920, in %s)" % [int(worst), where], worst > 0 and worst <= 1920.0)
	var wide := 0.0
	for n in h.panels:
		wide = maxf(wide, n.points.get_global_rect().end.x)
	check("the panels stay inside the 1080 width (%d)" % int(wide), wide <= 1080.0)


func test_sin_card() -> void:
	await screen([4, 4, 4])
	check("each player's Sin is a button", can_tap("sin0") and can_tap("sin1") and can_tap("sin2") and can_tap("sin3"))
	tap("sin0")
	var card: String = h.sin_title.text + " " + h.sin_text.text
	check("tapping it shows the Sin's two abilities and the cost", h.sin_card.is_visible_in_tree() and card.contains("Wrath") and card.contains("Spark of Rage") and card.contains("reroll one die showing 5 or 6")
		and card.contains("Vengeful Strike") and card.contains("costs 50") and card.contains("350") and card.contains("at most once on your turn"))
	check("with one button, Close", can_tap("close") and acts() == 1)
	tap("close")
	tap("sin3")
	check("another player's Sin can be read too", (h.sin_title.text + h.sin_text.text).contains("Envy") and h.sin_text.text.contains("Jealous Grasp") and h.sin_text.text.contains("costs 30"))
	tap("close")
	check("Close shows the table again", not h.sin_card.visible and can_tap("ready"))
	var texts_ok := true
	for sin in h.Sins.INFO:
		for tier in ["t1", "t2"]:
			texts_ok = texts_ok and h.Sins.INFO[sin][tier].text.length() > 20
	check("all seven Sins have both cards", h.Sins.INFO.size() == 7 and texts_ok)


func test_abilities() -> void:
	# Spark of Rage, out of turn, from the button on a roll
	await screen([4, 4, 4,  6, 5, 1,  2])
	turns(1)
	tap("ready")
	tap("roll")
	check("a roll with a 5 or 6 shows Wrath's Spark of Rage button; Wrath's own roll does not", can_tap("spark1") and not h.btn.has("spark0"))
	tap("spark1")
	check("Wrath picks the die: only the 6 and the 5 can be tapped", can_tap("d1_0") and can_tap("d1_1") and not can_tap("d1_2") and can_tap("back"))
	tap("d1_0")
	check("one line says who did what to whom", h.event_box.is_visible_in_tree() and h.event.contains("Player 1 (Wrath) used Spark of Rage on Player 2") and h.event.contains("came up 2") and h.event.contains("Player 2 lost 70"))
	check("the points and the roll changed, and Player 2 plays on", h.panels[1].points.text == "40" and can_tap("pass") and h.title.text.contains("Player 2"))
	check("once a round: the button is gone", not h.btn.has("spark1"))
	tap("points")
	tap("back")
	check("the line stays while nothing is done", h.event.contains("Spark of Rage"))
	tap("buy")
	check("and goes at the next action", h.event == "" and not h.event_box.visible)

	# Hubris, before the roll
	await screen([6, 1, 1], 1, false, ["pride", "wrath", "gluttony", "envy"])
	tap("ready")
	check("Pride can declare Hubris before the roll, and the button says what to beat", can_tap("hubris") and h.btn.hubris.text.contains("beat 50"))
	tap("hubris")
	check("declared: the line says so, and it cannot be declared twice", h.event.contains("declared Hubris") and not can_tap("hubris") and h.btn.hubris.text.contains("Already used this turn") and can_tap("roll"))
	tap("roll")
	check("60 beats 50: the screen says the score doubled", shown().contains("doubled") and h.panels[0].points.text == "120")

	# Green-Eyed Glance, before the roll
	await screen([6, 1, 1,  1, 2, 3], 1, false, ["wrath", "envy", "gluttony", "pride"])
	turns(1)
	tap("ready")
	tap("glance")
	check("Envy picks any die an opponent rolled", can_tap("d0_0") and can_tap("d0_1") and not h.btn.has("d1_0"))
	tap("d0_0")
	check("the roll gets a fourth die", h.btn.roll.text == "Roll 4 dice" and h.event.contains("temporary die showing 6"))
	tap("roll")
	check("1, 2, 3 and the copied 6: 60, not Purgatory", h.panels[1].points.text == "60" and h.panels[1].roll.get_child_count() == 4 and can_tap("pass"))

	# Whisper of Desire, before scoring
	await screen([6, 5, 1,  1, 2, 3], 1, false, ["wrath", "lust", "gluttony", "pride"])
	turns(1)
	tap("ready")
	tap("roll")
	check("Lust's roll stops before scoring: swap, or score it as it is", h.title.text.contains("swap before scoring") and can_tap("whisper") and can_tap("settle") and h.panels[1].points.text == "0")
	tap("whisper")
	tap("d1_0")
	check("then a higher die of another player's", can_tap("d0_0") and can_tap("d0_1") and not can_tap("d0_2"))
	tap("d0_0")
	check("swapped, then scored: 60 and no Purgatory", h.panels[1].points.text == "60" and h.event.contains("swapped a 1 for their 6") and can_tap("pass") and shown().contains("scored 60"))

	# Feast, then Jealous Grasp copying it
	await screen([6, 4, 1,  5, 4, 1], 1, false, ["gluttony", "envy", "wrath", "pride"])
	tap("ready")
	tap("roll")
	check("Tier 2 is switched off below 350, and the button says why", not can_tap("bite") and h.btn.bite.text.contains("350"))
	tap("feast")
	check("Feast: only a 4, 5 or 6 can be given", can_tap("d0_0") and can_tap("d0_1") and not can_tap("d0_2"))
	tap("d0_0")
	check("Feast is used for this turn: its button is off and says so", not can_tap("feast") and h.btn.feast.text.contains("Already used this turn"))
	check("the 6 went to the supply for 150", h.panels[0].points.text == "250" and h.panels[0].dice.text == "2 dice" and h.event.contains("used Feast") and h.header.text.contains("7 dice"))
	tap("pass")
	give(1, 400)
	check("reaching 350 shows TIER 2 on the player", h.panels[1].tag.text.contains("TIER 2"))
	tap("ready")
	tap("roll")
	tap("grasp")
	check("Jealous Grasp lists what was used this round", can_tap("copy_feast") and shown().contains("Feast"))
	tap("copy_feast")
	tap("d1_0")
	check("Envy paid 30, gave a 5 to the supply and gained 150", h.panels[1].points.text == str(400 + 90 + 150 - 30) and h.event.contains("Jealous Grasp") and h.event.contains("Feast"))

	# Voracious Bite: pick the target
	await screen([4, 4, 4], 1, false, ["gluttony", "pride", "wrath", "envy"])
	give(0, 400)
	give(1, 100)
	tap("ready")
	tap("roll")
	tap("bite")
	check("the player picks the target", can_tap("target1") and can_tap("target2") and can_tap("target3") and not h.btn.has("target0") and can_tap("back"))
	tap("target1")
	check("Voracious Bite: 20 paid, 20 stolen", h.panels[0].points.text == "520" and h.panels[1].points.text == "80" and h.event.contains("used Voracious Bite on Player 2: stole 20"))
	check("once a turn: the button is off and says so", not can_tap("bite") and h.btn.bite.text.contains("Already used this turn"))

	# Superiority, then Lethargic Aura into it
	await screen([4, 4, 4], 1, false, ["pride", "sloth", "wrath", "envy"])
	give(0, 400)
	give(1, 400)
	tap("ready")
	tap("roll")
	tap("superiority")
	check("Superiority: 40 paid, and the player shows ARMED", h.panels[0].points.text == "480" and h.panels[0].tag.text.contains("ARMED"))
	tap("pass")
	tap("ready")
	tap("roll")
	tap("aura")
	tap("target0")
	check("the attacker loses 20, and the line says so", h.event.contains("Lethargic Aura on Player 1") and h.event.contains("Superiority: Player 2 lost 20") and h.panels[1].points.text == str(520 - 30 + 10 - 20))
	check("the target shows LETHARGIC, and is no longer ARMED", h.panels[0].tag.text.contains("LETHARGIC") and not h.panels[0].tag.text.contains("ARMED"))

	# Vengeful Strike: the target chooses, with the phone
	await screen([4, 4, 4], 1, false, ["wrath", "pride", "gluttony", "envy"])
	give(0, 400)
	tap("ready")
	tap("roll")
	tap("strike")
	tap("target2")
	check("the phone goes to the target to choose", h.title.text == "Pass the phone to Player 3" and can_tap("choose_points") and can_tap("choose_die") and acts() == 2)
	tap("choose_die")
	check("they gave a die: Wrath shows 4 dice (1 taken), and the phone goes back", h.panels[0].dice.text == "4 dice (1 taken)" and h.panels[2].dice.text == "2 dice"
		and h.event.contains("chose to give a die for 2 full rounds") and h.event.contains("Pass the phone back to Player 1") and can_tap("pass"))

	# Cut a Deal and The Vig
	await screen([6, 6, 6], 1, false, ["wrath", "greed", "gluttony", "envy"])
	tap("ready")
	tap("roll")
	tap("buy")
	check("The Vig: the line says Greed gained 20", h.event.contains("The Vig: Player 2 (Greed) gained 20") and h.panels[1].points.text == "20")
	tap("pass")
	give(1, 400)
	turns(0)
	tap("ready")
	tap("roll")
	check("The Vig is always on: its button is off and says so", not can_tap("vig") and h.btn.vig.text.contains("Always on"))
	tap("deal")
	check("a player with neither 50 points nor a spare die cannot be chosen... others can", can_tap("target0") and can_tap("target2"))
	tap("target2")
	check("a target without 50 points can only give a die", not can_tap("choose_points") and can_tap("choose_die"))
	tap("choose_die")
	check("Cut a Deal: Greed holds the die for 1 full round", h.panels[1].dice.text == "4 dice (1 taken)" and h.event.contains("1 full round"))

	# Entangling Allure: two secret picks, a match, Lust takes one
	await screen([], 1, false, ["lust", "pride", "gluttony", "envy"])
	give(0, 400)
	turns(4)
	tap("ready")
	tap("roll")
	if can_tap("settle"):
		tap("settle")
	tap("allure")
	check("no use until 2 players are chosen", not can_tap("use"))
	tap("target1")
	tap("target2")
	tap("use")
	check("the phone goes to the first, who is told to keep it hidden", h.title.text == "Pass the phone to Player 2" and can_tap("ready") and acts() == 1 and shown().contains("secret"))
	tap("ready")
	check("they tap one of their own dice", can_tap("d1_0") and can_tap("d1_2") and not h.btn.has("d2_0"))
	tap("d1_0")
	check("then the phone goes to the second, and the first pick is not shown", h.title.text == "Pass the phone to Player 3" and h.event == "" and not h.btn.has("d1_0"))
	tap("ready")
	tap("d2_0")
	check("a match: the phone goes back to Lust to take one of the two", h.title.text == "Pass the phone back to Player 1" and can_tap("take1") and can_tap("take2") and shown().contains("a match"))
	tap("take2")
	check("Lust took Player 3's die", h.panels[0].dice.text == "4 dice" and h.panels[2].dice.text == "2 dice" and h.event.contains("A match: Player 1 took that die from Player 3"))


## Whole matches by taps alone on seeded dice with the Sins dealt: any button on screen, at random, to a winner.
func test_whole_match() -> void:
	for seed_value in [7, 8, 9, 10]:
		await screen(null, seed_value, false, [])
		var pick := RandomNumberGenerator.new()
		pick.seed = seed_value
		var taps := 0
		var events := {}
		var stuck := ""
		while h.s.winner == -1 and taps < 60000:
			taps += 1
			var keys := []
			for k in h.btn:
				if can_tap(k) and k != "help" and not k.begins_with("sin"):
					keys.append(k)
			if keys.is_empty():
				stuck = "no button to tap: %s" % shown()
				break
			# pass less often than the rest, so turns have things happen in them
			var key: String = keys[pick.randi_range(0, keys.size() - 1)]
			if key == "pass" and keys.size() > 1 and pick.randi_range(0, 2) > 0:
				continue
			tap(key)
			if h.event != "":
				events[h.event.split(" used ")[-1].split(":")[0].split(" on ")[0]] = true
			if Rules.total_dice(h.s) != 18:
				stuck = "%d dice" % Rules.total_dice(h.s)
				break
			if taps % 500 == 0:
				await process_frame
		check("seed %d: a whole match by random taps ends in a winner (%d taps, round %d, %s; %s)" % [seed_value, taps, h.s.round_number,
			", ".join(h.s.seats.map(func(p): return p.sin)), stuck], stuck == "" and h.s.winner >= 0)
		check("seed %d: the winner screen is up" % seed_value, h.title.text.contains("wins!") and can_tap("new"))
