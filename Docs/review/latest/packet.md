# Packet: game length at 1500, Greed vs novices, Handoff (REPLY 4)
**Changed:** sim only (`577e86d`). New options: `scale_bots` sets bank_at, offer progress, risk vs standings and novice stop as a share of the target. `mimic_max` caps Envy's Mimicry per game. Docs: Handoff (`0379281`). Runs are in `build/agency/p4/`: 20k games, 4 seats, V5 config, skill edge from 5k games per Sin.
**V5 build sheet** (moved here so it stays visible): `Docs/review/archive/2026-11-15-v5-build/sheet.png`
**Length:**

| Run | Win range | Comebacks | Lead changes | Rounds | Minutes | Skill edge | Envy Mimicry/game |
|---|---|---|---|---|---|---|---|
| 1000 | 22.3-28.5 | 12.1% | 3.99 | 4.3 | 1.4 | 30.0 | 0.65 |
| 1500, bots scaled, Mimicry max 1 | 14.0 (Envy)-30.6 | 12.4% | 5.48 | 6.1 | 2.0 | 25.3 | 0.76 |
| 1500, bots scaled, no cap | 17.4-39.7 (Envy) | 13.4% | 5.33 | 5.9 | 2.0 | 26.1 | 1.66 |
| 1500, cap + comeback thresholds x1.5 | 13.1 (Envy)-30.4 | 11.8% | 5.34 | 6.2 | 2.1 | 25.2 | 0.76 |

**Why skill edge still falls:** most of the drop is Envy.
- Her edge goes from 38.1 at 1000 to 14.6 at 1500 with the cap, and to 46.1 with no cap. Her Mimicry pays a fixed number of points, so its share of a 1500 game depends only on how often it fires. Matching uses (0.76 vs 0.65) halves its share, so she sinks.
- Without Envy, the mean edge is 28.7 at 1000 and 27.1 at 1500, a small drop.
- It is not the catch-up rules. Scaling the comeback and mark thresholds x1.5 leaves the edge at 25.2.
- Comebacks barely move (12-13%). Lead changes rise in proportion to rounds.
- My read, not tested: the edge comes from pushing luck at the standings' swing points. A longer game doesn't add more of those, it adds more turns that every bot plays alike.

**Greed vs novices** (best bot vs 3 novices): Greed 28.9, below the others' 30.3-48.6.
- Proposal: Cash Out at x2.25 (from x2). Against novices Greed goes to 31.8, inside the others' 29.8-48.5. Equal bots: 21.7-27.9 (Greed 25.3, was 22.9), with Sloth 21.7, just under 22 (it was 22.3).
- This needs `core/rules.gd` V5 `greed_mult` and the power wording, so I have not made it.

**Handoff:** Now says V5 is built locally and playable on the table view. Next has the offer card's small text as the first item of the next UI pass. Waiting on Ben: the push and TestFlight. Open faults has the known gaps: hold to explain, no approved goldens, the Master's line is small text.
**Questions**
1. Greed's Cash Out to x2.25 (core change)? **Rec:** yes, with a 40k equal-bot check for Sloth before commit.
2. Stop testing length now that 1000 is set for the playtest? **Rec:** yes; revisit only if playtests feel short.
