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

## Steps
1. Base rules + sim, no Sins (done, pending first run).
2. Sins in core + sim win rates per Sin.
3. Try the rule changes in the sim, compare.
4. Playable UI: solo vs bots, then pass-and-play.
5. Android export, then iOS.

## Sim run 1 (base rules, no Sins, 20k games each, Godot 4.7.2)
- Buying dice barely matters: solo, 3 dice = 14.3 turns to 1000, best (4 dice) = 13.2. 4 and 5 tie at a table (30% vs 31%). 7+ dice lose.
- Strong first-player advantage. With 7 players, seat 1 wins 21.5% and seat 7 wins 8.9% (fair is 14.3%). 4 players: 29.9% vs 20.2%. Cause: game ends the moment someone hits 1000.
  - Fix to test: finish the round so everyone gets equal turns, highest score wins.
- Indulgence vs Redemption: 52/48, close to irrelevant.
- Game length: ~10 rounds (~41 turns at 4p, ~70 at 7p).

## Rulebook gaps found
- Indulgence with under 50 points: not covered. Sim falls back to Redemption.
- Can score go negative? Not covered.
