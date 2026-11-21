# Sinners' Gambit: the refusal (pitch on the hand itself)

Date: 2026-11-21. Status: **draft, not approved (Ben, 2026-11-21); no game code.** Changes the hand in the dice poker pitch (`2026-11-20-dice-poker-pitch.md`). Numbers: `sim/demand_probe/demand7.py` and `demand8.py` (exact best play).

## The pitch
You may refuse a throw. Keep one die as now, or keep none: the dice go back, but the Master takes one die from the bag for good. Every throw now asks "is this good enough?", and the bag is the clock.

## Why
The demand probe found the ceiling is the hand, not the Sin. A hand has about 2.3 keeps with a real choice, 44% of those are coin flips, and a lone die is kept for you with nothing to decide. No payout rule gets a Sin past 0.7 questions a hand.

## The rule
1. After a throw, **keep one die or refuse them all.** A lone die can be refused too.
2. **Refused dice go back; one die leaves the bag for good.** Skulls stay out as always.
3. The bag starts at **8** (today 7), so a refusal or two still leaves a full row in reach.
4. Everything else stands: draw 1 to 3, three skulls bust, the Last Dance, a full row or an empty bag ends the hand.

## What the probe says
| The hand | Choices a hand | Coin flips | Refusals a hand | Busts | Last Dance | Throws |
|---|---|---|---|---|---|---|
| Today | 2.33 | 44% | | 20.0% | 37% | 4.6 |
| Draw 2 or 3 (no single die) | 2.99 | 54% | | 26.6% | 34% | 4.4 |
| Draw 2 or 3, four skulls bust, bag 8 | 3.50 | 51% | | 11.9% | 19% | 4.7 |
| Always draw 3 | 3.22 | 58% | | 35.3% | 33% | 4.1 |
| You may refuse, bag 7 | 4.45 | 16% | 0.69 | 22.9% | 76% | 4.9 |
| **You may refuse, bag 8** | **5.12** | **11%** | **1.25** | **25.1%** | **65%** | **5.6** |
| You may refuse, bag 9 | 5.85 | 6% | 2.05 | 29.0% | 61% | 6.5 |

A **choice** is a throw with two or more different things to do (dice of different faces, or refusing).

With the Sin from the demand pitch (a lone 6 pays 4, each 2 costs 1):

| The hand | Questions asked a hand | The hand wins / the Sin wins | Marks: hand / Sin |
|---|---|---|---|
| Today | 0.43 | 38% / 62% | 2.95 / 1.97 |
| Draw 2 or 3 | 0.48 | 35% / 65% | 2.85 / 1.95 |
| You may refuse, bag 7 | 1.28 | 66% / 34% | 3.57 / 2.28 |
| **You may refuse, bag 8** | **1.65** | **53% / 47%** | **3.84 / 2.26** |
| You may refuse, bag 9 | 2.31 | 51% / 49% | 3.97 / 2.23 |

A Sin that acts on the draw instead (today's hand, the Sin paying at the keep):

| The Sin | Questions asked a hand | The hand wins | Choice keeps | Marks: hand / Sin |
|---|---|---|---|---|
| Keep the lowest die thrown: pays 1 | 0.36 | 85% | 2.97 | 3.31 / 2.26 |
| Keep a new face over a match: pays 1 | 1.00 | 76% | 2.33 | 3.25 / 0.51 |
| Each match you send back: pays 1 | 0.87 | 21% | 2.31 | 2.61 / 1.89 |

## Is refusing a skill, or a rule of thumb? (`demand8.py`, bag 8)
Each player draws and keeps as best play does, and only decides the refusal by its rule; all are scored in the refusal game.

| Player | Marks | Best play is ahead by | Refusals a hand | Busts |
|---|---|---|---|---|
| Best play | 4.59 | | 1.12 | 25.1% |
| Never refuses | 2.91 | 58% | 0 | 13.1% |
| Today's best play, never refuses | 3.10 | 48% | 0 | 21.1% |
| Refuses when no die improves the hand | 3.69 | 24% | 2.91 | 29.1% |
| Refuses when no die matches the row | 3.69 | 24% | 2.91 | 29.1% |
| Refuses when no die matches, once the row holds two | 4.24 | 8% | 1.63 | 25.2% |

With the lone 6 hosting, best play (6.10 marks, 1.37 refusals) is 35% ahead of the best of these rules and 41% ahead of never refusing.

- **Without a Sin, one rule of thumb gets within 8%:** "fill two places, then refuse anything that does not match". That is closer than greedy gets today (11%), so the refusal alone is mostly a habit to learn, not a question to weigh.
- **With a Sin it is a real decision:** the same rule falls 35% behind, because the Sin's die and the matching die are different dice.
- **It is not optional.** Never refusing costs half the marks, so this is a second core rule, not a spare button.
- "No die improves the hand" and "no die matches the row" are the same rule in practice, and refuse far too much (2.91 a hand).

## The Last Dance under the refusal
| The hand | Hands that reach the Dance | Of those, after a refusal | Busts | Busts that are Dance losses |
|---|---|---|---|---|
| Today (bag 7) | 37% | none | 20.0% | 31% |
| You may refuse, bag 7 | 76% | 53% | 22.9% | 55% |
| No refusal, bag 8 | 0% | | 21.1% | 0% |
| **You may refuse, bag 8** | **65%** | **100%** | **25.1%** | **43%** |

With a bag of 8 the Dance can only come from refusing: every Dance is one the player chose to risk. But 43% of busts are then the Dance's one-in-six skull at the very end, against 31% today; fewer busts are the three-skull squeeze.

## What I read from it
- **Forcing bigger draws adds keeps but not choices worth having:** coin flips rise from 44% to over half, and busts move out of range.
- **A Sin on the draw asks about one question a hand,** but one side wins it three times in four, and the choice keeps do not rise.
- **The refusal is the only change that moves everything the right way:** choices double, coin flips fall to about one in nine, and the same Sin asks four times as many questions with the two sides near even.

## What argues against it
- **The Last Dance stops being rare.** It comes in 65% of hands, against 37% today, because refusing drains the bag. The one moment the review cared about becomes the usual ending. That may be good (every hand has a climax) or may wear it out; only play will tell.
- **Not every choice is a hard one.** Refusing is always on offer, so "5.12 choices" counts throws where refusing is plainly wrong. Best play refuses about 1.1 to 1.25 times a hand (the lower figure counts a refusal worth exactly the same as keeping as a keep); that is the honest size of the new decision.
- **Without a Sin the refusal is a rule of thumb** (a simple rule is 8% behind best play), and nearly half of busts become a lost Last Dance. See the two sections above.
- **Hands are a throw longer** (5.6 against 4.6), and richer: best play earns 4.59 marks a hand against 3.58, so the pay table would need a look.
- **Best play draws a single die more often with one skull showing** (46% against 11%), since a lone die can now be refused. Whether that feels cautious or dull is for Ben.
- **It is a second rule on every throw.** The hand was meant to be one idea; this is one and a half.

## How we'll know it works
- **The probe's marks hold in the project's sim:** choices a hand at 4 or more, coin flips under 20%, busts between 20% and 30%, refusals between 1 and 2 a hand.
- **Ben plays three hands** and refuses at least once because he wanted to, not to try the button.

## My calls (open to Ben)
- Bag 8. Bag 7 changes nothing else but makes the Dance the ending of three hands in four; bag 9 makes hands 6.5 throws long.
- The lost die comes from the bag, not from the thrown dice, so the dice you refused can come back.
- Build the one-Sin prototype first on today's hand; add the refusal after Ben has played it, so each change is judged alone.
