## Screenshots of the step 1 pass-and-play screen at phone size, for Ben. Needs a window (not --headless):
## godot --path . --resolution 1080x2340 --script res://tools/table_shots.gd   ->  build/table_shots/*.png
## The two-player table: add  -- seats=2 dir=table_shots_2p
extends SceneTree

const TableScreen = preload("res://ui/table_screen.gd")
const Rules = preload("res://game/rules.gd")

var h
var n := 0
var dir := "table_shots"   # build/<dir>; pass -- dir=<name> to keep a second screen shape beside the first
var seats := 4             # pass -- seats=2 for the two-player table


class Faces:
	var queue: Array = []
	func _init(f: Array) -> void:
		queue = f.duplicate()
	func randi_range(_a: int, _b: int) -> int:
		return 4 if queue.is_empty() else queue.pop_front()   # past the script every die shows 4


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("dir="):
			dir = a.substr(4)
		if a.begins_with("seats="):
			seats = int(a.substr(6))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/" + dir))
	for f in DirAccess.get_files_at("res://build/" + dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://build/%s/%s" % [dir, f]))
	if seats == 2:
		await _two()
		quit(0)
		return
	h = TableScreen.new()
	# P1 Wrath 4,5,1; P2 Lust 1,2,3 (swaps); Spark rerolls to 2; P3 Gluttony 6,4,1; P4 Pride 6,6,1
	h.rng = Faces.new([4, 5, 1,  1, 2, 3,  2,  6, 4, 1,  6, 6, 1])
	h.sins = ["wrath", "lust", "gluttony", "pride"]
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(h)
	await _shot("how_to_play")
	tap("got_it")
	await _shot("pass_the_phone")
	tap("sin0")
	await _shot("sin_card_wrath")
	tap("close")
	tap("sin3")
	await _shot("sin_card_pride")
	tap("close")
	tap("ready")
	await _shot("roll")
	tap("roll")
	await _shot("gambit_wrath")
	tap("buy")
	await _shot("bought_a_die")
	tap("points")
	tap("other2")
	tap("p10")
	tap("p10")
	await _shot("give_points")
	tap("offer")
	await _shot("agree")
	tap("agree")
	await _shot("agreed")
	tap("pass")
	# Lust: Whisper of Desire before scoring
	tap("ready")
	tap("roll")
	await _shot("lust_swap_before_scoring")
	tap("whisper")
	await _shot("whisper_pick_your_die")
	tap("d1_0")
	await _shot("whisper_pick_their_die")
	tap("d0_1")
	await _shot("whisper_done_spark_button_on_roll")
	# Wrath, out of turn: Spark of Rage on Lust's roll
	tap("spark1")
	await _shot("spark_pick_a_die")
	tap("d1_0")
	await _shot("spark_done")
	tap("pass")
	# Gluttony: Feast
	tap("ready")
	tap("roll")
	await _shot("gambit_gluttony_tier_2_shut")
	tap("feast")
	await _shot("feast_pick_a_die")
	tap("d2_0")
	await _shot("feast_done")
	tap("pass")
	# Pride: Hubris
	tap("ready")
	await _shot("pride_before_the_roll")
	tap("hubris")
	await _shot("hubris_declared")
	tap("roll")
	await _shot("hubris_won")
	tap("pass")
	# round 2, everyone past 350: Tier 2
	for i in 4:
		Rules.add_points(h.s, i, 400)
	h._refresh()
	tap("ready")
	tap("roll")
	await _shot("gambit_wrath_tier_2_open")
	tap("strike")
	await _shot("strike_pick_a_target")
	tap("target3")
	await _shot("strike_target_chooses")
	tap("choose_die")
	await _shot("strike_done")
	tap("pass")
	tap("ready")
	tap("roll")
	if h.btn.has("settle"):
		tap("settle")
	tap("allure")
	tap("target0")
	tap("target3")
	await _shot("allure_two_players")
	tap("use")
	await _shot("allure_pass_to_first")
	tap("ready")
	await _shot("allure_secret_pick")
	tap("d0_0")
	tap("ready")
	tap("d3_0")
	await _shot("allure_after_the_picks")
	if h.btn.has("take0"):
		tap("take0")
		await _shot("allure_done")
	tap("pass")
	# Gluttony: Voracious Bite on Pride; then Purgatory for Pride
	tap("ready")
	tap("roll")
	tap("bite")
	tap("target3")
	await _shot("bite_done")
	tap("pass")
	h.rng.queue = [1, 2, 3]
	tap("ready")
	tap("roll")
	await _shot("into_purgatory")
	tap("pass")
	# the last stretch: Wrath close to the goal, then the win and the match log
	h.s.seats[0].points = 940
	h._refresh()
	await _shot("near_the_goal")
	h.rng.queue = [6, 1, 1]
	tap("ready")
	tap("roll")
	await _shot("winner_with_match_log_button")
	tap("log_win")
	await _shot("match_log")
	quit(0)


## The two-player table: the count choice, the cards whose words change, a gift, Bite and Entangling Allure.
func _two() -> void:
	h = TableScreen.new()
	# P1 Lust 4,5,1; P2 Gluttony 6,4,2; P1 4,6,2; then every die shows 4
	h.rng = Faces.new([])
	h.sins = ["lust", "gluttony"]
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(h)
	await _shot("how_to_play_4_chosen")
	tap("seats2")
	h.rng.queue = [4, 5, 1,  6, 4, 2,  4, 6, 2]   # set here: the four-player match the card opened on dealt its Sins from the dice
	await _shot("how_to_play_2_chosen")
	tap("got_it")
	await _shot("pass_the_phone")
	tap("sin0")
	await _shot("sin_card_lust")
	tap("close")
	tap("sin1")
	await _shot("sin_card_gluttony")
	tap("close")
	tap("ready")
	await _shot("roll")
	tap("roll")
	await _shot("gambit_lust")
	tap("points")
	await _shot("give_points_other_player_chosen")
	tap("back")
	tap("pass")
	for i in 2:
		Rules.add_points(h.s, i, 400)
	h._refresh()
	tap("ready")
	tap("roll")
	await _shot("gambit_gluttony_tier_2_open")
	tap("bite")
	await _shot("bite_pick_the_target")
	tap("target0")
	await _shot("bite_done")
	tap("pass")
	tap("ready")
	tap("roll")
	if h.btn.has("settle"):
		await _shot("lust_swap_before_scoring")
		tap("settle")
	tap("allure")
	await _shot("allure_lust_picks_in_secret")
	tap("d0_0")
	await _shot("allure_pass_to_the_other_player")
	tap("ready")
	await _shot("allure_other_player_picks")
	tap("d1_1")
	await _shot("allure_done")
	tap("pass")
	tap("ready")
	tap("roll")
	tap("bite")
	await _shot("bite_refused_the_turn_after")
	tap("back")
	await _shot("gambit_gluttony_2_dice")
	tap("help")
	await _shot("how_to_play_mid_match")


func tap(key: String) -> void:
	if not h.btn.has(key) or h.btn[key].disabled:
		printerr("no button to tap: ", key, " (on screen: ", h.btn.keys(), ")")
		quit(1)
		return
	h.btn[key].pressed.emit()


func _shot(name: String) -> void:
	for i in 6:
		await process_frame
	n += 1
	var img := root.get_texture().get_image()
	var path := "res://build/%s/%02d_%s.png" % [dir, n, name]
	img.save_png(ProjectSettings.globalize_path(path))
	print("shot ", path, " ", img.get_size())
