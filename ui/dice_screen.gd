## Dice poker against the Master: the dressed screen (docs/superpowers/specs/2026-11-20-dice-poker-pitch.md, core B).
## Each throw you draw 1, 2 or 3 dice and keep one in your row of five; three skulls bust; a full row is paid.
extends Control

const Rules = preload("res://dice/rules.gd")
const Config = preload("res://dice/config.gd")
const Tutorial = preload("res://ui/dice_tutorial.gd")
const Version = preload("res://ui/version.gd")

const BLACKLETTER := preload("res://assets/fonts/PirataOne-Regular.ttf")
const SERIF := preload("res://assets/fonts/IMFellEnglish-Regular.ttf")
const CINZEL := preload("res://assets/fonts/Cinzel.ttf")

const DICE := {
	0: preload("res://assets/art/runtime/dice/blank.png"),
	1: preload("res://assets/art/runtime/dice/skull.png"),
	2: preload("res://assets/art/runtime/dice/2.png"),
	3: preload("res://assets/art/runtime/dice/3.png"),
	4: preload("res://assets/art/runtime/dice/4.png"),
	5: preload("res://assets/art/runtime/dice/5.png"),
	6: preload("res://assets/art/runtime/dice/6.png"),
}
const BG := preload("res://assets/art/runtime/bg.png")
const MASTER := preload("res://assets/art/runtime/table/master_bust.png")
const JAW := preload("res://assets/art/runtime/table/master_jaw.png")
const CANDLE_LIT := preload("res://assets/art/runtime/table/candle_lit.png")
const CANDLE_OUT := preload("res://assets/art/runtime/table/candle_out.png")
const TRAY := preload("res://assets/art/ui/dice_tray.png")
const RIBBON := preload("res://assets/art/ui/label_ribbon.png")
const SEAL := preload("res://assets/art/runtime/seals/normal.png")
const SEAL_DOWN := preload("res://assets/art/runtime/seals/pressed.png")
const SEAL_SMALL := preload("res://assets/art/ui/seal_small_normal.png")
const SEAL_SMALL_DOWN := preload("res://assets/art/ui/seal_small_pressed.png")
const NUMERALS := [null, preload("res://assets/art/runtime/seals/n1.png"),
	preload("res://assets/art/runtime/seals/n2.png"), preload("res://assets/art/runtime/seals/n3.png")]
const PAGE := preload("res://assets/art/runtime/page.png")
const COINS := preload("res://assets/art/ui/icon_coins.png")
const BAG_ICON := preload("res://assets/art/ui/icon_die.png")
const FLEUR := preload("res://assets/art/ui/divider_fleur.png")
const SINS := ["pride", "greed", "lust", "envy", "gluttony", "wrath", "sloth"]

const IVORY := Color("efe3c8")
const GOLD := Color("e8c06a")
const INK := Color("3a1f12")
const BLOOD := Color("9e1b1b")

const W := 1020          # content width
const DIE := 176         # die size in the row
const TDIE := 196        # die size in the tray

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
var cards: Array = []     # [{title, text, button, then}]

# nodes
var marks_label: Label
var bag_label: Label
var stage: Control
var master: TextureRect
var jaw: TextureRect
var windows: Array = []
var candles: Array = []
var msg: Label
var tray: Control
var tray_dice: Array = []
var ribbon_label: Label
var hint: Label
var row_slots: Array = []
var row_dice: Array = []
var seals: Array = []       # [{btn, cap}]
var seal_box: HBoxContainer
var keep_btn: TextureButton
var keep_box: Control
var keep_cap: Label
var overlay: Control
var card_title: Label
var card_text: Label
var card_btn: Button
var card_alt: Button
var fx: Control


func _ready() -> void:
	_load()
	_build()
	if not seen.get("tutorial", false):
		_start_tutorial()
	else:
		_new_hand()


# ---------- the hand ----------

func _new_hand(rng = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	s = Rules.new_hand(cfg, rng)
	selected = -1
	phase = "throw"
	sin_i = hands % SINS.size()
	_set_windows()
	for c in candles:
		c.texture = CANDLE_LIT
	_clear_tray()
	_refresh()


func _start_tutorial() -> void:
	tut = Tutorial.new()
	_new_hand(Tutorial.rng())
	_tut_sync()


func _on_seal(n: int) -> void:
	if phase != "throw" or overlay.visible or not n in Rules.draw_options(s):
		return
	if tut != null and not tut.done():
		var st: Dictionary = tut.step()
		if st.type != "throw" or st.n != n:
			return
		tut.advance()
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


func _end() -> void:
	phase = "over"
	hands += 1
	total += s.marks
	_save()
	_refresh()
	if s.busted:
		_laugh()
	await get_tree().create_timer(1.6).timeout   # let the bust or the last die be seen first
	var title := ""
	var text := ""
	if s.busted:
		title = "The Master takes the hand"
		text = "Three skulls. The hand pays nothing." if s.skulls >= int(cfg.bust_at) else "A skull on the Last Dance. The hand pays nothing."
	else:
		var sc: Dictionary = Rules.score(cfg, s.row)
		title = "%s: %d mark%s" % [sc.name, sc.marks, "" if sc.marks == 1 else "s"]
		text = "Your row is full, and it is paid.\n\nYou have %d marks in all." % total
	var then := func():
		if tut != null:
			tut = null
			seen["tutorial"] = true
			_save()
		_new_hand()
	_card(title, text, "Next hand", then, "", Callable(), _big(s))


## How grand the result card is: 0 for a bust or a small hand, 1 for three of a kind, 2 for a straight or better.
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
	var faces: Array = s.last_faces
	var tw := create_tween().set_parallel(true)
	var n := faces.size()
	for j in n:
		var d := _die_node(faces[j], TDIE)
		var x := tray_x(j) - TDIE / 2.0
		var y := tray.size.y / 2.0 - TDIE / 2.0
		d.position = Vector2(x, y + 260)
		d.scale = Vector2(0.3, 0.3)
		d.rotation = randf_range(-2.5, 2.5)
		d.modulate.a = 0.0
		tray.add_child(d)
		tray_dice.append(d)
		var delay := 0.07 * j
		tw.tween_property(d, "position", Vector2(x, y), 0.38).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "scale", Vector2.ONE, 0.38).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "rotation", 0.0, 0.38).set_delay(delay).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "modulate:a", 1.0, 0.15).set_delay(delay)
	await tw.finished
	if s.skulls > skulls0:
		for k in range(skulls0, mini(s.skulls, candles.size())):
			candles[k].texture = CANDLE_OUT
		_jaw_drop()
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
	_refresh()
	done.call()


func _jaw_drop() -> void:
	var tw := create_tween()
	tw.tween_property(jaw, "position:y", jaw.get_meta("y0") + 26.0, 0.12)
	tw.tween_property(jaw, "position:y", jaw.get_meta("y0"), 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _laugh() -> void:
	var tw := create_tween()
	for k in 5:
		tw.tween_property(jaw, "position:y", jaw.get_meta("y0") + 22.0, 0.09)
		tw.tween_property(jaw, "position:y", jaw.get_meta("y0"), 0.09)


func _shake() -> void:
	var p0 := stage.position
	var tw := create_tween()
	for k in 4:
		tw.tween_property(stage, "position", p0 + Vector2(randf_range(-12, 12), randf_range(-6, 6)), 0.04)
	tw.tween_property(stage, "position", p0, 0.05)


# ---------- the tutorial ----------

func _tut_sync() -> void:
	if tut == null:
		return
	while not tut.done() and tut.step().type == "card":
		var st: Dictionary = tut.step()
		tut.advance()
		_card(st.title, st.text, "Got it", func(): _tut_sync())
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
	marks_label.text = "%d" % total
	bag_label.text = "%d in the bag" % s.bag
	# the row, sorted so matches sit together
	var shown := shown_row()
	for j in row_dice.size():
		var d: TextureRect = row_dice[j]
		if j < shown.size():
			d.texture = DICE[shown[j]]
			d.modulate = Color.WHITE
			d.visible = true
			d.get_child(0).visible = shown[j] == 0
		elif j == s.row.size() and selected >= 0 and phase == "keep":
			d.texture = DICE[s.thrown[selected]]
			d.modulate = Color(1, 1, 1, 0.5)
			d.visible = true
			d.get_child(0).visible = false
		else:
			d.visible = false
	hint.text = next_hint() if phase != "over" else ""
	# the hand's name, or what the picked die would make
	if phase == "keep" and selected >= 0:
		var pv: Dictionary = Rules.preview(s, selected)
		ribbon_label.text = "%s · %d" % [pv.name, pv.marks]
		ribbon_label.add_theme_color_override("font_color", BLOOD)
	else:
		var sc: Dictionary = Rules.score(cfg, s.row)
		ribbon_label.text = "%s · %d" % [sc.name, sc.marks] if not s.row.is_empty() else "Your row"
		ribbon_label.add_theme_color_override("font_color", INK)
	# tray dice: lift the picked one, dim skulls
	for j in tray_dice.size():
		var d: TextureRect = tray_dice[j]
		if not is_instance_valid(d):
			continue
		var face: int = s.last_faces[j] if j < s.last_faces.size() else 2
		var picked := phase == "keep" and selected >= 0 and _tray_index_of(selected) == j
		d.modulate = Color(1, 1, 1, 1) if face > int(cfg.skull_faces) else Color(0.85, 0.75, 0.75)
		d.scale = Vector2(1.08, 1.08) if picked else Vector2.ONE
	# the seals
	var opts := Rules.draw_options(s) if phase == "throw" else []
	var dance := Rules.is_dance(s) and phase == "throw"
	seal_box.visible = phase != "keep"
	keep_box.visible = phase == "keep"
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
		sd.cap.text = "%s\n%s" % [label, odds]
		sd.cap.add_theme_color_override("font_color", IVORY if p < 0.01 else (Color("f0a080") if p < 0.2 else Color("ff6a5a")))
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
					m = "One die left: the Last Dance. Any face is wild; a skull loses the hand."
				elif s.thrown.is_empty() and s.throws > 0 and s.row.size() == 0 and s.skulls > 0 and s.last_faces.size() > 0 and s.last_faces.max() <= int(cfg.skull_faces):
					m = "Nothing but skulls. Draw again."
				else:
					var o: Array = Rules.draw_options(s)
					var said: String = " or ".join(o.map(func(x): return str(x))) if o.size() <= 2 else "1, 2 or 3"
					m = "Draw %s %s. You keep one; the rest go back." % [said, "die" if o == [1] else "dice"]
			"keep":
				m = "Tap a die to see what it makes; tap again or Keep." if selected < 0 else "Keep it, or tap another die."
			"over":
				m = ""
	msg.text = m


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


## What one more die would make at best ("One more 4: Full house · 5"), or "" when no die improves the row.
func next_hint() -> String:
	if s.row.is_empty() or s.row.size() >= int(cfg.row):
		return ""
	var now: Dictionary = Rules.score(cfg, s.row)
	var best := {}
	var bf := 0
	for f in range(int(cfg.skull_faces) + 1, 7):
		var sc: Dictionary = Rules.score(cfg, s.row + [f])
		if sc.marks > now.marks and (best.is_empty() or sc.marks > best.marks or (sc.marks == best.marks and sc.hand > best.hand)):
			best = sc
			bf = f
	if best.is_empty():
		return ""
	return "One more %d: %s · %d" % [bf, best.name, best.marks]


func _set_windows() -> void:
	for k in windows.size():
		windows[k].texture = load("res://assets/art/runtime/sins/%s.png" % SINS[(sin_i + k * 3) % SINS.size()])


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


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font = SERIF
	th.default_font_size = 34
	th.set_color("font_color", "Label", IVORY)
	theme = th
	var bg := TextureRect.new()
	bg.texture = BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(0.55, 0.5, 0.48)
	add_child(bg)
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
	hint = _label("", SERIF, 32, GOLD)
	hint.custom_minimum_size = Vector2(W, 48)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_centered(hint))
	v.add_child(_spacer())
	v.add_child(_centered(_seals()))

	fx = Control.new()
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx)
	_build_overlay()


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
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


func _top_bar() -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(W, 96)
	var coins := TextureRect.new()
	coins.texture = COINS
	coins.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coins.size = Vector2(72, 72)
	coins.position = Vector2(10, 12)
	bar.add_child(coins)
	marks_label = _label("0", CINZEL, 46, GOLD)
	marks_label.position = Vector2(92, 18)
	bar.add_child(marks_label)
	var mk := _label("marks", SERIF, 26)
	mk.position = Vector2(92, 64)
	mk.add_theme_font_size_override("font_size", 32)
	bar.add_child(mk)
	var bi := TextureRect.new()
	bi.texture = BAG_ICON
	bi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bi.size = Vector2(60, 66)
	bi.position = Vector2(W / 2.0 - 150, 14)
	bar.add_child(bi)
	bag_label = _label("7 in the bag", CINZEL, 36)
	bag_label.position = Vector2(W / 2.0 - 80, 24)
	bar.add_child(bag_label)
	var help := TextureButton.new()
	help.texture_normal = SEAL_SMALL
	help.texture_pressed = SEAL_SMALL_DOWN
	help.ignore_texture_size = true
	help.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	help.size = Vector2(92, 92)
	help.position = Vector2(W - 100, 2)
	help.pressed.connect(_on_help)
	bar.add_child(help)
	var q := _label("?", BLACKLETTER, 60, GOLD)
	q.size = Vector2(92, 92)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	help.add_child(q)
	return bar


func _stage() -> Control:
	stage = Control.new()
	stage.custom_minimum_size = Vector2(W, 520)
	for k in 2:
		var w := TextureRect.new()
		w.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		w.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		w.size = Vector2(150, 500)
		w.position = Vector2(20 if k == 0 else W - 170, 10)
		w.modulate = Color(0.85, 0.85, 0.9)
		stage.add_child(w)
		windows.append(w)
	master = TextureRect.new()
	master.texture = MASTER
	master.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var ms := 0.82
	master.size = Vector2(656, 546) * ms
	master.position = Vector2((W - master.size.x) / 2.0, 0)
	stage.add_child(master)
	jaw = TextureRect.new()
	jaw.texture = JAW
	jaw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	jaw.size = Vector2(127, 87) * ms
	jaw.position = Vector2(353, 226) * ms
	jaw.set_meta("y0", jaw.position.y)
	master.add_child(jaw)
	for k in 3:
		var c := TextureRect.new()
		c.texture = CANDLE_LIT
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		c.size = Vector2(50, 220)
		c.position = Vector2(W / 2.0 - 25 + (k - 1) * 200, 300)
		stage.add_child(c)
		candles.append(c)
	return stage


func _message() -> Control:
	msg = _label("", SERIF, 34)
	msg.custom_minimum_size = Vector2(W - 40, 100)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return msg


func _tray() -> Control:
	tray = Control.new()
	tray.custom_minimum_size = Vector2(W - 20, 360)
	var t := NinePatchRect.new()
	t.texture = TRAY
	t.patch_margin_left = 60
	t.patch_margin_right = 60
	t.patch_margin_top = 60
	t.patch_margin_bottom = 60
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(t)
	tray.mouse_filter = Control.MOUSE_FILTER_STOP
	tray.gui_input.connect(_on_tray_input)
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
	r.custom_minimum_size = Vector2(760, 140)
	ribbon_label = _label("Your row", BLACKLETTER, 56, INK)
	ribbon_label.remove_theme_color_override("font_shadow_color")
	ribbon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	ribbon_label.offset_bottom = -22
	ribbon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	r.add_child(ribbon_label)
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
		var wl := _label("WILD", CINZEL, 34, Color("b8860b"))
		wl.size = Vector2(DIE, DIE)
		wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		wl.remove_theme_color_override("font_shadow_color")
		wl.visible = false
		d.add_child(wl)
		row_dice.append(d)
	return h


func _seals() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(W, 320)
	seal_box = HBoxContainer.new()
	seal_box.add_theme_constant_override("separation", 30)
	seal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	seal_box.size = Vector2(W, 320)
	holder.add_child(seal_box)
	for n in range(1, 4):
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		box.custom_minimum_size = Vector2(300, 0)
		var btn := TextureButton.new()
		btn.texture_normal = SEAL
		btn.texture_pressed = SEAL_DOWN
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = Vector2(220, 220)
		btn.pressed.connect(_on_seal.bind(n))
		var num := TextureRect.new()
		num.texture = NUMERALS[n]
		num.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		num.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		num.size = Vector2(110, 110)
		num.position = Vector2(55, 48)
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(num)
		var bc := CenterContainer.new()
		bc.add_child(btn)
		box.add_child(bc)
		var cap := _label("", CINZEL, 36)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(cap)
		seal_box.add_child(box)
		seals.append({"box": box, "btn": btn, "cap": cap})
	var kb := VBoxContainer.new()
	kb.size = Vector2(W, 320)
	kb.alignment = BoxContainer.ALIGNMENT_BEGIN
	kb.add_theme_constant_override("separation", 0)
	keep_btn = TextureButton.new()
	keep_btn.texture_normal = SEAL
	keep_btn.texture_pressed = SEAL_DOWN
	keep_btn.ignore_texture_size = true
	keep_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	keep_btn.custom_minimum_size = Vector2(240, 240)
	keep_btn.pressed.connect(_on_keep)
	var kl := _label("KEEP", CINZEL, 44, GOLD)
	kl.size = Vector2(240, 240)
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keep_btn.add_child(kl)
	var kc := CenterContainer.new()
	kc.add_child(keep_btn)
	kb.add_child(kc)
	keep_cap = _label("", CINZEL, 36)
	keep_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kb.add_child(keep_cap)
	kb.visible = false
	keep_box = kb
	holder.add_child(kb)
	return holder


# ---------- cards ----------

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(cc)
	var page := PanelContainer.new()
	var psb := StyleBoxTexture.new()
	psb.texture = PAGE
	psb.texture_margin_left = 200
	psb.texture_margin_right = 200
	psb.texture_margin_top = 200
	psb.texture_margin_bottom = 200
	psb.content_margin_left = 130
	psb.content_margin_right = 130
	psb.content_margin_top = 215
	psb.content_margin_bottom = 180
	page.add_theme_stylebox_override("panel", psb)
	page.custom_minimum_size = Vector2(980, 0)
	cc.add_child(page)
	var pm := VBoxContainer.new()
	page.add_child(pm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	pm.add_child(v)
	card_title = _label("", BLACKLETTER, 64, INK)
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
	card_text = _label("", SERIF, 36, INK)
	card_text.remove_theme_color_override("font_shadow_color")
	card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_text.custom_minimum_size = Vector2(800, 0)
	v.add_child(card_text)
	card_btn = _card_button()
	card_btn.pressed.connect(_on_card_btn)
	v.add_child(card_btn)
	card_alt = _card_button()
	card_alt.pressed.connect(_on_card_alt)
	card_alt.visible = false
	v.add_child(card_alt)


func _card_button() -> Button:
	var b := Button.new()
	b.add_theme_font_override("font", CINZEL)
	b.add_theme_font_size_override("font_size", 40)
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_color_override("font_pressed_color", IVORY)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.custom_minimum_size = Vector2(0, 110)
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("5a1010") if st != "pressed" else Color("3a0808")
		sb.border_color = Color(GOLD, 0.7)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(18)
		b.add_theme_stylebox_override(st, sb)
	return b


func _card(title: String, text: String, button: String, then: Callable, alt := "", alt_then := Callable(), big := 0) -> void:
	cards.append({"title": title, "text": text, "button": button, "then": then, "alt": alt, "alt_then": alt_then, "big": big})
	if not overlay.visible:
		_show_card()


func _show_card() -> void:
	var c: Dictionary = cards[0]
	card_title.text = c.title
	card_title.add_theme_font_size_override("font_size", [64, 76, 92][c.big])
	card_title.add_theme_color_override("font_color", BLOOD if c.big == 2 else INK)
	card_text.text = c.text
	card_btn.text = c.button
	card_alt.text = c.alt
	card_alt.visible = c.alt != ""
	overlay.visible = true


func _on_card_btn() -> void:
	_close_card("then")


func _on_card_alt() -> void:
	_close_card("alt_then")


func _close_card(which: String) -> void:
	if cards.is_empty():
		return
	var c: Dictionary = cards.pop_front()
	overlay.visible = false
	if not cards.is_empty():
		_show_card()
	var f: Callable = c[which]
	if f.is_valid():
		f.call()
	_refresh()


func _on_help() -> void:
	if overlay.visible:
		return
	var lines: Array = []
	for h in range(Rules.HANDS.size() - 1, -1, -1):
		var nm: String = Rules.HANDS[h]
		if nm == "Straight":
			nm = "Straight (2 3 4 5 6)"
		lines.append("%s   %d" % [nm, Rules.pay(cfg, h)])
	var text := "\n".join(lines) + "\n\nEach throw, draw 1, 2 or 3 dice and keep one in your row; the rest go back. A 1 is a skull: it stays out and snuffs a candle. Three skulls and the Master takes the hand. A full row is paid. The bag's last die is thrown alone: wild, but a skull loses the hand."
	text += "\n\n%s%s" % [Version.VERSION, (" (%s)" % Version.BUILD) if Version.BUILD != "" else ""]
	_card("The hands", text, "Back", Callable(), "Replay the tutorial", func():
		_start_tutorial())


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
