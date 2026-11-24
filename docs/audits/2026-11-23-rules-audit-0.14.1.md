# Sinners' Gambit 0.14.1: rules audit

Date: 2026-11-23. Commit audited: 78e9156 (0.14.1, local). Status: findings only; nothing in the game was changed.

Every rule the game plays is stated below from the project's files alone. The code and the screen agree on all of them; the documents do not. There is no current rules document, the one spec the code cites still describes a different hand, and 13 places are listed where a document, a comment or shown text says something the code does not do.

## How it was done

- Ben's rules-guide brief was used with its sources swapped for today's files, because the files it names (`Docs\`, rules V5, the REPLY files) exist only at the tag `archive/sinners-gambit-v1`.
- Sources: `CLAUDE.md`; every file in `docs/superpowers/specs/` and `plans/` about this game; `docs/audits/2026-11-23-audit-0.14.0.md`; `.claude/handoff.md`; `dice/*.gd`, `ui/*.gd`, `tests/dice_test.gd`, `sim/dice_sim.gd`.
- Two readers worked separately, one on documents and one on code, and their reports were compared. Nothing was run for this audit.
- No answer is filled from another dice game, and no design change is suggested.
- "Derived" marks a conclusion reasoned from the code that no test pins.

Priority used on a conflict, highest first:

1. The latest change Ben approved (a dated line in `CLAUDE.md`, or an approved plan).
2. The current rules document. None exists; see Gaps.
3. The tutorial and screen design.
4. Older documents, marked [OLD].
5. Ideas not approved, marked [PROPOSED].

Status words: BUILT (the build named), LOCAL ONLY (committed here, in no build), SIM ONLY, PARKED, REMOVED.

## Terms

- **Bag:** the dice you roll from. **Row:** the five places you fill.
- **Roll:** take 1, 2 or 3 dice from the bag and show them. **Keep:** put one rolled die in the row.
- **Skull:** a rolled 1. **Candle:** one of three lights; each skull puts one out.
- **Hand:** one play from an empty row to a paid row or a loss; also the name of what the row makes (Pair, Run).
- **Marks:** the score. **The Sin:** the stained-glass figure watching the hand, who pays or takes marks on top.
- **The Last Dance:** the roll of the bag's last die.
- **The Master of the Dance:** the Reaper behind the table, who takes a lost hand.

Code names keep older words (throw, draw, wild, seal, straight, full house); `tests/ui_test.gd` bans them from the screen.

## Documents that change a rule, in order

| # | Date | Document | Change |
|---|---|---|---|
| 1 | 11-20 | `2026-11-20-bag-hand-design.md` | Replaces the first hand (five dice, slots, a Target) with a bag hand (wires, tiers). |
| 2 | 11-20 | `2026-11-20-dice-poker-pitch.md` | Replaces the bag hand with dice poker: bag 8, roll 2, cash out. |
| 3 | 11-20 | `CLAUDE.md`, Design | "no cash out (a hand plays to a full row or a bust), bag 7", choose 1, 2 or 3 dice. The pitch was not edited. |
| 4 | 11-21 | `plans/2026-11-21-sin-demand.md` | The Sin's demand (0.12.0): Pride, Envy and Wrath host in turn; total never below 0. |
| 5 | 11-21 | `plans/2026-11-21-lone-six.md` | Pride becomes "exactly one 6"; "`HOSTS` is Pride alone"; Envy and Wrath stop hosting. |
| 6 | 11-21 | `specs/2026-11-21-tutorial-design.md` | Three lessons replace the one guided hand; shown words renamed. |
| 7 | 11-23 | `plans/2026-11-23-0.14.1-fixes.md` | The hint counts the Sin; the `?` page waits for the dice; two cards for a player who skipped. |

## The rules as played

### The bag and the row
- **Verdict:** A hand starts with 7 dice in the bag and a row of 5 places.
- **Basis:** `CLAUDE.md`, Design: "no cash out (a hand plays to a full row or a bust), bag 7". Code: `dice/config.gd:4-9` (`bag` 7, `row` 5).
- **Status:** BUILT (0.14.0; unchanged in 0.14.1).
- **Notes:** [OLD] `2026-11-20-dice-poker-pitch.md`, The hand: "The bag holds 8 dice."

### Rolling
- **Verdict:** Each turn you choose to roll 1, 2 or 3 dice, never more than the bag holds.
- **Basis:** `CLAUDE.md`, Design: "each throw you choose to draw 1, 2 or 3 dice". Code: `dice/rules.gd:26-29`.
- **Status:** BUILT (0.14.0).
- **Notes:** A button the bag cannot fill is greyed with "only N in the bag". [OLD] the pitch: "Throw: draw 2 dice from the bag."

### Keeping
- **Verdict:** You keep exactly one rolled die in the row; the other dice that are not skulls go back into the bag.
- **Basis:** `plans/2026-11-21-tutorial.md`, Task 1: "Keep one; the rest go back into the bag." Code: `dice/rules.gd:80-81`.
- **Status:** BUILT (0.14.0).
- **Steps:**
  1. Roll. Skulls leave first.
  2. If one die is left, it is kept for you (`dice/rules.gd:70-71`).
  3. If two or three are left, tap one and tap Keep.
  4. If none are left, nothing is kept and you roll again (`dice/rules.gd:72-73`).
- **Notes:** You cannot decline every die. A 1-die roll is therefore always a forced keep, including a 2 or a second 6 under Pride.

### Skulls
- **Verdict:** A 1 is a skull; it cannot be kept, never returns to the bag, and the third skull loses the hand.
- **Basis:** `specs/2026-11-21-tutorial-design.md`, Lesson 2: "Three candles out and the Master takes the hand: it pays nothing." Code: `dice/config.gd` (`skull_faces` 1, `bust_at` 3), `dice/rules.gd:47-64`.
- **Status:** BUILT (0.14.0).
- **Notes:** A lost hand pays 0 marks, the Sin's marks included. There is no other penalty.

### The Last Dance
- **Verdict:** When one die is left in the bag it is rolled alone; a skull loses the hand, and any other face counts as whichever number pays most.
- **Basis:** `plans/2026-11-21-sin-demand.md`, The numbers: "The wild die takes the face that pays most in all." Code: `dice/rules.gd:33-34`, `:66-68`, `:161-172`.
- **Status:** BUILT (0.14.0).
- **Notes:**
  - "Pays most" counts the hand and the Sin together; a tie goes to the better hand. Under Pride the die can become the single 6.
  - Derived: with bag 7 and row 5, the Last Dance comes only with four dice in the row and two skulls showing. A skull there is always the third skull.

### The end of the hand
- **Verdict:** The hand ends when the row is full or on the third skull; you cannot stop early.
- **Basis:** `CLAUDE.md`, Design: "no cash out (a hand plays to a full row or a bust)". Code: `dice/rules.gd:93-95`; `tests/dice_test.gd:109`.
- **Status:** BUILT (0.14.0). Cash out: REMOVED (2026-11-20).
- **Notes:** The code also ends a hand on an empty bag. Derived: at bag 7 that cannot happen before the row is full.

### The hands and what they pay
- **Verdict:** A full row is paid as the best hand in it, from this table.
- **Basis:** Code: `dice/config.gd:10` (`pay` "0,1,2,3,5,5,7,12"), `dice/rules.gd:7`, `:118-141`. No approved document holds the final table.
- **Status:** BUILT (0.14.0).

| Hand | What makes it | Marks |
|---|---|---|
| Five of a kind | all five the same | 12 |
| Four of a kind | four dice the same | 7 |
| Three and a pair | three the same and a pair | 5 |
| Run | 2, 3, 4, 5, 6 | 5 |
| Three of a kind | three dice the same | 3 |
| Two pair | two pairs | 2 |
| Pair | two dice the same | 1 |
| No match | shown on a row not yet full | 0 |

- **Notes:** A row of fewer than five dice shows its hand so far on the ribbon; a Run needs all five. A full row always makes at least a Pair or the Run, so No match is never paid.

### The Sin
- **Verdict:** Pride watches every free hand: exactly one 6 in the row pays 4 marks, and each 2 costs 1.
- **Basis:** `specs/2026-11-21-tutorial-design.md`, The words: "Exactly one 6 pays 4. Each 2 costs 1." Code: `dice/demands.gd:10`, `dice/rules.gd:145-155`, `ui/dice_screen.gd:59` (`HOSTS`).
- **Status:** BUILT (0.13.0 onward).
- **Notes:**
  - A second 6 takes the 4 back; a third changes nothing.
  - The hand and the Sin are added, and the total is never below 0 (`dice/rules.gd:175`). Example: 2, 2, 3, 4, 5 under Pride pays 0.
  - Lessons 1 and 2 have no Sin, though Pride's window hangs there. Lesson 3 uses Pride.
  - Envy ("Each 6 pays 1. Each 2 costs 1.") and Wrath ("Each die thrown at two skulls pays 1.") are in `dice/demands.gd` and tested. SIM ONLY: `plans/2026-11-21-lone-six.md`: "stay in the file, tested, and do not host."
  - Greed, Lust, Gluttony and Sloth have window art and no rule.

### The Master of the Dance
- **Verdict:** The Master takes a lost hand; he has no other rule.
- **Basis:** `specs/2026-11-21-tutorial-design.md`, kept phrase: "The Master takes the hand". Code: no opponent play found.
- **Status:** BUILT (0.14.0).

### Marks
- **Verdict:** Each hand's marks are added to a running total that is saved and never falls; marks buy nothing.
- **Basis:** `docs/audits/2026-11-23-audit-0.14.0.md`, Gameplay: "the total never falls, and marks buy nothing". Code: `ui/dice_screen.gd:363`, `:1780-1793`.
- **Status:** BUILT (0.14.0).
- **Notes:** Lesson hands pay into the total (5 and 7 marks, then lesson 3's hand), and "Replay the tutorial" pays them again. Leaving a hand unfinished costs nothing.

### The hint under the row
- **Verdict:** The hint names the one die that would raise what the row pays, hand and Sin together, and is empty when no die would.
- **Basis:** `plans/2026-11-23-0.14.1-fixes.md`, Task 1: "only if that value is higher than the row's value now". Code: `ui/dice_screen.gd`, `next_hint`.
- **Status:** LOCAL ONLY (0.14.1). In 0.14.0 (BUILT) the hint counts the hand alone.

### The `?` page and the one-time cards
- **Verdict:** The `?` page holds the ranking and four rule paragraphs; a player who skipped the lessons gets a "Skulls" card and a "The Last Dance" card once each.
- **Basis:** `plans/2026-11-23-0.14.1-fixes.md`, Task 3: "First skull, hand not lost". Code: `ui/dice_screen.gd:96-101` (`RULES`), `_meet`.
- **Status:** The page: BUILT (0.14.0). The two cards, and the page waiting for moving dice: LOCAL ONLY (0.14.1).

## Where they disagree

Documents against code:

1. **Bag.** Docs say "The bag holds 8 dice" (the pitch); code does 7. Resolved by `CLAUDE.md`'s dated change: 7.
2. **Roll size.** Docs say "draw 2 dice" (the pitch); code lets you choose 1 to 3. Resolved the same way.
3. **Cash out.** Docs say "Throw again or cash out" (the pitch); code has none. Resolved the same way.
4. **Who hosts.** `CLAUDE.md` says "(Pride, Envy, Wrath), and only they host"; code has `HOSTS := ["pride"]`. Resolved by the approved lone-six plan: Pride alone.
5. **A full row and 0.** `plans/2026-11-21-tutorial.md`, Task 4 says "so a full row never pays 0"; code pays 0 for 2, 2, 3, 4, 5 under Pride (`tests/dice_test.gd:207`). Not resolved by any document.
6. **How often the Last Dance comes.** `dice/config.gd:5` says "~25% of hands"; `sim/dice_sim.gd:99` sets a pass band of 15 to 30%; the 0.14.0 audit measured 37.9% under Pride. Not resolved.
7. **Statuses.** The dice-poker pitch and the Sin's demand pitch both read "draft for Ben's approval"; their plans read approved and the rules are in a build.
8. **`.claude/handoff.md`** describes 0.11.2: "All seven Sins host in turn". Code: Pride alone.

Shown text against code:

9. **"Keep one" each turn.** A roll of nothing but skulls keeps none. The line "Nothing but skulls. Roll again." shows only while the row is empty.
10. **"Counts as any number you need."** The code chooses the face for the best total, Sin included. No shown text says the last die can earn or cost Sin marks.
11. **"Tap ? at any time."** In 0.14.1 the page does not open during a roll or a payout.
12. **"A Sin watches each hand."** Lessons 1 and 2 have no Sin.
13. **The banner "A skull on the Last Dance. The hand pays nothing."** Derived: it cannot appear at bag 7 and row 5, because that skull is always the third and "Three skulls." shows.

Rules in the code that no shown rule text states:

- The total is never below 0. It shows only as the banner "Pride takes it all".
- A single rolled die is kept for you. Only lesson 2's card says so; the `?` page does not, and a player who skipped never reads it.
- Replaying the tutorial pays marks again.

Stale comments:

- `ui/dice_screen.gd:60`: "All seven host hands, in this order". Only Pride hosts.
- `ui/dice_screen.gd:476-477`: examples name Envy, who cannot occur.
- Wrath's line uses "thrown", a banned word. It cannot be shown while Wrath does not host.

## Not live

| Rule | Status | Basis |
|---|---|---|
| The refusal (keep none, lose a bag die, bag 8) | [PROPOSED], PARKED | `2026-11-21-the-refusal-pitch.md`: "draft, not approved (Ben, 2026-11-21); no game code" |
| Envy and Wrath as hosts | SIM ONLY | `plans/2026-11-21-lone-six.md`, Rules |
| Greed, Lust, Gluttony, Sloth as hosts | No rule exists | examples only in the pitch and the handoff |
| Stakes, a debt, the run | [PROPOSED] | the pitch, "Later: the run (not this step)" |
| Cash out | REMOVED | `CLAUDE.md`, Design |
| Slots, the Target, tiers, wires, the Ward, the prize | REMOVED | the pitch: "Goes: tiers, the Target, the Offering, engine slots, wires, the prize." |
| The exact solver, the rule-of-thumb players, `sim/cores_sim.gd` | SIM ONLY | `dice/policies.gd`, `sim/` |

## Gaps

I don't see these in the provided files. Each names the document that should own it.

- **A current rules document.** The rules as built live in `CLAUDE.md`'s Design lines and in comments in `dice/config.gd`. Owner: a new rules file in `docs/`, or the dice-poker pitch brought up to date.
- **The pay table as tuned.** The pitch lists it as provisional ("the sim sets the numbers") and no later document records the choice. Owner: the rules file.
- **Why bag 7.** One line in `CLAUDE.md` and a comment whose figure the sim contradicts. Owner: the rules file.
- **What marks are for** (stakes, a debt, a run). Owner: the run pitch, not yet written.
- **Rules for the four Sins with no demand.** Owner: the Sin's demand pitch ("seven Sins need seven").
- **The hint's rule**, stated only in a plan. Owner: the tutorial design.
- **The risk captions' rule** ("no risk", "under 1% to lose it"). Owner: the tutorial design.
- **Whether the total is meant to persist** between sessions. The code saves it; no document says so. Owner: the rules file.
