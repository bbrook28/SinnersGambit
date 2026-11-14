## Plays presentation actions one after another, so the screen never runs ahead of itself.
## The rules push actions (via ui/main.gd) faster than they play; core/game.gd's awaited
## view.beat() calls drain() so the rules can't get more than one step ahead of the screen.
## Timing comes from ui/tuning.gd (Tuning.speed is the global multiplier). Docs/UXPass.md.
extends Node

const Tuning = preload("res://ui/tuning.gd")

signal drained

var _actions: Array[Callable] = []
var _running := false
var _skip_beat := false   # finish the current beat now (one tap)
var skip_all := false     # skip every beat until the player's next decision (double tap)
var _tweens: Array[Tween] = []


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
		var a: Callable = _actions.pop_front()
		_skip_beat = false
		await a.call()
		_finish_tweens()
	_running = false
	drained.emit()


## Holds for `seconds` at speed 1.0. Cut short by a tap.
func wait(seconds: float) -> void:
	if seconds <= 0.0 or skipping():
		return
	var left := Tuning.t(seconds)
	while left > 0.0 and not skipping():
		await get_tree().process_frame
		left -= get_process_delta_time()


## A tween that runs at the global speed and jumps to its end when the beat is skipped.
func tween(owner: Node) -> Tween:
	var tw := owner.create_tween()
	tw.set_speed_scale(Tuning.speed)
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
