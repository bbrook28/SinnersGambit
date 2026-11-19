# REPLY 40 items 3 and 4: seat order, and the prompt re-sheet (proposal; sim and sheet only)
No rules code and no game code. Raw output: `sims.txt`.

## Item 3. Seat order
**The fault:** today seat 0 throws first every round, and you are always seat 0.
- Core engine, 35 tables pooled (70,000 games), wins by seat, first to last: **14.6 / 20.8 / 28.8 / 35.8**.
- The last seat throws last in the Master's final round, with every score known, so it presses exactly as far as it needs to.

**The fix: the final round runs from the leader down.** The leader throws first and the last seat throws last. Every other round is unchanged.

| Order (sim/seat_sim.gd, core, 35 tables pooled) | Seat 0 / 1 / 2 / 3 | Spread |
|---|---|---|
| Today (seat 0 first every round) | 14.6 / 20.8 / 28.8 / 35.8 | 21.2 |
| **The fix: the final round from the leader down** | **21.8 / 24.7 / 26.9 / 26.5** | **5.1** |
| Other: the first seat moves one place each round | 21.5 / 22.0 / 26.8 / 29.7 | 8.2 |
| Other: the final round from the last seat up | 19.8 / 23.8 / 27.5 / 28.8 | 9.0 |
| Both (rotate, and the final round from the leader down) | 24.3 / 25.2 / 26.2 / 24.3 | 1.9 |
- Rounds per match are the same in every row (5.37), so no row costs time.
- Recommended: the fix alone. It is one rule with one sentence to learn. Adding rotation flattens it further, but costs a second rule (question 2).
- **What you see:** at the final round, the Master's line names the order ("The final round. Gluttony first; the last of you throws last."). The windows take their turns in that order, and the turn band follows as it does now.
- **What changes:** `Docs/TableDesign.md` §1 (a round, step 3: "...the final round runs from the leader down"); the Master's final-round line in `ui/rules_text.gd`; the round loop in `core/game.gd` (needs Ben's word).

**"You win", both ways, from now on** (`sim/match_sim.gd`, today's structure, 4 seats, 2000 matches):
| | As seat 0 (today) | Seat-neutral (your seat shuffled) |
|---|---|---|
| No decisions | 16.6% | 25.3% |
| Fall + hex + raise (standings price, hex allowed on a backed rival, credit capped at 150) | 27.1% | 30.9% |
- Seat-neutral, the decisions are worth +5.6 points.
- With the agreed set, the gap is 5.7 / 10.5 / 42.8 s; 12% of gaps are over 10 s.

**The 35 tables, core against the sim engine (REPLY 40 item 5):** the sim engine models V5's abilities with the profile sim's rule keys (Envy's copy, Greed's vig, Gluttony's eat) rather than with `sins/`. So without bets a few tables land differently: 2 pairings outside against core's 0.

## Item 4. Prompt re-sheet (`prompts_se.png` at 0.34 of SE device px, `prompts_std.png` at 0.22 of std)
**a. Tap guard** (frame 1). The guard proposed:
- When the slip rises, its seals stay pale and answer nothing until a gold ring fills, 0.6 s after the slip has fully risen.
- A tap that began before the ring filled never answers it, nor does any tap outside the slip.
- A tap on the background still finishes the rival's beat (REPLY 35), and never takes or passes.
- The test that would prove it: a new `tests/oot_guard_check.gd`.
  - It double-taps the Throw spot at 0, 0.1 ... 0.6 s after the slip starts to rise, and taps the background throughout. No bet may be placed, and your score must not change.
  - A single tap at 0.7 s or later takes the bet.
  - Against a build without the guard, the first part must fail.

**b. A readable loss** (frame 2b):
- "−50" is shown at your token in red, the same size as the "+65" in 2a, and your label counts down to 290.
- "+50" is shown at its token in its colour, and its label reads 570.

**c. The open-bet marker** (frames 1b and 3): after Take, a chip in your colour reading "50" sits at the foot of the rival's window for the rest of its turn. It goes when the bet is paid or lost.

**d. Frame 0**:
- Gluttony's window is the one forward and lit as his line names it.
- At the open, the proposed track puts the three rivals' tokens side by side on one stem with one "0", and yours below it.
- The faint light strip under the tokens is left over from pasting the mock; it isn't part of the proposal.

**Flights across labels (2a, 4):** accepted. Each flight lasts about 0.6 s and passes a label for a frame or two. The label is whole before and after, and its count changes only when the flight lands.

## Touches / Could break (if built after Ben's word)
- **Seat order:** the round loop in `core/` and the final-round line. Bots are unaffected. Every Sin's numbers move a little: rerun the 35 tables after the change.
- **The prompts:** the seals row on a rival's turn, the chip at its window foot, the guard timer in `ui/tuning.gd`, and the new test.
- **The lock:** the windows don't move.
- **New sheet fixtures:** `table_oot_fall_lost`; `table_oot_pick` now has Gluttony forward.
