## Plays presentation actions one after another, so the screen never runs ahead of itself.
## The rules push actions (via ui/main.gd) faster than they play; core/game.gd's awaited
## view.beat() calls drain() so the rules can't get more than one step ahead of the screen.
## Timing comes from ui/tuning.gd (Tuning.speed is the global multiplier). Docs/archive/UXPass.md.
extends Node

const Tuning = preload("res://ui/tuning.gd")

signal drained

var _actions: Array[Callable] = []
var _running := false
var _skip_beat := false   # finish the current beat now (one tap)
var skip_all := false     # skip every beat until the player's next decision (double tap)
var _tweens: Array[Tween] = []
## Held while the rulebook or an explanation card is open: no new beat starts, waits don't count
## down and the beat's tweens stop where they are.
var paused := false


func set_paused(on: bool) -> void:
	paused = on
	for tw in _tweens:
		if tw.is_valid():
			if on:
				tw.pause()
			else:
				tw.play()


## action: a Callable that may await. It plays one beat (use wait() for its timing).
func push(action: Callable) -> void:
	_actions.append(action)
	if not _running:
		_run()


func busy() -> bool:
	return _running or not _actions.is_empty()


func skipping() -> bool:
	return _skip_beat or skip_all


## Returns once everything queued so far has played.
func drain() -> void:
	if busy():
		await drained


func _run() -> void:
	_running = true
	while not _actions.is_empty():
		while paused:
			await get_tree().process_frame
		var a: Callable = _actions.pop_front()
		_skip_beat = false
		await a.call()
		_finish_tweens()
	_running = false
	drained.emit()


## Seconds the queue has run, unpaused (game time: tests that scale Engine.time_scale scale this too).
var clock := 0.0


func _process(delta: float) -> void:
	if not paused:
		clock += delta


## REPLY 38: a rival's beat holds at least `floor_s` real seconds at 1x from `since` (a clock reading), only
## the Speed setting scaling it (not BOT_PACE). Cut short by a tap, like every wait.
func hold_to(since: float, floor_s: float) -> void:
	var left: float = floor_s / maxf(Tuning.speed, 0.01) - (clock - since)
	while left > 0.0 and not skipping():
		await get_tree().process_frame
		if not paused:
			left -= get_process_delta_time()


## Holds `seconds` real seconds at 1x (only the Speed setting scales it). Cut short by a tap.
func hold(seconds: float) -> void:
	await hold_to(clock, seconds)


## Holds for `seconds` at speed 1.0. Cut short by a tap.
func wait(seconds: float) -> void:
	if seconds <= 0.0 or skipping():
		return
	var left := Tuning.t(seconds)
	while left > 0.0 and not skipping():
		await get_tree().process_frame
		if not paused:
			left -= get_process_delta_time()


## A tween that runs at the global speed and jumps to its end when the beat is skipped.
func tween(owner: Node) -> Tween:
	var tw := owner.create_tween()
	tw.set_speed_scale(Tuning.rate())
	if skipping():
		tw.set_speed_scale(1000.0)
	_tweens = _tweens.filter(func(x): return x.is_valid())
	_tweens.append(tw)
	return tw


func _finish_tweens() -> void:
	for tw in _tweens:
		if tw.is_valid() and tw.is_running():
			tw.custom_step(1000.0)
	_tweens.clear()


func skip_beat() -> void:
	_skip_beat = true
	_finish_tweens()


func skip_to_decision() -> void:
	skip_all = true
	skip_beat()
