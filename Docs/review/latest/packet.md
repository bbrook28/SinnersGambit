# Packet: REPLY 17 (line into the robe, hand clamp, Idle-one and Hubris x2, round-floor sim)
**Local only, not pushed** (waiting on your play of 118). Layout is not locked and there is no art.
- **The Master's line:** now on a plate in his robe, its foot 12 px above the rival windows' tops. It stays clear of the active window and the card in his hand, and clear of his arm if two lines still fit (380 px). TableSpec is updated.
- **Raised hand:** clamped so the sleeve's round end sits at or below the safe line (SE calling: arm top y 61, safe line 58; build 118 had 41). The first clamp only covered the hand, and the sleeve still crossed the line, so I fixed it.
- **Rules (Rules.V5):** `idle_one`: Idle turns the throw's first Strike into a 4 and the rest into 3s. Power text: "Ignore this throw's Strikes; the first becomes a 4." Hubris is x2 (was x1.75); Cash Out stays x1.25. TableDesign gets a "Decided (REPLY 17)" line.
- Suite: all pass (v5_check 373, with Idle-one and x2). Text audit: 32/32 clean at se and std.

**Sheets:** `sheet.png` (std) and `sheet_se.png`: build 118 rest, mark, offer, calling, then the same four now. `boxes.txt` has the new `line` box.
**What I see:** in mark, the plate runs in front of his pointing arm at both sizes. His arm leaves under 380 px beside it, so it falls back to crossing. In offer at SE, the plate's left end overlaps the arm by about 65 px. The hood's top is still above the SE safe line; only the hand is clamped.

**Sim** (20000 mixed; Idle-one + Hubris x2 as built, Devour +45):
| run | Sin range | over 6 rounds | 4 or fewer | last seat wins |
|---|---|---|---|---|
| call 550, no floor (built) | 19.8-27.9 | 9.4% | 24.0% | 5.9% |
| 550, no call before round 3 (games last 5+) | 20.4-27.8 | 9.5% | 0% | 5.9% |
| 550, no call before round 5 (games last 7+) | 20.3-30.7 | 100% | 0% | 5.6% |
| 600, no call before round 3 | 20.1-27.7 | 14.8% | 0% | 5.9% |
The call ends the game two rounds later, so "no call before round 3" is what makes round 5 the earliest end. With that floor at 550: 63% of games end in round 5 and 9.5% go past 6. The range also narrows (20.4-27.8). Taken literally ("the call can't fire before round 5"), every game runs 7 rounds or more, and Envy rises to 30.7.

**Questions**
1. Floor reading: should the earliest end be round 5 (call no earlier than round 3)? Rec: yes. It kills every game of 4 rounds or fewer, and long games stay at 9.5%.
2. Build that floor at 550? Rec: yes, after you've played 118. It's a rules change (core/game.gd).
3. In mark, should the plate cross his arm or wrap to 3-4 lines beside it? Rec: cross. Narrow plates rise into the hood and reach the SE safe line.
4. Should the hood's top also stay under the SE safe line? Rec: no. It's figure, not text or control, and lowering it shrinks the windows.
