# Packet: REPLY 43, the playable build (local only, 0 credits, no push)
**Built** (c6bb2e3, 8eaf5ac, b820a70, 012404f, ac9fc0f, 232649c): the final round runs from the leader down, and the Master names first and last. Fall, hex, the raise and the Master's credit (to -150) are in `core/game.gd`, offered only to a single human seat, so bot sims are unchanged. A rival's turn runs as held beats, with the token pulse, the stake flying to its own token, the slide with a counting label, and the kept half on a bust. Also built: the slip with the 0.6 s guard, the chip, a win shown in deep gold and a loss in red, the hex beat, the tokens' rings, the restack after the slide, the open row, and the Master's table of 4. Save version is now 6, because bets add answers; an older Continue save is not offered.
**Deviations:** one change per commit was not possible: the pieces share `main.gd`, `table_play.gd` and `table_blockout.gd`, so they landed as six commits by file set. The slip now rises in 0.1 s, so its guard fills 0.7 s after the rise starts; that is the only way both halves of the test spec hold. New wording: the raise is "{Sin}'s fall, now?"; the pick lines are "It beat you last time.", "You've beaten it least.", "Not faced in two tables." and "The dice chose it."; plus five final-order lines.
**Suite:** 15 of 15 pass. New: `tests/oot_guard_check.gd`. With the guard: no bet from presses begun at 0.01-0.58 s, including one held to 0.8 s, and one tap at 0.9 s takes it. With `--noguard`, part (A) fails, as required.
**Pace floors** (raised in b820a70, with the beats): median bot turn 6.5 s, match 267 s with every bet passed (before: 2.8 s and 183 s). The floors went from 2.0 s / 120 s to 3.0 s / 180 s.
**Goldens:** `tests/golden/` holds none (nothing approved yet), so `gallery --check` compares nothing.
**Text audit** (10 table fixtures, SE and std): clean except "Take" at 2.0:1 in `table_oot_guard`. That fixture shows the slip mid-guard, where the seals are pale by design.
**Evidence:**
- `sheet_se.png` and `sheet_std.png`: a rival beat, a bet offered, the guard at 0.4 s, an open bet, the hex offer, the Master's pick, the final round, tokens at 4 and at 7 after a slide, and the open. `shots/` holds every frame at device size.
- `clip.mp4` (3 s, SE) and `clip_frames.png`: at 7, Gluttony banks 180; the token pulses, "+180" flies, the token slides, then the track restacks.

**Report**
- During the slide the token leaves its stem behind until the restack.
- At 7, the restack after the slide moves Envy down a row as Gluttony rises.
- In `table_final_order`, the "550" post label sits under the crimson post, as it did before this build.
- The chip covers the foot of the rival's window art.
- At the open, both token rows' rings sit at least 31 SE px from the page edge (rival row 36, mine 31).

**Item 4, the composite** (unwired; no art work done):
- The pink beam reduced to a faint wash is intended. REPLY 33 asked for a soft light in place of the hard shaft. The composite lays an elliptical falloff from the active window's foot, at most 0.30, and that one number sets its strength.
- Die state: the composite pasted try 2's painted dice without today's underlines (gold for a scorer, crimson for a Strike), so it shows none. Once wired, the table would draw the underlines over the art.
- SE lock boxes against the border's inner edge (26 SE px in; the rule is 12 SE px from an edge):
  - "1000": the box runs 22 px past and the ink 6 px past.
  - Bank and Throw: each box runs 15 px past. Their words sit centred inside, clear of the border.
- The blots at the foot are in try 2's painted page: the REPLY 34 refill stops at the dice, so both corners are as try 2 painted them.

**Questions**
1. Bets are on in the First Game too. Rec: turn them off in game one, as powers and temptations are.
2. Should the stem travel with its token during the slide? Rec: yes, in the next pass.
3. A TestFlight build once Ben has played it locally? Rec: yes, on his word only.
