## Step 1: 2, 3 or 4 players pass one phone (rules: docs/step1-rules.md, in game/). A flat blockout: boxes and words, no art.
## Before the first turn: the How to play card (also behind the How to play button), where the number of players is chosen
## and the Sins are dealt out or picked, each player in seat order.
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
const DIE_SEP := 8       # between two of them
const DICE_ROOM := 424   # the narrowest a row's line of dice gets: beside a two-line share and Spark of Rage (six compact dice; tests/table_test.gd checks it)
const PICK := 104        # a die you tap to choose it
const SIZE_SMALL := 34
const SIZE_EVENT := 30    # the last move
const SIZE_NOTE := 34     # the smallest text on the table: the top bar, "no roll yet", "scored N", a switched-off ability's reason (30 before 0.23.0)
const SIZE_TEXT := 40
const SIZE_NAME := 48
const SIZE_TITLE := 54
const SIZE_POINTS := 72
const BUTTON_H := 116
const BORDER_TURN := 10  # a seat's box: the border on the turn player's row
const BORDER_NEAR := 6   # and on a row within NEAR_GAP of the goal
const ROW_SIDE := 30     # a seat's box: left and right, edge to content. More than the thickest border, so the turn row keeps 20 clear inside it; the same on every row, so the names line up. At 32, six dice beside a share and Spark of Rage wrap to a second line.
const NAME_GAP := 28     # between a player's name and the Sin button
const TAG_SEP := "  ·  " # between a row's tags: TURN  ·  TIER 1 USED
const ROW_GAP := 10      # between two seats' boxes
const ROW_PAD := 12      # a seat's box: top and bottom, edge to content
const ROW_LINES := 4     # a seat's box: between the name line and the dice line
const MARGIN_TOP := 30   # the page's margins where the display has no safe-area inset
const MARGIN_BOTTOM := 24
## The seats' boxes come in two sizes. Compact is the numbers above: four of them fit every view on a 1920 screen.
## Roomy is compact plus a share of ROOMY, set once a match (_measure) from the height there is to spend: what the screen
## has past BASE_HEIGHT (the stretch aspect is "expand"), a whole compact box for each seat fewer than four, and what the
## fullest turn view leaves at BASE_HEIGHT. Roomy is the size shown; a view that does not fit with it (a form, mostly) is
## shown compact for as long as that is so (_fit).
const BASE_HEIGHT := 1920
const CARD_COMPACT := 192  # a compact box's height (tests/table_test.gd checks it is still this)
const TURN_SPARE := 48     # of what the fullest Gambit view leaves at BASE_HEIGHT with four compact boxes: 74 when this was set (0.21.0), more since the gift buttons went
## Roomy at its fullest, as amounts added to compact: 40 + 12 + 2 x 22 = 96 a box, half as tall again as a compact one.
const ROOMY := {
	"die": 40,    # a die of a last roll: up to 104, as big as a die you tap; fewer of them fit beside a share and Spark of Rage the more there are (die_px)
	"lines": 12,  # between the name line and the dice line
	"pad": 22,    # top and bottom
	"gap": 10,    # between two boxes
	"head": 16,   # above the "Player N: ..." heading
}
## On top of the size set for the match, each view gives the height it leaves unused to the boxes (_fit), up to FILL_MAX
## a box, so the boxes, not an empty band, take the screen (Ben, 2026-11-28). The fullest views leave little or nothing.
const FILL_MAX := 100
## The How to play card: shown before the first turn of each match, and from the How to play button at any time.
const HOWTO := [
	"First to 1000 points wins.",
	"On your turn, roll all your dice once. A 4, 5 or 6 scores 40, 50 or 60.",
	"If every die shows 1, 2 or 3 you are in Purgatory: no score, and your turn ends. On a later turn, two or more dice showing 1, 2 or 3 get you out.",
	"After rolling you can buy one die a turn for 20.",
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
var view := "handover"       # handover (pass the phone), turn (roll, swap, Gambit, turn over, winner), ability
var note := ""               # what the roll did, shown in the turn view
var event := ""              # who did what to whom, in one line; stays until the next action
var act := {}                # the ability being set up: key, by (seat), args (the choices so far), back (the view to return to)
var btn := {}                # the buttons on screen now, by key (the test taps these)
var log = MatchLog.new()     # every move of this match
var shares: Array = []       # a seat: [what an ability added to their last roll ("Glance +60", or ""), points of it that last_score leaves out (Slow Drip)]
var roll_before := 0         # the turn player's points before their roll
var copied := ""             # the text Copy log last put on the clipboard
var dealt := false           # the table has been shown this match: the Sins are dealt or picked
var picking := false         # the players are picking their Sins, in seat order
var picks: Array = []        # the Sins picked so far: picks[i] is seat i's
var swap_refused: Array = [] # Lust's roll waiting to be scored: the swaps Whisper of Desire refuses, as [gave, got] faces

var serif: FontVariation
var header: Label
var panels: Array = []       # one Dictionary of nodes a seat
var panel_box: VBoxContainer # the seats' boxes: rebuilt for each match's number of players
var count_row: HBoxContainer # on the How to play card: how many players
var start_row: HBoxContainer # on the How to play card before the first turn: Deal them out, Pick Sins
var deal_btn: Button
var pick_btn: Button
var pick_card: Control       # the Sin picker, over everything
var pick_title: Label
var pick_list: VBoxContainer
var pick_back_btn: Button
var event_box: PanelContainer
var event_label: RichTextLabel
var title: Label
var title_gap: MarginContainer # holds the heading; its top margin is the roomy size's extra gap above it
var page: VBoxContainer      # the table's column: everything but the cards that cover it
var page_top := MARGIN_TOP   # the page's margins, safe area included
var page_bottom := MARGIN_BOTTOM
var grow := {}               # this match's roomy size: the amounts added to compact, by ROOMY's keys
var tight := false           # the boxes are shown compact: the view on screen does not fit with roomy ones
var fill := 0                # what the view on screen adds to each box's height, out of the height it leaves unused
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
	resized.connect(_measure)
	# The page's minimum height is what its content needs: checked whenever it changes, not at a guessed moment.
	page.minimum_size_changed.connect(_fit)
	new_match()


## The roomy size for this match and this screen: the share of ROOMY the height to spend allows, rounded down.
func _measure() -> void:
	var n: int = s.seats.size()
	var usable: float = size.y - (page_top - MARGIN_TOP) - (page_bottom - MARGIN_BOTTOM)
	var spend: float = maxf(0.0, usable - BASE_HEIGHT + TURN_SPARE + (4 - n) * (CARD_COMPACT + ROW_GAP))
	var full: float = n * (ROOMY.die + ROOMY.lines + 2 * ROOMY.pad) + (n - 1) * ROOMY.gap + ROOMY.head
	var k := clampf(spend / full, 0.0, 1.0)
	grow = {}
	for key in ROOMY:
		grow[key] = int(ROOMY[key] * k)
	tight = false
	fill = 0
	_space()
	_fit()


## What the size on screen adds to compact: this match's roomy amount, or nothing while the boxes are compact.
func grown(key: String) -> int:
	return 0 if tight else int(grow.get(key, 0))


## A die of a last roll of count dice, at the size on screen: the roomy size, or the biggest at which that many fit on
## one line in DICE_ROOM, and never smaller than compact.
func die_px(count := 1) -> int:
	var d := DIE + grown("die")
	var fits := int((DICE_ROOM - (count - 1) * DIE_SEP) / maxi(count, 1))
	return maxi(DIE, mini(d, fits))


## Sets the boxes to the size on screen now.
func _space() -> void:
	panel_box.add_theme_constant_override("separation", ROW_GAP + grown("gap"))
	title_gap.add_theme_constant_override("margin_top", grown("head"))
	for n in panels:
		n.col.add_theme_constant_override("separation", ROW_LINES + grown("lines"))
		n.box.set_content_margin(SIDE_TOP, ROW_PAD + grown("pad"))
		n.box.set_content_margin(SIDE_BOTTOM, ROW_PAD + grown("pad"))
		n.dice.custom_minimum_size = Vector2(230, die_px())   # the line is as tall in every box, whatever its dice
		var d := die_px(n.roll.get_child_count())
		for c in n.roll.get_children():
			if c is PanelContainer:   # a die
				c.custom_minimum_size = Vector2(d, d)
			else:                     # "no roll yet": as tall as the line, its words in the middle beside "3 dice"
				c.custom_minimum_size = Vector2(0, die_px())


## Compact or roomy, from what the view on screen needs: compact while it would not fit with roomy boxes.
## Decided again each time the page's minimum height changes, in both directions: a label that has just been shown asks
## for too much height until it is laid out, so one reading cannot be kept. While compact, what roomy would need is the
## height now plus all that roomy adds, which is never less than the truth: the two answers cannot chase each other.
## Then the fill: what the view leaves unused, shared out among the boxes. The height without it is the page's less what
## the fill adds to each box now, so the fill cannot feed on itself.
func _fit() -> void:
	var n: int = panels.size()
	if n == 0:
		return
	var more: int = n * (int(grow.lines) + 2 * int(grow.pad) + int(grow.die)) + (n - 1) * int(grow.gap) + int(grow.head)
	var avail: float = size.y - page_top - page_bottom
	var need: float = _unfilled() + (more if tight else 0)
	var want: bool = need > avail
	if want != tight:
		tight = want
		_space()
	fill = 0 if tight else clampi(int((avail - _unfilled()) / n), 0, FILL_MAX)
	_fill()   # also when the fill is the same: a box's content may have changed height


## The page's height without the fill.
func _unfilled() -> float:
	var extra := 0.0
	for p in panels:
		extra += maxf(0.0, p.panel.get_combined_minimum_size().y - _natural(p))
	return page.get_combined_minimum_size().y - extra


## A box's height without the fill: its content and its padding.
func _natural(p: Dictionary) -> float:
	return p.col.get_combined_minimum_size().y + p.box.get_content_margin(SIDE_TOP) + p.box.get_content_margin(SIDE_BOTTOM)


## Each box as tall as its content plus the fill, the content in the middle.
func _fill() -> void:
	for p in panels:
		p.panel.custom_minimum_size.y = (_natural(p) + fill) if fill > 0 else 0.0


## chosen: the Sins the players picked, one a seat; else they are dealt. card: open on the How to play card.
func new_match(chosen: Array = [], card := true) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	# Fixed Sins (tests, screenshots) are used seat by seat; with too few for the table they are dealt at random.
	var fixed: Array = sins.slice(0, seats) if sins.size() >= seats else []
	if chosen.size() == seats:
		fixed = chosen
	s = Rules.new_match(Config.merged({"seats": seats}), rng, fixed)
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
	_measure()
	view = "handover"
	note = ""
	event = ""
	act = {}
	picking = false
	picks = []
	swap_refused = []
	howto.visible = card and chosen.size() != seats
	dealt = not howto.visible
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


## The short reason on a die Whisper of Desire will not swap: "to 1000".
func cross_mark() -> String:
	return "to %d" % int(s.cfg.win)


## The swaps Whisper of Desire refuses this seat now because they would be what takes them to the goal, as [gave, got]
## faces, each pair once. copy: through Jealous Grasp, after scoring.
func refused_swaps(seat: int, copy: bool) -> Array:
	var out := []
	for pr in Rules.whisper_pairs(s, seat):
		var pair := [s.seats[seat].last_roll[pr[0]], s.seats[pr[1]].last_roll[pr[2]]]
		if not out.has(pair) and Rules.whisper_crosses(s, seat, pair[0], pair[1], copy):
			out.append(pair)
	return out


## Refused swaps go in the match log, and come back as a sentence for the screen ("" if there were none).
## total: the seat's points before the roll or the copy.
func _log_refused(seat: int, pairs: Array, total: int) -> String:
	if pairs.is_empty():
		return ""
	# one part a die given, with every die it was refused for: "a 2 for a 6 or 5"
	var by_gave := {}
	for p in pairs:
		if not by_gave.has(p[0]):
			by_gave[p[0]] = []
		by_gave[p[0]].append(str(p[1]))
	var parts := []
	for gave in by_gave:
		parts.append("a %d for a %s" % [gave, " or ".join(by_gave[gave])])
	log.add(s.round_number, who(seat), "Whisper of Desire refused: %s. %s" % ["; ".join(parts), Rules.whisper_cross_text(s.cfg)], 0, total)
	return " Whisper of Desire refused some swaps. %s" % Rules.whisper_cross_text(s.cfg)


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
		out = "You rolled %s. Every die shows 1, 2 or 3: Purgatory. You score 0 and your turn ends. No buying or abilities until you are out." % faces
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


## Before the first turn: deal the Sins at random, one each (a test's fixed Sins stay as they are), and show the table.
func _on_deal() -> void:
	if fresh:
		new_match([], false)


## Before the first turn: the players pick their Sins instead, the phone passed in seat order.
func _on_pick_sins() -> void:
	if not fresh:
		return
	picking = true
	picks = []
	_refresh()


## The player whose pick it is takes a free Sin. The last pick starts the match.
func _on_pick(sin: String) -> void:
	if not picking or picks.has(sin) or not Config.SINS.has(sin):
		return
	picks.append(sin)
	if picks.size() == seats:
		new_match(picks.duplicate())
	else:
		_refresh()


func _on_pick_back() -> void:
	picking = false
	picks = []
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
	swap_refused = []
	if r.get("pending", false):
		swap_refused = refused_swaps(s.turn, false)
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
	note = roll_note(r) + _log_refused(s.turn, swap_refused, roll_before)
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


func _on_back() -> void:
	view = str(act.get("back", "turn"))
	act = {}
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
	# a Whisper copied by Jealous Grasp: what it refuses is read before the swap changes the dice
	var copy_refused: Array = refused_swaps(by, true) if act.key == "grasp" and str(args.get("key", "")) == "whisper" else []
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
			note = roll_note(r) + _log_refused(by, swap_refused, pts[by])
			log.add(s.round_number, who(by), words, 0, pts[by])
			var plain: Array = r.faces.duplicate()
			plain[args.mine] = r.gave
			_log_roll(r, r.scored - (0 if Rules.lows(s.cfg, plain) == plain.size() else Rules.score(s.cfg, plain)))
		else:
			event += _log_refused(by, copy_refused, pts[by])
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
	# two lines at SIZE_NOTE, broken where it reads best rather than wherever the width runs out
	header.text = "Round %d   ·   First to %d wins\nSupply: %s" % [s.round_number, int(s.cfg.win), dice_text(s.supply)]
	for c in buttons.get_children():
		buttons.remove_child(c)
		c.queue_free()
	btn = {}
	for i in s.seats.size():
		_refresh_panel(i)
	event_label.text = "[color=#%s]LAST MOVE[/color]%s%s" % [BAD.to_html(false), "   ", event.replace("[", "[lb]")]
	event_box.visible = event != ""
	if view == "handover":
		_view_handover()
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
	for c in pick_list.get_children():
		pick_list.remove_child(c)
		c.queue_free()
	count_row.visible = fresh
	start_row.visible = fresh
	# Before the table has been shown the card closes by dealing or picking; after that, with Got it.
	got_btn.visible = dealt
	pick_card.visible = picking
	if picking:
		btn = {"pick_back": pick_back_btn}
		pick_title.text = "%s: pick your Sin" % seat_name(picks.size())
		for sin in Config.SINS:
			pick_list.add_child(_pick_entry(sin))
	elif howto.visible:
		btn = {}
		if dealt:
			btn["got_it"] = got_btn
		if fresh:
			btn["deal"] = deal_btn
			btn["pick"] = pick_btn
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
	sb.set_border_width_all(BORDER_TURN if turn else (BORDER_NEAR if near else 2))
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
	n.tag.text = TAG_SEP.join(tags)
	n.tag.add_theme_color_override("font_color", BAD if p.purgatory else GOLD)
	n.dice.text = dice_text(p.dice) + (" (%d taken)" % p.held if p.held > 0 else "")
	n.dice.add_theme_font_size_override("font_size", 30 if p.held > 0 else SIZE_TEXT)
	for c in n.roll.get_children():
		n.roll.remove_child(c)
		c.queue_free()
	if p.last_roll.is_empty():
		var none := _label("no roll yet", SIZE_TEXT, DIM)
		none.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		none.custom_minimum_size = Vector2(0, die_px())
		n.roll.add_child(none)
		n.scored.text = ""
	else:
		for f in p.last_roll:
			n.roll.add_child(_die(f, die_px(p.last_roll.size())))
		# with what an ability added to it: "scored 210 (Glance +60)"
		n.scored.text = "scored %d" % (p.last_score + int(shares[i][1])) + ("\n(%s)" % shares[i][0] if shares[i][0] != "" else "")
		# two lines at 24 are no taller than a compact die, so the row keeps its height; one line is at SIZE_NOTE
		n.scored.add_theme_font_size_override("font_size", 24 if shares[i][0] != "" else SIZE_NOTE)
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
			first = "Roll %s once. The last die is not rolled: it shows the copied %d." % [dice_text(p.dice - 1), p.glance]
		text.text = first + " A 4, 5 or 6 scores 40, 50 or 60. A 1, 2 or 3 scores nothing. If every die shows 1, 2 or 3 you go to Purgatory: you score 0 and your turn ends."
	if p.lethargic:
		text.text += " Lethargic Aura: one die is rolled twice and the lower kept."
	# The abilities used before the roll.
	if p.sin == "pride":
		_add(_ability_button("hubris", "Declare Hubris: beat %d to score %d more, or score 0" % [Rules.hubris_target(s), int(s.cfg.hubris_win_add)]))
	elif p.sin == "envy":
		_add(_ability_button("glance", "Green-Eyed Glance: copy a die in place of one of yours"))
	var n: int = p.dice - (1 if p.glance > 0 else 0)
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
	title.text = "%s: buy, use abilities, then pass" % seat_name(s.turn)
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
	if Sins.INFO.has(p.sin):
		var t1: Dictionary = Sins.INFO[p.sin].t1
		var t2: Dictionary = Sins.INFO[p.sin].t2
		var row := []
		# Spark of Rage is not shown while no other player's roll has a 5 or 6 to reroll (Ben, 2026-11-26).
		if not (t1.key == "spark" and Rules.block(s, "spark") == Rules.NO_SPARK):
			row.append(_ability_button(t1.key, t1.name))
		row.append(_ability_button(t2.key, "%s (%d)" % [t2.name, Sins.cost(s.cfg, t2.key)]))
		_add(_row(row))
	_add(_button("pass", "Pass: end my turn", _on_pass, true))


func _view_end() -> void:
	title.text = "%s: your turn is over" % seat_name(s.turn)
	text.text = note
	_add(_button("pass", "Pass the phone", _on_pass, true))


func _view_over() -> void:
	title.text = "%s wins!" % seat_name(s.winner)
	text.text = "%s\n%s ended a Fate Phase on %d points, out of Purgatory. First to %d wins." % [note, seat_name(s.winner), s.seats[s.winner].points, int(s.cfg.win)]
	_add(_row([_button("log_win", "Match log", _on_log), _button("new", "New match", new_match, true)]))


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
		# a die of yours with a higher die to take, but every such swap refused, is marked with the reason
		var why_go := func(f: int) -> String:
			for i in others:
				for g in s.seats[i].last_roll:
					if g > f:
						return cross_mark()
			return ""
		for f in s.seats[by].last_roll:
			if not can_go.call(f) and why_go.call(f) != "":
				text.text += "\n%s The dice marked \"%s\" cannot be swapped." % [Rules.whisper_cross_text(s.cfg), cross_mark()]
				break
		_add(_dice_row(by, can_go, why_go))
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
			text.text += "\n%s The dice marked \"%s\" cannot be taken." % [Rules.whisper_cross_text(s.cfg), cross_mark()]
		for i in others:
			if not s.seats[i].last_roll.is_empty():
				_add(_dice_row(i, func(f): return f > mine and not Rules.whisper_crosses(s, by, mine, f, copied),
					func(f): return cross_mark() if f > mine else ""))
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
	var top := MARGIN_TOP
	var bottom := MARGIN_BOTTOM
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if screen.y > 0 and safe.size.y > 0:
		var k := get_viewport_rect().size.y / float(screen.y)
		top = maxi(top, int(safe.position.y * k) + 8)
		bottom = maxi(bottom, int((screen.y - safe.end.y) * k) + 8)
	page_top = top
	page_bottom = bottom
	var v := _page(self, top, bottom, 10)
	page = v

	header = _label("", SIZE_NOTE, DIM)
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
	panel_box.add_theme_constant_override("separation", ROW_GAP)
	v.add_child(panel_box)
	# who did what to whom: the last move, a card of its own, headed LAST MOVE on its first line
	var eb := StyleBoxFlat.new()
	eb.bg_color = Color("3a2226")
	eb.border_color = BAD
	eb.set_border_width_all(2)
	eb.border_width_left = 8
	eb.set_corner_radius_all(12)
	eb.set_content_margin_all(16)
	eb.set_content_margin(SIDE_LEFT, 24)
	event_box = PanelContainer.new()
	event_box.add_theme_stylebox_override("panel", eb)
	event_label = RichTextLabel.new()
	event_label.bbcode_enabled = true
	event_label.fit_content = true
	event_label.scroll_active = false
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_label.add_theme_font_size_override("normal_font_size", SIZE_EVENT)
	event_label.add_theme_color_override("default_color", TEXT)
	event_box.add_child(event_label)
	v.add_child(event_box)
	title = _label("", SIZE_TITLE, GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_gap = MarginContainer.new()   # no margin, so no height of its own, until _space gives it one
	title_gap.add_child(title)
	v.add_child(title_gap)
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
	deal_btn = _button("deal", "Deal them out", _on_deal)
	pick_btn = _button("pick", "Pick Sins", _on_pick_sins, true)
	start_row = _row([deal_btn, pick_btn])
	cv.add_child(start_row)
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

	# the Sin picker: one entry a Sin, tapped by each player in seat order
	pick_card = ColorRect.new()
	pick_card.color = BG
	pick_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pick_card)
	var pv := _page(pick_card, top + 30, bottom, 12)
	pick_title = _label("", SIZE_TITLE, GOLD)
	pv.add_child(pick_title)
	var pick_hint := _label("Pass the phone in seat order. Each player taps a free Sin.", SIZE_SMALL, DIM)
	pick_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(pick_hint)
	pick_list = VBoxContainer.new()
	pick_list.add_theme_constant_override("separation", 10)
	pv.add_child(pick_list)
	var psp := Control.new()
	psp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv.add_child(psp)
	pick_back_btn = _button("pick_back", "Back", _on_pick_back)
	pv.add_child(pick_back_btn)


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
	sb.set_content_margin_all(ROW_PAD)
	# The content margin is measured from the box's edge, border included: the sides are set past the thickest border.
	sb.set_content_margin(SIDE_LEFT, ROW_SIDE)
	sb.set_content_margin(SIDE_RIGHT, ROW_SIDE)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", ROW_LINES)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER   # in the middle of a box the fill makes taller
	pc.add_child(v)
	var top := HBoxContainer.new()
	var top_sep := 14
	top.add_theme_constant_override("separation", top_sep)
	v.add_child(top)
	top.add_child(_label(seat_name(i), SIZE_NAME, SEAT_COLORS[i]))
	# a wider gap after the name only: the row's separation on each side of this, and the rest here
	var name_gap := Control.new()
	name_gap.custom_minimum_size = Vector2(NAME_GAP - 2 * top_sep, 0)
	top.add_child(name_gap)
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
	roll.add_theme_constant_override("h_separation", DIE_SEP)
	roll.add_theme_constant_override("v_separation", 8)
	low.add_child(roll)
	var scored := _label("", SIZE_NOTE, DIM)
	scored.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scored.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	scored.size_flags_vertical = Control.SIZE_FILL
	low.add_child(scored)
	var spark := _button("spark%d" % i, "Spark\nof Rage", func(): _on_ability("spark", wrath_seat(), {"target": i}))
	spark.custom_minimum_size = Vector2(130, DIE)
	spark.add_theme_font_size_override("font_size", 26)
	spark.visible = false
	low.add_child(spark)
	panels.append({"panel": pc, "box": sb, "col": v, "sin": sin_btn, "tag": tag, "points": points, "dice": dice, "roll": roll, "scored": scored, "spark": spark})
	return pc


## One die of a last roll: a 4, 5 or 6 (it scores) is bright; a 1, 2 or 3 is dim.
func _die(face: int, px: int) -> Control:
	var high: bool = face > int(s.cfg.low_max)
	var sb := StyleBoxFlat.new()
	sb.bg_color = TEXT if high else BUTTON_OFF
	sb.border_color = DIM
	sb.set_border_width_all(0 if high else 2)
	sb.set_corner_radius_all(10)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size = Vector2(px, px)
	var l := _label(str(face), SIZE_NAME, DARK if high else DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pc.add_child(l)
	return pc


## A player's last roll as dice to tap (keys d<seat>_<index>); allowed(face) says which can be tapped.
## why(face): a short reason shown on a die that cannot be tapped ("": none).
func _dice_row(seat: int, allowed: Callable, why := Callable()) -> Control:
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
		var reason: String = str(why.call(roll[j])) if b.disabled and why.is_valid() else ""
		if reason != "":
			var mark := _label(reason, 20, BAD)
			mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			b.add_child(mark)
			# along the die's bottom edge, 4 clear of it
			mark.anchor_right = 1.0
			mark.anchor_top = 1.0
			mark.anchor_bottom = 1.0
			mark.offset_top = -36
			mark.offset_bottom = -4
		flow.add_child(b)
	return h


## One Sin in the picker (key pick_<sin>): its name and a line for each ability; a Sin already taken is dimmed and off.
func _pick_entry(sin: String) -> Control:
	var by: int = picks.find(sin)
	var taken := by >= 0
	var sb := StyleBoxFlat.new()
	sb.bg_color = BUTTON_OFF if taken else BUTTON
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(10)
	sb.set_content_margin(SIDE_LEFT, 20)
	sb.set_content_margin(SIDE_RIGHT, 20)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pc.add_child(v)
	var t1: Dictionary = Sins.INFO[sin].t1
	var t2: Dictionary = Sins.INFO[sin].t2
	v.add_child(_label(sin.capitalize() + ("%staken by %s" % [TAG_SEP, seat_name(by)] if taken else ""), SIZE_TEXT, DIM if taken else GOLD))
	for line in ["%s: %s" % [t1.name, Sins.text(t1.key, seats)], "%s (%d): %s" % [t2.name, Sins.cost(s.cfg, t2.key), Sins.text(t2.key, seats)]]:
		var l := _label(line, 26, DIM if taken else TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	# the whole entry is the button: a clear one laid over the words
	var b := Button.new()
	b.disabled = taken
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var down := StyleBoxFlat.new()
	down.bg_color = Color(1, 1, 1, 0.12)
	down.set_corner_radius_all(12)
	b.add_theme_stylebox_override("pressed", down)
	b.pressed.connect(_on_pick.bind(sin))
	pc.add_child(b)
	btn["pick_" + sin] = b
	return pc


## A player to choose (key target<seat>); why: the reason they cannot be chosen, shown on the button.
func _target_button(i: int, why: String, chosen: bool) -> Button:
	var b := _button("target%d" % i, seat_name(i) + ("\n" + why if why != "" else ""), _on_target.bind(i), false, why != "", chosen)
	if why != "":
		b.add_theme_font_size_override("font_size", 26)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return b


## The button that starts one of the turn player's abilities, in one of three looks (Ben, 2026-11-28):
## available, a gold border; used this turn, filled dark with gold words and USED; shut for another reason, an outline
## only, with the reason. Used and shut are switched off and say why.
func _ability_button(key: String, label: String) -> Button:
	var why := Rules.block(s, key)
	var used: bool = why != "" and spent(s.seats[s.turn], key)
	var words := label + (TAG_SEP + "USED" if used else "") + ("\n" + why if why != "" else "")
	var b := _button(key, words, _on_ability.bind(key, s.turn), false, why != "")
	b.add_theme_font_size_override("font_size", SIZE_NOTE if why != "" else SIZE_SMALL)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if why == "":
		for st in ["normal", "hover", "pressed"]:
			var sb: StyleBoxFlat = b.get_theme_stylebox(st).duplicate()
			sb.border_color = GOLD
			sb.set_border_width_all(4)
			b.add_theme_stylebox_override(st, sb)
	else:
		var off := StyleBoxFlat.new()
		off.set_corner_radius_all(12)
		off.set_content_margin_all(8)
		off.set_border_width_all(2)
		if used:
			off.bg_color = BUTTON_OFF
			off.border_color = GOLD.darkened(0.45)
		else:
			off.bg_color = BG
			off.border_color = BUTTON
		b.add_theme_stylebox_override("disabled", off)
		b.add_theme_color_override("font_disabled_color", GOLD if used else DIM)
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
