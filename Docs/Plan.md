# Plan (agreed 2026-11-13)

## Dice math (strike = 1/3 per die; bust at 3+ strikes; ignores Purgatory cost)
| Dice | Bust | EV/turn |
|---|---|---|
| 3 | 3.7% | 75 |
| 4 | 11% | 96 |
| 5 | 21% | 111 |
| 6 | 32% | 119 |
| 7 | 43% | 119 |
| 8 | 53% | 114 |

A die costs 100: 3→4 pays back in ~5 turns, 4→5 in ~7, 5→6 in ~12. "Buy to 5, stop" is close to solved.

## Balance/fun recommendations (not yet applied; sim first)
1. Push-your-luck in the roll: set scoring dice aside, then bank or reroll the rest. Strikes stay locked.
2. Ability timing: split abilities into "roll window" and "Gambit" types. Several Tier 1s act on the roll but are used after scoring.
3. Hot spots:
   - Gluttony Feast (150 pts for a 100-pt die = arbitrage)
   - Envy Covet All (copies the leader's score)
   - Sloth Time Distortion (−33%)
   - Tier 3 "Once Per Game" vs "Cooldown 2"/"once per cycle"
4. Measure each Sin's win rate with the headless sim before tuning by hand.

## Phases (agreed 2026-11-13: rebalance everything, abilities included, and add content)
1. **Base loop.** Press, choose how many dice each roll, instant win + head start for later seats, dice supply scales with player count, Indulgence cost scales with score.
2. **Rebuild the Sins on the new loop.**
   - Fixed structure: T1 free identity passive · T2 active (300) · T3 ultimate (666), once per game, no cooldowns.
   - Every ability tagged Before roll / After roll / Gambit.
   - Target: each Sin wins 12–16% of 7-player sim games, then Ben plays for feel.
   - Draft kits:
     - Wrath: profit when anyone busts · force a reroll · target's Strikes count double next turn
     - Greed: Vig · interest on unspent points · dice cost 150 for others for a round
     - Lust: swap a die with the previous roll · binding pact (shared cut) · one-turn Command
     - Envy: borrow a die face · copy last ability · steal part of the gap to the leader
     - Pride: call a target before rolling (×1.5 or 0) · first attack each round bounces · ignore one bust
     - Gluttony: feed a die mid-turn for 100 · cheaper dice · eat a die from every opponent for a round
     - Sloth: bonus for banking without pressing · target rolls one fewer die · undo your own bust
3. **Additions.** Blessed/cursed dice first. Later: Circles of Hell round modifiers, Devil's Bargain in Purgatory, solo campaign up the nine Circles (after UI).
4. Playable UI: solo vs bots, then pass-and-play (phone + iPad).
5. Android export, then iOS.

## Art direction (agreed with Ben 2026-11-13)
Gothic illuminated manuscript meets stained glass, in pixel art. Candlelit blacks and deep reds, gold-leaf numbers, a stained-glass panel per Sin, bone dice.
- Borrow Balatro's principles: big readable numbers, juicy score tick-ups, screen shake, every roll animated and loud.
- Don't copy its look: no felt table, swirling CRT background or joker cards.

## Sim run 1 (base rules, no Sins, 20k games each, Godot 4.7.2)
- Buying dice barely matters: solo, 3 dice = 14.3 turns to 1000, best (4 dice) = 13.2. 4 and 5 tie at a table (30% vs 31%). 7+ dice lose.
- Strong first-player advantage. With 7 players, seat 1 wins 21.5% and seat 7 wins 8.9% (fair is 14.3%). 4 players: 29.9% vs 20.2%. Cause: game ends the moment someone hits 1000.
  - Fix to test: finish the round so everyone gets equal turns, highest score wins.
- Indulgence vs Redemption: 52/48, close to irrelevant.
- Game length: ~10 rounds (~41 turns at 4p, ~70 at 7p).

## Sim run 2 (10k games each)
- Finish the round (no press): 4p seats now 24–26%, fixed. 7p still 16.5% → 11.7%. Cause: 27 dice run out at 7 players, so early seats get them first.
- Press (roll again; points and Strikes add up over the turn):
  - It's a real decision: at 4p, a bot that never presses wins 15%; pressing styles win 26–31%.
  - Games get shorter: ~8 rounds instead of ~10.
  - New problem: buying dice becomes a trap. At a 5-bot table, buy-to-3 wins 43% and buy-to-7 wins 5.5%. More dice = more Strikes per press.
  - New problem: with finish the round, the last seat chases a known target. 7p goes from 8% (seat 1) to 22% (seat 7).
- Indulgence vs Redemption still 52/48: the choice doesn't matter.

## Sim runs 3–4 (dice choice: each roll, choose how many dice to throw)
- Plain dice choice is broken: the best play is rolling 2–3 dice at a time. With 3 Strikes left, 2 dice can't bust you. Buying is still a trap: at 6 players, buy-to-3 wins 34% and buy-to-8 wins 6%.
- Skill matters a lot: at 4p, best style 43%, throw-everything 22%, one roll and bank 7.5%.
- Head start that zeroes seat bias: 4p ≈ +40 per seat, 7p ≈ +20 per seat (re-check after scoring changes).
- Indulgence at 10/20/30% of score: pay vs redeem still within a few points. The choice doesn't matter at any price → replace it (Devil's Bargain, Phase 3) instead of tuning.
- **Combo multiplier fixes buying.** Each extra scoring die in one roll adds ×chain to that roll's points.
  - chain 0.5: every buy target from 3 to 8 wins 16–18% at 6 players. Best play becomes "throw everything first, then roll 2".
  - chain 1.0: same, slight edge to 6 dice.
  - Side effect: with the target still 1000, games drop to ~3 rounds (chain 0.5) or ~2 (chain 1.0). Target or face values must scale.

## Sim run 5: rescale, keeping 1000 / 666 (Ben's call)
Chain 0.5, six value/cost setups. Winner: **die values 20/25/30, die cost 100**.
- Buying: every buy target 3–8 wins 15–18% at 6 players. A real choice.
- Length: ~8 rounds at 4p, ~7 at 7p.
- Head start +20 per seat: worst seat within 1 point of fair at both 4p and 7p.
- Cheap dice (cost cut with values) made buy-to-8 dominant; 12/15/18 games ran 11–15 rounds.

## Phase 1 rules (locked 2026-11-13, `Rules.V2` in code)
- **Roll:** each throw, choose how many of your dice to throw. Strikes add up over the turn; 3 = Purgatory, turn points lost. Bank any time.
- **Score:** 4/5/6 = 20/25/30. Combo: each extra scoring die in the same throw adds ×0.5 (3 scorers = ×2, 5 = ×3).
- **Dice:** cost 100. Supply = 8 per player (min 27).
- **Win:** first to 1000 wins instantly. Seat N starts with 20 × (N−1) points.
- **Tiers:** 300 / 666 unchanged.
- **Purgatory escape:** unchanged for now; to be replaced by the Devil's Bargain in Phase 3.

## Phase 2, step 1: Tier 1 abilities (tuned 2026-11-13, `sim/run_sins.gd`)
7 players, one of each Sin, seats shuffled, 10k games. Fair = 14.3%, target 12–16%.

| Sin | Tier 1 (final) | Win % | History |
|---|---|---|---|
| Wrath | Spark of Rage: +40 whenever another player busts | 13.5 | 30 → 10%, 50 → 21%, 35 → 12% |
| Greed | The Vig: 17 of each die an opponent buys goes to Greed | 14.3 | 20 → 18%, 15 → 12% |
| Lust | Whisper of Desire: once a turn, swap a 3 (or a 2 if no 3) for the best face in the previous player's last throw. A swapped 2 cancels its Strike | 15.1 | any die → 33%, 3s only → 9%, 2 first → 20% |
| Envy | Green-Eyed Glance: once a turn, add a copy of the previous player's best face to a throw. Counts toward the combo | 14.9 | unchanged |
| Pride | Hubris: before rolling, call "beat the last player's turn" (floor 50). Beat it ×1.6, miss = 0 | 14.2 | ×1.5 → 12%, ×1.75 → 17% |
| Gluttony | Feast: once a turn, feed a die from your throw to the Supply for +90. Feeding a Strike die cancels it | 13.0 | +100 → 18%, +75 → 9% |
| Sloth | Lazy Bones: your first Strike each turn doesn't count | 15.1 | replaced Slow Drip (bank after one throw, +30/+50) → 5% |

- Every Sin beats plain bots 1-vs-3 (34–55%). Wrath and Greed are weakest alone because they feed off the table.
- Games with Sins run ~5 rounds at 7p (vs ~7 without). Revisit length after Tiers 2–3.
- Sim limit: bots don't change how they press for their Sin (except Pride's call). A human Sloth or Wrath may play differently.

## Rulebook gaps found
- Indulgence with under 50 points: not covered. Sim falls back to Redemption.
- Can score go negative? Not covered.
