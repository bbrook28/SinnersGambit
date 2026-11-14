## Continue rebuilds the same game: play a game to N answers, take its save (through JSON, as on
## disk), rebuild it in a fresh main and compare every score, dice count and the supply at the
## same decision. godot --headless --path . --script res://tests/replay_check.gd
extends SceneTree

const ANSWERS := [5, 25, 60]


func _initialize() -> void:
	var fails := 0
	for n in ANSWERS:
		fails += await _check(n)
	print("REPLAY ALL PASSED" if fails == 0 else "REPLAY FAILED (%d)" % fails)
	quit()


func _check(n: int) -> int:
	Engine.time_scale = 40.0
	var a = await _main()
	a._start(a.SIN_SCRIPTS[randi() % 7])
	while true:
		await process_frame
		if not _waiting(a):
			continue
		if a.human.record.size() >= n or _buttons(a)[0].text == "New game":
			break
		var bs := _buttons(a)
		bs[randi() % bs.size()].pressed.emit()
	var want := _state(a)
	var saved = JSON.parse_string(JSON.stringify(a._save))
	a.queue_free()
	await process_frame
	var b = await _main()
	b._start(null, saved)
	var frames := 0
	while frames < 20000:
		await process_frame
		frames += 1
		if _waiting(b) and not b._replaying:
			break
	var got := _state(b)
	b.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	if got == want:
		print("replay ok at %d answers: %s" % [saved.choices.size(), want])
		return 0
	print("REPLAY MISMATCH at %d answers\n  want %s\n  got  %s" % [saved.choices.size(), want, got])
	return 1


func _main():
	var m = load("res://ui/main.tscn").instantiate()
	m.save_enabled = false
	root.add_child(m)
	await process_frame
	return m


func _buttons(m) -> Array:
	if m._buttons == null:
		return []
	return m._buttons.get_children().filter(func(x): return not x.is_queued_for_deletion() and x.visible)


func _waiting(m) -> bool:
	return not _buttons(m).is_empty() and not m._q.busy()


func _state(m) -> Array:
	var s := [m.game.supply, m._prompt_label.get_parsed_text()]
	for p in m.game.players:
		s.append([p.sin.sin_name, p.score, p.dice])
	return s
