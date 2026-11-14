## Run mode, placeholder board (Phase 8). Phase 9 replaces the look, Phase 10 the motion.
## Today's tray, dice and seals; Points x Mult; a relic row (tap a relic for its text); a plain shop
## page that names the next ruling Sin and its twist. Rules: run/. Words: ui/rules_text.gd RUN.
## Built by ui/main.gd (host), whose seals, safe area and ink wash it borrows.
## Saves on entering each shop (RUN_SAVE); logs every finished run (RUN_LOG, one JSON line each).
extends Control

const RunState = preload("res://run/run_state.gd")
const Round = preload("res://run/round.gd")
const Relics = preload("res://run/relics.gd")
const Shop = preload("res://run/shop.gd")
const Kits = preload("res://run/kits.gd")
const Rulers = preload("res://run/rulers.gd")
const Style = preload("res://ui/style.gd")
const Art = preload("res://ui/art.gd")
const Die = preload("res://ui/widgets/die.gd")
const T = preload("res://ui/rules_text.gd")

const RUN_SAVE := "user://run_save.json"
const RUN_LOG := "user://run_log.jsonl"
const TARGET := 44.0 * 1080.0 / 393.0   # 44 pt
const GAP := 13.0 * 1080.0 / 393.0
const SIDE := 17.0 * 1080.0 / 393.0
const DIE_SIDE := 150
const KEPT_SIDE := 84
const CHIP := Vector2(176, 130)
const SEAL := 200

signal to_menu
signal new_run

var host                       # ui/main.gd
var run                        # run/run_state.gd
var show_rules := false        # first run: one rules card before the first throw
var ctx := {}
var st := {}
var gs: Array = []
var sel := {}                  # group index -> true
var eat := -1                  # roll position Gluttony eats, or -1
var phase := "throw"           # throw, pick, after (bust or Bank shown), end
var msg := ""
var rng := RandomNumberGenerator.new()
var _t0 := 0                   # msec when this session's play time started
var _kept: Array = []          # [face value, gild, crimson] kept this turn, for the kept row
var _root: MarginContainer
var _popup: Control


func setup(p_host, p_run) -> void:
	host = p_host
	run = p_run
	rng.randomize()
	_t0 = Time.get_ticks_msec()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if run.status == "shop":
		_show_shop()
	else:
		_new_turn()
		if show_rules:
			_rules_card()


# ---------- frame ----------

func _clear() -> void:
	if _root:
		_root.queue_free()
	_root = MarginContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe: Vector2 = host._safe_insets() if host else Vector2.ZERO
	_root.add_theme_constant_override("margin_left", int(SIDE))
	_root.add_theme_constant_override("margin_right", int(SIDE))
	_root.add_theme_constant_override("margin_top", int(safe.x) + 24)
	_root.add_theme_constant_override("margin_bottom", int(safe.y) + 24)
	add_child(_root)


func _vbox(parent: Control, gap := GAP) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(gap))
	parent.add_child(v)
	return v


func _text(parent: Control, s: String, size := 36, col := Style.C_BONE) -> RichTextLabel:
	var r := Style.body(s, size, col, 8)
	parent.add_child(r)
	return r


func _button(parent: Control, s: String, cb: Callable, h := 140.0, kind := "run") -> Button:
	var b := Button.new()
	b.text = s
	b.set_meta("kind", kind)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(TARGET, maxf(h, TARGET))
	b.add_theme_font_size_override("font_size", 30)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _seal(parent: Control, s: String, cb: Callable, kind: String) -> Button:
	var b: Button
	if host:
		b = host._menu_seal(s, SEAL, cb)
	else:
		b = Button.new()
		b.text = s
		b.custom_minimum_size = Vector2(SEAL, SEAL)
		b.pressed.connect(cb)
	b.set_meta("kind", kind)
	parent.add_child(b)
	return b


func _dim(b: Button, on: bool) -> void:
	b.disabled = not on
	b.modulate = Color.WHITE if on else Color(1, 1, 1, 0.4)


# ---------- play ----------

func _new_turn() -> void:
	var t: Array = run.begin_turn()
	ctx = t[0]
	st = t[1]
	gs = []
	sel = {}
	eat = -1
	_kept = []
	phase = "throw"
	msg = T.run("hint_throw")
	_draw_play()


func _header(v: VBoxContainer) -> void:
	var c: int = run.circle + 1
	var where: String = T.run("sin_round", {"sin": run.ruler()}) if run.is_sin_round() else T.run("trial", {"n": run.round_i + 1})
	_text(v, "%s  ·  %s" % [T.run("circle", {"c": c}), where], 46, Style.C_GOLD)
	if run.is_sin_round():
		_text(v, Rulers.text(run.ruler(), run.cfg), 32, Style.C_STRIKE.lightened(0.35))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(GAP * 2))
	v.add_child(row)
	for pair in [[T.run("target"), run.target], [T.run("score"), run.score], [T.run("turns"), run.turns_left], [T.run("gold"), run.gold]]:
		var col := VBoxContainer.new()
		for j in 2:
			var l: Label = Style.label(str(pair[j]), 28, Style.C_BONE_DARK) if j == 0 else Style.number(str(pair[j]), 44, 6)
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
			col.add_child(l)
		row.add_child(col)


func _relic_row(v: VBoxContainer, selling: bool) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(GAP * 0.6))
	v.add_child(row)
	for i in run.cfg.relic_slots:
		var b := Button.new()
		b.custom_minimum_size = CHIP
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 24)
		b.set_meta("kind", "relic")
		if i < run.relics.size():
			var id: String = run.relics[i].id
			b.text = Relics.name_of(id)
			var idx: int = i
			b.pressed.connect(func(): _relic_popup(idx, selling))
		else:
			b.text = T.run("empty_slot")
			b.disabled = true
			b.modulate = Color(1, 1, 1, 0.35)
		row.add_child(b)


func _draw_play() -> void:
	_clear()
	var v := _vbox(_root)
	_header(v)
	_relic_row(v, false)
	# Kept this turn
	var kept := HFlowContainer.new()
	kept.alignment = FlowContainer.ALIGNMENT_CENTER
	kept.custom_minimum_size.y = KEPT_SIDE
	for k in _kept:
		kept.add_child(_die_face(k[0], k[1], k[2], KEPT_SIDE))
	v.add_child(kept)
	# The tray
	var tray := PanelContainer.new()
	var sb := StyleBoxTexture.new()
	sb.texture = Art.TRAY
	sb.set_texture_margin_all(60)
	sb.set_content_margin_all(48)
	tray.add_theme_stylebox_override("panel", sb)
	tray.custom_minimum_size.y = DIE_SIDE * 2 + 140
	tray.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(tray)
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", int(GAP))
	flow.add_theme_constant_override("v_separation", int(GAP))
	tray.add_child(flow)
	if phase == "pick" or (phase == "after" and not st.roll_d.is_empty()):
		var held := _held()
		for i in st.roll_d.size():
			flow.add_child(_roll_die(i, held))
	# Points x Mult and the Bank it would make
	var pv := _preview()
	_text(v, "%s [color=#%s]%d[/color]  x  %s [color=#%s]%d[/color]" % [T.run("points"), Style.C_GOLD.to_html(false), pv.p, T.run("mult"), Style.C_CRIMSON.lightened(0.3).to_html(false), pv.m], 50)
	if phase == "pick" and not sel.is_empty():
		_text(v, "%s %d" % [T.run("bank"), pv.bank], 40, Style.C_GOLD)
	_text(v, msg, 32, Style.C_BONE)
	# Seals
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(GAP * 3))
	v.add_child(row)
	var col := VBoxContainer.new()
	row.add_child(col)
	if phase == "after":
		_seal(col, T.run("next"), _on_next, "next")
	else:
		var tb := _seal(col, T.run("throw"), _on_throw, "throw")
		_dim(tb, phase == "throw" or (not sel.is_empty() and not pv.bank_only))
		var chance: float = pv.bust if phase == "pick" else _bust_chance(st.left)
		col.add_child(Style.label(T.run("bust_chance", {"n": int(round(chance * 100))}), 30, Style.C_BONE))
		var bb := _seal(row, T.run("bank"), _on_bank, "bank")
		_dim(bb, phase == "pick" and not sel.is_empty())
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(foot)
	_button(foot, T.run("to_menu"), func(): to_menu.emit(), TARGET, "menu").custom_minimum_size.x = 220


func _die_face(v: int, gild: int, crimson: int, side: int) -> Control:
	var d = Die.new(v, side, v * 3 + side)
	if gild or crimson:
		var mark := ColorRect.new()
		mark.color = Style.C_GOLD if gild else Style.C_CRIMSON
		mark.custom_minimum_size = Vector2(side * 0.22, side * 0.22)
		mark.size = mark.custom_minimum_size
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.add_child(mark)
	return d


func _face(pos: int) -> Array:
	var di: int = st.roll_d[pos]
	var fi: int = st.roll_f[pos]
	if di < 0:
		return [Round.PLAIN[fi], 0, 0]
	var die: Dictionary = ctx.dice[di]
	return [die.f[fi], die.g[fi], die.c[fi]]


## Roll position -> group index (keepable dice only).
func _held() -> Dictionary:
	var out := {}
	for gi in gs.size():
		for p in gs[gi].pos:
			out[p] = gi
	return out


func _roll_die(pos: int, held: Dictionary) -> Control:
	var f := _face(pos)
	var b := Button.new()
	b.custom_minimum_size = Vector2(DIE_SIDE, DIE_SIDE)
	b.flat = false
	b.set_meta("kind", "die")
	var on: bool = held.has(pos) and sel.has(held[pos])
	var eaten := eat == pos
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.set_border_width_all(6 if (on or eaten) else 0)
	box.border_color = Style.C_GOLD if on else Style.C_CRIMSON
	box.set_corner_radius_all(18)
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, box)
	var d := _die_face(f[0], f[1], f[2], DIE_SIDE - 12)
	d.position = Vector2(6, 6)
	b.add_child(d)
	if not held.has(pos) and not eaten:
		b.modulate = Color(1, 1, 1, 0.55)
	b.pressed.connect(func(): _tap(pos))
	return b


## Tap a die: its whole group toggles. A die you can't keep: Gluttony eats it (once a turn).
func tap(pos: int) -> void:
	_tap(pos)


func _tap(pos: int) -> void:
	if phase != "pick":
		return
	var held := _held()
	if held.has(pos):
		var gi: int = held[pos]
		if sel.has(gi):
			sel.erase(gi)
		else:
			sel[gi] = true
	elif Round.can_eat(ctx, st):
		eat = -1 if eat == pos else pos
	msg = T.run("hint_pick")
	var pv := _preview()
	if pv.all and not sel.is_empty():
		msg = T.run("hint_bank_only" if pv.bank_only else "hint_all")
	_draw_play()


func _sel_list() -> Array:
	var l: Array = sel.keys()
	l.sort()
	return l


## What keeping the selection would make: Points, Mult, the Bank, bust chance of the rethrow.
func _preview() -> Dictionary:
	if phase != "pick" or sel.is_empty():
		return {"p": st.p, "m": st.m, "bank": 0, "bust": 0.0, "bank_only": false, "all": false}
	var s2: Dictionary = st.duplicate()
	Round.keep(ctx, s2, gs, _sel_list(), eat)
	var all: bool = s2.bank_only or s2.left.size() == ctx.dice.size() and s2.returned and not st.returned
	return {"p": s2.p, "m": s2.m, "bank": Round.bank_value(ctx, s2).score, "bust": _bust_chance(s2.left), "bank_only": s2.bank_only, "all": all}


func _bust_chance(left: Array) -> float:
	if left.is_empty():
		return 0.0
	var r := RandomNumberGenerator.new()
	r.seed = 11
	var s := {"left": left, "roll_d": [], "roll_f": []}
	var busts := 0
	for i in 300:
		var rf: Array = []
		for d in left:
			rf.append(r.randi_range(0, 5))
		s.roll_d = left
		s.roll_f = rf
		if Round.groups(ctx, s).is_empty():
			busts += 1
	return busts / 300.0


func _keep_selection() -> void:
	for gi in _sel_list():
		for p in gs[gi].pos:
			_kept.append(_face(p))
	if eat >= 0:
		_kept.append(_face(eat))
	Round.keep(ctx, st, gs, _sel_list(), eat)
	sel = {}
	eat = -1


func _on_throw() -> void:
	if phase == "pick":
		if sel.is_empty():
			return
		_keep_selection()
		if st.bank_only:
			_bank()
			return
	elif phase != "throw":
		return
	gs = Round.throw(ctx, st, rng)
	if gs.is_empty():
		var b: Dictionary = run.finish_bust(ctx, st)
		phase = "after"
		msg = T.run("bust") + ("  " + T.run("banked", {"n": b.score}) if b.score > 0 else "")
		_after_turn()
		return
	phase = "pick"
	msg = T.run("hint_pick")
	if Round.can_eat(ctx, st) and not Round.unkeepable(st, gs).is_empty():
		msg += " " + T.run("hint_eat")
	_draw_play()


func _on_bank() -> void:
	if phase != "pick" or sel.is_empty():
		return
	_keep_selection()
	_bank()


func _bank() -> void:
	var b: Dictionary = run.finish_bank(ctx, st)
	st.roll_d = []
	phase = "after"
	msg = T.run("banked", {"n": b.score})
	_after_turn()


func _after_turn() -> void:
	if run.status == "shop":
		var p: Dictionary = run.last_pay
		msg += "  " + T.run("cleared", {"g": p.clear + p.unused + p.interest})
	_draw_play()


func _on_next() -> void:
	match run.status:
		"play": _new_turn()
		"shop":
			save_run()
			_show_shop()
		_:
			_end()


# ---------- shop ----------

func _show_shop() -> void:
	phase = "shop"
	_clear()
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)
	var v := _vbox(scroll)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text(v, T.run("shop"), 70, Style.C_GOLD)
	var c: int = run.circle + 1
	var rname: String = T.run("sin_round", {"sin": run.ruler()}) if run.is_sin_round() else T.run("trial", {"n": run.round_i + 1})
	_text(v, T.run("shop_next", {"c": c, "round": rname, "t": run.round_target(run.circle, run.round_i)}), 34)
	_text(v, T.run("shop_ruler", {"sin": run.ruler(), "c": c, "twist": Rulers.text(run.ruler(), run.cfg)}), 34, Style.C_STRIKE.lightened(0.35))
	_text(v, "%s %d" % [T.run("gold"), run.gold], 46, Style.C_GOLD)
	for i in run.offers.relics.size():
		var id: String = run.offers.relics[i]
		if id == "":
			continue
		var b := _button(v, T.run("shop_relic", {"name": Relics.name_of(id), "rar": T.run("rar_" + Relics.rarity(id)), "price": Shop.relic_price(run, id), "text": Relics.text(id)}), func():
			if Shop.buy_relic(run, i):
				_show_shop(), 150, "offer")
		_dim(b, Shop.can_buy_relic(run, i))
	if run.offers.die:
		var b := _button(v, T.run("shop_die", {"price": Shop.die_price(run), "n": run.dice.size(), "max": run.cfg.max_dice}), func():
			if Shop.buy_die(run):
				_show_shop(), 150, "offer")
		_dim(b, Shop.can_buy_die(run))
	for i in run.offers.repaints.size():
		var k: String = run.offers.repaints[i]
		if k == "":
			continue
		var b := _button(v, T.run("shop_repaint", {"name": Shop.REPAINT_TEXT[k][0], "price": run.cfg.repaint_price, "text": Shop.REPAINT_TEXT[k][1]}), func(): _repaint_picker(i), 150, "offer")
		_dim(b, Shop.can_buy_repaint(run, i))
	var rb := _button(v, T.run("shop_reroll", {"price": Shop.reroll_price(run)}), func():
		if Shop.reroll(run):
			_show_shop(), TARGET, "reroll")
	_dim(rb, run.gold >= Shop.reroll_price(run))
	_relic_row(v, true)
	var cc := CenterContainer.new()
	v.add_child(cc)
	_seal(cc, T.run("shop_leave"), leave_shop, "leave")


func leave_shop() -> void:
	run.leave_shop()
	_new_turn()


func _repaint_picker(offer_i: int) -> void:
	var ov := _overlay()
	var v: VBoxContainer = ov.get_meta("v")
	_text(v, T.run("shop_pick_face"), 34)
	for d in run.dice.size():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", int(GAP * 0.5))
		v.add_child(row)
		var die: Dictionary = run.dice[d]
		for fi in range(1, 6):
			var mark := " *" if die.g[fi] else ""
			mark += " +" if die.c[fi] else ""
			var b := _button(row, "%d%s" % [die.f[fi], mark], func():
				if Shop.buy_repaint(run, offer_i, d, fi):
					_close_popup()
					_show_shop(), TARGET, "face")
			b.custom_minimum_size.x = TARGET
			_dim(b, Shop.can_repaint(run, d, fi))
	_button(v, T.run("shop_cancel"), _close_popup, TARGET, "close")


func _relic_popup(i: int, selling: bool) -> void:
	var ov := _overlay()
	var v: VBoxContainer = ov.get_meta("v")
	var id: String = run.relics[i].id
	_text(v, Relics.name_of(id), 56, Style.C_GOLD)
	_text(v, "%s. %s" % [T.run("rar_" + Relics.rarity(id)).capitalize(), Relics.text(id)], 36)
	if selling:
		_button(v, T.run("sell", {"n": Shop.sell_value(run, id)}), func():
			Shop.sell_relic(run, i)
			_close_popup()
			_show_shop(), TARGET, "sell")
	_button(v, T.run("close"), _close_popup, TARGET, "close")


## A dimmed full-screen card; tap Close (or outside) to dismiss.
func _overlay() -> Control:
	_close_popup()
	var ov := Control.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(Style.C_BLACK, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_close_popup())
	ov.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(cc)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.C_INK
	sb.border_color = Style.C_GOLD_DEEP
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(40)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size.x = 900
	cc.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(GAP))
	panel.add_child(v)
	ov.set_meta("v", v)
	add_child(ov)
	_popup = ov
	return ov


func _close_popup() -> void:
	if _popup and is_instance_valid(_popup):
		_popup.queue_free()
	_popup = null


func _rules_card() -> void:
	var ov := _overlay()
	var v: VBoxContainer = ov.get_meta("v")
	_text(v, T.run("rules_title"), 56, Style.C_GOLD)
	for line in T.run("rules_body").split("\n"):
		_text(v, line, 34)
	_button(v, T.run("rules_ok"), _close_popup, TARGET, "rules_ok")


# ---------- save, end, log ----------

func play_secs() -> float:
	return float(run.stats.get("play_secs", 0.0)) + (Time.get_ticks_msec() - _t0) / 1000.0


func save_run() -> void:
	run.stats.play_secs = play_secs()
	_t0 = Time.get_ticks_msec()
	if host and not host.save_enabled:
		return
	var f := FileAccess.open(RUN_SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(run.to_dict()))
		f.close()


static func load_run():
	if not FileAccess.file_exists(RUN_SAVE):
		return null
	var d = JSON.parse_string(FileAccess.get_file_as_string(RUN_SAVE))
	if not d is Dictionary:
		return null
	var r = RunState.new()
	return r if r.from_dict(d) else null


static func clear_save() -> void:
	if FileAccess.file_exists(RUN_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_SAVE))


func _end() -> void:
	phase = "end"
	clear_save()
	var mins := play_secs() / 60.0
	if not host or host.save_enabled:
		log_run(run, mins)
	_clear()
	var v := _vbox(_root, GAP * 2)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	_text(v, T.run("won") if run.status == "won" else T.run("lost", {"c": run.circle + 1}), 60, Style.C_GOLD)
	_text(v, T.run("end_stats", {"sin": run.sin, "c": run.reached() if run.status != "won" else 7, "turns": run.stats.turns, "busts": run.stats.busts, "best": run.stats.best_bank, "min": "%.0f" % mins}), 36)
	_relic_row(v, false)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(GAP * 3))
	v.add_child(row)
	_seal(row, T.run("new_run"), func(): new_run.emit(), "new_run")
	_seal(row, T.run("to_menu"), func(): to_menu.emit(), "menu")


## One line per finished run: Sin, Circle reached, relics, busts, turns, minutes.
static func log_run(r, mins: float) -> void:
	var line := {
		"date": Time.get_datetime_string_from_system(), "sin": r.sin, "won": r.status == "won",
		"circle": r.reached(), "relics": r.relics.map(func(x): return x.id), "busts": r.stats.busts,
		"turns": r.stats.turns, "minutes": snappedf(mins, 0.1), "best_bank": r.stats.best_bank,
	}
	var f := FileAccess.open(RUN_LOG, FileAccess.READ_WRITE if FileAccess.file_exists(RUN_LOG) else FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(JSON.stringify(line))
		f.close()


## Debug export: the log to the clipboard, and a copy in Documents where the OS allows it. Returns the run count.
static func export_log() -> int:
	var text := FileAccess.get_file_as_string(RUN_LOG) if FileAccess.file_exists(RUN_LOG) else ""
	DisplayServer.clipboard_set(text)
	var path := ProjectSettings.globalize_path(RUN_LOG)
	var docs := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if docs != "":
		var f := FileAccess.open(docs.path_join("sinners_runs.jsonl"), FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()
			path = docs.path_join("sinners_runs.jsonl")
	print("run log exported: ", path)
	return text.count("\n")
