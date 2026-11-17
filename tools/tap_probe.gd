## REPLY 34 item 1: does a tap on the table's Throw seal also count as a background tap (skip a beat; two quick
## ones skip to my next decision)? Plays a match with the table; at each of my decisions taps Throw as a phone
## would: a touch press and release at its centre with no motion before it. Reports, per tap, whether main took
## it as a background tap (main._press_at set) and whether the queue was told to skip.
## godot --path . --script res://tools/tap_probe.gd -- --table
extends SceneTree

const Tuning = preload("res://ui/tuning.gd")

var main
var taps := 0
var report: Array[String] = []
var waited := 0.0


func _initialize() -> void:
	Tuning.speed = 1.0
	Engine.time_scale = 4.0
	await process_frame
	main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	main.save_enabled = false
	main.tutorial_enabled = false
	main.first_game_enabled = true
	main._start(main.SIN_SCRIPTS[2])


func _find_throw(n: Node) -> Button:
	for c in n.get_children():
		if c is Button and c.visible and c.get_global_rect().size.x > 100 and str(c.get_meta("word", "")) == "Throw":
			return c
		var r := _find_throw(c)
		if r:
			return r
	return null


var use_touch := true


func _touch(pos: Vector2, pressed: bool) -> void:
	if use_touch:
		var e := InputEventScreenTouch.new()
		e.position = pos
		e.pressed = pressed
		e.index = 0
		Input.parse_input_event(e)
	else:
		var m := InputEventMouseButton.new()
		m.position = pos
		m.global_position = pos
		m.button_index = MOUSE_BUTTON_LEFT
		m.pressed = pressed
		Input.parse_input_event(m)


func _process(delta: float) -> bool:
	if main == null or main.game == null or main._table == null:
		return false
	if Engine.get_process_frames() % 600 == 0:
		print("probe: live %s busy %s buttons %d" % [main._table._live("roll") != null, main._q.busy(), main._table._buttons.size()])
	var live = main._table._live("roll")
	if tapping or live == null or main._q.busy():
		waited = 0.0
		return false
	waited += delta
	if waited < 0.6:
		return false
	waited = 0.0
	var tb: Button = _find_seal()
	if tb == null:
		report.append("no Throw seal found")
		_done()
		return false
	var cp: Vector2 = tb.get_global_transform_with_canvas() * (tb.size / 2.0)
	_tap(root.get_final_transform() * cp)
	return false


var tapping := false


func _tap(c: Vector2) -> void:
	tapping = true
	var t0: float = main._press_t
	_touch(c, true)
	await process_frame
	var bg: bool = main._press_at != Vector2.INF
	var seen: bool = main._press_t != t0  # main._input saw the press
	_touch(c, false)
	await process_frame
	await process_frame
	taps += 1
	use_touch = taps < 3  # taps 1-3 by touch, then 4-6 by a mouse press with no motion before it
	report.append("tap %d (%s) at %s: hovered %s, seen by main._input %s, counted as a background tap %s, busy after %s, last_tap %.2f, skip_all %s" % [taps, "touch" if taps <= 3 else "mouse, no motion", c, str(main.get_viewport().gui_get_hovered_control()), seen, bg, main._q.busy(), main._last_tap, main._q.skip_all])
	tapping = false
	if taps >= 6:
		_done()

func _find_seal() -> Button:
	var view = main._table.view
	for c in view.find_children("*", "Button", true, false):
		if c.visible and c.get_global_rect().size.x >= 150 and c.get_global_rect().position.x > 600 and c.get_global_rect().position.y > 1500:
			return c
	return null


func _done() -> void:
	for r in report:
		print(r)
	quit()
