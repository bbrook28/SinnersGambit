# Packet: REPLY 14 (the Master's mark in the sim; his figure in the blockout)
**Sim baseline:** call at 600, Cash Out x1.25, chain capped x2, a bust keeps half the turn's face points. Bots now count the half they keep when deciding. Seed 1; 20000 mixed games; 4000 games for each odd seat. "Mark" = at the start of each round the strict leader is marked for that round.

| run | Sin range | Envy | Greed | lead after r2 (2nd / last) | last seat wins | 0-bank turns (all / Gambler) | chain share | rounds (over 6) | odd seat Novice / Banker / Gambler |
|---|---|---|---|---|---|---|---|---|---|
| R13 cap+(b), bots untaught | 19.6-30.8 | 24.5 | 30.8 | 166 / 384 | 3.6% | 11% / 12% | 35% | 5.19 | 20.3 / 24.6 / 22.6 |
| baseline, bots taught | 20.4-30.3 | 25.2 | 30.3 | 165 / 384 | 3.5% | 10.7% / 11% | 34% | 5.20 (8.5%) | 20.4 / 24.4 / 18.0 |
| mark: chain off | 18.9-32.0 | 27.1 | 27.8 | 136 / 332 | 5.7% | 11.1% / 11% | 29% | 5.57 (16.7%) | 20.4 / 23.5 / 15.4 |
| mark: one die fewer | 19.4-30.3 | 27.8 | 30.0 | 154 / 361 | 3.8% | 10.4% / 10% | 33% | 5.34 (11.3%) | 18.6 / 22.9 / 15.9 |

**Bank per turn, median / p90 / max** (round 1 · 3 · 5): baseline 110/315/1320 · 90/365/1785 · 70/350/1385 · chain off 100/300/1320 · 80/345/1505 · 70/340/1365 · one die fewer 105/305/1320 · 80/360/1440 · 70/350/1445.
**Also:** the final margin is 242 at baseline, 157 with chain off and 217 with one die fewer. Games won by 400 or more: 20%, 7% and 17%.

**What it says:** teaching the bots moved little; only the Gambler as the odd seat drops (22.6 → 18.0), because every seat now presses harder. Chain off on the leader is the stronger mark. The lead after round 2 drops by 30, the last seat wins 5.7% (up from 3.5%), and margins of 400 or more fall from 20% to 7%. It costs 0.37 of a round, and 17% of games run past 6 rounds. It also spreads the Sins (Gluttony 32.0, Pride 19.8, Sloth 18.9). One die fewer barely moves anything.

**Build (local, blockout):** the Master is now a flat figure (hood, bone mask, plum robe, gold collar), centred above the windows. He speaks from beside his figure, on the side away from his reach. Poses: rest; speak; call (arm raised; the build uses it for his call and the final round); mark (arm to the leader's window, gold ring); offer (card in hand to that window). Mark and offer are fixture-only for now: the build has no mark rule, and offers cover the table. The skeleton is gone. New fixtures: `table_master_rest`, `_mark`, `_offer`, `_calling`. Text audit: 32/32 clean at se and std.
**Sheet:** before (the old Master line under the track, skeleton by the candles), then rest, mark, offer, calling (std). `sheet_se.png` shows the same four poses at SE size.
**What I see:** the screen has no spare band at std or SE. The dice were already at their minimum, so a Master twice a rival's window height halves every window. At std the active window drops from about 280 to 132 px wide; at SE rivals are about 25 pt wide. The offer card covers the Greed window it is handed to.

**Questions**
1. The figure takes space from the windows (they are about half as big). Should the Master stand behind the window row, with the windows in front of his robe, so the windows keep their old size? Rec: yes. It keeps the windows readable and still reads as a full figure at the head of the table.
2. Which mark goes to the next sim step: chain off, or one die fewer? Rec: chain off. It is the only one that narrows the lead and lifts the last seat.
3. Chain off spreads the Sins (Gluttony 32, Sloth 18.9). Should I run the mark with Gluttony's and Sloth's numbers as the next sim? Rec: hold until 2 is decided.
4. Should the offer card rest just above the target window, not on it? Rec: yes.
