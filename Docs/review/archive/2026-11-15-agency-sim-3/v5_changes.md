# V5: the changes I would make (none made; each waits for Ben's OK)
V4 stays as it is, so old replays and `sim/check_v3.gd v4` still run. One change per commit, in this order, each with a test.

## core/
1. `rules.gd`: `const V5 := V4.duplicate()` plus `"v5": true, "purgatory": false, "auto_purgatory": false, "powers": true, "vig": 60, "fury_trigger": 300, "fury_grudge": 200, "hubris_mult": 1.75, "greed_mult": 1.5, "eat": 90, "wrath_max": 2, "tempt_comeback": true, "comeback_per": 200, "comeback_max": 2.0, "comeback_gap": true, "comeback_gap_at": 150, "mark_free_behind": 150`.
2. `turn_state.gd`: `var power_used := false`.
3. `game.gd` `take_turn`: under `opt("powers")`, ask the Sin at three points, once a turn: turn start (Pride: name the Bank), after each throw before Strikes count (Wrath, Lust, Gluttony, Sloth, Envy), and at the throw-or-bank decision (Greed). Each window calls `p.sin.power_ready(self, p, turn)` and then `await p.bot.wants_power(...)` (the human's seal tap comes through the same bot interface, as Throw and Bank do now). The Purgatory branch (`_try_escape`) is skipped when `purgatory_on` is false (it already is).
4. `game.gd` `_tempt`: scale the offer's gain by `comeback_factor(p)` (x(1 + D/200), up to x3; points round to 5, dice round) before the decision. A mark taken while `mark_free_behind`+ behind adds to `marks_taken` but not to `marks`.
5. `game.gd` `_start_costs`: a seat `comeback_gap_at`+ behind has an offer ready every turn.
6. `game.gd`: `view.master_event(kind, p, facts)` for game start, bust, Bank 200+, rival bust, offer entrance, mark, claim, win, loss (facts: the stake, Strikes, the margin, who throws first). The view picks the line; core only reports facts.

## sins/
7. `sin.gd`: `power_ready(game, me, turn) -> bool` and `use_power(game, me, turn)`, empty by default.
8. Each Sin, under `v5` only (the V4 Basic stays for V4): Wrath rethrows up to `wrath_max` Strikes; Greed banks half at `greed_mult` and throws on; Lust turns a Strike into the last player's best die; Envy copies its best die (+face x face_mult, outside the multiplier); Pride names 150/200/250 for x`hubris_mult`; Gluttony removes a Strike die for +`eat`; Sloth makes this throw's Strikes 3s. Under V5 the passive Basics (Spark of Rage, Whisper, Glance, Hubris at turn start, Feast, Lazy Bones) are off; Greater abilities, the Vig and Envy's Mimicry stay.
9. `wrath.gd`: Fury reads `fury_trigger` / `fury_grudge` (it already does; V5 sets 300 / 200).
10. `temptations.gd`: `apply()` takes the scaled offer (it already reads `offer.g`); no other change.

## ai/
11. `bot_policy.gd`: `wants_power(game, p, kind) -> bool`, which presses at the first chance (the sim's best policy for six Sins); Greed compares half now at x1.5 against throwing it all on (`sim/sim_game.gd _power_greed`).
12. `bot_policy.gd` `risk_for`: no `SIN_RISK` tilt when `v5`.
13. `bot_policy.gd`: a first-game setting (bank at 200, risk 1.55, buy to 4), chosen by `ui/` for game one.

## Not core (ui/, after the above): seal tap and its states, Purgatory out of `rules_text.gd`, the Master's lines in `rules_text.gd`, onboarding.
