# Packet: REPLY 41 items 2 (the shuffled seat) and 4 (two sheet checks)
**Local only. 0 credits. No push.** Sim, sheet and docs only. Read `proposal.md`; raw output is in `sims.txt`.
**Still unreviewed:** the REPLY 37/38 packet in `Docs/review/archive/2026-11-18-reply37-38-items2-4/`.
**Item 1:** TableDesign §1 step 3 now carries the final-round order as "agreed, not built" (its own commit).
**Item 2, a correction:** the game already draws your seat once a match. `ui/main.gd` calls `order.shuffle()` and Continue saves the order. Only the sim kept you first.
- Wins by seat, your seat drawn once a match: today 16.7 / 22.4 / 29.1 / 31.9; with the fix 22.4 / 25.1 / 26.8 / 25.7.
- You win, averaged over the draw: 24.6% without decisions and 32.3% with them; the same with the fix.
- So the fix doesn't move your average. It removes the 15-point gap between drawing the first seat and the last.
- What depends on your seat today: listed in `proposal.md` (main, table views, core's start line, the tutorial's fixed first seat).
**Gap with the decisions, the 0.6 s guard counted:** 6.3 / 10.9 / 47.8 s; 15% over 10 s.
- With the fix, the worst case grows to 61.3 s: you can move from first to last in the final round.
**Item 4** (`fixes_se.png` at SE 1:1; the full sheets are updated):
- The open: both token rows are 31 SE px clear of the page edge.
- "+65" now uses the same face, size and stroke as "−50", in deep gold.
**Questions**
1. Keep the seat drawn once a match, as built, rather than adding any rule? Rec: yes.
2. Is "+65" in deep gold enough weight, or should a win use a colour of its own? Rec: deep gold, to keep gold meaning scoring.
