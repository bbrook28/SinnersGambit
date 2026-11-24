# Sinners' Gambit: dice poker against the Master (pitch)

Date: 2026-11-20. Status: approved 2026-11-20, then changed by Ben the same day (bag 7, choose 1 to 3 dice a roll, no cash out; `CLAUDE.md`, Design). This page was not rewritten and no longer describes the hand: the rules as built are in `docs/rules.md`. Replaces the bag hand (`2026-11-20-bag-hand-design.md`) as the hand, if approved.

## The pitch
You draw dice from a bag, a pair at a time, and build a poker hand against the Master of the Dance. Every throw you keep one die. Every 1 is a skull. Three skulls and the Master takes the lot. Cash out whenever your hand is good enough.

## Why (Ben, after playing 0.8.0)
"This needs to be simple and elegant like Balatro or poker." The bag hand asked the player to learn a pile of separate rules (slots, wires, tiers, a second wire) before any of them meant anything, and even perfect play mostly ignored them. Poker works because the core is one idea everyone already knows, and every decision follows from it.

## The hand
1. **The bag** holds 8 dice. A 1 is a **skull**; 2 to 6 are pips.
2. **Throw:** draw 2 dice from the bag.
3. **Skulls stay** on the table and leave the bag. **Three skulls: bust**, the hand scores nothing.
4. **Keep exactly one** of the other dice in your **row** (5 places). The die you don't keep goes back into the bag.
5. **Throw again or cash out.** Your row scores as the best poker hand in it.
6. **The Last Dance:** the bag's last die, thrown alone. A skull busts you outright; any other face is **wild**.
7. A full row cashes out by itself.

## What it pays (the sim sets the numbers)
High die 0 · pair 1 · two pair 2 · three of a kind 3 · straight (2-3-4-5-6) 5 · full house 5 · four of a kind 7 · five of a kind 12.
Pips are 2 to 6, so there is exactly one straight, and five of a kind is a real, rare dream.

## The one choice
Which die to keep. Take the safe pair now, or chase the straight? Throw on with two skulls showing, or cash out a three of a kind? The screen shows the stakes: what each die would make of your row, and your chance of busting on the next throw. Nothing else needs explaining, because everyone already knows the poker ranking.

## What stays, what goes
- **Stays:** the bag, skulls, three to bust, the Last Dance, cash out, the bust odds on the Throw button, the stained glass and the Master.
- **Goes:** tiers, the Target, the Offering, engine slots, wires, the prize. They stay in git (up to this commit) if a piece earns its way back.

## Later: the run (not this step)
Hands chain into a night at the Master's table. The **Seven Sins** are the modifiers you gather between hands, each one rule printed on its glass window ("Greed: pairs pay double", "Wrath: your first skull each hand is thrown again"). The hand stays tiny; the run is where it grows.

## How we'll know it works
- **Ben plays it** on TestFlight and can say, after one hand, what he's trying to do and why each keep mattered.
- **The sim** checks that good play beats greedy play by a clear margin, that a hand runs 5 to 7 throws, and that busts land around 1 in 4 (the old pass marks that still mean something).

## My calls (open to Ben)
- Bag 8, draw 2, keep exactly 1, row of 5 (a full row is 5 throws with no skulls; 3 spare dice for skulls).
- The Last Dance die is wild instead of doubled: doubling means nothing in poker.
- You must keep a die each throw: a forced keep makes junk dice hurt.
- The tutorial is one guided hand: throw, a skull, a pair, a choice between a pair and a straight draw, cash out.
