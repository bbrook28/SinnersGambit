# Run design (Phase 7, revision 2, approved for Phase 8 2026-11-14)
Solo roguelike runs replace the bot table. Keep: throw, push your luck, Bank, bust, all the art. Strikes are gone: you bust when a throw has nothing you can keep. Numbers are starting guesses; the Phase 8 sim sets them. Points in multiples of 5, Mult and gold in whole numbers, multipliers only "x2", no percentages.

## 1. Run structure
- Pick a Sin (your starting kit). A run is **7 Circles** of three rounds: two trials, then the Sin who rules it. Each round: reach the target in **3 turns**. Reaching it ends the round; unused turns pay gold. Missing it ends the run.
- Circles 1-6 are ruled by the other six Sins; only mild twists (Sloth, Greed, Envy) may rule Circles 1-2. Circle 7 is your own Sin, turned against you. The next ruling Sin and its twist are shown in the shop.
- Targets (trial / trial / Sin; a full run takes about 22-28 minutes, §11): C1 1000 / 1500 / 2000, C2 2000 / 3000 / 4000, C3 3500 / 5000 / 7000, C4 6000 / 9000 / 12000, C5 10000 / 15000 / 20000, C6 16000 / 24000 / 32000, C7 25000 / 40000 / 50000. C1's trial is about 1.2 average turns of the start kit (820); later Circles assume relics. Aim: a good bot clears C1 95%, C4 60%, wins 40%.

## 2. Ruling Sins: one twist each (window fills the screen, twist in one line, then it shrinks to its seat)
| Sin | Twist | |
|---|---|---|
| Sloth | You throw one fewer die. | mild |
| Greed | Each Bank costs 1 gold; with none, it scores half (to a multiple of 5). | mild |
| Envy | Each turn, Envy takes one of your relics at random. | mild |
| Lust | Single dice score no Points. | |
| Wrath | Each die you leave unkept costs 10 Points (never below 0). | |
| Pride | Each Bank must beat your last, or it scores 0. | |
| Gluttony | Each Bank, Gluttony eats one of your dice (never below one; back after). | |

## 3. Scoring: keep and rethrow, Points x Mult
After each throw, tap the dice to keep; you must keep at least one group. Then rethrow the rest, or Bank.
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
| Sloth (Recommended) | A bust still banks your Points, with no Mult. | 6 |
| Wrath | A bust adds +3 Mult to your next turn. | 6 |
| Greed | When you Bank, +5 Points for every gold you hold. | 6 |
| Lust | Every pair you keep adds +2 Mult, not +1. | 6 |
| Envy | Your leftmost relic fires twice. Starts with one common relic. | 6 |
| Pride | Bank having kept only sets, no single dice: x2 total. | 6 |
| Gluttony | Once a turn, eat a die you can't keep; it counts as kept, for no Points. | 7 |

## 5. Relics: five slots, fire left to right, drag to reorder, sell for half
C = common (5 gold), U = uncommon (10), R = rare (15). The pool grows to 50+ in Phase 11.
| # | Relic | Effect | |
|---|---|---|---|
| 1 | Rosary | Each 6 you keep adds +1 Mult. | C |
| 2 | Gilt Pip | Each 4 you keep scores 15 more Points. | C |
| 3 | Saint's Knuckle | Each 5 you keep scores 15 more Points. | C |
| 4 | Votive Candle | +50 Points on your first throw each turn. | C |
| 5 | Cracked Bell | A single 3 can be kept, for 15 Points. | C |
| 6 | Collection Plate | +1 gold each time you Bank. | C |
| 7 | Ossuary | Your first throw each turn has one extra die. | C |
| 8 | Bone Dice | A set of 1s adds +3 more Mult. | C |
| 9 | Reliquary | When you Bank, +10 Points per die you own. | C |
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
| 22 | Gargoyle | +2 Mult for each throw after your second. | U |
| 23 | Tithe Box | Interest pays up to 10 gold, not 5. | U |
| 24 | Almoner's Purse | Unused turns pay 3 gold each, not 1. | U |
| 25 | Candelabra | +1 Mult for every relic you own. | U |
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
- Earn: clear a trial +5 gold, a Sin's round +10, each unused turn +1. Interest: +1 per 5 gold held at round end, up to 5.
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

## 11. Scratch sim (`sim/keep_sim2.gd`, one-step lookahead bot, 600 turns each) and Phase 8 plan
| Dice | Avg turn | Throws (p95) | Decisions | First-throw bust |
|---|---|---|---|---|
| 5 | 500 | 2.9 (5) | 1.9 | 0% |
| 6 | 820 | 3.1 (6) | 2.2 | 0% |
| 7 | 1180 | 3.0 (6) | 2.4 | 0% |
| 8 | 1670 | 3.2 (6) | 2.6 | 0% |
| 8, two faces each repainted to 6 | 4170 | 3.4 (6); bolder bot 4.9 (7) | 2.7-3.5 | 0% |
- A decision is a throw point with two or more legal options (keep choice x throw / Bank) within 20% of each other. Repainting two faces of one die at 6 dice: x1.5 average turn. Five dice fall under two decisions, so no kit starts there. If keeping every die returned them every time, the strongest build never stopped (95th percentile at the 40-throw cap), hence once a turn.
- Minutes: about 5 s a throw (throw, pops, taps), 3-5 throws a turn, about 2.5 of 3 turns used a round, 30 s of shop: 21 rounds is 22-28 minutes (bolder players at the top). 4 turns a round was 29-36.
- Phase 8 build: `run/` (rules only): `run_state.gd`, `round.gd`, `relics.gd` (hooks: on_keep, on_throw, on_bank, on_bust, on_round_end), `kits.gd`, `rulers.gd`, `shop.gd`. `ai/run_bot.gd`: keeps and throws by searching the whole turn (not one throw ahead), buys by simulating rounds with and without each offer. `sim/run_sim.gd` rebuilt. Placeholder board: today's tray and seals, Points x Mult, a relic row, a plain shop page.
- The run sim must report: win rate and Circle reached per Sin; relic pick rate (none above twice the average; this flags broken relics, not final balance); share of winning runs holding an x2 source (above 60%: add multiplicative uncommons); throws per turn (mean, and the strongest build's 95th percentile, 8 or fewer); decisions per turn; minutes per run; whether dice 7 and 8 each raise the average turn; share of turns ending in a bust for the best bot (target 10-25%; under 10%, tighten what is keepable, e.g. singles only on 5 and 6, and re-derive the numbers; the scratch sim's 0% first-throw bust suggests this is likely). Kits are balanced by win rate in the sim, with no handicaps carried over: Gluttony's seventh die is paid for by its weaker kit, tuned until its win rate matches.
