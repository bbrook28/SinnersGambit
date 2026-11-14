## Plays run mode through the real board (ui/main.gd -> ui/run_board.gd), headless, one run per Sin:
## taps dice, Throw, Bank, Next, buys in the shop, leaves. Checks every visible button is at least
## 44 pt and on screen, and that Continue's save resumes at the shop.
## godot --headless --path . --script res://tests/run_ui_check.gd
extends SceneTree

const Kits = preload("res://run/kits.gd")
const Shop = preload("res://run/shop.gd")
const Round = preload("res://run/round.gd")
const RunBoard = preload("res://ui/run_board.gd")
const TARGET := 44.0 * 1080.0 / 393.0

var main
var board
var fails: Array[String] = []
var sin_i := 0
var steps := 0
var screens := {}


func _initialize() -> void:
	Engine.time_scale = 50.0
	await process_frame
	await _all()


func _all() -> void:
	for s in Kits.ORDER:
		await _one(s)
	await _resume_check()
	if fails.is_empty():
		print("RUN UI CHECK PASSED: %d runs, %d steps, screens %s" % [Kits.ORDER.size(), steps, str(screens.keys())])
	else:
		for f in fails.slice(0, 30):
			print("FAIL: " + f)
		print("RUN UI CHECK FAILED: %d" % fails.size())
	quit()


func _fresh() -> void:
	if main:
		main.queue_free()
		await process_frame
	main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	main.save_enabled = false
	main.run_rules_seen = false
	await process_frame


func _one(sin: String) -> void:
	await _fresh()
	main._start_run(sin)
	for i in 40:
		await process_frame
		if main._run_board:
			break
	board = main._run_board
	if board == null:
		fails.append("%s: no board" % sin)
		return
	await _settle()
	_check(sin + " first turn (rules card)")
	board._close_popup()
	var guard := 0
	while board.phase != "end" and guard < 3000:
		guard += 1
		steps += 1
		match board.phase:
			"throw":
				board._on_throw()
			"pick":
				_pick()
			"after":
				board._on_next()
			"shop":
				if guard % 7 == 0:
					await _settle()
					_check(sin + " shop")
				_shop()
		if guard % 50 == 0:
			await _settle()
			_check("%s %s" % [sin, board.phase])
	await _settle()
	_check(sin + " end")
	if board.phase != "end":
		fails.append("%s: run didn't end" % sin)


## Tap one die of every group; Bank once the target is in reach or on two keeps, else Throw.
func _pick() -> void:
	var held: Dictionary = board._held()
	var done := {}
	for pos in held:
		if not done.has(held[pos]):
			done[held[pos]] = true
			board.tap(pos)
	var pv: Dictionary = board._preview()
	if pv.bank + board.run.score >= board.run.target or board.st.throws >= 3 or pv.bank_only:
		board._on_bank()
	else:
		board._on_throw()


func _shop() -> void:
	var run = board.run
	for i in run.offers.relics.size():
		if Shop.can_buy_relic(run, i):
			Shop.buy_relic(run, i)
	if run.offers.repaints.size() > 0 and Shop.can_buy_repaint(run, 0):
		board._repaint_picker(0)
		board._close_popup()
	board.leave_shop()


func _settle() -> void:
	for i in 3:
		await process_frame


func _check(screen: String) -> void:
	screens[screen.get_slice(" ", 1)] = true
	var vp: Vector2 = board.get_viewport_rect().size
	for b in _buttons(board):
		if not b.is_visible_in_tree():
			continue
		var r: Rect2 = b.get_global_rect()
		if r.size.x < TARGET - 0.5 or r.size.y < TARGET - 0.5:
			fails.append("%s: '%s' is %.0fx%.0f px (44 pt = %.0f)" % [screen, _label(b), r.size.x, r.size.y, TARGET])
		if r.position.x < -0.5 or r.end.x > vp.x + 0.5:
			fails.append("%s: '%s' off screen (x %.0f-%.0f)" % [screen, _label(b), r.position.x, r.end.x])


func _label(b: Button) -> String:
	return b.text.get_slice("\n", 0) if b.text != "" else str(b.get_meta("kind", b.name))


func _buttons(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_buttons(c))
	return out


## Continue: a run saved on entering a shop loads back into that shop.
func _resume_check() -> void:
	await _fresh()
	var RunState = load("res://run/run_state.gd")
	var run = RunState.new()
	run.start("Lust", 4)
	run._end_round(true)
	var f := FileAccess.open(RunBoard.RUN_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify(run.to_dict()))
	f.close()
	var back = RunBoard.load_run()
	if back == null or back.status != "shop" or back.gold != run.gold:
		fails.append("Continue: the save didn't load into the shop")
	main._start_run("", back)
	for i in 40:
		await process_frame
		if main._run_board:
			break
	if main._run_board == null or main._run_board.phase != "shop":
		fails.append("Continue: board isn't on the shop")
	RunBoard.clear_save()
