# Dice poker: plan

Spec: `docs/superpowers/specs/2026-11-20-dice-poker-pitch.md` (approved by Ben, 2026-11-20).
Same shape as before: rules with no UI, every number in a config, a headless sim, then the screen. Godot 4.7.2, GDScript, `preload` consts, no `class_name`.

1. **Rules** (`dice/`: `config.gd`, `state.gd`, `rules.gd`), tests first (`tests/dice_test.gd`):
   throw (draw `min(2, bag)`; skulls stay and leave the bag; three bust; the Last Dance: one die from a one-die bag, a skull busts, any other face is wild), keep exactly one (the other goes back), cash out, a full row cashes out, an empty bag cashes out, `score(row)` (best poker hand, the wild die taking its best face), `bust_chance`, and `preview(keep)` (the hand and marks a keep would make).
2. **Sim** (`sim/dice_sim.gd`): random, greedy (keeps the die that scores best now, cashes out at a pair or better) and strong (playouts over keeps and the stop call). Reports marks a hand and the paired gap to greedy, busts, throws, the Last Dance, each hand's rate, and agony as a report, not a pass mark. Pass marks: strong beats greedy by a clear margin; greedy beats random; busts about 1 in 4; 5 to 7 throws. Tune the pay table and the bag on seed 4; I report the numbers and the table I picked.
3. **The screen** replaces the bag hand's: the bag, the skulls, your row of 5, the two thrown dice. Tap a die and the row shows what it would make ("Two pair: 2 marks"). Throw shows the bust chance; Cash out shows what the row pays. `?` lists the hand ranking with its marks. The guided first hand: a throw, a skull, a pair, a pair against a straight draw, cash out.
4. **Evidence and TestFlight:** phone-size screenshots, then 0.9.0 to TestFlight. The bag hand's code (`hand/`, its sim and tests) is removed in the same change; it stays in git.

Stop points: if the sim can't meet the pass marks with any sensible pay table, I stop and report before building the screen. Otherwise I go straight through to TestFlight and send the sim numbers with the build.
