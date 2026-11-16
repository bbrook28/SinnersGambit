# Phase 0: simplified rules (approved and built 2026-11-13; see Docs/Handoff.md)

Numbers are today's values from `core/rules.gd` and `sins/*.gd`. In the build they come from the config, so Phase 8 changes flow through. Scoring is already 5x face (`V2.face_mult`); multiplier today is +x0.5 per extra scorer, uncapped (x1.5 for two, x2 for three, x2.5 for four).

## First game in five sentences
1. On your turn, throw all your dice as often as you like, then Bank to keep this turn's points.
2. 4, 5 and 6 score five times their face; 3 does nothing; 1 and 2 are Strikes.
3. Scoring several dice in one throw is worth more.
4. Bust: your third Strike in a turn loses this turn's points and starts your next turn in Purgatory.
5. After you bank you may buy dice for 100 each, and the first to 1000 wins.

Your Sin's Basic ability is taught on Sin select and in the tutorial, not in the five.

## Other rule lines (rulebook, glossary)
- **Purgatory:** Your turn starts with a free throw of all your dice: any 6 frees you, otherwise you pay 50 (nothing if you can't). Then play your turn as normal.
- **Greater ability:** Unlocks for good the first time you reach 300; usable once a round.
- **First Game:** 4 players, Basic abilities only, slower bots. Finishing a game unlocks Greater abilities and Table of 7.
- **Round:** Everyone takes one turn.

## Abilities (15 words max)
| Sin | Basic | Greater |
|---|---|---|
| Wrath | **Spark of Rage:** Gain 40 whenever another player busts. | **Fury:** Once a round, make an opponent reroll their three best dice right after they throw. |
| Greed | **The Vig:** When an opponent buys a die, 17 of its price goes to you. | **Interest:** Bank and buy nothing to gain 8% of your score, up to 60. |
| Gluttony | **Feast:** Once a turn, sacrifice a thrown die for 50; a sacrificed Strike doesn't count. | **Gorge:** Your first die each turn costs 70 instead of 100. |
| Lust | **Whisper of Desire:** Once a turn, turn a 3 or 2 into the previous player's best die. | **Binding Pact:** Pick an opponent; you take 15% of the next turn they bank. |
| Envy | **Green-Eyed Glance:** Once a turn, add a copy of the previous player's best die to this throw. | **Mimicry:** Once a round, add two copies of the previous player's best die to this throw. |
| Pride | **Hubris:** Before throwing, bet 100, 150 or 200: bank at least that for x1.5, else 0. | **Untouchable:** Once a round, the first ability used against you hits its user instead. |
| Sloth | **Lazy Bones:** Your first Strike each turn doesn't count. | **Drag:** Pick an opponent; next turn they throw 3 fewer dice (never under 1). |

Hidden details (shown by the UI, not in the sentence): Feast and Gorge keep you at 2 dice minimum; Glance and Whisper only fire when that die scores; Glance's die is for this throw only.

## Need redesign (can't be honest in one plain sentence)
1. **Envy's Mimicry.** The sentence is short but misleading: copying Wrath's Spark of Rage or Greed's Vig does nothing, since they only fire on other players' turns. Proposal: **"Once a round, add two copies of the previous player's best die to this throw."** (A stronger Glance, no borrowing.) Fallback: keep Mimicry, and when the previous player is Wrath or Greed it copies the next Sin back.
2. **Pride's Hubris.** Needs two hidden rules (the 50 floor, "previous player's banked turn" which is 0 after a bust) and an odd x1.6. Proposal: **"Before throwing, name a target of 100 or more; bank at least that for x1.5, or 0."** Or drop the floor and use x1.5.
3. **Gluttony's Feast + Gorge.** Each writes fine, but together they're the buy-70 / feed-90 profit loop. Proposal (Phase 8): Feast gives 50, or a fed die can't be rebought the same turn.

## Numbers that break "multiples of 5 / clean" (Phase 8)
The Vig 17 (-> 15 or 20), Interest 8% (-> 10%, max 50), Hubris x1.6 (-> x1.5), Binding Pact 15% (rounded to 5s), seat handicap 20 (-> 10).

## Code changes once approved
- Rules: new `Rules.V3` (all values in one dict): no dice choice (always all dice, press on), auto Purgatory (free throw, 6 frees, else pay 50 or 0, then play on), Greater unlock already permanent. `first_game` option: 4 seats, no Greater, bots at half pace (UI).
- `ai/`: drop `wants_indulgence` and dice-count logic under V3.
- Sin prompts use the sentences above. Terms Indulgence and Redemption removed everywhere.
- Sim run comparing V2 and V3 win rates per Sin and game length.
