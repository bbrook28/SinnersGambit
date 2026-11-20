# Sinners' Gambit: the bag hand

Date: 2026-11-20. Status: approved by Ben, 2026-11-20. Replaces "The hand" and "Slot kinds" in `2026-11-20-core-hand-design.md`; that doc's intent, goals, anti-goals and sim pass marks still stand unless changed here.

## Why
The first hand failed its agony mark at about 15% through every tuning tried (Target size, dice count, a Target ceiling, an open prize, bigger prizes). The cause is its shape, not its numbers: 5 dice with one placed per throw cap a hand at 5 decisions, the Target of 8 is met in about two placements, and most decisions are "feed the Target". Ben wants a 6-7 throw hand with a beginning, a middle where the board shifts under you, and a tense endgame.

## Intent (Ben)
- **Two forces move the board.** Your placements build an engine that changes how you reach the Target; the Master reacts to what you commit to with visible counter-pressure.
- **Every Master rule is visible** as a wire: a condition and its consequence, printed where it applies. Your own next throw is the only unknown. New wires may be dealt mid-hand, and always show before they can strike (Into the Breach, not hidden traps).
- **The Target anchors the hand.** The engine changes the route to it (lowers what it needs, multiplies dice, banks safety); it never wins on its own.
- **Every die has two jobs:** feeding the Target or answering the board.
- Middle-hand dilemmas to aim for: sunk cost or pivot; greed or survival; spend or score.

## Anti-goals (added)
- A clean early exit that makes fighting through throws 4-6 irrational.
- Dead pieces: an outlet, wire or slot that can do nothing on the table it's dealt to.
- A side engine that wins without the Target.

## Approaches considered (Ben picked B)
- **A. A bigger cup** (throw all 7-8 dice, place one): about 1 throw in 10 opens with three skulls, a bust with no decision; fixing it breaks the 3-skull rule.
- **B. A bag and a handful (picked):** hand length is set by bag and handful size, not by the Target; skull pressure per throw is constant and readable; the bag running down to one die is the Last Dance.
- **C. The engine gives dice back:** length swings with skill (a poor opening is a 3-throw hand, a strong one runs on), so length and agony are hard to tune.

## The hand
Pieces:
- **The bag:** 8 dice (`bag`). The 1 is a skull; 2-6 are pips.
- **The table:** the Target, the Offering, 2 engine slots and the Master's wires, each showing its rule.

Order of play:
1. **Lay out.** The Master deals the Target, the Offering, 2 engine slots (drawn from the engine kinds below, no repeats; so at least one is a 2-die slot), 1 prize (a Pair or a Sum) and 1 wire (drawn from the wires below). The prize is dealt face down.
2. **Throw:** draw `handful` dice (3) from the bag, or every die left if fewer, and throw them.
3. **Skulls stay:** each skull stays on the table and leaves the bag for the hand. Three skulls bust. A full Ward cancels the next skull (it never reaches the table) and empties. Skulls from the handful and from Curse rethrows land together: a full Ward cancels the first one, the rest stay.
4. **Place exactly one die** (not a skull) into a slot that accepts it, or place your held die instead (Hold, below). The unplaced dice go back into the bag, except on the Dance: an unplaced Dance die leaves the hand.
5. **The Master answers**, at once: any wire whose condition is now true takes effect; when you first place a die into an engine slot, he deals a second wire (if the wire pool has one left). A wire never fires on the answer that deals it.
6. **Throw again or cash out.**
7. **Last Dance:** the throw that draws the bag's last die alone (even under Hunger, if only 1 die was left; a throw that empties a bag of 2+ is not a Dance; the sim reports how often a hand ends without one). Its pips count double wherever they go, and a skull busts you outright whatever the skull count, unless a full Ward cancels it. A held die may be placed instead, but the thrown die is still the Dance die.
8. When the bag is empty: a held die may be placed once more (no throw, no wire), then the hand cashes out automatically.

With 8 dice and at most 2 surviving skulls, a hand runs 6-8 throws when played to the end.

Outcomes:
- **Cash out with the Target met:** won. Stopping as soon as the Target is met pays the bare win (`win_marks`). Meeting the Target reveals the prize, so the choice to throw on is made seeing it; a claimed prize adds its marks.
- **Cash out short of the Target:** lost.
- **Bust:** lost; claimed prizes are forfeit.

## Always on the table
| Slot | Accepts | Effect |
|---|---|---|
| **Target** | any die, many | adds its pips (doubled after a full Ladder, doubled on the Dance) toward what the Target needs: `target` (about 16, the sim sets it) plus Tax, minus Offerings. "Met" is checked live: a Tax that fires after the Target is met can un-meet it. The prize, once revealed, stays revealed; Hunger, once on, stays on |
| **Offering** | any die, many | the Target needs 1 less. The least-bad outlet: never dead |

## Engine slots (2 dealt per hand)
| Slot | Accepts | Effect |
|---|---|---|
| **Hold** | one die | keeps that die out of the bag. On a later throw you may place it instead of a thrown die; Hold is then empty and can take another |
| **Ward** | two dice of the same face, across throws | full: cancels the next skull (including the Dance's), then empties |
| **Ladder** | two dice, the second higher than the first (so the first must be 5 or less) | full: every later die into the Target counts double |

## The Master's wires (1 at the start, 1 more on your first engine die)
| Wire | Condition | Consequence |
|---|---|---|
| **Tax** (on one 2-die engine slot, shown there) | that slot is filled | the Target needs +3, for the rest of the hand |
| **Hunger** | the Target is met and you throw on | every later throw draws 4 dice (or all that are left) |
| **Curse** | a die sits held, or alone in an engine slot that isn't full, when you throw | each such die is rethrown with your handful and takes its new face. A waiting die is always alone in its slot, so it still fits, with one exception: a 6 alone in the Ladder can never be finished, so it goes back into the bag. A 1 or 2 makes it a skull, a normal skull in every way (counts toward three, a full Ward cancels it) |

A wire is never dealt where it could never trigger: Tax always goes on a Ward or Ladder (the slot you just seeded, or the other slot if you seeded Hold); every hand has at least one, since 2 of the 3 engine kinds are 2-die slots; Curse is always live because every engine slot can hold a die across a throw.

## Prizes
One per hand: a Pair (2 marks) or a Sum to 8 (1 mark), face down until the Target is met, then revealed; filled one die per throw; claimed prizes pay if the hand is won. Their countdowns retire (see below); a prize simply stays until the hand ends.

## What retires
Threats, reroll tokens and all countdowns. Wires take over the Master's job.

## The simulation
The same sim, rules and policies rebuilt on the bag hand; every number above is a `hand/config.gd` key (`bag`, `handful`, `hunger_handful`, `target`, `tax`, `win_marks`, prize sizes, the slot and wire pools). Same report and pass marks as the first hand, plus:
- **Pace:** throws per hand, aiming at 6-7 for strong.
- **Early exits:** how often strong cashes out on throws 1-3, and whether it pays.
- Per-piece use: how often strong fills each engine slot and how often each wire fires.

## Decided by Ben
The bag and the handful; three skulls bust, skulls stay and leave the bag; 6-7 throws; every Master rule visible as a wire, your own throw the only unknown; wires may be dealt mid-hand, always before they can strike; the Target anchors the hand, the engine changes the route to it; other ways to finish must cost real dice; stopping at the Target pays the bare win, and the prize (revealed when the Target is met) pays only if you throw on and claim it; Ladder takes 2 dice; the Offering lowers what the Target needs, always; Curse reaches any die waiting in an engine slot; a Hunger throw or the Dance draws whatever is left; the second wire is dealt on your first engine die, and Tax always lands on a 2-die slot (Ben, after the builder check).

## My calls (open to Ben)
- An 8-die bag (9 runs 7-9 throws); a handful of 3; a starting Target of about 16; Tax +3.
- The first set: Hold, Ward, Ladder; Tax, Hunger, Curse; 2 engine slots and 1 starting wire per hand.
- A full Ward cancels even the Dance's skull.
- Curse's rethrow uses the same skull face as a normal throw, plus the 2.
- Prizes lose their countdowns.

## Left to the builder
- The strong policy keeps its playout method; its playout policy needs a small greedy rule for each engine slot.
- How the sim reports per-piece use.
