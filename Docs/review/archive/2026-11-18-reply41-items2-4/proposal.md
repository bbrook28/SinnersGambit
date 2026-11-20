# REPLY 41 items 2 and 4: the shuffled seat, and two sheet checks (proposal; sim and sheet only)
Raw output: `sims.txt` (`sim/match_sim.gd`, today's structure, 4 seats, 3000 matches a row; each prompt now counts the 0.6 s guard).

## Item 2. The seat drawn once a match
**Correction.** The game already draws your seat once a match and keeps that order for the whole match: `ui/main.gd` `_start` adds you to the seats, then calls `order.shuffle()`. Only the sim kept you at seat 0, so "he is always first" was true of the sim, not of the game. Today's "you win" is therefore the seat-neutral figure.

| Your seat drawn once a match | Wins by seat, first to last | You win, no decisions | You win, with the decisions |
|---|---|---|---|
| Today's order | 16.7 / 22.4 / 29.1 / 31.9 | 24.6% | 32.3% |
| With the fix (final round from the leader down) | 22.4 / 25.1 / 26.8 / 25.7 | 24.4% | 32.3% |
- The fix doesn't change your average. It removes the 15-point swing between drawing the first seat and the last.
- The decisions are fall, hex with the raise, the standings price, and credit capped at 150.
- **Gap with the decisions, the 0.6 s guard counted:** 6.3 / 10.9 / 47.8 s; 15% over 10 s (was 5.7 / 10.5 / 42.8; 12%).
- **With the fix:** 6.2 / 10.9 / 61.3 s. The worst case grows because, in the final round, you can move from first to last, so up to six rival turns can run back to back.

**What assumes your seat today** (no code changed):
- `ui/main.gd`:
  - `_start` draws the order and saves it in `_save.seats`, so Continue restores your seat;
  - the open card says "open_first" or "open_seat" by your seat;
  - the Master's start event adds the "first" hold only when you are first;
  - `_me()` finds you by your bot, not by index.
- `ui/table_blockout.gd` and `ui/table_play.gd`: the windows and the turn band follow seat order. You are found by the "you" flag, never by index 0.
- `core/game.gd`: `play()` runs seats in order, and the Master's "start" line goes to `players[0]`, the first seat, whoever it is. The fix changes only the final round's order here (it needs Ben's word).
- `ui/tutorial_game.gd`: a scripted game with you as Envy in the first seat, by design.
- The sims: `sim/match_sim.gd` keeps you at seat 0 unless `you=random` (now the default to report).

## Item 4. Two checks (`fixes_se.png`, SE device px; the full sheets `prompts_se.png` and `prompts_std.png` updated)
- **The open:** the tokens' row now starts at the track's start and runs right. Both rows are 31 SE px clear of the page edge. The faint light strip under the row is left over from pasting the mock.
- **A win reads as a loss does:** "+65" uses the same face, size and stroke as "−50", in deep gold (118, 78, 0) instead of the pale gold.
