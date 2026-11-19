# Packet: REPLY 35 items 2 and 4 (a followable rival turn, the 10 s measure; frame composite, Greed quote)
**Local only. 0 credits. Proposal, sheets and sim; no game code changed.** Details: `proposal.md`, `gaps.txt`. Sim tool: `sim/match_sim.gd` (adds the seconds between your decisions and a beat scale).
**Item 2: a rival's turn as held beats** (`strip_sheet.png`: Wrath's turn at a table of 4, today's art, each beat with its minimum and what it must show).
- Beats: turn start 0.6 s, throw 0.7, result 0.9, power 0.7, then bank 0.9 or bust 1.4. The line stays 2.5 s, and the turn waits for it.
- Every beat shows who acted, scored or lost, the new total and any power, without words.
- New on the table: the rival's token pulses at its turn start; the stake flies to the token, which slides as its label counts up; on a bust the kept half flies.
- Seconds (normal game, sim):
  - A bot turn: median 8.2 s (p90 10.6). Today: 4.1.
  - A round: 43 s at 4 seats, 69 s at 7.
  - A match: 3.9 min at 4 seats, 5.8 at 7.
- **The 10 s measure fails on pacing alone.** Inside your turn: 3.6 s between decisions. From your last decision to your next turn: 34.6 s at 4 seats and 60.4 s at 7. At Fast (beats halved) it is still 21.8 s and 36.0 s.
- It can only hold with a decision of yours inside each rival's turn (item 3). The gap is then one rival turn: median 8.2 s, with 18% over 10 s. A prompt at most every second rival throw caps it.
- `TableDesign.md` §5: the 2.5 s (and the table's 4 s) bot-turn target is dropped, and the floor is marked as under review.
**Item 4: frame composite** (`frame_sheet.png`: today | try 2 | composite | composite + SE lock boxes; `composite_750.png`). Not wired. Made earlier; you have not yet seen it.
- The arch is gone.
- The page inside the border is flat parchment with try 2's fine grain, down to just above the dice. Try 2's track, baked light and grey stain are gone; the only light is the soft one.
- The track ink is squeezed 4.4% about the centre and now runs x 83-699 at SE (the border's inner edge is at 707). Today "1000" ran to 714, 7 px under the border.
- Labels moved, in SE px: 1000 −11/−16; 280 +7/+4; 340 +6/+3; 410 +4/+1; 520 +1/−2. No window or lock box moved.
- The fill fades into try 2's page over 30 px above the dice.
**Item 5: Greed dice, a quote only.** One NB 2.1 painted edit of `greed.png` (223x760): **12 credits** at 1K, 18 at 2K; the upload is free. It goes in padded to 9:16 and is cropped back. Balance: 126. Not generated.
**Questions**
1. Do the beats and what each shows (strip sheet) go forward as the pacing floor? Rec: yes. Build them with the pace-test floors raised in the same commit.
2. Settle the 10 s measure in item 3, with a decision of yours inside each rival's turn, rather than by speeding rivals up? Rec: yes.
3. Composite: is the page clean enough to brief a painted pass? Rec: judge `composite_750.png` at phone size.
4. Greed dice edit for 12 credits? Rec: yes, at 1K.
