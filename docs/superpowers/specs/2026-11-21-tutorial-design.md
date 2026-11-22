# The tutorial: three short guided hands, and plainer words

Status: **approved by Ben, 2026-11-21.** Plan: `docs/superpowers/plans/2026-11-21-tutorial.md`. Written 2026-11-21 after Ben's note on 0.13.1: a lot of the lingo and the functions are not explained.

## Why
A player who has never played poker or a dice game must understand everything on the screen. Today the guided hand says "poker hand", "Pair" and "Three of a kind" without saying what makes one; marks, the Sin, the tags on the dice, the ribbon, the hint and "wild" are not taught at all; and "draw" and "throw" name one act.

## Goals
- Every word and every number on the screen is taught once, by doing it, before the player needs it.
- One word for one thing, the same in the tutorial, on the table and on the ? page.
- The ? page holds all the rules, so nothing has to be remembered.

## Not in this build
- No rule changes, no new art, no sound. The stakes probe and the run are separate work.
- Envy and Wrath are not taught (they do not host).

## Would make it a failure
- Walls of text: no card over about 45 words, and never two cards in a row without a roll between them, except at the start of a lesson.
- A term used before it is taught.
- A returning player forced through it again.

## The words (Ben chose to rename; the list is Claude's proposal)
| Now | Becomes | Where |
|---|---|---|
| draw, throw | roll | all on-screen text |
| Straight | Run | hand name |
| Full house | Three and a pair | hand name |
| High die | No match | hand name, shown only on a row not yet full (a full row always makes at least a Pair or a Run, so it is not in the ranking) |
| wild / WILD | counts as any number / ANY | messages, the label on the die |
| a lone 6 | exactly one 6 | Pride's line: "Exactly one 6 pays 4. Each 2 costs 1." |
| Pride hosts this hand | Pride is watching this hand | ? page, the Sin's card |
| seal | button | tutorial text |
| snuffs a candle | puts out a candle | tutorial, ? page |

Kept, each taught once: skull, marks, the bag, your row, Keep, the Last Dance, "The Master takes the hand".
Code names (`throw`, `draw_options`, `HANDS` order) do not change; only what is shown.

## The three lessons
Each is one scripted hand: fixed dice, only the right button live, a line of instruction under the table edge, as the guided hand works today. The first card of each lesson has a second button, "Skip the lessons", which ends the tutorial. After lesson 3 the tutorial is marked seen. "Replay the tutorial" on the ? page starts lesson 1.

### Lesson 1: the row (no Sin, no skull can come)
Teaches: roll, the bag, keep, your row, what a hand is, the ribbon, the hint, marks.
1. Card "The Master's dice": fill your row with five dice. Dice that match make a hand, and a better hand pays more marks. Marks are your score.
2. Roll 2 → 4, 6. "Tap the 4, then Keep." The 6 goes back into the bag; the count at the top drops by one.
3. Roll 2 → 4, 3. Keep the 4. Card "A Pair": two dice the same. The ribbon under the table always shows what your row is worth now, and "if kept" shows what a die would make before you keep it.
4. Roll 3 → 4, 5, 2. Keep the 4: Three of a kind · 3. The line points at the hint under the row: "One more 4: Four of a kind · 7".
5. Roll 2 → 6, 2. Keep the 6. Roll 2 → 6, 3. Keep the 6: Three and a pair · 5.
6. The row is full and paid. Card "Paid": the ranking table, with one line on each hand (Run is 2, 3, 4, 5, 6).

### Lesson 2: skulls (no Sin)
Teaches: the skull, candles, losing a hand, the chance on each button, more dice against more risk, the last die.
1. Card "Skulls": a 1 is a skull. It cannot be kept, it never goes back into the bag, and it puts out one candle. Three candles out and the Master takes the hand: it pays nothing.
2. Roll 2 → 1, 5. A candle goes out; the 5 is the only die left to keep, so it is kept.
3. Card "More dice, more risk": more dice give more to choose from and more chances of a skull. Under each button is your chance of losing the hand on that roll.
4. Roll 3 → 5, 1, 3. Second candle out. Keep the 5. The line: "One more skull loses the hand. One die is the safest roll."
5. Roll 1 → 5. Roll 1 → 3. Row: 5, 5, 5, 3; one die in the bag.
6. Card "The Last Dance": the bag's last die is rolled alone. Whatever it shows counts as any number you need; a skull loses the hand.
7. Roll → 4, shown as ANY: Four of a kind · 7. Paid.

### Lesson 3: the Sin (Pride)
Teaches: the window, the Sin's line on the table edge, the tags above the dice, the second number on the ribbon, the result line.
1. The opening, then card "The Sin": a Sin watches each hand. It pays marks for what it wants and takes marks for what it hates, on top of your hand. Its rule is written on the table edge. Lose the hand and it pays nothing.
2. Roll 2 → 6, 3. The 6 wears "+4". "The number above a die is what Pride pays if you keep it. Keep the 6."
3. Roll 2 → 6, 4. The 6 wears "−4". "A second 6 is no longer exactly one: Pride's 4 would be lost. Keep the 4."
4. Card "The dice are yours": the ribbon shows your hand and Pride's marks side by side. Tap ? for all the rules.
5. The rest of the hand is real dice and the player's own choices. The result line names both parts ("Pair 1 + Pride 4").

The one-time cards that today follow the tutorial (first skull, first Last Dance, first demand) are marked seen when the lessons are finished, and still appear for a player who skipped.

## The ? page
Same words as the lessons, in this order: the ranking (seven rows, each with a line on what makes it), the Sin watching this hand and its line, then the rules in four short paragraphs (rolling and keeping; skulls and candles; the Last Dance; the Sin). Version at the foot. It scrolls if it does not fit.

## Approaches
- **Three short guided hands (chosen by Ben).** A few ideas each, learned by doing; about 15 taps a lesson.
- One longer guided hand: one sitting, but eight or more cards of reading in a single hand, and skulls, the last die and the Sin cannot all happen naturally in five keeps.
- Cards only, no scripted dice: cheapest, and the reading nobody does.

## Risks
- "Exactly one 6 pays 4. Each 2 costs 1." is longer than today's line and must still end left of the candles at 30 px or more, at phone shape and 4:3.
- "Three and a pair · 5" is wider than "Full house · 5" on the ribbon beside the Sin's marks.
- Three lessons before free play may feel long. The skip button is the answer; Ben judges the length by playing.

## Done when
- `ui_test` walks each lesson to its end, checks the skip, and checks that no on-screen string holds "draw", "throw", "wild", "lone", "hosts", "Straight" or "Full house".
- Shots of every card and every guided step at phone shape and 4:3, sent to Ben without a verdict.
- Version 0.14.0.

## Left to the builder
The wording of each instruction line within the limits above; how the lesson scripts are stored in `ui/dice_tutorial.gd`; the layout of the eight-row ranking.
