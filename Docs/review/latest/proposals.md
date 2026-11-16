# Proposals and sim: REPLY 6 items 4-5, REPLY 7, REPLY 9 c
All sim only (`sim/profile_sim.gd`), V5 rules, 4 seats, seed 1. Mixed = 20000 games with a random profile and Sin per seat. Odd = 4000 games per profile, one against 3 Plain. Per-game seed = 1000003 + game; replay with `profile_sim.gd -- replay <seed> mixed`. Raw output: `build/agency/p6/`.

## Profiles (REPLY 7)
Plain, Novice, Banker (rarely buys), Gambler (tilts after a bust), Chaser (risks more when 150+ behind), Sitter (cautious when ahead), Forgetter (uses the seal 30-60% of the time, takes few offers), Offer-taker, Grudge. Each draws its numbers from a range per game and has a 1-5% whim per decision.

## Rule 4: borrowed seal (proposal)
From round 2, if your second slot is empty, the Master offers you a random rival Sin's power. It costs 1 mark of that Sin and gives 3 uses, then the slot empties.
| | base | borrowed |
|---|---|---|
| rounds (aim 5) | 4.53 | 3.67 |
| final margin / 400+ | 407 / 45% | 489 / 56% |
| Sin range | 21.2-31.5 | 19.9-34.9 (Envy top) |
| Forgetter mixed / odd | 13.3 / 11.4 | 9.3 / 7.0 |
| Novice mixed / odd | 20.9 / 18.4 | 17.7 / 15.2 |
- Offers 4.7 a game, 82% taken. The winner's borrowed gain is at least the winning margin in 9.9% of games.
- Dominant pairs: Envy+Sloth(b) 41.3 (seed 1000134), Envy+Wrath(b) 39.7 (1000028). Borrowed Envy is weakest: 15.4% for its holder.
- The variants (keep until claimed, free with 3 uses) are within 1 point of each other. "Once a round" is not measured: the sim option has a bug and gave the same numbers as once a turn.

## Rule 5: the Master's penultimate round (proposal)
When the leader reaches N at a round's end, the Master calls it. The next round is the penultimate round, then the final round. No win score.
| | base (1000) | call 500 | call 600 | call 700 | target 1250 | target 1500 |
|---|---|---|---|---|---|---|
| rounds | 4.53 | 4.66 | 5.03 | 5.40 | 5.41 | 6.62 |
| over 6 rounds | 5.9% | 2.5% | 6.4% | 13.2% | 20.3% | 50.7% |
| final margin | 407 | 335 | 351 | 367 | 443 | 433 |
| last at half wins | 13.0% | 18.3% | 17.9% | 17.8% | 12.7% | 12.7% |
| last seat within 250, entering last round | 9.0% | 4.1% | 3.5% | 3.0% | 5.4% | 4.7% |
| last seat wins | 6.8% | 4.5% | 3.9% | 3.6% | 5.3% | 4.3% |
| Sin range | 21.2-31.5 | 19.3-32.9 | 19.4-33.6 | 19.2-35.6 | 20.9-37.0 | 14.0-29.4 |
- Call 600 hits 5 rounds and gives more comebacks than raising the target. The cost is that the last seat goes into the final round further behind (762 vs 559) and wins it less.
- Greed climbs under the call (31.9 at 600; Greed+banker 42.1, seed 1000041).
- Profiles at call 600 (odd): Novice 19.4, Banker 22.4, Forgetter 11.6. All are a little better than base.

## REPLY 9 c: buy only from this turn's banked points
- Buys fall from 1.65 to 1.49 dice a seat a game; someone buys in 99.9% of games.
- Rounds stay at 4.54. The margin falls from 407 to 394. Greed falls from 25.1 to 24.8, and Envy stays at 32.0.
- Banker: 20.8 → 21.8 mixed, 18.8 → 18.2 odd. The rule barely moves anything.

## Far behind: are the offers too weak?
- With all offers off, the last at half wins 9.0% of games (13.0% with them). The last seat wins 2.8% of last rounds (6.8% with them).
- With only the comeback offers off, the last at half wins 9.7%.
- The offers already account for most comebacks. They are not too weak.

## Found, not designed
- **Forgetter:** a rule that is fair for Plain but punishing for Forgetter. Forgetter is the worst profile everywhere (11-14%), and borrowing makes it worse.
- **Banker:** a long target punishes Banker (15.9% at 1500).
- **Envy:** too strong with Banker: 39.8% (seed 1000011).
- **Sloth:** weak with Forgetter (5.9%) and Banker (6.7%).
- **Runaways:** a margin of 2120 (seed 1018960) in base, and 2740 (1003691) with borrowing.
- **Long games:** the longest run 10 rounds in base (seeds 1000263, 1002383).
- **Stalls and locks:** no stalls, loops or locks, and no seat's dice reach 0.
