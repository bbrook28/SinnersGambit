# Sinners' Gambit: the rules as built

Date: 2026-11-23, for 0.14.1. This page states only what the code does, with the file and line for each rule. It holds no reasons and no design: those are in `docs/superpowers/specs/`. If this page and the code disagree, the code is right and this page is out of date.

Every number is in `dice/config.gd` (`DEFAULTS`) or `dice/demands.gd`. Code names keep older words (throw, draw, wild); the screen says roll and "counts as".

## The hand

1. **The bag and the row.** A hand starts with 7 dice in the bag and an empty row of 5 places (`dice/config.gd:5`, `:10`).
2. **Rolling.** Each turn you roll 1, 2 or 3 dice from the bag, never more than the bag holds (`dice/config.gd:7`, `dice/rules.gd:26-29`).
3. **Keeping.** You keep one rolled die in the row; the other dice that are not skulls go back into the bag (`dice/rules.gd:77-83`).
   - If only one die can be kept, it is kept for you (`dice/rules.gd:70-71`).
   - If the roll is nothing but skulls, none is kept and you roll again (`dice/rules.gd:72-73`).
   - You cannot decline every die.
4. **Skulls.** A 1 is a skull. It cannot be kept and never goes back into the bag. The third skull loses the hand (`dice/config.gd:8-9`, `dice/rules.gd:55-65`).
5. **The Last Dance.** When one die is left in the bag it is rolled alone (`dice/rules.gd:33-34`). A skull loses the hand (`dice/rules.gd:60`). Any other face goes in the row as a die that counts as whichever number pays most, the hand and the Sin together; a tie goes to the better hand (`dice/rules.gd:66-69`, `:161-172`).
6. **The end.** The hand ends when the row is full or it is lost. You cannot stop early (`dice/rules.gd:93-95`).
7. **A lost hand pays 0,** the Sin's marks included (`dice/rules.gd:60-65`). There is no other penalty.

## What a full row pays

The best hand in the row, from this table (`dice/config.gd:11`, `dice/rules.gd:7`, `:118-141`):

| Hand | What makes it | Marks |
|---|---|---|
| Five of a kind | all five the same | 12 |
| Four of a kind | four dice the same | 7 |
| Three and a pair | three the same and a pair | 5 |
| Run | 2, 3, 4, 5, 6 | 5 |
| Three of a kind | three dice the same | 3 |
| Two pair | two pairs | 2 |
| Pair | two dice the same | 1 |
| No match | only a row not yet full | 0 |

A full row always makes at least a Pair or the Run.

## The Sin

- **Pride watches every free hand** (`HOSTS`, `ui/dice_screen.gd:59`). Its rule: "Exactly one 6 pays 4. Each 2 costs 1." (`dice/demands.gd:10`, `dice/rules.gd:145-155`). A second 6 takes the 4 back.
- **The hand and the Sin are added, and the total is never below 0** (`dice/rules.gd:175`). So a full row can pay 0: 2, 2, 3, 4, 5 under Pride is a Pair for 1 less 2 (`tests/dice_test.gd:207`).
- Lessons 1 and 2 have no Sin; lesson 3 has Pride.

## Marks

Each hand's marks are added to a running total (`ui/dice_screen.gd`, `_end`). The total is saved between sessions, never falls and buys nothing.

A lesson's hand pays the first time it ends. Played again from "Replay the tutorial" it pays nothing, and its result says "A replay pays nothing." (`lessons_paid`, `ui/dice_screen.gd`, `_end`).

## Not live

| Rule | Status |
|---|---|
| Envy ("Each 6 pays 1. Each 2 costs 1.") and Wrath ("Each die thrown at two skulls pays 1.") | In `dice/demands.gd` and tested; they do not host. Sim only (`demand=envy`, `demand=wrath`). |
| Greed, Lust, Gluttony, Sloth | Window art, no rule. |
| The refusal (keep none and lose a bag die) | Parked: `docs/superpowers/specs/2026-11-21-the-refusal-pitch.md`, not approved. |
| Cash out, bag 8, two dice a roll | Removed on 2026-11-20 (`CLAUDE.md`, Design). The dice-poker pitch still describes them. |
| Stakes, a debt, a run | Not designed. |
