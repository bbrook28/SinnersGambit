## Plays full UI games headless, pressing a random prompt button each time, one game per Sin.
## godot --headless --path . --script res://tests/ui_autoplay.gd
extends SceneTree

const SIN_COUNT := 7

var main
var sin_i := 0
var games_done := 0
var presses := 0


func _initialize() -> void:
	Engine.time_scale = 50.0
	await process_frame
	_next()


func _next() -> void:
	if main:
		main.queue_free()
	if sin_i >= SIN_COUNT:
		print("ALL PASSED: %d games, %d human choices" % [games_done, presses])
		quit()
		return
	main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	main._start(main.SIN_SCRIPTS[sin_i])
	sin_i += 1


func _process(_delta: float) -> bool:
	if main == null or main._buttons == null:
		return false
	var bs: Array = main._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion())
	if bs.is_empty():
		return false
	if bs[0].text == "New game":
		games_done += 1
		print("%s: %s" % [main.human.label, main._prompt_label.get_parsed_text()])
		_next()
		return false
	presses += 1
	bs[randi() % bs.size()].pressed.emit()
	return false
