## Screenshots of the hand screen at phone size, for Ben. Needs a window (not --headless):
## godot --path . --resolution 1080x2340 --script res://tools/shots.gd   ->  build/shots/*.png
extends SceneTree

const HandScreen = preload("res://ui/hand_screen.gd")

var h
var n := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/shots"))
	DirAccess.remove_absolute("user://shots.cfg")
	h = HandScreen.new()
	h.save_path = "user://shots.cfg"
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(h)
	await _shot("tutorial_intro")
	h._on_card_btn()
	h._on_throw()
	h._on_die(0)
	await _shot("tutorial_pick")
	h._on_slot(0)
	h._on_card_btn()
	h._on_throw()
	await _shot("tutorial_skull_card")
	h._on_card_btn()
	h._on_slot(2)
	h._on_card_btn()
	h._on_throw()
	h._on_die(0)
	h._on_slot(0)
	await _shot("tutorial_tier1_card")
	h._on_card_btn()
	h._on_throw()
	h._on_card_btn()
	h._on_die(0)
	h._on_slot(4)
	h._on_card_btn()
	await _shot("tutorial_free")
	h._on_cash()
	await _shot("result_card")
	h._on_card_btn()
	while not h.cards.is_empty():
		await _shot("first_time_card")
		h._on_card_btn()
	h._on_throw()
	while not h.cards.is_empty():
		h._on_card_btn()
	await _shot("real_hand_throw")
	h._on_help()
	await _shot("rules_card")
	DirAccess.remove_absolute("user://shots.cfg")
	quit(0)


func _shot(name: String) -> void:
	for i in 4:
		await process_frame
	n += 1
	var img := root.get_texture().get_image()
	var path := "res://build/shots/%02d_%s.png" % [n, name]
	img.save_png(ProjectSettings.globalize_path(path))
	print("shot ", path, " ", img.get_size())
