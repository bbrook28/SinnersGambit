## Run mode rules (run/): scoring, busts, the once-a-turn return, every relic, kits, twists, shop,
## save, and two seeded bot runs.
## godot --headless --path . --script res://tests/run_check.gd
extends SceneTree

const RunState = preload("res://run/run_state.gd")
const Round = preload("res://run/round.gd")
const Relics = preload("res://run/relics.gd")
const Shop = preload("res://run/shop.gd")
const Kits = preload("res://run/kits.gd")
const Rulers = preload("res://run/rulers.gd")
const RunBot = preload("res://ai/run_bot.gd")

var fails: Array[String] = []
var checks := 0


func ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails.append(what)


## A turn context: n plain dice, these relic ids, your Sin, a twist.
func mk(n := 6, relic_ids: Array = [], sin := "Sloth", twist := "", gold := 0) -> Dictionary:
	var dice: Array = []
	for i in n:
		dice.append(Round.plain_die())
	var row: Array = relic_ids.map(func(id): return {"id": id, "n": 0})
	return {
		"cfg": RunState.default_cfg(), "sin": sin, "twist": twist, "dice": dice,
		"fx": Relics.effective(row, sin == "Envy"), "owned": n, "gold": gold, "turns_left": 0,
		"busted_rounds": 0, "carry_mult": 0, "last_bank": -1,
	}


## Throws the given face values (1-6) with st.left.
func roll(ctx: Dictionary, st: Dictionary, faces: Array) -> Array:
	st.throws += 1
	Round.set_roll(st, faces.map(func(v): return v - 1))
	st.p += Relics.on_throw(ctx.fx, st)
	return Round.groups(ctx, st)


func find_group(gs: Array, v: int) -> int:
	for i in gs.size():
		if gs[i].v == v:
			return i
	return -1


## Throw faces, keep the groups of these values, return the Bank.
func bank_after(ctx: Dictionary, faces: Array, keep_vals: Array) -> int:
	var st := Round.new_turn(ctx)
	var gs := roll(ctx, st, faces)
	var sel: Array = keep_vals.map(func(v): return find_group(gs, v))
	Round.keep(ctx, st, gs, sel)
	return Round.bank_value(ctx, st).score


func _initialize() -> void:
	_scoring()
	_relics()
	_kits()
	_twists()
	_shop_and_save()
	_bot_runs()
	if fails.is_empty():
		print("RUN CHECK PASSED: %d checks" % checks)
	else:
		for f in fails:
			print("FAIL: " + f)
		print("RUN CHECK FAILED: %d of %d" % [fails.size(), checks])
	quit()


func _scoring() -> void:
	var c := mk()
	var st := Round.new_turn(c)
	var gs := roll(c, st, [5, 5, 5, 2, 3, 1])
	ok(gs.size() == 1 and gs[0].kind == "set" and gs[0].p == 75 and gs[0].m == 2, "three 5s: 75 Points, +2 Mult")
	gs = roll(c, st, [4, 6, 2, 2, 1, 3])
	ok(gs.size() == 3, "single 4, single 6, pair of 2s: three groups (got %d)" % gs.size())
	ok(find_group(gs, 2) >= 0 and gs[find_group(gs, 2)].p == 20 and gs[find_group(gs, 2)].m == 1, "pair of 2s: 20 Points +1 Mult")
	st = Round.new_turn(c)
	# Bust: nothing keepable.
	var s2 := Round.new_turn(mk(3))
	ok(roll(mk(3), s2, [1, 2, 3]).is_empty(), "1, 2, 3: bust")
	# Whole groups: keep the 5s, rethrow the rest.
	st = Round.new_turn(c)
	gs = roll(c, st, [5, 5, 2, 3, 1, 4])
	Round.keep(c, st, gs, [find_group(gs, 5)])
	ok(st.left.size() == 4 and st.p == 50 and st.m == 2, "keep a pair of 5s: 4 dice left, 50 x 2")
	ok(Round.bank_value(c, st).score == 100, "Bank 50 x 2 = 100")
	# Keep every die: back once a turn, then the next keep-all Banks.
	st = Round.new_turn(mk(2))
	var c2 := mk(2)
	gs = roll(c2, st, [6, 6])
	Round.keep(c2, st, gs, [0])
	ok(st.left.size() == 2 and st.returned and not st.bank_only, "every die kept: both come back")
	gs = roll(c2, st, [4, 4])
	Round.keep(c2, st, gs, [0])
	ok(st.bank_only, "every die kept again: must Bank")
	ok(Round.bank_value(c2, st).score == (60 + 40) * 3, "two pairs over the turn: 100 x 3")
	# A legal keep needs a group.
	st = Round.new_turn(c)
	gs = roll(c, st, [5, 2, 2, 3, 1, 4])
	ok(Round.keep(c, st, gs, []) == -1, "keeping nothing is refused")
	# keep_choices: every non-empty set of groups.
	ok(Round.keep_choices(c, st, gs).size() == 7, "three groups: seven keeps")


func _relics() -> void:
	var F := [6, 6, 4, 5, 2, 3]  # pair of 6s, single 4, single 5
	var base := bank_after(mk(), F, [6, 4, 5])  # (60 + 20 + 25) x 2 = 210
	ok(base == 210, "base keep: 210 (got %d)" % base)
	var expect := {
		"rosary": (105) * 4,                 # +1 Mult per 6
		"gilt_pip": (105 + 15) * 2,
		"knuckle": (105 + 15) * 2,
		"votive": (105 + 50) * 2,
		"plate": 210,
		"reliquary": (105 + 30) * 2,
		"psalter": 105 * 6,
		"sexton": 210,
		"nail": 105 * 4,                     # two dice left unkept
		"hourglass": 210,                    # no turns left in mk()
		"ember": 210,
		"pilgrim": 210,
		"calf": 210,
		"chalice": (105 + 30) * 3,           # the pair of 6s counts as three
		"gargoyle": 210,
		"tithe": 210,
		"almoner": 210,
		"candelabra": 105 * 3,
		"pyre": 210,
		"halo": 210,
		"thorn": 420,
		"last_rites": 210,
		"bone_dice": 210,
		"bell": 210,
		"censer": 210,
		"holy_water": 210,
		"beads": 210,
		"ossuary": -1,                       # checked below
		"mirror": 210,                       # nothing to its right
		"hair_shirt": -1,
	}
	for id in expect:
		if expect[id] < 0:
			continue
		var got := bank_after(mk(6, [id]), F, [6, 4, 5])
		ok(got == expect[id], "%s: expected %d, got %d" % [id, expect[id], got])
	# Rule relics.
	ok(bank_after(mk(6, ["bell"]), [3, 2, 2, 1, 1, 6], [3]) == 15, "Cracked Bell: a single 3 keeps for 15")
	ok(roll(mk(6, []), Round.new_turn(mk()), [3, 2, 1, 4, 2, 1]).size() == 3, "no Bell: 3 not a group")
	var hs := mk(6, ["hair_shirt"])
	ok(roll(hs, Round.new_turn(hs), [6, 2, 3, 4, 1, 5]).is_empty(), "Hair Shirt: singles can't be kept (bust)")
	ok(bank_after(hs, [6, 6, 2, 3, 4, 1], [6]) == 60 * 7, "Hair Shirt: +5 Mult")
	var bd := mk(6, ["bone_dice"])
	ok(bank_after(bd, [1, 1, 2, 3, 4, 6], [1]) == 10 * 5, "Bone Dice: a pair of 1s is +1 +3 Mult")
	var bz := mk(6, ["beads"])
	var stb := Round.new_turn(bz)
	var gb := roll(bz, stb, [4, 5, 6, 1, 2, 3])
	ok(gb.size() == 1 and gb[0].kind == "beads" and gb[0].p == 75 and gb[0].m == 2, "Prayer Beads: 4-5-6 a set +2 Mult")
	var hz := mk(6, ["halo"])
	ok(bank_after(hz, [5, 5, 5, 5, 2, 3], [5]) == 100 * 4 * 2, "Halo: a set of four doubles")
	var hc := mk(6, ["halo", "chalice"])
	ok(bank_after(hc, [5, 5, 5, 2, 3, 1], [5]) == (75 + 25) * 4 * 2, "Halo + Twin Chalice: a three counts as four")
	var lr := mk(6, ["last_rites"])
	var stl := Round.new_turn(lr)
	var gl := roll(lr, stl, [6, 6, 6, 5, 5, 2])
	Round.keep(lr, stl, gl, [find_group(gl, 6), find_group(gl, 5)])
	ok(Round.bank_value(lr, stl).score == (90 + 50) * 4 * 2, "Last Rites: one die left, x2")
	var ms := mk(6, ["mirror", "last_rites"])
	ok(Round.bank_value(ms, stl).score == (90 + 50) * 4 * 4, "Mirror Shard + Last Rites: x4")
	var cn := mk(2, ["censer"])
	var stc := Round.new_turn(cn)
	var gc := roll(cn, stc, [6, 6])
	Round.keep(cn, stc, gc, [0])
	ok(stc.m == 1 + 1 + 3, "Censer: +3 Mult keeping every die")
	var os := mk(6, ["ossuary"])
	ok(Round.new_turn(os).left.size() == 7, "Ossuary: seven dice on the first throw")
	var hw := mk(1, ["holy_water"])
	var sth := Round.new_turn(hw)
	var r := RandomNumberGenerator.new()
	var saved := 0
	for i in 200:
		sth = Round.new_turn(hw)
		var g := Round.throw(hw, sth, r)
		if sth.holy == 1 and not g.is_empty():
			saved += 1
	ok(saved > 10, "Holy Water: a bust rethrows (%d saves in 200 one-die turns)" % saved)
	var hg := mk(6, ["hourglass"])
	hg.turns_left = 2
	ok(bank_after(hg, F, [6, 4, 5]) == 105 * 6, "Hourglass: +2 Mult per turn left")
	var cf := mk(6, ["calf"], "Sloth", "", 12)
	ok(bank_after(cf, F, [6, 4, 5]) == 105 * 4, "Golden Calf: +1 Mult per 5 gold")
	var gg := mk(6, ["gargoyle"])
	var stg := Round.new_turn(gg)
	stg.throws = 3
	var gq := roll(gg, stg, F)
	Round.keep(gg, stg, gq, [find_group(gq, 6)])
	ok(Round.bank_value(gg, stg).score == 60 * (2 + 2), "Gargoyle: +1 Mult per throw after the second")
	var em := mk(6, ["ember"])
	em.busted_rounds = 2
	ok(bank_after(em, F, [6, 4, 5]) == 105 * 4, "Ember: +1 Mult per round busted in")
	var row := [{"id": "pilgrim", "n": 0}, {"id": "pyre", "n": 0}]
	Relics.on_round_end(row, true, true)
	Relics.on_round_end(row, true, false)
	ok(row[0].n == 2 and row[1].n == 1, "Pilgrim grows per clear, Pyre per bust round")
	var pf := Relics.effective(row, false)
	ok(pf._pilgrim == 2 and pf._pyre == 1, "counters reach fx")
	var cfg := RunState.default_cfg()
	var fx := Relics.effective([{"id": "tithe", "n": 0}, {"id": "almoner", "n": 0}, {"id": "sexton", "n": 0}, {"id": "thorn", "n": 0}], false)
	ok(Relics.interest_cap(fx, cfg) == 10 and Relics.unused_turn_pay(fx, cfg) == 3 and Relics.shop_relics(fx, cfg) == 3 and Relics.turns_lost(fx) == 1, "Tithe Box, Almoner's Purse, Sexton's Key, Thorn Crown rules")
	ok(Relics.LIST.size() == 30, "30 relics")


func _kits() -> void:
	var F := [6, 6, 4, 5, 2, 3]
	ok(bank_after(mk(6, [], "Lust"), F, [6]) == 60 * 3, "Lust: a pair adds +2 Mult")
	ok(bank_after(mk(6, [], "Pride"), F, [6]) == 60 * 2 * 2, "Pride: only sets kept, x2")
	ok(bank_after(mk(6, [], "Pride"), F, [6, 4]) == 80 * 2, "Pride: a single kept, no x2")
	ok(bank_after(mk(6, [], "Greed", "", 4), F, [6]) == (60 + 8) * 2, "Greed: +2 Points per gold")
	var sl := mk(6, [], "Sloth")
	var st := Round.new_turn(sl)
	st.p = 120
	st.m = 4
	ok(Round.bust_value(sl, st).score == 240, "Sloth: a bust banks the Points with half the Mult")
	ok(Round.bust_value(mk(6, [], "Wrath"), st).carry_mult == 5, "Wrath: a bust carries +5 Mult")
	var en := Relics.effective([{"id": "rosary", "n": 0}, {"id": "knuckle", "n": 0}], true)
	ok(en.rosary == 2 and en.knuckle == 1, "Envy: the leftmost relic fires twice")
	var gl := mk(7, [], "Gluttony")
	var stg := Round.new_turn(gl)
	var gs := roll(gl, stg, [5, 5, 5, 6, 6, 6, 2])
	Round.keep(gl, stg, gs, [0, 1], 6)
	ok(stg.returned and stg.left.size() == 7 and stg.eaten, "Gluttony: eating the 2 keeps every die")
	gs = roll(gl, stg, [5, 5, 5, 6, 6, 6, 2])
	ok(Round.keep(gl, stg, gs, [0], 6) == -1, "Gluttony eats once a turn")
	var run = RunState.new()
	run.start("Gluttony", 3)
	ok(run.dice.size() == 7, "Gluttony starts with 7 dice")
	run.start("Envy", 3)
	ok(run.relics.size() == 1 and Relics.rarity(run.relics[0].id) == "C", "Envy starts with a common relic")


func _twists() -> void:
	var F := [6, 6, 4, 5, 2, 3]
	ok(bank_after(mk(6, [], "Sloth", "Lust"), F, [6, 4]) == 60 * 2, "Lust rules: singles score no Points")
	ok(bank_after(mk(6, [], "Sloth", "Wrath"), F, [6]) == (60 - 40) * 2, "Wrath rules: 10 per unkept die")
	var g := mk(6, [], "Sloth", "Greed", 0)
	ok(bank_after(g, F, [6]) == 60, "Greed rules, no gold: half")
	var st := Round.new_turn(g)
	g.gold = 2
	var gs := roll(g, st, F)
	Round.keep(g, st, gs, [find_group(gs, 6)])
	ok(Round.bank_value(g, st).gold == -1 and Round.bank_value(g, st).score == 120, "Greed rules: a Bank costs 1 gold")
	var p := mk(6, [], "Sloth", "Pride")
	p.last_bank = 120
	ok(bank_after(p, F, [6]) == 0, "Pride rules: a Bank that doesn't beat the last scores 0")
	var run = RunState.new()
	for own in Kits.ORDER:
		for s in 20:
			var r := RandomNumberGenerator.new()
			r.seed = s
			var o := Rulers.order(own, r)
			ok(o.size() == 7 and o[6] == own and o[0] in Kits.MILD and o[1] in Kits.MILD and not own in o.slice(0, 6), "ruler order for %s" % own)
	# Sloth's round: one fewer die. Gluttony's: a die eaten per Bank, back after.
	run.start("Wrath", 5)
	run.rulers = ["Sloth", "Gluttony", "Envy", "Lust", "Greed", "Pride", "Wrath"]
	run.round_i = 2
	run.begin_round()
	ok(run.round_dice.size() == 5, "Sloth rules: five dice")
	run.circle = 1
	run.begin_round()
	var t: Array = run.begin_turn()
	t[1].p = 10
	run.finish_bank(t[0], t[1])
	ok(run.round_dice.size() == 5 and run.dice.size() == 6, "Gluttony rules: a die eaten per Bank, not for good")
	run.circle = 2
	run.relics = [{"id": "rosary", "n": 0}, {"id": "knuckle", "n": 0}]
	run.begin_round()
	run.begin_turn()
	ok(run.relics.size() == 1 and run.taken.size() == 1, "Envy rules: a relic taken each turn")
	run._end_round(true)
	ok(run.relics.size() == 2, "...and given back after the round")


func _shop_and_save() -> void:
	var run = RunState.new()
	run.start("Sloth", 9)
	run.gold = 40
	run._end_round(true)
	ok(run.status == "shop" and run.offers.relics.size() == 2 and run.offers.repaints.size() == 2, "a shop after the round: 2 relics, 2 repaints")
	var g0: int = run.gold
	ok(g0 == 40 + 5 + 3 + 5, "pay: trial 5, three unused turns, interest 5 (got %d)" % g0)
	var id: String = run.offers.relics[0]
	ok(Shop.buy_relic(run, 0) and run.relics.size() == 1 and run.gold == g0 - Shop.relic_price(run, id), "buy a relic")
	ok(Shop.buy_die(run) and run.dice.size() == 7 and run.gold == g0 - Shop.relic_price(run, id) - 10, "buy a die for 10")
	ok(not Shop.can_repaint(run, 0, 0), "the 1 can't be repainted")
	run.offers.repaints = ["six", "six"]
	ok(Shop.buy_repaint(run, 0, 0, 1) and run.dice[0].f[1] == 6, "Six: the 2 becomes a 6")
	ok(Shop.buy_repaint(run, 1, 0, 2) and run.dice[0].r.size() == 2, "two faces repainted")
	run.offers.repaints = ["gild"]
	ok(not Shop.can_repaint(run, 0, 3), "a third face can't be repainted")
	var before: int = run.gold
	Shop.sell_relic(run, 0)
	ok(run.relics.is_empty() and run.gold == before + Shop.relic_price(run, id) / 2, "sell for half")
	var rp: int = Shop.reroll_price(run)
	Shop.reroll(run)
	ok(Shop.reroll_price(run) == rp + 1, "each reroll costs 1 more")
	var d: Dictionary = JSON.parse_string(JSON.stringify(run.to_dict()))
	var r2 = RunState.new()
	ok(r2.from_dict(d), "save loads")
	ok(r2.gold == run.gold and r2.dice.size() == run.dice.size() and r2.dice[0].f[1] == 6 and r2.offers.relics == run.offers.relics and r2.rng.state == run.rng.state, "save round trip")
	r2.leave_shop()
	ok(r2.status == "play" and r2.target == run.cfg.targets[0][1], "resume: the next round")


func _bot_runs() -> void:
	var res: Array = []
	for k in 2:
		var run = RunState.new()
		run.start("Greed", 77)
		var bot = RunBot.new(77)
		bot.fast = true
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var turns := 0
		while run.status == "play" or run.status == "shop":
			if run.status == "shop":
				bot.shop(run)
				run.leave_shop()
				continue
			var t: Array = run.begin_turn()
			bot.begin_turn(run, t[0])
			var busted := false
			while true:
				var gs := Round.throw(t[0], t[1], rng)
				if gs.is_empty():
					busted = true
					break
				if not bot.play(t[0], t[1], gs):
					break
			if busted:
				run.finish_bust(t[0], t[1])
			else:
				run.finish_bank(t[0], t[1])
			turns += 1
			if turns > 200:
				break
		res.append([run.status, run.reached(), run.stats.turns, run.gold])
	ok(res[0][0] in ["won", "lost"], "a bot run ends (%s)" % str(res[0]))
	ok(res[0] == res[1], "a seeded run replays the same (%s vs %s)" % [str(res[0]), str(res[1])])
