## Step 1: 2, 3 or 4 players pass one phone (rules: docs/step1-rules.md, in game/). A flat blockout: boxes and words, no art.
## Before the first turn: the How to play card (also behind the How to play button), where the number of players is chosen.
## Top: the players, always shown (points, dice, Purgatory, last roll); tap a Sin's name to read its abilities.
## Then one line saying who did what to whom, kept until the next action. Bottom: what the player holding the phone does now.
## The Match log button (top, and on the winner screen) lists every move of the match, newest first (ui/match_log.gd).
extends Control

const Rules = preload("res://game/rules.gd")
const Config = preload("res://game/config.gd")
const Sins = preload("res://game/sins.gd")
const MatchLog = preload("res://ui/match_log.gd")

const FELL_FILE := preload("res://assets/fonts/IMFellEnglish-NoDigits.ttf")
const DIGITS_TEXT := preload("res://assets/fonts/Digits-Text.ttf")

const BG := Color("14161c")
const PANEL := Color("22262f")
const PANEL_TURN := Color("343b4b")
const PANEL_NEAR := Color("5a4310")   # a player within NEAR_GAP points of the goal
const TEXT := Color("f2ead8")
const DIM := Color("9aa0ad")
const GOLD := Color("e8c06a")
const DARK := Color("14161c")
const BAD := Color("ff6b5e")
const BUTTON := Color("3a4152")
const BUTTON_OFF := Color("262a33")
const SEAT_COLORS := [Color("ff8a7a"), Color("6fb8ff"), Color("7fe08a"), Color("ffd24a")]

const W := 1040          # content width
const DIE := 64          # a die of a last roll
const PICK := 104        # a die you tap to choose it
const SIZE_SMALL := 34
const SIZE_TEXT := 40
const SIZE_NAME := 48
const SIZE_TITLE := 54
const SIZE_POINTS := 72
const BUTTON_H := 116
const GIFT_TITLES := {"points": "Give points", "lend": "Lend a die", "die": "Buy a die for a player"}
const GIFT_RULES := {
	"points": "Any amount the giver has. The other player taps to agree; then it is permanent.",
	"lend": "The die is theirs for one roll, then it goes to the supply, not back to the lender. No one can go below 2 dice.",
	"die": "The giver pays 20 and the die from the supply is theirs to keep.",
}
## The How to play card: shown before the first turn of each match, and from the How to play button at any time.
const HOWTO := [
	"First to 1000 points wins.",
	"On your turn, roll all your dice once. A 4, 5 or 6 scores 40, 50 or 60.",
	"If every die shows 1, 2 or 3 you are in Purgatory: no score, and your turn ends. On a later turn, two or more dice showing 1, 2 or 3 get you out.",
	"After rolling you can buy one die a turn for 20. You can also give points, lend a die or buy a die for someone.",
	"Each Sin has two abilities. Tap a Sin's name to read them.",
	"You can use each ability once on your turn.",
	"Talk and make deals. Promises are not binding.",
	"Then pass the phone.",
]

const SEAT_CHOICES := [2, 3, 4]   # the table sizes the How to play card offers
const NEAR_GAP := 150             # a player this close to the goal (850 of 1000; Ben, 2026-11-26) is shown brighter
## The abilities that change what a roll scores, as the short name shown beside the score: "scored 210 (Glance +60)".
const SHARE_NAMES := {"glance": "Glance", "hubris": "Hubris", "whisper": "Whisper", "drip": "Slow Drip"}

var seats := 4               # players in the next match: chosen on the How to play card before the first turn
var fresh := true            # no turn has begun: the number of players can still be changed
var s                        # the match (game/state.gd)
var rng = null               # set before the screen enters the tree to script the dice; else random
var sins: Array = []         # set to fix the Sins; else dealt at random
var view := "handover"       # handover (pass the phone), turn (roll, swap, Gambit, turn over, winner), gift, agree, ability
var note := ""               # what the roll did, shown in the turn view
var event := ""              # who did what to whom, in one line; stays until the next action
var offer := {}              # the gift being set up: kind, give (the turn player gives), other (seat or -1), amount
var act := {}                # the ability being set up: key, by (seat), args (the choices so far), back (the view to return to)
var btn := {}                # the buttons on screen now, by key (the test taps these)
var log = MatchLog.new()     # every move of this match
var shares: Array = []       # a seat: [what an ability added to their last roll ("Glance +60", or ""), points of it that last_score leaves out (Slow Drip)]
var roll_before := 0         # the turn player's points before their roll
var copied := ""             # the text Copy log last put on the clipboard

var serif: FontVariation
var header: Label
var panels: Array = []       # one Dictionary of nodes a seat
var panel_box: VBoxContainer # the seats' boxes: rebuilt for each match's number of players
var count_row: HBoxContainer # on the How to play card: how many players
var event_box: PanelContainer
var event_label: Label
var title: Label
var text: Label
var buttons: VBoxContainer
var howto: Control           # the How to play card, over everything
var help_btn: Button
var got_btn: Button
var sin_card: Control        # a Sin's two abilities, over everything
var sin_title: Label
var sin_text: Label
var close_btn: Button
var log_btn: Button
var log_card: Control        # the match log, over everything
var log_list: VBoxContainer
var copy_btn: Button
var log_close_btn: Button


func _init() -> void:
	serif = FontVariation.new()
	serif.base_font = FELL_FILE
	serif.fallbacks = [DIGITS_TEXT]


func _ready() -> void:
	_build()
	new_match()


func new_match() -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	# Fixed Sins (tests, screenshots) are used seat by seat; with too few for the table they are dealt at random.
	s = Rules.new_match(Config.merged({"seats": seats}), rng, sins.slice(0, seats) if sins.size() >= seats else [])
	fresh = true
	for c in panel_box.get_children():
		panel_box.remove_child(c)
		c.queue_free()
	panels = []
	log = MatchLog.new()
	shares = []
	copied = ""
	for i in seats:
		panel_box.add_child(_panel(i))
		shares.append(["", 0])
	view = "handover"
	note = ""
	event = ""
	act = {}
	howto.visible = true
	sin_card.visible = false
	log_card.visible = false
	_refresh()


# ---- the match log

## A move by a seat, with what it did to that seat's points since before.
func _log(seat: int, words: String, before: int) -> void:
	log.add(s.round_number, who(seat), words, s.seats[seat].points - before, s.seats[seat].points)


## An ability changed what this roll scored: count it, show it beside the score, and return the words for the log.
func _share(seat: int, key: String, points: int, unscored := 0) -> String:
	var words := "%s %s" % [SHARE_NAMES[key], MatchLog.signed(points)]
	shares[seat] = [words, unscored]
	log.count(seat, Sins.ability_name(key), points)
	return ", " + words


## The settled roll of the player whose turn it is. whisper: what Lust's swap added to it (null: no swap).
func _log_roll(r: Dictionary, whisper = null) -> void:
	var seat: int = s.turn
	var cfg: Dictionary = s.cfg
	var words := "rolled %s, scored %d" % [faces_text(r.faces), r.scored]
	var low := Rules.lows(cfg, r.faces)
	if whisper != null:
		words += _share(seat, "whisper", whisper)
	if r.get("glance", 0) > 0:
		words += _share(seat, "glance", 0 if r.purgatory else Rules.face_score(cfg, r.glance))
	if r.get("hubris", "") == "won":
		words += _share(seat, "hubris", r.scored - Rules.score(cfg, r.faces))
	elif r.get("hubris", "") == "lost":
		words += _share(seat, "hubris", -Rules.score(cfg, r.faces))
	if r.get("drip", false):
		words += _share(seat, "drip", int(cfg.drip_gain), int(cfg.drip_gain))
	if r.get("aura", false):
		words += ", Lethargic Aura (one die rolled twice, the lower kept)"
	if r.escaped:
		words += ", out of Purgatory"
	elif r.purgatory and low < r.faces.size():
		words += ", stays in Purgatory"
	elif r.purgatory:
		words += ", into Purgatory"
	_log(seat, words, roll_before)
	if r.won:
		log.add(s.round_number, who(seat), "wins with %d points" % s.seats[seat].points, 0, s.seats[seat].points)


func _on_log() -> void:
	log_card.visible = true
	copy_btn.text = "Copy log"
	_refresh()


func _on_close_log() -> void:
	log_card.visible = false
	_refresh()


## The whole match as plain text, to the clipboard.
func _on_copy_log() -> void:
	var names := []
	var points := []
	for i in s.seats.size():
		names.append(who(i))
		points.append(s.seats[i].points)
	copied = log.copy_text(names, points)
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set(copied)
		copy_btn.text = "Copied"
	else:
		copy_btn.text = "No clipboard here"


## Has the player used this ability for this turn? (Spark of Rage: for this round.)
func spent(p, key: String) -> bool:
	return p.used.has(key) or (key == "spark" and p.spark_used)


# ---- names and sentences

func seat_name(i: int) -> String:
	return "Player %d" % (i + 1)


func sin_name(i: int) -> String:
	return str(s.seats[i].sin).capitalize()


## "Player 1 (Wrath)".
func who(i: int) -> String:
	if s.seats[i].sin == "":
		return seat_name(i)
	return "%s (%s)" % [seat_name(i), sin_name(i)]


func dice_text(n: int) -> String:
	return "1 die" if n == 1 else "%d dice" % n


func rounds_text(n: int) -> String:
	return "1 full round" if n == 1 else "%d full rounds" % n


## What a gift does, as one sentence.
func gift_line(kind: String, from: int, to: int, amount: int) -> String:
	if kind == Rules.POINTS:
		return "%s gives %d points to %s." % [seat_name(from), amount, seat_name(to)]
	if kind == Rules.LEND:
		return "%s lends a die to %s for one roll." % [seat_name(from), seat_name(to)]
	return "%s pays %d and buys a die for %s." % [seat_name(from), int(s.cfg.die_cost), seat_name(to)]


func offer_from() -> int:
	return s.turn if offer.give else offer.other


func offer_to() -> int:
	return offer.other if offer.give else s.turn


## Why the offer cannot be made yet, or "".
func offer_block() -> String:
	if offer.other < 0:
		return "Choose a player."
	return Rules.gift_block(s, offer.kind, offer_from(), offer_to(), offer.amount)


func faces_text(faces: Array) -> String:
	return ", ".join(faces.map(func(f): return str(f)))


## What the roll did, in words.
func roll_note(r: Dictionary) -> String:
	var faces := faces_text(r.faces)
	var low := Rules.lows(s.cfg, r.faces)
	var out := ""
	if r.escaped:
		out = "You rolled %s. %s showing 1, 2 or 3: you are out of Purgatory, and the roll scores %d." % [faces, dice_text(low).capitalize(), r.scored]
	elif r.purgatory and low < r.faces.size():
		out = "You rolled %s. Only %s showing 1, 2 or 3: you need two or more. You stay in Purgatory and score nothing." % [faces, dice_text(low)]
	elif r.purgatory and s.seats[s.turn].points >= int(s.cfg.win):
		out = "You rolled %s. Every die shows 1, 2 or 3: Purgatory. You score 0 and your turn ends. You cannot win while in Purgatory." % faces
	elif r.purgatory:
		out = "You rolled %s. Every die shows 1, 2 or 3: Purgatory. You score 0 and your turn ends. No buying, trading or abilities until you are out." % faces
	else:
		out = "You rolled %s and scored %d." % [faces, r.scored]
	if r.get("glance", 0) > 0:
		out += " Green-Eyed Glance: the last die is the copied %d, not rolled." % r.glance
	if r.get("aura", false):
		out += " Lethargic Aura: your first die was rolled twice and the lower kept."
	if r.get("hubris", "") == "won":
		out += " Hubris: it beat %d, so the score includes %d more." % [r.beat, int(s.cfg.hubris_win_add)]
	elif r.get("hubris", "") == "lost":
		out += " Hubris: it did not beat %d, so the roll scores 0." % r.beat
	if r.get("drip", false):
		out += " Slow Drip: under %d, so %d more." % [int(s.cfg.drip_under), int(s.cfg.drip_gain)]
	return out


## Who did what to whom, from what Rules.use returned. key: the ability (a copy passes the copied one).
func event_line(r: Dictionary, key := "") -> String:
	if key == "":
		key = r.key
	var me := who(r.by)
	var ab := Sins.ability_name(key)
	var t: String = seat_name(r.target) if r.has("target") else ""
	var out := ""
	match key:
		"spark":
			out = "%s used %s on %s: a %d was rerolled and came up %d." % [me, ab, t, r.was, r.face]
			var change: int = r.change - r.lost
			if change < 0:
				out += " %s lost %d." % [t, -change]
			elif change > 0:
				out += " %s gained %d." % [t, change]
		"strike":
			if r.choice == "die":
				out = "%s used %s on %s, who chose to give a die for %s." % [me, ab, t, rounds_text(int(s.cfg.strike_rounds))]
			else:
				out = "%s used %s on %s, who chose to lose points: %d lost." % [me, ab, t, r.paid]
		"deal":
			if r.choice == "die":
				out = "%s used %s on %s, who chose to give a die for %s." % [me, ab, t, rounds_text(int(s.cfg.deal_rounds))]
			else:
				out = "%s used %s on %s, who chose to pay %d." % [me, ab, t, r.paid]
		"whisper":
			out = "%s used %s on %s: swapped a %d for their %d." % [me, ab, t, r.gave, r.got]
		"allure":
			var two: bool = r.a == r.by or r.b == r.by   # two players: Lust is one of the two
			if two:
				var them: int = r.b if r.a == r.by else r.a
				out = "%s used %s on %s: %s picked a %d and %s a %d." % [me, ab, seat_name(them), seat_name(r.a), r.face_a, seat_name(r.b), r.face_b]
			else:
				out = "%s used %s on %s and %s: they picked a %d and a %d." % [me, ab, seat_name(r.a), seat_name(r.b), r.face_a, r.face_b]
			if not r.match:
				out += " No match: the two dice swapped."
			elif r.take >= 0:
				out += " A match: %s took that die from %s, to keep." % [seat_name(r.by), seat_name(r.take)]
			elif two:
				out += " A match, but no one can go below %d dice: no die taken." % int(s.cfg.min_dice)
			else:
				out += " A match, but neither can go below %d dice: no die taken." % int(s.cfg.min_dice)
		"glance":
			out = "%s used %s: one die of the next roll is not rolled and shows %d, copied from %s." % [me, ab, r.face, t]
		"grasp":
			out = "%s paid for %s. %s" % [me, ab, event_line(r, r.copied)]
		"hubris":
			out = "%s declared %s: beat %d and the roll scores %d more; fail and it is 0." % [me, ab, r.beat, int(s.cfg.hubris_win_add)]
		"superiority":
			out = "%s armed %s: the first player to target them before their next turn loses %d." % [me, ab, int(s.cfg.superiority_loss)]
		"feast":
			out = "%s used %s: a %d went to the supply for %d points." % [me, ab, r.face, r.gain]
		"bite":
			out = "%s used %s on %s: stole %d." % [me, ab, t, r.stolen]
		"aura":
			out = "%s used %s on %s: on their next roll one die is rolled twice and the lower kept." % [me, ab, t]
		"drip":
			out = "%s copied %s: %d more." % [me, ab, r.gain]
	for p in r.get("superiority", []):
		out += " Superiority: %s lost %d for targeting %s." % [seat_name(r.by), int(s.cfg.superiority_loss), seat_name(p)]
	return out


## The seat that is Wrath, or -1.
func wrath_seat() -> int:
	for i in s.seats.size():
		if s.seats[i].sin == "wrath":
			return i
	return -1


## The ability whose choices are being asked for: the copied one under Jealous Grasp.
func act_key() -> String:
	return str(act.args.get("key", "grasp")) if act.key == "grasp" else str(act.key)


## The choices so far, as Rules.block and Rules.use take them.
func act_args(more := {}) -> Dictionary:
	var a: Dictionary = act.args.duplicate()
	a.merge(more, true)
	if act.by != s.turn:
		a["by"] = act.by
	return a


# ---- taps

func _on_ready() -> void:
	view = "turn"
	fresh = false
	_refresh()


## The number of players, chosen on the How to play card before the first turn: a new match at that table size.
func _on_seats(n: int) -> void:
	if not fresh or not SEAT_CHOICES.has(n):
		return
	seats = n
	new_match()


## The one other player at a two-player table; -1 at a bigger one.
func only_other(seat: int) -> int:
	return 1 - seat if s.seats.size() == 2 else -1


func _on_help() -> void:
	howto.visible = true
	_refresh()


func _on_got_it() -> void:
	howto.visible = false
	_refresh()


func _on_sin(i: int) -> void:
	var sn: String = s.seats[i].sin
	if not Sins.INFO.has(sn):
		return
	var t1: Dictionary = Sins.INFO[sn].t1
	var t2: Dictionary = Sins.INFO[sn].t2
	sin_title.text = "%s: %s" % [seat_name(i), sin_name(i)]
	sin_text.text = "Tier 1, free: %s\n%s\n\nTier 2, costs %d: %s\n%s\n\nTier 2 opens when you reach %d points and stays open. Each ability at most once on your turn. No abilities in Purgatory." % [
		t1.name, Sins.text(t1.key, s.seats.size()), Sins.cost(s.cfg, t2.key), t2.name, Sins.text(t2.key, s.seats.size()), int(s.cfg.tier2_at)]
	sin_card.visible = true
	_refresh()


func _on_close() -> void:
	sin_card.visible = false
	_refresh()


func _on_roll() -> void:
	roll_before = s.seats[s.turn].points
	var r: Dictionary = Rules.roll(s)
	if r.is_empty():
		return
	event = ""
	shares[s.turn] = ["", 0]
	if r.get("pending", false):
		note = "You rolled %s." % faces_text(r.faces)
	else:
		note = roll_note(r)
		_log_roll(r)
	_refresh()


## Lust scores the roll without swapping.
func _on_settle() -> void:
	if s.phase != Rules.SWAP:
		return
	var r: Dictionary = Rules.settle(s)
	note = roll_note(r)
	_log_roll(r)
	_refresh()


func _on_buy() -> void:
	var before: int = s.seats[s.turn].points
	if Rules.buy(s, 1):
		note = "You bought a die for %d. You roll it from your next turn." % int(s.cfg.die_cost)
		event = ""
		_log(s.turn, "bought a die for %d" % int(s.cfg.die_cost), before)
		var g := Rules.vig_seat(s, s.turn)
		if g >= 0:
			event = "The Vig: %s gained %d from the die %s bought." % [who(g), int(s.cfg.vig), seat_name(s.turn)]
			_log_vig(g, s.turn)
	_refresh()


## The Vig paid Greed for a die this seat bought.
func _log_vig(greed: int, buyer: int) -> void:
	var gain := int(s.cfg.vig)
	_log(greed, "The Vig: gained %d from the die %s bought" % [gain, seat_name(buyer)], s.seats[greed].points - gain)
	log.count(greed, Sins.ability_name("vig"), gain)


func _on_pass() -> void:
	if Rules.pass_turn(s):
		view = "handover"
		note = ""
		event = ""
	_refresh()


func _on_gift(kind: String) -> void:
	offer = {"kind": kind, "give": true, "other": only_other(s.turn), "amount": 10}
	view = "gift"
	_refresh()


func _on_give(give: bool) -> void:
	offer.give = give
	_refresh()


func _on_other(i: int) -> void:
	offer.other = i
	_refresh()


func _on_amount(delta: int) -> void:
	offer.amount = maxi(10, offer.amount + delta)
	_refresh()


func _on_all() -> void:
	if offer.other >= 0 or offer.give:
		offer.amount = maxi(10, s.seats[offer_from()].points)
	_refresh()


func _on_back() -> void:
	view = str(act.get("back", "turn")) if view == "ability" else "turn"
	act = {}
	_refresh()


func _on_offer() -> void:
	if offer_block() == "":
		view = "agree"
	_refresh()


func _on_agree(yes: bool) -> void:
	var line := gift_line(offer.kind, offer_from(), offer_to(), offer.amount)
	var before: int = s.seats[offer_from()].points
	event = ""
	if yes and Rules.gift(s, offer.kind, offer_from(), offer_to(), offer.amount):
		note = "%s agreed. %s" % [seat_name(offer.other), line]
		_log(offer_from(), "gift, %s agreed: %s" % [seat_name(offer.other), line], before)
		var g := Rules.vig_seat(s, offer_from())
		if offer.kind == Rules.DIE and g >= 0:
			event = "The Vig: %s gained %d from the die %s bought." % [who(g), int(s.cfg.vig), seat_name(offer_from())]
			_log_vig(g, offer_from())
	else:
		note = "%s refused. Nothing changed." % seat_name(offer.other)
		_log(offer_from(), "gift, %s refused: %s" % [seat_name(offer.other), line], before)
	note += " Pass the phone back to %s." % seat_name(s.turn)
	view = "turn"
	_refresh()


## Start an ability: by is the seat using it (the turn player, or Wrath out of turn); preset: choices already made.
func _on_ability(key: String, by: int, preset := {}) -> void:
	act = {"key": key, "by": by, "args": preset.duplicate(), "back": view, "pair": [], "ready": false, "away": false}
	if key == "allure" and only_other(by) >= 0:
		# Two players: Lust is one of the two, and picks first with the phone already in hand.
		act.args["a"] = by
		act.args["b"] = only_other(by)
		act.ready = true
		act.away = true
	view = "ability"
	_step()


func _on_grasp_key(key: String) -> void:
	act.args["key"] = key
	_step()


func _on_target(i: int) -> void:
	if act_key() == "allure":
		if act.pair.has(i):
			act.pair.erase(i)
		elif act.pair.size() < 2:
			act.pair.append(i)
		_refresh()
		return
	act.args["target"] = i
	if ["strike", "deal"].has(act_key()):
		act.away = true   # the phone goes to the target for their choice
	_step()


func _on_pair() -> void:
	if act.pair.size() == 2:
		act.args["a"] = act.pair[0]
		act.args["b"] = act.pair[1]
		act.away = true
	_step()


func _on_choice(c: String) -> void:
	act.args["choice"] = c
	_step()


func _on_secret_ready() -> void:
	act.ready = true
	_refresh()


func _on_take(i: int) -> void:
	act.args["take"] = i
	_step()


func _on_die(seat: int, index: int) -> void:
	var a: Dictionary = act.args
	match act_key():
		"spark", "glance":
			a["target"] = seat
			a["index"] = index
		"feast":
			a["index"] = index
		"whisper":
			if not a.has("mine"):
				a["mine"] = index
			else:
				a["target"] = seat
				a["theirs"] = index
		"allure":
			a["pick_b" if a.has("pick_a") else "pick_a"] = index
			act.ready = false
	_step()


## Entangling Allure, both dice picked and matching: the seats Lust may take from.
func allure_takes() -> Array:
	var a: Dictionary = act.args
	var out := []
	if s.seats[a.a].last_roll[a.pick_a] == s.seats[a.b].last_roll[a.pick_b]:
		for i in [a.a, a.b]:
			if i != act.by and Rules.spare(s, i):
				out.append(i)
	return out


## Are all the choices made?
func act_complete() -> bool:
	var a: Dictionary = act.args
	var needs: Array = Rules.NEEDS[act.key].duplicate()
	if act.key == "grasp" and a.has("key"):
		needs += Rules.NEEDS[a.key]
	for k in needs:
		if not a.has(k):
			return false
	if act_key() == "allure" and not a.has("take"):
		var takes := allure_takes()
		if takes.size() == 2:
			return false
		if takes.size() == 1:
			a["take"] = takes[0]
	return true


## After each choice: ask the next one, or use the ability.
func _step() -> void:
	if not act_complete():
		_refresh()
		return
	var away: bool = act.away
	var whisper: bool = act.key == "whisper"
	var by: int = act.by
	var args := act_args()
	var pts := []
	for q in s.seats:
		pts.append(q.points)
	var r: Dictionary = Rules.use(s, act.key, args)
	if r.is_empty():
		var why: String = Rules.block(s, act.key, args)
		event = "Nothing happened: %s" % why
		_log(by, "tried %s: refused. %s" % [Sins.ability_name(act.key), why], pts[by])
	else:
		event = event_line(r)
		var words := event.trim_prefix(who(by) + " ")
		if whisper:
			# Lust's swap, then the roll it settled: what the swap added is the score less the unswapped roll's.
			note = roll_note(r)
			log.add(s.round_number, who(by), words, 0, pts[by])
			var plain: Array = r.faces.duplicate()
			plain[args.mine] = r.gave
			_log_roll(r, r.scored - (0 if Rules.lows(s.cfg, plain) == plain.size() else Rules.score(s.cfg, plain)))
		else:
			_log(by, words, pts[by])
			# Spark of Rage rerolled a die of the target's roll: the score shown is no longer the one the share was part of.
			if r.get("copied", act.key) == "spark":
				shares[r.target] = ["", 0]
			# Hubris and Green-Eyed Glance are counted when the roll they change is scored.
			if not ["hubris", "glance"].has(act.key):
				var others := 0
				for i in s.seats.size():
					if i != by:
						others += s.seats[i].points - pts[i]
				log.count(by, Sins.ability_name(act.key), s.seats[by].points - pts[by], others)
	if away:
		event += " Pass the phone back to %s." % seat_name(s.turn)
	view = str(act.back)
	act = {}
	_refresh()


# ---- drawing

func _refresh() -> void:
	header.text = "Round %d   ·   First to %d wins   ·   Supply: %s" % [s.round_number, int(s.cfg.win), dice_text(s.supply)]
	for c in buttons.get_children():
		buttons.remove_child(c)
		c.queue_free()
	btn = {}
	for i in s.seats.size():
		_refresh_panel(i)
	event_label.text = event
	event_box.visible = event != ""
	if view == "handover":
		_view_handover()
	elif view == "gift":
		_view_gift()
	elif view == "agree":
		_view_agree()
	elif view == "ability":
		_view_ability()
	elif s.phase == Rules.FATE:
		_view_fate()
	elif s.phase == Rules.SWAP:
		_view_swap()
	elif s.phase == Rules.GAMBIT:
		_view_gambit()
	elif s.phase == Rules.END:
		_view_end()
	else:
		_view_over()
	# A card covers the table: while it is up, its buttons are the only ones.
	for c in count_row.get_children():
		count_row.remove_child(c)
		c.queue_free()
	count_row.visible = fresh
	if howto.visible:
		btn = {"got_it": got_btn}
		if fresh:
			# before the first turn: how many players (the chosen number is the bright one)
			var l := _label("Players", SIZE_NAME, GOLD)
			l.custom_minimum_size = Vector2(220, 0)
			count_row.add_child(l)
			for n in SEAT_CHOICES:
				var b := _button("seats%d" % n, str(n), _on_seats.bind(n), false, false, n == seats)
				b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				count_row.add_child(b)
	elif sin_card.visible:
		btn = {"close": close_btn}
	elif log_card.visible:
		btn = {"copy_log": copy_btn, "close_log": log_close_btn}
		for c in log_list.get_children():
			log_list.remove_child(c)
			c.queue_free()
		# newest first
		for i in range(log.entries.size() - 1, -1, -1):
			var row := _label(MatchLog.line(log.entries[i]), 30, TEXT)
			row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			log_list.add_child(row)
		if log.entries.is_empty():
			log_list.add_child(_label("Nothing has happened yet.", SIZE_SMALL, DIM))
	else:
		btn["help"] = help_btn
		btn["log"] = log_btn


func _refresh_panel(i: int) -> void:
	var p = s.seats[i]
	var n: Dictionary = panels[i]
	var turn: bool = i == s.turn
	var sb: StyleBoxFlat = n.box
	# Close to the goal: a warm box, a thicker border and gold points, whoever's turn it is.
	var near: bool = p.points >= int(s.cfg.win) - NEAR_GAP
	sb.bg_color = PANEL_NEAR if near else (PANEL_TURN if turn else PANEL)
	sb.set_border_width_all(10 if turn else (6 if near else 2))
	n.points.add_theme_color_override("font_color", GOLD if near else TEXT)
	var best := 0
	for q in s.seats:
		best = maxi(best, q.points)
	n.sin.text = sin_name(i) if p.sin != "" else "no Sin"
	n.sin.disabled = not Sins.INFO.has(p.sin)
	btn["sin%d" % i] = n.sin
	n.points.text = str(p.points)
	var tags := []
	if s.winner == i:
		tags.append("WINNER")
	elif turn:
		tags.append("TURN")
	if s.winner < 0 and best > 0 and p.points == best:
		tags.append("LEADING")
	if p.purgatory:
		tags.append("IN PURGATORY")
	# On your turn: an ability already used is marked, so the row says what is left.
	var info: Dictionary = Sins.INFO.get(p.sin, {})
	if turn and not info.is_empty() and spent(p, info.t1.key):
		tags.append("TIER 1 USED")
	if p.tier2 and p.sin != "":
		tags.append("TIER 2 USED" if turn and spent(p, info.t2.key) else "TIER 2")
	if p.armed:
		tags.append("ARMED")
	if p.lethargic:
		tags.append("LETHARGIC")
	n.tag.text = "  ".join(tags)
	n.tag.add_theme_color_override("font_color", BAD if p.purgatory else GOLD)
	n.dice.text = dice_text(p.dice) + (" + %d lent" % p.lent if p.lent > 0 else "") + (" (%d taken)" % p.held if p.held > 0 else "")
	n.dice.add_theme_font_size_override("font_size", 30 if (p.lent > 0 or p.held > 0) else SIZE_TEXT)
	for c in n.roll.get_children():
		n.roll.remove_child(c)
		c.queue_free()
	if p.last_roll.is_empty():
		n.roll.add_child(_label("no roll yet", SIZE_SMALL, DIM))
		n.scored.text = ""
	else:
		for f in p.last_roll:
			n.roll.add_child(_die(f))
		# with what an ability added to it: "scored 210 (Glance +60)"
		n.scored.text = "scored %d" % (p.last_score + int(shares[i][1])) + ("\n(%s)" % shares[i][0] if shares[i][0] != "" else "")
		# two lines at the smaller size are no taller than the dice, so the row keeps its height
		n.scored.add_theme_font_size_override("font_size", 24 if shares[i][0] != "" else 30)
	# Wrath's Spark of Rage: a button on every other player's roll, while Wrath can use it on them.
	var w := wrath_seat()
	var can: bool = w >= 0 and w != i and (view == "turn" or view == "handover") and Rules.block(s, "spark", {"by": w, "target": i}) == ""
	n.spark.visible = can
	if can:
		btn["spark%d" % i] = n.spark


func _view_handover() -> void:
	var p = s.seats[s.turn]
	title.text = "Pass the phone to %s" % seat_name(s.turn)
	text.text = ""
	if p.sin != "":
		text.text = "%s plays %s." % [seat_name(s.turn), sin_name(s.turn)]
	if p.purgatory:
		text.text += " They are in Purgatory."
	_add(_button("ready", "I am %s" % seat_name(s.turn), _on_ready, true))


func _view_fate() -> void:
	var p = s.seats[s.turn]
	title.text = "%s: roll" % seat_name(s.turn)
	if p.purgatory:
		text.text = "You are in Purgatory. Roll all your dice: two or more showing 1, 2 or 3 free you, and then the roll's 4s, 5s and 6s score. Fewer, and your turn ends with nothing scored."
	else:
		# A Green-Eyed Glance copy is waiting: one die is not rolled, as the roll button below says.
		var first := "Roll all your dice once."
		if p.glance > 0:
			first = "Roll %s once. The last die is not rolled: it shows the copied %d." % [dice_text(p.dice + p.lent - 1), p.glance]
		text.text = first + " A 4, 5 or 6 scores 40, 50 or 60. A 1, 2 or 3 scores nothing. If every die shows 1, 2 or 3 you go to Purgatory: you score 0 and your turn ends."
	if p.lent > 0:
		text.text += " %s lent to you for this roll, then to the supply." % ("1 die is" if p.lent == 1 else "%d dice are" % p.lent)
	if p.lethargic:
		text.text += " Lethargic Aura: one die is rolled twice and the lower kept."
	# The abilities used before the roll.
	if p.sin == "pride":
		_add(_ability_button("hubris", "Declare Hubris: beat %d to score %d more, or score 0" % [Rules.hubris_target(s), int(s.cfg.hubris_win_add)]))
	elif p.sin == "envy":
		_add(_ability_button("glance", "Green-Eyed Glance: copy a die in place of one of yours"))
	var n: int = p.dice + p.lent - (1 if p.glance > 0 else 0)
	_add(_button("roll", "Roll %s" % dice_text(n) + (", plus the copied %d" % p.glance if p.glance > 0 else ""), _on_roll, true))


## The Whisper of Desire card without its "Before scoring, " opening, for the swap view.
func _whisper_words() -> String:
	var t: String = Sins.text("whisper", s.seats.size()).trim_prefix("Before scoring, ")
	return t.substr(0, 1).to_upper() + t.substr(1)


## Lust has rolled: swap a die before scoring, or score it as it is.
func _view_swap() -> void:
	title.text = "%s: swap before scoring?" % seat_name(s.turn)
	text.text = "%s\nWhisper of Desire: %s Then the roll is scored." % [note, _whisper_words()]
	_add(_ability_button("whisper", "Whisper of Desire: swap a die"))
	_add(_button("settle", "Score the roll as it is", _on_settle, true))


func _view_gambit() -> void:
	var p = s.seats[s.turn]
	title.text = "%s: buy, trade, then pass" % seat_name(s.turn)
	text.text = note
	var can := Rules.max_buy(s) > 0
	var buy_text := "Buy a die: %d points" % int(s.cfg.die_cost)
	if s.supply < 1:
		buy_text = "Buy a die: the supply is empty"
	elif p.bought >= int(s.cfg.buys_a_turn):
		buy_text = "Buy a die: only one die a turn"
	elif not can:
		buy_text = "Buy a die: you need %d points" % int(s.cfg.die_cost)
	_add(_button("buy", buy_text, _on_buy, false, not can))
	var gifts := [_button("points", "Give\npoints", _on_gift.bind(Rules.POINTS)), _button("lend", "Lend\na die", _on_gift.bind(Rules.LEND)),
		_button("die", "Buy a die\nfor a player", _on_gift.bind(Rules.DIE))]
	for g in gifts:
		g.add_theme_font_size_override("font_size", SIZE_SMALL)
	_add(_row(gifts))
	if Sins.INFO.has(p.sin):
		var t1: Dictionary = Sins.INFO[p.sin].t1
		var t2: Dictionary = Sins.INFO[p.sin].t2
		_add(_row([_ability_button(t1.key, t1.name), _ability_button(t2.key, "%s (%d)" % [t2.name, Sins.cost(s.cfg, t2.key)])]))
	_add(_button("pass", "Pass: end my turn", _on_pass, true))


func _view_end() -> void:
	title.text = "%s: your turn is over" % seat_name(s.turn)
	text.text = note
	_add(_button("pass", "Pass the phone", _on_pass, true))


func _view_over() -> void:
	title.text = "%s wins!" % seat_name(s.winner)
	text.text = "%s\n%s ended a Fate Phase on %d points, out of Purgatory. First to %d wins." % [note, seat_name(s.winner), s.seats[s.winner].points, int(s.cfg.win)]
	_add(_row([_button("log_win", "Match log", _on_log), _button("new", "New match", new_match, true)]))


func _view_gift() -> void:
	var kind: String = offer.kind
	title.text = "%s: %s" % [seat_name(s.turn), GIFT_TITLES[kind].to_lower()]
	_add(_row([_button("give", "I give", _on_give.bind(true), false, false, offer.give),
		_button("ask", "I ask for it", _on_give.bind(false), false, false, not offer.give)]))
	var others := []
	for i in s.seats.size():
		if i == s.turn:
			continue
		var out: bool = s.seats[i].purgatory
		others.append(_button("other%d" % i, seat_name(i) + ("\nin Purgatory" if out else ""), _on_other.bind(i), false, out, offer.other == i))
	_add(_row(others))
	if kind == Rules.POINTS:
		if offer.other >= 0 or offer.give:
			offer.amount = clampi(offer.amount, 10, maxi(10, s.seats[offer_from()].points))
		var amount := _label("%d points" % offer.amount, SIZE_NAME, TEXT)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amount.custom_minimum_size = Vector2(250, 0)
		_add(_row([_button("m100", "- 100", _on_amount.bind(-100)), _button("m10", "- 10", _on_amount.bind(-10)), amount,
			_button("p10", "+ 10", _on_amount.bind(10)), _button("p100", "+ 100", _on_amount.bind(100)), _button("all", "All", _on_all)]))
	var block := offer_block()
	text.text = GIFT_RULES[kind] + "\n" + (block if block != "" else gift_line(kind, offer_from(), offer_to(), offer.amount))
	_add(_row([_button("back", "Back", _on_back), _button("offer", "Offer" if offer.give else "Ask", _on_offer, true, block != "")]))


func _view_agree() -> void:
	title.text = "Pass the phone to %s" % seat_name(offer.other)
	var line := gift_line(offer.kind, offer_from(), offer_to(), offer.amount)
	text.text = "%s %s: %s\n%s, do you agree? Once you agree it is permanent." % [seat_name(s.turn), "offers" if offer.give else "asks", line, seat_name(offer.other)]
	_add(_row([_button("refuse", "Refuse", _on_agree.bind(false)), _button("agree", "Agree", _on_agree.bind(true), true)]))


## The next choice an ability needs: what to copy, a player, the target's own choice, a die, or a secret die.
func _view_ability() -> void:
	var a: Dictionary = act.args
	var k := act_key()
	var by: int = act.by
	var card: Dictionary = Sins.card(k)
	title.text = "%s: %s" % [who(by), Sins.ability_name(act.key)]
	if act.key == "grasp" and a.has("key"):
		title.text += ", copying %s" % card.name
	text.text = Sins.text(k, s.seats.size())
	var two: bool = only_other(by) >= 0
	var others := []
	for i in s.seats.size():
		if i != by:
			others.append(i)
	if act.key == "grasp" and not a.has("key"):
		# what to copy: every Tier 1 used this round, the ones that cannot be copied switched off with the reason
		var seen: Array = Rules.grasp_seen(s)
		text.text += "\nUsed this round: %s." % (", ".join(seen.map(func(x): return Sins.ability_name(x))) if not seen.is_empty() else "nothing")
		for x in seen:
			var why := Rules.block(s, "grasp", {"key": x})
			var b := _button("copy_" + x, Sins.ability_name(x) + ("\n" + why if why != "" else ""), _on_grasp_key.bind(x), false, why != "")
			b.add_theme_font_size_override("font_size", SIZE_SMALL)
			_add(b)
		_add(_button("back", "Back", _on_back))
	elif ["strike", "deal", "bite", "aura"].has(k) and not a.has("target"):
		text.text += "\nChoose a player."
		_add(_row(others.map(func(i): return _target_button(i, Rules.block(s, act.key, act_args({"target": i})), false))))
		_add(_button("back", "Back", _on_back))
	elif ["strike", "deal"].has(k):
		# the target chooses
		var t: int = a.target
		title.text = "Pass the phone to %s" % seat_name(t)
		var cost: int = int(s.cfg.strike_loss) if k == "strike" else int(s.cfg.deal_pay)
		var rounds := rounds_text(int(s.cfg[k + "_rounds"]))
		text.text = "%s uses %s on you. %s, choose: %s, or give them 1 of your dice for %s." % [who(by), card.name, seat_name(t),
			("lose %d points" % cost) if k == "strike" else ("pay them %d points" % cost), rounds]
		var no_points := Rules.block(s, act.key, act_args({"choice": "points"}))
		var no_die := Rules.block(s, act.key, act_args({"choice": "die"}))
		var b1 := _button("choose_points", ("Lose %d points" % cost if k == "strike" else "Pay %d points" % cost) + ("\n" + no_points if no_points != "" else ""),
			_on_choice.bind("points"), false, no_points != "")
		var b2 := _button("choose_die", "Give a die for %s" % rounds + ("\n" + no_die if no_die != "" else ""), _on_choice.bind("die"), false, no_die != "")
		for b in [b1, b2]:
			b.add_theme_font_size_override("font_size", 30)
		_add(_row([b1, b2]))
	elif k == "allure" and not a.has("a"):
		text.text += "\nChoose 2 players. The phone is passed to each to pick a die of their last roll in secret."
		_add(_row(others.map(func(i): return _target_button(i, Rules.block(s, "allure", {"a": i}), act.pair.has(i)))))
		var why := "Choose 2 players." if act.pair.size() < 2 else Rules.block(s, "allure", {"a": act.pair[0], "b": act.pair[1]})
		_add(_row([_button("back", "Back", _on_back), _button("use", "Use on these two", _on_pair, true, why != "")]))
	elif k == "allure" and not (a.has("pick_a") and a.has("pick_b")):
		# each chosen player in turn, in secret
		var t: int = a.b if a.has("pick_a") else a.a
		if not act.ready:
			title.text = "Pass the phone to %s" % seat_name(t)
			if two:
				text.text = "%s uses Entangling Allure and has picked one of their own dice in secret. %s: keep the screen to yourself; you will pick one die of your last roll in secret." % [
					who(by), seat_name(t)]
			else:
				text.text = "%s uses Entangling Allure on %s and %s. %s: keep the screen to yourself; you will pick one die of your last roll in secret." % [
					who(by), seat_name(a.a), seat_name(a.b), seat_name(t)]
			_add(_button("ready", "I am %s" % seat_name(t), _on_secret_ready, true))
		else:
			title.text = "%s: pick one die in secret" % seat_name(t)
			if two and t == by:
				text.text = "Keep the screen to yourself. Tap one die of your last roll; then %s picks one of theirs. If the two dice show the same number, you take theirs to keep. If not, the two dice swap." % seat_name(a.b)
			elif two:
				text.text = "If your die and the one %s picked show the same number, %s takes yours to keep. If not, the two dice swap. Tap a die, then pass the phone back." % [seat_name(by), seat_name(by)]
			else:
				text.text = "If the two picked dice show the same number, %s takes one of them to keep. If not, the two dice swap. Tap a die, then pass the phone on." % seat_name(by)
			_add(_dice_row(t, func(_f): return true))
			if two and t == by:
				_add(_button("back", "Back", _on_back))
	elif k == "allure":
		# a match, and both can spare the die: Lust chooses
		title.text = "Pass the phone back to %s" % seat_name(by)
		text.text = "%s and %s both picked a %d: a match. %s, take one of the two dice, to keep." % [seat_name(a.a), seat_name(a.b), s.seats[a.a].last_roll[a.pick_a], seat_name(by)]
		_add(_row([_button("take%d" % a.a, "Take the die\nfrom %s" % seat_name(a.a), _on_take.bind(a.a)),
			_button("take%d" % a.b, "Take the die\nfrom %s" % seat_name(a.b), _on_take.bind(a.b))]))
	elif k == "feast":
		text.text += "\nTap one of your dice showing 4, 5 or 6."
		_add(_dice_row(by, func(f): return Rules.face_score(s.cfg, f) > 0))
		_add(_button("back", "Back", _on_back))
	elif k == "whisper" and not a.has("mine"):
		text.text += "\nFirst tap the die of yours to swap away."
		var copy: bool = act.key == "grasp"
		# a die of yours can go if some higher die on the table can come in without the swap being what reaches the goal
		var can_go := func(f: int) -> bool:
			for i in others:
				for g in s.seats[i].last_roll:
					if g > f and not Rules.whisper_crosses(s, by, f, g, copy):
						return true
			return false
		_add(_dice_row(by, can_go))
		_add(_button("back", "Back", _on_back))
	elif k == "whisper":
		var mine: int = s.seats[by].last_roll[a.mine]
		text.text += "\nYour %d goes. Now tap a higher die of another player's." % mine
		var copied: bool = act.key == "grasp"
		var refused := false
		for i in others:
			for f in s.seats[i].last_roll:
				refused = refused or (f > mine and Rules.whisper_crosses(s, by, mine, f, copied))
		if refused:
			text.text += "\n%s The dice that would are switched off." % Rules.whisper_cross_text(s.cfg)
		for i in others:
			if not s.seats[i].last_roll.is_empty():
				_add(_dice_row(i, func(f): return f > mine and not Rules.whisper_crosses(s, by, mine, f, copied)))
		_add(_button("back", "Back", _on_back))
	else:
		# spark, glance: a die of another player's last roll
		var low: int = int(s.cfg.spark_min) if k == "spark" else 1
		text.text += "\nTap a die showing 5 or 6." if k == "spark" else "\nTap a die to copy."
		for i in others:
			if a.has("target") and a.target != i:
				continue
			if s.seats[i].last_roll.is_empty() or Rules.block(s, act.key, act_args({"target": i})) != "":
				continue
			_add(_dice_row(i, func(f): return f >= low))
		_add(_button("back", "Back", _on_back))


# ---- building

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font = serif
	th.default_font_size = SIZE_TEXT
	th.set_color("font_color", "Label", TEXT)
	theme = th
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var top := 30
	var bottom := 24
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if screen.y > 0 and safe.size.y > 0:
		var k := get_viewport_rect().size.y / float(screen.y)
		top = maxi(top, int(safe.position.y * k) + 8)
		bottom = maxi(bottom, int((screen.y - safe.end.y) * k) + 8)
	var v := _page(self, top, bottom, 10)

	header = _label("", 30, DIM)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_btn = _button("help", "How to play", _on_help)
	help_btn.custom_minimum_size = Vector2(210, 84)
	help_btn.add_theme_font_size_override("font_size", SIZE_SMALL)
	log_btn = _button("log", "Match log", _on_log)
	log_btn.custom_minimum_size = Vector2(180, 84)
	log_btn.add_theme_font_size_override("font_size", SIZE_SMALL)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(header)
	head.add_child(log_btn)
	head.add_child(help_btn)
	v.add_child(head)
	panel_box = VBoxContainer.new()
	panel_box.add_theme_constant_override("separation", 10)
	v.add_child(panel_box)
	# who did what to whom
	var eb := StyleBoxFlat.new()
	eb.bg_color = Color("3a2226")
	eb.border_color = BAD
	eb.set_border_width_all(2)
	eb.set_corner_radius_all(12)
	eb.set_content_margin_all(12)
	event_box = PanelContainer.new()
	event_box.add_theme_stylebox_override("panel", eb)
	event_label = _label("", 30, TEXT)
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_box.add_child(event_label)
	v.add_child(event_box)
	title = _label("", SIZE_TITLE, GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(title)
	text = _label("", SIZE_SMALL, TEXT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(text)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	v.add_child(buttons)

	# the How to play card
	howto = ColorRect.new()
	howto.color = BG
	howto.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(howto)
	var cv := _page(howto, top + 30, bottom, 30)
	cv.add_child(_label("How to play", SIZE_POINTS, GOLD))
	for line in HOWTO:
		var l := _label(line, SIZE_NAME, TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(l)
	var csp := Control.new()
	csp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cv.add_child(csp)
	count_row = HBoxContainer.new()
	count_row.add_theme_constant_override("separation", 12)
	cv.add_child(count_row)
	got_btn = _button("got_it", "Got it", _on_got_it, true)
	cv.add_child(got_btn)

	# a Sin's abilities
	sin_card = ColorRect.new()
	sin_card.color = BG
	sin_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sin_card)
	var sv := _page(sin_card, top + 30, bottom, 30)
	sin_title = _label("", SIZE_POINTS, GOLD)
	sv.add_child(sin_title)
	sin_text = _label("", SIZE_NAME, TEXT)
	sin_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sv.add_child(sin_text)
	var ssp := Control.new()
	ssp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sv.add_child(ssp)
	close_btn = _button("close", "Close", _on_close, true)
	sv.add_child(close_btn)

	# the match log: every move, newest first, in a list that scrolls
	log_card = ColorRect.new()
	log_card.color = BG
	log_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(log_card)
	var lv := _page(log_card, top + 30, bottom, 20)
	lv.add_child(_label("Match log", SIZE_POINTS, GOLD))
	var log_hint := _label("Every move, newest first. R is the round; in brackets, the change to that player's points and their total.", SIZE_SMALL, DIM)
	log_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv.add_child(log_hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lv.add_child(scroll)
	log_list = VBoxContainer.new()
	log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_list.add_theme_constant_override("separation", 18)
	scroll.add_child(log_list)
	copy_btn = _button("copy_log", "Copy log", _on_copy_log)
	log_close_btn = _button("close_log", "Close", _on_close_log, true)
	lv.add_child(_row([copy_btn, log_close_btn]))


## A centred column of the content width inside parent, between the safe margins.
func _page(parent: Control, top: int, bottom: int, gap: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	parent.add_child(margin)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(h)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(W, 0)
	v.add_theme_constant_override("separation", gap)
	h.add_child(v)
	return v


## A seat's box: name, Sin (a button: its abilities), tags and points; then dice, last roll, what it scored, and Spark of Rage.
func _panel(i: int) -> Control:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.border_color = SEAT_COLORS[i]
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(12)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	pc.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	v.add_child(top)
	top.add_child(_label(seat_name(i), SIZE_NAME, SEAT_COLORS[i]))
	var sin_btn := _button("sin%d" % i, "", _on_sin.bind(i))
	sin_btn.custom_minimum_size = Vector2(190, 72)
	sin_btn.add_theme_font_size_override("font_size", SIZE_SMALL)
	top.add_child(sin_btn)
	var tag := _label("", 28, GOLD)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(tag)
	var points := _label("0", SIZE_POINTS, TEXT)
	top.add_child(points)
	var low := HBoxContainer.new()
	low.add_theme_constant_override("separation", 14)
	v.add_child(low)
	var dice := _label("", SIZE_TEXT, TEXT)
	dice.custom_minimum_size = Vector2(230, DIE)
	dice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	low.add_child(dice)
	var roll := HFlowContainer.new()
	roll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roll.add_theme_constant_override("h_separation", 8)
	roll.add_theme_constant_override("v_separation", 8)
	low.add_child(roll)
	var scored := _label("", 30, DIM)
	scored.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scored.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	scored.size_flags_vertical = Control.SIZE_FILL
	low.add_child(scored)
	var spark := _button("spark%d" % i, "Spark\nof Rage", func(): _on_ability("spark", wrath_seat(), {"target": i}))
	spark.custom_minimum_size = Vector2(130, DIE)
	spark.add_theme_font_size_override("font_size", 22)
	spark.visible = false
	low.add_child(spark)
	panels.append({"box": sb, "sin": sin_btn, "tag": tag, "points": points, "dice": dice, "roll": roll, "scored": scored, "spark": spark})
	return pc


## One die of a last roll: a 4, 5 or 6 (it scores) is bright; a 1, 2 or 3 is dim.
func _die(face: int) -> Control:
	var high: bool = face > int(s.cfg.low_max)
	var sb := StyleBoxFlat.new()
	sb.bg_color = TEXT if high else BUTTON_OFF
	sb.border_color = DIM
	sb.set_border_width_all(0 if high else 2)
	sb.set_corner_radius_all(10)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size = Vector2(DIE, DIE)
	var l := _label(str(face), SIZE_NAME, DARK if high else DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pc.add_child(l)
	return pc


## A player's last roll as dice to tap (keys d<seat>_<index>); allowed(face) says which can be tapped.
func _dice_row(seat: int, allowed: Callable) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var l := _label(seat_name(seat), SIZE_TEXT, SEAT_COLORS[seat])
	l.custom_minimum_size = Vector2(190, PICK)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	h.add_child(flow)
	var roll: Array = s.seats[seat].last_roll
	for j in roll.size():
		var b := _button("d%d_%d" % [seat, j], str(roll[j]), _on_die.bind(seat, j), false, not allowed.call(roll[j]), true)
		b.custom_minimum_size = Vector2(PICK, PICK)
		b.add_theme_font_size_override("font_size", SIZE_NAME)
		flow.add_child(b)
	return h


## A player to choose (key target<seat>); why: the reason they cannot be chosen, shown on the button.
func _target_button(i: int, why: String, chosen: bool) -> Button:
	var b := _button("target%d" % i, seat_name(i) + ("\n" + why if why != "" else ""), _on_target.bind(i), false, why != "", chosen)
	if why != "":
		b.add_theme_font_size_override("font_size", 26)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return b


## The button that starts one of the turn player's abilities; switched off, with the reason, when it cannot be used now.
func _ability_button(key: String, label: String) -> Button:
	var why := Rules.block(s, key)
	var b := _button(key, label + ("\n" + why if why != "" else ""), _on_ability.bind(key, s.turn), false, why != "")
	b.add_theme_font_size_override("font_size", 30 if why != "" else SIZE_SMALL)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return b


func _label(t: String, size_px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	return l


func _add(c: Control) -> void:
	buttons.add_child(c)


func _row(items: Array) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	for c in items:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(c)
	return h


## A flat button, kept in btn under its key. main: the one to tap next (gold). chosen: a picked option (ivory).
func _button(key: String, label: String, then: Callable, main := false, off := false, chosen := false) -> Button:
	var b := Button.new()
	b.text = label
	b.disabled = off
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, BUTTON_H)
	b.add_theme_font_size_override("font_size", SIZE_TEXT)
	var fill := GOLD if main else (TEXT if chosen else BUTTON)
	var ink := DARK if (main or chosen) else TEXT
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = BUTTON_OFF if st == "disabled" else (fill.darkened(0.2) if st == "pressed" else fill)
		sb.set_corner_radius_all(12)
		sb.set_content_margin_all(8)
		b.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, ink)
	b.add_theme_color_override("font_disabled_color", DIM)
	b.pressed.connect(then)
	btn[key] = b
	return b
