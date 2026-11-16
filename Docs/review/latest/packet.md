# Packet: REPLY 16 (the Master as a figure, windows back to size, offer beat, call 550)
**Pushed** (main f44ffee; TestFlight run 18 = build 118, internal only). Build 117 never ran: GitHub had no macOS runner free.
- **Master:** stands behind the window row over the longest run of rival windows; for a mark or an offer, away from its window. His hood is two rival windows wide and flares into shoulders above the rivals' tops. His robe runs to both edges and down to the page top (no black band). His arm is a rival window thick.
- **Windows:** build 116's size at std and SE, and at 7 seats (std 386x694, rivals 193x347; SE 273x491, rivals 136x246). To get them back, the row took the old gap under it (22 px left) and the track band's pads went from 30 to 14 px. Rivals are lifted to 0.3 with an ink frame. A rival's stake, spoken lines and choice rows now sit on dark plates over the windows' feet.
- **Offer card:** centred just above its window, inside that window's width (std 170 px in a 193 window, SE 120 in 136).
- **Offer beat:** before the card screen, he holds the card up toward the offering Sin's window for 1.2 s; a tap skips. `table_play_check` sees it in play (92 frames) and the mark (84 frames).
- **Rules:** Devour +45; the call at 550 (item 4's rule: see the sim). Suite: all pass. Text audit: 32/32 clean at se and std. Every table_master fixture now posts at 550.

**Sheets:** `sheet.png` (std) and `sheet_se.png`: build 116 rest, mark, offer, calling, then the same four now. `boxes.txt`: pixel boxes for head, mask, shoulders, robe, arm and card in each pose, plus the windows, at std and SE (from `tools/boxes.gd`).
**What I see:** at SE the raised arm in calling reaches y 41, above the 58 px safe line. His line's plate covers the middle of the rival windows. At 7 seats the hood is narrower (two 7-seat windows, 244 px).

**Sim** (20000 mixed, Devour +45, the build's rules):
| run | Sin range | Greed / Pride / Sloth | over 6 rounds | 4 or fewer |
|---|---|---|---|---|
| call 500 | 19.7-30.2 | 30.2 / 20.2 / 19.7 | 7.5% | 29.0% |
| call 550 (built) | 19.7-29.5 | 29.5 / 20.2 / 19.7 | 12.0% | 20.4% |
| call 600 | 19.5-28.9 | 28.9 / 20.1 / 19.5 | 18.1% | 14.1% |
| 550 + Idle's first Strike to a 4 | 18.8-28.8 | 28.8 / 18.8 / 28.4 | 10.1% | 21.9% |
| 550 + Cash Out x1.2 | 19.7-29.4 | 29.4 / 20.1 / 19.7 | 12.1% | 20.2% |
| 550 + Hubris x2.0 (from 1.75) | 19.3-28.5 | 28.5 / 24.7 / 19.3 | 11.1% | 22.5% |
| 550 + all three | **19.9-27.8** | 27.8 / 23.6 / 27.5 | 9.6% | 23.7% |
**What it says:** no call meets both bars. Short games (4 rounds or fewer) and long ones (past 6) trade against each other, and even 600 leaves 14% short. Idle-one lifts Sloth (19.7 → 28.4) and Hubris x2.0 lifts Pride (20.2 → 24.7). Cash Out x1.2 doesn't move Greed. Lower Hubris targets can't be measured: the sim's Pride bots pick fixed targets.

**Questions**
1. Lock this layout? Rec: yes, and art can start from `boxes.txt`.
2. Build Idle-one and Hubris x2.0 (the "all three" row, without Cash Out x1.2)? Rec: yes. It gives the narrowest range measured so far (19.9-27.8).
3. Short games: should I sim a minimum of 5 rounds before the call can fire? Rec: yes. It targets the 20% of games that end in 4 rounds or fewer without lengthening the rest.
4. Should the raised arm in calling stay under the safe line at SE? Rec: yes. I'll clamp the hand to the safe line.
