# REPLY 35 item 2 (with REPLY 36 item 4): a rival's turn you can follow (proposal; nothing built)
Sheet: `strip_sheet.png`, a rival's turn as a strip of beats. It shows today's table drawn from fixtures (Wrath at a table of 4, std size), with each beat's minimum time and what the beat must show.

Each beat must show who acted, what they scored or lost, their new total, and any power used. All of it is shown, none of it written: no sentences in the play field.
| Beat | Min s | Who | Scored / lost | New total | Power |
|---|---|---|---|---|---|
| Turn start | 0.6 | Its window comes forward and lights; the others dim. Its track token pulses (new). | | the token's label | its seal sits by Throw (idle or spent) |
| Throw | 0.7 | dice in its colour's light | | | |
| Result | 0.9 | | scorers gold, Strikes red, its candles snuff; the stake counts up | | |
| Power | 0.7 | | the changed die gets the gold ring | | the seal flares (as built) |
| Bank | 0.9 | | the stake flies to its token (new) | the token slides; its label counts to the new total (new) | |
| Bust | 1.4 | | dice dim, the stake is blotted, the kept half flies to its token (new) | the token's label | |
| Line | 2.5 | the plate at its window's foot (as built) | | | |
- Beats run back to back. A line is held under them, and the turn does not end until the line has had its 2.5 s (6 words at about 2.5 words a second, plus finding it).
- A tap finishes the current beat only (item 1). The minimums are at 1x, and the Speed setting scales them as today.
- New: the token pulse at turn start, the stake's flight to the token, the token's slide with its label counting up, and the kept half flying on a bust. Everything else is built.
**Seconds** (sim, `sim/match_sim.gd` beat table; today's match structure; mixed profiles; your thinking included):
| | Bot turn, median (p10-p90) | Round | Match |
|---|---|---|---|
| Table of 4 | 8.2 s (5.1-10.6) | 43 s | 3.9 min (3.3-4.8) |
| Table of 7 | 8.3 s (5.1-10.6) | 69 s | 5.8 min (5.4-6.3) |
| Today, measured (item 1) | 4.1 s (2.8 First Game) | | 3-4.5 min |
- A typical bot turn is about 3 throws: 0.6 + 3 x 1.6 + 0.9 + about 0.8 waiting on the line, plus a power or an offer about two turns in three.
- Bot turns are never under 3.0 s.

## The 10 s measure (REPLY 36 item 4): seconds between your decisions, normal game (`gaps.txt`)
Sim, today's match structure, the beats above. "Fast" is every beat at half its time; thinking and the line's 2.5 s stay.
| | Within your turn, median | From your last decision, past the rivals, to your next turn: median (p90) | Bot turns over 10 s |
|---|---|---|---|
| Table of 4, Normal | 3.6 s | 34.6 s (41.8) | 18% |
| Table of 4, Fast | 2.8 s | 21.8 s (25.8) | 1% |
| Table of 7, Normal | 3.6 s | 60.4 s (69.6) | 20% |
| Table of 7, Fast | 2.8 s | 36.0 s (40.9) | 1% |
| First Game, today's beats (tap test, measured) | | 7.8-11.7 s | |
- **Pacing alone cannot hold 10 s.** Inside your turn the gaps are short. The gap that fails is the wait through the rivals: three readable rival turns take about 25 s at Normal (the median 8.2 s each) and still about 14 s at Fast. Pass the measure by speed and the rivals stop being readable, which is the build 120 fault.
- **What holds it:** a decision of yours inside every rival's turn (item 3's out-of-turn decisions). The gap then becomes one rival turn: median 8.2 s at Normal, with 18% of rival turns over 10 s. To bring the worst case under 10 s, the out-of-turn prompt comes at a throw boundary, at most every second rival throw. The rival's beats keep their minimums. The table of 4 (item 3) halves the wait at a table of 7.
- **The pace test floors** (`tests/table_pace_check.gd`: 2.0 s, 120 s) rise to this table's numbers in the same commit as the floor (REPLY 36 item 2).
