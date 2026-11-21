# Sinners' Gambit: the Sin's demand (pitch, second revision)

Date: 2026-11-21, revised twice the same day after the review of 0.12.0. Status: **draft for Ben's approval.** Adds to the dice poker pitch (`2026-11-20-dice-poker-pitch.md`); the hand's rules do not change. Numbers: `sim/demand_probe/demand5.py` (exact). The hand itself has its own pitch: `2026-11-21-the-refusal-pitch.md`.

## The pitch
Each hand a Sin hosts, and the Sin pays marks for something the poker hand punishes. To be paid you must spoil your hand a little; the keep asks whether the Sin's marks are worth it. Bust and the Sin pays nothing.

## Why
- **The review session, after three hands of 0.11.1:** "the hand never asks a new question"; a third of keeps were coin flips; the Last Dance was the one moment that mattered.
- **The review of 0.12.0:** the first demands (each 6 pays 2, each 5 pays 1; each 6 pays 1, each 2 costs 1) turned coin flips into obvious keeps. A player who ignores the Sin except to break ties earned within 2% to 5% of best play, and Pride paid more than the poker.

## The one rule
**The Sin pays for what the hand punishes.** Its window says what. Paid with your hand; lost on a bust.

## One shape to prototype
**Pride: a 6 that stands alone pays 4. Each 2 costs 1.**
Take one 6 and never pair it; and a 2 now hurts, so a throw of low dice is a real problem. One Sin, one build, then Ben plays.

## What the probe says (best play, exact)
| | Questions asked a hand | The hand wins / the Sin wins | Choice keeps a hand | Marks: hand / Sin |
|---|---|---|---|---|
| No Sin | 0 | | 2.33 | 3.58 / 0 |
| 0.12.0 Pride | 0.26 | 67% / 33% | 2.80 | 3.22 / 3.83 |
| 0.12.0 Envy | 0.23 | 81% / 19% | 2.94 | 3.30 / 1.11 |
| **A lone 6 pays 4, each 2 costs 1** | **0.43** | **40% / 60%** | **2.73** | **2.98 / 1.94** |
| A lone 6 pays 4 | 0.39 | 27% / 73% | 2.16 | 2.98 / 2.46 |
| Each face held once pays 1 | 0.69 | 37% / 63% | 1.78 | 2.88 / 2.29 |
| No 6 in a full row pays 3 | 0.02 | 9% / 91% | 2.73 | 3.47 / 1.71 |

A **question** is a keep where no thrown die is best for both the poker alone and the Sin alone. A **choice keep** is a throw with dice of two or more faces to choose from.

**0.43 questions a hand is under one every two hands.** That is the most this shape gives, and no payout shape the probe tried gives more than 0.7. The ceiling is the hand, which has about two choice keeps for a Sin to act on.

## Pass marks, in order
1. **Questions asked:** 0.4 a hand or more, and neither side wins more than 70% of them (a question one side always wins is not a question).
2. **Choice keeps a hand do not fall** below today's 2.33. This replaces the bust band for Sins: the cost of a safe shape is fewer decisions, and "held once" fails here at 1.78 because best play draws a single die 58% of the time with no skulls.
3. **The Sin pays less than the poker hand.**
4. **Ben plays three hands** and can name a keep he would have made differently without the Sin.

**Supporting numbers only:** best play beats greedy+ by 17% and poker+ by 11%; busts 22.1%. These gaps are not marks, because they can be high with no question asked: "no 6 in a full row" has the best gaps of anything tried (37% and 20%) and asks 0.02 questions a hand. Best play there is simply "never keep a 6", and the gap only measures players who keep 6s blindly.

## Open risks
- **Under one question every two hands** may still be too quiet. The refusal pitch is the answer if so.
- **A face is only paint.** This is one shape; seven Sins need seven.
- **A two-part rule** is more to read than "each 6 pays 2".
- **Wrath speaks only at two skulls,** about a third of hands; it sits out of this prototype.
- **Marks still have no purpose.** A separate gap; this pitch does not close it.

## On screen, in the same build (after approval)
The demand on the opening and through the hand; each thrown die shows what keeping it would do to the Sin's pay (a 6 reads +4 with none held, −4 with one held). With it, the review's fixes: the hint names a live straight, the wild die shows the face it was paid as, a hand the Sin takes to zero gets its own plate; then the demand line's size and digits, the ribbon's sign, the die tags.
