# Table design: rules and content (V4; owner of the table game's rules)
The table game is the real game: Play opens it. Your opponents are the Seven Sins, and they tempt you to push too far. Numbers here are checked against `core/rules.gd` `Rules.V4` and `sins/`; where they differ, the code wins. How the table looks and behaves as built: `Docs/TableSpec.md`. Phase status: `Docs/UXPlan.md`. Draft 2 with its build plan and sim log: `Docs/archive/TableDesign_draft2.md`.

## 1. Base rules (`Rules.V4`; V2 and V3 stay unchanged so old tests and saves replay)
- Throw all your dice; 4, 5, 6 score 5x face; several scorers in one throw x1.5 / x2 / x2.5 (+x0.5 each); a throw's points round down to a multiple of 5.
- 1 and 2 are Strikes; three Strikes bust: you lose the turn and start the next in Purgatory (a free throw; any 6 frees you, else pay 50).
- Bank keeps the turn's points; after a Bank you may buy dice for 100. Start with 3 dice, never below 2. Seat N starts with 20 x (N-1). First to 1000 wins.
- Nothing asks a player who isn't holding the phone, and always-yes abilities are automatic: Fury, Untouchable, Green-Eyed Glance, Mimicry, Whisper of Desire.
- No percentages: every ability number is flat (§5).
- First Game: Basic abilities only, at a table of 4. Planned, not built: "Greater" leaves the screen (the second ability reads "From 300, once a round:"); today the rulebook still says Greater.

## 2. Pass-and-play (Phase 7b, not started)
- Menu: **Solo** (the ladder), **Table** (setup), Continue. Table setup: 2-7 seats, each a Sin portrait (tap for the carousel; no Sin twice) with a Human / Bot toggle, and a Temptations toggle (on). Defaults: 4 seats, you + 3 bots.
- Handoff beat before a human's turn when the last human turn was someone else's: the next Sin's window fills the screen in its colour, "Pass to Wrath", tap to start. No names: each human is their Sin.
- Temptations come from the game in the offering Sin's voice; only rival Sins tempt you.

## 3. Sin lines
- Voices: Wrath barks and burns; Greed keeps the books; Lust wants more; Envy compares; Pride is royal; Gluttony eats; Sloth yawns.
- The lines themselves live in code only: `RulesText.LINES` (9 events x 5 lines x 7 Sins; 6 words max, `{name}` is the rival, `{host}` and `{n}` for Recall), checked by `tests/lines_check.gd`.
- A bot Sin says a line on about half of events (`Tuning.LINE_CHANCE` 0.5), at most one per turn, never the same line twice in a game. Events: own bust, rival's bust, big Bank (200+), takes the lead, attacked, takes aim, wins, loses, Recall (Solo, not built).
- Rating (Ben, 2026-11-15): teen level, above 9+. Innuendo and threats are fine; nothing explicit, no gore, no profanity or slurs.

## 4. Rivalry
- Each bot keeps a grudge list for the game: whoever aimed an ability at it (Fury, Pact, Drag). Paying one back clears that grudge.
- Targeting (Pact, Drag): the newest grudge, unless the leader is 200+ ahead of that seat; then the leader. Fury fires at 100+ on a grudge, 150+ on anyone. The bot says a "Takes aim" line; an "Attacked" line answers.
- Each Sin's bot plays to its nature (`ai/bot_policy.gd` `SIN_RISK`): Wrath, Lust and Gluttony push (0.9), Sloth and Greed bank sooner (1.15), Pride and Envy plain.

## 5. Bot turns and abilities
- A bot turn averages 2.5 s or less at 1x (`Tuning.BOT_PACE` 6.0; `tests/bot_pace.gd`). No log text, no "thinking".
- Wording is `RulesText.SINS`; numbers are `Rules.V4`.

| Sin | Basic | Greater (from 300, once a round) |
|---|---|---|
| Wrath | **Spark of Rage:** +40 whenever a rival busts. | **Fury:** the first rival throw worth 150+ rerolls its 3 best dice. (auto) |
| Greed | **The Vig:** when a rival buys a die, you get 40 of its price. | **Interest:** Bank and buy no dice: +75. |
| Gluttony | **Feast:** once a turn, feed a thrown die for +75; a fed Strike doesn't count. | **Gorge:** your first die each turn costs 40. |
| Lust | **Whisper of Desire:** once a turn, your 3 or 2 becomes the last player's best die. (auto) | **Binding Pact:** pick a rival; take 50 of the next turn they Bank. |
| Envy | **Green-Eyed Glance:** while behind, your first scoring throw each turn copies the last player's best die. (auto) | **Mimicry:** that throw gains two copies instead. (auto) |
| Pride | **Hubris:** before throwing, bet 150, 200 or 250: Bank that much for x1.5, else 0. | **Untouchable:** the first ability aimed at you bounces back. (auto) |
| Sloth | **Lazy Bones:** your first Strike each turn doesn't count. | **Drag:** pick a rival; they throw 3 fewer dice next turn (never below 1). |

Choices left: Feast (which die, or none), Hubris (bet or not), Pact and Drag (which rival). Feast and Gorge keep you at 2 dice.

## 6. Solo: the ladder (Phase 7c, not started)
- Seven Circles in order; each is one table game to 1000: C1-2 you + 2 bots, C3-7 you + 3 bots. One bot is the **host**, whose house rule binds every seat, host included. C1 is a First Game (Basic only); bots grow bolder each Circle. Hosts: the other six Sins in random order (only Sloth, Greed or Envy host C1-2); C7 is hosted by your own Sin. The other bots are drawn from Sins you've met.
- Win to go down a Circle; lose and replay that table (perks and marks stay). Progress saves at every table start. After each win, choose one of three perks; perks last the whole descent.
- Unlocks: Sloth and Wrath to start; beating a host unlocks that Sin for Solo and Table.

| Host | House rule | Host | House rule |
|---|---|---|---|
| Sloth | Everyone throws one fewer die (never below 2). | Lust | A throw with one scoring die scores nothing. |
| Greed | Each Bank costs 25. | Wrath | A bust also costs 50 of your score. |
| Envy | The leader throws one fewer die. | Pride | A Bank under 100 scores nothing. |
| Gluttony | Everyone starts with 5 dice; dice cost 150. | | |

Perks (15): 1 Start every table with 4 dice. 2 Start every table with 100. 3 Your first die each table is free. 4 Every 6 you throw scores 10 more. 5 Three scorers in one throw: +50. 6 Your first throw each turn has one extra die. 7 Purgatory never costs you. 8 Once a table, a bust keeps its points. 9 +20 whenever a rival busts. 10 Your second ability is ready from the start. 11 Refuse a temptation: +25. 12 Accept a temptation: +25. 13 Bank 200 or more: +25. 14 The first ability aimed at you each table misses. 15 Cleanse: remove every mark of one Sin (once).

**Endings** (after C7, by marks taken over the whole descent): **The Saint** (3 marks or fewer); **The Eighth Sin** (marks from all seven Sins); otherwise **Claimed**: the Sin you took the most marks from gives you its seat (7 endings, one painted scene and 3 lines each). Nine endings; the collection shows which you've seen. Endings and perk icons are painted in slice (c), which builds them.

## 7. Temptations, marks, claims
- At a throw-or-bank decision, from the game's second round on (never in a First Game), at most every other turn of yours (`tempt_gap` 2): one rival Sin offers, at the first decision of the turn where one of its offers fits. Pick weight 1, +4 for each of its marks the player holds. The offer is a full-screen moment (`Docs/TableSpec.md`), **Accept** / **Refuse**, one tap. The first offer you ever see carries one tip: "Accept for the gain and take its mark. Two marks, and it claims you." Bots get offers too. Which game first shows temptations to a new player: `Docs/Onboarding.md`.
- Every offer is one gain and one cost (`sins/temptations.gd`; spoken line and terms in `RulesText.TEMPT_SAY`, `GAIN_TERMS`, `COST_TERMS`). Gains: points now; clear a Strike; extra dice this throw and x2 this throw (accepting throws at once); a free die. Costs: lose points now (never below 0); lose points from your next Bank; start next turn with a Strike; fewer dice next turn (never below 1); lose a die after this turn (never below 2). A pending cost shows until paid; a bust doesn't pay it.
- Accepting gives you that Sin's **mark**. At **2** marks of one Sin, its **claim** binds you for the rest of the table and those marks clear. Solo counts every mark ever taken for the endings.

| Sin | Offers: gain, cost (when) | Claim at 2 marks |
|---|---|---|
| Wrath | (2 Strikes) Wipe a Strike. Your next Bank loses 25.<br>(not leading) Take 60 from the leader. Start next turn with a Strike.<br>Throw at x2. Lose 50 now.<br>(no Strikes) Two extra dice this throw. Your next Bank loses 50. | Each bust costs you 125. |
| Greed | A free die. Your next Bank loses 75.<br>(2 Strikes) Clear a Strike. Your next Bank loses 25.<br>Throw at x2. Your next Bank loses 50.<br>Take 100 now. I take a die after this turn. | Every Bank pays Greed 20. |
| Lust | Throw at x2. One fewer die next turn.<br>Take 50 now. One fewer die next turn.<br>(no Strikes) Two extra dice this throw. One fewer next turn.<br>(1+ Strike) Forget that Strike. Your next Bank loses 25. | You can't Bank before your second throw. |
| Envy | (you trail, no Strikes) Two extra dice this throw. Start next turn with a Strike.<br>(you trail) Throw at x2. Start next turn with a Strike.<br>(you trail) A free die, like theirs. Lose 75 now.<br>(1+ Strike) Clear a Strike. One fewer die next turn. | While you lead, each Bank pays Envy 25. |
| Pride | Throw at x2, like royalty. Your next Bank loses 50.<br>(no Strikes) Two extra dice, as you deserve. One fewer next turn.<br>(1+ Strike) Clear a Strike. Lose 25 now.<br>Take 60 now. Start next turn with a Strike. | A Bank under 200 scores nothing. |
| Gluttony | (no Strikes) Two extra dice this throw. Lose 25 now.<br>(1+ Strike) Clear a Strike. I eat a die after.<br>Throw at x2. I eat a die after.<br>A free die. Start next turn with a Strike. | Each bust eats one of your dice (never below 2). |
| Sloth | Take 90 now. Two fewer dice next turn.<br>(2 Strikes) Rest that Strike. One fewer die next turn.<br>A free die. Two fewer dice next turn.<br>Take 60 and rest. Start next turn with a Strike. | You throw two fewer dice (never below 1). |

## 8. Terms a new player learns (8)
Strike, Bust, Bank, Purgatory, Temptation, Mark, Claim, Circle. Plain words, not terms: seat, house rule, perk, host (shown as "Wrath's table"). "Greater", "Supply", "Line", "Ladder" never appear on screen (Greater still does: §1).

## 9. Balance as measured (`sim/check_v3.gd -- 4000 v4`, bots only, 2026-11-14)
- 4 seats (fair 25): Wrath 24.0, Greed 25.1, Lust 26.7, Envy 28.5, Pride 28.2, Gluttony 21.4, Sloth 21.1. 7 seats (fair 14.3) is off: Greed 29.4, Lust 9.6, Sloth 8.2; tune with 7b.
- Pace: 5.4 rounds, about 1.6 min with you and 3 bots.
- Temptations: 8.5 offers a game at 4 seats, 41% accepted. Claims 0.14 a game, under the 0.5-1.5 target; left as is until play shows how often a human is claimed (if rare, drop the bot's claim price from 100 to 60).
- Claim cost (relative win drop, target 15-35%): Wrath 18, Greed 19, Lust 19, Envy 18, Pride 25, Gluttony 18, Sloth 30.
- Purgatory: 6.1 a game, half freed by a 6; turning it off moves no Sin more than 2.1 points. Kept for the drama.

## 10. Agency and comeback (draft for Ben's OK, 2026-11-15; nothing here is built)
Why: in build 114 Ben (Sloth, 4 seats) ended on 20 against 390-545 with no way back, sat in Purgatory, never saw his ability act, and felt the dice decided. Measured with `sim/agency_sim.gd` (sim only; 20,000 games at 4 seats, V4, plain bots; skill: 4,000 games per Sin).

| Measure | Now | Purgatory off | + universal rethrow | Target |
|---|---|---|---|---|
| Skill edge: best bot vs 3 plain, mean (range) | 31.8% (26.3 Sloth to 39.7 Greed) | | | 35-45% |
| Comebacks (last at 500 goes on to win); lead changes a game | 7.3%; 4.15 | 7.3%; 4.14 | 7.2%; 4.15 | 10-20% |
| Last seat's turns begun in Purgatory (all seats) | 45.5% (30.5) | 0 | 33.7% (19.6) | |
| Equal bots, lowest to highest Sin | 20.9 Sloth to 28.7 Lust | 19.7 to 27.8 | 16.5 Sloth to 35.2 Pride | 22-28 |
| Last seat's final score; rounds; minutes (you + 3 bots) | 272; 5.5; 1.6 | 295; 5.4; 1.5 | 336; 4.4; 1.4 | |
- Skill edge comes mostly from one decision: never buying dice (the best bot stays on 3 dice; at 5 it wins 24-27%). Throw-or-bank timing adds 1-3 points. Buying at 100 is a trap.
- **Rec, Purgatory: cut.** Off, no Sin moves more than 1.5 points, the last seat ends 23 higher, games are 0.1 min shorter, one term fewer. A bust just loses the turn. **Rec, universal rethrow: drop.** Used 0.75 times a turn, it saves a bust on 18% of uses and shortens games by a round, but comebacks don't move and Sin shares spread to 16.5-35.2 (it duplicates Sloth's and Wrath's powers). The active powers below give the same relief per Sin.
**Active powers.** Each Sin's Basic becomes a once-a-turn power: tap my Sin's sigil seal, a third control between Bank and Throw (`Docs/TableSpec.md`). It glows when usable, shows spent when used, fires with the ring-and-sigil effect. Bots use theirs visibly. Greater stays as it is. Target: used on about half of turns, each Sin 22-28% with equal bots (sim before any UI).
| Sin | Power (10 words max) | When it's worth it |
|---|---|---|
| Sloth | Ignore this throw's Strikes. | after a bad throw; once, so save it or spend it |
| Wrath | Rethrow your Strikes once. | after a throw with Strikes |
| Greed | Bank half your stake now; keep throwing for the rest. | a big stake you want to push |
| Lust | Turn one of your dice into the last player's best. | after a throw: which die |
| Envy | While behind, this throw scores double. | before a throw: commit, a bust wastes it |
| Pride | Name your Bank; reach it for x1.5, else nothing. | before the first throw: 150, 200 or 250 |
| Gluttony | Eat one thrown die: +50, and it isn't a Strike. | after a throw; the die is back next turn |
**Comeback through temptation.** Behind the leader by D: an offer's gain is x(1 + D/200), up to x3 (points rounded to 5; extra and free dice rounded); at D 400+, "clear a Strike" clears all and x2 becomes x3. Costs stay the same. Trailing by 150+, an offer comes every turn (else every other). Measured (points and dice only): comebacks 7.3 to 11.1% with both; 12.4% at D/100 with Purgatory off. Greed and Sloth slip to 18-20, so retune with the powers.
**First-game bots.** A novice stand-in (throws on under 150 and 2 Strikes, buys to 4) wins 22.9% of Onboarding game one (3 seats, no abilities) against plain bots. Bots that bank at 200 with risk 1.6 and buy to 4 give 42.9%. **Rec:** that setting for game one only, aiming at 40%.
**The Master of the Dance.** A Danse Macabre skeleton, ink on the page (not glass), the table's host. Neutral: he wins whoever loses. He deals and narrates, snuffs my Strike candles, announces each Sin before its temptation, reacts to busts, big Banks and wins, and goads at my decision in words only. Offers and their terms stay with the Sins. Voice: courtly, dry, amused; never cruel to a new player. At most one line a turn, on about a third of events (`MASTER_CHANCE` 0.33), never in the same beat as a Sin's line.
| Event | Lines (6 words max) |
|---|---|
| Game start | Take your seats. The dance begins. / Dice ready. Souls ready. Shall we? / Seven Sins, one table. Delightful. / Mind your candles. Let us begin. / Welcome, welcome. Do throw first. |
| My bust | Ah. The dice have spoken. / Three candles out. Do sit. / A misstep. Everyone stumbles once. / Gone. Shall we try again? / Pity. It was going beautifully. |
| My big Bank | Splendid. Do bank like that again. / Well kept. The Sins noticed. / A fine harvest, if I may. / Bravo. My compliments to your nerve. / Into your keeping. Nicely done. |
| Rival's bust | Oh dear. Not you this time. / {name} trips. How very human. / Snuffed. Do take note. / The dance claims {name}. Briefly. / Careful steps win. Usually. |
| A Sin arrives to tempt | {name} has a little proposal. / A word from {name}, please. / Ah, {name} wishes to bargain. / Listen closely. {name} is generous. / {name} approaches. Mind your purse. |
| Mark taken | Marked. {name} will remember. / A small price. For now. / Signed in ink. How brave. / {name} smiles. That's rarely good. / One mark. Do count them. |
| Claim | Two marks. {name} owns you now. / Claimed. I did mention it. / {name} takes a seat in you. / Bound. The dance goes on. / Well. A lasting arrangement, then. |
| My win | The dance is yours. Well played. / A thousand. I'm genuinely impressed. / Victory. The Sins will sulk. / Bow, please. You've earned it. / Splendid. Do come again. |
| My loss | Not tonight. There's always another. / The dice were unkind. Again? / A good dance, all the same. / Rest. The table will wait. / Close. Closer than they'd admit. |
| Idle at my decision | Throw, or keep? Your call. / Candles are patient. I am less. / Courage or caution, dear guest? / Another throw? Purely a suggestion. / Take your time. Eternity's long. |
- **Rec, jester: cut**: the Master covers every reaction; one fewer object (restraint 5). Ladder: he opens each Circle ("Wrath's table"). Endings: The Saint, he bows and lets you leave the dance; The Eighth Sin, he gives you his place as host; Claimed, he leads you by the hand to the Sin's window and seats you in it.
- Art (none painted yet), each in the style of `assets/art/runtime/marginalia/skeleton.png`, flat ink line: idle leaning on a candle-snuffer; snuffing a candle; a sweeping bow (game start, a Sin's arrival); pointing at the dice (goad); applause (big Bank, win); a shrug (bust); writing in a ledger (mark); a hand on my shoulder towards a window (claim); leading the dance, full figure (endings).
**Changes for OK.** `core/`: `Rules.V5` (V4 replays): purgatory off, power and comeback keys; `game.gd`: a power window before and after each throw (once a turn), comeback scaling and the every-turn offer, Master events through `view`; `turn_state.gd`: power used. `sins/`: each Sin's Basic becomes `power_ready()` / `use_power()` under V5 (old Basics kept for V4); `temptations.gd`: scaled gains. `ai/`: `bot_policy.gd` `wants_power()` per Sin, a first-game setting (bank 200, risk 1.6, buy 4), and buying reviewed (see question 2). Also `sim/agency_sim.gd` measures power use and shares before any UI.
