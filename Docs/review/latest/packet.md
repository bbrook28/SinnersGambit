# Packet: REPLY 34 items 2-5 (pacing floor, match length, frame composite, Greed quote)
**Local only. 0 credits. No game code changed.** New sim tool: `sim/match_sim.gd` (c919115). Item 1's packet: `Docs/review/archive/2026-11-17-reply34-item1/`.
**2. Pacing floor** (`proposal.md`, item 2). Every beat has a minimum: throw 0.7 s, result 0.9 s, then bank 0.9 s or bust 1.4 s. A line stays up 2.5 s, and the turn waits for it.
- A bot turn: median 8.2 s (today 4.1 s). A round: 43 s at 4 seats, 69 s at 7. Today's match: 3.9 min at 4 seats.
- Speed setting: Normal and Fast on the table (Fast halves the beats but not the lines).
**3. Match length** (`proposal.md` item 3, `sims.txt`; sim and docs only). Simmed at 4 seats with mixed profiles:
- **A: three dances, scores carried** (races to 1200 and 2400, then the call at 3600; between dances one rule changes and a power may be swapped):
  - 14.9 min (12.2-18.4).
  - Lead changes: 18.7.
  - The leader entering the last dance loses 63%.
  - Sins (by start): 21.6-32.7.
- **B: three dances, scores reset** (each dance is today's game with the call at 750; placings 4/2/1/0, the last dance double):
  - 14.6 min.
  - Lead changes: 7.9.
  - The leader entering the last dance loses 35%.
  - Sins: 20.1-35.7.
- Finding: in any match longer than about 6 rounds, Envy wins about 60% unless powers are swapped (today 28.9%). At 7 seats there is no free Sin to swap to.
- Touches and Could break are listed in `proposal.md`. Briefly: core/, sins/ and ai/ (your OK); new interlude screens; the track's scale (A) or dance pips under the windows (B); 15 new Master lines.
**4. Frame composite** (`frame_sheet.png`: today | try 2 | composite | composite + SE lock boxes; `composite_750.png`). Not wired.
- The arch is gone.
- Inside the border, the page is now flat parchment plus try 2's fine grain, down to just above the dice. Try 2's track, baked light and grey stain are gone. The only light is the soft one.
- Track inset: today's track ink, squeezed 4.4% about the centre line, now runs x 83-699 at SE; the border's inner edge is at 707. Today the "1000" ran to 714, 7 px under the border.
- Label moves in screen px at SE: 1000 −11/−16; 280 +7/+4; 340 +6/+3; 410 +4/+1; 520 +1/−2. No window or lock box moved. Wiring it would narrow the track inside the band box.
- Faults: the fill fades back into try 2's page over 30 px just above the dice.
**5. Greed dice, a quote only.** One painted edit of `greed.png` (223x760) with NB 2.1: **12 credits** at 1K (the upload is free), 18 at 2K. 1K covers the window. NB 2.1 has no 1:3.4 frame, so the edit goes in padded to 9:16 and is cropped back. Balance: 126. Not generated.
**Questions**
1. Pacing floor as in `proposal.md`, with Normal and Fast on the table? Rec: yes. Build it with item 1's fix once you reply.
2. Which match structure goes forward? Rec: A (three dances, scores carried): the last dance decides most often (63%).
3. Before either structure: sim an Envy fix for long matches (for example, her copy once a dance, or capped at 30)? Rec: yes, sim only.
4. At 7 seats, should the power pick be a trade between seats? Rec: yes, but only once 2 is settled.
5. Composite: is the page clean enough to brief a painted pass, or another script pass first? Rec: judge `composite_750.png` at phone size.
6. Greed dice edit: 12 credits? Rec: yes, at 1K.
