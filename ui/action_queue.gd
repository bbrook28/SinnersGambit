## Plays presentation actions one after another, so the screen never runs ahead of itself.
## The rules push actions (via ui/main.gd) faster than they play; core/game.gd's awaited
## view.beat() calls drain() so the rules can't get more than one step ahead of the screen.
## Docs/UXPass.md.
extends Node

signal drained

const MIN_BEAT := 0.08   # no beat shrinks below this at any speed, unless skipped

## Global speed: 1, 2 or 4. Every wait() and every tween made with tween() obeys it.
var speed := 1.0
var _actions: Array[Callable] = []
var _running := false
var _skip_beat := false   # finish the current beat now (one tap)
var skip_all := false     # skip every beat until the player's next decision (double tap)


## action: a Callable that may await. It plays one beat (use wait() for its timing).
func push(action: Callable) -> void:
	_actions.append(action)
	if not _running:
		_run()


func busy() -> bool:
	return _running or not _actions.is_empty()


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
	_running = false
	drained.emit()


## Holds the current beat for t seconds at 1x. Cut short by a tap.
func wait(t: float) -> void:
	if t <= 0.0 or skip_all:
		return
	var left := maxf(MIN_BEAT, t / speed)
	while left > 0.0 and not _skip_beat and not skip_all:
		await get_tree().process_frame
		left -= get_process_delta_time()


## A tween that runs at the global speed (and jumps to its end when the beat is skipped).
func tween(owner: Node) -> Tween:
	var tw := owner.create_tween()
	tw.set_speed_scale(1000.0 if skip_all else speed)
	return tw


func skip_beat() -> void:
	_skip_beat = true


func skip_to_decision() -> void:
	skip_all = true
	_skip_beat = true
