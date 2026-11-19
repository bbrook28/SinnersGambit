# Table design: rules and content (V4; owner of the table game's rules)
The table game is the real game: Play opens it. Your opponents are the Seven Sins, and they tempt you to push too far. Numbers here are checked against `core/rules.gd` `Rules.V4` and `sins/`; where they differ, the code wins. How the table looks and behaves as built: `Docs/TableSpec.md`. Phase status: `Docs/UXPlan.md`. Draft 2 with its build plan and sim log: `Docs/archive/TableDesign_draft2.md`.

## 0. The table game as built (`Rules.V5`, REPLY 21; checked against `core/` and `sins/` on 2026-11-16)
Seats: you and 3 Sins (first game) or the table size you pick, 2-7. Everyone starts with 3 dice; the supply is 27 in all. No win score: the Master calls the end.
**A round:** (1) the Master marks the strict leader (score above 0): that seat scores no chain this round. (2) Each seat takes a turn in order. (3) At the round's end, if the leader has 550+ and at least 3 rounds are done, he calls it: one more round, then the final round; the highest total wins (a tie is drawn at random). Agreed, not built (REPLY 41): the final round runs from the leader down, so the last seat throws last; the Master's final-round line names the order. Today seat 0 throws first every round, and the first seat wins 14.6% against the last seat's 35.8% (sim/seat_sim.gd).
**A turn:**
1. Start: Pride may name a Bank (Hubris).
2. Throw all your dice (fewer if a debt or Drag says so; never below 1).
3. Rivals react (Greater abilities, from game two), then your own power if it is a throw power (Wrath, Lust, Envy, Gluttony, Sloth), once a turn.
4. Strikes: every 1 and 2 is a Strike; 3 in the turn is a bust. A bust loses the stake but keeps half the turn's face points still in the stake (to 5; not the share Cash Out banked, REPLY 22), and the turn ends (no buying). Kept or not, by power: Lust's and Sloth's changed dice and Wrath's rethrows count as faces; Envy's copy, Devour's +45 and any chain are stake only and are lost; Hubris doesn't touch a bust.
5. Score: 4, 5, 6 score 5x their face; each scorer past the first adds x0.5, capped at x2 (none for the marked seat); rounded down to 5. It adds to your stake.
6. Decide: first an offer, if one is due (from round 2, at most every other turn of yours; every turn when you're 150+ behind). Accepting takes its effect now. Then Greed's Cash Out if you use it (it forces a throw). Then throw again (step 2) or bank.
7. Bank: the stake joins your total (Hubris x2 if it reached its named Bank, else 0).
8. Buy: after banking, buy dice for 100 each (Gluttony's Gorge makes the first 40, from game two), at most 5 at once, as many as you can afford and the supply holds. Greed's Vig: when a rival buys, Greed gets 60 a die.
**Powers (once a turn, free):** Wrath rethrows up to 2 of this throw's Strikes (they can land as Strikes again). Greed's Cash Out banks half the stake (to 5) at x1.25 and throws on; the other half stays as stake. Lust turns one Strike into the best face of the previous turn's last throw (only if that face is 4+). Envy adds her best die's face x5 to the stake again (best die 4+, and not on a busting throw). Pride names 150, 200 or 250 before throwing: bank at least that for x2, else the Bank is 0. Gluttony eats one Strike die (it leaves this throw; she keeps her dice) for +45 to the stake. Sloth's Idle makes this throw's first Strike a 4 and the rest 3s.

## 1. Base rules (`Rules.V4`; V2 and V3 stay unchanged so old tests and saves replay)
- Throw all your dice; 4, 5, 6 score 5x face; several scorers in one throw x1.5 / x2 / x2.5 (+x0.5 each); a throw's points round down to a multiple of 5.
- 1 and 2 are Strikes; three Strikes bust: you lose the turn and its stake.
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
- Bot-turn pace: the old targets (2.5 s a bot turn, 4 s on the table) are dropped (REPLY 35): a turn that fast cannot be followed. As built: `Tuning.BOT_PACE` 6.0, on the table a beat before each throw, one on its result, and the seal's beat (`TABLE_BOT_BEFORE_ROLL`, `TABLE_BOT_RESULT`, `POWER_FOR`); measured 4.1 s median (2.8 s First Game). Under review: a pacing floor of held beats (REPLY 35 item 2) and the 10 s measure between your decisions (REPLY 36). No log text, no "thinking".
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

Perks (15): 1 Start every table with 4 dice. 2 Start every table with 100. 3 Your first die each table is free. 4 Every 6 you throw scores 10 more. 5 Three scorers in one throw: +50. 6 Your first throw each turn has one extra die. 7 Your first Strike each table doesn't count. 8 Once a table, a bust keeps its points. 9 +20 whenever a rival busts. 10 Your second ability is ready from the start. 11 Refuse a temptation: +25. 12 Accept a temptation: +25. 13 Bank 200 or more: +25. 14 The first ability aimed at you each table misses. 15 Cleanse: remove every mark of one Sin (once).

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
Strike, Bust, Bank, Temptation, Mark, Claim, Circle. Plain words, not terms: seat, house rule, perk, host (shown as "Wrath's table"). "Greater", "Supply", "Line", "Ladder" never appear on screen (Greater still does: §1).

## 9. Balance as measured (`sim/check_v3.gd -- 4000 v4`, bots only, 2026-11-14)
- 4 seats (fair 25): Wrath 24.0, Greed 25.1, Lust 26.7, Envy 28.5, Pride 28.2, Gluttony 21.4, Sloth 21.1. 7 seats (fair 14.3) is off: Greed 29.4, Lust 9.6, Sloth 8.2; tune with 7b.
- Pace: 5.4 rounds, about 1.6 min with you and 3 bots.
- Temptations: 8.5 offers a game at 4 seats, 41% accepted. Claims 0.14 a game, under the 0.5-1.5 target; left as is until play shows how often a human is claimed (if rare, drop the bot's claim price from 100 to 60).
- Claim cost (relative win drop, target 15-35%): Wrath 18, Greed 19, Lust 19, Envy 18, Pride 25, Gluttony 18, Sloth 30.
- Purgatory: cut (REPLY 1, §10); off, no Sin moves more than 1.5 points.

## 10. Agency and comeback (sim pass 3, 2026-11-15; built as `Rules.V5` in REPLY 3, on the table view only)
Decided: Purgatory cut; universal rethrow dropped; comeback offers, first-game bots, the Master and onboarding approved; jester cut (REPLY 1). Dice price stays 100; the mark rule is adopted; perk 7 and the 7 captions are approved (REPLY 2). Measured with `sim/agency_sim.gd` (sim-only rules in `sim/sim_game.gd`, `sim_sins.gd`, `sim_bots.gd`; V4 with Purgatory off, 4 seats, 20,000 games a pass, skill 4,000 per Sin; "plain" bots press a power at the first chance).
| Measure | V4 now | Proposal: powers + comeback + mark rule | Target |
|---|---|---|---|
| Skill edge, best bot vs 3 plain, mean | 31.8 | 29.1 | 35-45: **missed** |
| Best bot vs 3 novice stand-ins, mean (range) | | 37.3 (20.9 Greed - 50.7 Gluttony) | what a practised player feels |
| Comebacks (last at 500 goes on to win); lead changes | 7.3%; 4.15 | 13.1%; 4.67 | 10-20% |
| Equal bots, lowest to highest Sin | 20.9-28.7 | 19.5-27.7 (Greed lowest); with the Vig at 60, 22.1-27.0 | 22-28 |
| Claims a game (on the last seat / the leader) | 0.14 | 0.25 (0.01 / 0.05); without the mark rule 0.93 (0.20 / 0.07) | |
| Offers accepted, by a seat 150+ behind / by others | | 58% / 48% (3 offers in 4 go to a seat 150+ behind) | |
| Last seat's final score; rounds; minutes (you + 3 bots) | 272; 5.5; 1.6 | 359; 4.8; 1.5 | |
**Powers** (Basic becomes a once-a-turn seal; Greater stays; free reactions, no bonus and no cost). The bots keep their Sin risk tilt (REPLY 3: without it Sloth falls to 21.9). Built numbers (`Rules.V5`), tuned for bots that press at the first chance: every Sin 22.3-28.7 at 4 seats. Use columns are the pass-3 sim; core V5 use rates: `sim/v5_sim.gd`.
| Sin | Power (10 words max) | Numbers | Used on % of turns / at the first chance |
|---|---|---|---|
| Wrath | Rethrow up to two of this throw's Strikes. | Fury now at 300+ (200+ on a grudge); Drag 4 | 62 / 44 |
| Greed | Bank half your stake at x1.25; keep throwing. | The Vig to 60 a die (from 40) | 67 / 81 |
| Lust | Turn a Strike into the last player's best die. | Her seal shows that face | 53 / 47 |
| Envy (new) | Copy your best die: it scores its face again. | Outside the multiplier; any position, so it can't stack with comeback offers. Mimicry copies 3 | 72 / 80 |
| Pride | Name your Bank: reach it for x2, else nothing. | 150, 200 or 250 | 73 / 100 |
| Gluttony | Eat a Strike die: +45 to your stake. | The die is back next turn | 62 / 44 |
| Sloth | Ignore this throw's Strikes; the first becomes a 4. | | 64 / 46 |
- **Real choice? Only Greed's.** Best policy per Sin against pressing at the first chance (skill edge, no bonus / +30 / +50 for banking with the seal unspent / -30 for using it): pressing at once is best, or within a point of it, for Wrath, Lust, Pride, Gluttony and Sloth in every version (Gluttony 41.1 vs 37.4 held). Greed's sum (half now vs all later) beats a fixed rule once there is a bonus (25.4 vs 21.7 at +50). Envy's copy is worth at most 30, so with a bonus of 30 or more it is never worth using. Mean edge, best policy per Sin: 29.3 / 29.1 / 30.0 / 27.7. The reason: a turn is about 2 throws, so a power held past the first Strike rarely gets a later throw to save. **Rec:** no bonus and no cost; the powers stay free reactions. The choices live in banking and offers.
- **Skill edge by decision** (one change to the plain bot, vs 3 plain bots, fair 25): risk that follows the standings +3.0; weighing offers by standings +0.3 (refusing every offer -9.1, accepting every offer -0.6); buying to 4 dice -0.1 (to 3, -0.9); targeting the leader or the seat just above, 0; holding the power for a bad throw -5.1; all the gains together +3.7 (29.1). **Ceiling:** about 29-30 against sound bots, because the plain bot's offer sums are already near best and dice and targets barely matter; the edge is how hard you push your luck for the standings. Against novices it is 37 (Greed 21, Gluttony 51). Ben judges the rest by playing.
**Dice.** Free dice win: against 3-dice bots, 4 dice win 33.8%, 5 dice 39.9%, 6 dice 45.7%, so no structural fix (a Strike cap from dice beyond the third: 5 dice 41.3, 6 dice 50.1). At 100 under the proposal, buying to 5 is best (31.1% vs 28.8% at 3), and buying early beats buying late (31.8% vs 29.8%); at 75 and 60 the edge flattens or the most dice always win. Price 100.
**Comeback.** Behind the leader by D, an offer's gain is x(1 + D/200), up to x3 (`comeback_cap` 3.0): points (round to 5) and extra dice scale; clear, x2 and a free die do not. Costs stay the same. Trailing by 150+ brings an offer every turn. **Mark rule:** a mark taken while 150+ behind doesn't count toward a claim; it still counts for the ladder's endings. **First-game bots** (game one only): bank at 200, risk 1.55, buy to 4; a novice stand-in wins about 40%.
**The Master of the Dance.** A Danse Macabre skeleton, ink on the page, the table's host. Neutral: he wins whoever loses. He deals and narrates, snuffs my Strike candles, announces a Sin as part of its offer's entrance (no extra beat), reacts to busts, big Banks and wins, and goads at my decision in words only. Offers and terms stay with the Sins. Courtly, dry, amused; never cruel to a new player. At most one line a turn, on about a third of events (`MASTER_CHANCE` 0.33), never in a Sin's beat. Numbers come from `vals()`; a line that states a fact plays only when it is true [condition].
| Event | Lines (6 words max) |
|---|---|
| Game start | Take your seats. The dance begins. / Dice ready. Souls ready. Shall we? / Seven Sins, one table. Delightful. / Mind your candles. Let us begin. / You throw first. Do begin. [I throw first] |
| My bust | Ah. The dice have spoken. / {strikes} candles out. Do sit. / A misstep. Everyone stumbles. / Gone. Shall we try again? / Pity. It was going beautifully. [stake 100+] |
| My big Bank | Splendid. Do bank like that again. / Well kept. The Sins noticed. / A fine harvest, if I may. / Bravo. My compliments to your nerve. / Into your keeping. Nicely done. |
| Rival's bust | Oh dear. Not you this time. / {name} trips. How very human. / Snuffed. Do take note. / The dance claims {name}. Briefly. / Careful steps win. Usually. |
| A Sin's offer enters | {name} has a little proposal. / A word from {name}, please. / Ah, {name} wishes to bargain. / Listen closely. {name} is generous. / {name} approaches. Mind your purse. |
| Mark taken | Marked. {name} will remember. / A small price. For now. / Signed in ink. How brave. / {name} smiles. That's rarely good. / One mark. {claim_marks} and it claims. [first mark of that Sin] |
| Claim | {claim_marks} marks. {name} owns you now. / Claimed. I did mention it. / {name} will keep you close. / Bound. The dance goes on. / Well. A lasting arrangement, then. |
| My win | The dance is yours. Well played. / {win}. I'm genuinely impressed. / Victory. The Sins will sulk. / Bow, please. You've earned it. / Splendid. Do come again. |
| My loss | Not tonight. There's always another. / The dice were unkind. Again? / A good dance, all the same. / Rest. The table will wait. / Close. Closer than they'd admit. [within {close} (100) of the winner] |
| The round's mark (always) | You lead. No chain this round. / Ahead? Then no chain this round. / First place. No chain this round. / Marked. No chain this round. / Leader's toll: no chain this round. Rival: {name} leads. No chain this round. / {name} leads. Chain off this round. / I mark {name}. No chain. / Marked: {name}. No chain this round. / {name} pays: no chain this round. |
| Idle at my decision | Throw, or keep? Your call. / Candles are patient. I am less. / Courage or caution, dear guest? / Another throw? Purely a suggestion. / Take your time. Eternity's long. |
- Ladder: he opens each Circle ("Wrath's table"). Endings: The Saint, he bows and lets you leave the dance; The Eighth Sin, he gives you his place as host; Claimed, he leads you to the Sin's window and seats you in it. Art (nothing painted), flat ink like `assets/art/runtime/marginalia/skeleton.png`: idle on a candle-snuffer; snuffing; a bow; pointing at the dice; applause; a shrug; writing in a ledger; a hand on my shoulder towards a window; leading the dance, full figure.
**Decided (REPLY 15), built in `Rules.V5`:** the chain multiplier caps at x2 (`chain_cap`); a bust keeps half the turn's face points, to 5, never the chain (`soften` "half"); Greed's Cash Out at x1.25; the Master's mark: as each round starts he marks the strict leader (score above 0), who scores no chain that round (`mark` "chain"). He calls the end at 600 (`Rules.MASTER_CALL`).
**Decided (REPLY 16), built:** the call moves to 550 (at 500, 29% of games end in 4 rounds or fewer; at 550, 20%); Devour adds 45 (from 60).
**Decided (REPLY 17), built:** Idle-one: Idle's first Strike becomes a 4, the rest 3s (`idle_one`); Hubris at x2 (from x1.75); Cash Out stays x1.25. Sim with both, call 550: every Sin 19.8-27.9.
**Decided (REPLY 18), built:** the Master calls no earlier than round 3's end (`Rules.MASTER_CALL_FLOOR`), so round 5 is the earliest last round. Sim at 550: every Sin 20.4-27.8; no game of 4 rounds or fewer (was 24%); 9.5% go past 6 rounds; the last seat wins 5.9%.
**Built (REPLY 3):** `core/rules.gd` `V5`, `sins/` powers, `ai/bot_policy.gd` `wants_power` and `first_game`; tests `tests/v5_check.gd`.
