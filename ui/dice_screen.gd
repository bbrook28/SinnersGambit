## Dice poker against the Master: the dressed screen (docs/superpowers/specs/2026-11-20-dice-poker-pitch.md, core B).
## Each throw you draw 1, 2 or 3 dice and keep one in your row of five; three skulls bust; a full row is paid.
## One viewpoint: the Master plays behind the far edge of the table; the dice land on a leather mat in front of you.
extends Control

const Rules = preload("res://dice/rules.gd")
const Config = preload("res://dice/config.gd")
const Demands = preload("res://dice/demands.gd")
const Tutorial = preload("res://ui/dice_tutorial.gd")
const Version = preload("res://ui/version.gd")

# Each face is cut without its own digits and falls back to EB Garamond's lining figures (a 1 with a flag and a
# foot), sized to the text around them (EB Garamond: assets/fonts/EBGaramond-OFL.txt).
const PIRATA_FILE := preload("res://assets/fonts/PirataOne-NoDigits.ttf")
const FELL_FILE := preload("res://assets/fonts/IMFellEnglish-NoDigits.ttf")
const CINZEL_FILE := preload("res://assets/fonts/Cinzel-NoDigits.ttf")
const CINZEL_BOLD_FILE := preload("res://assets/fonts/Cinzel-Bold-NoDigits.ttf")
const DIGITS_TEXT := preload("res://assets/fonts/Digits-Text.ttf")
const DIGITS_TITLE := preload("res://assets/fonts/Digits-Title.ttf")
const DIGITS_CAPS := preload("res://assets/fonts/Digits-Caps.ttf")
const DIGITS_CAPS_BOLD := preload("res://assets/fonts/Digits-CapsBold.ttf")

const DICE := {
	0: preload("res://assets/art/runtime/dice/blank.png"),
	1: preload("res://assets/art/runtime/dice/skull.png"),
	2: preload("res://assets/art/runtime/dice/2.png"),
	3: preload("res://assets/art/runtime/dice/3.png"),
	4: preload("res://assets/art/runtime/dice/4.png"),
	5: preload("res://assets/art/runtime/dice/5.png"),
	6: preload("res://assets/art/runtime/dice/6.png"),
}
const TABLE := preload("res://assets/art/runtime/table/table.jpg")
const EDGE := preload("res://assets/art/runtime/table/table_edge.png")
const MAT := preload("res://assets/art/runtime/table/mat.png")
const SOFT := preload("res://assets/art/runtime/table/soft_shadow.png")
const GLOW := preload("res://assets/art/runtime/table/glow.png")
const IDLE := preload("res://assets/art/master/master_fiddle_idle_8f.png")   # 8 frames of 640 px
const CANDLE_LIT := preload("res://assets/art/runtime/table/candle_lit.png")
const CANDLE_OUT := preload("res://assets/art/runtime/table/candle_out.png")
const RIBBON := preload("res://assets/art/ui/label_ribbon.png")
const PLATE := preload("res://assets/art/runtime/table/plate.png")
const COIN := preload("res://assets/art/ui/coin_single.png")
const SEAL := preload("res://assets/art/runtime/seals/normal.png")
const SEAL_DOWN := preload("res://assets/art/runtime/seals/pressed.png")
const SEAL_SMALL := preload("res://assets/art/ui/seal_small_normal.png")
const SEAL_SMALL_DOWN := preload("res://assets/art/ui/seal_small_pressed.png")
const SEAL_THROW := preload("res://assets/art/runtime/seals/e_throw.png")   # Next hand
const SEAL_CHOOSE := preload("res://assets/art/runtime/seals/e_choose.png")  # Got it
const SEAL_BACK := preload("res://assets/art/runtime/seals/e_back.png")
const SEAL_BOOK := preload("res://assets/art/runtime/seals/e_rulebook.png")
const NUMERALS := [null, preload("res://assets/art/runtime/seals/n1.png"),
	preload("res://assets/art/runtime/seals/n2.png"), preload("res://assets/art/runtime/seals/n3.png")]
const PAGE := preload("res://assets/art/runtime/page_plain.png")   # plain torn parchment, 1000 x 1400, made whole
const COINS := preload("res://assets/art/ui/icon_coins.png")
const BAG_ICON := preload("res://assets/art/ui/icon_die.png")
const FLEUR := preload("res://assets/art/ui/divider_fleur.png")
const SINS := ["pride", "greed", "lust", "envy", "gluttony", "wrath", "sloth"]
## The Sins that host. 0.13.0: Pride alone, with the one demand under test (dice/demands.gd). The other windows wait.
const HOSTS := ["pride"]
## All seven host hands, in this order, and each opens its hand at full screen.
## TODO(art): Greed's window needs a SpriteCook redo (Ben, 2026-11-21): the dice patch redrew his hands and robe,
## with a finer glass grain and lead lines that do not meet at its edge (see assets/art/spritecook-assets.json, 498a2ec6).
## Each Sin's glass colour, spilled on the wall and the table edge (never on the mat, dice or captions).
const SIN_LIGHT := {"pride": Color("8a50ff"), "greed": Color("aeb8cc"), "lust": Color("e0306a"),
	"envy": Color("3fc85a"), "gluttony": Color("ff8a30"), "wrath": Color("ff4a20"), "sloth": Color("3a6aff")}
const OPEN_TIME := 0.85   # the Sin's opening beat, in seconds; a tap ends it
const OPEN_READ := 2.5    # the opening the first time a demand is met, to read it (after its card); later hands use OPEN_TIME
const COST := Color("ff3b2e")   # a die or a row that costs marks (the deep end of risk_color)
const SFX := {
	"dice_roll": preload("res://assets/audio/dice_roll.wav"),
	"die_land": preload("res://assets/audio/die_land.wav"),
	"keep": preload("res://assets/audio/keep.wav"),
	"tick": preload("res://assets/audio/tick.wav"),
	"skull": preload("res://assets/audio/skull.wav"),
	"snuff": preload("res://assets/audio/snuff.wav"),
	"coin": preload("res://assets/audio/coin.wav"),
	"pay_small": preload("res://assets/audio/pay_small.wav"),
	"pay_big": preload("res://assets/audio/pay_big.wav"),
	"bust": preload("res://assets/audio/bust.wav"),
	"press": preload("res://assets/audio/press.wav"),
}
## The dice each hand is shown with in the hand ranking (by Rules.HANDS index).
const EXAMPLES := {7: [6, 6, 6, 6, 6], 6: [5, 5, 5, 5, 2], 5: [4, 4, 4, 2, 2], 4: [2, 3, 4, 5, 6],
	3: [3, 3, 3, 5, 6], 2: [5, 5, 3, 3, 6], 1: [4, 4, 2, 5, 6]}

const IVORY := Color("efe3c8")
const GOLD := Color("e8c06a")
const INK := Color("3a1f12")
const BLOOD := Color("9e1b1b")

const W := 1020          # content width
const DIE := 176         # die size in the row
const TDIE := 196        # die size in the tray
const SIN_CARD := "A Sin watches each hand. It pays marks for what it wants and takes marks for what it hates, on top of your hand.\n\nIts rule is written on the table edge. Lose the hand and it pays nothing."
## All the rules, in the lessons' words, for the ? page.
const RULES := [
	"Rolling and keeping. Each turn, roll 1, 2 or 3 dice from the bag and keep one in your row; the rest go back into the bag. Five dice fill the row and it is paid. A full row always makes at least a Pair.",
	"Skulls and candles. A 1 is a skull: it cannot be kept, it stays out of the bag and it puts out a candle. Three skulls and the Master takes the hand: it pays nothing. Under each button is your chance of losing the hand on that roll.",
	"The Last Dance. The bag's last die is rolled alone. It counts as any number you need, but a skull loses the hand.",
	"The Sin. A Sin watches each hand. It pays marks for what it wants and takes marks for what it hates, on top of your hand. The number above a die is what the Sin pays or takes if you keep it. Lose the hand and it pays nothing.",
]
const CARD_CHROME := 800   # a card's title, flourish, two buttons and paper margins: the height its text cannot use
## What makes each hand, in the order of Rules.HANDS.
const HAND_NOTES := ["", "two dice the same", "two pairs", "three dice the same", "2, 3, 4, 5, 6",
	"three the same and a pair", "four dice the same", "all five the same"]
const LIGHT_PAD := 600 # how far the Sin's light may reach past each side of the stage
const EDGE_Y := 420     # the table's far edge in the stage
const FPS := 8.0         # the Master's idle
const CANDLE_H := 220.0  # a lit candle's height

var save_path := "user://dice.cfg"   # tests point it elsewhere
var cfg := Config.merged({})
var s                     # the hand (dice/state.gd)
var tut                   # dice_tutorial.gd while the guided hand runs
var phase := "throw"      # throw, keep, anim, over
var selected := -1        # thrown die index picked for a keep
var total := 0            # marks across hands
var hands := 0
var sin_i := 0
var seen := {}
var cards: Array = []     # [{title, text, button, then, alt, alt_then, big, icon, body}]
var counting := false     # the marks counter is counting up a payout
var serif: FontVariation      # IM Fell
var blackletter: FontVariation  # Pirata One
var caps: FontVariation       # Cinzel
var caps_bold: FontVariation  # Cinzel, bold
var clock := 0.0

# nodes
var wall: TextureRect
var marks_label: Label
var coins_icon: TextureRect
var bag_label: Label      # the number
var bag_words: Label
var stage: Control
var master: TextureRect
var window: TextureRect
var spill: TextureRect
var opener: Control
var opener_glass: TextureRect
var opener_name: Label
var opener_line: Label    # the Sin's demand, under its name
var demand_label: Label   # the demand, on the table edge under the window, for the whole hand
var opening: Tween
var candles: Array = []
var glows: Array = []
var msg: Label
var tray: Control
var tray_dice: Array = []
var banner: Control
var banner_title: Label
var banner_text: Label
var ribbon_label: Label
var ribbon_if: Label
var sin_plus: Label           # "+", or a minus when the Sin takes
var open_hold := 0.0          # how long the last opening held, in seconds (tests read it)
var sin_label: Label      # what the Sin pays for the row: "Pride · 4"
var hint: Label
var row_slots: Array = []
var row_dice: Array = []
var seals: Array = []       # [{box, btn, cap}]
var seal_box: HBoxContainer
var keep_btn: TextureButton
var keep_box: Control
var keep_cap: Label
var next_box: Control
var next_btn: TextureButton
var overlay: Control
var card_title: Label
var card_body: VBoxContainer
var card_text: Label
var card_scroll: ScrollContainer
var card_inner: VBoxContainer
var card_btn: Button
var card_alt: Button
var fx: Control


func _init() -> void:
	serif = _face(FELL_FILE, DIGITS_TEXT)
	blackletter = _face(PIRATA_FILE, DIGITS_TITLE)
	caps = _face(CINZEL_FILE, DIGITS_CAPS)
	caps_bold = _face(CINZEL_BOLD_FILE, DIGITS_CAPS_BOLD)


func _face(base: Font, digits: Font) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = base
	f.fallbacks = [digits]
	return f


func _ready() -> void:
	_load()
	_build()
	if not seen.get("tutorial", false):
		_start_tutorial()
	else:
		_new_hand()


func _process(delta: float) -> void:
	clock += delta
	if master != null:
		(master.texture as AtlasTexture).region = Rect2(640 * (int(clock * FPS) % 8), 0, 640, 640)
	if wall != null and stage != null:
		wall.size = Vector2(size.x, maxf(0.0, stage.global_position.y + EDGE_Y + 4))
	for k in glows.size():
		glows[k].modulate.a = 0.5 + 0.07 * sin(clock * (7.0 + k * 1.3) + k * 2.0)


# ---------- the hand ----------

func _new_hand(rng = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	# a lesson names its own Sin: none for the first two (Pride's window still hangs there), Pride for the third
	var host: String = HOSTS[0] if tut != null else HOSTS[posmod(hands - 1, HOSTS.size())]
	cfg = Config.merged({"demand": tut.demand() if tut != null else host})
	s = Rules.new_hand(cfg, rng)
	selected = -1
	phase = "throw"
	sin_i = SINS.find(host)
	_end_opening()
	_set_sin()
	for k in candles.size():
		_set_candle(k, true)
	_clear_tray()
	_refresh()
	if tut != null:
		return
	var met := "demand: " + demand_line()   # one card, and one slow opening, for each demand the player meets
	if demand_line() != "" and not seen.get(met, false):
		seen[met] = true
		_save()
		_card("The Sin", SIN_CARD, "Got it", func(): _open_sin(OPEN_READ))
	else:
		_open_sin()


func _start_tutorial() -> void:
	tut = Tutorial.new()
	_start_lesson()


## The current lesson's scripted hand.
func _start_lesson() -> void:
	_end_opening()
	cards.clear()
	overlay.visible = false
	_new_hand(tut.rng())
	_tut_sync()


## The lessons end: by the skip button (only the tutorial is marked seen, so the one-time cards still come), or
## after the last lesson (everything they taught is marked seen).
func _end_tutorial(finished: bool) -> void:
	if finished:
		for k in ["skull", "dance", "demand: " + Demands.DEMANDS["pride"].line]:
			seen[k] = true
	tut = null
	seen["tutorial"] = true
	_save()
	_new_hand()


func _on_seal(n: int) -> void:
	if opener != null and opener.visible:
		_end_opening()
	if phase != "throw" or overlay.visible or not n in Rules.draw_options(s):
		return
	if tut != null and not tut.done():
		var st: Dictionary = tut.step()
		if st.type != "throw" or st.n != n:
			return
		tut.advance()
	_sfx("press")
	var row0: int = s.row.size()
	var skulls0: int = s.skulls
	var was_dance := Rules.is_dance(s)
	Rules.throw(s, n)
	_play_throw(row0, skulls0, was_dance)


func _on_die(i: int) -> void:
	if phase != "keep" or overlay.visible or i >= s.thrown.size():
		return
	if tut != null and not tut.done():
		var st: Dictionary = tut.step()
		if st.type != "keep" or s.thrown[i] != st.face:
			return
	if selected == i:
		_on_keep()
		return
	selected = i
	_sfx("tick")
	_buzz(8)
	_refresh()


func _on_keep() -> void:
	if phase != "keep" or selected < 0 or overlay.visible:
		return
	if tut != null and not tut.done():
		var st: Dictionary = tut.step()
		if st.type != "keep" or s.thrown[selected] != st.face:
			return
		tut.advance()
	var from: Vector2 = tray_dice[_tray_index_of(selected)].global_position
	var face: int = s.thrown[selected]
	var slot: int = s.row.size()
	Rules.keep(s, selected)
	selected = -1
	phase = "anim"
	_fly(face, from, slot, func():
		_clear_tray()
		_after_move())


## Index in the tray (which shows every face thrown, skulls too) of thrown pip i.
func _tray_index_of(i: int) -> int:
	var n := -1
	for j in s.last_faces.size():
		if s.last_faces[j] > int(cfg.skull_faces):
			n += 1
			if n == i:
				return j
	return 0


func _after_move() -> void:
	if s.over:
		_end()
	else:
		phase = "throw"
		_refresh()
		_tut_sync()


## The hand is over: the Master laughs at a bust; a paid row sends its marks flying to the counter; then the
## result banner comes down over the mat, with Next hand in place of the seals.
func _end() -> void:
	phase = "over"
	hands += 1
	var before := total
	total += s.marks
	_save()
	counting = true
	marks_label.text = "%d" % before
	_refresh()
	if s.busted:
		_laugh()
		_sfx("bust")
		_buzz(250)
		await get_tree().create_timer(1.1).timeout
	else:
		await get_tree().create_timer(0.35).timeout
		await _payout(before)
	counting = false
	_show_result()


## Marks fly from the row to the counter, which counts up; the Master and the sound scale with the hand.
func _payout(before: int) -> void:
	var big := _big(s)
	_react(big)
	if s.marks <= 0:
		return
	_sfx("pay_big" if big >= 1 else "pay_small")
	_buzz(40 if big == 0 else 120)
	# the hand's marks fly from the row, then the Sin's from its window; what a Sin takes comes off the row's
	var t: Dictionary = Rules.total(cfg, s.row, s.bank)
	var from_row: int = s.marks if t.sin <= 0 else t.marks
	var from_sin: int = s.marks - from_row
	if from_row > 0:
		await _coins(row_slots[0].global_position + Vector2(DIE / 2.0, DIE / 2.0), from_row, before, 0.9 if from_sin == 0 else 0.75)
	if from_sin > 0:
		_sfx("pay_small")
		_pulse(window)
		await _coins(window.global_position + window.size / 2.0, from_sin, before + from_row, 0.9)


## m marks fly as coins from a point to the counter, which counts up from `before`; then a pause.
func _coins(from: Vector2, m: int, before: int, pause: float) -> void:
	var n := mini(m, 12)
	var to: Vector2 = coins_icon.global_position + coins_icon.size / 2.0
	var bend := Vector2(40.0, (from.y + to.y) / 2.0)
	for k in n:
		var c := TextureRect.new()
		c.texture = COIN
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.size = Vector2(66, 25)
		c.pivot_offset = c.size / 2.0
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.scale = Vector2.ZERO
		fx.add_child(c)
		var start := from + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		c.global_position = start - c.pivot_offset
		var shown := before + roundi(float(m) * (k + 1) / n)
		var tw := create_tween()
		tw.tween_interval(0.08 * k)
		tw.tween_property(c, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(t: float):
			var q := start.lerp(bend, t).lerp(bend.lerp(to, t), t)
			c.global_position = q - c.pivot_offset
			c.rotation = t * 6.0, 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			c.queue_free()
			_sfx("coin", 0.12, -4.0)
			marks_label.text = "%d" % shown
			_pulse(marks_label))
	await get_tree().create_timer(0.08 * n + pause).timeout


func _show_result() -> void:
	var title := ""
	var text := ""
	if s.busted:
		title = "The Master takes the hand"
		text = "Three skulls. The hand pays nothing." if s.skulls >= int(cfg.bust_at) else "A skull on the Last Dance. The hand pays nothing."
	else:
		var t: Dictionary = Rules.total(cfg, s.row, s.bank)
		title = "%d mark%s" % [t.total, "" if t.total == 1 else "s"] if t.total > 0 else "No marks"
		if t.total == 0 and t.sin < 0 and t.marks > 0:
			title = "%s takes it all" % sin_name()   # the hand made marks and the Sin took them: not a bust, not a blank
		text = "%s You have %d marks in all." % [paid_line(t), total]
	var big := _big(s)
	banner_title.text = title
	banner_title.add_theme_font_size_override("font_size", (52 if s.busted else [72, 84, 96][big]))
	banner_title.add_theme_color_override("font_color", GOLD if big > 0 else IVORY)
	banner_text.text = text
	tray.move_child(banner, -1)
	banner.visible = true
	banner.modulate.a = 0.0
	banner.scale = Vector2(0.85, 0.85)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(banner, "modulate:a", 1.0, 0.2)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for d in tray_dice:
		if is_instance_valid(d):
			tw.tween_property(d, "modulate:a", 0.0, 0.25)
	_refresh()
	_tut_sync()   # a lesson's last card comes with the result


func _on_next() -> void:
	if phase != "over" or not next_box.visible:
		return
	_sfx("press")
	if tut != null:
		if tut.next_lesson():
			_start_lesson()
		else:
			_end_tutorial(true)
		return
	_new_hand()


## What was paid, in words: "Your row is paid." with no Sin; "Pair 1 + Pride 4." or "Pair 1, Envy takes 2." with one.
## Envy can take more than the hand made; the hand then pays nothing, never less.
func paid_line(t: Dictionary) -> String:
	if demand_line() == "":
		return "Your row is paid."
	if t.sin > 0:
		return "%s %d + %s %d." % [t.name, t.marks, sin_name(), t.sin]
	if t.sin < 0:   # the Sin's own number, as the ribbon shows it; the title says what is left (never less than 0)
		return "%s %d, %s takes %d." % [t.name, t.marks, sin_name(), -t.sin]
	return "%s %d. %s pays nothing." % [t.name, t.marks, sin_name()]


## How grand the result is: 0 for a bust or a small hand, 1 for three of a kind, 2 for a straight or better.
func _big(st) -> int:
	if st.busted:
		return 0
	var m: int = Rules.score(cfg, st.row).marks
	return 2 if m >= 5 else (1 if m >= 3 else 0)


# ---------- animation ----------

func _play_throw(row0: int, skulls0: int, was_dance: bool) -> void:
	phase = "anim"
	selected = -1
	_clear_tray()
	_sfx("dice_roll")
	var faces: Array = s.last_faces
	var tw := create_tween().set_parallel(true)
	var n := faces.size()
	for j in n:
		var face: int = faces[j]
		var d := _die_node(randi_range(1, 6), TDIE)
		var x := tray_x(j) - TDIE / 2.0
		var y := tray.size.y / 2.0 - TDIE / 2.0
		d.position = Vector2(x, y + 260)
		d.scale = Vector2(0.3, 0.3)
		d.rotation = randf_range(-2.5, 2.5)
		d.modulate.a = 0.0
		tray.add_child(d)
		tray_dice.append(d)
		var delay := 0.07 * j
		tw.tween_property(d, "position", Vector2(x, y), 0.42).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "scale", Vector2.ONE, 0.42).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "rotation", 0.0, 0.42).set_delay(delay).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "modulate:a", 1.0, 0.15).set_delay(delay)
		tw.tween_method(_flicker.bind(d, face), 0.0, 1.0, 0.42).set_delay(delay)
	await tw.finished
	for j in n:
		if is_instance_valid(tray_dice[j]):
			tray_dice[j].texture = DICE[faces[j]]
			_tag_die(tray_dice[j], faces[j])
	_sfx("die_land", 0.1, -3.0)
	if s.skulls > skulls0:
		for k in range(skulls0, mini(s.skulls, candles.size())):
			_set_candle(k, false)
		_sfx("skull")
		_sfx("snuff", 0.05, -6.0)
		_buzz(90)
		_flinch()
		_shake()
		if not seen.get("skull", false) and (tut == null or tut.done()):
			seen["skull"] = true
		await get_tree().create_timer(0.55).timeout
	if s.busted:
		_end()
		return
	if s.row.size() > row0:
		# a lone pip or the Last Dance die was kept for you
		var j := 0
		for k in faces.size():
			if faces[k] > int(cfg.skull_faces):
				j = k
		var face: int = s.row[-1]
		if was_dance and (tut == null or tut.done()) and not seen.get("dance", false):
			seen["dance"] = true
			_save()
		await get_tree().create_timer(0.25).timeout
		_fly(face, tray_dice[j].global_position, row0, func():
			_clear_tray()
			_after_move())
		return
	if s.thrown.size() > 1:
		phase = "keep"
	else:
		phase = "throw"
	_refresh()
	_tut_sync()


## A thrown die carries what keeping it would do to the Sin's pay: "+4" for a first 6 under Pride, "−4" for a
## second (it takes the 4 back), "−1" for a 2. Only when there is a keep to decide; above the die, clear of the mat's stitching.
func _tag_die(d: TextureRect, face: int) -> void:
	if face <= int(cfg.skull_faces) or s.thrown.size() < 2:
		return
	var m: int = Rules.sin_marks(cfg, s.row + [face], s.bank) - Rules.sin_marks(cfg, s.row, s.bank)
	if m == 0:
		return
	var tag := _label(marks_text(m), caps_bold, 44, GOLD if m > 0 else COST)
	tag.size = Vector2(TDIE, 54)
	tag.position = Vector2(0, -56)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(tag)


## A gain or a cost with its sign: "+2", "−1".
func marks_text(m: int) -> String:
	return "+%d" % m if m >= 0 else "−%d" % -m


## While a die tumbles its face flickers; it settles on the face thrown.
func _flicker(v: float, d: TextureRect, face: int) -> void:
	if not is_instance_valid(d):
		return
	if v >= 0.98:
		d.texture = DICE[face]
		return
	var step := int(v * 8.0)
	if d.get_meta("step", -1) != step:
		d.set_meta("step", step)
		d.texture = DICE[randi_range(1, 6)]


func _fly(face: int, from: Vector2, slot: int, done: Callable) -> void:
	var d := _die_node(face, TDIE)
	fx.add_child(d)
	d.global_position = from
	var to: Vector2 = row_slots[slot].global_position
	var tw := create_tween().set_parallel(true)
	tw.tween_property(d, "global_position", to, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(d, "size", Vector2(DIE, DIE), 0.32)
	await tw.finished
	d.queue_free()
	_sfx("keep", 0.06)
	_buzz(15)
	_refresh()
	done.call()


## A skull: the Master starts, with a flash of red.
func _flinch() -> void:
	var tw := create_tween()
	tw.tween_property(master, "scale", Vector2(1.05, 0.96), 0.08)
	tw.tween_property(master, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var tc := create_tween()
	tc.tween_property(master, "modulate", Color(1.35, 0.7, 0.65), 0.06)
	tc.tween_property(master, "modulate", Color.WHITE, 0.45)


## A bust: the Master's shoulders shake with laughter.
func _laugh() -> void:
	var y0: float = master.get_meta("p0").y
	var tw := create_tween()
	for k in 6:
		tw.tween_property(master, "position:y", y0 - 12.0, 0.08)
		tw.tween_property(master, "position:y", y0, 0.08)


## A paid row: a nod for a small hand, a start for three of a kind, a stagger and a flash of gold for the grand ones.
func _react(big: int) -> void:
	var p0: Vector2 = master.get_meta("p0")
	var tw := create_tween()
	match big:
		0:
			tw.tween_property(master, "position:y", p0.y + 8.0, 0.15)
			tw.tween_property(master, "position:y", p0.y, 0.3)
		1:
			tw.tween_property(master, "scale", Vector2(0.95, 1.03), 0.1)
			tw.tween_property(master, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		_:
			for k in 5:
				tw.tween_property(master, "position:x", p0.x + (14.0 if k % 2 == 0 else -14.0), 0.05)
			tw.tween_property(master, "position:x", p0.x, 0.06)
			var flash := ColorRect.new()
			flash.color = Color(GOLD, 0.0)
			flash.set_anchors_preset(Control.PRESET_FULL_RECT)
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fx.add_child(flash)
			var tf := create_tween()
			tf.tween_property(flash, "color:a", 0.35, 0.08)
			tf.tween_property(flash, "color:a", 0.0, 0.6)
			tf.tween_callback(flash.queue_free)
			_shake()


func _pulse(c: Control) -> void:
	c.pivot_offset = c.size / 2.0
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector2(1.25, 1.25), 0.06)
	tw.tween_property(c, "scale", Vector2.ONE, 0.18)


func _shake() -> void:
	var p0 := stage.position
	var tw := create_tween()
	for k in 4:
		tw.tween_property(stage, "position", p0 + Vector2(randf_range(-12, 12), randf_range(-6, 6)), 0.04)
	tw.tween_property(stage, "position", p0, 0.05)


## Both candle pictures are drawn at one scale with their bottoms on the table, so the wax lines up.
func _set_candle(k: int, lit: bool) -> void:
	var c: TextureRect = candles[k]
	c.texture = CANDLE_LIT if lit else CANDLE_OUT
	var sz: Vector2 = c.texture.get_size() * (CANDLE_H / CANDLE_LIT.get_size().y)
	c.size = sz
	c.position = Vector2(c.get_meta("x") - sz.x / 2.0, c.get_meta("base") - sz.y)
	if k < glows.size():
		glows[k].visible = lit


# ---------- sound and touch ----------

func _sfx(name: String, vary := 0.05, db := 0.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = SFX[name]
	p.pitch_scale = 1.0 + randf_range(-vary, vary)
	p.volume_db = db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _buzz(ms: int) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


# ---------- the tutorial ----------

func _tut_sync() -> void:
	if tut == null:
		return
	while not tut.done() and tut.step().type == "card":
		var st: Dictionary = tut.step()
		tut.advance()
		var then := func():
			if st.get("open", false):
				_open_sin(OPEN_READ)
			_tut_sync()
		_card(st.title, st.text, "Got it", then, "Skip the lessons" if st.get("skip", false) else "",
			func(): _end_tutorial(false), 0, SEAL_CHOOSE, hand_ranking() if st.get("body", "") == "ranking" else null)
		return
	_refresh()


func _tut_msg() -> String:
	if tut == null or tut.done():
		return ""
	return tut.step().get("msg", "")


# ---------- drawing ----------

func _refresh() -> void:
	if s == null:
		return
	if not counting:
		marks_label.text = "%d" % total
	bag_label.text = "%d" % s.bag
	var f: Font = bag_label.get_theme_font("font")
	var fs := bag_label.get_theme_font_size("font_size")
	bag_words.position.x = bag_label.position.x + f.get_string_size(bag_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + f.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	# the row, sorted so matches sit together
	var shown := shown_row()
	for j in row_dice.size():
		var d: TextureRect = row_dice[j]
		if j < shown.size():
			var wl: Label = d.get_child(0)
			var paid_as: int = Rules.total(cfg, s.row, s.bank).wild_as if shown[j] == 0 and s.over and not s.busted else 0
			d.texture = DICE[paid_as if paid_as > 0 else shown[j]]
			d.modulate = Color.WHITE
			d.visible = true
			wl.visible = shown[j] == 0
			# on the blank die WILD fills the face; under the face it was paid as it sits below the die, where the
			# hint was (the hint is empty once the hand is over), so it never covers a pip
			wl.position = Vector2(0, DIE + 6) if paid_as > 0 else Vector2.ZERO
			wl.size = Vector2(DIE, 40) if paid_as > 0 else Vector2(DIE, DIE)
			wl.add_theme_font_size_override("font_size", 30 if paid_as > 0 else 34)
			wl.add_theme_color_override("font_color", GOLD if paid_as > 0 else Color("b8860b"))
		elif j == s.row.size() and selected >= 0 and phase == "keep":
			d.texture = DICE[s.thrown[selected]]
			d.modulate = Color(1, 1, 1, 0.5)
			d.visible = true
			d.get_child(0).visible = false
		else:
			d.visible = false
	hint.text = next_hint() if phase != "over" else ""
	# the hand's name, or what the picked die would make
	var paid: Dictionary
	if phase == "keep" and selected >= 0:
		paid = Rules.preview_total(s, selected)
		ribbon_label.text = "%s · %d" % [paid.name, paid.marks]
		ribbon_if.visible = true
	else:
		paid = Rules.total(cfg, s.row, s.bank)
		ribbon_label.text = "%s · %d" % [paid.name, paid.marks] if not s.row.is_empty() else "Your row"
		if phase == "over" and s.busted:
			ribbon_label.text = "Nothing paid"
		ribbon_if.visible = false
	# what the Sin pays for that row, beside the hand
	var owed: bool = demand_line() != "" and not (phase == "over" and s.busted) and (not s.row.is_empty() or ribbon_if.visible or paid.sin != 0)
	sin_label.visible = owed
	sin_plus.visible = owed
	if owed:
		sin_plus.text = "+" if paid.sin >= 0 else "−"
		sin_label.text = "%s · %d" % [sin_name(), absi(paid.sin)]
		for l in [sin_plus, sin_label]:
			l.add_theme_color_override("font_color", INK if paid.sin >= 0 else BLOOD)
	for l in [ribbon_label, sin_plus, sin_label]:
		l.add_theme_font_size_override("font_size", 42 if owed else 56)
	demand_label.text = demand_line()
	# the largest size, from 40 px down, at which the line ends left of the candles
	var room: float = candles[0].get_meta("x") - 60.0 - demand_label.position.x
	for px in [40, 38, 36, 34, 32, 30]:
		demand_label.add_theme_font_size_override("font_size", px)
		if demand_width() <= room:
			break
	# tray dice: lift the picked one, dim skulls
	if phase != "over":
		for j in tray_dice.size():
			var d: TextureRect = tray_dice[j]
			if not is_instance_valid(d):
				continue
			var face: int = s.last_faces[j] if j < s.last_faces.size() else 2
			var picked := phase == "keep" and selected >= 0 and _tray_index_of(selected) == j
			d.modulate = Color(1, 1, 1, 1) if face > int(cfg.skull_faces) else Color(0.85, 0.75, 0.75)
			d.scale = Vector2(1.08, 1.08) if picked else Vector2.ONE
	if phase != "over":
		banner.visible = false
	# the seals, or Keep, or Next hand
	var opts := Rules.draw_options(s) if phase == "throw" else []
	var dance := Rules.is_dance(s) and phase == "throw"
	seal_box.visible = phase == "throw" or phase == "anim"
	keep_box.visible = phase == "keep"
	next_box.visible = phase == "over" and banner.visible
	for n in range(1, 4):
		var sd: Dictionary = seals[n - 1]
		var ok: bool = n in opts
		if tut != null and not tut.done() and tut.step().type == "throw":
			ok = ok and tut.step().n == n
		sd.box.visible = not dance or n == 1
		sd.btn.disabled = not ok
		sd.btn.modulate = Color.WHITE if ok else Color(0.45, 0.4, 0.4)
		var label := "%d %s" % [n, "die" if n == 1 else "dice"]
		if dance:
			label = "The Last Dance"
		var odds := ""
		var p := 0.0
		if n > s.bag:
			odds = "only %d in the bag" % s.bag
		else:
			p = Rules.bust_chance(s, n)
			if p <= 0.0:
				odds = "no risk"
			elif p < 0.01:
				odds = "under 1% to lose it"
			else:
				odds = "%d%% to lose it" % roundi(100.0 * p)
		var pays: int = Rules.throw_pays(s, n) if ok else 0
		sd.pay.visible = pays > 0
		sd.pay.text = marks_text(pays)
		sd.cap.text = label
		sd.odds.text = odds
		sd.odds.add_theme_color_override("font_color", risk_color(p))
	if phase == "keep" and selected >= 0:
		keep_cap.text = "Keep the %d" % s.thrown[selected]
		keep_btn.disabled = false
		keep_btn.modulate = Color.WHITE
	else:
		keep_cap.text = "Pick a die"
		keep_btn.disabled = true
		keep_btn.modulate = Color(0.45, 0.4, 0.4)
	# the message
	var m := _tut_msg()
	if m == "":
		match phase:
			"throw":
				if Rules.is_dance(s):
					m = "One die left: the Last Dance. It counts as any number; a skull loses the hand."
				elif Rules.throw_pays(s, 1) > 0:
					m = "Two skulls show: %s pays %d for each die you roll now." % [sin_name(), Rules.throw_pays(s, 1)]
				elif s.thrown.is_empty() and s.throws > 0 and s.row.size() == 0 and s.skulls > 0 and s.last_faces.size() > 0 and s.last_faces.max() <= int(cfg.skull_faces):
					m = "Nothing but skulls. Roll again."
				else:
					var o: Array = Rules.draw_options(s)
					var said: String = " or ".join(o.map(func(x): return str(x))) if o.size() <= 2 else "1, 2 or 3"
					m = "Roll %s %s. Keep one; the rest go back into the bag." % [said, "die" if o == [1] else "dice"]
			"keep":
				m = "Tap a die to see what it makes; tap again or Keep." if selected < 0 else "Keep it, or tap another die."
			"over":
				m = ""
	msg.text = m


## The colour of a risk: ivory when there is next to none, then from pale amber to deep red as it grows.
func risk_color(p: float) -> Color:
	if p < 0.01:
		return IVORY
	return Color("f3d9a6").lerp(Color("ff3b2e"), clampf((p - 0.01) / 0.4, 0.0, 1.0))


## The row as shown: the most-matched faces first, then the higher; the wild die last.
func shown_row() -> Array:
	var r: Array = s.row.duplicate()
	r.sort_custom(func(a, b):
		if (a == 0) != (b == 0):
			return b == 0
		var ca: int = s.row.count(a)
		var cb: int = s.row.count(b)
		return ca > cb if ca != cb else a > b)
	return r


## What one more die would make at best ("One more 4: Three and a pair · 5"), or "" when no die improves the row.
## A die is judged by what the row would pay in all, the hand and the Sin together, so under Pride a second 6
## is not offered; where the die changes the Sin's pay the hint says so ("One more 6: Pride +4").
func next_hint() -> String:
	var row: Array = s.row.duplicate()
	if phase == "keep" and selected >= 0:
		row.append(s.thrown[selected])   # count the picked die, as the ribbon does
	if row.is_empty() or row.size() >= int(cfg.row):
		return ""
	var sin0: int = Rules.sin_marks(cfg, row, s.bank)
	# three or four dice, all different: the straight is the hand in play, so name the faces it still needs
	if row.size() >= 3 and not 0 in row:
		var missing: Array = []
		var full: Array = row.duplicate()
		for f in range(int(cfg.skull_faces) + 1, 7):
			if not f in row:
				missing.append(str(f))
				full.append(f)
		if missing.size() == int(cfg.row) - row.size():
			return "Needs %s: %s · %d%s" % [" and ".join(missing), Rules.HANDS[4], Rules.pay(cfg, 4),
				_sin_change(Rules.sin_marks(cfg, full, s.bank) - sin0, ", ")]
	var now: Dictionary = Rules.score(cfg, row)
	var best := {}
	var best_all: int = now.marks + sin0
	var best_sin := 0
	var bf := 0
	for f in range(int(cfg.skull_faces) + 1, 7):
		var sc: Dictionary = Rules.score(cfg, row + [f])
		var sin: int = Rules.sin_marks(cfg, row + [f], s.bank)
		var all: int = sc.marks + sin
		if all > best_all or (not best.is_empty() and all == best_all and sc.hand > best.hand):
			best = sc
			best_all = all
			best_sin = sin
			bf = f
	if best.is_empty():
		return ""
	if best.marks > now.marks:
		return "One more %d: %s · %d%s" % [bf, best.name, best.marks, _sin_change(best_sin - sin0, ", ")]
	return "One more %d: %s" % [bf, _sin_change(best_sin - sin0, "")]


## The Sin's name and what a die would add to or take from its pay ("Pride +4"), after lead; "" for no change.
func _sin_change(m: int, lead: String) -> String:
	return "" if m == 0 else "%s%s %s" % [lead, sin_name(), marks_text(m)]


## This hand's Sin: its window on the wall, its colour on the wall and the table edge.
func _set_sin() -> void:
	var sin: String = SINS[sin_i]
	window.texture = load("res://assets/art/runtime/sins/%s_window.png" % sin)
	spill.modulate = Color(SIN_LIGHT[sin], 0.42)


func sin_name() -> String:
	return SINS[sin_i].capitalize()


## The width of the demand line as drawn on the table edge, in pixels.
func demand_width() -> float:
	return demand_label.get_theme_font("font").get_string_size(demand_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		demand_label.get_theme_font_size("font_size")).x


## The hosting Sin's demand in words, or "" when it demands nothing.
func demand_line() -> String:
	return Demands.of(cfg).get("line", "")


## The Sin's window fills the screen for a beat, then settles into its place on the wall. A tap ends it.
func _open_sin(hold := OPEN_TIME) -> void:
	_end_opening()
	open_hold = hold
	opener_glass.texture = window.texture
	opener_name.text = sin_name()
	opener_line.text = demand_line()
	var vp := get_viewport_rect().size
	var big := Vector2(vp.x * 0.86, vp.x * 0.86 * 820.0 / 640.0)
	opener_glass.size = big
	opener_glass.position = (vp - big) / 2.0 - Vector2(0, 60)
	opener_name.position = Vector2(0, opener_glass.position.y + big.y + 10)
	opener_name.size = Vector2(vp.x, 120)
	opener_line.position = Vector2(60, opener_name.position.y + 130)
	opener_line.size = Vector2(vp.x - 120, 120)
	opener.modulate.a = 0.0
	opener_name.modulate.a = 1.0
	opener_line.modulate.a = 1.0
	opener.visible = true
	window.modulate.a = 0.0
	var from := Rect2(opener_glass.position, big)
	opening = create_tween()
	opening.tween_property(opener, "modulate:a", 1.0, 0.15)
	opening.tween_interval(hold - 0.55)
	opening.tween_property(opener_line, "modulate:a", 0.0, 0.12)
	opening.parallel().tween_property(opener_name, "modulate:a", 0.0, 0.12)
	# the window's place is read as the glass flies, so a layout still settling cannot misplace it
	opening.tween_method(func(t: float):
		var to := window.get_global_rect()
		opener_glass.position = from.position.lerp(to.position, t)
		opener_glass.size = from.size.lerp(to.size, t), 0.0, 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	opening.tween_callback(_end_opening)


func _end_opening() -> void:
	if opening != null and opening.is_valid():
		opening.kill()
	opening = null
	if opener != null:
		opener.visible = false
	if window != null:
		window.modulate.a = 1.0


func _on_opener_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_end_opening()


func _clear_tray() -> void:
	for d in tray_dice:
		if is_instance_valid(d):
			d.queue_free()
	tray_dice.clear()


func _die_node(face: int, size_px: int) -> TextureRect:
	var d := TextureRect.new()
	d.texture = DICE[face]
	d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	d.size = Vector2(size_px, size_px)
	d.pivot_offset = Vector2(size_px, size_px) / 2.0
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


func _gradient(stops: Array, radial := false) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(stops.map(func(x): return x[0]))
	g.colors = PackedColorArray(stops.map(func(x): return x[1]))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 256
	if radial:
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.45)
		t.fill_to = Vector2(1.15, 0.45)
	else:
		t.fill_from = Vector2(0, 0)
		t.fill_to = Vector2(0, 1)
	return t


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font = serif
	th.default_font_size = 34
	th.set_color("font_color", "Label", IVORY)
	theme = th
	# the table, seen from your chair, and the dark wall behind the Master
	var bg := TextureRect.new()
	bg.texture = TABLE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(0.86, 0.72, 0.6)
	add_child(bg)
	wall = TextureRect.new()
	wall.texture = _gradient([[0.0, Color("060303")], [0.7, Color("1a0e09")], [1.0, Color("2a170d")]])
	wall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wall)
	var vignette := TextureRect.new()
	vignette.texture = _gradient([[0.0, Color(0, 0, 0, 0)], [0.6, Color(0, 0, 0, 0.05)], [1.0, Color(0, 0, 0, 0.55)]], true)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var top := 30
	var bottom := 24
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if screen.y > 0 and safe.size.y > 0:
		var k := get_viewport_rect().size.y / float(screen.y)
		top = maxi(top, int(safe.position.y * k) + 8)
		bottom = maxi(bottom, int((screen.y - safe.end.y) * k) + 8)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	add_child(margin)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	margin.add_child(v)

	v.add_child(_centered(_top_bar()))
	v.add_child(_spacer())
	v.add_child(_centered(_stage()))
	v.add_child(_centered(_message()))
	v.add_child(_spacer())
	v.add_child(_centered(_tray()))
	v.add_child(_spacer())
	v.add_child(_centered(_ribbon()))
	v.add_child(_centered(_row()))
	hint = _label("", serif, 34, GOLD)
	hint.custom_minimum_size = Vector2(W, 52)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_centered(hint))
	v.add_child(_spacer())
	v.add_child(_centered(_seals()))

	fx = Control.new()
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx)
	_build_opener()
	_build_overlay()


func _build_opener() -> void:
	opener = Control.new()
	opener.set_anchors_preset(Control.PRESET_FULL_RECT)
	opener.mouse_filter = Control.MOUSE_FILTER_STOP
	opener.gui_input.connect(_on_opener_input)
	opener.visible = false
	add_child(opener)
	var dim := TextureRect.new()
	dim.texture = _gradient([[0.0, Color(0, 0, 0, 0.45)], [0.32, Color(0, 0, 0, 0.5)], [0.42, Color(0, 0, 0, 0.88)], [1.0, Color(0, 0, 0, 0.9)]])
	dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opener.add_child(dim)
	opener_glass = TextureRect.new()
	opener_glass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	opener_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opener.add_child(opener_glass)
	opener_name = _label("", blackletter, 110, GOLD)
	opener_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opener_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opener.add_child(opener_name)
	opener_line = _label("", serif, 46)
	opener_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opener_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opener_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opener.add_child(opener_line)


func _centered(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc


func _spacer() -> Control:
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.custom_minimum_size = Vector2(0, 6)
	return sp


func _label(text: String, font: Font, size_px: int, color := IVORY) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)
	return l


func _top_bar() -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(W, 96)
	coins_icon = TextureRect.new()
	coins_icon.texture = COINS
	coins_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coins_icon.size = Vector2(72, 72)
	coins_icon.position = Vector2(10, 12)
	bar.add_child(coins_icon)
	marks_label = _label("0", caps_bold, 50, GOLD)
	marks_label.position = Vector2(92, 12)
	bar.add_child(marks_label)
	var mk := _label("marks", serif, 32)
	mk.position = Vector2(94, 62)
	bar.add_child(mk)
	var bi := TextureRect.new()
	bi.texture = BAG_ICON
	bi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bi.size = Vector2(60, 66)
	bi.position = Vector2(W / 2.0 - 150, 14)
	bar.add_child(bi)
	bag_label = _label("7", caps_bold, 38)
	bag_label.position = Vector2(W / 2.0 - 80, 24)
	bar.add_child(bag_label)
	bag_words = _label("in the bag", caps_bold, 38)
	bag_words.position = Vector2(W / 2.0 - 50, 24)
	bar.add_child(bag_words)
	var help := TextureButton.new()
	help.texture_normal = SEAL_SMALL
	help.texture_pressed = SEAL_SMALL_DOWN
	help.ignore_texture_size = true
	help.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	help.size = Vector2(92, 92)
	help.position = Vector2(W - 100, 2)
	help.pressed.connect(_on_help)
	bar.add_child(help)
	var q := _label("?", blackletter, 60, GOLD)
	q.size = Vector2(92, 92)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	help.add_child(q)
	return bar


## The Master plays his fiddle behind the far edge of the table; three candles stand on it, one per skull.
func _stage() -> Control:
	stage = Control.new()
	stage.custom_minimum_size = Vector2(W, EDGE_Y + 110)
	stage.clip_contents = false
	# the Sin's light on the wall and the table edge, kept inside the stage (off the mat and the text)
	var light := Control.new()
	light.clip_contents = true
	# cut only at the bottom: it reaches up behind the top bar and out past both sides (a wide screen shows the wall there)
	light.size = Vector2(W + 60 + 2 * LIGHT_PAD, EDGE_Y + 110 + 400)
	light.position = Vector2(-30 - LIGHT_PAD, -400)
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(light)
	var add_light := CanvasItemMaterial.new()
	add_light.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spill = TextureRect.new()
	spill.texture = GLOW
	spill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spill.size = Vector2(900, 900)
	spill.position = Vector2(LIGHT_PAD + 30 + 167 - 450, 400 + 194 - 450)
	spill.material = add_light
	spill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	light.add_child(spill)
	window = TextureRect.new()
	window.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	window.size = Vector2(290, 372)
	window.position = Vector2(22, EDGE_Y - 40 - 372)
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(window)
	var sill := ColorRect.new()
	sill.color = Color("4e4238")
	sill.size = Vector2(326, 14)
	sill.position = Vector2(4, EDGE_Y - 42)
	sill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(sill)
	var sill_lip := ColorRect.new()
	sill_lip.color = Color(0.78, 0.63, 0.35, 0.8)
	sill_lip.size = Vector2(326, 2)
	sill_lip.position = Vector2(4, EDGE_Y - 42)
	sill_lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(sill_lip)
	var sill_shadow := ColorRect.new()
	sill_shadow.color = Color(0, 0, 0, 0.45)
	sill_shadow.size = Vector2(326, 6)
	sill_shadow.position = Vector2(4, EDGE_Y - 28)
	sill_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(sill_shadow)
	master = TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = IDLE
	at.region = Rect2(0, 0, 640, 640)
	master.texture = at
	master.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	master.size = Vector2(500, 500)
	master.position = Vector2(334, EDGE_Y + 84 - 500)
	master.pivot_offset = Vector2(250, 500)
	master.set_meta("p0", master.position)
	stage.add_child(master)
	var edge := TextureRect.new()
	edge.texture = EDGE
	edge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	edge.size = Vector2(W + 600, 110)
	edge.position = Vector2(-300, EDGE_Y)
	stage.add_child(edge)
	demand_label = _label("", caps_bold, 40)   # Cinzel bold: the hand's rule, with lining digits
	demand_label.size = Vector2(800, 56)
	demand_label.position = Vector2(10, EDGE_Y + 30)
	demand_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(demand_label)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for k in 3:
		var x: float = [872.0, 932.0, 992.0][k]   # together at his right, past the fiddle's scroll, off the window
		var base := EDGE_Y + 60.0
		var sh := TextureRect.new()
		sh.texture = SOFT
		sh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sh.size = Vector2(96, 26)
		sh.position = Vector2(x - 44, base - 14)
		sh.modulate = Color(0, 0, 0, 0.8)
		stage.add_child(sh)
		var c := TextureRect.new()
		c.texture = CANDLE_LIT
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.set_meta("x", x)
		c.set_meta("base", base)
		stage.add_child(c)
		candles.append(c)
		var g := TextureRect.new()
		g.texture = GLOW
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.size = Vector2(300, 300)
		g.position = Vector2(x - 150, base - CANDLE_H + 26 - 150)
		g.material = add
		g.modulate = Color(1.0, 0.62, 0.28, 0.5)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(g)
		glows.append(g)
		_set_candle(k, true)
	return stage


func _message() -> Control:
	msg = _label("", serif, 36)
	msg.custom_minimum_size = Vector2(W - 40, 100)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return msg


## The leather mat the dice land on; the result banner comes down over it when the hand ends.
func _tray() -> Control:
	tray = Control.new()
	tray.custom_minimum_size = Vector2(W - 20, 360)
	# candlelight pooled on the table around the mat
	var pool := TextureRect.new()
	pool.texture = GLOW
	pool.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pool.size = Vector2(1500, 900)
	pool.position = Vector2((W - 20 - 1500) / 2.0, 180 - 450)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	pool.material = add
	pool.modulate = Color(1.0, 0.6, 0.3, 0.16)
	pool.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(pool)
	var shadow := Panel.new()
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color(0, 0, 0, 0.35)
	ssb.set_corner_radius_all(34)
	ssb.shadow_color = Color(0, 0, 0, 0.55)
	ssb.shadow_size = 22
	ssb.shadow_offset = Vector2(0, 10)
	shadow.add_theme_stylebox_override("panel", ssb)
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(shadow)
	var t := TextureRect.new()
	t.texture = MAT
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(t)
	tray.mouse_filter = Control.MOUSE_FILTER_STOP
	tray.gui_input.connect(_on_tray_input)
	# the result banner (moved above the dice when it is shown)
	banner = Control.new()
	banner.size = Vector2(W - 20, 360)
	banner.pivot_offset = banner.size / 2.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.visible = false
	tray.add_child(banner)
	var bt := NinePatchRect.new()
	bt.texture = PLATE
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		bt.set_patch_margin(side, 40)
	bt.size = Vector2(760, 170)
	bt.position = Vector2((W - 20 - 760) / 2.0, 46)
	banner.add_child(bt)
	banner_title = _label("", blackletter, 60)
	banner_title.size = Vector2(680, 170)
	banner_title.position = Vector2((W - 20 - 680) / 2.0, 42)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.add_child(banner_title)
	banner_text = _label("", serif, 34)
	banner_text.size = Vector2(W - 140, 120)
	banner_text.position = Vector2(60, 226)
	banner_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.add_child(banner_text)
	return tray


## Touch arrives as an emulated mouse press, so only mouse buttons are handled (no double taps).
func _on_tray_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		tap_tray(e.position.x)


## A tap at x in the tray picks the pip die drawn nearest it (within half a die's spacing).
func tap_tray(x: float) -> void:
	if phase != "keep":
		return
	var n: int = s.last_faces.size()
	var best := -1
	var bd := 1e9
	for j in n:
		var cx := tray_x(j)
		if s.last_faces[j] > int(cfg.skull_faces) and absf(x - cx) < bd:
			bd = absf(x - cx)
			best = j
	if best < 0 or bd >= (TDIE + 40) / 2.0:
		return
	var pip := -1
	for j in best + 1:
		if s.last_faces[j] > int(cfg.skull_faces):
			pip += 1
	_on_die(pip)


## The x in the tray where thrown face j sits (tests tap here).
func tray_x(j: int) -> float:
	var n: int = s.last_faces.size()
	return tray.size.x / 2.0 + (j - (n - 1) / 2.0) * (TDIE + 40)


func _ribbon() -> Control:
	var r := TextureRect.new()
	r.texture = RIBBON
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.custom_minimum_size = Vector2(760, 176)
	var line := HBoxContainer.new()
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	line.offset_top = 44
	line.offset_bottom = -26
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 18)
	r.add_child(line)
	ribbon_label = _label("Your row", blackletter, 56, INK)
	sin_plus = _label("+", blackletter, 56, INK)
	sin_label = _label("", blackletter, 56, INK)
	for l in [ribbon_label, sin_plus, sin_label]:
		l.remove_theme_color_override("font_shadow_color")
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size_flags_vertical = Control.SIZE_EXPAND_FILL
		line.add_child(l)
	sin_plus.visible = false
	sin_label.visible = false
	ribbon_if = _label("if kept", serif, 28, INK)   # the ghost die in the row shows which one
	ribbon_if.remove_theme_color_override("font_shadow_color")
	ribbon_if.set_anchors_preset(Control.PRESET_FULL_RECT)
	ribbon_if.offset_top = 14
	ribbon_if.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon_if.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	ribbon_if.visible = false
	r.add_child(ribbon_if)
	return r


func _row() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	for j in int(cfg.row):
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(DIE, DIE)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.05, 0.04, 0.75)
		sb.border_color = Color(GOLD, 0.45)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(26)
		slot.add_theme_stylebox_override("panel", sb)
		h.add_child(slot)
		row_slots.append(slot)
		var d := _die_node(2, DIE)
		d.visible = false
		slot.add_child(d)
		var wl := _label("ANY", caps_bold, 34, Color("b8860b"))
		wl.size = Vector2(DIE, DIE)
		wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		wl.remove_theme_color_override("font_shadow_color")
		wl.visible = false
		d.add_child(wl)
		row_dice.append(d)
	return h


func _seal_button(tex: Texture2D, down: Texture2D, px: int) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = tex
	b.texture_pressed = down
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(px, px)
	b.pivot_offset = Vector2(px, px) / 2.0
	if down == null:
		b.button_down.connect(func(): b.scale = Vector2(0.94, 0.94))
		b.button_up.connect(func(): b.scale = Vector2.ONE)
	return b


func _seals() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(W, 330)
	seal_box = HBoxContainer.new()
	seal_box.add_theme_constant_override("separation", 30)
	seal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	seal_box.size = Vector2(W, 330)
	holder.add_child(seal_box)
	for n in range(1, 4):
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		box.custom_minimum_size = Vector2(310, 0)
		var btn := _seal_button(SEAL, SEAL_DOWN, 220)
		btn.pressed.connect(_on_seal.bind(n))
		var num := TextureRect.new()
		num.texture = NUMERALS[n]
		num.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		num.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		num.size = Vector2(110, 110)
		num.position = Vector2(55, 48)
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(num)
		var pay := _label("", caps_bold, 46, GOLD)
		pay.size = Vector2(90, 56)
		pay.position = Vector2(150, 0)
		pay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pay.visible = false
		btn.add_child(pay)
		var bc := CenterContainer.new()
		bc.add_child(btn)
		box.add_child(bc)
		var cap := _label("", caps_bold, 38)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(cap)
		var odds := _label("", caps_bold, 29)
		odds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(odds)
		seal_box.add_child(box)
		seals.append({"box": box, "btn": btn, "cap": cap, "odds": odds, "pay": pay})
	var kb := VBoxContainer.new()
	kb.size = Vector2(W, 330)
	kb.alignment = BoxContainer.ALIGNMENT_BEGIN
	kb.add_theme_constant_override("separation", 0)
	keep_btn = _seal_button(SEAL, SEAL_DOWN, 240)
	keep_btn.pressed.connect(_on_keep)
	var kl := _label("KEEP", caps_bold, 46, GOLD)
	kl.size = Vector2(240, 240)
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keep_btn.add_child(kl)
	var kc := CenterContainer.new()
	kc.add_child(keep_btn)
	kb.add_child(kc)
	keep_cap = _label("", caps_bold, 38)
	keep_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kb.add_child(keep_cap)
	kb.visible = false
	keep_box = kb
	holder.add_child(kb)
	var nb := VBoxContainer.new()
	nb.size = Vector2(W, 330)
	nb.add_theme_constant_override("separation", 0)
	next_btn = _seal_button(SEAL_THROW, null, 240)
	next_btn.pressed.connect(_on_next)
	var nc := CenterContainer.new()
	nc.add_child(next_btn)
	nb.add_child(nc)
	var ncap := _label("Next hand", caps_bold, 40)
	ncap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nb.add_child(ncap)
	nb.visible = false
	next_box = nb
	holder.add_child(nb)
	return holder


# ---------- cards ----------

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.84)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(cc)
	var page := PanelContainer.new()
	var psb := StyleBoxTexture.new()
	psb.texture = PAGE
	psb.texture_margin_left = 90
	psb.texture_margin_right = 90
	psb.texture_margin_top = 90
	psb.texture_margin_bottom = 90
	psb.content_margin_left = 96
	psb.content_margin_right = 96
	psb.content_margin_top = 80
	psb.content_margin_bottom = 64
	page.add_theme_stylebox_override("panel", psb)
	page.custom_minimum_size = Vector2(980, 0)
	cc.add_child(page)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	page.add_child(v)
	card_title = _label("", blackletter, 64, INK)
	card_title.remove_theme_color_override("font_shadow_color")
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(card_title)
	var fl := TextureRect.new()
	fl.texture = FLEUR
	fl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fl.custom_minimum_size = Vector2(0, 60)
	v.add_child(fl)
	# the body and the text scroll when they are taller than the screen allows, so the buttons never leave it
	card_scroll = ScrollContainer.new()
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(card_scroll)
	card_inner = VBoxContainer.new()
	card_inner.add_theme_constant_override("separation", 22)
	card_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_inner.minimum_size_changed.connect(_fit_card)
	var gutter := MarginContainer.new()   # room for the scroll bar, so it never crosses the pay column
	gutter.add_theme_constant_override("margin_right", 28)
	gutter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_scroll.add_child(gutter)
	gutter.add_child(card_inner)
	card_body = VBoxContainer.new()
	card_inner.add_child(card_body)
	card_text = _label("", serif, 38, INK)
	card_text.remove_theme_color_override("font_shadow_color")
	card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_text.custom_minimum_size = Vector2(752, 0)
	card_inner.add_child(card_text)
	var bc := CenterContainer.new()      # stacked in one column, seals on one left edge
	v.add_child(bc)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 0)
	bc.add_child(buttons)
	card_btn = _card_button()
	card_btn.pressed.connect(_on_card_btn)
	buttons.add_child(card_btn)
	card_alt = _card_button()
	card_alt.pressed.connect(_on_card_alt)
	card_alt.visible = false
	buttons.add_child(card_alt)


## The card's scrolling part is as tall as what it holds, up to what the screen leaves beside the title and buttons.
func _fit_card() -> void:
	var cap: float = maxf(300.0, get_viewport_rect().size.y - CARD_CHROME)
	card_scroll.custom_minimum_size.y = minf(card_inner.get_combined_minimum_size().y, cap)


## A card's button: a wax seal with its words beside it.
func _card_button() -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", caps_bold)
	b.add_theme_font_size_override("font_size", 40)
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, INK)
	b.add_theme_color_override("font_pressed_color", BLOOD)
	b.add_theme_constant_override("icon_max_width", 150)
	b.add_theme_constant_override("h_separation", 18)
	b.custom_minimum_size = Vector2(0, 160)
	b.icon = SEAL_CHOOSE
	b.size_flags_horizontal = Control.SIZE_FILL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.button_down.connect(func(): b.modulate = Color(0.85, 0.75, 0.75))
	b.button_up.connect(func(): b.modulate = Color.WHITE)
	return b


func _card(title: String, text: String, button: String, then: Callable, alt := "", alt_then := Callable(), big := 0,
		icon: Texture2D = SEAL_CHOOSE, body: Control = null) -> void:
	cards.append({"title": title, "text": text, "button": button, "then": then, "alt": alt, "alt_then": alt_then,
		"big": big, "icon": icon, "body": body})
	if not overlay.visible:
		_show_card()


func _show_card() -> void:
	var c: Dictionary = cards[0]
	card_title.text = c.title
	card_title.add_theme_font_size_override("font_size", [64, 76, 92][c.big])
	card_title.add_theme_color_override("font_color", BLOOD if c.big == 2 else INK)
	for k in card_body.get_children():
		card_body.remove_child(k)
		k.queue_free()
	if c.body != null:
		card_body.add_child(c.body)
	card_body.visible = c.body != null
	card_text.text = c.text
	card_text.visible = c.text != ""
	card_btn.text = c.button
	card_btn.icon = c.icon
	card_alt.text = c.alt
	card_alt.icon = SEAL_BOOK
	card_alt.visible = c.alt != ""
	card_scroll.scroll_vertical = 0
	_fit_card()
	overlay.visible = true


func _on_card_btn() -> void:
	_close_card("then")


func _on_card_alt() -> void:
	_close_card("alt_then")


func _close_card(which: String) -> void:
	if cards.is_empty():
		return
	_sfx("press")
	var c: Dictionary = cards.pop_front()
	overlay.visible = false
	if not cards.is_empty():
		_show_card()
	var f: Callable = c[which]
	if f.is_valid():
		f.call()
	_refresh()


## The ? page. It waits for moving dice: Replay the tutorial would clear the tray under a roll still playing.
func _on_help() -> void:
	if overlay.visible or phase == "anim":
		return
	var text := "\n\n".join(RULES)
	if demand_line() != "":
		text = "%s is watching this hand.\n%s\n\n%s" % [sin_name(), demand_line(), text]
	text += "\n\n%s%s" % [Version.VERSION, (" (%s)" % Version.BUILD) if Version.BUILD != "" else ""]
	_card("The hands", text, "Back", Callable(), "Replay the tutorial", func():
		_start_tutorial(), 0, SEAL_BACK, hand_ranking())


## The hands from best to worst, each with what makes it, its dice and its pay, in three columns.
func hand_ranking() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 28)
	g.add_theme_constant_override("v_separation", 8)
	for h in range(Rules.HANDS.size() - 1, 0, -1):
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", -6)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := _label(Rules.HANDS[h], serif, 36, INK)
		nm.remove_theme_color_override("font_shadow_color")
		cell.add_child(nm)
		var note := _label(HAND_NOTES[h], serif, 26, Color(INK, 0.75))
		note.remove_theme_color_override("font_shadow_color")
		cell.add_child(note)
		g.add_child(cell)
		var dice := HBoxContainer.new()
		dice.add_theme_constant_override("separation", 4)
		for f in EXAMPLES[h]:
			var d := TextureRect.new()
			d.texture = DICE[f]
			d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			d.custom_minimum_size = Vector2(54, 54)
			dice.add_child(d)
		g.add_child(dice)
		var pay := _label("%d" % Rules.pay(cfg, h), caps_bold, 42, INK)
		pay.remove_theme_color_override("font_shadow_color")
		pay.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pay.custom_minimum_size = Vector2(60, 0)
		g.add_child(pay)
	return g


# ---------- saving ----------

func _load() -> void:
	var c := ConfigFile.new()
	if c.load(save_path) == OK:
		total = int(c.get_value("dice", "total", 0))
		hands = int(c.get_value("dice", "hands", 0))
		seen = c.get_value("dice", "seen", {})


func _save() -> void:
	var c := ConfigFile.new()
	c.set_value("dice", "total", total)
	c.set_value("dice", "hands", hands)
	c.set_value("dice", "seen", seen)
	c.save(save_path)
