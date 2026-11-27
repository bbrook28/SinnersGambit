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


## The buttons on screen, not counting How to play, Match log, the Sins' names and Spark of Rage on a roll.
func acts() -> int:
	var n := 0
	for k in h.btn:
		if k != "help" and k != "log" and not k.begins_with("sin") and not k.begins_with("spark"):
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
	await test_two_players()
	await test_log()
	await test_display()
	await test_fits()
	await test_whole_match()
	print("table_test: %d failure(s)" % _fails)
	quit(1 if _fails > 0 else 0)


func test_howto() -> void:
	await screen([4, 5, 1], 1, true)
	check("a match opens on the How to play card: Got it, and 2, 3 or 4 players with 4 chosen", h.howto.is_visible_in_tree() and can_tap("got_it") and can_tap("seats2") and can_tap("seats3") and can_tap("seats4") and acts() == 4 and h.seats == 4)
	var all := " ".join(h.HOWTO)
	check("the card is at most eight lines", h.HOWTO.size() <= 8)
	var facts := ["1000", "40, 50 or 60", "Purgatory", "two or more", "20", "give points", "lend a die", "one die a turn", "buy a die for someone", "not binding", "pass the phone", "Tap a Sin", "each ability once on your turn"]
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
	check("How to play brings the card back, and before the first turn the number of players can still be changed", h.howto.visible and can_tap("got_it") and can_tap("seats2") and acts() == 4)
	tap("got_it")
	tap("ready")
	tap("roll")
	tap("help")
	check("once a turn has begun the card has one button: the number of players is fixed", can_tap("got_it") and acts() == 1 and not h.count_row.is_visible_in_tree())
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
	check("passing asks for the phone to go to Player 2", h.title.text == "Pass the phone to Player 2" and h.panels[1].tag.text == "TURN" and h.panels[0].tag.text == "LEADING")
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
	check("the winner screen has two buttons: Match log and New match", can_tap("new") and can_tap("log_win") and acts() == 2)
	tap("new")
	check("a new match opens on the How to play card again, with the number of players to choose", can_tap("got_it") and can_tap("seats2") and acts() == 4)
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
	# the longest rows: an ability's share under every score, and every tag the turn player can show
	for i in 4:
		h.shares[i] = ["Slow Drip +40", 40]
	h.s.seats[0].used = {"spark": true, "strike": true}
	h.s.seats[0].armed = true
	h.s.seats[0].lethargic = true
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
	check("the top row with Match log and How to play stays inside the 1080 width (%d)" % int(h.help_btn.get_global_rect().end.x), h.help_btn.get_global_rect().end.x <= 1080.0 and h.log_btn.is_visible_in_tree())


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
	check("Pride can declare Hubris before the roll, and the button says what to beat and what it pays", can_tap("hubris") and h.btn.hubris.text.contains("beat 50 to score 50 more"))
	tap("hubris")
	check("declared: the line says so, and it cannot be declared twice", h.event.contains("declared Hubris") and h.event.contains("scores 50 more") and not can_tap("hubris") and h.btn.hubris.text.contains("Already used this turn") and can_tap("roll"))
	tap("roll")
	check("60 beats 50: the screen says the score includes 50 more", shown().contains("scored 110") and shown().contains("includes 50 more") and h.panels[0].points.text == "110")
	check("no Hubris words still say the score doubles", not (h.event + shown() + h.Sins.card("hubris").text).contains("doubl"))

	# Green-Eyed Glance, before the roll
	await screen([6, 1, 1,  1, 2, 3], 1, false, ["wrath", "envy", "gluttony", "pride"])
	turns(1)
	tap("ready")
	tap("glance")
	check("Envy picks any die an opponent rolled", can_tap("d0_0") and can_tap("d0_1") and not h.btn.has("d1_0"))
	tap("d0_0")
	check("one die will not be rolled: two dice and the copied 6", h.btn.roll.text == "Roll 2 dice, plus the copied 6" and h.event.contains("is not rolled and shows 6, copied from Player 1"))
	await process_frame
	await process_frame
	check("while the copy waits the roll text says the same as the button, and fits (text ends at %d of 1080, buttons at %d of 1920)" % [int(h.text.get_global_rect().end.x), int(h.buttons.get_global_rect().end.y)],
		shown().contains("Roll 2 dice once. The last die is not rolled: it shows the copied 6.") and not shown().contains("Roll all your dice")
		and h.text.get_global_rect().end.x <= 1080.0 and h.text.get_global_rect().position.x >= 0.0 and h.buttons.get_global_rect().end.y <= 1920.0)
	tap("roll")
	check("1, 2 and the copied 6: 60, not Purgatory, and still three dice", h.panels[1].points.text == "60" and h.panels[1].roll.get_child_count() == 3 and can_tap("pass")
		and shown().contains("You rolled 1, 2, 6 and scored 60. Green-Eyed Glance: the last die is the copied 6, not rolled."))
	check("the match log has the use: who was copied and which face", h.log.lines().slice(-2) == [
		"R1 Player 2 (Envy): used Green-Eyed Glance: one die of the next roll is not rolled and shows 6, copied from Player 1. [+0, total 0]",
		"R1 Player 2 (Envy): rolled 1, 2, 6, scored 60, Glance +60 [+60, total 60]"])
	tap("pass")
	turns(3)
	tap("ready")
	check("on Envy's next turn Glance is switched off and the button says why", not can_tap("glance") and h.btn.glance.text.contains("Not on two turns running: open again next turn.") and h.btn.roll.text == "Roll 3 dice")
	await process_frame
	await process_frame
	check("the switched-off button fits the screen (%d of 1080 wide, ends at %d of 1920)" % [int(h.btn.glance.get_global_rect().end.x), int(h.buttons.get_global_rect().end.y)],
		h.btn.glance.get_global_rect().end.x <= 1080.0 and h.btn.glance.get_global_rect().position.x >= 0.0 and h.buttons.get_global_rect().end.y <= 1920.0)
	tap("roll")
	tap("pass")
	turns(3)
	tap("ready")
	check("and on the turn after that it can be used again", can_tap("glance"))
	tap("sin1")
	check("Envy's card has the new words", h.sin_text.text.contains("one of your dice is not rolled") and h.sin_text.text.contains("Not on two turns running") and not h.sin_text.text.contains("temporary"))
	tap("close")

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

	# Whisper of Desire cannot be what takes Lust to 1000: Player 1 shows 6, 5, 1; Lust on 900 rolls 4, 1, 1
	await screen([6, 5, 1,  4, 1, 1], 1, false, ["wrath", "lust", "gluttony", "pride"])
	turns(1)
	give(1, 900)
	tap("ready")
	tap("roll")
	check("the swap view states the limit", shown().contains("Not if the swap is what takes you to 1000"))
	tap("whisper")
	tap("d1_1")
	check("the 6 would make 1000: it is switched off and the screen says why; the 5 can be taken", not can_tap("d0_0") and can_tap("d0_1") and shown().contains("A swap cannot be what takes you to 1000"))
	tap("d0_1")
	check("swapped for the 5: 990 and no winner", h.panels[1].points.text == "990" and h.s.winner == -1 and can_tap("pass"))
	# every swap would reach 1000: Lust on 990 rolls 1, 2, 3
	await screen([6, 5, 1,  1, 2, 3], 1, false, ["wrath", "lust", "gluttony", "pride"])
	turns(1)
	give(1, 990)
	tap("ready")
	tap("roll")
	check("when every swap would reach 1000 the Whisper button is off with the reason, and the roll can be scored", not can_tap("whisper") and h.btn.whisper.text.contains("Every swap would take you to 1000") and can_tap("settle"))
	tap("settle")
	check("scored as it is: Purgatory", h.panels[1].tag.text.contains("IN PURGATORY"))

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


## Two players (Ben, 2026-11-26): chosen on the How to play card. Every die shows 4, so no roll offers Lust a swap.
func test_two_players() -> void:
	await screen([], 1, true, ["lust", "gluttony"])
	tap("seats3")
	check("3 players: three players on the table", h.s.seats.size() == 3 and h.panels.size() == 3 and h.panel_box.get_child_count() == 3 and h.howto.visible)
	tap("seats2")
	check("2 players: choosing 2 starts a two-player match, still on the card, with 2 shown as chosen", h.s.seats.size() == 2 and h.panels.size() == 2 and h.panel_box.get_child_count() == 2
		and h.howto.visible and h.seats == 2 and Rules.total_dice(h.s) == 12)
	tap("got_it")
	check("2 players: pass the phone to Player 1; both players shown with their Sins", h.title.text == "Pass the phone to Player 1" and h.panels[0].sin.text == "Lust" and h.panels[1].sin.text == "Gluttony"
		and h.panels[1].points.is_visible_in_tree() and h.header.text.contains("6 dice"))
	tap("sin0")
	check("2 players: Lust's card says Entangling Allure is between the two of you", h.sin_text.text.contains("You and the other player each secretly pick") and not h.sin_text.text.contains("Choose 2 players"))
	tap("close")
	tap("sin1")
	check("2 players: Gluttony's card says not on two turns running", h.sin_text.text.contains("Not on two turns running") and not h.sin_text.text.contains("same target"))
	tap("close")
	give(0, 400)
	give(1, 400)
	tap("ready")
	tap("roll")
	tap("points")
	check("2 players: a gift is to the one other player, already chosen", can_tap("offer") and can_tap("other1") and not h.btn.has("other0") and shown().contains("Player 1 gives 10 points to Player 2."))
	tap("back")
	tap("pass")
	# Gluttony bites
	tap("ready")
	tap("roll")
	tap("bite")
	check("2 players: the one other player is the target", can_tap("target0") and not h.btn.has("target1") and shown().contains("Steal 20 from the other player"))
	tap("target0")
	check("2 players: Voracious Bite stole 20", h.event.contains("used Voracious Bite on Player 1: stole 20"))
	tap("pass")
	# Lust: Entangling Allure with the one other player
	tap("ready")
	tap("roll")
	tap("allure")
	check("2 players: Lust picks first, in secret, with no players to choose", h.title.text == "Player 1: pick one die in secret" and can_tap("d0_0") and can_tap("d0_2") and not h.btn.has("d1_0")
		and can_tap("back") and not h.btn.has("use") and shown().contains("you take theirs"))
	tap("back")
	check("2 players: Back before the pick costs nothing", can_tap("allure") and h.panels[0].points.text == str(400 + 120 - 20 + 120))
	tap("allure")
	tap("d0_0")
	check("2 players: then the phone goes to the other player, and Lust's pick is not shown", h.title.text == "Pass the phone to Player 2" and can_tap("ready") and acts() == 1 and h.event == "" and not h.btn.has("d0_0") and shown().contains("secret"))
	tap("ready")
	check("2 players: they tap one of their own dice", can_tap("d1_0") and not h.btn.has("d0_0") and shown().contains("takes yours"))
	tap("d1_0")
	check("2 players: a 4 and a 4 match: Lust takes the other player's die, and the phone goes back", h.panels[0].dice.text == "4 dice" and h.panels[1].dice.text == "2 dice"
		and h.event.contains("Player 1 picked a 4 and Player 2 a 4") and h.event.contains("A match: Player 1 took that die from Player 2") and h.event.contains("Pass the phone back to Player 1") and can_tap("pass"))
	check("2 players: Lust paid 40", h.panels[0].points.text == str(400 + 120 - 20 + 120 - 40))
	tap("pass")
	# Gluttony's next turn: not on two turns running
	tap("ready")
	tap("roll")
	tap("bite")
	check("2 players: the turn after a Bite it is refused, and the button says when it opens again", not can_tap("target0") and h.btn.target0.text.contains("two turns running") and h.btn.target0.text.contains("next turn"))
	tap("back")
	tap("pass")
	turns(1)
	tap("ready")
	tap("roll")
	tap("bite")
	check("2 players: on the turn after that it is open again", can_tap("target0"))
	tap("target0")
	await process_frame
	await process_frame
	check("2 players: the buttons end inside the screen (%d of 1920)" % int(h.buttons.get_global_rect().end.y), h.buttons.get_global_rect().end.y <= 1920.0)


## The log's lines as they are on screen, top first.
func log_shown() -> Array:
	var out := []
	for c in h.log_list.get_children():
		out.append(c.text)
	return out


## The match log: every move, newest first on screen, and the same lines oldest first in the copy.
func test_log() -> void:
	# a scripted match: Wrath rolls 4, 5, 1 and buys a die; Pride declares Hubris and rolls 6, 6, 6
	await screen([4, 5, 1,  6, 6, 6])
	check("Match log is a button on the table", can_tap("log"))
	tap("log")
	check("it opens the log: empty before the first move, with Copy log and Close", h.log_card.is_visible_in_tree() and can_tap("copy_log") and can_tap("close_log") and acts() == 2
		and h.log.entries.is_empty() and log_shown() == ["Nothing has happened yet."])
	tap("close_log")
	check("Close shows the table again", not h.log_card.visible and can_tap("ready"))
	tap("ready")
	tap("roll")
	tap("buy")
	tap("pass")
	tap("ready")
	tap("hubris")
	tap("roll")
	var want := [
		"R1 Player 1 (Wrath): rolled 4, 5, 1, scored 90 [+90, total 90]",
		"R1 Player 1 (Wrath): bought a die for 20 [-20, total 70]",
		"R1 Player 2 (Pride): declared Hubris: beat 90 and the roll scores 50 more; fail and it is 0. [+0, total 0]",
		"R1 Player 2 (Pride): rolled 6, 6, 6, scored 230, Hubris +50 [+230, total 230]",
	]
	check("the scripted match gives the expected log: round, player, Sin, roll, ability, points and total (got: %s)" % " | ".join(h.log.lines()), h.log.lines() == want)
	tap("log")
	var newest_first := want.duplicate()
	newest_first.reverse()
	check("on screen the same lines, newest first", log_shown() == newest_first)
	tap("copy_log")
	var copy: Array = Array(h.copied.split("\n"))
	var at: int = copy.find("Totals")
	var moves: Array = copy.slice(0, maxi(at, 0))
	moves.reverse()
	check("Copy log: one line a move, oldest first, matching the lines on screen", at == want.size() and moves == log_shown())
	check("then each player's totals: uses and points for each ability (got: %s)" % " | ".join(copy.slice(at + 1)), copy.slice(at + 1) == [
		"Player 1 (Wrath), 70 points: no abilities used", "Player 2 (Pride), 230 points: Hubris x1 +50",
		"Player 3 (Gluttony), 0 points: no abilities used", "Player 4 (Envy), 0 points: no abilities used"])
	check("the Copy log button says what happened", h.copy_btn.text != "Copy log")
	tap("close_log")
	# a refused attempt: buttons that cannot be used are switched off, so the refusal is forced here
	h._on_ability("feast", h.s.turn)
	h._on_die(h.s.turn, 0)
	check("a refused attempt is logged with the reason (%s)" % h.log.lines()[-1], h.log.lines()[-1] == "R1 Player 2 (Pride): tried Feast: refused. Not this Sin's ability. [+0, total 230]")

	# into Purgatory, and the win
	await screen([1, 2, 3,  6, 1, 1])
	h.s.seats[1].points = 940
	h._refresh()
	tap("ready")
	tap("roll")
	check("a roll into Purgatory is logged", h.log.lines()[-1] == "R1 Player 1 (Wrath): rolled 1, 2, 3, scored 0, into Purgatory [+0, total 0]")
	tap("pass")
	tap("ready")
	tap("roll")
	check("the win is logged after the roll that won", h.log.lines().slice(-2) == ["R1 Player 2 (Pride): rolled 6, 1, 1, scored 60 [+60, total 1000]", "R1 Player 2 (Pride): wins with 1000 points [+0, total 1000]"])
	tap("log_win")
	check("Match log on the winner screen opens the log, the win on top", h.log_card.is_visible_in_tree() and log_shown()[0].contains("wins with 1000 points"))
	tap("close_log")
	check("and Close goes back to the winner screen", h.title.text == "Player 2 wins!" and can_tap("new"))
	tap("new")
	check("a new match starts with an empty log", h.log.entries.is_empty())

	# staying in Purgatory, and out of it
	await screen([1, 2, 3,  4, 4, 4,  4, 4, 4,  4, 4, 4,  2, 6, 6,  4, 4, 4,  4, 4, 4,  4, 4, 4,  3, 3, 5])
	turns(5)
	check("a roll that stays in Purgatory is logged", h.log.lines()[-1] == "R2 Player 1 (Wrath): rolled 2, 6, 6, scored 0, stays in Purgatory [+0, total 0]")
	turns(3)
	tap("ready")
	tap("roll")
	check("a roll out of Purgatory is logged, in round 3", h.log.lines()[-1] == "R3 Player 1 (Wrath): rolled 3, 3, 5, scored 50, out of Purgatory [+50, total 50]")

	# a gift, agreed and refused, and The Vig
	await screen([6, 6, 6], 1, false, ["wrath", "greed", "gluttony", "envy"])
	tap("ready")
	tap("roll")
	tap("buy")
	check("The Vig is logged for Greed", h.log.lines()[-1] == "R1 Player 2 (Greed): The Vig: gained 20 from the die Player 1 bought [+20, total 20]")
	tap("points")
	tap("other2")
	tap("offer")
	tap("agree")
	check("an agreed gift is logged for the giver", h.log.lines()[-1] == "R1 Player 1 (Wrath): gift, Player 3 agreed: Player 1 gives 10 points to Player 3. [-10, total 150]")
	tap("points")
	tap("other2")
	tap("offer")
	tap("refuse")
	check("a refused gift is logged, and nothing moved", h.log.lines()[-1] == "R1 Player 1 (Wrath): gift, Player 3 refused: Player 1 gives 10 points to Player 3. [+0, total 150]")
	tap("log")
	tap("copy_log")
	check("the totals count The Vig for Greed", h.copied.contains("Player 2 (Greed), 20 points: The Vig x1 +20"))

	# Entangling Allure: the secret picks are not in the log until both are made
	await screen([], 1, false, ["lust", "pride", "gluttony", "envy"])
	give(0, 400)
	turns(4)
	tap("ready")
	tap("roll")
	if can_tap("settle"):
		tap("settle")
	tap("allure")
	tap("target1")
	tap("target2")
	tap("use")
	tap("ready")
	tap("d1_0")
	tap("log")
	check("after the first secret pick the log shows nothing of Entangling Allure", not " ".join(log_shown()).contains("Allure") and not " ".join(log_shown()).contains("picked"))
	tap("close_log")
	check("closing the log goes back to the pass for the second pick", h.title.text == "Pass the phone to Player 3" and can_tap("ready"))
	tap("ready")
	tap("d2_0")
	tap("take2")
	check("once both are picked it is logged, with the picks (%s)" % h.log.lines()[-1], h.log.lines()[-1] ==
		"R2 Player 1 (Lust): used Entangling Allure on Player 2 and Player 3: they picked a 4 and a 4. A match: Player 1 took that die from Player 3, to keep. [-40, total 600]")
	tap("log")
	tap("copy_log")
	check("the totals count its cost", h.copied.contains("Player 1 (Lust), 600 points: Entangling Allure x1 -40"))

	# Spark of Rage: counted for Wrath with what it did to the other player
	await screen([4, 4, 4,  6, 5, 1,  2])
	turns(1)
	tap("ready")
	tap("roll")
	tap("spark1")
	tap("d1_0")
	check("Spark of Rage out of turn is logged for Wrath (%s)" % h.log.lines()[-1], h.log.lines()[-1] ==
		"R1 Player 1 (Wrath): used Spark of Rage on Player 2: a 6 was rerolled and came up 2. Player 2 lost 70. [+0, total 120]")
	tap("log")
	tap("copy_log")
	check("the totals show what it cost the others", h.copied.contains("Player 1 (Wrath), 120 points: Spark of Rage x1 +0 (others -70)"))


## The table's own words and colors: who leads, who is close, what an ability added to a score, what is used up.
func test_display() -> void:
	await screen([4, 5, 1,  6, 6, 6])
	check("before anyone scores no one is LEADING", not h.panels[0].tag.text.contains("LEADING"))
	tap("ready")
	tap("roll")
	check("the player in first place is tagged LEADING", h.panels[0].tag.text == "TURN  LEADING" and h.panels[1].tag.text == "")
	tap("pass")
	tap("ready")
	tap("roll")
	check("the tag moves when the lead changes", h.panels[1].tag.text.contains("LEADING") and not h.panels[0].tag.text.contains("LEADING"))
	h.s.seats[0].points = 180
	h._refresh()
	check("players tied for first are both LEADING", h.panels[0].tag.text.contains("LEADING") and h.panels[1].tag.text.contains("LEADING"))
	give(2, 840)
	check("at 840 a player is shown as any other", h.panels[2].box.bg_color == h.PANEL and h.panels[2].points.get_theme_color("font_color") == h.TEXT)
	give(2, 10)
	check("at 850 the player's box and points are brighter", h.panels[2].box.bg_color == h.PANEL_NEAR and h.panels[2].points.get_theme_color("font_color") == h.GOLD
		and h.panels[2].box.get_border_width(SIDE_LEFT) == 6 and h.panels[0].box.bg_color != h.PANEL_NEAR)
	give(1, 700)
	check("and so is the turn player's at 850 or more, with the turn border", h.panels[1].box.bg_color == h.PANEL_NEAR and h.panels[1].box.get_border_width(SIDE_LEFT) == 10)

	# what an ability added to a score
	await screen([6, 1, 1,  1, 2, 3], 1, false, ["wrath", "envy", "gluttony", "pride"])
	turns(1)
	tap("ready")
	check("before any ability is used the row is not marked", not h.panels[1].tag.text.contains("USED"))
	tap("glance")
	tap("d0_0")
	check("Green-Eyed Glance used: the turn player's row says TIER 1 USED", h.panels[1].tag.text.contains("TIER 1 USED") and not h.panels[0].tag.text.contains("USED"))
	tap("roll")
	check("the score shows the ability's share: scored 60 (Glance +60)", h.panels[1].scored.text == "scored 60\n(Glance +60)" and h.panels[0].scored.text == "scored 60")
	await process_frame
	await process_frame
	check("the row with the share stays inside the 1080 width (%d)" % int(h.panels[1].scored.get_global_rect().end.x), h.panels[1].scored.get_global_rect().end.x <= 1080.0)
	tap("pass")
	check("after passing the mark is gone and the share stays with the roll", not h.panels[1].tag.text.contains("USED") and h.panels[1].scored.text.contains("(Glance +60)"))

	await screen([6, 1, 1], 1, false, ["pride", "wrath", "gluttony", "envy"])
	tap("ready")
	tap("hubris")
	tap("roll")
	check("a won Hubris: scored 110 (Hubris +50)", h.panels[0].scored.text == "scored 110\n(Hubris +50)")

	await screen([4, 1, 1], 1, false, ["sloth", "wrath", "gluttony", "envy"])
	tap("ready")
	tap("roll")
	check("Slow Drip: the 40 is in the score shown: scored 80 (Slow Drip +40)", h.panels[0].scored.text == "scored 80\n(Slow Drip +40)" and h.panels[0].points.text == "80"
		and not h.panels[0].tag.text.contains("USED"))

	await screen([6, 5, 1,  1, 2, 3], 1, false, ["wrath", "lust", "gluttony", "pride"])
	turns(1)
	tap("ready")
	tap("roll")
	tap("whisper")
	tap("d1_0")
	tap("d0_0")
	check("Whisper of Desire: scored 60 (Whisper +60), and the log has the swap then the roll", h.panels[1].scored.text == "scored 60\n(Whisper +60)"
		and h.log.lines().slice(-2) == ["R1 Player 2 (Lust): used Whisper of Desire on Player 1: swapped a 1 for their 6. [+0, total 0]", "R1 Player 2 (Lust): rolled 6, 2, 3, scored 60, Whisper +60 [+60, total 60]"])
	tap("spark1")
	tap("d1_0")
	check("Spark of Rage rerolls a die of that roll: the share is no longer shown beside the changed score", h.panels[1].scored.text == "scored 40")

	# Tier 2 used up
	await screen([4, 4, 4], 1, false, ["gluttony", "pride", "wrath", "envy"])
	give(0, 400)
	give(1, 100)
	tap("ready")
	tap("roll")
	check("Tier 2 open and unused reads TIER 2", h.panels[0].tag.text.contains("TIER 2") and not h.panels[0].tag.text.contains("USED"))
	tap("bite")
	tap("target1")
	check("after Voracious Bite the row says TIER 2 USED", h.panels[0].tag.text.contains("TIER 2 USED") and not h.panels[0].tag.text.contains("TIER 1 USED"))
	tap("feast")
	tap("d0_0")
	check("and after Feast, TIER 1 USED too", h.panels[0].tag.text.contains("TIER 1 USED") and h.panels[0].tag.text.contains("TIER 2 USED"))


## Whole matches by taps alone on seeded dice with the Sins dealt: any button on screen, at random, to a winner.
func test_whole_match() -> void:
	for c in [[7, 4], [8, 4], [9, 4], [10, 4], [11, 2], [12, 2], [13, 2], [14, 3]]:
		var seed_value: int = c[0]
		await screen(null, seed_value, true, [])
		if c[1] != 4:
			tap("seats%d" % c[1])
		tap("got_it")
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
			if Rules.total_dice(h.s) != c[1] * 3 + 6:
				stuck = "%d dice" % Rules.total_dice(h.s)
				break
			if taps % 500 == 0:
				await process_frame
		check("seed %d, %d players: a whole match by random taps ends in a winner (%d taps, round %d, %s; %s)" % [seed_value, c[1], taps, h.s.round_number,
			", ".join(h.s.seats.map(func(p): return p.sin)), stuck], stuck == "" and h.s.winner >= 0)
		check("seed %d: the winner screen is up" % seed_value, h.title.text.contains("wins!") and can_tap("new"))
