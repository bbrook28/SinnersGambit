## Loads every script (.gd) and scene (.tscn) in the project and fails on any parse or load error.
## Run it first: a script that fails to compile makes every screen that preloads it fall back silently
## (Ben, 2026-11-15: a parse error in ui/table_blockout.gd drew the title screen in every table fixture).
## godot --headless --path . --script res://tests/load_check.gd
extends SceneTree

const SKIP := ["res://.godot", "res://build", "res://android", "res://addons"]

var bad: Array = []
var count := 0


func _initialize() -> void:
	_walk("res://")
	if bad.is_empty():
		print("LOAD CHECK PASSED: %d scripts and scenes" % count)
		quit(0)
	else:
		printerr("LOAD CHECK FAILED: %d of %d: %s" % [bad.size(), count, ", ".join(bad)])
		quit(1)


func _walk(dir: String) -> void:
	for s in SKIP:
		if dir.trim_suffix("/") == s:
			return
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		if not sub.begins_with("."):
			_walk(dir.path_join(sub))
	for f in d.get_files():
		if f.ends_with(".gd") or f.ends_with(".tscn"):
			_check(dir.path_join(f))


func _check(path: String) -> void:
	count += 1
	if path == get_script().resource_path:
		return  # itself: already running
	var r = ResourceLoader.load(path)
	if r == null:
		bad.append(path)
		return
	if r is Script and not r.can_instantiate():
		bad.append(path)
	elif r is PackedScene and not r.can_instantiate():
		bad.append(path)
