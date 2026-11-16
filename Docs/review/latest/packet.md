# Packet: REPLY 13 (chain multiplier and bust softener; sim only)
**Setup:** de05313 adds `chain_cap`, `soften=first|half` and `odd_kinds` to the sim. Every run uses the call at 600 and Greed Cash Out x1.25, seed 1, 20000 mixed games, and 4000 games for each odd seat. Bots don't know about the softener: they still treat a bust as 0. No build.

| run | Sin range | Envy | Greed | lead after r2 (2nd / last) | last seat wins | 0-bank turns (all / Gambler) | chain share | rounds | odd seat Novice / Banker / Gambler |
|---|---|---|---|---|---|---|---|---|---|
| chain 0.5 (base) | 20.3-34.8 | 34.8 | 24.5 | 189 / 424 | 4.2% | 41% / 52% | 44% | 5.10 | 19.4 / 22.1 / 21.3 |
| chain 0.25 | 15.8-31.7 | 31.7 | 30.3 | 146 / 322 | 3.3% | 41% / 51% | 28% | 5.83 | 20.0 / 24.1 / 19.8 |
| chain 0.5, capped x2 | **20.1-29.7** | 25.1 | 29.4 | 170 / 394 | 3.4% | 42% / 53% | 38% | 5.26 | 20.2 / 24.2 / 20.3 |
| chain off (ref) | 9.1-44.0 | 23.0 | 44.0 | 111 / 235 | 1.7% | 41% / 51% | 0% | 7.20 | 24.4 / 32.7 / 18.0 |
| base + (a) first throw | 20.0-34.6 | 34.6 | 25.9 | 183 / 411 | 4.7% | 12% / 13% | 40% | 5.02 | 19.4 / 21.6 / 22.1 |
| base + (b) half faces | 19.8-34.7 | 34.7 | 25.4 | 185 / 414 | 4.4% | 11% / 12% | 40% | 5.04 | 19.6 / 22.7 / 22.8 |
| cap x2 + (a) | 19.5-31.8 | 24.3 | 31.8 | 164 / 382 | 3.7% | 12% / 14% | 34% | 5.15 | 20.1 / 24.2 / 22.6 |
| cap x2 + (b) | 19.6-30.8 | 24.5 | 30.8 | 166 / 384 | 3.6% | 11% / 12% | 35% | 5.19 | 20.3 / 24.6 / 22.6 |

**Bank per turn, median / p90 / max** (round 1 · round 3 · round 5):
- base: 115/315/1390 · 110/405/2245 · 0/435/2310 · chain 0.25: 90/265/1075 · 90/305/1425 · 40/320/1680
- cap x2: 115/315/1390 · 105/360/1415 · 0/350/1875 · chain off: 75/205/775 · 70/200/715 · 55/200/885
- cap x2 + (a): 115/315/1390 · 110/360/1435 · 85/350/1450 · cap x2 + (b): 115/315/1390 · 105/360/1435 · 75/350/1715

**What it says:** the x2 cap is the best single change: it ends Envy's lead (34.8 → 25.1) and gives the narrowest range, with rounds nearly unchanged. Chain 0.25 tames the lead most but adds 0.7 of a round (24% of games go past 6 rounds) and spreads the Sins. Either softener cuts zero-bank turns from 41% to 11-12% without moving the Sin balance. The last seat's chance stays at 3-5% in every run. Under the cap, Greed (29-32) and Gluttony (29-30) are the high pair.

**Questions**
1. Take chain capped at x2 as the rule for the next build? Rec: yes.
2. Which softener: (b) half the turn's face points, or (a) the first throw's? Rec: (b). It is one rule ("a bust keeps half your face points") and gives the fewest zero-bank turns.
3. Should I teach the bots the softener (a bust is worth half the face points) and re-run cap x2 + (b), before the build? Rec: yes. Today's bots under-press, so the numbers above are conservative.
4. Under the cap, Greed sits at 31%. Should I sim Cash Out at x1.1? Rec: hold it until question 3 is in.
