## REPLY 37: the Continue save at the end of a match.
## (A) save_enabled on (a real game): the game saves as you answer, and a finished game deletes the save, so
##     Continue cannot resume a dead game.
## (B) save_enabled off (tests and tools): with no save on disk, the finished game leaves none (no Continue seal
##     appears); with a save on disk, the finished game leaves it byte for byte as it was. A test's game never
##     writes one, so Continue can only ever offer the real game.
## Keeps the real save and settings aside and puts them back. godot --headless --path . --script res://tests/save_check.gd
extends SceneTree

const SAVE := "user://save.json"
const SETTINGS := "user://settings.cfg"

var fails := 0
var kept := {}


func _initialize() -> void:
	for p in [SAVE, SETTINGS]:
		kept[p] = FileAccess.get_file_as_bytes(p) if FileAccess.file_exists(p) else null
	Engine.time_scale = 40.0
	# (A) a real game
	_remove(SAVE)
	var saw_save := await _play(true)
	_check(saw_save, "A: the game saved while it was played")
	_check(not FileAccess.file_exists(SAVE), "A: the finished game deleted the save")
	# (B1) a test's game, no save on disk
	_remove(SAVE)
	var wrote := await _play(false)
	_check(not wrote and not FileAccess.file_exists(SAVE), "B1: no save written, none left")
	var m = load("res://ui/main.gd")
	_check(m.load_save().is_empty(), "B1: nothing for Continue to offer")
	# (B2) a test's game with the real save on disk
	var real := '{"v": 0, "real": true}'
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	f.store_string(real)
	f.close()
	await _play(false)
	_check(FileAccess.file_exists(SAVE) and FileAccess.get_file_as_string(SAVE) == real, "B2: the real save is left byte for byte")
	for p in kept:
		if kept[p] == null:
			_remove(p)
		else:
			var w := FileAccess.open(p, FileAccess.WRITE)
			w.store_buffer(kept[p])
			w.close()
	Engine.time_scale = 1.0
	print("SAVE CHECK PASSED" if fails == 0 else "SAVE CHECK FAILED (%d)" % fails)
	quit()


func _remove(p: String) -> void:
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


## Plays one game to its end, answering at random. Returns whether a save file appeared while it played
## (one that wasn't there, or had changed, when it began).
func _play(save_on: bool) -> bool:
	var before := FileAccess.get_file_as_string(SAVE) if FileAccess.file_exists(SAVE) else ""
	var a = load("res://ui/main.tscn").instantiate()
	root.add_child(a)
	a.save_enabled = save_on
	a.tutorial_enabled = false
	a.first_game_enabled = true
	await process_frame
	a._start(a.SIN_SCRIPTS[randi() % 7])
	var seen := false
	var frames := 0
	while frames < 200000:
		await process_frame
		frames += 1
		if FileAccess.file_exists(SAVE) and FileAccess.get_file_as_string(SAVE) != before:
			seen = true
		var bs: Array = a._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion() and not b.disabled)
		if bs.is_empty() or a._q.busy():
			continue
		if str(bs[0].get_meta("value", "")) == "new":
			break
		bs[randi() % bs.size()].pressed.emit()
	await process_frame
	a.queue_free()
	await process_frame
	return seen
