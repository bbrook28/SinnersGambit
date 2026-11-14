## Steps through the whole tutorial headless: taps every read step, presses the one live button on
## every act step, and checks the rigged dice and scores land where ui/tutorial_game.gd says.
## godot --headless --path . --script res://tests/tutorial_check.gd
extends SceneTree

const TutorialGame = preload("res://ui/tutorial_game.gd")
const TutorialDice = preload("res://ui/tutorial_dice.gd")
const RulesText = preload("res://ui/rules_text.gd")
const Rules = preload("res://core/rules.gd")
const TIMEOUT := 180.0  # real seconds

var main
var fails: Array[String] = []
var seen := -1          # the last SCRIPT step checked
var pressed_at := -1    # the act step whose button was pressed
var started := 0.0
var steps_run := 0


func _initialize() -> void:
	Engine.time_scale = 50.0
	started = Time.get_ticks_msec() / 1000.0
	# The rig itself: every seed must give exactly its faces through Rules.roll.
	for s in TutorialGame.SCRIPT:
		if s.has("faces"):
			_check_seed(s.faces)
	for t in TutorialGame.BOT_TURNS:
		for f in t:
			_check_seed(f)
	for k in RulesText.TUTORIAL:
		if RulesText.tutorial(k, {"ability": "x"}).find("{") >= 0:
			fails.append("TUTORIAL.%s has an unfilled placeholder" % k)
	await process_frame
	main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	main.save_enabled = false
	main.tutorial_enabled = false
	main.start_tutorial(false)


func _check_seed(faces: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = TutorialDice.seed_for(faces)
	var got := Rules.roll(rng, faces.size())
	if str(got) != str(faces):
		fails.append("seed for %s gives %s" % [faces, got])


func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() / 1000.0 - started > TIMEOUT:
		fails.append("timed out at step %d" % (main._tutor.index if main and main._tutor else -1))
		_finish()
		return true
	if main == null or main._tutor == null:
		return false
	var t = main._tutor
	var ov = t.overlay
	var i: int = t.index - 1
	if ov.mode == ov.READ and ov._choices.visible:
		_step_started(i, t)
		_finish()
		return true
	if ov.mode == ov.READ and ov._ready_for_tap:
		_step_started(i, t)
		ov.advance()
	elif ov.mode == ov.ACT and pressed_at != i:
		_step_started(i, t)
		var live: Array = main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion() and not b.disabled)
		if live.size() != 1:
			fails.append("step %d (%s): %d live buttons, want 1" % [i, TutorialGame.SCRIPT[i].get("say", ""), live.size()])
		if live.is_empty():
			return false
		var b: Button = live[0]
		if not ov.hole.encloses(ov.rest_rect(b)) or not ov.hole.has_point(b.get_global_rect().get_center()):
			fails.append("step %d: the live button %s is outside the spotlight %s" % [i, b.get_global_rect(), ov.hole])
		if ov._has_point(b.get_global_rect().get_center()):
			fails.append("step %d: the overlay blocks the live button" % i)
		pressed_at = i
		b.pressed.emit()
	return false


## State checks as each step begins (the board has caught up; core waits on the step).
func _step_started(i: int, t) -> void:
	if i == seen:
		return
	seen = i
	steps_run += 1
	var g = main.game
	var me = main.human_player()
	var s: Dictionary = TutorialGame.SCRIPT[i]
	match s.get("say", "end" if s.get("end", false) else ""):
		"scored":
			_want(i, str(g.turn.faces), "[6, 4, 3]", "faces")
			_want(i, g.turn.points, 75, "turn points")
		"strike":
			_want(i, str(g.turn.faces), "[6, 5, 1]", "faces")
			_want(i, g.turn.strikes, 1, "Strikes")
			_want(i, g.turn.points, 157, "turn points")
		"buy":
			_want(i, me.score, 157, "score after bank")
		"bot":
			_want(i, g.current == me, false, "bot's turn")
			_want(i, str(g.turn.faces), "[6, 4, 3]", "bot faces")
		"turn2":
			_want(i, me.dice, 4, "dice after buying")
			_want(i, me.score, 57, "score after buying")
		"sin":
			_want(i, str(g.turn.faces), "[4, 3, 3, 2]", "faces")
		"glance":
			_want(i, str(g.turn.faces), "[4, 3, 3, 2, 6]", "faces with the copy")
			_want(i, g.turn.points, 75, "turn points")
			_want(i, g.turn.strikes, 1, "Strikes")
		"bust":
			_want(i, me.in_purgatory, true, "in Purgatory")
			_want(i, me.score, 57, "score after bust")
		"purgatory":
			_want(i, me.in_purgatory, false, "freed")
			_want(i, str(g.turn.redeem_faces), "[6, 3, 2, 5]", "Purgatory throw")
			_want(i, me.score, 57, "score (nothing paid)")
		"end":
			_want(i, t.done(), true, "script finished")


func _want(i: int, got, want, what: String) -> void:
	if got != want:
		fails.append("step %d (%s): %s is %s, want %s" % [i, TutorialGame.SCRIPT[i].get("say", "end"), what, got, want])


func _finish() -> void:
	if steps_run != TutorialGame.SCRIPT.size() - 1:  # the Purgatory rig has no screen of its own
		fails.append("ran %d steps, want %d" % [steps_run, TutorialGame.SCRIPT.size() - 1])
	# Skip ends it and marks it done.
	main._starting = false
	main.tutorial_pending = true
	main._tutor.overlay.skipped.emit()
	if main.tutorial_pending:
		fails.append("Skip didn't mark the tutorial done")
	for f in fails:
		print(f)
	print("TUTORIAL PASSED (%d steps)" % steps_run if fails.is_empty() else "TUTORIAL FAILED (%d)" % fails.size())
	quit()
