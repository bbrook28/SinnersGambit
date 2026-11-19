## REPLY 38 item 3 (sim only): all 35 tables of four Sins, today's abilities and today's table rules (core V5,
## the Master's call, temptations and powers on, the game's bot in every seat). Seat order shuffled each game.
## Prints each Sin's win % at each table and lists the pairings outside the band (15-35, fair 25).
## godot --headless --path . --script res://sim/tables_sim.gd -- [games per table] [part=i/n] [key=value ...]
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const MatchGame = preload("res://sim/match_game.gd")  # game=match: sim/match_game.gd, so seat 0 can bet (oot=...)
const ProfileSim = preload("res://sim/profile_sim.gd")  # game=match models V5 with its rule keys (V5_SIM)
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"), preload("res://sins/greed.gd"), preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"), preload("res://sins/pride.gd"), preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]
const NAMES := ["Wrath", "Greed", "Lust", "Envy", "Pride", "Gluttony", "Sloth"]
const LO := 15.0
const HI := 35.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var games: int = int(args[0]) if args.size() > 0 and args[0].is_valid_int() else 2000
	var part := [0, 1]
	var o := Rules.V5.duplicate()
	o["master_call"] = Rules.MASTER_CALL  # as ui/main.gd table_rules()
	o["call_floor"] = Rules.MASTER_CALL_FLOOR
	o["tier2"] = true
	for a in args:
		if a.begins_with("part="):
			var pr: PackedStringArray = a.substr(5).split("/")
			part = [int(pr[0]), int(pr[1])]
		elif "=" in a:
			var kv: PackedStringArray = a.split("=")
			var v = str_to_var(kv[1])
			o[kv[0]] = v if v != null else kv[1]  # a word (oot=fall+hex) stays a string
	if str(o.get("game", "core")) == "match":  # the sim game is not core: it needs V5_SIM's keys to model V5
		for a in Array(ProfileSim.V5_SIM.split(" ")) + Array(args):
			if "=" in a and not a.begins_with("part="):
				var kv: PackedStringArray = a.split("=")
				var v = str_to_var(kv[1])
				o[kv[0]] = v if v != null else kv[1]
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	var tables := []
	for a in 7:
		for b in range(a + 1, 7):
			for c in range(b + 1, 7):
				for d in range(c + 1, 7):
					tables.append([a, b, c, d])
	var out := 0
	var seat_w := [0, 0, 0, 0]
	var played := 0
	var all := {}
	for t in tables.size():
		if t % part[1] != part[0]:
			continue
		var tb: Array = tables[t]
		var rng := RandomNumberGenerator.new()
		rng.seed = 1000 + t
		var wins := {}
		for g in games:
			var order: Array = tb.duplicate()
			for i in range(3, 0, -1):
				var j := rng.randi_range(0, i)
				var x = order[i]
				order[i] = order[j]
				order[j] = x
			var sins := []
			for i in order:
				sins.append(SIN_SCRIPTS[i].new())
			var game = (MatchGame if str(o.get("game", "core")) == "match" else Game).new([bot, bot, bot, bot], t * 100003 + g, o.duplicate(), sins)
			var w = await game.play()
			if w != null:
				wins[w.sin.sin_name] = wins.get(w.sin.sin_name, 0) + 1
				seat_w[w.seat] += 1
		played += games
		var line := "table %2d %s:" % [t + 1, "+".join(tb.map(func(i): return NAMES[i]))]
		var flag := ""
		for i in tb:
			var n: String = NAMES[i]
			var v: float = 100.0 * wins.get(n, 0) / games
			line += " %s %.1f" % [n, v]
			if v < LO or v > HI:
				flag += " %s %.1f %s" % [n, v, "LOW" if v < LO else "HIGH"]
				out += 1
			if not all.has(n):
				all[n] = []
			all[n].append(v)
		print(line + ("   OUT:" + flag if flag != "" else ""))
	var sl := "per Sin over its tables (min-max):"
	for n in NAMES:
		if all.has(n):
			var a: Array = all[n]
			sl += " %s %.1f-%.1f" % [n, a.min(), a.max()]
	print(sl)
	print("wins by seat (seat 0 throws first%s): %s" % [", and bets: oot=%s" % o.get("oot") if str(o.get("oot", "none")) != "none" else "", " ".join(seat_w.map(func(x): return "%.1f" % (100.0 * x / maxf(1, played))))])
	print("pairings outside %d-%d: %d" % [int(LO), int(HI), out])
	quit()
