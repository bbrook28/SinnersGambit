## A solo run (Docs/RunDesign.md §1): 7 Circles of three rounds, two trials then the ruling Sin.
## Rules only. The board (ui/run_board.gd), the bot (ai/run_bot.gd) and the sim drive it the same way:
##   begin_turn() -> ctx, st; Round.throw / keep ...; then finish_bank() or finish_bust().
## After a round: status "shop" (Shop.* on this object), then leave_shop(). Ends "won" or "lost".
extends RefCounted

const Round = preload("res://run/round.gd")
const Relics = preload("res://run/relics.gd")
const Kits = preload("res://run/kits.gd")
const Rulers = preload("res://run/rulers.gd")
const Shop = preload("res://run/shop.gd")

const SAVE_VERSION := 1


## Every tunable number. The sim overrides keys; the doc (RunDesign) quotes the defaults.
static func default_cfg() -> Dictionary:
	return {
		"targets": [
			[700, 800, 900], [2000, 3000, 3200], [3500, 5500, 6000], [7000, 10000, 10000],
			[10000, 13000, 13000], [14000, 16000, 15000], [16000, 18000, 16000],
		],
		"turns": 3,
		"start_dice": 6,
		"gluttony_dice": 7,
		"singles": [4, 5, 6],
		"start_gold": 0,
		"pay_trial": 5,
		"pay_sin": 10,
		"unused_turn_gold": 1,
		"interest_per": 5,
		"interest_cap": 5,
		"shop_relics": 2,
		"shop_repaints": 2,
		"reroll_base": 2,
		"prices": {"C": 5, "U": 10, "R": 15},
		"repaint_price": 5,
		"repaint_faces": 2,
		"die_prices": [10, 20],
		"max_dice": 8,
		"relic_slots": 5,
		"rarity_weights": [60, 30, 10],
		"sloth_bust_mult": 0.5,
		# A ruling Sin's round target is the table's, times this (twists differ in how hard they bite).
		"twist_target": {"Sloth": 0.9, "Greed": 1.15, "Envy": 0.7, "Lust": 0.85, "Wrath": 0.65, "Pride": 0.6, "Gluttony": 0.85},
		"wrath_bust_mult": 5,
		"greed_per_gold": 2,
		"lust_pair_mult": 2,
		"wrath_unkept": 10,
	}


var cfg: Dictionary
var sin := ""
var rng := RandomNumberGenerator.new()
var run_seed := 0
var rulers: Array = []
var circle := 0           # 0-6
var round_i := 0          # 0, 1 trials; 2 the ruling Sin
var dice: Array = []
var relics: Array = []    # the row, left to right: {id, n}
var gold := 0
var dice_bought := 0
var status := "play"      # play, shop, won, lost
var offers := {}
var banned: Array = []    # relic ids the sim keeps out of shops
## This round
var target := 0
var turns_left := 0
var score := 0
var last_bank := -1
var round_busted := false
var round_dice: Array = []
var taken: Array = []     # relics Envy holds until the round ends
var carry_mult := 0       # Wrath's kit
var busted_rounds := 0
var rounds_cleared := 0
var last_pay := {}        # what the round just paid: {clear, unused, interest}
var stats := {}


func start(p_sin: String, p_seed: int, p_cfg := {}) -> void:
	cfg = default_cfg()
	for k in p_cfg:
		cfg[k] = p_cfg[k]
	sin = p_sin
	run_seed = p_seed
	rng.seed = p_seed
	rulers = Rulers.order(sin, rng)
	dice = []
	for i in Kits.dice_count(sin, cfg):
		dice.append(Round.plain_die())
	relics = []
	gold = cfg.start_gold
	stats = {"turns": 0, "throws": 0, "busts": 0, "banks": 0, "best_bank": 0, "bought": [], "offered": [], "shops": 0}
	if sin == "Envy":
		var commons := Relics.ids("C")
		relics.append({"id": commons[rng.randi_range(0, commons.size() - 1)], "n": 0})
	begin_round()


func ruler() -> String:
	return rulers[circle]


func is_sin_round() -> bool:
	return round_i == 2


func twist() -> String:
	return ruler() if is_sin_round() else ""


func begin_round() -> void:
	status = "play"
	target = round_target(circle, round_i)
	var fx := Relics.effective(relics, sin == "Envy")
	turns_left = cfg.turns - Relics.turns_lost(fx)
	score = 0
	last_bank = -1
	round_busted = false
	taken = []
	round_dice = dice.duplicate()
	if twist() == "Sloth" and round_dice.size() > 1:
		round_dice.remove_at(_plainest(round_dice))


func _plainest(ds: Array) -> int:
	var best := 0
	for i in ds.size():
		if ds[i].r.size() <= ds[best].r.size():
			best = i
	return best


## Starts a turn: returns [ctx, st] for run/round.gd.
func begin_turn() -> Array:
	if twist() == "Envy" and not relics.is_empty():
		taken.append(relics.pop_at(rng.randi_range(0, relics.size() - 1)))
	var ctx := make_ctx()
	return [ctx, Round.new_turn(ctx)]


func make_ctx() -> Dictionary:
	return {
		"cfg": cfg, "sin": sin, "twist": twist(), "dice": round_dice,
		"fx": Relics.effective(relics, sin == "Envy"), "owned": dice.size(), "gold": gold,
		"turns_left": turns_left - 1, "busted_rounds": busted_rounds + (1 if round_busted else 0),
		"carry_mult": carry_mult, "last_bank": last_bank,
	}


## Banks the turn. Returns the bank_value result (score, gold, parts).
func finish_bank(ctx: Dictionary, st: Dictionary) -> Dictionary:
	var b := Round.bank_value(ctx, st)
	gold = maxi(0, gold + b.gold)
	score += b.score
	if not b.zeroed:
		last_bank = maxi(last_bank, b.score)
	stats.banks += 1
	stats.best_bank = maxi(stats.best_bank, b.score)
	carry_mult = 0
	if twist() == "Gluttony" and round_dice.size() > 1:
		round_dice.remove_at(rng.randi_range(0, round_dice.size() - 1))
	_end_turn(st)
	return b


func finish_bust(ctx: Dictionary, st: Dictionary) -> Dictionary:
	var b := Round.bust_value(ctx, st)
	score += b.score
	carry_mult = b.carry_mult
	round_busted = true
	stats.busts += 1
	_end_turn(st)
	return b


func _end_turn(st: Dictionary) -> void:
	stats.turns += 1
	stats.throws += st.throws
	turns_left -= 1
	if score >= target:
		_end_round(true)
	elif turns_left <= 0:
		_end_round(false)


func _end_round(cleared: bool) -> void:
	relics.append_array(taken)
	taken = []
	if round_busted:
		busted_rounds += 1
	Relics.on_round_end(relics, cleared, round_busted)
	if not cleared:
		status = "lost"
		return
	rounds_cleared += 1
	var fx := Relics.effective(relics, sin == "Envy")
	var interest := mini(gold / cfg.interest_per, Relics.interest_cap(fx, cfg))
	var clear: int = cfg.pay_sin if is_sin_round() else cfg.pay_trial
	var unused: int = turns_left * Relics.unused_turn_pay(fx, cfg)
	last_pay = {"clear": clear, "unused": unused, "interest": interest}
	gold += clear + unused + interest
	round_i += 1
	if round_i > 2:
		round_i = 0
		circle += 1
	if circle >= cfg.targets.size():
		status = "won"
		return
	status = "shop"
	stats.shops += 1
	Shop.roll(self)


func leave_shop() -> void:
	begin_round()


## Circle reached, 1-7 (8 = won).
func reached() -> int:
	return 8 if status == "won" else circle + 1


# ---------- save (on entering each shop) ----------

func to_dict() -> Dictionary:
	return {
		"v": SAVE_VERSION, "cfg": cfg, "sin": sin, "seed": run_seed, "rng": str(rng.state), "rulers": rulers,
		"circle": circle, "round_i": round_i, "dice": dice, "relics": relics, "gold": gold,
		"dice_bought": dice_bought, "status": status, "offers": offers, "busted_rounds": busted_rounds,
		"rounds_cleared": rounds_cleared, "carry_mult": carry_mult, "stats": stats, "last_pay": last_pay,
	}


func from_dict(d: Dictionary) -> bool:
	if int(d.get("v", 0)) != SAVE_VERSION or d.get("status", "") != "shop":
		return false
	cfg = _ints(d.cfg)
	sin = d.sin
	run_seed = int(d.seed)
	rng.seed = run_seed
	rng.state = String(d.rng).to_int()
	rulers = d.rulers
	circle = int(d.circle)
	round_i = int(d.round_i)
	dice = _ints(d.dice)
	relics = _ints(d.relics)
	gold = int(d.gold)
	dice_bought = int(d.dice_bought)
	status = "shop"
	offers = _ints(d.offers)
	busted_rounds = int(d.busted_rounds)
	rounds_cleared = int(d.rounds_cleared)
	carry_mult = int(d.carry_mult)
	stats = _ints(d.stats)
	last_pay = _ints(d.last_pay)
	return true


## JSON brings numbers back as floats; the rules want ints.
static func _ints(v):
	if v is float:
		return int(v) if v == floorf(v) else v
	if v is Array:
		var out: Array = []
		for e in v:
			out.append(_ints(e))
		return out
	if v is Dictionary:
		var out := {}
		for k in v:
			out[k] = _ints(v[k])
		return out
	return v


## A round's target: the table's, and in a ruling Sin's round times its twist factor (to 100).
func round_target(c: int, ri: int) -> int:
	var t: int = cfg.targets[c][ri]
	if ri == 2:
		t = int(round(t * float(cfg.twist_target.get(rulers[c], 1.0)) / 100.0)) * 100
	return t
