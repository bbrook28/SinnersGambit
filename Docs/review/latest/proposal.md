# REPLY 34 items 2-3: pacing floor and match length (proposals; nothing built)
Raw sim output: `sims.txt` (two passes; the second, with `bot turn seconds` and `held at the end`, is the one quoted). Tool: `sim/match_sim.gd` (sim only; 4 seats unless stated, every seat a random profile, random Sins, V5 rules as `sim/profile_sim.gd` models them; seat 0 pays your thinking time).

## Item 2: pacing floor (seconds at 1x)
A rival's turn is a run of held beats. Each beat has a minimum; a tap still finishes a beat, never more (item 1's fix).
| Beat | Min s | What holds |
|---|---|---|
| Turn start | 0.6 | its window comes forward |
| Throw | 0.7 | dice fly and land |
| Result | 0.9 | scorers lit, stake counts up, Strikes snuff candles |
| Power | 0.7 | the seal fires (`POWER_FOR`, as now) |
| Offer | 2.0 | the card and the rival's answer |
| Buy | 0.8 | dice bought |
| Bank / Bust | 0.9 / 1.4 | the stake flies to the track / breaks |
| Line | 2.5 | a line stays up 2.5 s (6 words max: about 2.5 words a second, plus 0.5 s to find it). Beats run under it, but the turn does not end until it has had its 2.5 s (about +0.8 s a turn on average). |
A bot turn is never under 3.0 s. You: +1 s for your first tap, +2 s each decision, +4 s an offer. The Master: 1.2 s marking each round, 1.6 s on the call.
- **Bot turn:** median 8.2 s (p10 5.1, p90 10.6). Today it is 4.1 s (2.8 s in the First Game; item 1). A typical bot turn is about 3 throws.
- **Round:** 43 s at 4 seats, 69 s at 7. **Today's match** under the floor: 3.9 min at 4 seats (p90 4.8), 5.8 min at 7.
- **Speed setting:** yes, but only two steps, Normal and Fast, shown on the table (in the Master's menu). Fast halves every beat except the line's 2.5 s. At 7 seats a round of 69 s is long to sit through. Not simmed at Fast.

## Item 3: match length (target 15-20 min)
**A. Three dances, scores carry over** (the one asked for). Dances 1 and 2 are races to 1200 and 2400. Each ends at the end of the round in which someone reaches the target, with at least 2 rounds a dance. Dance 3 ends as today: the call at 3600, then one more round, then the final round. Between dances the Master changes one table rule (one of: dice at 60; chain cap x3; no mark; a bust keeps nothing; faces pay 6x; everyone gains a die). Each seat may also swap its power for a Sin not at the table, the last seat first (in the sim the leader keeps; others swap 6 times in 10).
**B. Three dances, scores reset.** Each dance is today's game, with the call at 750 from round 4. Placings score 4/2/1/0, and the last dance counts double. Most points wins; a tie goes to total score. The same rule change and power swap happen between dances.
| | Today | A: carry | B: reset |
|---|---|---|---|
| Minutes, median (p10-p90) | 3.9 (3.3-4.8) | 14.9 (12.2-18.4) | 14.6 (12.8-17.5) |
| Rounds (by dance) | 5.6 | 21.5 (6.9/6.2/8.4) | 19.8 (6.7/6.6/6.6) |
| Lead changes a match | 5.7 | 18.7 | 7.9 (score, within dances) |
| Leader entering the last stretch loses (today: from the call) | 56% | 63% | 35% |
| Close entering it (A: within 250; B: within 2 dance points) | 77% | 60% | 71% |
| Win % by starting Sin (fair 25) | 17.2-32.1 | 21.6-32.7 (Envy high) | 20.1-35.7 (Envy high) |
| Win % by the Sin held at the end | | 14.9 Sloth - 39.5 Envy | 16.9 Sloth - 48.0 Envy |
| Without power swaps | | Envy 59.5, Sloth 8.2 | Envy 61.8, Sloth 6.2 |
| 7 seats | 5.8 min | 15.9 min (targets 900/1800/2700) | 18.2 min (call 550) |
- **Finding: long play breaks Envy.** Today Envy wins 28.9%. In any structure longer than about 6 rounds she wins about 60% if powers stay put (her copy grows with dice bought). The swaps hide this rather than fix it. Either structure needs Envy retuned first, sim only.
- **At 7 seats every Sin is seated, so there is nothing to swap to.** The power pick would have to be a trade between seats.
- **The rule changes alone do little.** Carry with rule changes but no swaps plays like carry with neither, within sim noise.
- **Seat 0 (who throws first, and the others start 20 a seat ahead)** wins 14-19% against a fair 25%, in today's game too. This is not new.
**Touches / could break**
- Both structures:
  - Rules: `core/game.gd` round loop (dance ends, the rule change, the power swap) and `sins/` (a Sin changing seat mid-match). These need your OK.
  - Bots: `ai/bot_policy.gd` `progress()` and `call_rounds_left()` assume 1000 and one call; they need to know about dances.
  - Saves: V5 replay.
  - Tests: a new rules version, so old saves and tests keep V5.
  - New screens, each with a fixture: the interlude (his rule card, your power pick).
  - The Master's lines: 3 new events (a dance ends, the new rule, the pick) at 5 lines each, and the call line's number.
- A only: the track's scale goes from 1000 to 3600. The track redraws its marks and labels within the band box, so the lock boxes don't move. Could break: track label spacing at 4 digits.
- B only: dance points need a place on the table, for example pips by the marks under each window, which sits inside the lock boxes. Could break: crowding under the 7-seat windows.
