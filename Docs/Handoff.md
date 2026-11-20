# Handoff (2026-11-16): owner of now, next, waiting on Ben, open faults
Read `CLAUDE.md` first. Phase list: `Docs/UXPlan.md`. The per-step log to 2026-11-15: `Docs/archive/Handoff_2026-11-13_to_15.md`. Ben's replies arrive in `Docs/review/inbox/reply.md` (REPLY n); each gets a packet in `Docs/review/latest/`.

## Now
- Phase 8, the table, playing `Rules.V5` (rules as built: `Docs/TableDesign.md` §0). Pushed and on TestFlight: build 118 (main f44ffee): the Master as a figure, the call at 550, Devour +45.
- **Local only, not pushed** (Ben: no push until he has played 118): the Master's line in his robe and the hand clamp (REPLY 17); Idle-one and Hubris x2 (17); the call floor, no call before round 3's end (18); the dim post, game end on the page, the one-line buy row and the 5-dice cap (19-21).
- Layout locked (REPLY 24): `Docs/TableSpec.md`, reference `Docs/table_lock/boxes.txt`. Art batch 1 in fixtures only.

## Next
1. REPLY 21 order: the line-time proposal (19 item 4), then REPLY 20's option A (the rival plays on my page) after Ben sees it with a gain and a line together.
2. Ben plays 118; then push the local work.
3. Only after Ben approves the layout: the 2.5D test (`Docs/UXPlan.md` §8). Then 7b pass-and-play (`Docs/TableDesign.md` §9).

## Waiting on Ben
- Are claims too rare? (0.19 a game under V5; `Docs/TableDesign.md` §9 has the fallback.)

## Open faults
- **Known V5 gaps:** hold to explain is not built on the table; the gallery's golden images are not yet approved (`tests/golden/` is empty, so `--check` compares nothing); why build 118's top buy row was dead on the phone is not found (desktop clicks and touch work in the new single row; the old layout is gone).
- **Portraits (parked for the clean-up pass, `Docs/UXPlan.md`; no third attempt, no edits, no credits):** Gluttony's pinky is cut off the palm by a dark line (the goblet collar's painted edge in the arm layer; two fixes failed). Wrath's arm layers don't meet the sleeves. Greed's dice pile has smeared, miscounted pips. Until the pass, every Sin shows its flat portrait with living-glass light only (`Tuning.LAYERS_PARKED`, all seven).
- **"Greater" is still on screen** in the rulebook and glossary (`ui/rules_text.gd:104-107,199`), though `Docs/TableDesign.md` §1 plans to remove it.
- **Balance (V4):** 7 seats are off (Greed 29.4 vs 14.3 fair); claims come 0.14 a game against a 0.5-1.5 target.
- **Old board (replaced by the table, not fixed):** labels under 15 pt, dimmed text under 4.5:1 contrast, a synthetic 12-dice layout with 5 pt gaps, a Buy-dice list of 7-8+ options running past the safe area. Full list: `build/audit/<size>.txt`.
- **Settings Back seal at SE:** it hangs over the page's lower edge, and its caption ends 11.5 pt above the screen bottom, under the 16 pt margin (REPLY 46). Not fixed: needs Ben's word.

## Budgets
- SpriteCook: 572 credits left. No credits on portraits until the clean-up pass.

## Pointers
- Rules and content: `Docs/TableDesign.md` · table as built: `Docs/TableSpec.md` · art: `Docs/ArtDirection.md` · sound: `Docs/AudioStyle.md` · onboarding: `Docs/Onboarding.md` · parked run game: `Docs/RunDesign.md` · review packets: `Docs/review/latest/`, old ones in `Docs/review/archive/` · history: `Docs/archive/`.
- TestFlight secrets (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8) are set; `ios.yml` names this file if one goes missing.
