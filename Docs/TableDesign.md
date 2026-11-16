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
