# Sinners' Gambit: the Sin's demand (pitch)

Date: 2026-11-21. Status: draft for Ben's approval. Adds to the dice poker pitch (`2026-11-20-dice-poker-pitch.md`); the hand's rules do not change.

## The pitch
Each hand, one Sin hosts, and the Sin wants something. Give it what it wants and it pays marks on top of your poker hand. Bust and it pays nothing. The poker hand asks "what am I building?"; the Sin asks "and what is it worth to spoil it?"

## Why (Ben, after three hands of 0.11.1)
"The hand never asks a new question." About a third of keeps were coin flips (holding a 4, choosing a 2 or a 3), he drew three dice every throw until the second skull, and the Last Dance was the one moment he cared. The Sin must "make the dead dice matter".

## The one rule
**The Sin pays marks for each thing it wants.** Its window shows what, and how much. Paid with your hand; lost on a bust. That is the whole rule; only the "what" changes from Sin to Sin.

## Three Sins for the prototype
| Sin | Wants | The question it asks |
|---|---|---|
| **Pride** | Each 6 pays +2, each 5 pays +1 | Break the pair of 3s for a 6? |
| **Envy** | Each 6 pays +1, each 2 costs 1 | A die can now hurt you: draw more to dodge it? |
| **Wrath** | Each die you throw while two skulls show pays +1 | One die and safe, or two dice and paid? |

The other four Sins wait until Ben has played these three.

## What the solver says (exact best play, `sim/demand_probe/`)
| | Keeps that are coin flips | A wrong keep costs 1/4 mark or more | Busts | Marks from poker / from the Sin |
|---|---|---|---|---|
| No Sin (0.11.2) | 44% | 55% | 20% | 3.6 / 0 |
| Pride | 20% | 78% | 23% | 3.2 / 3.9 |
| Envy | 21% | 76% | 27% | 3.3 / 1.1 |
| Wrath | 43% | 56% | 24% | 3.5 / 0.4 |

- **The examples in the handoff do not work, and the table above is what replaced them.**
  - "Each 6 pays +1" alone leaves 35% coin flips: it only settles keeps that include a 6. The Sin needs two faces at different prices (or a face that costs).
  - "Wrath pays per skull survived" changes nothing: skulls are luck, so best play is the same as with no Sin.
  - "Pays per throw of three dice" makes you draw three every time; "pays per throw of one die" makes you draw one every time, with no keeps at all.
- **Which face a Sin names is only paint.** "Each 6" and "each 2" are the same game to the last decimal, because the poker ranking treats every face alike. Seven Sins cannot be seven faces; they must be seven shapes. This is the main risk of the idea, and why the prototype is three shapes, not seven Sins.
- **Wrath does not fix the coin-flip keeps** (43%). It asks its question about the draw instead: with two skulls showing, best play today is always one die; under Wrath it splits 41% one die, 59% two.
- **Draw count is still a habit under Pride and Envy** (three dice with no skulls, mostly two with one). Only Wrath makes it a choice.
- The poker hand still carries its weight: best play makes about the same hands with a Sin as without.

## On screen
The Sin's opening names its demand in one line. During the hand the demand stays on its window, each thrown die shows what it would pay or cost, and the payout counts the hand and the Sin separately.

## Out of scope
- **Marks still have no purpose.** That is a separate gap; this pitch does not close it.
- The run, the other four Sins, new art.

## How we'll know it works
- **The solver:** under Pride and Envy, fewer than 25% of keeps are coin flips (44% today) and a wrong keep costs 1/4 mark or more in over 70%; under Wrath, best play with two skulls is a real split; busts stay between 20% and 30%.
- **Ben plays three hands of each** and can name, for each Sin, a keep or a throw he would have made differently without it.

## My calls (open to Ben)
- Which Sin gets which demand, and the prices; the sim tunes the prices.
- Envy takes marks away. It is the only demand here that makes a dead die hurt, but a hand can now pay less than its poker (never below 0).
- The other four Sins keep hosting as they do in 0.11.2, with no demand, until the three are judged.
