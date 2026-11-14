# Run design (Phase 7 draft, 2026-11-14)
Solo roguelike runs replace the bot table. Keep: throw all your dice, push your luck, Bank, three Strikes bust, all the art. Numbers are starting guesses; the Phase 8 sim sets them. Rule for numbers: Points in multiples of 5, Mult and gold in whole numbers, multipliers only "x2", no percentages.

## 1. Run structure
- Pick a Sin (your starting kit). A run is **7 Circles**. Each Circle is three rounds: two trials, then the Sin who rules it.
- Each round: reach the target in **4 turns**. Reaching it ends the round at once; unused turns pay gold. Missing it ends the run.
- Circles 1-6 are ruled by the other six Sins in a shuffled order. Circle 7 is your own Sin, turned against you.
- Between rounds: the shop. The next ruling Sin and its twist are always shown, so you can prepare.
- Targets (round 1 / round 2 / Sin): C1 300 / 450 / 600, C2 500 / 750 / 1000, C3 1000 / 1500 / 2000, C4 1800 / 2700 / 3600, C5 3000 / 4500 / 6000, C6 5000 / 7500 / 10000, C7 8000 / 12000 / 16000. Aim: a good bot clears C1 95%, C4 60%, wins 40%.
- Length: 21 rounds, about 25-35 minutes.

## 2. Ruling Sins (bosses): one twist each, no bot turns anywhere
Its window fills the screen, the twist shows in one line, then it shrinks to its seat above the tray for the fight.
| Sin | Twist |
|---|---|
| Sloth | You throw one fewer die. |
| Wrath | Each Strike costs 25 Points. |
| Greed | Each Bank costs 1 gold. No gold, no Bank. |
| Lust | Your best die each throw scores nothing. |
| Envy | Envy takes your leftmost relic for this fight. |
| Pride | Each Bank must beat your last, or it scores 0. |
| Gluttony | Each Bank, Gluttony eats one of your dice until the fight ends. |

## 3. Scoring: Points x Mult
- Each scoring die adds its Points (4 / 5 / 6 = 20 / 25 / 30) and +1 Mult. 3s do nothing. 1s and 2s are Strikes.
- Points and Mult add up across the whole turn and stay on screen. **Bank** multiplies them into the round score. A bust (third Strike) loses both and spends the turn.
- Order, for the motion pass: each die pops left to right, then "each throw" relics fire left to right, then on Bank the "when you Bank" relics fire, then Points and Mult slam together.
- Why Mult counts scoring dice, not throws (scratch sim, 4000 rounds): with Mult = throws, 3 dice average 200 a turn and 8 dice only 57, so buying dice would be a trap. Counting scoring dice keeps 3 dice (360) and 8 dice (295) close, and repainting Strike faces is what makes more dice pay (8 dice with no 2s: 420).
- The Throw seal shows the bust chance (exact, from each die's faces and your Strikes).

## 4. Starting kits (the Sin abilities become passives; nothing asks "use it?")
| Sin | Kit | Dice |
|---|---|---|
| Sloth (Recommended) | Your first Strike each turn doesn't count. | 3 |
| Wrath | A bust gives your next turn +3 Mult. | 3 |
| Greed | +1 gold every time you Bank. | 3 |
| Lust | Once a turn, a 3 becomes your best die in that throw. | 3 |
| Envy | Your leftmost relic fires twice. Starts with one common relic. | 3 |
| Pride | Bank with no Strikes: x2 total. | 3 |
| Gluttony | Once a turn, tap a thrown die to eat it: +50 Points, no Strike. Back next turn. | 4 |

## 5. Relics: five slots, fire left to right, drag to reorder, sell for half
C = common (5 gold), U = uncommon (10), R = rare (15).
| # | Relic | Effect | |
|---|---|---|---|
| 1 | Rosary | Each 6 gives +1 more Mult. | C |
| 2 | Gilt Pip | Each 4 scores 15 more Points. | C |
| 3 | Saint's Knuckle | Each 5 scores 15 more Points. | C |
| 4 | Votive Candle | +50 Points on your first throw each turn. | C |
| 5 | Cracked Bell | 3s score 15 Points, but add no Mult. | C |
| 6 | Collection Plate | +1 gold each time you Bank. | C |
| 7 | Ossuary | Throw one extra die on your first throw each turn. | C |
| 8 | Bone Dice | Each Strike still scores 10 Points. | C |
| 9 | Reliquary | When you Bank, +10 Points per die you own. | C |
| 10 | Psalter | Bank after a single throw: +4 Mult. | C |
| 11 | Sexton's Key | The shop offers one more relic. | C |
| 12 | Censer | +3 Mult when every die in a throw scores. | U |
| 13 | Martyr's Nail | When you Bank, +2 Mult per Strike you hold. | U |
| 14 | Holy Water | Your first 1 each turn is not a Strike. | U |
| 15 | Hourglass | When you Bank, +2 Mult per turn left this round. | U |
| 16 | Ember | +1 Mult for every bust this run. | U |
| 17 | Pilgrim's Staff | Gains +1 Mult for every round you clear. | U |
| 18 | Golden Calf | +1 Mult for every 5 gold you hold. | U |
| 19 | Twin Chalice | Your best die each throw counts twice. | U |
| 20 | Hair Shirt | +5 Mult on every Bank, but 3s are Strikes too. | U |
| 21 | Gargoyle | +2 Mult for each throw after your second. | U |
| 22 | Tithe Box | Interest pays up to 10 gold, not 5. | U |
| 23 | Almoner's Purse | Unused turns pay 3 gold each, not 1. | U |
| 24 | Candelabra | +1 Mult for every relic you own. | U |
| 25 | Pyre | Each bust adds 10 Points to your 6s for the run. | U |
| 26 | Halo | You bust on the fourth Strike, not the third. | R |
| 27 | Mirror Shard | Copies the relic to its right. | R |
| 28 | Thorn Crown | x2 total, but one fewer turn each round. | R |
| 29 | Last Rites | Bank holding exactly two Strikes: x2 total. | R |
| 30 | Indulgence | Once a round, a bust still banks your Points at x1. | R |

## 6. Combos that change how you play
1. **Halo + Martyr's Nail:** ride to three Strikes on purpose; every Bank carries +6 Mult.
2. **Mirror Shard + Last Rites:** x4 at exactly two Strikes; you stop banking early and stop pushing past two.
3. **Golden Calf + Tithe Box:** hoard instead of shop; each 5 gold is Mult and interest at once.
4. **Ember + Pyre** (best as Wrath): bust on purpose in Circles 1-2 to build a late-run engine.
5. **Ossuary + Votive Candle + Psalter:** one-throw turns, never press; bust chance stops mattering.
6. **Hourglass + Thorn Crown:** three turns, but a big first turn pays huge; the round becomes "win it on turn one".
7. **Censer + Gluttony:** eat the one die that didn't score so every throw is all-scoring.
8. **Hair Shirt + Holy Water + Bone Dice:** 3s strike too, but Strikes score and the first 1 is free; play with Strikes as income.
9. **Twin Chalice + Rosary + Six repaints:** build a dice set of 6s; every 6 is double Points and Mult.
10. **Candelabra + Sexton's Key:** go wide with cheap commons instead of saving for rares.

## 7. Shop and economy
- Earn: clear a trial +5 gold, a Sin's round +10, each unused turn +1. Interest: +1 per 5 gold held at round end, up to 5.
- Shop (after every round): 2 relics, 1 die, 2 repaints. Reroll 2 gold, +1 each time in the same shop.
- Prices: relic 5 / 10 / 15, die 5, repaint 5, sell a relic for half its price. Dice cap at 8 (two rows of four at twice today's size).
- Repaints (pick a die, the face is set by the offer): **Blank** a 2 (no Strike); **Six** a 3; **Gild** a face (+15 Points); **Crimson** a face (+2 Mult). A 1 can never be repainted, so every die keeps a Strike.
- Why save: interest, Golden Calf and Tithe Box reward a bank of gold, and Greed's round needs a gold per Bank. Seeing the next Sin in advance makes that a real choice.

## 8. What gets cut or merged
- **Purgatory: cut.** In a 4-turn round a bust already costs a quarter of your chances; a second penalty doubles the punishment and needs its own rules.
- **Greater abilities: cut.** Relics are the growth layer; a second built-in ability competes with them.
- **Statuses (flame, star, chevron, rings): cut.** The only lasting state is the ruling Sin's twist, shown on its window.
- **Table of 4 / 7, seat handicap, buying after Bank, the race to 1000: cut.** Dice are bought in the shop.
- **Ability prompts: cut.** Every kit is automatic except Gluttony's eat, which is a tap on a die, not a Yes / No card.
- **Bot-turn summary, Skip to my turn, Chronicle: cut.** No bots. Run history moves to stats.

## 9. Meta (Phase 11)
- Unlocks: start with Sloth and Wrath. Reaching Circle 4 unlocks Greed; the first win unlocks Lust; a win with each new Sin unlocks Envy, then Pride, then Gluttony. 20 relics start unlocked; 10 unlock by feats ("Bank 5000 in one turn").
- Collection: every Sin, relic, ruling twist and repaint; locked ones show as dark glass with how to unlock them. It is the rulebook.
- Difficulty: eight Vows, each adding one rule to the last (targets rise faster, Sin rounds have 3 turns, interest stops, four relic slots, ...). Winning on a Vow unlocks the next for that Sin.
- Stats: runs, wins per Sin, highest Circle, best Bank, most-used relics.
- Daily run: a date-seeded Sin, relic pool and Sin order, the same on every phone; your best is kept on the device (no online in v1).

## 10. Terms a new player must learn (8)
Strike, Bust, Bank, Points, Mult, Gold, Relic, Circle. Round, turn, target, shop and repaint are plain words.

## 11. The bot-table mode
Cut it from v1 (and pass-and-play with it, which changes CLAUDE.md's "v1" line once approved). `core/`, `sins/`, `ai/` and `sim/check_v3.gd` stay untouched, so a table mode can return after ship if playtesters ask.

## 12. Phase 8 build plan (for review, not started)
- New `run/` folder, rules only, no UI: `run_state.gd`, `round.gd` (turn loop on `Rules.roll`), `relics.gd` (data table plus hooks: on_die, on_throw, on_bank, on_bust, on_round_end), `kits.gd`, `rulers.gd`, `shop.gd`. Reuses `core/rules.gd` without changing it.
- `ai/run_bot.gd` (new file in `ai/`, needs your OK): throws while the bust chance is under its nerve; buys by simulating 200 rounds with and without each offer.
- `sim/run_sim.gd` replaced by a run sim: win rate and Circle reached per Sin, relic pick rate (none above twice the average), gold curve, turns per run.
- Placeholder board: today's tray and seals, a Points x Mult readout, a relic row, a plain shop page.
