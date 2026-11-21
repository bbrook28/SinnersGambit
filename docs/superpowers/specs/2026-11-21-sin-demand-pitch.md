# Sinners' Gambit: the Sin's demand (pitch, revised)

Date: 2026-11-21, revised the same day after the review of 0.12.0. Status: **draft for Ben's approval.** Adds to the dice poker pitch (`2026-11-20-dice-poker-pitch.md`); the hand's rules do not change. Numbers: `sim/demand_probe/demand5.py` (exact).

## The pitch
Each hand, one Sin hosts, and the Sin pays marks for something the poker hand punishes. To be paid you must spoil your hand a little; the question each keep asks is whether the Sin's marks are worth it. Bust and the Sin pays nothing.

## Why
- **The review session, after three hands of 0.11.1:** "the hand never asks a new question"; a third of keeps were coin flips; the Last Dance was the one moment that mattered.
- **The review of 0.12.0:** the first demands (Pride: each 6 pays 2, each 5 pays 1; Envy: each 6 pays 1, each 2 costs 1) turned coin flips into obvious keeps. A player who ignores the Sin except to break ties earns within 2% to 5% of best play, and Pride paid more than the poker.

## The one rule
**The Sin pays for what the hand punishes.** Its window says what. Paid with your hand; lost on a bust.

## Two shapes to prototype
| Shape | The demand | What it pulls against |
|---|---|---|
| **A lone 6** | A 6 that stands alone in your row pays 4. A second 6 and it pays nothing. | Pairing your 6 |
| **Held once** | Each face you hold exactly once pays 1. | Every pair and set |

Prices are the highest at which the Sin still pays less than the poker: a lone 6 at 5, or held once at 1.5, pays more than the hand.

## What the probe says (best play, exact)
| | Marks: hand / Sin | Busts | Best over greedy+ | Best over poker+ | Hands where the Sin changes a keep |
|---|---|---|---|---|---|
| No Sin | 3.58 / 0 | 20.0% | 11% | 0% | 0% |
| 0.12.0 Pride | 3.22 / 3.83 | 23.4% | 2% | 5% | 8% |
| 0.12.0 Envy | 3.30 / 1.11 | 27.1% | 4% | 7% | 4% |
| A lone 6 pays 4 | 2.98 / 2.46 | 17.0% | 21% | 9% | 26% |
| Held once pays 1 | 2.88 / 2.29 | 15.6% | 16% | 7% | 40% |
| A lone 6 pays 4, each 2 costs 1 | 2.98 / 1.94 | 22.1% | 17% | 11% | 23% |

Greedy+ keeps what scores best in poker now; poker+ plays the no-Sin game exactly right; both break ties toward the Sin. "Changes a keep" means poker+ would keep a different die and lose a quarter mark or more by it.

## What argues against this
- **The Sin is silent in most hands.** A lone 6 changes a keep in 26% of hands; held once in 40%. No shape the probe tried passes one changed keep in two hands. A hand has only about two keeps with a real choice, so a payout rule has little to act on.
- **These shapes reward safe draws.** Best play throws fewer dice (1.98 and 1.82 a throw, against 2.16 with no Sin); with no skulls showing, held once draws a single die 58% of the time, because any new face is welcome. That is why busts fall, and it also leaves fewer keeps with a choice (2.16 and 1.78 a hand, against 2.33).
- **The gap over greedy+ flatters.** Greedy+ is already 11% behind with no Sin. Poker+ is the honest measure, and there the gain is 7% to 9%.
- **A gap over poker+ can come from the draw alone.** 0.12.0's Envy shows 7% while changing a keep in 4% of hands. So the marks gap cannot be the only pass mark.

## Pass marks
1. Best play beats greedy+ by more than 11%.
2. Best play beats poker+ by 7% or more, **and** the Sin changes a keep in at least a quarter of hands. The second half is there because of Envy above; a quarter is what the better shapes reach, not a comfortable target.
3. The Sin pays less than the poker hand.
4. Busts between 20% and 30%.
5. **Ben plays three hands of each** and can name a keep he would have made differently without the Sin.

Neither shape meets mark 4 as it stands. For the lone 6, adding "each 2 costs 1" brings busts to 22.1% and passes marks 1 to 4, at the cost of a two-part rule. For held once, no price or added cost in the probe gets above 18%; it rewards safe draws by nature, and I would rather prototype it at 15.6% and let Ben judge than bend it.

## Open risks
- **A face is only paint.** This gives two shapes; seven Sins need seven.
- **Wrath speaks only at two skulls,** about a third of hands, and is unchanged by this revision.
- **Marks still have no purpose.** A separate gap; this pitch does not close it.
- **If one changed keep in three hands is too quiet,** the fix is probably not a better demand but more keeps in a hand, or a demand on the draw.

## On screen, and in the same build (after approval)
The demand on the opening and in the hand, each thrown die showing what it would pay; plus the review's fixes: the hint names a live straight, the wild die shows the face it was paid as, a hand the Sin takes to zero gets its own plate, and then the demand line's size and digits, the ribbon's sign, the seal badges and the die tags.
