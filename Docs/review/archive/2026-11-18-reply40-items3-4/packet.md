# Packet: REPLY 40 items 3 (seat order) and 4 (prompt re-sheet)
**Local only. 0 credits. No push.** Sim, sheet and docs only. Read `proposal.md`; raw output is in `sims.txt`.
**Still unreviewed:** the REPLY 37/38 packet, in `Docs/review/archive/2026-11-18-reply37-38-items2-4/` (the save fix, the token sheets, the composite).
**Item 3, seat order** (core engine, 35 tables pooled, 70,000 games; new `sim/seat_sim.gd`). Wins by seat, first to last:
- Today: 14.6 / 20.8 / 28.8 / 35.8. The last seat throws last in the final round, with every score known.
- **The fix, the final round from the leader down:** 21.8 / 24.7 / 26.9 / 26.5. Every other round is unchanged, and so is the match length.
- With rotation added (the first seat moves each round): 24.3 / 25.2 / 26.2 / 24.3.
- Wording: TableDesign §1 step 3 and the Master's final-round line, which names the order.
**You win, both ways** (match sim, today's structure):
- No decisions: 16.6% as seat 0, 25.3% seat-neutral.
- Fall + hex + raise: 27.1% as seat 0, 30.9% seat-neutral.
- Gap with the agreed set: 5.7 / 10.5 / 42.8 s; 12% over 10 s.
**Item 4, re-sheet** (`prompts_se.png`, `prompts_std.png`; 7 frames):
- a. Tap guard: the seals answer nothing until their ring fills (0.6 s); background taps never answer. Test proposed in `proposal.md`.
- b. Losing reads as big as winning: −50 at your token, +50 at its token.
- c. A chip in your colour rides at its window foot while a bet is open.
- d. Gluttony's window is forward as it is named. Tokens at 0 sit side by side with one label (the paste leaves a faint strip).
- Flights across labels are accepted: about 0.6 s in motion, and the labels are whole before and after.
**Item 5:** the sim engine models V5's abilities with the profile sim's keys, not `sins/`. Hence 2 against 0 outside without bets.
**Questions**
1. Seat order: the final round from the leader down, as the one fix? Rec: yes.
2. Add rotation too (spread 1.9 instead of 5.1)? Rec: no; one rule is enough for now.
3. Tap guard at 0.6 s, with its test written in the build? Rec: yes.
4. The track at the open, tokens at 0 side by side on one stem? Rec: yes, in the build with the prompts.
