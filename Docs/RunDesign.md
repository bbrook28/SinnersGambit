# Run design (revision 3: Phase 8 sim numbers, 2026-11-14; revision 2 approved for Phase 8)
Solo roguelike runs replace the bot table. Keep: throw, push your luck, Bank, bust, all the art. Strikes are gone: you bust when a throw has nothing you can keep. Numbers are starting guesses; the Phase 8 sim sets them. Points in multiples of 5, Mult and gold in whole numbers, multipliers only "x2", no percentages.

## 1. Run structure
- Pick a Sin (your starting kit). A run is **7 Circles** of three rounds: two trials, then the Sin who rules it. Each round: reach the target in **3 turns**. Reaching it ends the round; unused turns pay gold. Missing it ends the run.
- Circles 1-6 are ruled by the other six Sins; only mild twists (Sloth, Greed, Envy) may rule Circles 1-2. Circle 7 is your own Sin, turned against you. The next ruling Sin and its twist are shown in the shop.
- Targets (trial / trial / Sin; tuned by the Phase 8 run sim, §11): C1 800 / 1000 / 1200, C2 2000 / 3000 / 3500, C3 3500 / 5500 / 7000, C4 7000 / 10000 / 12000, C5 10000 / 13000 / 15000, C6 14000 / 17000 / 18000, C7 17000 / 20000 / 21000. A Sin's round target is the table's times its twist factor (§2), to the nearest 100. Aim (Ben, Phase 8): the best bot clears C1 99%, C4 80%, wins 60-70%; harder play comes from Vows (§9). Late targets are nearly flat because the bot's builds stop growing after C5 (5 relic slots, 8 dice); Phase 11's bigger pool should let them ramp.

## 2. Ruling Sins: one twist each, in that Sin's round only (window fills the screen, twist in one line, then it shrinks to its seat). Factor = the round's target multiplier.
| Sin | Twist | |
|---|---|---|
| Sloth | You throw one fewer die. | mild, x0.9 |
| Greed | Each Bank costs 1 gold; with none, it scores half (to a multiple of 5). | mild, x1.15 |
| Envy | Each turn, Envy takes one of your relics at random, until the round ends. | mild, x0.7 |
| Lust | Single dice score no Points. | x0.85 |
| Wrath | Each die you leave unkept costs 10 Points (never below 0). | x0.75 |
| Pride | Each Bank must beat your last Bank this round, or it scores 0. | x0.6 |
| Gluttony | Each Bank, Gluttony eats one of your dice (never below one; back after the round). | x0.85 |

## 3. Scoring: keep and rethrow, Points x Mult
After each throw, tap the dice to keep; you must keep at least one group. A tap keeps a die's whole group (all dice of that face); you can't split a set. Then rethrow the rest, or Bank. Tightening singles to 5 and 6 was tried in the sim and rejected (§11).
| You can keep | Points | Mult |
|---|---|---|
| A single 4, 5 or 6 | 20 / 25 / 30 | +0 |
| A set: two or more matching dice, any face | 5 per pip on each die | +1 per die after the first (pair +1, three +2, four +3) |
| A lone 1, 2 or 3 | can't be kept | |
- Mult starts at 1. Points and Mult add up across the turn and stay on screen; **Bank** multiplies them into the round score.
- **Bust:** a throw with nothing you can keep. You lose the turn's Points and Mult. The Throw seal shows the bust chance for the dice you would rethrow.
- Keep every die and they all come back for another throw, **once a turn**. After that, keeping every die banks the turn. Every die keeps its 1; repaints change at most two other faces.
- Order, for the motion pass: each kept die pops its Points left to right, each set adds its Mult, "when you keep" relics fire left to right; on Bank, "when you Bank" relics fire, then Points and Mult slam together.

## 4. Starting kits: passives, nothing asks "use it?"
| Sin | Kit | Dice |
|---|---|---|
| Sloth (Recommended) | A bust still banks your Points, with half your Mult. | 6 |
| Wrath | A bust adds +5 Mult to your next turn. | 6 |
| Greed | When you Bank, +2 Points for every gold you hold. | 6 |
| Lust | Every pair you keep adds +2 Mult, not +1. | 6 |
| Envy | Your leftmost relic fires twice. Starts with one common relic. | 6 |
| Pride | Bank having kept only sets, no single dice: x2 total. | 6 |
| Gluttony | Once a turn, eat a die you can't keep; it counts as kept, for no Points. | 7 |

## 5. Relics: five slots, fire left to right, drag to reorder, sell for half
C = common (5 gold), U = uncommon (10), R = rare (15). The pool grows to 50+ in Phase 11.
| # | Relic | Effect | |
|---|---|---|---|
| 1 | Rosary | Each 6 you keep adds +1 Mult. | U |
| 2 | Gilt Pip | Each 4 you keep scores 15 more Points. | C |
| 3 | Saint's Knuckle | Each 5 you keep scores 15 more Points. | C |
| 4 | Votive Candle | +50 Points on your first throw each turn. | C |
| 5 | Cracked Bell | A single 3 can be kept, for 15 Points. | U |
| 6 | Collection Plate | +1 gold each time you Bank. | C |
| 7 | Ossuary | Your first throw each turn has one extra die. | C |
| 8 | Bone Dice | A set of 1s adds +3 more Mult. | C |
| 9 | Reliquary | When you Bank, +5 Points per die you own. | C |
| 10 | Psalter | Bank after a single throw: +4 Mult. | C |
| 11 | Sexton's Key | The shop offers one more relic. | C |
| 12 | Prayer Beads | A 4, 5 and 6 in one throw keep as a set (+2 Mult). | U |
| 13 | Censer | +3 Mult each time you keep every die. | U |
| 14 | Martyr's Nail | When you Bank, +1 Mult per die left unkept. | U |
| 15 | Holy Water | Once a turn, a bust rethrows instead. | U |
| 16 | Hourglass | When you Bank, +2 Mult per turn left this round. | U |
| 17 | Ember | +1 Mult for each round you busted in, this run. | U |
| 18 | Pilgrim's Staff | Gains +1 Mult for every round you clear. | U |
| 19 | Golden Calf | +1 Mult for every 5 gold you hold. | U |
| 20 | Twin Chalice | Your largest set each turn counts one die bigger. | U |
| 21 | Hair Shirt | +5 Mult on every Bank, but single dice can't be kept. | U |
| 22 | Gargoyle | +1 Mult for each throw after your second. | U |
| 23 | Tithe Box | Interest pays up to 10 gold, not 5. | U |
| 24 | Almoner's Purse | Unused turns pay 3 gold each, not 1. | U |
| 25 | Candelabra | +1 Mult for every relic you own. | R |
| 26 | Pyre | Each round you bust in adds 10 Points to your 6s. | U |
| 27 | Halo | Bank with a set of four or more kept: x2 total. | R |
| 28 | Mirror Shard | Copies the relic to its right. | R |
| 29 | Thorn Crown | x2 total, but one fewer turn each round. | R |
| 30 | Last Rites | Bank with exactly one die left unkept: x2 total. | R |

## 6. Combos that change how you play
1. **Hair Shirt + Lust:** sets only; every pair is +2 Mult and the single 6 you used to keep is bait.
2. **Mirror Shard + Last Rites:** x4 with one die left; you push down to the last die every turn.
3. **Censer + Gluttony:** eat the one die you can't keep, so you keep every die and they come back.
4. **Halo + Twin Chalice:** a three counts as four, so every three of a kind is x2.
5. **Martyr's Nail + Psalter + Ossuary:** one throw, keep a single die, Bank with six unkept; turns take seconds.
6. **Golden Calf + Tithe Box** (best as Greed): hoard instead of shop; gold is Mult, Points and interest at once.
7. **Ember + Pyre** (best as Wrath): bust once a round on purpose in Circles 1-2 to build a late engine.
8. **Bone Dice + Cracked Bell:** 1s and 3s become worth keeping; you stop rethrowing low dice.

## 7. Shop and economy
- Earn: clear a trial +5 gold, a Sin's round +10, each unused turn +1. Interest: +1 per 5 gold held at round end (before pay), up to 5. A run starts with 0 gold.
- Shop (after every round): 2 relics, 1 die, 2 repaints. Reroll 2 gold, +1 each time in the same shop.
- Prices: relic 5 / 10 / 15, sell for half; repaint 5. A die costs 10, then 20 (each die adds about 40% to the average turn, §12). Dice cap at 8.
- Repaints (pick a die; at most two faces per die, never the 1): **Six** (a face becomes a 6), **Gild** (the face scores +15 Points when kept), **Crimson** (the face adds +1 Mult when kept).
- Why save: interest, Golden Calf, Tithe Box and Greed's kit pay for holding gold, and Greed's round charges a gold per Bank. Seeing the next Sin in advance makes it a real choice.

## 8. Cut or merged
- **Strikes and the Strike candles: cut.** Keep-and-rethrow makes its own risk.
- **Purgatory, Greater abilities, statuses, Table of 4 / 7, seat handicap, buying after Bank, the race to 1000, ability prompts: cut.** Relics are the growth layer; dice are bought in the shop; every kit is automatic except Gluttony's eat, a tap on a die.
- **Bot table, bot-turn summary, Skip to my turn, Chronicle: cut** (with pass-and-play, agreed 2026-11-14). Run history moves to stats; `core/`, `sins/`, `ai/` stay so a table mode can return after ship.

## 9. Meta (Phase 11)
- Unlocks: start with Sloth and Wrath. Circle 4 unlocks Greed; the first win unlocks Lust; a win with each new Sin unlocks Envy, then Pride, then Gluttony. 20 relics start unlocked; 10 unlock by feats.
- Collection: every Sin, relic, twist and repaint; locked ones show as dark glass with how to unlock them. It is the rulebook.
- Difficulty: eight Vows, each adding one rule to the last; a win unlocks the next for that Sin. Stats: runs, wins per Sin, highest Circle, best Bank, most-used relics. Daily run: date-seeded Sin, relic pool and Sin order; best kept on the device.

## 10. Terms a new player must learn (8)
Set, Bust, Bank, Points, Mult, Gold, Relic, Circle. Keep, single, round, turn, target, shop and repaint are plain words.

## 11. Phase 8 run sim (`sim/run_sim.gd`, `ai/run_bot.gd`)
The bot searches the whole turn (Monte Carlo: every legal keep scored, the best five played to the end of the turn 16 times each with a fast policy) and plays for the round: a turn's worth is the chance it clears the target. It buys by simulating 40 turns with and without each offer and estimating rounds survived over the next nine. Minutes: 5 s a throw, 30 s a shop. Pass of 420 runs (60 per Sin), 2026-11-14, before the Bell / Candelabra / Gargoyle fix; the 1,000-per-Sin report replaces these numbers.

| Measure | Result | Target |
|---|---|---|
| Win rate (best bot) | 62% | 60-70% |
| Clears C1 / C4 | 98% / 85% | 99% / 80% |
| Win rate per Sin | Sloth 63, Wrath 58, Greed 58, Lust 68, Envy 55, Pride 58, Gluttony 70 | within ±5 (only if it survives 1,000 per Sin) |
| Turns ending in a bust | 6.0% playing to the target; 22-30% playing for points (plain dice) | 10-25%: accepted as is (Ben, Phase 8) |
| Throws per turn | mean 3.3, p95 7; strongest fifth of C7 builds p95 8 | p95 of strongest ≤ 8 |
| Decisions per turn | 2.49 in runs; 2.45 at 6 plain dice | 2 or more |
| Minutes per run | 19.0 all, 21.9 winning (p10 18.4, p90 25.2) | 20-30 |
| Winning runs holding an x2 source | 28% (relics alone 16%) | under 60%: no multiplicative uncommons needed |
| Relic pick rate | average 22%; Cracked Bell 63%, Gargoyle 46% flagged | none above twice the average |

- Plain dice, playing for points (avg turn / bust / throws / decisions): 5 dice 619 / 26% / 3.9 / 2.0; 6 dice 907 / 30% / 4.2 / 2.5; 7 dice 1421 / 24% / 4.5 / 2.8; 8 dice 2032 / 22% / 4.8 / 3.2. Dice 7 and 8 each raise the average turn (x1.57, x1.43).
- Singles on 5 and 6 only (tried): bust 20% but decisions 0.8 a turn, turns halve, C1 clears 46%. Rejected; 4/5/6 stay.
- What changed from revision 2: targets (§1), twist factors (§2), whole-group keeping (§3), Sloth half Mult, Wrath +5, Greed +2 (§4), Rosary uncommon, Reliquary +5 per die, then Cracked Bell uncommon, Candelabra rare, Gargoyle +1 (§5).
- Sin rounds still decide most runs (late builds plateau near 25k a round at p50); trials fail 0-5%.
- A decision is a throw point where the best two options (keep choice x throw / Bank, by expected turn score) are within 20%.
- Run it: `godot --headless --path . --script res://sim/run_sim.gd -- runs=20 [sin=Lust] [key=JSON]`; parallel parts with `out=`, then `merge=`. Phase 7's scratch pre-screen stays in `sim/keep_sim2.gd`.
