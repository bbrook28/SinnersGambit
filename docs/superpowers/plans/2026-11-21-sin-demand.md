# The Sin's demand: plan for 0.12.0

Spec: `docs/superpowers/specs/2026-11-21-sin-demand-pitch.md` (approved by Ben, 2026-11-21).
Goal: a build where Pride, Envy and Wrath each host hands with their demand, for Ben to play three hands of each.
Same shape as dice poker: rules with no UI, every number in a config, the sim, then the screen. Godot 4.7.2, GDScript, `preload` consts, no `class_name`, CRLF in `.gd`. Tests first in every task; commit after each task; nothing is pushed.

## The numbers (from the pitch; the sim may move the prices, never the shape)
| Sin | Demand | Line on the window |
|---|---|---|
| Pride | each 6 +2, each 5 +1 | "Each 6 pays 2. Each 5 pays 1." |
| Envy | each 6 +1, each 2 −1 | "Each 6 pays 1. Each 2 costs 1." |
| Wrath | each die thrown while 2 skulls show +1 (not the Last Dance) | "Each die thrown at two skulls pays 1." |

A hand pays its poker marks plus the Sin's marks, never less than 0. A bust pays nothing. The wild die takes the face that pays most in all.

## 1. Rules (`dice/`), tests in `tests/dice_test.gd`
- New `dice/demands.gd`: `const DEMANDS := {"pride": {"faces": {6: 2, 5: 1}, "danger": 0, "line": ...}, "envy": {...}, "wrath": {"faces": {}, "danger": 1, "line": ...}}`, `const DANGER_AT := 2`, and `static func of(cfg: Dictionary) -> Dictionary` (empty for no Sin).
- `config.gd`: new key `"demand": ""` (a Sin's name, or "" for none), so the sim takes `demand=pride`.
- `state.gd`: `var bank := 0` (Wrath's marks earned so far), copied by `clone()`.
- `rules.gd`:
  - `sin_marks(cfg, row: Array, bank: int) -> int`: the faces' marks in the row plus the bank.
  - `total(cfg, row: Array, bank: int) -> Dictionary`: `{hand, name, marks, sin, total}`; `marks` is the poker, `total = max(0, marks + sin)`; a wild die takes the face with the best `total` (ties: the better hand).
  - `throw_pays(s, n: int) -> int`: what the Sin pays for throwing `n` dice now (0 unless Wrath, 2 skulls showing, not the Last Dance); `throw` adds it to `s.bank` before the dice land.
  - `_pay_out` sets `s.marks` to `total(...).total`. `score` and `preview` keep their meaning (the poker hand), so today's tests stand.
  - `preview_total(s, i: int) -> Dictionary`: `total` of the row with thrown die `i` kept.
- Tests (exact values):
  - No demand: every existing test passes unchanged.
  - Pride, row `[6, 6, 5, 3, 3]`: marks 2, sin 5, total 7. Row `[4, 4, 4, 0]` paid on an empty bag: the wild becomes a 4 (four of a kind 7) not a 6 (three of a kind 3 + 2).
  - Pride, row `[3, 3, 0]` on an empty bag: the wild becomes a 3 (3 marks) not a 6 (1 + 2 = 3): the tie goes to the better hand.
  - Envy, row `[2, 2, 3, 4, 5]`: marks 1, sin −2, total 0 (not −1).
  - Wrath: a 2-die throw at 2 skulls banks 2; at 1 skull banks 0; the Last Dance banks 0; a bust after banking pays 0; a paid row adds the bank.

## 2. Solver and sim (`dice/policies.gd`, `sim/dice_sim.gd`)
- `Solver.value(row, skulls, bag, bank := 0)` and `throw_value(row, skulls, bag, n, bank := 0)`; the memo key includes the bank; payment is `Rules.total`. Test: with no demand the solver still says 3.581 marks a hand (to 3 places); with `demand=pride` it says more than with none.
- The sim reports, for strong: keeps whose best two different faces are **worth the same** (new; today's "close" skips exact ties), marks from poker and from the Sin, and the draw mix with two skulls showing.
- Pass marks by demand:
  - Pride, Envy: same-worth keeps under 25%; a wrong keep costs 0.25 marks or more in over 70%.
  - Wrath: with two skulls showing, strong draws two dice in 30% to 70% of throws.
  - All: busts 20% to 30%. The old "strong beats greedy by 15%" mark is reported, not judged (greedy does not know the demand).
- Run seed 4, 20000 hands, once per Sin, one process at a time (a broken script pops a Windows alert per process). Reports go to `build/sim/dice_4_<sin>.txt`.
- **Stop point:** if a Sin misses its marks at the pitch's prices and one price change does not fix it, I stop and bring Ben the numbers before any screen work. The Python probe predicts 20% / 21% same-worth and a 41/59 split, so I expect a pass.

## 3. The screen (`ui/dice_screen.gd`, `ui/dice_tutorial.gd`), tests in `tests/ui_test.gd`
Each new piece follows what the screen already does: names and prices read "Name · N" (the ribbon), captions under seals are Cinzel bold, body lines are IM Fell, gains are gold and losses are blood red, and nothing is sized or coloured outside the constants at the top of the file.

- **Who hosts.** In 0.12.0 only Pride, Envy and Wrath host, in turn (a `HOSTS` list beside `SINS`; the other four windows stay in the build). The guided first hand has no demand: its scripted dice teach the poker, and a forced "keep the 4" over a 6 would contradict Pride. `_new_hand` sets `cfg.demand`.
  - Test: hands 1 to 6 after the tutorial are hosted Pride, Envy, Wrath, Pride, Envy, Wrath; the tutorial hand's `cfg.demand` is "".
- **The demand is told.** The opening shows the Sin's line under its name and holds for a tap or 2.5 s (0.85 s is too short to read a rule). The first hand with a demand also gets one card, once: "The Sin's demand: each hand a Sin hosts, and pays you for what it wants. A bust pays nothing." During the hand the line stays on a plate under the window (`demand_label`).
  - Test: Pride's opening shows "Each 6 pays 2. Each 5 pays 1."; `demand_label.text` is the same after the opening; the card shows once and is saved in `seen`.
- **The stakes are shown.**
  - Each thrown die the Sin cares about carries a tag: "+2" gold, "−1" blood red.
  - Beside the ribbon, `sin_label`: "Pride · 4" for the row so far, or for the row with the picked die ("if kept" already covers it). Envy can read "Envy · −2".
  - Under Wrath with two skulls showing, each seal gets a gold line over its risk: "Wrath pays 2".
  - Test: Pride, row `[6]`, thrown `[6, 3]`, the 6 picked: the 6's tag reads "+2", `ribbon_label` "Pair · 1", `sin_label` "Pride · 4". Wrath at two skulls: seal 2's pay line reads "Wrath pays 2"; at one skull it is hidden.
- **The payout counts both.** Coins fly from the row for the poker marks, then from the window for the Sin's. The banner's title is the total; its text splits it: "Pair 1 + Pride 4. You have 37 marks in all." For Envy taking: "Pair 1, Envy takes 1."
  - Test: a paid Pride hand: `banner_title` is the total, `banner_text` begins "Pair 1 + Pride 4."; `total` rises by the total.
- **`?`** shows the hosting Sin's line above the hand ranking.

## 4. Evidence
- `ui/version.gd` to 0.12.0. `bash tests/run_all.sh` passes.
- `tools/shots.gd` adds: a demand opening, the plate and tags in a Pride keep, Wrath's seals at two skulls, the split payout, an Envy result that takes marks. Shots at phone size go to Ben with the three sim reports, without a verdict.
- Then I stop: Ben says whether to push and start TestFlight.

## Risks I will watch
- The 2.5 s opening every hand may drag by the third hand; a tap skips it, and Ben judges it.
- Three more things on screen (plate, tags, `sin_label`) on a full layout; the shots are taken at 1080x2340 and at the iPad's 4:3 to show nothing overlaps.
- Envy at 27% busts in the probe is near the 30% ceiling; the sim decides whether its price changes.

## Open to Ben
- Only three Sins hosting in 0.12.0 (the pitch said the other four keep hosting with no demand). I recommend three: Ben meets each demand every third hand instead of three hands in seven.
