## Stages every gameplay event as a beat that directs the eye (Docs/UXPass.md):
## one focal point at a time (everything else dims), four phases per beat
## (anticipation, action, impact, hold), values travel from cause to effect and count up
## where they land, and bigger results get bigger staging. Timings: ui/tuning.gd.
## Lives under ui/main.gd and drives its board nodes; it never touches the rules.
extends Node

const Tuning = preload("res://ui/tuning.gd")
const Style = preload("res://ui/style.gd")
const Art = preload("res://ui/art.gd")
const Rules = preload("res://core/rules.gd")
const T = Tuning
const Sfx = preload("res://ui/sfx.gd")

var m          # ui/main.gd
var q          # ui/action_queue.gd
var fx: Control
var sfx: Node          # ui/sfx.gd
var _shown := {}          # the snapshot the board currently shows
var _prompt_gen := 0      # bumps on every prompt, so stale idle hints do nothing
var _pulses: Array[Tween] = []
var _line := ""             # the log line of the beat playing (shown once a bot has revealed its move)


func _ready() -> void:
	sfx = Sfx.new()
	add_child(sfx)


func setup(main, queue, layer: Control) -> void:
	m = main
	q = queue
	fx = layer
	sfx.q = queue


# ================= Beats =================

## One rules log line. prev: what the board showed before; snap: the state after this line.
func play(text: String, ev: Dictionary, prev: Dictionary, snap: Dictionary) -> void:
	_line = text
	if not (ev.kind in ["throw", "bank", "buy", "attack", "redemption"]):
		m.show_ticker(text)
	var mt: RegExMatch = ev.match
	match ev.kind:
		"blank":
			return
		"throw":
			await _throw(mt.get_string(1), int(mt.get_string(2)), prev, snap, "Throw %s" % mt.get_string(2))
		"redemption":
			await _throw(mt.get_string(1).trim_suffix(" rolls for"), 0, prev, snap, "Redemption")
		"score":
			await _score(prev, snap)
		"bust":
			await _bust(prev, snap)
		"bank":
			await _bank(mt.get_string(1), int(mt.get_string(2)), prev, snap)
		"buy":
			await _buy(mt.get_string(1), int(mt.get_string(2)), prev, snap)
		"ability":
			await _ability(mt.get_string(1), mt.get_string(2), mt.get_string(3), prev, snap)
		"reroll":
			await _reroll(snap)
		"attack":
			await _attack(text, prev, snap)
		"bounce":
			await _bounce(text, prev, snap)
		"hubris":
			await _hubris(mt.get_string(1) == "pays off", prev, snap)
		"redeemed", "still_purgatory":
			await _redeem_result(ev.kind == "redeemed", snap)
		"win":
			await _win(snap)
		"vig", "indulgence":
			await _generic(prev, snap, snap.cur)  # from the buyer's / payer's window
		"pact_cut":
			focus(["turn"], T.DIM)
			await _effects_from(_center(m._turn_label), prev, snap)
			await q.wait(T.HOLD)
		_:
			await _generic(prev, snap, -1)
	_shown = snap


## Full-width banner sweeps in, holds, sweeps out. The board changes over while it covers the stage.
func turn_change(p, snap: Dictionary) -> void:
	var seat: int = snap.cur
	var mine: bool = p.bot == m.human
	var col: Color = Style.SIN_COLORS[p.sin.sin_name]
	while m._dice_area.size.y <= 0.0:  # the first turn starts the frame the board is built
		await get_tree().process_frame
	focus(["seat%d" % seat])
	m.show_ticker("")
	var band := _banner_band("Your turn" if mine else "%s's turn" % m.player_name(p), col)
	sfx.play("banner_in", 0.6 if mine else 0.3)
	var w: float = m.size.x
	band.position.x = -w
	var tw: Tween = q.tween(band)
	tw.tween_property(band, "position:x", 0.0, T.BANNER_IN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await q.wait(T.BANNER_IN)
	m._refresh(snap)
	_punch(_seat(seat).window, 0.6)
	if mine:
		haptic(0.5)
	await q.wait(T.BANNER_HOLD)
	sfx.play("banner_out", 0.3)
	tw = q.tween(band)
	tw.tween_property(band, "position:x", w, T.BANNER_OUT).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await q.wait(T.BANNER_OUT)
	band.queue_free()
	_shown = snap


## Your decision: pulse what you can tap, dim what you can't, hint the main move after a while.
func my_turn(buttons: Array) -> void:
	_prompt_gen += 1
	var gen := _prompt_gen
	focus(["thumb"], T.DIM, {"dice": T.INFO_DIM, "turn": T.INFO_DIM, "throw": T.INFO_DIM}, false)
	_stop_pulses()
	for i in buttons.size():
		var b: Control = buttons[i]
		b.pivot_offset = b.size / 2
		var tw := b.create_tween().set_loops()
		tw.tween_interval(0.06 * i)
		tw.tween_property(b, "scale", Vector2.ONE * T.PULSE_SCALE, T.PULSE_PERIOD / 2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(b, "scale", Vector2.ONE, T.PULSE_PERIOD / 2).set_trans(Tween.TRANS_SINE)
		_pulses.append(tw)
	await get_tree().create_timer(T.IDLE_HINT).timeout
	if gen != _prompt_gen or buttons.is_empty() or not is_instance_valid(buttons[0]):
		return
	var primary: Control = buttons[0]
	for b in buttons:
		if is_instance_valid(b) and b.get_meta("kind", "") == "roll":
			primary = b
	_stop_pulses()
	primary.pivot_offset = primary.size / 2
	var tw := primary.create_tween().set_loops()
	tw.tween_property(primary, "scale", Vector2.ONE * T.HINT_SCALE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(primary, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.6)
	_pulses.append(tw)
	burst(_center(primary), 0.4, Style.C_GOLD)


func prompt_answered() -> void:
	_prompt_gen += 1
	_stop_pulses()
	haptic(0.2)


# ================= Event beats =================

## A throw (or a Redemption roll). Bots think and show the move first; dice tumble in from the thrower.
func _throw(who: String, n: int, prev: Dictionary, snap: Dictionary, card: String) -> void:
	var seat := _seat_index(who)
	if not _is_mine(seat):
		await _think_and_card(seat, card, "roll")
	m.show_ticker(_line)
	focus(["dice", "seat%d" % seat], T.DIM, {"throw": T.DIM})
	m._refresh(snap, ["glow", "banner", "plates", "turn", "strikes"])
	m._throw_label.text = ""
	m._show_dice([])
	# Anticipation: the tray draws breath.
	_lift(m._dice_area, T.ANTICIPATION, Color.WHITE, "shake")
	await q.wait(T.ANTICIPATION)
	# Action: the dice tumble in from the thrower's side, one after another.
	var faces: Array = snap.turn.faces
	m._show_dice(faces)
	sfx.play("throw" if faces.size() > 1 else "throw_one", clampf(faces.size() / 8.0, 0.3, 1.0))
	await get_tree().process_frame  # let the flow container place them
	var side := signf(_center(_seat(seat).col).x - _center(m._dice_area).x)
	var dice: Array = m._dice_nodes
	for i in dice.size():
		var d: Control = dice[i]
		var to := d.position
		d.position = to + Vector2(side * 520.0 + randf_range(-60, 60), -340.0 + randf_range(-60, 60))
		d.rotation = randf_range(-3.0, 3.0)
		d.scale = Vector2.ONE * 0.55
		d.modulate.a = 0.0
		var tw: Tween = q.tween(d)
		tw.tween_interval(T.STAGGER * i)
		tw.tween_property(d, "modulate:a", 1.0, 0.08)
		tw.parallel().tween_property(d, "position", to, T.ACTION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(d, "rotation", 0.0, T.ACTION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(d, "scale", Vector2.ONE, T.ACTION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Landing squash.
		tw.tween_property(d, "scale", Vector2(1.14, 0.86), T.IMPACT * 0.4)
		tw.tween_property(d, "scale", Vector2.ONE, T.IMPACT * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await q.wait(T.ACTION + T.STAGGER * maxi(0, dice.size() - 1))
	# Impact: dust, shake and a tap you feel, scaled to the number of dice.
	var k := clampf(dice.size() / 8.0, T.K_MIN, 1.0)
	for d in dice:
		burst(_center(d), k * 0.5, Style.C_BONE_DARK)
	shake(k * 0.6)
	impact(k * 0.6, "")  # the throw sound already lands
	await q.wait(T.IMPACT)
	if n == 0:  # Redemption: say what's needed
		m._throw_label.add_theme_font_size_override("font_size", 72)
		m._throw_label.text = "Redemption: need a 6"
	await q.wait(T.HOLD)


## Strikes nail in one by one, then the scoring dice send their points to the throw total and on to the turn.
func _score(prev: Dictionary, snap: Dictionary) -> void:
	await _strikes(prev, snap)
	var faces: Array = snap.turn.faces
	var pts: int = snap.turn.points - _turn_points(prev)
	var dice: Array = m._dice_nodes
	var scorers := []
	for i in mini(faces.size(), dice.size()):
		if faces[i] >= 4:
			scorers.append(i)
	focus(["dice", "throw", "turn"])
	if pts <= 0 or scorers.is_empty():
		m._throw_label.add_theme_font_size_override("font_size", m.SCORE_SIZE)
		m._throw_label.text = "+0"
		m._throw_label.modulate = Color(0.6, 0.55, 0.5)
		sfx.play("impact_light", 0.0, 0.7)
		_punch(m._throw_label, 0.3)
		await q.wait(T.HOLD)
		m._throw_label.modulate = Color.WHITE
		m._refresh(snap, ["turn"])
		return
	var k := T.k_of(pts)
	# Anticipation: the scoring dice lift and glow.
	for i in scorers:
		_lift(dice[i], T.ANTICIPATION, Color(1.3, 1.2, 0.9))
	await q.wait(T.ANTICIPATION)
	# Action: each die's points fly to the throw total, which counts up as they land.
	m._throw_label.add_theme_font_size_override("font_size", m.SCORE_SIZE)
	m._throw_label.text = "+0"
	var base := 0
	var dest := _center(m._throw_label)
	var act := T.ACTION * (1.0 + T.ACTION_STRETCH * k)
	for j in scorers.size():
		var i: int = scorers[j]
		var v: int = faces[i] * m.game.face_mult
		var from := base
		base += v
		var tw := fly("+%d" % v, _center(dice[i]), dest, Style.C_GOLD, act, T.STAGGER * j)
		tw.tween_callback(func():
			count(m._throw_label, from, from + v, T.IMPACT, "+%d")
			_punch(m._throw_label, 0.3))
	await q.wait(act + T.STAGGER * (scorers.size() - 1))
	# The chain multiplier brands the total.
	if pts != base:
		var mult := float(pts) / base
		stamp("x%.1f" % mult, _center(m._throw_label) + Vector2(260, -10), Style.C_GOLD, 0.6, 90)
		count(m._throw_label, base, pts, T.IMPACT * 2, "+%d")
	# Impact.
	_punch(m._throw_label, k)
	burst(dest, k, Style.C_GOLD)
	shake(k * 0.5)
	impact(k * 0.5)
	await q.wait(T.IMPACT)
	await q.wait(T.HOLD * 0.5)
	# Second action: the throw total travels to the turn total, which punches and counts up.
	var tw2 := fly("+%d" % pts, dest, _center(m._turn_label), Style.C_GOLD, T.ACTION)
	var before := _turn_points(prev)
	tw2.tween_callback(func():
		count_turn(before, snap.turn.points)
		_punch(m._turn_label, k))
	await q.wait(T.ACTION + T.IMPACT)
	m._refresh(snap, ["turn", "strikes"])
	await q.wait(T.HOLD)


## New Strikes since the last beat: each Strike die flashes red and its ember drives a nail in.
func _strikes(prev: Dictionary, snap: Dictionary) -> void:
	var had := _strike_count(prev)
	var now: int = snap.turn.strikes
	if now <= had:
		return
	var faces: Array = snap.turn.faces
	var dice: Array = m._dice_nodes
	var strike_dice := []
	for i in mini(faces.size(), dice.size()):
		if faces[i] <= 2:
			strike_dice.append(dice[i])
	focus(["dice", "turn"])
	for d in strike_dice:
		_lift(d, T.ANTICIPATION, Color(1.5, 0.55, 0.5))
	await q.wait(T.ANTICIPATION)
	for s in range(had, mini(now, m._strike_icons.size())):
		var nail: Control = m._strike_icons[s]
		var src: Vector2 = _center(strike_dice[(s - had) % strike_dice.size()]) if not strike_dice.is_empty() else _center(m._dice_area)
		var tw := fly("✕", src, _center(nail), Style.C_STRIKE.lightened(0.3), T.ACTION * 0.7)
		await q.wait(T.ACTION * 0.7)
		nail.texture = Art.STRIKE_STRUCK
		var k := 0.45 + 0.25 * s
		_punch(nail, k)
		burst(_center(nail), k * 0.6, Style.C_STRIKE)
		shake(k * 0.5)
		impact(k, "nail_last" if s >= 2 else "nail")
		await q.wait(T.IMPACT)
	await q.wait(T.HOLD * 0.6)


## The third nail, the stage gutters, the turn total burns to nothing.
func _bust(prev: Dictionary, snap: Dictionary) -> void:
	await _strikes(prev, snap)
	focus(["dice", "turn", "throw"])
	for nail in m._strike_icons:
		_lift(nail, T.ANTICIPATION, Color(1.6, 0.5, 0.4))
	await q.wait(T.ANTICIPATION)
	var lost := _turn_points(prev)
	count_turn(lost, 0, T.ACTION * 1.5)
	m._throw_label.text = ""
	await q.wait(T.ACTION * 1.5)
	flash(Style.C_STRIKE, 0.45, T.IMPACT * 3)
	stamp("BUST", _center(m._dice_area), Style.C_STRIKE.lightened(0.2), 1.0)
	shake(1.0)
	impact(1.0, "bell")
	sfx.play("crack", 1.0)
	burst(_center(m._turn_label), 1.0, Style.C_STRIKE)
	await q.wait(T.IMPACT)
	m._refresh(snap, ["plates", "glow"])
	await q.wait(T.HOLD * 2.0)


## The turn total travels to the plate; the plate punches and counts up.
func _bank(who: String, n: int, prev: Dictionary, snap: Dictionary) -> void:
	var seat := _seat_index(who)
	if not _is_mine(seat):
		await _think_and_card(seat, "Bank %d" % n, "bank")
	m.show_ticker(_line)
	var pt: Dictionary = _seat(seat)
	focus(["turn", "seat%d" % seat])
	m._throw_label.text = ""
	var k := T.k_of(n)
	_lift(m._turn_label, T.ANTICIPATION)
	await q.wait(T.ANTICIPATION)
	var act := T.ACTION * (1.0 + T.ACTION_STRETCH * k)
	var from_score := _score_of(prev, seat)
	var tw := fly("+%d" % n, _center(m._turn_label), _center(pt.score), Style.C_GOLD, act)
	count_turn(_turn_points(prev), 0, act)
	await q.wait(act)
	count(pt.score, from_score, _score_of(snap, seat), T.COUNT_UP)
	_punch(pt.score, k)
	_punch(pt.window, k * 0.5)
	burst(_center(pt.score), k, Style.C_GOLD)
	shake(k * 0.5)
	impact(k * 0.7, "coins")
	await q.wait(T.IMPACT)
	await q.wait(maxf(T.HOLD, T.COUNT_UP - T.IMPACT))
	m._refresh(snap, ["plates"])


## The price leaves the plate; new dice drop onto it.
func _buy(who: String, n: int, prev: Dictionary, snap: Dictionary) -> void:
	var seat := _seat_index(who)
	if not _is_mine(seat):
		await _think_and_card(seat, "Buy %d" % n, "pill")
	m.show_ticker(_line)
	var pt: Dictionary = _seat(seat)
	focus(["seat%d" % seat])
	_lift(pt.col, T.ANTICIPATION)
	await q.wait(T.ANTICIPATION)
	var s0 := _score_of(prev, seat)
	var s1 := _score_of(snap, seat)
	var away := _center(pt.score) + Vector2(0, 420)
	sfx.play("buy", 0.5)
	fly("-%d" % (s0 - s1), _center(pt.score), away, Style.C_BONE_DARK, T.ACTION)
	count(pt.score, s0, s1, T.ACTION)
	await q.wait(T.ACTION * 0.6)
	var tw := fly("+%d" % n, away, _center(pt.dice), Style.C_BONE, T.ACTION)
	await q.wait(T.ACTION)
	m._refresh(snap, ["plates"])
	_punch(pt.dice, 0.5)
	burst(_center(pt.dice), 0.3, Style.C_BONE)
	impact(0.3, "impact_light")
	await q.wait(T.IMPACT + T.HOLD)


## The Sin acts: its window lifts, its line is written, the glass flares, then its effect travels.
func _ability(who: String, ability: String, what: String, prev: Dictionary, snap: Dictionary) -> void:
	var seat := _seat_index(who)
	if seat < 0:
		await _generic(prev, snap, -1)
		return
	var pt: Dictionary = _seat(seat)
	focus(["seat%d" % seat], T.DIM, {"dice": T.INFO_DIM, "turn": T.INFO_DIM})
	_lift(pt.window, T.ANTICIPATION)
	await q.wait(T.ANTICIPATION)
	var note: Control = m._marginalia(pt, ability, what)
	await q.wait(T.ACTION)
	m._flare(pt)
	impact(0.4, "glass")
	burst(_center(pt.window), 0.5, Style.SIN_COLORS[pt.sin].lightened(0.3))
	await q.wait(T.IMPACT)
	await _effects_from(_center(pt.window), prev, snap)
	await q.wait(T.HOLD * 1.5)
	if is_instance_valid(note):
		var tw: Tween = q.tween(note)
		tw.tween_property(note, "modulate:a", 0.0, 0.2)
		tw.tween_callback(note.queue_free)
		await q.wait(0.2)


## Fury: the targeted dice jump, spin, and land on new faces.
func _reroll(snap: Dictionary) -> void:
	focus(["dice"])
	var dice: Array = m._dice_nodes
	for d in dice:
		_lift(d, T.ANTICIPATION, Color(1.4, 0.7, 0.6), "shake")
	await q.wait(T.ANTICIPATION)
	sfx.play("throw", 0.6)
	for d in dice:
		var tw: Tween = q.tween(d)
		tw.tween_property(d, "rotation", TAU, T.ACTION).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func(): d.rotation = 0.0)
	await q.wait(T.ACTION * 0.5)
	m._show_dice(snap.turn.faces)
	await get_tree().process_frame
	for d in m._dice_nodes:
		burst(_center(d), 0.3, Style.C_BONE_DARK)
	shake(0.4)
	impact(0.5, "")
	await q.wait(T.ACTION * 0.5 + T.IMPACT + T.HOLD)


## A Tier 2 attack: a streak flies from attacker to target, which shudders and takes its mark.
func _attack(text: String, prev: Dictionary, snap: Dictionary) -> void:
	var r := RegEx.create_from_string("^(.+?) (unleashes Fury on|binds a Pact on|Drags) (.+?)\\.$").search(text)
	if r == null:
		await _generic(prev, snap, -1)
		return
	var a := _seat_index(r.get_string(1))
	var b := _seat_index(r.get_string(3))
	var verb: String = {"unleashes Fury on": "Fury", "binds a Pact on": "Binding Pact", "Drags": "Drag"}[r.get_string(2)]
	if not _is_mine(a):
		await _think_and_card(a, "%s: %s" % [verb, r.get_string(3)], "pill")
	m.show_ticker(_line)
	await _streak(a, b, prev, snap)


func _bounce(text: String, prev: Dictionary, snap: Dictionary) -> void:
	var r := RegEx.create_from_string("^(.+?) is Untouchable: it bounces back onto (.+?)!$").search(text)
	if r == null:
		await _generic(prev, snap, -1)
		return
	sfx.play("glass_light", 0.7)
	await _streak(_seat_index(r.get_string(1)), _seat_index(r.get_string(2)), prev, snap)


func _streak(a: int, b: int, prev: Dictionary, snap: Dictionary) -> void:
	if a < 0 or b < 0:
		await _generic(prev, snap, -1)
		return
	var pa: Dictionary = _seat(a)
	var pb: Dictionary = _seat(b)
	var col: Color = Style.SIN_COLORS[pa.sin]
	focus(["seat%d" % a, "seat%d" % b])
	_lift(pa.window, T.ANTICIPATION)
	await q.wait(T.ANTICIPATION)
	fly("✦", _center(pa.window), _center(pb.window), col.lightened(0.4), T.ACTION, 0.0, 110)
	await q.wait(T.ACTION)
	m._flare(pb)
	_punch(pb.col, 0.7)
	flash(col, 0.25, T.IMPACT * 2)
	shake(0.6)
	impact(0.7, "hit")
	await q.wait(T.IMPACT)
	m._refresh(snap, ["plates"])
	await q.wait(T.HOLD)


func _hubris(paid: bool, prev: Dictionary, snap: Dictionary) -> void:
	focus(["turn"])
	_lift(m._turn_label, T.ANTICIPATION)
	await q.wait(T.ANTICIPATION)
	var before := _turn_points(prev)
	if paid:
		stamp("x1.6", _center(m._turn_label) + Vector2(0, -90), Style.C_GOLD, 0.8, 110)
		sfx.play("glass", 0.8)
		await q.wait(T.ACTION)
		impact(0.6, "coins")
		shake(0.5)
	else:
		count_turn(before, 0, T.ACTION)
		stamp("Hubris fails", _center(m._dice_area), Style.C_STRIKE.lightened(0.2), 0.8, 110)
		sfx.play("crack", 0.8)
		await q.wait(T.ACTION)
		impact(0.8)
		shake(0.7)
	await q.wait(T.IMPACT + T.HOLD)


func _redeem_result(freed: bool, snap: Dictionary) -> void:
	focus(["dice", "seat%d" % snap.cur])
	if freed:
		for i in mini(snap.turn.faces.size(), m._dice_nodes.size()):
			if snap.turn.faces[i] == 6:
				_lift(m._dice_nodes[i], T.ANTICIPATION, Color(1.4, 1.25, 0.8))
	await q.wait(T.ANTICIPATION)
	stamp("Redeemed!" if freed else "Still in Purgatory", _center(m._dice_area),
		Style.C_GOLD if freed else Style.C_STRIKE.lightened(0.3), 0.7, 100)
	impact(0.6 if freed else 0.3, "glass" if freed else "")
	if freed:
		burst(_center(m._dice_area), 0.7, Style.C_GOLD)
	await q.wait(T.ACTION + T.IMPACT)
	m._refresh(snap, ["plates"])
	await q.wait(T.HOLD)


func _win(snap: Dictionary) -> void:
	var seat := -1
	var best := -999999
	for i in snap.players.size():
		if snap.players[i].score > best:
			best = snap.players[i].score
			seat = i
	focus(["seat%d" % seat])
	m._refresh(snap)
	var pt: Dictionary = _seat(seat)
	_lift(pt.col, T.ANTICIPATION * 2)
	await q.wait(T.ANTICIPATION * 2)
	m._flare(pt)
	burst(_center(pt.window), 1.0, Style.C_GOLD)
	burst(_center(pt.score), 1.0, Style.C_GOLD)
	shake(0.8)
	impact(1.0, "bell")
	sfx.play("win", 1.0)
	sfx.play("coins", 1.0)
	await q.wait(T.HOLD * 3)


## Anything else: show it, let any changed numbers travel, hold.
func _generic(prev: Dictionary, snap: Dictionary, seat: int) -> void:
	var src := _center(m._banner) if seat < 0 else _center(_seat(seat).window)
	await _effects_from(src, prev, snap)
	m._refresh(snap)
	await q.wait(T.HOLD)


## Whatever numbers changed between two snapshots travel from src to where they belong:
## plate scores, the turn total and the dice. No number changes in place.
func _effects_from(src: Vector2, prev: Dictionary, snap: Dictionary) -> void:
	if prev.is_empty():
		return
	var moved := false
	for i in snap.players.size():
		var d: int = snap.players[i].score - prev.players[i].score
		if d != 0:
			var pt: Dictionary = _seat(i)
			var s0: int = prev.players[i].score
			var s1: int = snap.players[i].score
			var tw := fly("%+d" % d, src, _center(pt.score), Style.C_GOLD if d > 0 else Style.C_BONE_DARK, T.ACTION)
			tw.tween_callback(func():
				count(pt.score, s0, s1, T.COUNT_UP)
				_punch(pt.score, T.k_of(d)))
			moved = true
	var dp: int = _turn_points(snap) - _turn_points(prev)
	if dp != 0:
		var t0 := _turn_points(prev)
		var t1 := _turn_points(snap)
		var tw := fly("%+d" % dp, src, _center(m._turn_label), Style.C_GOLD, T.ACTION)
		tw.tween_callback(func():
			count_turn(t0, t1)
			_punch(m._turn_label, T.k_of(dp)))
		moved = true
	if snap.has("turn") and prev.has("turn") and str(snap.turn.faces) != str(prev.turn.faces) and not m._dice_nodes.is_empty():
		await q.wait(T.ACTION * 0.6)
		m._show_dice(snap.turn.faces)
		await get_tree().process_frame
		for d in m._dice_nodes:
			_punch(d, 0.3)
		burst(_center(m._dice_area), 0.4, Style.C_BONE)
		moved = true
		await q.wait(T.ACTION * 0.4)
	elif moved:
		await q.wait(T.ACTION)
	if moved:
		await q.wait(T.COUNT_UP)
		m._refresh(snap, ["plates", "turn"])


# ================= Bots: think, then show the move =================

func _think_and_card(seat: int, text: String, kind: String) -> void:
	if seat < 0:
		return
	var pt: Dictionary = _seat(seat)
	focus(["seat%d" % seat])
	m.set_waiting_text("%s is thinking" % m.player_name(m.game.players[seat]))
	var tw: Tween = q.tween(pt.window)
	pt.window.pivot_offset = pt.window.size / 2
	tw.tween_property(pt.window, "scale", Vector2.ONE * 1.06, T.THINK / 2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(pt.window, "scale", Vector2.ONE, T.THINK / 2).set_trans(Tween.TRANS_SINE)
	var dots: Tween = q.tween(self)
	var base := "%s is thinking" % m.player_name(m.game.players[seat])
	dots.tween_method(func(v: float): m.set_waiting_text(base + ".".repeat(int(v) % 4)), 0.0, 7.99, T.THINK)
	await q.wait(T.THINK)
	# The chosen move rises out of the window, enlarged at centre.
	var card := _card(text, kind)
	var to := _center(m._dice_area) - card.size / 2
	card.position = _center(pt.window) - card.size / 2
	card.scale = Vector2.ONE * 0.3
	card.modulate.a = 0.0
	focus(["seat%d" % seat], T.DIM * 0.8)
	var t2: Tween = q.tween(card)
	t2.tween_property(card, "modulate:a", 1.0, 0.1)
	t2.parallel().tween_property(card, "position", to, T.ACTION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t2.parallel().tween_property(card, "scale", Vector2.ONE, T.ACTION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await q.wait(T.ACTION)
	_punch(card, 0.4)
	impact(0.2, "card")
	await q.wait(T.IMPACT + T.CARD_HOLD)
	var t3: Tween = q.tween(card)
	t3.tween_property(card, "scale", Vector2.ONE * 0.6, 0.15)
	t3.parallel().tween_property(card, "modulate:a", 0.0, 0.15)
	t3.tween_callback(card.queue_free)
	await q.wait(0.15)
	m.set_waiting_text("")


func _card(text: String, kind: String) -> Control:
	var big := kind in ["roll", "bank"]
	var sz := Vector2(380, 380) if big else Vector2(maxf(520.0, Style.BLACKLETTER.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x + 140), 220)
	var c := Control.new()
	c.size = sz
	c.pivot_offset = sz / 2
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := TextureRect.new()
	tex.texture = Art.SEAL_L[0] if big else Art.YOU_TAB
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if big else TextureRect.STRETCH_SCALE
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "bank":
		tex.material = Art.tint_material(Color("e0b872"))
		tex.modulate = Color(2.0, 1.75, 1.4)
	c.add_child(tex)
	var l := Style.label(text.replace(" ", "\n") if big else text, 76 if big else 64, Style.C_IVORY, true, 10)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("line_spacing", -18)
	c.add_child(l)
	fx.add_child(c)
	return c


# ================= Focus =================

## Brightens and slightly enlarges the focal groups, dims the rest. levels: per-group overrides.
func focus(keys: Array, others := T.DIM, levels := {}, grow := true) -> void:
	for key in m.focus_groups():
		var node: CanvasItem = m.focus_groups()[key]
		var base: Color = node.get_meta("base_mod", Color.WHITE) if node.has_meta("base_mod") else _remember(node)
		var lv: float = 1.0 if key in keys else levels.get(key, others)
		var tw: Tween = node.create_tween()  # outside the queue: focus carries across beats
		tw.tween_property(node, "modulate", Color(base.r * lv, base.g * lv, base.b * lv, base.a), T.t(T.FOCUS_FADE))
		if node is Control and key.begins_with("seat"):
			node.pivot_offset = node.size / 2
			tw.parallel().tween_property(node, "scale", Vector2.ONE * (T.FOCUS_SCALE if key in keys and grow else 1.0), T.t(T.FOCUS_FADE))


func unfocus() -> void:
	focus(m.focus_groups().keys())


func _remember(node: CanvasItem) -> Color:
	node.set_meta("base_mod", node.modulate)
	return node.modulate


# ================= Juice primitives =================

## A value flies from a to b along an arc. Returns its tween (append callbacks to act on arrival).
func fly(text: String, a: Vector2, b: Vector2, col: Color, dur: float, delay := 0.0, font := T.FLY_FONT) -> Tween:
	var l := Style.label(text, font, col, false, 10)
	l.add_theme_font_override("font", Style.NUMERAL)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	fx.add_child(l)
	l.size = l.get_combined_minimum_size()
	l.pivot_offset = l.size / 2
	l.position = a - l.size / 2
	l.modulate.a = 0.0
	var ctrl := (a + b) / 2 + Vector2(0, -T.FLY_ARC)
	var tw: Tween = q.tween(l)
	tw.tween_interval(delay)
	tw.tween_callback(func(): sfx.play("whoosh", clampf(dur / T.ACTION - 0.5, 0.2, 1.0)))
	tw.tween_property(l, "modulate:a", 1.0, 0.06)
	tw.tween_property(l, "scale", Vector2.ONE * 1.3, 0.08)
	tw.tween_method(func(t: float):
		var p := a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t)
		l.position = p - l.size / 2
		l.scale = Vector2.ONE * lerpf(1.3, 0.8, t), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(l.queue_free)
	return tw


## A label counts from a to b. fmt: "%d", "+%d".
func count(l: Label, a: int, b: int, dur: float, fmt := "%d") -> void:
	var tw: Tween = q.tween(l)
	tw.tween_method(func(v: float):
		l.text = fmt % int(round(v))
		_tick(a, b, v), float(a), float(b), dur)


func count_turn(a: int, b: int, dur := T.COUNT_UP) -> void:
	var tw: Tween = q.tween(m._turn_label)
	tw.tween_method(func(v: float):
		m.set_turn_points(int(round(v)))
		_tick(a, b, v), float(a), float(b), dur)


## Count-up ticks rise in pitch as the number climbs (and fall as it drains).
func _tick(a: int, b: int, v: float) -> void:
	if a == b or is_equal_approx(v, float(a)):
		return
	var t := (v - a) / float(b - a)
	sfx.tick(t if b > a else 1.0 - t)


func _punch(node: Control, k: float) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.pivot_offset = node.size / 2
	var base: Vector2 = node.scale
	var tw: Tween = q.tween(node)
	tw.tween_property(node, "scale", base * (1.0 + (T.PUNCH_SCALE - 1.0) * clampf(k, T.K_MIN, 1.0)), T.IMPACT * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", base, T.IMPACT * 1.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Anticipation: lift (and optionally tint) an element, holding until the beat moves on.
func _lift(node: Control, dur: float, tint := Color.WHITE, snd := "lift") -> void:
	if node == null or not is_instance_valid(node):
		return
	sfx.play(snd, 0.4)
	node.pivot_offset = node.size / 2
	var tw: Tween = q.tween(node)
	tw.tween_property(node, "scale", Vector2.ONE * T.LIFT_SCALE, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if tint != Color.WHITE:
		tw.parallel().tween_property(node, "self_modulate", tint, dur)
	tw.tween_property(node, "scale", Vector2.ONE, T.ACTION).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(node, "self_modulate", Color.WHITE, T.ACTION * 2)


func shake(k: float) -> void:
	var board: Control = m._board
	if board == null or k <= 0.0:
		return
	var amp := T.SHAKE_PX * clampf(k, 0.0, 1.0)
	var tw: Tween = q.tween(board)
	tw.tween_method(func(t: float):
		board.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * amp * (1.0 - t), 0.0, 1.0, T.IMPACT * 2)
	tw.tween_callback(func(): board.position = Vector2.ZERO)


func burst(at: Vector2, k: float, col: Color) -> void:
	var p := CPUParticles2D.new()
	p.amount = int(lerpf(T.PARTICLES_MIN, T.PARTICLES_MAX, clampf(k, 0.0, 1.0)))
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.7
	p.speed_scale = T.speed
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 420.0 + 300.0 * k
	p.gravity = Vector2(0, 900)
	p.scale_amount_min = 4.0
	p.scale_amount_max = 9.0 + 6.0 * k
	var g := Gradient.new()
	g.set_color(0, col.lightened(0.3))
	g.set_color(1, Color(col, 0.0))
	p.color_ramp = g
	p.position = at
	fx.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func flash(col: Color, alpha: float, dur: float) -> void:
	var r := ColorRect.new()
	r.color = Color(col, alpha)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.add_child(r)
	var tw: Tween = q.tween(r)
	tw.tween_property(r, "color:a", 0.0, dur)
	tw.tween_callback(r.queue_free)


## Big word or number slammed onto a spot: in large, overshoot, settle, gone at the end of the beat.
func stamp(text: String, at: Vector2, col: Color, k: float, font := T.STAMP_FONT) -> void:
	var l := Style.label(text, font, col, text.to_lower() != text.to_upper() and not text.begins_with("x"), 14)
	if text.begins_with("x"):
		l.add_theme_font_override("font", Style.NUMERAL)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	fx.add_child(l)
	l.size = l.get_combined_minimum_size()
	l.pivot_offset = l.size / 2
	l.position = at - l.size / 2
	l.scale = Vector2.ONE * 2.4
	l.modulate.a = 0.0
	var tw: Tween = q.tween(l)
	tw.tween_property(l, "modulate:a", 1.0, T.IMPACT)
	tw.parallel().tween_property(l, "scale", Vector2.ONE, T.IMPACT * 2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(T.HOLD * 2)
	tw.tween_property(l, "modulate:a", 0.0, 0.2)
	tw.tween_callback(l.queue_free)
	sfx.play("stamp", k)
	shake(k * 0.4)


## The impact phase: a tap you feel and a sound you hear, both sized by k.
## snd: "impact" = wood on the desk sized by k; "" = haptic only; else a ui/sfx.gd sound.
func impact(k: float, snd := "impact") -> void:
	haptic(k)
	if snd == "impact":
		sfx.impact(k)
	elif snd != "":
		sfx.play(snd, k)


func haptic(k: float) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(int(lerpf(T.HAPTIC_MS_MIN, T.HAPTIC_MS_MAX, clampf(k, 0.0, 1.0))), clampf(0.3 + k * 0.7, 0.0, 1.0))


func _banner_band(text: String, col: Color) -> Control:
	var band := Control.new()
	var h := 300.0
	band.size = Vector2(m.size.x, h)
	band.position.y = _center(m._dice_area).y - h / 2
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = Color(col.darkened(0.55), 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(bg)
	for y in [0.0, h - 10.0]:
		var rule := ColorRect.new()
		rule.color = Style.C_GOLD_DEEP
		rule.position = Vector2(0, y)
		rule.size = Vector2(m.size.x, 10)
		band.add_child(rule)
	var l := Style.label(text, 130, Style.C_IVORY, true, 14)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	band.add_child(l)
	fx.add_child(band)
	return band


func _stop_pulses() -> void:
	for tw in _pulses:
		if tw.is_valid():
			tw.kill()
	_pulses.clear()


# ================= Lookups =================

func _seat(i: int) -> Dictionary:
	return m._portraits[i]


func _seat_index(who: String) -> int:
	for i in m._portraits.size():
		var pt: Dictionary = m._portraits[i]
		if (pt.mine and who == "You") or (not pt.mine and who == pt.sin):
			return i
	return -1


func _is_mine(seat: int) -> bool:
	return seat >= 0 and m._portraits[seat].mine


func _center(c: Control) -> Vector2:
	return c.get_global_rect().get_center() if c and is_instance_valid(c) else m.size / 2


func _turn_points(s: Dictionary) -> int:
	return s.turn.points if s.has("turn") else 0


func _strike_count(s: Dictionary) -> int:
	return s.turn.strikes if s.has("turn") else 0


func _score_of(s: Dictionary, seat: int) -> int:
	return s.players[seat].score if s.has("players") else 0
