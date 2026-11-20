# Sinners' Gambit: the core hand, and a simulation to tune it

Date: 2026-11-20. Status: draft for Ben's approval.

## Intent
A push-your-luck dice game for phones with the tension of a frontier card table where one wrong move means death, and the presentation and depth that Balatro and Inscryption reach (their qualities, never their content). Gothic look: the Seven Sins in stained glass and the Master of the Dance (the crowned Danse Macabre Reaper with his fiddle).

The old version failed because the only choice was "throw again or stop" (luck, not skill), rivals' turns were dead time, too many systems arrived at once, and nothing on screen explained itself. This design answers each: every safe throw asks where a die goes, there are no rivals' turns, the hand is one small system, and every rule shows on the table.

The first job is to prove one hand is tense and skilful on its own, by numbers first (Ben's pick). This document defines the hand and the simulation that tunes it. No screen is built until the sim's numbers are approved.

## Goals
- One hand, played solo against the Master, where the decision after every safe throw is real: no single obviously best move most of the time.
- Death is countable at a glance: skulls on the table.
- A hand ends in a climax (cash out or one all-in throw), never a fizzle.
- A simulation that reports whether good play beats poor play by a clear margin, and how often busts, cash-outs and Last Dances happen.

## Non-goals (this step)
- The run (lives, rising hands, Sin pacts), screens, art, sound, onboarding. Pacts are designed later, on top of a hand that already works.
- Multiplayer of any kind.

## Anti-goals (failure even if it works)
- A hand where the right placement is obvious every throw (no agony).
- A hand decided by luck: good play winning about as often as random play.
- Any rule the player must remember that the table doesn't show.
- Watching instead of playing: the Master's answers are instant, never a turn to sit through.

## The hand
Pieces:
- **Dice:** 5 six-sided dice. The 1 is a **skull**; 2-6 are pips.
- **Table:** the slots the Master lays out. Each slot shows its rule and its reward; some show a countdown.

Order of play:
1. **Lay out.** The Master deals the hand's table: one Target, one Offering, and 2-3 others drawn from the slot kinds below.
2. **Throw** every die still in your hand.
3. **Skulls stay.** Each skull thrown stays on the table, out of your hand for the rest of the hand. Three skulls on the table is a **bust**.
4. **Place exactly one die** (not a skull) into a slot that accepts it. The rest return to your hand.
5. **The Master answers**, at once: every countdown drops by one; a threat at 0 strikes, a prize at 0 is taken off the table.
6. **Throw again or cash out.**
7. **Last Dance:** when one die is left in your hand, its throw is the Dance: its pips count double wherever it goes, and a skull busts you outright whatever the skull count.
8. The hand also ends when your hand is empty (every die placed or a skull): that is an automatic cash-out.

Outcomes:
- **Cash out with the Target met:** the hand is won. Claimed prizes pay.
- **Cash out short of the Target:** the hand is lost (in the run: a life).
- **Bust:** the hand is lost and claimed prizes are forfeit.

## Slot kinds (first set)
| Slot | Accepts | Effect |
|---|---|---|
| **Target** (always) | any die, many over the hand | adds its pips toward the hand's target number |
| **Offering** (always) | any die, many | the lowest countdown on the table rises by 1 (a least-bad outlet: never wasted, never a goal) |
| **Threat** | one die at or above its number (e.g. 5+) | placing stops it. At 0 it strikes: adds a skull to your table |
| **Pair prize** | two dice of the same value, filled across throws | claimed when full: bonus pips to the Target |
| **Sum prize** | two dice summing to its number, filled across throws | claimed when full: bonus pips to the Target |
| **Reroll token** (prize) | one die at or above its number | claimed: once this hand, rethrow one die before placing |

Multi-die slots fill one die per throw; a half-filled slot keeps its die. A slot that is taken off the table (countdown 0) loses any dice in it.

## The simulation
A headless Godot script (UI-free rules in their own file, so a later screen reuses them). It plays the hand many thousands of times with several policies and reports:
- **Outcome rates:** hand won, short, bust; Last Dance reached; Last Dance survived.
- **Skill gap:** win rate of a strong policy (search over placements and stop decisions) against greedy (always feed the Target, stop at the target) and random-legal. Target: strong beats greedy by a clear margin and greedy beats random.
- **Agony:** how often the strong policy's best and second-best placements are close in expected value (a proxy for "no obvious move").
- **Pace:** throws per hand.
- Every number in the rules (target size, threat thresholds, countdowns, bonus sizes, skull face count) is a parameter, so tuning is a command line, not a code change.

## Approaches considered
- **A. Numbers first (picked by Ben):** tune the hand in a sim before any screen. Odds are sound before anything is felt; the risk is tuning a hand that turns out dull to play, so the sim measures skill gap and agony, not just rates.
- **B. A playable greybox with a sim beside it:** faster to feel, but the screen arrives before the odds are known.
- **C. A polished slice:** closest to the target feel, but locks presentation before the core is proven, the old project's mistake.

## Decided by Ben
Push your luck; gothic art stays; the Master is the opponent on the table and answers instantly; Sin pacts are what grows over a run (later); skulls bust at three; dice are placed into slots; a least-bad outlet always exists; a shrinking pool ends in a climax; exactly one die placed per throw; numbers first.

## Rules settled after the builder check (my calls, open to Ben)
- **A threat strikes once and leaves the table.** Its skull counts toward the bust but takes no die from your hand.
- **Countdowns:** threats and prizes may have them; the Target and Offering never do. **The Offering raises a countdown of your choice by 1**, a threat's or a prize's, so it can keep a prize alive as well as delay danger.
- **Last Dance doubling applies wherever a number is used:** pips into the Target, a Sum prize, and thresholds (a doubled 3 meets "5+"). Pairs still match by face.
- **The reroll token** rethrows one die before you place; a rethrown skull is a skull and stays on the table.
- **Pass marks for tuning:** strong beats greedy by at least 10 points of win rate and greedy beats random; on at least 30% of decisions the strong policy's two best placements are within 5% of each other in expected value; busts 20-35% of hands; the Last Dance reached in 15-30%.

## Left to the builder (my calls, open to Ben)
- Starting values: target and threat numbers, countdown lengths, bonus sizes. The sim's first job is to find them.
- The strong policy's method (expectimax over the next throw is enough to start).
- Where the sim's results are written (`build/sim/`), and its command line.
