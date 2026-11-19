# Packet: REPLY 38 item 3, match length and rivals' turns (sim and docs only)
**Local only. 0 credits. No push.** Nothing in the game changed. Read `proposal.md`; raw output is in `sims.txt`.
**New sim code:** `sim/match_game.gd` and `sim/match_sim.gd` (out-of-turn decisions, timed per item 2's beats); `sim/tables_sim.gd` (all 35 tables).
**Lever 1, three decisions on a rival's turn** (each real, staked, with a visible result):
- Back the fall: at its turn start, 50 that it busts this turn.
- The long shot: before a throw, priced by the dice.
- Hex: once a round, at 2 Strikes, 60 turns its best scorer into a Strike.
- Stakes are on the Master's credit, so every rival turn has a live prompt.
**Lever 2, his table of 4:** the Sin that beat you last, the one you've beaten least, and one you haven't faced lately. On screen, the windows light one by one, each with his line.
**The gap, at 4 seats with both levers:** median 5.5 s, p90 9.6-10.4 s, worst 39-43 s; 8-11% of gaps are over 10 s.
- Without lever 1, every gap across the rivals is over 10 s (about 31 s at 4 seats).
- What's left over 10 s: long rival turns with nothing live in them (a turn that can't bust in a throw). That is the same at any length.
**Structures with both levers:**
- A, carry 800/1600/2400: 15.0 min, 14 lead changes, the leader entering the last dance loses 63%.
- B, reset with the call at 400: 15.5 min, 7 lead changes, 38%.
- Short carry 500/1000/1500: 10.8 min.
- Short one race (the call at 1000): 7.6 min.
- You win 29-31% against a fair 25, because the bots don't bet.
**35 tables:** 0 of 140 pairings are outside 15-35. Nearest the edges: Gluttony 33.9 and Pride 17.9.
**Lever 3 (compressed turns):** left out, with no sheet to prove it.
**Questions**
1. Since the worst case can't hold 10 s, should the match be shorter: three dances carrying 500/1000/1500 (10.8 min)? Rec: yes.
2. The three decisions: build all three (fall, long shot, hex) on the Master's credit? Rec: fall and hex first; the long shot is a pure swing.
3. Should the bots bet too, to remove your edge? Rec: yes, at a simple read, then re-sim the Sins.
4. Should the Master's picked table of 4 replace the random draw for Solo bots? Rec: yes.
